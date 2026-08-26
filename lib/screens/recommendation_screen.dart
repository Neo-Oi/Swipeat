import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import '../models/restaurant.dart';
import '../services/ad_service.dart';
import '../services/candidate_pool.dart';
import '../services/google_places_service.dart';
import '../services/location_service.dart';
import '../utils/distance_calculator.dart';
import '../widgets/premium_empty_state.dart';
import '../widgets/google_places_attribution.dart';
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
  static const _swipeThreshold = 112.0;
  static const _dismissDuration = Duration(milliseconds: 180);

  double dragOffsetX = 0;

  bool isPageFinished = false;
  bool isReloading = false;
  bool isActionInProgress = false;
  bool isDragging = false;

  String? reloadErrorMessage;
  Position? currentPosition;

  static const AdService adService = AdService();

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
    Position? position;
    try {
      position = await LocationService.getCurrentPosition(
        requestPermission: false,
      );
    } catch (_) {
      // A location provider can be unavailable while the recommendation card
      // is still usable with the Place-provided distance.
      return;
    }

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

  double get swipeFeedbackOpacity {
    return (dragOffsetX.abs() / _swipeThreshold).clamp(0.0, 1.0).toDouble();
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

  Future<void> showNextRestaurant() async {
    if (isActionInProgress) return;

    HapticFeedback.selectionClick();
    setState(() {
      isActionInProgress = true;
      isDragging = false;
      dragOffsetX = -MediaQuery.sizeOf(context).width;
    });

    await Future<void>.delayed(_dismissDuration);
    if (!mounted) return;

    setState(() {
      candidatePool.skipCurrent();
      isPageFinished = candidatePool.isCurrentBatchFinished;
      dragOffsetX = 0;
      isActionInProgress = false;
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

  Future<void> decideRestaurant(Restaurant restaurant) async {
    if (isActionInProgress) return;

    HapticFeedback.lightImpact();
    setState(() {
      isActionInProgress = true;
      isDragging = false;
      dragOffsetX = MediaQuery.sizeOf(context).width;
    });

    await Future<void>.delayed(_dismissDuration);
    if (!mounted) return;

    setState(() {
      dragOffsetX = 0;
    });

    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => DecisionScreen(restaurant: restaurant)),
    );

    if (mounted) {
      setState(() {
        isActionInProgress = false;
      });
    }
  }

  void resetCardPosition() {
    setState(() {
      isDragging = false;
      dragOffsetX = 0;
    });
  }

  void handleDragEnd() {
    setState(() {
      isDragging = false;
    });

    if (dragOffsetX > _swipeThreshold) {
      final restaurant = currentRestaurant;
      if (restaurant != null) decideRestaurant(restaurant);
    } else if (dragOffsetX < -_swipeThreshold) {
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
    if (widget.poolMode == CandidatePoolMode.premium) {
      return Scaffold(
        appBar: AppBar(title: const Text('候補なし')),
        body: PremiumEmptyState(
          onWidenDistance: () => Navigator.pop(context),
          onChangeGenre: () => Navigator.pop(context),
          onOmakase: () {
            Navigator.popUntil(context, (route) => route.isFirst);
          },
        ),
      );
    }

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
    final showBreakAd = adService.shouldShowBreakAd(
      mode: widget.poolMode,
      completedCount: candidatePool.displayedCount,
      hasMoreCandidates: hasMore,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('おすすめ終了')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              hasMore ? 'まだ決まりませんか？' : '候補をすべて見終わりました',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              hasMore
                  ? 'この中で決めるか、次の候補を見ることができます。'
                  : isPremium
                  ? '候補をもう一度見るか、再検索してください。'
                  : '再検索するか、条件を変更してください。',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            if (showBreakAd) ...[
              const SizedBox(height: 8),
              const AdSlot(),
              const SizedBox(height: 24),
            ],
            if (reloadErrorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                reloadErrorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
            const SizedBox(height: 32),
            if (isPremium)
              ElevatedButton(
                onPressed: restartCurrentPage,
                child: const Text('候補をもう一度見る'),
              ),
            if (hasMore) ...[
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: showNextPage,
                child: const Text('さらに5店舗を見る'),
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
            if (widget.noticeMessage.isNotEmpty) ...[
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
              const SizedBox(height: 12),
            ],
            Semantics(
              label: '左へスワイプで見送る、右へスワイプで決定',
              child: Container(
                key: const ValueKey('swipe-guidance'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.red.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '見送る',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Text(
                      'スワイプ',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '決定',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.green.shade600,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedOpacity(
                        key: const ValueKey('swipe-feedback'),
                        duration: isDragging
                            ? Duration.zero
                            : const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        opacity: swipeFeedbackOpacity,
                        child: Container(
                          key: const ValueKey('swipe-feedback-surface'),
                          alignment: dragOffsetX > 0
                              ? Alignment.centerLeft
                              : Alignment.centerRight,
                          padding: EdgeInsets.only(
                            left: dragOffsetX > 0 ? 24 : 0,
                            right: dragOffsetX > 0 ? 0 : 24,
                          ),
                          color: dragOffsetX > 0
                              ? Colors.green
                              : Colors.redAccent,
                          child: Text(
                            dragOffsetX > 0 ? 'ここにする' : '次へ',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  AnimatedPositioned(
                    duration: isDragging
                        ? Duration.zero
                        : const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    left: dragOffsetX,
                    right: -dragOffsetX,
                    top: 0,
                    bottom: 0,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onHorizontalDragStart: (_) {
                        if (isActionInProgress) return;
                        setState(() {
                          isDragging = true;
                        });
                      },
                      onHorizontalDragUpdate: (details) {
                        if (isActionInProgress) return;
                        setState(() {
                          dragOffsetX += details.delta.dx;
                        });
                      },
                      onHorizontalDragEnd: (_) {
                        handleDragEnd();
                      },
                      child: Card(
                        key: const ValueKey('recommendation-card'),
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
                                  height: 260,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 260,
                                      alignment: Alignment.center,
                                      color: Colors.grey.shade300,
                                      child: const Text('写真を表示できません'),
                                    );
                                  },
                                )
                              else
                                Container(
                                  height: 260,
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
                                    if (restaurant.googlePlaceId != null &&
                                        restaurant.googlePlaceId!.isNotEmpty)
                                      const GooglePlacesAttribution(),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: OutlinedButton(
                    key: const ValueKey('skip-action-button'),
                    onPressed: isActionInProgress ? null : showNextRestaurant,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      backgroundColor: Colors.red.shade50,
                      side: BorderSide(color: Colors.red.shade400, width: 2),
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(8),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.close_rounded, size: 28),
                        SizedBox(height: 2),
                        Text('見送る', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                SizedBox(
                  width: 72,
                  height: 72,
                  child: ElevatedButton(
                    key: const ValueKey('decide-action-button'),
                    onPressed: isActionInProgress
                        ? null
                        : () => decideRestaurant(restaurant),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.green.shade600,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(8),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_rounded, size: 28),
                        SizedBox(height: 2),
                        Text('決定', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
