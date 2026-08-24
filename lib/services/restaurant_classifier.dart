import 'package:flutter/foundation.dart';

import '../data/chain_brand_dictionary.dart';
import '../data/google_place_type_mapper.dart';
import '../models/restaurant_classification.dart';
import '../models/restaurant_genre.dart';

/// Places の1店舗を Swipeat の分類へ変換した結果。
class RestaurantClassificationResult {
  const RestaurantClassificationResult({
    required this.placeName,
    required this.classification,
    this.placeId,
    this.googlePrimaryType,
    this.googleTypes = const [],
  });

  final String placeName;
  final String? placeId;
  final String? googlePrimaryType;
  final List<String> googleTypes;
  final RestaurantClassification classification;

  /// Debug ビルドで分類品質を確認するための、位置情報を含まない値。
  Map<String, Object?> toDebugMap() {
    return <String, Object?>{
      'placeName': placeName,
      'placeId': placeId,
      'googlePrimaryType': googlePrimaryType,
      'googleTypes': googleTypes,
      'matchedBrand': classification.brand,
      'primaryGenre': classification.primaryGenre?.name,
      'classificationSource': classification.classificationSource.name,
    };
  }

  /// Debug ビルドでのみ分類情報をログへ出す。
  void logDebug() {
    if (!kDebugMode) return;
    debugPrint(toDebugMap().toString());
  }
}

/// Google の曖昧な分類を Swipeat の代表ジャンルへ補正する。
///
/// 優先順位は、チェーン辞書 → 店舗名の高信頼度ヒント →
/// Google primaryType → Google types → other とする。
class RestaurantClassifier {
  const RestaurantClassifier({
    this.chainBrandDictionary = const ChainBrandDictionary(),
  });

  final ChainBrandDictionary chainBrandDictionary;

  static const _nameHints = <_NameGenreHint>[
    _NameGenreHint('しゃぶしゃぶ', RestaurantGenre.shabuShabu),
    _NameGenreHint('お好み焼き', RestaurantGenre.okonomiyaki),
    _NameGenreHint('ハンバーガー', RestaurantGenre.hamburger),
    _NameGenreHint('ハンバーグ', RestaurantGenre.hamburg),
    _NameGenreHint('インドカレー', RestaurantGenre.indianCurry),
    _NameGenreHint('ベトナム', RestaurantGenre.vietnamese),
    _NameGenreHint('イタリアン', RestaurantGenre.italian),
    _NameGenreHint('フレンチ', RestaurantGenre.french),
    _NameGenreHint('焼き鳥', RestaurantGenre.yakitori),
    _NameGenreHint('とんかつ', RestaurantGenre.tonkatsu),
    _NameGenreHint('串カツ', RestaurantGenre.kushikatsu),
    _NameGenreHint('焼肉', RestaurantGenre.yakiniku),
    _NameGenreHint('ステーキ', RestaurantGenre.steak),
    _NameGenreHint('ラーメン', RestaurantGenre.ramen),
    _NameGenreHint('つけ麺', RestaurantGenre.tsukemen),
    _NameGenreHint('うどん', RestaurantGenre.udon),
    _NameGenreHint('そば', RestaurantGenre.soba),
    _NameGenreHint('パスタ', RestaurantGenre.pasta),
    _NameGenreHint('寿司', RestaurantGenre.sushi),
    _NameGenreHint('すし', RestaurantGenre.sushi),
    _NameGenreHint('天ぷら', RestaurantGenre.tempura),
    _NameGenreHint('天丼', RestaurantGenre.donburi),
    _NameGenreHint('牛丼', RestaurantGenre.gyudon),
    _NameGenreHint('海鮮', RestaurantGenre.seafood),
    _NameGenreHint('餃子', RestaurantGenre.gyoza),
    _NameGenreHint('カレー', RestaurantGenre.curry),
    _NameGenreHint('ピザ', RestaurantGenre.pizza),
    _NameGenreHint('たこ焼き', RestaurantGenre.takoyaki),
    _NameGenreHint('うなぎ', RestaurantGenre.unagi),
    _NameGenreHint('カフェ', RestaurantGenre.cafe),
    _NameGenreHint('ベーカリー', RestaurantGenre.bakery),
    _NameGenreHint('パン屋', RestaurantGenre.bakery),
    _NameGenreHint('スイーツ', RestaurantGenre.dessert),
  ];

