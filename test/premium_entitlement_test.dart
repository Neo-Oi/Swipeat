import 'package:flutter_test/flutter_test.dart';
import 'package:swipeat/models/premium_entitlement.dart';
import 'package:swipeat/services/premium_service.dart';

class _FakeEntitlementProvider implements PremiumEntitlementProvider {
  _FakeEntitlementProvider(this.entitlement);

  PremiumEntitlement entitlement;

  @override
  Future<PremiumEntitlement> readEntitlement() async => entitlement;
}

void main() {
  final now = DateTime.utc(2026, 8, 25, 12);

  group('PremiumEntitlement', () {
    test('active Google Play entitlement is Premium', () {
      const entitlement = PremiumEntitlement(
        status: PremiumEntitlementStatus.active,
        source: PremiumEntitlementSource.googlePlay,
      );

      expect(entitlement.isPremiumAt(now), isTrue);
      expect(PremiumEntitlementSource.googlePlay.id, 'google_play');
    });

    test('active free trial is complete Premium', () {
      final entitlement = PremiumEntitlement(
        status: PremiumEntitlementStatus.active,
        source: PremiumEntitlementSource.freeTrial,
        validFrom: now.subtract(const Duration(days: 1)),
        validUntil: now.add(const Duration(days: 6)),
      );

      expect(entitlement.isPremiumAt(now), isTrue);
    });

    test('complimentary and developer sources can be active', () {
      for (final source in <PremiumEntitlementSource>[
        PremiumEntitlementSource.complimentary,
        PremiumEntitlementSource.developer,
      ]) {
        final entitlement = PremiumEntitlement(
          status: PremiumEntitlementStatus.active,
          source: source,
        );
        expect(entitlement.isPremiumAt(now), isTrue);
      }
    });

    test('expired, revoked, pending, unknown and none are Free', () {
      final cases = <PremiumEntitlement>[
        PremiumEntitlement(
          status: PremiumEntitlementStatus.active,
          source: PremiumEntitlementSource.googlePlay,
          validUntil: now,
        ),
        const PremiumEntitlement(
          status: PremiumEntitlementStatus.expired,
          source: PremiumEntitlementSource.googlePlay,
        ),
        const PremiumEntitlement(
          status: PremiumEntitlementStatus.revoked,
          source: PremiumEntitlementSource.googlePlay,
        ),
        const PremiumEntitlement(
          status: PremiumEntitlementStatus.pending,
          source: PremiumEntitlementSource.googlePlay,
        ),
        const PremiumEntitlement(
          status: PremiumEntitlementStatus.unknown,
          source: PremiumEntitlementSource.googlePlay,
        ),
        const PremiumEntitlement.none(),
      ];

      for (final entitlement in cases) {
        expect(entitlement.isPremiumAt(now), isFalse);
      }
    });

    test('future validity start is not active yet', () {
      final entitlement = PremiumEntitlement(
        status: PremiumEntitlementStatus.active,
        source: PremiumEntitlementSource.googlePlay,
        validFrom: now.add(const Duration(minutes: 1)),
      );

      expect(entitlement.isPremiumAt(now), isFalse);
    });
  });

  test('PremiumService delegates authority to its provider', () async {
    final provider = _FakeEntitlementProvider(
      const PremiumEntitlement(
        status: PremiumEntitlementStatus.active,
        source: PremiumEntitlementSource.complimentary,
      ),
    );
    final service = PremiumService(provider: provider);

    expect(await service.canUsePremium(now: now), isTrue);
  });
}
