import 'package:flutter_test/flutter_test.dart';
import 'package:swipeat/models/restaurant_classification.dart';
import 'package:swipeat/models/restaurant_genre.dart';
import 'package:swipeat/services/restaurant_classifier.dart';

void main() {
  const classifier = RestaurantClassifier();

  group('RestaurantClassifier', () {
    test('uses the chain dictionary before all fallbacks', () {
      final result = classifier.classify(
        placeName: 'すき家 京都店',
        googlePrimaryType: 'restaurant',
        googleTypes: const ['ramen_restaurant'],
      );

      expect(result.classification.primaryGenre, RestaurantGenre.gyudon);
      expect(result.classification.brand, 'すき家');
      expect(result.classification.isChain, isTrue);
      expect(
        result.classification.classificationSource,
        ClassificationSource.chainDictionary,
      );
    });

    test('uses a high-confidence name hint before Google types', () {
      final result = classifier.classify(
        placeName: 'ラーメン研究所',
        googlePrimaryType: 'restaurant',
        googleTypes: const ['cafe'],
      );

      expect(result.classification.primaryGenre, RestaurantGenre.ramen);
      expect(
        result.classification.classificationSource,
        ClassificationSource.businessName,
      );
      expect(result.classification.subTags, contains(RestaurantGenre.cafe));
    });

    test('uses Google primaryType when the name is not informative', () {
      final result = classifier.classify(
        placeName: '駅前のお店',
        googlePrimaryType: 'ramen_restaurant',
      );

      expect(result.classification.primaryGenre, RestaurantGenre.ramen);
      expect(
        result.classification.classificationSource,
        ClassificationSource.googlePrimaryType,
      );
    });

    test('uses a specific Google type when primaryType is generic', () {
      final result = classifier.classify(
        placeName: '駅前のお店',
        googlePrimaryType: 'restaurant',
        googleTypes: const ['restaurant', 'sushi_restaurant'],
      );

      expect(result.classification.primaryGenre, RestaurantGenre.sushi);
      expect(
        result.classification.classificationSource,
        ClassificationSource.googleTypes,
      );
    });

    test('falls back to other for generic or missing classifications', () {
      final generic = classifier.classify(
        placeName: '駅前のお店',
        googlePrimaryType: 'restaurant',
      );
      final unknown = classifier.classify(placeName: '駅前のお店');

      expect(generic.classification.primaryGenre, RestaurantGenre.other);
      expect(
        generic.classification.classificationSource,
        ClassificationSource.googlePrimaryType,
      );
      expect(unknown.classification.primaryGenre, RestaurantGenre.other);
      expect(
        unknown.classification.classificationSource,
        ClassificationSource.fallback,
      );
    });

    test('exposes the required debug fields without location data', () {
      final result = classifier.classify(
        placeName: 'テスト店舗',
        placeId: 'place-123',
        googlePrimaryType: 'restaurant',
        googleTypes: const ['restaurant'],
      );

      expect(result.toDebugMap(), containsPair('placeName', 'テスト店舗'));
      expect(result.toDebugMap(), containsPair('placeId', 'place-123'));
      expect(
        result.toDebugMap(),
        containsPair('googlePrimaryType', 'restaurant'),
      );
      expect(result.toDebugMap(), containsPair('primaryGenre', 'other'));
      expect(
        result.toDebugMap(),
        containsPair('classificationSource', 'googlePrimaryType'),
      );
      expect(result.toDebugMap().containsKey('latitude'), isFalse);
    });
  });
}
