// Unit tests for the core geofence configuration.

import 'package:flutter_test/flutter_test.dart';
import 'package:native_geofence/native_geofence.dart';

import 'package:native_geofence_test/constants.dart';
import 'package:native_geofence_test/geofence_callback.dart';
import 'package:native_geofence_test/geofence_service.dart';

void main() {
  group('constants', () {
    test('radius is half of the 50 m diameter', () {
      expect(kGeofenceDiameterMeters, 50);
      expect(kGeofenceRadiusMeters, 25);
    });
  });

  group('buildGeofence', () {
    const location = Location(latitude: 40.75798, longitude: -73.98554);
    final geofence = buildGeofence(location);

    test('uses the configured id and location', () {
      expect(geofence.id, kGeofenceId);
      expect(geofence.location.latitude, location.latitude);
      expect(geofence.location.longitude, location.longitude);
    });

    test('has a 25 m radius (50 m diameter)', () {
      expect(geofence.radiusMeters, kGeofenceRadiusMeters);
      expect(geofence.radiusMeters * 2, kGeofenceDiameterMeters);
    });

    test('triggers on both enter and exit', () {
      expect(geofence.triggers, contains(GeofenceEvent.enter));
      expect(geofence.triggers, contains(GeofenceEvent.exit));
    });
  });

  group('exitNotificationActionFor (background / terminated app)', () {
    // These assertions cover the logic that runs in the dedicated background
    // isolate native_geofence spins up when the OS delivers a geofence event
    // to a terminated app. The mapping is a pure function of the event, so it
    // behaves identically whether the app is foregrounded, backgrounded, or
    // fully switched off.
    test('exit shows the "you left the zone" notification', () {
      expect(
        exitNotificationActionFor(GeofenceEvent.exit),
        ExitNotificationAction.show,
      );
    });

    test('enter clears the notification', () {
      expect(
        exitNotificationActionFor(GeofenceEvent.enter),
        ExitNotificationAction.cancel,
      );
    });

    test('dwell does nothing', () {
      expect(
        exitNotificationActionFor(GeofenceEvent.dwell),
        ExitNotificationAction.none,
      );
    });
  });
}
