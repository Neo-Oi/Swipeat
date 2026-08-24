import '../models/restaurant.dart';
import '../models/restaurant_genre.dart';

/// Premium のジャンル条件を候補へ適用する。
///
/// 代表ジャンルだけを判定に使うため、subTags のみ一致する店舗や未分類店舗を
/// 候補数確保のために混ぜない。
class PremiumCandidateFilter {
  const PremiumCandidateFilter();

  List<Restaurant> filter({
    required List<Restaurant> restaurants,
    required RestaurantGenre genre,
  }) {
    return restaurants
        .where(
          (restaurant) =>
              restaurant.classification?.matchesPrimaryGenre(genre) ?? false,
        )
        .toList(growable: false);
  }
}