  RestaurantClassificationResult classify({
    required String placeName,
    String? placeId,
    String? googlePrimaryType,
    List<String> googleTypes = const [],
  }) {
    final chain = chainBrandDictionary.findByPlaceName(placeName);
    if (chain != null) {
      return _result(
        placeName: placeName,
        placeId: placeId,
        googlePrimaryType: googlePrimaryType,
        googleTypes: googleTypes,
        primaryGenre: chain.primaryGenre,
        style: chain.style,
        brand: chain.brand,
        isChain: true,
        source: ClassificationSource.chainDictionary,
      );
    }

    final nameHint = _findNameHint(placeName);
    if (nameHint != null) {
      return _result(
        placeName: placeName,
        placeId: placeId,
        googlePrimaryType: googlePrimaryType,
        googleTypes: googleTypes,
        primaryGenre: nameHint.genre,
        subTags: _subTags(googleTypes, excluding: nameHint.genre),
        source: ClassificationSource.businessName,
      );
    }

    final normalizedPrimaryType = googlePrimaryType?.trim().toLowerCase();
    if (normalizedPrimaryType != null && normalizedPrimaryType.isNotEmpty) {
      final primaryGenre = GooglePlaceTypeMapper.map(normalizedPrimaryType);
      if (primaryGenre != RestaurantGenre.other) {
        return _result(
          placeName: placeName,
          placeId: placeId,
          googlePrimaryType: googlePrimaryType,
          googleTypes: googleTypes,
          primaryGenre: primaryGenre,
          subTags: _subTags(googleTypes, excluding: primaryGenre),
          source: ClassificationSource.googlePrimaryType,
        );
      }
    }

    for (final googleType in googleTypes) {
      if (!GooglePlaceTypeMapper.hasMapping(googleType)) continue;

      final genre = GooglePlaceTypeMapper.map(googleType);
      if (genre == RestaurantGenre.other) continue;

      return _result(
        placeName: placeName,
        placeId: placeId,
        googlePrimaryType: googlePrimaryType,
        googleTypes: googleTypes,
        primaryGenre: genre,
        subTags: _subTags(googleTypes, excluding: genre),
        source: ClassificationSource.googleTypes,
      );
    }

    final hasUsablePrimaryType =
        normalizedPrimaryType != null &&
        normalizedPrimaryType.isNotEmpty &&
        GooglePlaceTypeMapper.hasMapping(normalizedPrimaryType);

    return _result(
      placeName: placeName,
      placeId: placeId,
      googlePrimaryType: googlePrimaryType,
      googleTypes: googleTypes,
      primaryGenre: RestaurantGenre.other,
      source: hasUsablePrimaryType
          ? ClassificationSource.googlePrimaryType
          : ClassificationSource.fallback,
    );
  }

  RestaurantClassificationResult _result({
    required String placeName,
    required String? placeId,
    required String? googlePrimaryType,
    required List<String> googleTypes,
    required RestaurantGenre primaryGenre,
    required ClassificationSource source,
    List<RestaurantGenre> subTags = const [],
    RestaurantStyle style = RestaurantStyle.unknown,
    String? brand,
    bool isChain = false,
  }) {
    return RestaurantClassificationResult(
      placeName: placeName,
      placeId: placeId,
      googlePrimaryType: googlePrimaryType,
      googleTypes: List<String>.unmodifiable(googleTypes),
      classification: RestaurantClassification(
        primaryGenre: primaryGenre,
        subTags: List<RestaurantGenre>.unmodifiable(subTags),
        style: style,
        brand: brand,
        isChain: isChain,
        classificationSource: source,
      ),
    );
  }

  _NameGenreHint? _findNameHint(String placeName) {
    final normalizedName = _normalize(placeName);
    for (final hint in _nameHints) {
      if (normalizedName.contains(_normalize(hint.text))) return hint;
    }
    return null;
  }

  List<RestaurantGenre> _subTags(
    List<String> googleTypes, {
    required RestaurantGenre excluding,
  }) {
    final tags = <RestaurantGenre>[];
    for (final type in googleTypes) {
      final genre = GooglePlaceTypeMapper.map(type);
      if (genre == RestaurantGenre.other || genre == excluding) continue;
      if (!tags.contains(genre)) tags.add(genre);
    }
    return tags;
  }

  static String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(
      RegExp(r'[\s・･.,，。!！?？:：;；()（）\[\]【】_\-‐‑–—]'),
      '',
    );
  }
}

class _NameGenreHint {
  const _NameGenreHint(this.text, this.genre);

  final String text;
  final RestaurantGenre genre;
}
