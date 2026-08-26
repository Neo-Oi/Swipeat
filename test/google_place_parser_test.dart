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
    List<Map<String, dynamic>> photos = const [],
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
      if (photos.isNotEmpty) 'photos': photos,
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

  test('keeps at most three photos and their author attributions', () {
    final restaurant = parser.parse(
      place: place(
        id: 'photo-place',
        name: '写真店舗',
        photos: [
          <String, dynamic>{
            'name': 'places/photo-place/photos/photo-1',
            'authorAttributions': [
              <String, dynamic>{
                'displayName': '投稿者A',
                'uri': 'https://example.test/author-a',
              },
            ],
          },
          <String, dynamic>{'name': 'places/photo-place/photos/photo-2'},
          <String, dynamic>{'name': 'places/photo-place/photos/photo-3'},
          <String, dynamic>{'name': 'places/photo-place/photos/photo-4'},
        ],
      ),
      originLatitude: 35.0,
      originLongitude: 135.0,
    );

    expect(restaurant.photos, hasLength(3));
    expect(restaurant.displayPhotos, hasLength(3));
    expect(restaurant.photos.first.url, contains('photo-1'));
    expect(
      restaurant.photos.first.authorAttributions.single.displayName,
      '投稿者A',
    );
    expect(restaurant.photos.last.url, contains('photo-3'));
  });
}
