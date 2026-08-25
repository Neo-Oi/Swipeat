import 'package:geolocator/geolocator.dart';

enum LocationAccessFailure {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  unavailable,
  disclosureDeclined,
}

class LocationAccessResult {
  const LocationAccessResult.success(this.position) : failure = null;

  const LocationAccessResult.failure(this.failure) : position = null;

  final Position? position;
  final LocationAccessFailure? failure;

  bool get isSuccess => position != null;
}

class LocationService {
  static Future<bool> needsPermissionDisclosure() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever;
  }

  static Future<LocationAccessResult> getCurrentPositionResult({
    bool requestPermission = true,
  }) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      return const LocationAccessResult.failure(
        LocationAccessFailure.serviceDisabled,
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied && requestPermission) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      return const LocationAccessResult.failure(
        LocationAccessFailure.permissionDenied,
      );
    }
    if (permission == LocationPermission.deniedForever) {
      return const LocationAccessResult.failure(
        LocationAccessFailure.permissionDeniedForever,
      );
    }

    try {
      return LocationAccessResult.success(
        await Geolocator.getCurrentPosition(),
      );
    } on Exception {
      return const LocationAccessResult.failure(
        LocationAccessFailure.unavailable,
      );
    }
  }

  static Future<Position?> getCurrentPosition({
    bool requestPermission = true,
  }) async {
    final result = await getCurrentPositionResult(
      requestPermission: requestPermission,
    );
    return result.position;
  }

  static Future<bool> openSettings(LocationAccessFailure failure) {
    if (failure == LocationAccessFailure.serviceDisabled) {
      return Geolocator.openLocationSettings();
    }
    return Geolocator.openAppSettings();
  }
}
