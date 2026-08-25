import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipeat/services/ad_service.dart';
import 'package:swipeat/services/candidate_pool.dart';

void main() {
  const service = AdService();

  group('AdService', () {
    test('shows break ads after 5, 10 and 15 Free candidates', () {
      for (final completedCount in [5, 10, 15]) {
        expect(
          service.shouldShowBreakAd(
            mode: CandidatePoolMode.free,
            completedCount: completedCount,
            hasMoreCandidates: true,
          ),
          isTrue,
        );
      }
    });

    test('shows an ad on the final Free page, but not in Premium', () {
      expect(
        service.shouldShowBreakAd(
          mode: CandidatePoolMode.free,
          completedCount: 20,
          hasMoreCandidates: false,
        ),
        isTrue,
      );
      expect(
        service.shouldShowBreakAd(
          mode: CandidatePoolMode.free,
          completedCount: 3,
          hasMoreCandidates: false,
        ),
        isTrue,
      );
      expect(
        service.shouldShowBreakAd(
          mode: CandidatePoolMode.premium,
          completedCount: 5,
          hasMoreCandidates: true,
        ),
        isFalse,
      );
    });
  });

  testWidgets('AdSlot has a large, non-actionable ad area', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: AdSlot())));

    expect(find.byType(AdSlot), findsOneWidget);
    expect(find.text('広告領域'), findsOneWidget);
    // 180px の広告本体 + 上下16pxの余白。
    expect(tester.getSize(find.byType(AdSlot)).height, 212);
  });

  testWidgets('hidden AdSlot renders no ad area', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AdSlot(visible: false))),
    );

    expect(find.text('広告領域'), findsNothing);
  });
}
