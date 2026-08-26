import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipeat/models/restaurant_photo.dart';
import 'package:swipeat/widgets/restaurant_photo_gallery.dart';

void main() {
  const photos = <RestaurantPhoto>[
    RestaurantPhoto(url: 'https://example.test/photo-1.jpg'),
    RestaurantPhoto(url: 'https://example.test/photo-2.jpg'),
    RestaurantPhoto(url: 'https://example.test/photo-3.jpg'),
  ];

  testWidgets('loads one photo at a time and advances on tap', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: RestaurantPhotoGallery(photos: photos)),
      ),
    );
    await tester.pump();

    expect(find.text('1 / 3'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey(
          'restaurant-photo-image-https://example.test/photo-1.jpg',
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey(
          'restaurant-photo-image-https://example.test/photo-2.jpg',
        ),
      ),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('restaurant-photo-gallery')));
    await tester.pump();

    expect(find.text('2 / 3'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey(
          'restaurant-photo-image-https://example.test/photo-1.jpg',
        ),
      ),
      findsNothing,
    );
    expect(
      find.byKey(
        const ValueKey(
          'restaurant-photo-image-https://example.test/photo-2.jpg',
        ),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('restaurant-photo-gallery')));
    await tester.tap(find.byKey(const ValueKey('restaurant-photo-gallery')));
    await tester.pump();
    expect(find.text('1 / 3'), findsOneWidget);
  });

  testWidgets('shows author attribution when supplied', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RestaurantPhotoGallery(
            photos: [
              RestaurantPhoto(
                url: 'https://example.test/photo.jpg',
                authorAttributions: [
                  RestaurantPhotoAttribution(displayName: '投稿者A'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('写真提供: 投稿者A'), findsOneWidget);
  });
}
