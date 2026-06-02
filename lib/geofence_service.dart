import 'package:geolocator/geolocator.dart';
import 'package:native_geofence/native_geofence.dart';
import 'package:permission_handler/permission_handler.dart';

import 'constants.dart';
import 'geofence_callback.dart';

/// Builds the [Geofence] used by the app: a circular zone centred on
/// [location] with a 50 m diameter ([kGeofenceRadiusMeters] = 25 m radius)
/// that fires on both enter and exit transitions.
Geofence buildGeofence(Location location) {
  return Geofence(
    id: kGeofenceId,
    location: location,
    radiusMeters: kGeofenceRadiusMeters,
    triggers: const {GeofenceEvent.enter, GeofenceEvent.exit},
    iosSettings: const IosGeofenceSettings(initialTrigger: true),
    androidSettings: const AndroidGeofenceSettings(
      initialTriggers: {GeofenceEvent.enter, GeofenceEvent.exit},
    ),
  );
}

/// Coordinates location permissions, reading the user position and registering
/// the geofence with the OS.
class GeofenceService {
  /// Requests the runtime permissions needed for background geofencing and
  /// notifications. Returns `true` only when every required permission is
  /// granted.
  static Future<bool> requestPermissions() async {
    final location = await Permission.location.request();
    final locationAlways = await Permission.locationAlways.request();
    final notification = await Permission.notification.request();
    return location.isGranted &&
        locationAlways.isGranted &&
        notification.isGranted;
  }

  /// Reads the device's current position and converts it to a [Location].
  ///
  /// Throws if location services are disabled or permissions are denied.
  static Future<Location> currentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServiceDisabledException();
    }
    final position = await Geolocator.getCurrentPosition();
    return Location(latitude: position.latitude, longitude: position.longitude);
  }

  /// Registers the geofence centred on [location] with the OS.
  static Future<void> create(Location location) async {
    await NativeGeofenceManager.instance.createGeofence(
      buildGeofence(location),
      geofenceTriggered,
    );
  }

  /// Removes the previously created geofence, if any.
  static Future<void> remove() async {
    await NativeGeofenceManager.instance.removeGeofenceById(kGeofenceId);
  }

  /// Returns the ids of all currently registered geofences.
  static Future<List<String>> registeredIds() async {
    return NativeGeofenceManager.instance.getRegisteredGeofenceIds();
  }
}
