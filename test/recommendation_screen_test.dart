import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipeat/models/restaurant.dart';
import 'package:swipeat/models/restaurant_photo.dart';
import 'package:swipeat/screens/recommendation_screen.dart';

Restaurant _restaurant(String name, {List<RestaurantPhoto> photos = const []}) {
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
    photos: photos,
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

    expect(find.text('決定'), findsNWidgets(2));
    expect(find.text('見送る'), findsNWidgets(2));
    expect(find.text('一人・～1,000円・500m以内・気にしない'), findsNothing);
    expect(find.text('条件を選び直す'), findsNothing);
    expect(find.byKey(const ValueKey('swipe-guidance')), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('swipe-guidance'))).dy,
      lessThan(
        tester.getTopLeft(find.byKey(const ValueKey('recommendation-card'))).dy,
      ),
    );
    expect(find.text('右スワイプ・緑：決定 / 左スワイプ・赤：見送る'), findsNothing);

    final skipButton = tester.widget<OutlinedButton>(
      find.byKey(const ValueKey('skip-action-button')),
    );
    final decideButton = tester.widget<ElevatedButton>(
      find.byKey(const ValueKey('decide-action-button')),
    );

    expect(
      skipButton.style!.shape!.resolve(const <WidgetState>{}),
      isA<CircleBorder>(),
    );
    expect(
      decideButton.style!.shape!.resolve(const <WidgetState>{}),
      isA<CircleBorder>(),
    );
    expect(
      skipButton.style!.backgroundColor!.resolve(const <WidgetState>{}),
      Colors.red.shade50,
    );
    expect(
      decideButton.style!.backgroundColor!.resolve(const <WidgetState>{}),
      Colors.green.shade600,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('skip-action-button'))),
      const Size(72, 72),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('decide-action-button'))),
      const Size(72, 72),
    );
  });

  testWidgets('見送るボタンはカードを退場させて次候補を表示する', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RecommendationScreen(
          companion: '一人',
          budget: '～1,000円',
          distance: '500m以内',
          category: '気にしない',
          restaurants: [_restaurant('1店目'), _restaurant('2店目')],
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('skip-action-button')));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('2店目'), findsOneWidget);
    expect(find.byKey(const ValueKey('recommendation-card')), findsOneWidget);
  });

  testWidgets('背面のスワイプ色は静止時に隠れ、ドラッグ中だけ見える', (tester) async {
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

    AnimatedOpacity feedback() => tester.widget<AnimatedOpacity>(
      find.byKey(const ValueKey('swipe-feedback')),
    );

    expect(feedback().opacity, 0);

    Container feedbackSurface() => tester.widget<Container>(
      find.byKey(const ValueKey('swipe-feedback-surface')),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('recommendation-card'))),
    );
    await gesture.moveBy(const Offset(20, 0));
    await gesture.moveBy(const Offset(80, 0));
    await tester.pump();

    expect(feedback().opacity, greaterThan(0));
    expect(feedbackSurface().color, Colors.green);

    await gesture.moveBy(const Offset(-160, 0));
    await tester.pump();
    expect(feedbackSurface().color, Colors.redAccent);

    await gesture.up();
    await tester.pump(const Duration(milliseconds: 200));

    expect(feedback().opacity, 0);
  });

  testWidgets('決定ボタンはカード退場後に決定画面を開く', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RecommendationScreen(
          companion: '一人',
          budget: '～1,000円',
          distance: '500m以内',
          category: '気にしない',
          restaurants: [_restaurant('決定する店')],
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('decide-action-button')));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(find.text('今日はここにしよう'), findsOneWidget);
    expect(find.text('決定する店'), findsOneWidget);
  });

  testWidgets('候補カードの写真タップで次の写真だけを読み込む', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RecommendationScreen(
          companion: '一人',
          budget: '～1,000円',
          distance: '500m以内',
          category: '気にしない',
          restaurants: [
            _restaurant(
              '写真付き店舗',
              photos: const [
                RestaurantPhoto(url: 'https://example.test/photo-1.jpg'),
                RestaurantPhoto(url: 'https://example.test/photo-2.jpg'),
              ],
            ),
          ],
        ),
      ),
    );
    await tester.pump();

    expect(find.text('1 / 2'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('restaurant-photo-gallery')));
    await tester.pump();
    expect(find.text('2 / 2'), findsOneWidget);
  });
}
