import 'package:flutter_test/flutter_test.dart';
import 'package:swipeat/data/chain_brand_dictionary.dart';
import 'package:swipeat/models/restaurant_genre.dart';

void main() {
  const dictionary = ChainBrandDictionary();

  group('ChainBrandDictionary', () {
    final expectedGenres = <String, RestaurantGenre>{
      'すき家': RestaurantGenre.gyudon,
      '松屋': RestaurantGenre.gyudon,
      '松のや': RestaurantGenre.tonkatsu,
      '一蘭': RestaurantGenre.ramen,
      '丸亀製麺': RestaurantGenre.udon,
      'スシロー': RestaurantGenre.sushi,
      'CoCo壱番屋': RestaurantGenre.curry,
      'マクドナルド': RestaurantGenre.hamburger,
      'びっくりドンキー': RestaurantGenre.hamburg,
      'サイゼリヤ': RestaurantGenre.italian,
      '餃子の王将': RestaurantGenre.gyoza,
      '大阪王将': RestaurantGenre.gyoza,
      '焼肉きんぐ': RestaurantGenre.yakiniku,
    };

    for (final entry in expectedGenres.entries) {
      test('${entry.key} maps to ${entry.value.name}', () {
        final definition = dictionary.findByPlaceName('${entry.key} 駅前店');

        expect(definition, isNotNull);
        expect(definition!.brand, entry.key);
        expect(definition.primaryGenre, entry.value);
        expect(definition.isChain, isTrue);
      });
    }

    test('does not confuse 松のや with 松屋', () {
      expect(dictionary.findByPlaceName('松のや 新宿店')?.brand, '松のや');
      expect(dictionary.findByPlaceName('松屋 新宿店')?.brand, '松屋');
    });

    test('does not confuse 餃子の王将 with 大阪王将', () {
      expect(dictionary.findByPlaceName('餃子の王将 梅田店')?.brand, '餃子の王将');
      expect(dictionary.findByPlaceName('大阪王将 梅田店')?.brand, '大阪王将');
    });

    test('normalizes spaces and punctuation in place names', () {
      expect(dictionary.findByPlaceName('ＣｏＣｏ 壱番屋')?.primaryGenre, isNull);
      expect(
        dictionary.findByPlaceName('CoCo・壱番屋 京都店')?.primaryGenre,
        RestaurantGenre.curry,
      );
    });

    test('returns null for an unregistered restaurant', () {
      expect(dictionary.findByPlaceName('個人食堂 駅前店'), isNull);
      expect(dictionary.findByPlaceName(''), isNull);
    });
  });
}
