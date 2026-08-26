class RestaurantPhotoAttribution {
  const RestaurantPhotoAttribution({required this.displayName, this.uri});

  final String displayName;
  final String? uri;
}

class RestaurantPhoto {
  const RestaurantPhoto({
    required this.url,
    this.authorAttributions = const [],
  });

  final String url;
  final List<RestaurantPhotoAttribution> authorAttributions;
}
