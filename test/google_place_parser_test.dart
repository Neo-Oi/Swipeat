import 'package:flutter_test/flutter_test.dart';
import 'package:swipeat/models/restaurant_genre.dart';
import 'package:swipeat/services/google_place_parser.dart';

void main() {
  const parser = GooglePlaceParser(apiKey: 'test-key');

  Map<String, dynamic> place({
    required String id,
    required String name,
    String primaryType = 'restaurant',
    List<String> types = const ['restaurant'],
  }) {
    return <String, dynamic>{
      'id': id,
      'displayName': <String, dynamic>{'text': name},
      'formattedAddress': '東京都テスト区1-1',
      'location': <String, dynamic>{'latitude': 35.0, 'longitude': 135.0},
      'primaryType': primaryType,
      'types': types,
      'rating': 4.2,
      'userRatingCount': 12,
      'currentOpeningHours': <String, dynamic>{'openNow': true},
    };
  }

  test('parses primaryType and classification into Restaurant', () {
    final restaurants = parser.parseMany(
      places: [
        place(
          id: 'ramen-1',
          name: '駅前のお店',
          primaryType: 'ramen_restaurant',
          types: const ['restaurant', 'ramen_restaurant'],
        ),
      ],
      originLatitude: 35.0,
      originLongitude: 135.0,
    );

    expect(restaurants, hasLength(1));
    expect(restaurants.single.googlePlaceId, 'ramen-1');
    expect(restaurants.single.googlePrimaryType, 'ramen_restaurant');
    expect(restaurants.single.googleTypes, contains('ramen_restaurant'));
    expect(
      restaurants.single.classification?.primaryGenre,
      RestaurantGenre.ramen,
    );
    expect(restaurants.single.isOpenNow, isTrue);
  });

  test('deduplicates the same place id and preserves unique places', () {
    final restaurants = parser.parseMany(
      places: [
        place(id: 'same', name: '同じ店舗'),
        place(id: 'same', name: '同じ店舗の重複'),
        place(id: 'other', name: '別店舗'),
      ],
      originLatitude: 35.0,
      originLongitude: 135.0,
    );

    expect(restaurants, hasLength(2));
    expect(restaurants.map((restaurant) => restaurant.googlePlaceId), [
      'same',
      'other',
    ]);
    expect(restaurants.first.name, '同じ店舗');
  });

  test('handles missing optional Place fields', () {
    final restaurants = parser.parseMany(
      places: [
        <String, dynamic>{
          'id': 'minimal',
          'displayName': <String, dynamic>{'text': '最小店舗'},
          'types': <String>[],
        },
      ],
      originLatitude: 35.0,
      originLongitude: 135.0,
    );

    expect(restaurants, hasLength(1));
    expect(restaurants.single.name, '最小店舗');
    expect(restaurants.single.distanceMeters, 0);
    expect(
      restaurants.single.classification?.primaryGenre,
      RestaurantGenre.other,
    );
  });
}
