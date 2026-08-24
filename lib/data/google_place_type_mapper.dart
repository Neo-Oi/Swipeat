import '../models/restaurant_genre.dart';

/// Google Places の primaryType を Swipeat ジャンルへ変換するテーブル。
///
/// Google の汎用タイプや未知タイプは候補数のために推測せず、
/// [RestaurantGenre.other] に留める。
class GooglePlaceTypeMapper {
  const GooglePlaceTypeMapper._();

  static const Map<String, RestaurantGenre> _mappings = {
    'ramen_restaurant': RestaurantGenre.ramen,
    'sushi_restaurant': RestaurantGenre.sushi,
    'tonkatsu_restaurant': RestaurantGenre.tonkatsu,
    'yakiniku_restaurant': RestaurantGenre.yakiniku,
    'italian_restaurant': RestaurantGenre.italian,
    'hamburger_restaurant': RestaurantGenre.hamburger,
    'japanese_curry_restaurant': RestaurantGenre.curry,
    'japanese_restaurant': RestaurantGenre.japanese,
    'udon_restaurant': RestaurantGenre.udon,
    'soba_restaurant': RestaurantGenre.soba,
    'pasta_restaurant': RestaurantGenre.pasta,
    'french_restaurant': RestaurantGenre.french,
    'pizza_restaurant': RestaurantGenre.pizza,
    'chinese_restaurant': RestaurantGenre.chinese,
    'korean_restaurant': RestaurantGenre.korean,
    'thai_restaurant': RestaurantGenre.thai,
    'vietnamese_restaurant': RestaurantGenre.vietnamese,
    'indian_restaurant': RestaurantGenre.indian,
    'seafood_restaurant': RestaurantGenre.seafood,
    'cafe': RestaurantGenre.cafe,
    'bakery': RestaurantGenre.bakery,
    'dessert_shop': RestaurantGenre.dessert,
    'bar': RestaurantGenre.izakayaFood,
    'restaurant': RestaurantGenre.other,
    'meal_takeaway': RestaurantGenre.other,
    'meal_delivery': RestaurantGenre.other,
  };

  /// Returns the mapped genre, or `other` for an unrecognised non-null type.
  static RestaurantGenre map(String primaryType) {
    return _mappings[primaryType.trim().toLowerCase()] ?? RestaurantGenre.other;
  }

  /// Returns whether the value was explicitly listed in the mapper table.
  static bool hasMapping(String primaryType) {
    return _mappings.containsKey(primaryType.trim().toLowerCase());
  }
}
