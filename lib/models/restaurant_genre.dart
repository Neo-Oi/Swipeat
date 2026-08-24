/// Swipeat が検索条件として扱う独自ジャンル。
///
/// Google Places の `types` とは別の安定した ID として扱う。表示名や
/// 大分類は [RestaurantGenreCatalog] に集約し、UI や分類器へ散在させない。
enum RestaurantGenre {
  gyudon,
  donburi,
  teishoku,
  sushi,
  tempura,
  tonkatsu,
  yakitori,
  unagi,
  okonomiyaki,
  takoyaki,
  japanese,
  ramen,
  tsukemen,
  udon,
  soba,
  pasta,
  yakiniku,
  steak,
  hamburg,
  shabuShabu,
  sukiyaki,
  kushikatsu,
  italian,
  french,
  western,
  pizza,
  hamburger,
  curry,
  indianCurry,
  chinese,
  gyoza,
  korean,
  thai,
  vietnamese,
  indian,
  ethnic,
  cafe,
  bakery,
  dessert,
  seafood,
  izakayaFood,
  other,
}

/// Premium ジャンル UI の大分類。
enum RestaurantGenreGroup {
  japanese,
  noodles,
  meat,
  western,
  curry,
  chineseAsian,
  cafeLightOther,
}

/// ジャンルの安定した表示・検索定義。
class RestaurantGenreDefinition {
  const RestaurantGenreDefinition({
    required this.genre,
    required this.id,
    required this.label,
    required this.group,
  });

  final RestaurantGenre genre;
  final String id;
  final String label;
  final RestaurantGenreGroup group;
}

/// Swipeat 独自ジャンルの唯一の定義元。
class RestaurantGenreCatalog {
  const RestaurantGenreCatalog._();

