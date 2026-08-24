import '../models/restaurant.dart';
import '../services/restaurant_classifier.dart';
import '../utils/distance_calculator.dart';

/// Google Places API のレスポンスをアプリの Restaurant へ変換する。
///
/// HTTP 通信から分離しているため、実ネットワークなしで FieldMask の応答形を
/// 決定的にテストできる。
class GooglePlaceParser {
  const GooglePlaceParser({
    required this.apiKey,
    this.classifier = const RestaurantClassifier(),
  });

  final String apiKey;
  final RestaurantClassifier classifier;

  Restaurant parse({
    required Map<String, dynamic> place,
    required double originLatitude,
    required double originLongitude,
  }) {
    final location = place['location'] as Map<String, dynamic>?;
    final placeLatitude = (location?['latitude'] as num?)?.toDouble();
    final placeLongitude = (location?['longitude'] as num?)?.toDouble();

    final distanceMeters = placeLatitude != null && placeLongitude != null
        ? DistanceCalculator.calculateDistanceMeters(
            fromLatitude: originLatitude,
            fromLongitude: originLongitude,
            toLatitude: placeLatitude,
            toLongitude: placeLongitude,
          )
        : 0;

    final types = (place['types'] as List<dynamic>? ?? [])
        .map((type) => type.toString())
        .toList(growable: false);
    final placeId = place['id']?.toString();
    final name = place['displayName']?['text']?.toString() ?? '名称不明';
    final primaryType = place['primaryType']?.toString();
    final classificationResult = classifier.classify(
      placeName: name,
      placeId: placeId,
      googlePrimaryType: primaryType,
      googleTypes: types,
    );
    classificationResult.logDebug();

    final photos = place['photos'] as List<dynamic>? ?? [];
    final firstPhoto = photos.isNotEmpty
        ? photos.first as Map<String, dynamic>
        : null;
    final photoName = firstPhoto?['name']?.toString();
    final photoUrl = photoName == null
        ? null
        : 'https://places.googleapis.com/v1/$photoName/media'
              '?maxHeightPx=600'
              '&maxWidthPx=800'
              '&key=$apiKey';

    return Restaurant(
      name: name,
      tags: _tagsFromTypes(types),
      budget: '価格情報なし',
      description: 'Google Maps から取得した周辺店舗です。',
      companions: const ['一人', '友達', '恋人', '家族', '職場'],
      budgets: const ['〜1000円', '1000〜2000円', '2000〜3000円', '気にしない'],
      distanceMeters: distanceMeters,
      categories: _categoriesFromTypes(types),
      googlePlaceId: placeId,
      address: place['formattedAddress']?.toString(),
      latitude: placeLatitude,
      longitude: placeLongitude,
      rating: (place['rating'] as num?)?.toDouble(),
      userRatingCount: (place['userRatingCount'] as num?)?.toInt(),
      photoUrl: photoUrl,
      isOpenNow: place['currentOpeningHours']?['openNow'] as bool?,
      googlePrimaryType: primaryType,
      googleTypes: types,
      classification: classificationResult.classification,
    );
  }

  /// Place ID が同じレスポンスを一度だけ Restaurant へ変換する。
  List<Restaurant> parseMany({
    required List<dynamic> places,
    required double originLatitude,
    required double originLongitude,
  }) {
    final seenPlaceIds = <String>{};
    final restaurants = <Restaurant>[];

    for (final rawPlace in places) {
      final place = rawPlace as Map<String, dynamic>;
      final placeId = place['id']?.toString();
      if (placeId != null && !seenPlaceIds.add(placeId)) continue;

      restaurants.add(
        parse(
          place: place,
          originLatitude: originLatitude,
          originLongitude: originLongitude,
        ),
      );
    }

    return restaurants;
  }

  static List<String> _categoriesFromTypes(List<String> types) {
    final categories = <String>[];

    if (types.contains('japanese_restaurant')) categories.add('和食');

    if (types.contains('italian_restaurant') ||
        types.contains('american_restaurant')) {
      categories.add('洋食');
    }

    if (types.contains('chinese_restaurant')) categories.add('中華');
    if (types.contains('cafe')) categories.add('カフェ');
    if (types.contains('bakery')) categories.add('ベーカリー');
    if (types.contains('fast_food_restaurant')) categories.add('ファストフード');

    return categories.isEmpty ? ['その他'] : categories;
  }

  static List<String> _tagsFromTypes(List<String> types) {
    final tags = <String>[];

    if (types.contains('cafe')) tags.add('カフェ');
    if (types.contains('bakery')) tags.add('ベーカリー');
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
