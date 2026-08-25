import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipeat/models/restaurant.dart';
import 'package:swipeat/screens/recommendation_screen.dart';

Restaurant _restaurant(String name) {
  return Restaurant(
    name: name,
    tags: const ['テスト'],
    budget: '～1,000円',
    description: 'テスト用の候補です。',
    companions: const ['一人'],
    budgets: const ['～1,000円'],
    distanceMeters: 300,
    categories: const ['気にしない'],
    isOpenNow: true,
  );
}

void main() {
  testWidgets('候補カードに決定と見送るボタンを表示する', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RecommendationScreen(
          companion: '一人',
          budget: '～1,000円',
          distance: '500m以内',
          category: '気にしない',
          restaurants: [_restaurant('テスト店舗')],
        ),
      ),
    );
    await tester.pump();

    expect(find.text('決定'), findsOneWidget);
    expect(find.text('見送る'), findsOneWidget);
  });
}
