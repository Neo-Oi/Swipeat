import 'dart:math';

class DistanceCalculator {
  static int calculateDistanceMeters({
    required double fromLatitude,
    required double fromLongitude,
    required double toLatitude,
    required double toLongitude,
  }) {
    const earthRadiusMeters = 6371000;

    final fromLatRad = _toRadians(fromLatitude);
    final toLatRad = _toRadians(toLatitude);

    final deltaLatRad = _toRadians(toLatitude - fromLatitude);
    final deltaLonRad = _toRadians(toLongitude - fromLongitude);

    final a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(fromLatRad) *
            cos(toLatRad) *
            sin(deltaLonRad / 2) *
            sin(deltaLonRad / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return (earthRadiusMeters * c).round();
  }

  static double _toRadians(double degree) {
    return degree * pi / 180;
  }
}