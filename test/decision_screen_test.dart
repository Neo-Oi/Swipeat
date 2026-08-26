import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipeat/models/restaurant.dart';
import 'package:swipeat/models/restaurant_photo.dart';
import 'package:swipeat/screens/decision_screen.dart';

void main() {
  testWidgets('決定画面の写真タップで次の写真へ進む', (tester) async {
    const restaurant = Restaurant(
      name: '決定店舗',
      tags: ['テスト'],
      budget: '～1,000円',
      description: 'テスト用の店舗です。',
      companions: ['一人'],
      budgets: ['～1,000円'],
      distanceMeters: 300,
      categories: ['気にしない'],
      photos: [
        RestaurantPhoto(url: 'https://example.test/decision-1.jpg'),
        RestaurantPhoto(url: 'https://example.test/decision-2.jpg'),
      ],
    );

    await tester.pumpWidget(
      const MaterialApp(home: DecisionScreen(restaurant: restaurant)),
    );
    await tester.pump();

    expect(find.text('1 / 2'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('restaurant-photo-gallery')));
    await tester.pump();
    expect(find.text('2 / 2'), findsOneWidget);
  });
}
