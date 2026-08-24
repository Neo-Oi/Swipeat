import 'package:flutter_test/flutter_test.dart';
import 'package:swipeat/models/restaurant_classification.dart';
import 'package:swipeat/models/restaurant_genre.dart';

void main() {
  group('RestaurantGenreCatalog', () {
    test('contains every v1.0 genre with a stable id', () {
      expect(
        RestaurantGenreCatalog.definitions.length,
        RestaurantGenre.values.length,
      );

      final ids = RestaurantGenreCatalog.definitions
          .map((definition) => definition.id)
          .toSet();

      expect(ids.length, RestaurantGenre.values.length);
      expect(RestaurantGenreCatalog.findById('gyudon')?.label, '牛丼');
      expect(
        RestaurantGenreCatalog.findById('shabu_shabu')?.genre,
        RestaurantGenre.shabuShabu,
      );
    });

    test('groups provide the two-level Premium navigation data', () {
      expect(
        RestaurantGenreCatalog.detailsFor(RestaurantGenreGroup.japanese),
        hasLength(11),
      );
      expect(
        RestaurantGenreCatalog.detailsFor(
          RestaurantGenreGroup.noodles,
        ).map((definition) => definition.id),
        containsAll(<String>['ramen', 'tsukemen', 'udon', 'soba', 'pasta']),
      );
    });
  });

  group('RestaurantClassification', () {
    test('matches only primaryGenre, not subTags', () {
      const classification = RestaurantClassification(
        primaryGenre: RestaurantGenre.gyudon,
        subTags: [RestaurantGenre.curry, RestaurantGenre.teishoku],
      );

      expect(
        classification.matchesPrimaryGenre(RestaurantGenre.gyudon),
        isTrue,
      );
      expect(
        classification.matchesPrimaryGenre(RestaurantGenre.curry),
        isFalse,
      );
    });

    test('can represent an unknown primary genre safely', () {
      const classification = RestaurantClassification();

      expect(classification.primaryGenre, isNull);
      expect(
        classification.classificationSource,
        ClassificationSource.fallback,
      );
      expect(
        classification.matchesPrimaryGenre(RestaurantGenre.other),
        isFalse,
      );
    });
  });
}
