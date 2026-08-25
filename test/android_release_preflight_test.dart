import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import '../tool/android_release_preflight.dart';

void main() {
  late Directory tempDirectory;
  late Map<String, String> validEnvironment;

  setUp(() {
    tempDirectory = Directory.systemTemp.createTempSync('swipeat-release-');
    final keystore = File(
      '${tempDirectory.path}${Platform.pathSeparator}upload.jks',
    )..writeAsStringSync('test keystore placeholder');
    validEnvironment = <String, String>{
      for (final name in androidReleaseEnvironmentVariables) name: 'configured',
      for (final name in androidReleaseDartDefines) name: 'configured',
      'SWIPEAT_APPLICATION_ID': 'jp.example.swipeat',
      'ANDROID_KEYSTORE_FILE': keystore.path,
      'ADMOB_APP_ID': 'ca-app-pub-1234567890123456~1234567890',
      'PREMIUM_ENTITLEMENT_SYNC_URL': 'https://api.example.test/entitlement',
    };
  });

  tearDown(() {
    if (tempDirectory.existsSync()) tempDirectory.deleteSync(recursive: true);
  });

  test('accepts complete production configuration without exposing values', () {
    final result = validateAndroidReleaseEnvironment(validEnvironment);

    expect(result.isValid, isTrue);
    expect(result.errors, isEmpty);
  });

  test('reports missing values by name only', () {
    validEnvironment.remove('FIREBASE_API_KEY');
    validEnvironment.remove('ANDROID_KEYSTORE_PASSWORD');

    final result = validateAndroidReleaseEnvironment(validEnvironment);

    expect(result.isValid, isFalse);
    expect(result.errors, contains(contains('FIREBASE_API_KEY')));
    expect(result.errors, contains(contains('ANDROID_KEYSTORE_PASSWORD')));
    expect(result.errors.join('\n'), isNot(contains('configured')));
  });

  test('rejects placeholder app IDs and test AdMob IDs', () {
    validEnvironment['SWIPEAT_APPLICATION_ID'] = 'com.example.swipeat';
    validEnvironment['ADMOB_APP_ID'] = 'ca-app-pub-3940256099942544~3347511713';

    final result = validateAndroidReleaseEnvironment(validEnvironment);

    expect(result.errors, contains(contains('公開用の固有ID')));
    expect(result.errors, contains(contains('テストID')));
  });

  test('requires HTTPS for the entitlement endpoint', () {
    validEnvironment['PREMIUM_ENTITLEMENT_SYNC_URL'] =
        'http://api.example.test';

    final result = validateAndroidReleaseEnvironment(validEnvironment);

    expect(result.errors, contains(contains('HTTPS')));
  });
}
