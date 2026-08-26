import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/restaurant.dart';
import '../widgets/google_places_attribution.dart';
import '../widgets/restaurant_photo_gallery.dart';

class DecisionScreen extends StatelessWidget {
  const DecisionScreen({super.key, required this.restaurant});

  final Restaurant restaurant;

  Future<void> openGoogleMaps() async {
    final placeId = restaurant.googlePlaceId;

    final Uri uri = placeId != null && placeId.isNotEmpty
        ? Uri.parse(
            'https://www.google.com/maps/search/?api=1&query_place_id=$placeId&query=${Uri.encodeComponent(restaurant.name)}',
          )
        : Uri.parse(
            'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(restaurant.name)}',
          );

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Google Mapsを開けませんでした');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ratingText = restaurant.rating == null
        ? '評価なし'
        : '★${restaurant.rating!.toStringAsFixed(1)}（口コミ ${restaurant.userRatingCount ?? 0}件）';

    final openText = restaurant.isOpenNow == true
        ? '営業中'
        : restaurant.isOpenNow == false
        ? '営業時間外'
        : '営業情報なし';

    return Scaffold(
      appBar: AppBar(title: const Text('決定')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            RestaurantPhotoGallery(
              key: ValueKey(
                'restaurant-photo-${restaurant.googlePlaceId ?? restaurant.name}',
              ),
              photos: restaurant.displayPhotos,
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '今日はここにしよう',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    restaurant.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoChip(text: ratingText),
                      _InfoChip(text: '約${restaurant.distanceMeters}m'),
                      _InfoChip(text: openText),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '住所：${restaurant.address ?? '住所情報なし'}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    restaurant.description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (restaurant.googlePlaceId != null &&
                      restaurant.googlePlaceId!.isNotEmpty)
                    const GooglePlacesAttribution(),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: openGoogleMaps,
                    child: const Text('Google Mapsで開く'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    child: const Text('最初に戻る'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Text(text, style: const TextStyle(fontSize: 13)),
    );
  }
}
