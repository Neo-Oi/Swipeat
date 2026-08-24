import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/restaurant.dart';
import '../services/google_places_service.dart';
import '../services/candidate_pool.dart';
import '../services/location_service.dart';
import '../utils/distance_calculator.dart';
import 'decision_screen.dart';

class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({
    super.key,
    required this.companion,
    required this.budget,
    required this.distance,
    required this.category,
    required this.restaurants,
    this.poolMode = CandidatePoolMode.free,
    this.noticeMessage = '',
  });

  final String companion;
  final String budget;
  final String distance;
  final String category;
  final List<Restaurant> restaurants;
  final CandidatePoolMode poolMode;
  final String noticeMessage;

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  double dragOffsetX = 0;

  bool isPageFinished = false;
  bool isReloading = false;

  String? reloadErrorMessage;
  Position? currentPosition;

  late CandidatePool candidatePool;

  final ScrollController cardScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    candidatePool = CandidatePool(
      restaurants: widget.restaurants,
      mode: widget.poolMode,
    );
    loadCurrentPosition();
  }

  @override
  void dispose() {
    cardScrollController.dispose();
    super.dispose();
  }

  Future<void> loadCurrentPosition() async {
    final position = await LocationService.getCurrentPosition();

    if (!mounted) return;

    setState(() {
      currentPosition = position;
    });
  }

  bool get hasNextPage {
    return candidatePool.hasNextBatch;
  }

  Restaurant? get currentRestaurant {
    return candidatePool.currentRestaurant;
  }

  int distanceLimit(String distance) {
    if (distance == '300m以内') return 300;
    if (distance == '500m以内') return 500;
    if (distance == '1km以内') return 1000;
    if (distance == '1500m以内') return 1500;
    if (distance == '2000m以内') return 2000;
    return 1500;
  }

  int calculatedDistance(Restaurant restaurant) {
    if (currentPosition == null ||
        restaurant.latitude == null ||
        restaurant.longitude == null) {
      return restaurant.distanceMeters;
    }

    return DistanceCalculator.calculateDistanceMeters(
      fromLatitude: currentPosition!.latitude,
      fromLongitude: currentPosition!.longitude,
      toLatitude: restaurant.latitude!,
      toLongitude: restaurant.longitude!,
    );
  }

  Future<void> reloadRestaurants() async {
    if (currentPosition == null) {
      setState(() {
        reloadErrorMessage = '現在地を取得できませんでした。条件を変えて再度試してください。';
      });
      return;
    }

    setState(() {
      isReloading = true;
      reloadErrorMessage = null;
    });

    try {
      final fetchedRestaurants =
          await GooglePlacesService.searchNearbyRestaurants(
            latitude: currentPosition!.latitude,
            longitude: currentPosition!.longitude,
            radiusMeters: distanceLimit(widget.distance),
            category: widget.category,
            openNowOnly: true,
          );

      final openRestaurants = fetchedRestaurants
          .where((restaurant) => restaurant.isOpenNow == true)
          .toList();

      if (!mounted) return;

      setState(() {
        candidatePool = CandidatePool(
          restaurants: openRestaurants,
          mode: widget.poolMode,
        );
        dragOffsetX = 0;
        isPageFinished = false;
        isReloading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        resetCardScroll();
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isReloading = false;
        reloadErrorMessage = error.toString();
      });
    }
  }

  List<String> recommendationReasons({
    required Restaurant restaurant,
    required int distanceMeters,
  }) {
    final reasons = <String>[];

    if (distanceMeters <= 300) {
      reasons.add('現在地からかなり近い');
    } else if (distanceMeters <= 800) {
      reasons.add('歩いて行きやすい距離');
    }

    if (restaurant.isOpenNow == true) {
      reasons.add('現在営業中');
    }

    if (restaurant.rating != null && restaurant.rating! >= 4.0) {
      reasons.add('評価が高い');
    }

    if (widget.category != '気にしない' &&
        restaurant.categories.any(
          (category) => widget.category.contains(category),
        )) {
      reasons.add('選んだカテゴリのいずれかに合っている');
    }

    if (reasons.isEmpty) {
      reasons.add('選択条件に近い候補');
    }

    return reasons;
  }

  void resetCardScroll() {
    if (cardScrollController.hasClients) {
      cardScrollController.jumpTo(0);
    }
  }

  void showNextRestaurant() {
    setState(() {
      dragOffsetX = 0;
      candidatePool.skipCurrent();
      isPageFinished = candidatePool.isCurrentBatchFinished;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      resetCardScroll();
    });
  }

  void restartCurrentPage() {
    setState(() {
      candidatePool.restartCurrentBatch();
      dragOffsetX = 0;
      isPageFinished = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      resetCardScroll();
    });
  }

  void showNextPage() {
    if (!candidatePool.advanceToNextBatch()) return;

    setState(() {
      dragOffsetX = 0;
      isPageFinished = false;
      reloadErrorMessage = null;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      resetCardScroll();
    });
  }

  void decideRestaurant(Restaurant restaurant) {
    setState(() {
      dragOffsetX = 0;
    });

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DecisionScreen(restaurant: restaurant)),
    );
  }

  void resetCardPosition() {
    setState(() {
      dragOffsetX = 0;
    });
  }

  void handleDragEnd() {
    if (dragOffsetX > 120) {
      final restaurant = currentRestaurant;
      if (restaurant != null) decideRestaurant(restaurant);
    } else if (dragOffsetX < -120) {
      showNextRestaurant();
    } else {
      resetCardPosition();
    }
  }

  Widget buildInfoChip(String text) {
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

  Widget buildEmptyView() {
    return Scaffold(
      appBar: AppBar(title: const Text('候補なし')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '条件に合う営業中の店舗が見つかりませんでした',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              '${widget.companion}・${widget.budget}・${widget.distance}・${widget.category}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15),
            ),
            if (reloadErrorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                reloadErrorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: isReloading ? null : reloadRestaurants,
              child: Text(isReloading ? '再検索中...' : '再検索する'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('条件を変える'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: const Text('最初に戻る'),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPageFinishedView() {
    final hasMore = hasNextPage;
    final isPremium = widget.poolMode == CandidatePoolMode.premium;

    return Scaffold(
      appBar: AppBar(title: const Text('おすすめ終了')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              hasMore ? '今日のおすすめはここまでです' : '候補をすべて見終わりました',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              hasMore
                  ? 'この中で決めるか、まだ迷う場合は次の候補を見られます。'
                  : '同じ候補をもう一度見るか、再検索してください。',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            if (reloadErrorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                reloadErrorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: restartCurrentPage,
              child: Text(isPremium ? '候補をもう一度見る' : 'この5件をもう一度見る'),
            ),
            if (hasMore) ...[
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: showNextPage,
                child: const Text('まだ迷う'),
              ),
            ],
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: isReloading ? null : reloadRestaurants,
              child: Text(isReloading ? '再検索中...' : '再検索する'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('条件を変える'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (candidatePool.length == 0) {
      return buildEmptyView();
    }

    if (isPageFinished) {
      return buildPageFinishedView();
    }

    final restaurant = currentRestaurant;
    if (restaurant == null) {
      return buildPageFinishedView();
    }
    final distanceMeters = calculatedDistance(restaurant);
    final reasons = recommendationReasons(
      restaurant: restaurant,
      distanceMeters: distanceMeters,
    );

    final ratingText = restaurant.rating == null
        ? '評価なし'
        : '★${restaurant.rating!.toStringAsFixed(1)}（${restaurant.userRatingCount ?? 0}件）';

    final openText = restaurant.isOpenNow == true
        ? '営業中'
        : restaurant.isOpenNow == false
        ? '営業時間外'
        : '営業情報なし';

    return Scaffold(
      appBar: AppBar(title: const Text('おすすめ')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${widget.companion}・${widget.budget}・${widget.distance}・${widget.category}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            if (widget.noticeMessage.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Text(
                  widget.noticeMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(left: 24),
                            color: Colors.green,
                            child: const Text(
                              'ここにする',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 24),
                            color: Colors.redAccent,
                            child: const Text(
                              '次へ',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 120),
                    left: dragOffsetX,
                    right: -dragOffsetX,
                    top: 0,
                    bottom: 0,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onHorizontalDragUpdate: (details) {
                        setState(() {
                          dragOffsetX += details.delta.dx;
                        });
                      },
                      onHorizontalDragEnd: (_) {
                        handleDragEnd();
                      },
                      child: Card(
                        elevation: 5,
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: SingleChildScrollView(
                          controller: cardScrollController,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (restaurant.photoUrl != null)
                                Image.network(
                                  restaurant.photoUrl!,
                                  height: 220,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 220,
                                      alignment: Alignment.center,
                                      color: Colors.grey.shade300,
                                      child: const Text('写真を表示できません'),
                                    );
                                  },
                                )
                              else
                                Container(
                                  height: 220,
                                  alignment: Alignment.center,
                                  color: Colors.grey.shade300,
                                  child: const Text('写真なし'),
                                ),
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      restaurant.name,
                                      style: const TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        buildInfoChip(ratingText),
                                        buildInfoChip('約${distanceMeters}m'),
                                        buildInfoChip(openText),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'おすすめ理由',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          ...reasons.map(
                                            (reason) => Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 4,
                                              ),
                                              child: Text('✓ $reason'),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: restaurant.tags.map((tag) {
                                        return Chip(label: Text(tag));
                                      }).toList(),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      '予算：${restaurant.budget}',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      '住所：${restaurant.address ?? '住所情報なし'}',
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      restaurant.description,
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              '右スワイプ：ここにする / 左スワイプ：次へ',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('条件を選び直す'),
            ),
          ],
        ),
      ),
    );
  }
}
