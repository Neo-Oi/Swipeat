import 'package:flutter_test/flutter_test.dart';
import 'package:swipeat/data/google_place_type_mapper.dart';
import 'package:swipeat/models/restaurant_genre.dart';

void main() {
  group('GooglePlaceTypeMapper', () {
    test('maps specific primary types', () {
      expect(
        GooglePlaceTypeMapper.map('ramen_restaurant'),
        RestaurantGenre.ramen,
      );
      expect(
        GooglePlaceTypeMapper.map('sushi_restaurant'),
        RestaurantGenre.sushi,
      );
      expect(
        GooglePlaceTypeMapper.map('tonkatsu_restaurant'),
        RestaurantGenre.tonkatsu,
      );
      expect(
        GooglePlaceTypeMapper.map('yakiniku_restaurant'),
        RestaurantGenre.yakiniku,
      );
      expect(
        GooglePlaceTypeMapper.map('italian_restaurant'),
        RestaurantGenre.italian,
      );
      expect(
        GooglePlaceTypeMapper.map('hamburger_restaurant'),
        RestaurantGenre.hamburger,
      );
      expect(
        GooglePlaceTypeMapper.map('japanese_curry_restaurant'),
        RestaurantGenre.curry,
      );
    });

    test('maps generic and unknown types conservatively to other', () {
      expect(GooglePlaceTypeMapper.map('restaurant'), RestaurantGenre.other);
      expect(
        GooglePlaceTypeMapper.map('some_future_type'),
        RestaurantGenre.other,
      );
      expect(GooglePlaceTypeMapper.hasMapping('restaurant'), isTrue);
      expect(GooglePlaceTypeMapper.hasMapping('some_future_type'), isFalse);
    });

    test('normalizes case and surrounding whitespace', () {
      expect(
        GooglePlaceTypeMapper.map('  RAMEN_RESTAURANT '),
        RestaurantGenre.ramen,
      );
    });
  });
}
