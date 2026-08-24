import '../models/chain_brand_definition.dart';
import '../models/restaurant_classification.dart';
import '../models/restaurant_genre.dart';

/// チェーンブランドの seed と名称マッチングを一元管理する。
///
/// 新しいチェーンは [definitions] にデータを追加するだけで登録できる。
/// 分類器に店舗名の巨大な if/else を持たせないための境界でもある。
class ChainBrandDictionary {
  const ChainBrandDictionary({this.definitions = seedDefinitions});

  static const seedDefinitions = <ChainBrandDefinition>[
    ChainBrandDefinition(
      brand: 'すき家',
      aliases: ['すき家', 'すきや'],
      primaryGenre: RestaurantGenre.gyudon,
      style: RestaurantStyle.fastFood,
    ),
    ChainBrandDefinition(
      brand: '吉野家',
      aliases: ['吉野家', 'よしの家'],
      primaryGenre: RestaurantGenre.gyudon,
      style: RestaurantStyle.fastFood,
    ),
    ChainBrandDefinition(
      brand: '松屋',
      aliases: ['松屋'],
      primaryGenre: RestaurantGenre.gyudon,
      style: RestaurantStyle.fastFood,
    ),
    ChainBrandDefinition(
      brand: '松のや',
      aliases: ['松のや', '松ノや', '松乃家'],
      primaryGenre: RestaurantGenre.tonkatsu,
      style: RestaurantStyle.fastFood,
    ),
    ChainBrandDefinition(
      brand: '一蘭',
      aliases: ['一蘭', 'いちらん'],
      primaryGenre: RestaurantGenre.ramen,
      style: RestaurantStyle.specialty,
    ),
    ChainBrandDefinition(
      brand: '丸亀製麺',
      aliases: ['丸亀製麺', '丸亀製麺所'],
      primaryGenre: RestaurantGenre.udon,
      style: RestaurantStyle.fastFood,
    ),
    ChainBrandDefinition(
      brand: 'スシロー',
      aliases: ['スシロー', 'あきんどスシロー'],
      primaryGenre: RestaurantGenre.sushi,
      style: RestaurantStyle.fastFood,
    ),
    ChainBrandDefinition(
      brand: 'CoCo壱番屋',
      aliases: ['CoCo壱番屋', 'coco壱番屋', 'ココイチ', 'CoCo壱'],
      primaryGenre: RestaurantGenre.curry,
      style: RestaurantStyle.fastFood,
    ),
    ChainBrandDefinition(
      brand: 'マクドナルド',
      aliases: ['マクドナルド', 'マック', 'マクド'],
      primaryGenre: RestaurantGenre.hamburger,
      style: RestaurantStyle.fastFood,
    ),
    ChainBrandDefinition(
      brand: 'びっくりドンキー',
      aliases: ['びっくりドンキー', 'びっくりどんきー'],
      primaryGenre: RestaurantGenre.hamburg,
      style: RestaurantStyle.familyRestaurant,
    ),
    ChainBrandDefinition(
      brand: 'サイゼリヤ',
      aliases: ['サイゼリヤ', 'サイゼリア'],
      primaryGenre: RestaurantGenre.italian,
      style: RestaurantStyle.familyRestaurant,
    ),
    ChainBrandDefinition(
      brand: '餃子の王将',
      aliases: ['餃子の王将', '餃子王将'],
      primaryGenre: RestaurantGenre.gyoza,
      style: RestaurantStyle.casualDining,
    ),
    ChainBrandDefinition(
      brand: '大阪王将',
      aliases: ['大阪王将'],
      primaryGenre: RestaurantGenre.gyoza,
      style: RestaurantStyle.casualDining,
    ),
    ChainBrandDefinition(
      brand: '焼肉きんぐ',
      aliases: ['焼肉きんぐ', '焼肉キング'],
      primaryGenre: RestaurantGenre.yakiniku,
      style: RestaurantStyle.buffet,
    ),
  ];

  final List<ChainBrandDefinition> definitions;

  /// 店舗名に含まれるブランドを返す。
  ///
  /// 長い別名を先に照合するため、より具体的なブランド名が一般的な
  /// 部分一致に負けない。結果は辞書の定義そのものであり、分類結果の
  /// source は後続の [RestaurantClassifier] が付与する。
  ChainBrandDefinition? findByPlaceName(String placeName) {
    final normalizedPlaceName = _normalize(placeName);
    if (normalizedPlaceName.isEmpty) return null;

    final candidates = <_AliasCandidate>[];
    for (final definition in definitions) {
      for (final alias in definition.aliases) {
        final normalizedAlias = _normalize(alias);
        if (normalizedAlias.isNotEmpty &&
            normalizedPlaceName.contains(normalizedAlias)) {
          candidates.add(
            _AliasCandidate(
              definition: definition,
              aliasLength: normalizedAlias.length,
            ),
          );
        }
      }
    }

    if (candidates.isEmpty) return null;

    candidates.sort((a, b) => b.aliasLength.compareTo(a.aliasLength));
    return candidates.first.definition;
  }

  static String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(
      RegExp(r'[\s・･.,，。!！?？:：;；()（）\[\]【】_\-‐‑–—]'),
      '',
    );
  }
}

class _AliasCandidate {
  const _AliasCandidate({required this.definition, required this.aliasLength});

  final ChainBrandDefinition definition;
  final int aliasLength;
}
