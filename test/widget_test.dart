import 'package:flutter_test/flutter_test.dart';
import 'package:swipeat/main.dart';

void main() {
  testWidgets('Swipeat home screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SwipeatApp());

    expect(find.text('Swipeat'), findsWidgets);
    expect(find.text('今すぐ提案'), findsOneWidget);
  });
}
