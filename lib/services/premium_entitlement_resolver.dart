import 'package:flutter/foundation.dart';

import '../models/premium_entitlement.dart';
import 'premium_service.dart';

/// 開発中だけ利用できる Premium override。
///
/// `kDebugMode` を最初に確認するため、Release ビルドで環境変数を指定しても
/// developer entitlement は生成されない。
class DeveloperPremiumOverride {
  const DeveloperPremiumOverride({bool? enabled})
    : _enabled =
          enabled ??
          (const String.fromEnvironment('SWIPEAT_DEVELOPER_PREMIUM') == 'true');

  final bool _enabled;

  bool get isEnabled => kDebugMode && _enabled;

  PremiumEntitlement? get entitlement {
    if (!isEnabled) return null;
    return const PremiumEntitlement(
      status: PremiumEntitlementStatus.active,
      source: PremiumEntitlementSource.developer,
    );
  }
}

/// サーバー権限と Debug 限定 override を合成する。
class PremiumEntitlementResolver implements PremiumEntitlementProvider {
  const PremiumEntitlementResolver({
    required this.serverProvider,
    this.developerOverride = const DeveloperPremiumOverride(),
  });

  final PremiumEntitlementProvider serverProvider;
  final DeveloperPremiumOverride developerOverride;

  @override
  Future<PremiumEntitlement> readEntitlement() async {
    final override = developerOverride.entitlement;
    if (override != null) return override;
    return serverProvider.readEntitlement();
  }
}
