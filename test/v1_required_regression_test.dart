import 'package:flutter_test/flutter_test.dart';
import 'package:swipeat/data/chain_brand_dictionary.dart';
import 'package:swipeat/models/premium_entitlement.dart';
import 'package:swipeat/models/restaurant.dart';
import 'package:swipeat/models/restaurant_classification.dart';
import 'package:swipeat/models/restaurant_genre.dart';
import 'package:swipeat/services/ad_service.dart';
import 'package:swipeat/services/candidate_pool.dart';
import 'package:swipeat/services/premium_candidate_filter.dart';
import 'package:swipeat/services/restaurant_classifier.dart';

Restaurant _restaurant(
  int index, {
  String? placeId,
  RestaurantClassification? classification,
}) {
  return Restaurant(
    name: '店舗$index',
    tags: const [],
    budget: '指定なし',
    description: 'テスト店舗',
    companions: const [],
    budgets: const [],
    distanceMeters: index,
    categories: const [],
    googlePlaceId: placeId ?? 'place-$index',
    classification: classification,
  );
}

void main() {
  group('v1.0 required classification regression', () {
    test('covers the 14 seeded chain definitions and collision pairs', () {
      const dictionary = ChainBrandDictionary();

      expect(dictionary.definitions, hasLength(14));
      expect(dictionary.findByPlaceName('松のや 駅前店')?.brand, '松のや');
      expect(dictionary.findByPlaceName('松屋 駅前店')?.brand, '松屋');
      expect(dictionary.findByPlaceName('餃子の王将 駅前店')?.brand, '餃子の王将');
      expect(dictionary.findByPlaceName('大阪王将 駅前店')?.brand, '大阪王将');
    });

    test('uses Google primaryType as the deterministic fallback', () {
      final result = RestaurantClassifier().classify(
        placeName: '駅前の店舗',
        googlePrimaryType: 'ramen_restaurant',
      );

      expect(result.classification.primaryGenre, RestaurantGenre.ramen);
      expect(
        result.classification.classificationSource,
        ClassificationSource.googlePrimaryType,
      );
    });
  });

  group('v1.0 required candidate pool boundaries', () {
    test('Free 20 candidates stay in 5 / 5 / 5 / 5 without refetching', () {
      final pool = CandidatePool(
        restaurants: List.generate(20, _restaurant),
        mode: CandidatePoolMode.free,
      );

      expect(pool.currentBatchLength, 5);
      for (final expectedStart in [5, 10, 15]) {
        for (var i = 0; i < 5; i++) {
          pool.skipCurrent();
        }
        expect(pool.advanceToNextBatch(), isTrue);
        expect(pool.currentBatchStart, expectedStart);
        expect(pool.length, 20);
      }
      expect(pool.hasNextBatch, isFalse);
    });

    test('0, 3 and 20 candidates terminate without invalid indexes', () {
      for (final count in [0, 3, 20]) {
        final pool = CandidatePool(
          restaurants: List.generate(count, _restaurant),
          mode: CandidatePoolMode.free,
        );

        while (!pool.isExhausted) {
          while (pool.currentRestaurant != null) {
            pool.skipCurrent();
          }
          if (pool.hasNextBatch) {
            expect(pool.advanceToNextBatch(), isTrue);
          }
        }
        expect(pool.isExhausted, isTrue);
      }
    });

    test(
      'Premium 20 candidates remain continuous and never show break ads',
      () {
        final pool = CandidatePool(
          restaurants: List.generate(20, _restaurant),
          mode: CandidatePoolMode.premium,
        );
        const adService = AdService();

        expect(pool.currentBatchLength, 20);
        for (var i = 0; i < 20; i++) {
          expect(pool.currentRestaurant, isNotNull);
          pool.skipCurrent();
        }
        expect(pool.isExhausted, isTrue);
        expect(
          adService.shouldShowBreakAd(
            mode: CandidatePoolMode.premium,
            completedCount: 5,
            hasMoreCandidates: true,
          ),
          isFalse,
        );
      },
    );
  });

  test(
    'Premium genre filter uses primaryGenre and keeps zero matches empty',
    () {
      final ramen = RestaurantClassification(
        primaryGenre: RestaurantGenre.ramen,
        subTags: const [RestaurantGenre.curry],
      );
      final curryOnly = RestaurantClassification(
        primaryGenre: RestaurantGenre.gyudon,
        subTags: const [RestaurantGenre.curry],
      );

      final result = const PremiumCandidateFilter().filter(
        restaurants: [
          _restaurant(1, classification: ramen),
          _restaurant(2, classification: curryOnly),
        ],
        genre: RestaurantGenre.curry,
      );

      expect(result, isEmpty);
    },
  );

  test(
    'active, trial and complimentary entitlements are Premium; expired is Free',
    () {
      final now = DateTime.utc(2026, 8, 25);
      for (final source in [
        PremiumEntitlementSource.googlePlay,
        PremiumEntitlementSource.freeTrial,
        PremiumEntitlementSource.complimentary,
        PremiumEntitlementSource.developer,
      ]) {
        expect(
          PremiumEntitlement(
            status: PremiumEntitlementStatus.active,
            source: source,
            validFrom: now.subtract(const Duration(days: 1)),
            validUntil: now.add(const Duration(days: 1)),
          ).isPremiumAt(now),
          isTrue,
        );
      }

      expect(
        PremiumEntitlement(
          status: PremiumEntitlementStatus.expired,
          source: PremiumEntitlementSource.googlePlay,
        ).isPremiumAt(now),
        isFalse,
      );
    },
  );
}
