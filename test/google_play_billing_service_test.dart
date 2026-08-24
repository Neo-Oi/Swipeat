import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:swipeat/services/google_play_billing_service.dart';

class _FakeBillingStore implements BillingStore {
  _FakeBillingStore(this.product);

  final ProductDetails product;
  final StreamController<List<PurchaseDetails>> controller =
      StreamController<List<PurchaseDetails>>.broadcast();
  bool buyCalled = false;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => controller.stream;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<ProductDetailsResponse> queryProductDetails(
    Set<String> identifiers,
  ) async {
    return ProductDetailsResponse(
      productDetails: [product],
      notFoundIDs: const [],
    );
  }

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    buyCalled = true;
    return true;
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {}

  @override
  Future<void> restorePurchases() async {}
}

void main() {
  test('does not use a fixed price and reads the Play product price', () async {
    final store = _FakeBillingStore(
      ProductDetails(
        id: 'premium-monthly',
        title: 'Swipeat Premium',
        description: 'Monthly subscription',
        price: '￥320',
        rawPrice: 320,
        currencyCode: 'JPY',
      ),
    );
    final service = GooglePlayBillingService(
      configuration: const PremiumProductConfiguration(
        productId: 'premium-monthly',
      ),
      store: store,
      platformIsAndroid: true,
    );

    expect(await service.loadDisplayPrice(), '￥320');
    expect(await service.startSubscription(), isTrue);
    expect(store.buyCalled, isTrue);
  });

  test('fails closed on web or when the product id is missing', () async {
    final webService = GooglePlayBillingService(
      configuration: const PremiumProductConfiguration(productId: 'premium'),
      store: _FakeBillingStore(
        ProductDetails(
          id: 'premium',
          title: 'Premium',
          description: '',
          price: '￥300',
          rawPrice: 300,
          currencyCode: 'JPY',
        ),
      ),
      platformIsAndroid: false,
    );
    expect(
      webService.loadPremiumProduct(),
      throwsA(isA<BillingUnavailableException>()),
    );

    final unconfigured = GooglePlayBillingService(
      store: _FakeBillingStore(
        ProductDetails(
          id: 'premium',
          title: 'Premium',
          description: '',
          price: '￥300',
          rawPrice: 300,
          currencyCode: 'JPY',
        ),
      ),
      platformIsAndroid: true,
    );
    expect(
      unconfigured.loadPremiumProduct(),
      throwsA(isA<BillingConfigurationException>()),
    );
  });
}
