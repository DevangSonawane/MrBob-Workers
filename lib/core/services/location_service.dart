import 'package:geolocator/geolocator.dart';

/// A vendor position.
class VendorLocation {
  const VendorLocation(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}

/// Thin wrapper around geolocator so the rest of the app never touches the
/// plugin directly (and so it can be swapped for a fake in tests).
///
/// Only foreground location is needed: the H3 guide asks for location while
/// the app is open, and the vendor only receives offers while the app keeps
/// sending a position.
class LocationService {
  const LocationService();

  /// Asks for foreground location permission if it was not granted yet.
  /// Returns false when the permission was refused or location services are
  /// switched off on the device.
  Future<bool> ensurePermission() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return false;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (_) {
      return false;
    }
  }

  /// The current position, or null when it could not be resolved.
  Future<VendorLocation?> currentPosition() async {
    try {
      if (!await ensurePermission()) return null;
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return VendorLocation(position.latitude, position.longitude);
    } catch (_) {
      return null;
    }
  }
}
