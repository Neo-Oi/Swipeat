import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../services/google_places_service.dart';
import '../services/location_service.dart';
import 'recommendation_screen.dart';

class CompanionSelectScreen extends StatefulWidget {
  const CompanionSelectScreen({super.key});

  @override
  State<CompanionSelectScreen> createState() => _CompanionSelectScreenState();
}

class _CompanionSelectScreenState extends State<CompanionSelectScreen> {
  String? selectedDistance;

  Position? currentPosition;
  bool isLoading = false;
  String? errorMessage;

  final List<String> distances = [
    '300m以内',
    '500m以内',
    '1km以内',
    '1.5km以内',
  ];

  @override
  void initState() {
    super.initState();
    loadCurrentPosition();
  }

  Future<void> loadCurrentPosition() async {
    final position = await LocationService.getCurrentPosition();

    if (!mounted) return;

    setState(() {
      currentPosition = position;
    });
  }

  int distanceLimit(String distance) {
    if (distance == '300m以内') return 300;
    if (distance == '500m以内') return 500;
    if (distance == '1km以内') return 1000;
    if (distance == '1.5km以内') return 1500;

    return 1500;
  }

  int relaxedDistanceLimit(String distance) {
    final currentLimit = distanceLimit(distance);

    if (currentLimit <= 300) return 500;
    if (currentLimit <= 500) return 1000;
    if (currentLimit <= 1000) return 1500;

    return 2000;
  }

  Future<void> searchRestaurants() async {
    if (selectedDistance == null) {
      return;
    }

    if (currentPosition == null) {
      setState(() {
        errorMessage = '現在地を取得できませんでした。位置情報の許可を確認してください。';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      var usedDistanceLabel = selectedDistance!;
      var noticeMessage = '';

      var googleRestaurants =
          await GooglePlacesService.searchNearbyRestaurants(
        latitude: currentPosition!.latitude,
        longitude: currentPosition!.longitude,
        radiusMeters: distanceLimit(selectedDistance!),
        category: '気にしない',
        openNowOnly: true,
      );

      googleRestaurants = googleRestaurants
          .where((restaurant) => restaurant.isOpenNow == true)
          .toList();

      if (googleRestaurants.isEmpty) {
        final relaxedLimit = relaxedDistanceLimit(selectedDistance!);

        usedDistanceLabel = '${relaxedLimit}m以内';
        noticeMessage = '候補が少なかったため、距離条件を広げました。';

        googleRestaurants =
            await GooglePlacesService.searchNearbyRestaurants(
          latitude: currentPosition!.latitude,
          longitude: currentPosition!.longitude,
          radiusMeters: relaxedLimit,
          category: '気にしない',
          openNowOnly: true,
        );

        googleRestaurants = googleRestaurants
            .where((restaurant) => restaurant.isOpenNow == true)
            .toList();
      }

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RecommendationScreen(
            companion: '指定なし',
            budget: '指定なし',
            distance: usedDistanceLabel,
            category: '気にしない',
            noticeMessage: noticeMessage,
            restaurants: googleRestaurants,
          ),
        ),
      );
    } catch (error) {
      setState(() {
        errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Widget buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget buildSingleChoiceList({
    required List<String> items,
    required String? selectedValue,
    required void Function(String value) onSelected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        return ChoiceChip(
          label: Text(item),
          selected: selectedValue == item,
          onSelected: isLoading
              ? null
              : (_) {
                  onSelected(item);
                },
        );
      }).toList(),
    );
  }

  bool get canSearch {
    return selectedDistance != null && !isLoading;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('距離を選択'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'どれくらい近くで探しますか？',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              '現在地周辺の営業中のお店から、選んだ距離内で提案します。',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Text(
              currentPosition == null ? '現在地：取得中または未許可' : '現在地：取得済み',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
            ),
            buildSectionTitle('探す距離'),
            buildSingleChoiceList(
              items: distances,
              selectedValue: selectedDistance,
              onSelected: (value) {
                setState(() {
                  selectedDistance = value;
                });
              },
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: canSearch ? searchRestaurants : null,
              child: Text(isLoading ? '取得中...' : 'この距離で探す'),
            ),
          ],
        ),
      ),
    );
  }
}