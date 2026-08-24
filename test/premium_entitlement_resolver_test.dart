import 'package:flutter_test/flutter_test.dart';
import 'package:swipeat/models/premium_entitlement.dart';
import 'package:swipeat/services/premium_entitlement_resolver.dart';
import 'package:swipeat/services/premium_service.dart';

class _FakeProvider implements PremiumEntitlementProvider {
  const _FakeProvider(this.entitlement);

  final PremiumEntitlement entitlement;

  @override
  Future<PremiumEntitlement> readEntitlement() async => entitlement;
}

void main() {
  test('Debug developer override creates only developer entitlement', () async {
    const resolver = PremiumEntitlementResolver(
      serverProvider: _FakeProvider(PremiumEntitlement.none()),
      developerOverride: DeveloperPremiumOverride(enabled: true),
    );

    final entitlement = await resolver.readEntitlement();
    // flutter test is a debug build; Release always returns the server value.
    expect(entitlement.source, PremiumEntitlementSource.developer);
    expect(entitlement.isPremiumAt(), isTrue);
  });

  test('disabled override uses server entitlement', () async {
    const resolver = PremiumEntitlementResolver(
      serverProvider: _FakeProvider(
        PremiumEntitlement(
          status: PremiumEntitlementStatus.active,
          source: PremiumEntitlementSource.complimentary,
        ),
      ),
      developerOverride: DeveloperPremiumOverride(enabled: false),
    );

    final entitlement = await resolver.readEntitlement();
    expect(entitlement.source, PremiumEntitlementSource.complimentary);
  });
}
