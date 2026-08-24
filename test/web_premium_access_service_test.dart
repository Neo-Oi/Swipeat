import 'package:flutter_test/flutter_test.dart';
import 'package:swipeat/models/premium_entitlement.dart';
import 'package:swipeat/services/premium_service.dart';
import 'package:swipeat/services/web_premium_access_service.dart';
import 'package:swipeat/widgets/web_premium_access_panel.dart';
import 'package:flutter/material.dart';

class _FakeSession implements AuthSessionProvider {
  const _FakeSession(this.isSignedIn);

  @override
  final bool isSignedIn;
}

class _FakeProvider implements PremiumEntitlementProvider {
  const _FakeProvider(this.entitlement, {this.shouldThrow = false});

  final PremiumEntitlement entitlement;
  final bool shouldThrow;

  @override
  Future<PremiumEntitlement> readEntitlement() async {
    if (shouldThrow) throw StateError('network');
    return entitlement;
  }
}

void main() {
  test('does not read entitlement when Web user is signed out', () async {
    const service = WebPremiumAccessService(
      session: _FakeSession(false),
      entitlementProvider: _FakeProvider(PremiumEntitlement.none()),
    );

    final result = await service.resolve();
    expect(result.status, WebPremiumAccessStatus.unauthenticated);
  });

  test('shares an active Android entitlement with Web', () async {
    const service = WebPremiumAccessService(
      session: _FakeSession(true),
      entitlementProvider: _FakeProvider(
        PremiumEntitlement(
          status: PremiumEntitlementStatus.active,
          source: PremiumEntitlementSource.googlePlay,
        ),
      ),
    );

    final result = await service.resolve();
    expect(result.status, WebPremiumAccessStatus.premium);
    expect(result.hasPremium, isTrue);
  });

  test('returns Free for an account without active entitlement', () async {
    const service = WebPremiumAccessService(
      session: _FakeSession(true),
      entitlementProvider: _FakeProvider(PremiumEntitlement.none()),
    );

    final result = await service.resolve();
    expect(result.status, WebPremiumAccessStatus.free);
    expect(result.hasPremium, isFalse);
  });

  test('fails closed when entitlement lookup is unavailable', () async {
    const service = WebPremiumAccessService(
      session: _FakeSession(true),
      entitlementProvider: _FakeProvider(
        PremiumEntitlement.none(),
        shouldThrow: true,
      ),
    );

    final result = await service.resolve();
    expect(result.status, WebPremiumAccessStatus.unavailable);
    expect(result.hasPremium, isFalse);
  });

  testWidgets('Web panel does not expose a purchase action', (
    WidgetTester tester,
  ) async {
    const result = WebPremiumAccessResult(status: WebPremiumAccessStatus.free);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: WebPremiumAccessPanel(result: result)),
      ),
    );

    expect(find.text('AndroidでPremiumを契約できます'), findsOneWidget);
    expect(find.textContaining('Webでは決済できません'), findsOneWidget);
    expect(find.text('購入する'), findsNothing);
  });
}
