import 'package:flutter_test/flutter_test.dart';
import 'package:swipeat/models/restaurant.dart';
import 'package:swipeat/services/candidate_pool.dart';

Restaurant restaurant(String id) {
  return Restaurant(
    name: '店舗$id',
    tags: const [],
    budget: '不明',
    description: 'テスト店舗',
    companions: const [],
    budgets: const [],
    distanceMeters: 100,
    categories: const [],
    googlePlaceId: id,
  );
}

List<Restaurant> restaurants(int count) {
  return List<Restaurant>.generate(
    count,
    (index) => restaurant('place-$index'),
  );
}

void main() {
  group('CandidatePool Free', () {
    test('splits 20 candidates into 5 / 5 / 5 / 5 without refetching', () {
      final pool = CandidatePool(
        restaurants: restaurants(20),
        mode: CandidatePoolMode.free,
      );

      expect(pool.length, 20);
      expect(pool.currentBatchLength, 5);
      expect(pool.currentBatch.map((item) => item.googlePlaceId), [
        'place-0',
        'place-1',
        'place-2',
        'place-3',
        'place-4',
      ]);

      final batchLengths = <int>[];
      while (true) {
        batchLengths.add(pool.currentBatchLength);
        for (var i = 0; i < pool.currentBatchLength; i++) {
          expect(pool.currentRestaurant, isNotNull);
          pool.skipCurrent();
        }

        if (!pool.hasNextBatch) break;
        expect(pool.advanceToNextBatch(), isTrue);
      }

      expect(batchLengths, [5, 5, 5, 5]);
      expect(pool.displayedCount, 20);
      expect(pool.remainingCount, 0);
      expect(pool.isExhausted, isTrue);
    });

    test('handles fewer than five candidates without an invalid index', () {
      final pool = CandidatePool(
        restaurants: restaurants(3),
        mode: CandidatePoolMode.free,
      );

      expect(pool.currentBatchLength, 3);
      for (var i = 0; i < 3; i++) {
        expect(pool.currentRestaurant, isNotNull);
        pool.skipCurrent();
      }

      expect(pool.isCurrentBatchFinished, isTrue);
      expect(pool.hasNextBatch, isFalse);
      expect(pool.currentRestaurant, isNull);
    });

    test('handles an empty candidate pool', () {
      final pool = CandidatePool(
        restaurants: const [],
        mode: CandidatePoolMode.free,
      );

      expect(pool.currentBatch, isEmpty);
      expect(pool.currentRestaurant, isNull);
      expect(pool.isCurrentBatchFinished, isTrue);
      expect(pool.isExhausted, isTrue);
    });
  });

  group('CandidatePool Premium', () {
    test('keeps 20 candidates in one continuous batch', () {
      final pool = CandidatePool(
        restaurants: restaurants(20),
        mode: CandidatePoolMode.premium,
      );

      expect(pool.currentBatchLength, 20);
      expect(pool.hasNextBatch, isFalse);

      for (var i = 0; i < 5; i++) {
        pool.skipCurrent();
      }
      expect(pool.isCurrentBatchFinished, isFalse);
      expect(pool.displayedCount, 5);
      expect(pool.remainingCount, 15);
    });
  });

  test('deduplicates by placeId and caps the initial pool at 20', () {
    final source = <Restaurant>[
      restaurant('duplicate'),
      restaurant('duplicate'),
      ...restaurants(25),
    ];
    final pool = CandidatePool(
      restaurants: source,
      mode: CandidatePoolMode.free,
    );

    expect(pool.length, 20);
    expect(
      pool.restaurants.map((item) => item.googlePlaceId).toSet(),
      hasLength(20),
    );
  });

  test('can restart a batch without changing the stored candidates', () {
    final pool = CandidatePool(
      restaurants: restaurants(6),
      mode: CandidatePoolMode.free,
    );
    pool.skipCurrent();
    pool.skipCurrent();
    expect(pool.displayedCount, 2);

    pool.restartCurrentBatch();
    expect(pool.displayedCount, 0);
    expect(pool.currentRestaurant?.googlePlaceId, 'place-0');
    expect(pool.length, 6);
  });
}
