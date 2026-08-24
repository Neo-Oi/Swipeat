import 'restaurant_classification.dart';
import 'restaurant_genre.dart';

/// Swipeat が補正に利用するチェーンブランドの定義。
class ChainBrandDefinition {
  const ChainBrandDefinition({
    required this.brand,
    required this.primaryGenre,
    required this.aliases,
    this.style = RestaurantStyle.unknown,
  });

  final String brand;
  final RestaurantGenre primaryGenre;
  final List<String> aliases;
  final RestaurantStyle style;

  bool get isChain => true;
}
