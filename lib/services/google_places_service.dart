import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/restaurant.dart';
import 'google_place_parser.dart';

class GooglePlacesService {
  static const String _endpoint =
      'https://places.googleapis.com/v1/places:searchNearby';

  static const String _apiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');

  static Future<List<Restaurant>> searchNearbyRestaurants({
    required double latitude,
    required double longitude,
    required int radiusMeters,
    required String category,
    required bool openNowOnly,
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception(
        'GOOGLE_MAPS_API_KEY が未設定です。'
        'flutter run / flutter build 時に --dart-define=GOOGLE_MAPS_API_KEY=xxxxx を指定してください。',
      );
    }

    final includedTypes = _includedTypesForMoodLabel(category);

    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': _apiKey,
        'X-Goog-FieldMask':
            'places.id,places.displayName,places.formattedAddress,places.location,places.rating,places.userRatingCount,places.currentOpeningHours,places.primaryType,places.types,places.photos',
      },
      body: jsonEncode({
        if (includedTypes.isNotEmpty) 'includedTypes': includedTypes,
        if (openNowOnly) 'openNow': true,
        'maxResultCount': 20,
        'languageCode': 'ja',
        'rankPreference': 'DISTANCE',
        'locationRestriction': {
          'circle': {
            'center': {'latitude': latitude, 'longitude': longitude},
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
    return const GooglePlaceParser(apiKey: _apiKey).parseMany(
      places: places,
      originLatitude: latitude,
      originLongitude: longitude,
    );
  }

  static List<String> _includedTypesForMoodLabel(String moodLabel) {
    if (moodLabel == '気にしない') {
      return ['restaurant', 'cafe'];
    }

    final moods = moodLabel.split('・');
    final types = <String>{};

    for (final mood in moods) {
      types.addAll(_includedTypesForSingleMood(mood));
    }

    return types.toList();
  }

  static List<String> _includedTypesForSingleMood(String mood) {
    switch (mood) {
      case 'さっぱり':
        return ['japanese_restaurant', 'cafe'];
      case 'ガッツリ':
        return ['restaurant', 'chinese_restaurant', 'fast_food_restaurant'];
      case 'すぐ食べたい':
        return ['fast_food_restaurant', 'cafe'];
      case 'ゆっくりしたい':
        return ['cafe', 'restaurant'];
      case '軽め':
        return ['cafe', 'bakery'];
      case 'カフェ気分':
        return ['cafe', 'bakery'];
      default:
        return ['restaurant'];
    }
  }
}
