import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../services/google_places_service.dart';
import '../services/location_service.dart';
import 'companion_select_screen.dart';
import 'premium_genre_select_screen.dart';
import 'privacy_policy_screen.dart';
import 'recommendation_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isLoading = false;
  String? errorMessage;

  Future<void> startRandomRecommendation() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final Position? position = await LocationService.getCurrentPosition();

      if (position == null) {
        setState(() {
          errorMessage = '現在地を取得できませんでした。位置情報の許可を確認してください。';
          isLoading = false;
        });
        return;
      }

      final restaurants = await GooglePlacesService.searchNearbyRestaurants(
        latitude: position.latitude,
        longitude: position.longitude,
        radiusMeters: 1500,
        category: '気にしない',
        openNowOnly: true,
      );

      final openRestaurants =
          restaurants
              .where((restaurant) => restaurant.isOpenNow == true)
              .toList()
            ..shuffle();

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RecommendationScreen(
            companion: '指定なし',
            budget: '指定なし',
            distance: '1.5km以内',
            category: 'ランダム提案',
            restaurants: openRestaurants,
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

  void openDistanceSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CompanionSelectScreen()),
    );
  }

  void openPremiumGenreSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PremiumGenreSelectScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Swipeat')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.asset(
                  'assets/images/swipeat_icon.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Swipeat',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 44, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              '探すより、決める。',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            const Text(
              '現在地周辺の営業中のお店から、まずはランダムに提案します。',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 12),
            const Text(
              '※ 営業中のお店のみ表示するため、朝や深夜は候補が少なくなる場合があります。',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: isLoading ? null : startRandomRecommendation,
              child: Text(isLoading ? '提案中...' : '今すぐ提案'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: isLoading ? null : openDistanceSearch,
              child: const Text('距離を選んで探す'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: isLoading ? null : openPremiumGenreSearch,
              child: const Text('希望を指定して探す（Premium）'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: isLoading
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PrivacyPolicyScreen(),
                        ),
                      );
                    },
              child: const Text('プライバシーポリシー・広告設定'),
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 24),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
            const SizedBox(height: 40),
            const Text(
              '迷ったら、まずは提案を見る。少ない候補から短時間で決めるためのアプリです。',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
