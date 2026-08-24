import 'package:flutter_test/flutter_test.dart';
import 'package:swipeat/services/firebase_auth_service.dart';

void main() {
  test('environment configuration reports missing required fields safely', () {
    const configuration = FirebaseAuthConfiguration(
      apiKey: '',
      appId: '',
      messagingSenderId: '',
      projectId: '',
    );

    expect(configuration.isConfigured, isFalse);
    expect(
      configuration.missingRequiredFields,
      containsAll(<String>[
        'FIREBASE_API_KEY',
        'FIREBASE_APP_ID',
        'FIREBASE_MESSAGING_SENDER_ID',
        'FIREBASE_PROJECT_ID',
      ]),
    );
    expect(
      () => configuration.toFirebaseOptions(),
      throwsA(isA<FirebaseAuthConfigurationException>()),
    );
  });

  test('complete configuration creates FirebaseOptions without hardcoding', () {
    const configuration = FirebaseAuthConfiguration(
      apiKey: 'api-key',
      appId: 'app-id',
      messagingSenderId: 'sender-id',
      projectId: 'project-id',
      authDomain: 'project-id.firebaseapp.com',
      storageBucket: 'project-id.firebasestorage.app',
      measurementId: 'G-TEST',
    );

    final options = configuration.toFirebaseOptions();
    expect(options.apiKey, 'api-key');
    expect(options.appId, 'app-id');
    expect(options.messagingSenderId, 'sender-id');
    expect(options.projectId, 'project-id');
    expect(options.authDomain, 'project-id.firebaseapp.com');
  });

  test('auth service refuses to initialize when configuration is missing', () {
    final service = SwipeatFirebaseAuthService(
      configuration: const FirebaseAuthConfiguration(
        apiKey: '',
        appId: '',
        messagingSenderId: '',
        projectId: '',
      ),
    );

    expect(
      service.signInWithGoogle(),
      throwsA(isA<FirebaseAuthConfigurationException>()),
    );
  });
}
