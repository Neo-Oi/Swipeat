import '../models/premium_entitlement.dart';
import 'premium_service.dart';

enum WebPremiumAccessStatus { unauthenticated, premium, free, unavailable }

class WebPremiumAccessResult {
  const WebPremiumAccessResult({required this.status, this.entitlement});

  final WebPremiumAccessStatus status;
  final PremiumEntitlement? entitlement;

  bool get hasPremium => status == WebPremiumAccessStatus.premium;
}

abstract interface class AuthSessionProvider {
  bool get isSignedIn;
}

/// Web の Premium は購入せず、Android契約と同じアカウントの権限を読む。
class WebPremiumAccessService {
  const WebPremiumAccessService({
    required this.session,
    required this.entitlementProvider,
  });

  final AuthSessionProvider session;
  final PremiumEntitlementProvider entitlementProvider;

  Future<WebPremiumAccessResult> resolve() async {
    if (!session.isSignedIn) {
      return const WebPremiumAccessResult(
        status: WebPremiumAccessStatus.unauthenticated,
      );
    }

    try {
      final entitlement = await entitlementProvider.readEntitlement();
      return WebPremiumAccessResult(
        status: entitlement.isPremiumAt()
            ? WebPremiumAccessStatus.premium
            : WebPremiumAccessStatus.free,
        entitlement: entitlement,
      );
    } catch (_) {
      // 権限を確認できない時にPremiumを誤って解放しない。
      return const WebPremiumAccessResult(
        status: WebPremiumAccessStatus.unavailable,
      );
    }
  }
}
