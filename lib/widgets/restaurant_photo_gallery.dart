import 'package:flutter/material.dart';

import '../models/restaurant_photo.dart';

class RestaurantPhotoGallery extends StatefulWidget {
  const RestaurantPhotoGallery({
    super.key,
    required this.photos,
    this.height = 260,
  });

  final List<RestaurantPhoto> photos;
  final double height;

  @override
  State<RestaurantPhotoGallery> createState() => _RestaurantPhotoGalleryState();
}

class _RestaurantPhotoGalleryState extends State<RestaurantPhotoGallery> {
  int currentIndex = 0;

  List<RestaurantPhoto> get displayPhotos => widget.photos.take(3).toList();

  @override
  void didUpdateWidget(covariant RestaurantPhotoGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photos != widget.photos) {
      currentIndex = 0;
    }
  }

  void showNextPhoto() {
    if (displayPhotos.length < 2) return;
    setState(() {
      currentIndex = (currentIndex + 1) % displayPhotos.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final photos = displayPhotos;
    if (photos.isEmpty) {
      return _photoPlaceholder(widget.height, '写真なし');
    }

    final photo = photos[currentIndex];
    final authorNames = photo.authorAttributions
        .map((attribution) => attribution.displayName)
        .join('、');

    return Semantics(
      button: photos.length > 1,
      label: photos.length > 1
          ? '店舗写真 ${currentIndex + 1}/${photos.length}。タップで次の写真'
          : '店舗写真',
      child: GestureDetector(
        key: const ValueKey('restaurant-photo-gallery'),
        behavior: HitTestBehavior.opaque,
        onTap: photos.length > 1 ? showNextPhoto : null,
        child: SizedBox(
          height: widget.height,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                photo.url,
                key: ValueKey('restaurant-photo-image-${photo.url}'),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _photoPlaceholder(widget.height, '写真を表示できません');
                },
              ),
              if (photos.length > 1)
                Positioned(
                  right: 12,
                  top: 12,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      child: Text(
                        '${currentIndex + 1} / ${photos.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              if (authorNames.isNotEmpty)
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 8,
                  child: Text(
                    '写真提供: $authorNames',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      shadows: [Shadow(blurRadius: 3)],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _photoPlaceholder(double height, String text) {
    return Container(
      height: height,
      alignment: Alignment.center,
      color: Colors.grey.shade300,
      child: Text(text),
    );
  }
}
