/// Shared constants for the geofence test app.
///
/// These values are referenced both by the UI isolate ([main]) and by the
/// background isolate that runs the geofence callback, so they must live in a
/// dependency-free file that both can import.
library;

/// Identifier used for the single geofence this app manages.
const String kGeofenceId = 'user_zone';

/// The geofence diameter requested by the issue (50 meters).
const double kGeofenceDiameterMeters = 50;

/// The geofence radius. `native_geofence` is configured with a radius, so a
/// 50 m diameter corresponds to a 25 m radius.
const double kGeofenceRadiusMeters = kGeofenceDiameterMeters / 2;

/// Notification id for the "you left the zone" alert.
///
/// A fixed id is used so the same notification can be cancelled when the user
/// returns to the zone.
const int kExitNotificationId = 1001;

/// Name under which the UI isolate registers a [SendPort] so the background
/// geofence callback can forward events back to the running app.
const String kGeofencePortName = 'native_geofence_send_port';
