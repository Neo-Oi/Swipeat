import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:swipeat/models/premium_entitlement.dart';
import 'package:swipeat/services/google_play_billing_service.dart';
import 'package:swipeat/services/premium_entitlement_sync_service.dart';

class _FakeAuthTokenProvider implements AuthTokenProvider {
  _FakeAuthTokenProvider(this.token);

  final String? token;

  @override
  Future<String?> getIdToken() async => token;
}

class _FakeVerificationClient implements PremiumEntitlementVerificationClient {
  PurchaseVerificationPayload? payload;
  String? firebaseIdToken;

  @override
  Future<PremiumEntitlement> verifyPurchase({
    required PurchaseVerificationPayload payload,
    required String firebaseIdToken,
  }) async {
    this.payload = payload;
    this.firebaseIdToken = firebaseIdToken;
    return const PremiumEntitlement(
      status: PremiumEntitlementStatus.active,
      source: PremiumEntitlementSource.googlePlay,
    );
  }
}

PremiumPurchaseUpdate update({
  PurchaseStatus status = PurchaseStatus.purchased,
  String token = 'play-purchase-token',
}) {
  final purchase = PurchaseDetails(
    productID: 'premium-monthly',
    verificationData: PurchaseVerificationData(
      localVerificationData: token,
      serverVerificationData: token,
      source: 'test',
    ),
    transactionDate: '2026-08-25',
    status: status,
  );
  return PremiumPurchaseUpdate.fromPurchase(purchase);
}

void main() {
  test(
    'sends Play token with Firebase identity and uses server result',
    () async {
      final verificationClient = _FakeVerificationClient();
      final service = PremiumEntitlementSyncService(
        authTokenProvider: _FakeAuthTokenProvider('firebase-id-token'),
        verificationClient: verificationClient,
      );

      final entitlement = await service.sync(update());

      expect(entitlement.isPremiumAt(DateTime.utc(2026, 8, 25)), isTrue);
      expect(verificationClient.firebaseIdToken, 'firebase-id-token');
      expect(verificationClient.payload?.productId, 'premium-monthly');
      expect(verificationClient.payload?.purchaseToken, 'play-purchase-token');
      expect(verificationClient.payload?.source, 'google_play');
    },
  );

  test('does not allow an unauthenticated client to sync entitlement', () {
    final service = PremiumEntitlementSyncService(
      authTokenProvider: _FakeAuthTokenProvider(null),
      verificationClient: _FakeVerificationClient(),
    );

    expect(
      service.sync(update()),
      throwsA(isA<PremiumEntitlementSyncException>()),
    );
  });

  test('does not treat pending or empty-token purchases as entitlement', () {
    final service = PremiumEntitlementSyncService(
      authTokenProvider: _FakeAuthTokenProvider('firebase-id-token'),
      verificationClient: _FakeVerificationClient(),
    );

    expect(
      service.sync(update(status: PurchaseStatus.pending)),
      throwsA(isA<PremiumEntitlementSyncException>()),
    );
    expect(
      service.sync(update(token: '')),
      throwsA(isA<PremiumEntitlementSyncException>()),
    );
  });
}
