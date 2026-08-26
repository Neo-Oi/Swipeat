import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipeat/main.dart';

void main() {
  testWidgets('Swipeat home screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SwipeatApp());

    expect(find.text('Swipeat'), findsWidgets);
    expect(find.text('今すぐ提案'), findsOneWidget);
    expect(find.text('迷ったら、まずは提案を見る。少ない候補から短時間で決めるためのアプリです。'), findsNothing);
    expect(find.byType(SingleChildScrollView), findsNothing);
  });
}
