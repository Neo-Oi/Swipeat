import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipeat/models/premium_entitlement.dart';
import 'package:swipeat/models/restaurant_genre.dart';
import 'package:swipeat/screens/premium_genre_select_screen.dart';

void main() {
  testWidgets('shows groups first and details only after selecting a group', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: PremiumGenreSelectScreen()),
    );

    expect(find.text('和食'), findsOneWidget);
    expect(find.text('麺類'), findsOneWidget);
    expect(find.text('ラーメン'), findsNothing);

    await tester.ensureVisible(
      find.byKey(const ValueKey('genre-group-noodles')),
    );
    await tester.tap(find.byKey(const ValueKey('genre-group-noodles')));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.text('ラーメン'), findsOneWidget);
    expect(find.text('つけ麺'), findsOneWidget);
    expect(find.text('寿司'), findsNothing);
  });

  testWidgets('Free users see the Premium trial dialog for details', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: PremiumGenreSelectScreen()),
    );

    await tester.ensureVisible(
      find.byKey(const ValueKey('genre-group-noodles')),
    );
    await tester.tap(find.byKey(const ValueKey('genre-group-noodles')));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('ラーメン'));
    await tester.tap(find.text('ラーメン'));
    await tester.pumpAndSettle();

    expect(find.textContaining('7日間無料で試せます。'), findsOneWidget);
    expect(find.text('無料で試す'), findsOneWidget);
    expect(find.text('今はしない'), findsOneWidget);

    await tester.tap(find.text('今はしない'));
    await tester.pumpAndSettle();
    expect(find.text('Premium機能'), findsNothing);
  });

  testWidgets('active Premium users can select a detail genre', (
    WidgetTester tester,
  ) async {
    PremiumGenreSelection? selection;
    const entitlement = PremiumEntitlement(
      status: PremiumEntitlementStatus.active,
      source: PremiumEntitlementSource.freeTrial,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PremiumGenreSelectScreen(
          entitlement: entitlement,
          onGenreSelected: (value) => selection = value,
        ),
      ),
    );

    await tester.ensureVisible(
      find.byKey(const ValueKey('genre-group-noodles')),
    );
    await tester.tap(find.byKey(const ValueKey('genre-group-noodles')));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('ラーメン'));
    await tester.tap(find.text('ラーメン'));
    await tester.pumpAndSettle();

    expect(selection?.genre, RestaurantGenre.ramen);
    expect(find.text('Premium機能'), findsNothing);
  });

  testWidgets('おまかせ is available without Premium', (WidgetTester tester) async {
    PremiumGenreSelection? selection;

    await tester.pumpWidget(
      MaterialApp(
        home: PremiumGenreSelectScreen(
          onGenreSelected: (value) => selection = value,
        ),
      ),
    );

    await tester.tap(find.text('おまかせ'));
    await tester.pumpAndSettle();

    expect(selection?.isOmakase, isTrue);
  });
}
