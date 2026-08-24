import 'package:flutter_test/flutter_test.dart';
import 'package:swipeat/models/premium_entitlement.dart';

void main() {
  test('serializes and restores all entitlement fields', () {
    final original = PremiumEntitlement(
      status: PremiumEntitlementStatus.active,
      source: PremiumEntitlementSource.complimentary,
      validFrom: DateTime.utc(2026, 8, 1),
      validUntil: DateTime.utc(2026, 9, 1),
      productId: 'complimentary-family',
      updatedAt: DateTime.utc(2026, 8, 25),
    );

    final restored = PremiumEntitlement.fromMap(original.toMap());

    expect(restored.status, PremiumEntitlementStatus.active);
    expect(restored.source, PremiumEntitlementSource.complimentary);
    expect(restored.validFrom, original.validFrom);
    expect(restored.validUntil, original.validUntil);
    expect(restored.productId, 'complimentary-family');
    expect(restored.updatedAt, original.updatedAt);
  });

  test('unknown server values fail closed', () {
    final entitlement = PremiumEntitlement.fromMap(const <String, dynamic>{
      'status': 'unknown_future_status',
      'source': 'unknown_future_source',
      'validUntil': 'not-a-date',
    });

    expect(entitlement.status, PremiumEntitlementStatus.unknown);
    expect(entitlement.source, PremiumEntitlementSource.none);
    expect(entitlement.isPremiumAt(DateTime.utc(2026, 8, 25)), isFalse);
  });
}
