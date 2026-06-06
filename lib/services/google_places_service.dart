import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/restaurant.dart';
import '../utils/distance_calculator.dart';

class GooglePlacesService {
  static const String _endpoint =
      'https://places.googleapis.com/v1/places:searchNearby';

  static Future<List<Restaurant>> searchNearbyRestaurants({
    required double latitude,
    required double longitude,
    required int radiusMeters,
    required String category,
    required bool openNowOnly,
  }) async {
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GOOGLE_MAPS_API_KEY が .env に設定されていません');
    }

    final includedTypes = _includedTypesForCategory(category);

    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': apiKey,
        'X-Goog-FieldMask':
            'places.id,places.displayName,places.formattedAddress,places.location,places.rating,places.userRatingCount,places.currentOpeningHours,places.types,places.photos',
      },
      body: jsonEncode({
        if (includedTypes.isNotEmpty) 'includedTypes': includedTypes,
        if (openNowOnly) 'openNow': true,
        'maxResultCount': 20,
        'languageCode': 'ja',
        'rankPreference': 'DISTANCE',
        'locationRestriction': {
          'circle': {
            'center': {
              'latitude': latitude,
              'longitude': longitude,
            },
            'radius': radiusMeters.toDouble(),
          },
        },
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Google Places API error: ${response.statusCode} ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final places = decoded['places'] as List<dynamic>? ?? [];

    return places.map((place) {
      final placeMap = place as Map<String, dynamic>;

      final location = placeMap['location'] as Map<String, dynamic>?;
      final placeLatitude = (location?['latitude'] as num?)?.toDouble();
      final placeLongitude = (location?['longitude'] as num?)?.toDouble();

      final distanceMeters = placeLatitude != null && placeLongitude != null
          ? DistanceCalculator.calculateDistanceMeters(
              fromLatitude: latitude,
              fromLongitude: longitude,
              toLatitude: placeLatitude,
              toLongitude: placeLongitude,
            )
          : 0;

      final types = (placeMap['types'] as List<dynamic>? ?? [])
          .map((type) => type.toString())
          .toList();

      final photos = placeMap['photos'] as List<dynamic>? ?? [];
      final firstPhoto =
          photos.isNotEmpty ? photos.first as Map<String, dynamic> : null;
      final photoName = firstPhoto?['name']?.toString();

      final photoUrl = photoName == null
          ? null
          : 'https://places.googleapis.com/v1/$photoName/media'
              '?maxHeightPx=600'
              '&maxWidthPx=800'
              '&key=$apiKey';

      return Restaurant(
        name: placeMap['displayName']?['text']?.toString() ?? '名称不明',
        tags: _tagsFromTypes(types),
        budget: '価格情報なし',
        description: 'Google Maps から取得した周辺店舗です。',
        companions: const ['一人', '友達', '恋人', '家族', '職場'],
        budgets: const ['〜1000円', '1000〜2000円', '2000〜3000円', '気にしない'],
        distanceMeters: distanceMeters,
        categories: _categoriesFromTypes(types),
        googlePlaceId: placeMap['id']?.toString(),
        address: placeMap['formattedAddress']?.toString(),
        latitude: placeLatitude,
        longitude: placeLongitude,
        rating: (placeMap['rating'] as num?)?.toDouble(),
        userRatingCount: (placeMap['userRatingCount'] as num?)?.toInt(),
        photoUrl: photoUrl,
        isOpenNow: placeMap['currentOpeningHours']?['openNow'] as bool?,
      );
    }).toList();
  }

  static List<String> _includedTypesForCategory(String category) {
    switch (category) {
      case '和食':
        return ['japanese_restaurant'];
      case '洋食':
        return ['italian_restaurant', 'american_restaurant'];
      case '中華':
        return ['chinese_restaurant'];
      case 'カフェ':
        return ['cafe'];
      case 'ファストフード':
        return ['fast_food_restaurant'];
      case '気にしない':
        return ['restaurant', 'cafe'];
      default:
        return ['restaurant'];
    }
  }

  static List<String> _categoriesFromTypes(List<String> types) {
    if (types.contains('japanese_restaurant')) return ['和食'];
    if (types.contains('italian_restaurant') ||
        types.contains('american_restaurant')) {
      return ['洋食'];
    }
    if (types.contains('chinese_restaurant')) return ['中華'];
    if (types.contains('cafe')) return ['カフェ'];
    if (types.contains('fast_food_restaurant')) return ['ファストフード'];
    return ['その他'];
  }

  static List<String> _tagsFromTypes(List<String> types) {
    final tags = <String>[];

    if (types.contains('cafe')) tags.add('カフェ');
    if (types.contains('restaurant')) tags.add('飲食店');
    if (types.contains('japanese_restaurant')) tags.add('和食');
    if (types.contains('chinese_restaurant')) tags.add('中華');
    if (types.contains('italian_restaurant')) tags.add('イタリアン');
    if (types.contains('american_restaurant')) tags.add('洋食');
    if (types.contains('fast_food_restaurant')) tags.add('短時間');

    if (tags.isEmpty) tags.add('周辺店舗');

    return tags;
  }
}