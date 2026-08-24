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

  factory PremiumEntitlement.fromMap(Map<String, dynamic> map) {
    return PremiumEntitlement(
      status: _statusFromId(map['status']?.toString()),
      source: _sourceFromId(map['source']?.toString()),
      validFrom: _dateFromValue(map['validFrom']),
      validUntil: _dateFromValue(map['validUntil']),
      productId: map['productId']?.toString(),
      updatedAt: _dateFromValue(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'status': status.name,
      'source': source.id,
      if (validFrom != null) 'validFrom': validFrom!.toUtc().toIso8601String(),
      if (validUntil != null)
        'validUntil': validUntil!.toUtc().toIso8601String(),
      if (productId != null) 'productId': productId,
      if (updatedAt != null) 'updatedAt': updatedAt!.toUtc().toIso8601String(),
    };
  }

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

  static PremiumEntitlementStatus _statusFromId(String? id) {
    for (final status in PremiumEntitlementStatus.values) {
      if (status.name == id) return status;
    }
    return PremiumEntitlementStatus.unknown;
  }

  static PremiumEntitlementSource _sourceFromId(String? id) {
    switch (id) {
      case 'google_play':
        return PremiumEntitlementSource.googlePlay;
      case 'free_trial':
        return PremiumEntitlementSource.freeTrial;
      case 'complimentary':
        return PremiumEntitlementSource.complimentary;
      case 'developer':
        return PremiumEntitlementSource.developer;
      default:
        return PremiumEntitlementSource.none;
    }
  }

  static DateTime? _dateFromValue(Object? value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
