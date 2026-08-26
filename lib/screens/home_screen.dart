import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../services/google_places_service.dart';
import '../services/location_service.dart';
import 'companion_select_screen.dart';
import 'premium_genre_select_screen.dart';
import 'privacy_policy_screen.dart';
import 'recommendation_screen.dart';
import '../widgets/location_permission_disclosure.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isLoading = false;
  String? errorMessage;
  LocationAccessFailure? locationFailure;

  Future<void> startRandomRecommendation() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      locationFailure = null;
    });

    if (await LocationService.needsPermissionDisclosure()) {
      if (!mounted) return;
      final accepted = await showLocationPermissionDisclosure(context);
      if (!mounted) return;
      if (!accepted) {
        if (!mounted) return;
        setState(() {
          isLoading = false;
          locationFailure = LocationAccessFailure.disclosureDeclined;
          errorMessage = locationFailureMessage(locationFailure!);
        });
        return;
      }
    }

    try {
      final locationResult = await LocationService.getCurrentPositionResult();
      final Position? position = locationResult.position;

      if (position == null) {
        setState(() {
          locationFailure =
              locationResult.failure ?? LocationAccessFailure.unavailable;
          errorMessage = locationFailureMessage(locationFailure!);
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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxHeight < 700;
            final iconSize = isCompact ? 88.0 : 104.0;
            final horizontalPadding = isCompact ? 20.0 : 24.0;
            final sectionGap = isCompact ? 8.0 : 12.0;

            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: isCompact ? 12 : 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        'assets/images/swipeat_icon.png',
                        width: iconSize,
                        height: iconSize,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(height: sectionGap),
                  Text(
                    'Swipeat',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isCompact ? 36 : 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: isCompact ? 2 : 6),
                  Text(
                    '探すより、決める。',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isCompact ? 19 : 21,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: sectionGap),
                  const Text(
                    '現在地周辺の営業中のお店から、まずはランダムに提案します。',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '※ 営業中のお店のみ表示するため、朝や深夜は候補が少なくなる場合があります。',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  SizedBox(height: isCompact ? 12 : 20),
                  ElevatedButton(
                    onPressed: isLoading ? null : startRandomRecommendation,
                    child: Text(isLoading ? '提案中...' : '今すぐ提案'),
                  ),
                  SizedBox(height: isCompact ? 6 : 8),
                  OutlinedButton(
                    onPressed: isLoading ? null : openDistanceSearch,
                    child: const Text('距離を選んで探す'),
                  ),
                  SizedBox(height: isCompact ? 6 : 8),
                  OutlinedButton(
                    onPressed: isLoading ? null : openPremiumGenreSearch,
                    child: const Text('希望を指定して探す（Premium）'),
                  ),
                  SizedBox(height: isCompact ? 2 : 6),
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
                    const SizedBox(height: 8),
                    Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                    if (locationFailure != null &&
                        locationFailure !=
                            LocationAccessFailure.disclosureDeclined) ...[
                      const SizedBox(height: 4),
                      TextButton.icon(
                        onPressed: () =>
                            LocationService.openSettings(locationFailure!),
                        icon: const Icon(Icons.settings_outlined),
                        label: const Text('位置情報の設定を開く'),
                      ),
                    ],
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
