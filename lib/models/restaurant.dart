import 'restaurant_classification.dart';

class Restaurant {
  const Restaurant({
    required this.name,
    required this.tags,
    required this.budget,
    required this.description,
    required this.companions,
    required this.budgets,
    required this.distanceMeters,
    required this.categories,
    this.googlePlaceId,
    this.address,
    this.latitude,
    this.longitude,
    this.rating,
    this.userRatingCount,
    this.photoUrl,
    this.isOpenNow,
    this.googlePrimaryType,
    this.googleTypes = const [],
    this.classification,
  });

  final String name;
  final List<String> tags;
  final String budget;
  final String description;
  final List<String> companions;
  final List<String> budgets;
  final int distanceMeters;
  final List<String> categories;

  final String? googlePlaceId;
  final String? address;
  final double? latitude;
  final double? longitude;
  final double? rating;
  final int? userRatingCount;
  final String? photoUrl;
  final bool? isOpenNow;

  /// Google Places の代表タイプ。分類品質の確認と再分類に使用する。
  final String? googlePrimaryType;

  /// Google Places の補助タイプ。Premium の代表ジャンル判定には直接使わない。
  final List<String> googleTypes;

  /// Swipeat 独自の分類結果。
  final RestaurantClassification? classification;
}
