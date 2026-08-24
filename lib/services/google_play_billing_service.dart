import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Play Console の商品 ID。価格は ProductDetails から取得する。
class PremiumProductConfiguration {
  const PremiumProductConfiguration({required this.productId});

  factory PremiumProductConfiguration.fromEnvironment() {
    return const PremiumProductConfiguration(
      productId: String.fromEnvironment('PREMIUM_PRODUCT_ID'),
    );
  }

  final String productId;

  bool get isConfigured => productId.isNotEmpty;
}

class BillingConfigurationException implements Exception {
  const BillingConfigurationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class BillingUnavailableException implements Exception {
  const BillingUnavailableException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// InAppPurchase の差し替え可能な境界。
abstract interface class BillingStore {
  Stream<List<PurchaseDetails>> get purchaseStream;

  Future<bool> isAvailable();

  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers);

  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam});

  Future<void> completePurchase(PurchaseDetails purchase);

  Future<void> restorePurchases();
}

class InAppPurchaseBillingStore implements BillingStore {
  const InAppPurchaseBillingStore();

  InAppPurchase get _store => InAppPurchase.instance;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _store.purchaseStream;

  @override
  Future<bool> isAvailable() => _store.isAvailable();

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers) {
    return _store.queryProductDetails(identifiers);
  }

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) {
    return _store.buyNonConsumable(purchaseParam: purchaseParam);
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) {
    return _store.completePurchase(purchase);
  }

  @override
  Future<void> restorePurchases() => _store.restorePurchases();
}

/// Play の購入状態を UI/バックエンドへ渡す値。
class PremiumPurchaseUpdate {
  const PremiumPurchaseUpdate({
    required this.purchase,
    required this.productId,
    required this.status,
    required this.verificationData,
    this.purchaseId,
    this.error,
    this.pendingCompletePurchase = false,
  });

  factory PremiumPurchaseUpdate.fromPurchase(PurchaseDetails purchase) {
    return PremiumPurchaseUpdate(
      purchase: purchase,
      productId: purchase.productID,
      status: purchase.status,
      verificationData: purchase.verificationData,
      purchaseId: purchase.purchaseID,
      error: purchase.error,
      pendingCompletePurchase: purchase.pendingCompletePurchase,
    );
  }

  final PurchaseDetails purchase;
  final String productId;
  final PurchaseStatus status;
  final PurchaseVerificationData verificationData;
  final String? purchaseId;
  final IAPError? error;
  final bool pendingCompletePurchase;

  bool get isEntitlementCandidate =>
      status == PurchaseStatus.purchased || status == PurchaseStatus.restored;
}

/// Android Google Play subscription の購入境界。
///
/// 無料体験の期間判定は実装せず、Play Console の subscription offer と
/// 購読状態を Issue 18 のサーバー検証へ渡す。
class GooglePlayBillingService {
  GooglePlayBillingService({
    PremiumProductConfiguration? configuration,
    BillingStore? store,
    bool? platformIsAndroid,
  }) : configuration =
           configuration ?? PremiumProductConfiguration.fromEnvironment(),
       _store = store ?? const InAppPurchaseBillingStore(),
       _platformIsAndroid =
           platformIsAndroid ??
           (!kIsWeb && defaultTargetPlatform == TargetPlatform.android);

  final PremiumProductConfiguration configuration;
  final BillingStore _store;
  final bool _platformIsAndroid;

  bool get isSupportedPlatform => _platformIsAndroid;

  Future<void> ensureAvailable() async {
    if (!_platformIsAndroid) {
      throw const BillingUnavailableException(
        'Google Play Billing は Android でのみ利用できます。',
      );
    }
    if (!configuration.isConfigured) {
      throw const BillingConfigurationException(
        'PREMIUM_PRODUCT_ID が未設定です。Play Console の商品 ID を --dart-define で指定してください。',
      );
    }
    if (!await _store.isAvailable()) {
      throw const BillingUnavailableException('Google Play Billing を利用できません。');
    }
  }

  Future<ProductDetails> loadPremiumProduct() async {
    await ensureAvailable();
    final response = await _store.queryProductDetails({
      configuration.productId,
    });
    if (response.error != null) {
      throw BillingUnavailableException(response.error!.message);
    }
    if (response.productDetails.isEmpty) {
      throw BillingUnavailableException(
        '商品が見つかりません: ${configuration.productId}',
      );
    }
    return response.productDetails.first;
  }

  /// Play から取得した表示価格。価格をコードへ固定しない。
  Future<String> loadDisplayPrice() async {
    final product = await loadPremiumProduct();
    return product.price;
  }

  Future<bool> startSubscription({String? accountHash}) async {
    final product = await loadPremiumProduct();
    return _store.buyNonConsumable(
      purchaseParam: PurchaseParam(
        productDetails: product,
        applicationUserName: accountHash,
      ),
    );
  }

  Stream<PremiumPurchaseUpdate> get purchaseUpdates {
    return _store.purchaseStream.asyncExpand(
      (purchases) => Stream.fromIterable(
        purchases.map(PremiumPurchaseUpdate.fromPurchase),
      ),
    );
  }

  Future<void> completePurchase(PremiumPurchaseUpdate update) async {
    if (!update.pendingCompletePurchase) return;
    await _store.completePurchase(update.purchase);
  }

  Future<void> completeStorePurchase(PurchaseDetails purchase) {
    return _store.completePurchase(purchase);
  }

  Future<void> restorePurchases() async {
    await ensureAvailable();
    await _store.restorePurchases();
  }
}
