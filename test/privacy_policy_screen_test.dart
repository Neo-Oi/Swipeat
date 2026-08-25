import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:swipeat/screens/privacy_policy_screen.dart';

void main() {
  testWidgets('shows privacy policy and ad settings entry point', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PrivacyPolicyScreen()));

    expect(find.text('プライバシーポリシー'), findsOneWidget);
    expect(find.text('取得する情報'), findsOneWidget);
    expect(find.text('広告と同意'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pump();
    expect(find.text('広告・プライバシー設定を変更'), findsOneWidget);
  });
}
