import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipeat/widgets/location_permission_disclosure.dart';
import 'package:swipeat/services/location_service.dart';

void main() {
  testWidgets('explains foreground location use before permission', (
    tester,
  ) async {
    bool? accepted;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () async {
                accepted = await showLocationPermissionDisclosure(context);
              },
              child: const Text('open'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('現在地の利用について'), findsOneWidget);
    expect(find.textContaining('バックグラウンドでは取得しません'), findsOneWidget);
    expect(find.text('あとで'), findsOneWidget);
    expect(find.text('許可して続ける'), findsOneWidget);

    await tester.tap(find.text('許可して続ける'));
    await tester.pumpAndSettle();

    expect(accepted, isTrue);
  });

  test('provides recovery guidance for each location failure', () {
    expect(
      locationFailureMessage(LocationAccessFailure.serviceDisabled),
      contains('設定からオン'),
    );
    expect(
      locationFailureMessage(LocationAccessFailure.permissionDeniedForever),
      contains('端末の設定'),
    );
    expect(
      locationFailureMessage(LocationAccessFailure.disclosureDeclined),
      contains('許可すると'),
    );
  });
}