  static const definitions = <RestaurantGenreDefinition>[
    // 和食
    RestaurantGenreDefinition(
      genre: RestaurantGenre.gyudon,
      id: 'gyudon',
      label: '牛丼',
      group: RestaurantGenreGroup.japanese,
    ),
    RestaurantGenreDefinition(
      genre: RestaurantGenre.donburi,
      id: 'donburi',
      label: '丼もの',
      group: RestaurantGenreGroup.japanese,
    ),
    RestaurantGenreDefinition(
      genre: RestaurantGenre.teishoku,
      id: 'teishoku',
      label: '定食・食堂',
      group: RestaurantGenreGroup.japanese,
    ),
    RestaurantGenreDefinition(
      genre: RestaurantGenre.sushi,
      id: 'sushi',
      label: '寿司',
      group: RestaurantGenreGroup.japanese,
    ),
    RestaurantGenreDefinition(
      genre: RestaurantGenre.tempura,
      id: 'tempura',
      label: '天ぷら',
      group: RestaurantGenreGroup.japanese,
    ),
    RestaurantGenreDefinition(
      genre: RestaurantGenre.tonkatsu,
      id: 'tonkatsu',
      label: 'とんかつ',
      group: RestaurantGenreGroup.japanese,
    ),
    RestaurantGenreDefinition(
      genre: RestaurantGenre.yakitori,
      id: 'yakitori',
      label: '焼き鳥',
      group: RestaurantGenreGroup.japanese,
    ),
    RestaurantGenreDefinition(
      genre: RestaurantGenre.unagi,
      id: 'unagi',
      label: 'うなぎ',
      group: RestaurantGenreGroup.japanese,
    ),
    RestaurantGenreDefinition(
      genre: RestaurantGenre.okonomiyaki,
      id: 'okonomiyaki',
      label: 'お好み焼き',
      group: RestaurantGenreGroup.japanese,
    ),
    RestaurantGenreDefinition(
      genre: RestaurantGenre.takoyaki,
      id: 'takoyaki',
      label: 'たこ焼き',
      group: RestaurantGenreGroup.japanese,
    ),
    RestaurantGenreDefinition(
      genre: RestaurantGenre.japanese,
      id: 'japanese',
      label: 'その他和食',
      group: RestaurantGenreGroup.japanese,
    ),

    // 麺類
    RestaurantGenreDefinition(
      genre: RestaurantGenre.ramen,
      id: 'ramen',
      label: 'ラーメン',
      group: RestaurantGenreGroup.noodles,
    ),
    RestaurantGenreDefinition(
      genre: RestaurantGenre.tsukemen,
      id: 'tsukemen',
      label: 'つけ麺',
      group: RestaurantGenreGroup.noodles,
    ),
    RestaurantGenreDefinition(
      genre: RestaurantGenre.udon,
      id: 'udon',
      label: 'うどん',
      group: RestaurantGenreGroup.noodles,
    ),
    RestaurantGenreDefinition(
      genre: RestaurantGenre.soba,
      id: 'soba',
      label: 'そば',
      group: RestaurantGenreGroup.noodles,
    ),
    RestaurantGenreDefinition(
      genre: RestaurantGenre.pasta,
      id: 'pasta',
      label: 'パスタ',
      group: RestaurantGenreGroup.noodles,
    ),

    // 肉料理
    RestaurantGenreDefinition(
      genre: RestaurantGenre.yakiniku,
      id: 'yakiniku',
      label: '焼肉',
      group: RestaurantGenreGroup.meat,
    ),
    RestaurantGenreDefinition(
      genre: RestaurantGenre.steak,
      id: 'steak',
      label: 'ステーキ',
      group: RestaurantGenreGroup.meat,
    ),
    RestaurantGenreDefinition(
      genre: RestaurantGenre.hamburg,
      id: 'hamburg',
      label: 'ハンバーグ',
      group: RestaurantGenreGroup.meat,
    ),
    RestaurantGenreDefinition(
      genre: RestaurantGenre.shabuShabu,
      id: 'shabu_shabu',
      label: 'しゃぶしゃぶ',
      group: RestaurantGenreGroup.meat,
    ),
    RestaurantGenreDefinition(
      genre: RestaurantGenre.sukiyaki,
      id: 'sukiyaki',
      label: 'すき焼き',
      group: RestaurantGenreGroup.meat,
    ),
    RestaurantGenreDefinition(
      genre: RestaurantGenre.kushikatsu,
      id: 'kushikatsu',
      label: '串カツ・串揚げ',
      group: RestaurantGenreGroup.meat,
    ),

    // 洋食
    RestaurantGenreDefinition(
      genre: RestaurantGenre.italian,
      id: 'italian',
      label: 'イタリアン',
      group: RestaurantGenreGroup.western,
    ),
    RestaurantGenreDefinition(
      genre: RestaurantGenre.french,
      id: 'french',
      label: 'フレンチ',
      group: RestaurantGenreGroup.western,
    ),
    RestaurantGenreDefinition(
      genre: RestaurantGenre.western,
      id: 'western',
      label: '洋食',
      group: RestaurantGenreGroup.western,
    ),
    RestaurantGenreDefinition(
      genre: RestaurantGenre.pizza,
      id: 'pizza',
      label: 'ピザ',
      group: RestaurantGenreGroup.western,
    ),
    RestaurantGenreDefinition(
      genre: RestaurantGenre.hamburger,
      id: 'hamburger',
      label: 'ハンバーガー',
      group: RestaurantGenreGroup.western,
    ),

    // カレー
    RestaurantGenreDefinition(
      genre: RestaurantGenre.curry,
      id: 'curry',
      label: 'カレー',
      group: RestaurantGenreGroup.curry,
    ),
    RestaurantGenreDefinition(
      genre: RestaurantGenre.indianCurry,
      id: 'indian_curry',
      label: 'インド・ネパールカレー',
      group: RestaurantGenreGroup.curry,
    ),

    // 中華・アジア
    RestaurantGenreDefinition(
      genre: RestaurantGenre.chinese,
      id: 'chinese',
      label: '中華料理',
      group: RestaurantGenreGroup.chineseAsian,
    ),
    RestaurantGenreDefinition(
      genre: RestaurantGenre.gyoza,
      id: 'gyoza',
      label: '餃子',
      group: RestaurantGenreGroup.chineseAsian,
    ),
    RestaurantGenreDefinition(
      genre: RestaurantGenre.korean,
      id: 'korean',
      label: '韓国料理',
      group: RestaurantGenreGroup.chineseAsian,
    ),
    RestaurantGenreDefinition(
      genre: RestaurantGenre.thai,
      id: 'thai',
      label: 'タイ料理',
      group: RestaurantGenreGroup.chineseAsian,
    ),
    RestaurantGenreDefinition(
      genre: RestaurantGenre.vietnamese,
      id: 'vietnamese',
      label: 'ベトナム料理',
      group: RestaurantGenreGroup.chineseAsian,
    ),
    RestaurantGenreDefinition(
      genre: RestaurantGenre.indian,
      id: 'indian',
      label: 'インド料理',
      group: RestaurantGenreGroup.chineseAsian,
    ),
    RestaurantGenreDefinition(
      genre: RestaurantGenre.ethnic,
      id: 'ethnic',
      label: 'その他エスニック',
      group: RestaurantGenreGroup.chineseAsian,
    ),

    // カフェ・軽食・その他
    RestaurantGenreDefinition(
      genre: RestaurantGenre.cafe,
      id: 'cafe',
      label: 'カフェ',
      group: RestaurantGenreGroup.cafeLightOther,
    ),
    RestaurantGenreDefinition(
      genre: RestaurantGenre.bakery,
      id: 'bakery',
      label: 'パン・ベーカリー',
      group: RestaurantGenreGroup.cafeLightOther,
    ),
    RestaurantGenreDefinition(
      genre: RestaurantGenre.dessert,
      id: 'dessert',
      label: 'スイーツ',
      group: RestaurantGenreGroup.cafeLightOther,
    ),
    RestaurantGenreDefinition(
      genre: RestaurantGenre.seafood,
      id: 'seafood',
      label: '海鮮料理',
      group: RestaurantGenreGroup.cafeLightOther,
    ),
    RestaurantGenreDefinition(
      genre: RestaurantGenre.izakayaFood,
      id: 'izakaya_food',
      label: '居酒屋',
      group: RestaurantGenreGroup.cafeLightOther,
    ),
    RestaurantGenreDefinition(
      genre: RestaurantGenre.other,
      id: 'other',
      label: 'その他',
      group: RestaurantGenreGroup.cafeLightOther,
    ),
  ];

  static final Map<RestaurantGenre, RestaurantGenreDefinition> _byGenre = {
    for (final definition in definitions) definition.genre: definition,
  };

  static final Map<String, RestaurantGenreDefinition> _byId = {
    for (final definition in definitions) definition.id: definition,
  };

  static RestaurantGenreDefinition definitionFor(RestaurantGenre genre) {
    return _byGenre[genre]!;
  }

  static RestaurantGenreDefinition? findById(String id) {
    return _byId[id];
  }

  static List<RestaurantGenreDefinition> detailsFor(
    RestaurantGenreGroup group,
  ) {
    return definitions
        .where((definition) => definition.group == group)
        .toList(growable: false);
  }
}
