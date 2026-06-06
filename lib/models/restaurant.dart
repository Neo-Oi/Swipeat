class Restaurant {
  const Restaurant({
    required this.name,
    required this.tags,
    required this.budget,
    required this.description,
    required this.companions,
    required this.budgets,
    required this.distanceMeters,
    required this.categories,
    this.googlePlaceId,
    this.address,
    this.latitude,
    this.longitude,
    this.rating,
    this.userRatingCount,
    this.photoUrl,
    this.isOpenNow,
  });

  final String name;
  final List<String> tags;
  final String budget;
  final String description;
  final List<String> companions;
  final List<String> budgets;
  final int distanceMeters;
  final List<String> categories;

  final String? googlePlaceId;
  final String? address;
  final double? latitude;
  final double? longitude;
  final double? rating;
  final int? userRatingCount;
  final String? photoUrl;
  final bool? isOpenNow;
}