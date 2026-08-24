/// Premium 権限を付与した仕組み。
enum PremiumEntitlementSource {
  googlePlay,
  freeTrial,
  complimentary,
  developer,
  none,
}

extension PremiumEntitlementSourceId on PremiumEntitlementSource {
  String get id {
    switch (this) {
      case PremiumEntitlementSource.googlePlay:
        return 'google_play';
      case PremiumEntitlementSource.freeTrial:
        return 'free_trial';
      case PremiumEntitlementSource.complimentary:
        return 'complimentary';
      case PremiumEntitlementSource.developer:
        return 'developer';
      case PremiumEntitlementSource.none:
        return 'none';
    }
  }
}

/// サーバーや Play の購読状態を表す。
enum PremiumEntitlementStatus { active, pending, expired, revoked, unknown }

/// 端末ローカルの boolean ではなく、アカウント単位で扱う Premium 権限。
class PremiumEntitlement {
  const PremiumEntitlement({
    required this.status,
    required this.source,
    this.validFrom,
    this.validUntil,
    this.productId,
    this.updatedAt,
  });

  const PremiumEntitlement.none()
    : status = PremiumEntitlementStatus.unknown,
      source = PremiumEntitlementSource.none,
      validFrom = null,
      validUntil = null,
      productId = null,
      updatedAt = null;

  final PremiumEntitlementStatus status;
  final PremiumEntitlementSource source;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final String? productId;
  final DateTime? updatedAt;

  /// 指定時点で完全 Premium として扱えるか。
  ///
  /// 無料体験も source が [PremiumEntitlementSource.freeTrial] の active
  /// 権限として判定する。通信で権限を確認できない場合は unknown となり、
  /// 安全側で Free 扱いになる。
  bool isPremiumAt([DateTime? now]) {
    if (status != PremiumEntitlementStatus.active) return false;
    if (source == PremiumEntitlementSource.none) return false;

    final current = (now ?? DateTime.now()).toUtc();
    final start = validFrom?.toUtc();
    final end = validUntil?.toUtc();

    if (start != null && current.isBefore(start)) return false;
    if (end != null && !current.isBefore(end)) return false;
    return true;
  }

  PremiumEntitlement copyWith({
    PremiumEntitlementStatus? status,
    PremiumEntitlementSource? source,
    DateTime? validFrom,
    DateTime? validUntil,
    String? productId,
    DateTime? updatedAt,
  }) {
    return PremiumEntitlement(
      status: status ?? this.status,
      source: source ?? this.source,
      validFrom: validFrom ?? this.validFrom,
      validUntil: validUntil ?? this.validUntil,
      productId: productId ?? this.productId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
