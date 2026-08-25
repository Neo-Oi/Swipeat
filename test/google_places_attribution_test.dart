import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipeat/widgets/google_places_attribution.dart';

void main() {
  testWidgets('shows Google Maps Platform attribution', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: GooglePlacesAttribution())),
    );

    expect(find.text('Google Maps Platform のデータを利用しています'), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(GooglePlacesAttribution)),
      matchesSemantics(
        label: 'Google Maps Platform のデータを利用しています',
      ),
    );
  });
}
