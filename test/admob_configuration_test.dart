import 'package:flutter_test/flutter_test.dart';
import 'package:swipeat/services/ad_service.dart';

void main() {
  test('Debug configuration uses Google test banner ID', () {
    final configuration = AdMobConfiguration.fromEnvironment();

    expect(configuration.isConfigured, isTrue);
    expect(
      configuration.bannerAdUnitId,
      'ca-app-pub-3940256099942544/6300978111',
    );
  });

  test('release configuration accepts an injected production ID', () {
    const configuration = AdMobConfiguration(
      bannerAdUnitId: 'ca-app-pub-production/banner',
    );

    expect(configuration.isConfigured, isTrue);
    expect(configuration.bannerAdUnitId, contains('production'));
  });
}
