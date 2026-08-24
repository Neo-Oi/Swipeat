import 'restaurant_genre.dart';

/// 店舗の形態。料理ジャンルとは独立して扱う。
enum RestaurantStyle {
  fastFood,
  familyRestaurant,
  specialty,
  casualDining,
  cafe,
  izakaya,
  buffet,
  takeoutDelivery,
  unknown,
}

/// 店舗分類を決定した情報源。
enum ClassificationSource {
  chainDictionary,
  businessName,
  googlePrimaryType,
  googleTypes,
  fallback,
}

/// Premium 検索で利用する店舗分類。
class RestaurantClassification {
  const RestaurantClassification({
    this.primaryGenre,
    this.subTags = const [],
    this.style = RestaurantStyle.unknown,
    this.brand,
    this.isChain = false,
    this.classificationSource = ClassificationSource.fallback,
  });

  /// Premium 検索で参照する代表ジャンル。店舗につき最大1つ。
  final RestaurantGenre? primaryGenre;

  /// 補助的な料理情報。Premium の代表ジャンル一致には使用しない。
  final List<RestaurantGenre> subTags;

  final RestaurantStyle style;
  final String? brand;
  final bool isChain;
  final ClassificationSource classificationSource;

  bool matchesPrimaryGenre(RestaurantGenre genre) {
    return primaryGenre == genre;
  }

  RestaurantClassification copyWith({
    RestaurantGenre? primaryGenre,
    List<RestaurantGenre>? subTags,
    RestaurantStyle? style,
    String? brand,
    bool? isChain,
    ClassificationSource? classificationSource,
  }) {
    return RestaurantClassification(
      primaryGenre: primaryGenre ?? this.primaryGenre,
      subTags: subTags ?? this.subTags,
      style: style ?? this.style,
      brand: brand ?? this.brand,
      isChain: isChain ?? this.isChain,
      classificationSource: classificationSource ?? this.classificationSource,
    );
  }
}
