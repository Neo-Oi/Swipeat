import 'dart:io';

/// Environment variables consumed by the Android Gradle release build.
const androidReleaseEnvironmentVariables = <String>[
  'SWIPEAT_APPLICATION_ID',
  'ANDROID_KEYSTORE_FILE',
  'ANDROID_KEYSTORE_PASSWORD',
  'ANDROID_KEY_ALIAS',
  'ANDROID_KEY_PASSWORD',
  'ADMOB_APP_ID',
];

/// Dart defines required for all production Android features.
const androidReleaseDartDefines = <String>[
  'GOOGLE_MAPS_API_KEY',
  'ADMOB_BANNER_AD_UNIT_ID',
  'PREMIUM_PRODUCT_ID',
  'PREMIUM_ENTITLEMENT_SYNC_URL',
  'FIREBASE_API_KEY',
  'FIREBASE_APP_ID',
  'FIREBASE_MESSAGING_SENDER_ID',
  'FIREBASE_PROJECT_ID',
  'GOOGLE_SERVER_CLIENT_ID',
];

class AndroidReleasePreflightResult {
  const AndroidReleasePreflightResult(this.errors);

  final List<String> errors;

  bool get isValid => errors.isEmpty;
}

/// Checks production configuration without printing any secret values.
AndroidReleasePreflightResult validateAndroidReleaseEnvironment(
  Map<String, String> environment, {
  bool checkKeystoreFile = true,
}) {
  final errors = <String>[];

  for (final name in androidReleaseEnvironmentVariables) {
    if (_isBlank(environment[name])) {
      errors.add('$name が未設定です。');
    }
  }
  for (final name in androidReleaseDartDefines) {
    if (_isBlank(environment[name])) {
      errors.add('$name を --dart-define 用の環境変数として設定してください。');
    }
  }

  final applicationId = environment['SWIPEAT_APPLICATION_ID'];
  if (!_isBlank(applicationId) && !_isValidApplicationId(applicationId!)) {
    errors.add('SWIPEAT_APPLICATION_ID がAndroidの形式ではありません。');
  }
  if (applicationId == 'com.example.swipeat') {
    errors.add('SWIPEAT_APPLICATION_ID は公開用の固有IDへ変更してください。');
  }

  final keystorePath = environment['ANDROID_KEYSTORE_FILE'];
  if (checkKeystoreFile && !_isBlank(keystorePath)) {
    final file = File(keystorePath!);
    if (!file.existsSync() ||
        !file.statSync().type.toString().contains('file')) {
      errors.add('ANDROID_KEYSTORE_FILE が存在するファイルを指していません。');
    }
  }

  final admobAppId = environment['ADMOB_APP_ID'];
  if (!_isBlank(admobAppId) && admobAppId!.contains('3940256099942544')) {
    errors.add('ADMOB_APP_ID にGoogleのテストIDを指定しています。');
  }

  final endpoint = environment['PREMIUM_ENTITLEMENT_SYNC_URL'];
  if (!_isBlank(endpoint) && !endpoint!.startsWith('https://')) {
    errors.add('PREMIUM_ENTITLEMENT_SYNC_URL はHTTPSで指定してください。');
  }

  return AndroidReleasePreflightResult(List<String>.unmodifiable(errors));
}

bool _isBlank(String? value) => value == null || value.trim().isEmpty;

bool _isValidApplicationId(String value) {
  return RegExp(
    r'^[A-Za-z][A-Za-z0-9_]*(\.[A-Za-z][A-Za-z0-9_]*)+$',
  ).hasMatch(value);
}

void main() {
  final result = validateAndroidReleaseEnvironment(Platform.environment);
  if (!result.isValid) {
    stderr.writeln('Android Release preflight failed:');
    for (final error in result.errors) {
      stderr.writeln('- $error');
    }
    exitCode = 1;
    return;
  }

  stdout.writeln(
    'Android Release preflight passed. AABの署名・Application ID・target SDKは生成物でも確認してください。',
  );
}
