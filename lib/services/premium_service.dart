import '../models/premium_entitlement.dart';

/// Firebase/バックエンド/テスト用の権限取得境界。
abstract interface class PremiumEntitlementProvider {
  Future<PremiumEntitlement> readEntitlement();
}

/// Premium 権限を取得し、機能ゲートへ渡すアプリケーションサービス。
///
/// 実際の認証・Play Billing・Firebase は後続 Issue で provider として接続する。
class PremiumService {
  const PremiumService({required this.provider});

  final PremiumEntitlementProvider provider;

  Future<PremiumEntitlement> getEntitlement() {
    return provider.readEntitlement();
  }

  Future<bool> canUsePremium({DateTime? now}) async {
    final entitlement = await getEntitlement();
    return entitlement.isPremiumAt(now);
  }
}
