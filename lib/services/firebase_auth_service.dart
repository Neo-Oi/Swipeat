import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Firebase 初期化に必要な値。すべてビルド時に注入し、リポジトリへ直書きしない。
class FirebaseAuthConfiguration {
  const FirebaseAuthConfiguration({
    required this.apiKey,
    required this.appId,
    required this.messagingSenderId,
    required this.projectId,
    this.authDomain,
    this.storageBucket,
    this.measurementId,
    this.serverClientId,
  });

  factory FirebaseAuthConfiguration.fromEnvironment() {
    return const FirebaseAuthConfiguration(
      apiKey: String.fromEnvironment('FIREBASE_API_KEY'),
      appId: String.fromEnvironment('FIREBASE_APP_ID'),
      messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
      projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
      authDomain: String.fromEnvironment('FIREBASE_AUTH_DOMAIN'),
      storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
      measurementId: String.fromEnvironment('FIREBASE_MEASUREMENT_ID'),
      serverClientId: String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID'),
    );
  }

  final String apiKey;
  final String appId;
  final String messagingSenderId;
  final String projectId;
  final String? authDomain;
  final String? storageBucket;
  final String? measurementId;
  final String? serverClientId;

  bool get isConfigured =>
      apiKey.isNotEmpty &&
      appId.isNotEmpty &&
      messagingSenderId.isNotEmpty &&
      projectId.isNotEmpty;

  List<String> get missingRequiredFields {
    final missing = <String>[];
    if (apiKey.isEmpty) missing.add('FIREBASE_API_KEY');
    if (appId.isEmpty) missing.add('FIREBASE_APP_ID');
    if (messagingSenderId.isEmpty) {
      missing.add('FIREBASE_MESSAGING_SENDER_ID');
    }
    if (projectId.isEmpty) missing.add('FIREBASE_PROJECT_ID');
    return List<String>.unmodifiable(missing);
  }

  FirebaseOptions toFirebaseOptions() {
    if (!isConfigured) {
      throw FirebaseAuthConfigurationException(missingRequiredFields);
    }

    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
      authDomain: _nonEmptyOrNull(authDomain),
      storageBucket: _nonEmptyOrNull(storageBucket),
      measurementId: _nonEmptyOrNull(measurementId),
    );
  }

  static String? _nonEmptyOrNull(String? value) {
    return value == null || value.isEmpty ? null : value;
  }
}

class FirebaseAuthConfigurationException implements Exception {
  const FirebaseAuthConfigurationException(this.missingFields);

  final List<String> missingFields;

  @override
  String toString() {
    return 'Firebase設定が不足しています: ${missingFields.join(', ')}';
  }
}

/// Free/Premium の境界から呼び出す Google ログインサービス。
class SwipeatFirebaseAuthService {
  SwipeatFirebaseAuthService({FirebaseAuthConfiguration? configuration})
    : configuration =
          configuration ?? FirebaseAuthConfiguration.fromEnvironment();

  final FirebaseAuthConfiguration configuration;

  FirebaseApp? _app;
  FirebaseAuth? _auth;
  bool _googleSignInInitialized = false;

  Future<FirebaseAuth> _authInstance() async {
    if (!configuration.isConfigured) {
      throw FirebaseAuthConfigurationException(
        configuration.missingRequiredFields,
      );
    }

    final app = _app ??= await _initializeFirebase();
    return _auth ??= FirebaseAuth.instanceFor(app: app);
  }

  Future<FirebaseApp> _initializeFirebase() async {
    for (final app in Firebase.apps) {
      if (app.name == defaultFirebaseAppName) return app;
    }

    return Firebase.initializeApp(options: configuration.toFirebaseOptions());
  }

  /// User 操作から呼び出す Google ログイン。
  Future<UserCredential?> signInWithGoogle() async {
    final auth = await _authInstance();

    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      return auth.signInWithPopup(provider);
    }

    final googleSignIn = GoogleSignIn.instance;
    if (!_googleSignInInitialized) {
      await googleSignIn.initialize(
        serverClientId: configuration.serverClientId?.isEmpty == true
            ? null
            : configuration.serverClientId,
      );
      _googleSignInInitialized = true;
    }

    final account = await googleSignIn.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw StateError('Google Sign-In から ID token を取得できませんでした');
    }

    final credential = GoogleAuthProvider.credential(idToken: idToken);
    return auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    final auth = await _authInstance();
    if (!kIsWeb && _googleSignInInitialized) {
      await GoogleSignIn.instance.signOut();
    }
    await auth.signOut();
  }

  Stream<User?> authStateChanges() async* {
    final auth = await _authInstance();
    yield* auth.authStateChanges();
  }
}
