import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipeat/models/restaurant.dart';
import 'package:swipeat/models/restaurant_classification.dart';
import 'package:swipeat/models/restaurant_genre.dart';
import 'package:swipeat/services/premium_candidate_filter.dart';
import 'package:swipeat/widgets/premium_empty_state.dart';

Restaurant restaurant(String name, RestaurantClassification? classification) {
  return Restaurant(
    name: name,
    tags: const [],
    budget: '不明',
    description: 'テスト店舗',
    companions: const [],
    budgets: const [],
    distanceMeters: 100,
    categories: const [],
    classification: classification,
  );
}

void main() {
  const filter = PremiumCandidateFilter();

  test('uses primaryGenre only and excludes subTags-only matches', () {
    final result = filter.filter(
      genre: RestaurantGenre.ramen,
      restaurants: [
        restaurant(
          'ラーメン店',
          const RestaurantClassification(primaryGenre: RestaurantGenre.ramen),
        ),
        restaurant(
          '別ジャンルのラーメン提供店',
          const RestaurantClassification(
            primaryGenre: RestaurantGenre.teishoku,
            subTags: [RestaurantGenre.ramen],
          ),
        ),
        restaurant('未分類店', null),
      ],
    );

    expect(result.map((item) => item.name), ['ラーメン店']);
  });

  test('returns an empty result instead of mixing other genres', () {
    final result = filter.filter(
      genre: RestaurantGenre.ramen,
      restaurants: [
        restaurant(
          '寿司店',
          const RestaurantClassification(primaryGenre: RestaurantGenre.sushi),
        ),
      ],
    );

    expect(result, isEmpty);
  });

  testWidgets('PremiumEmptyState shows the three safe alternatives', (
    WidgetTester tester,
  ) async {
    var widenPressed = false;
    var changePressed = false;
    var omakasePressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PremiumEmptyState(
            onWidenDistance: () => widenPressed = true,
            onChangeGenre: () => changePressed = true,
            onOmakase: () => omakasePressed = true,
          ),
        ),
      ),
    );

    expect(find.textContaining('この条件では営業中の店舗が'), findsOneWidget);
    await tester.tap(find.text('距離を広げる'));
    await tester.tap(find.text('ジャンルを変更'));
    await tester.tap(find.text('おまかせで探す'));
    await tester.pump();

    expect(widenPressed, isTrue);
    expect(changePressed, isTrue);
    expect(omakasePressed, isTrue);
  });
}
