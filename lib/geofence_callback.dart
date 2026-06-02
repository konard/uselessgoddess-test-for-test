import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:native_geofence/native_geofence.dart';

import 'constants.dart';
import 'notification_service.dart';

/// Notification side-effect a geofence transition requires.
///
/// Kept as a plain enum so the decision logic ([exitNotificationActionFor]) is
/// a pure function that can be unit tested without any plugins or a live UI
/// isolate — which is exactly the situation when the app is terminated.
enum ExitNotificationAction {
  /// Show the "you left the zone" notification (on [GeofenceEvent.exit]).
  show,

  /// Clear the "you left the zone" notification (on [GeofenceEvent.enter]).
  cancel,

  /// Do nothing (for events this app does not act on, e.g. dwell).
  none,
}

/// Maps a geofence [event] to the notification action required by the issue:
///
///   * [GeofenceEvent.exit]  -> [ExitNotificationAction.show];
///   * [GeofenceEvent.enter] -> [ExitNotificationAction.cancel];
///   * anything else         -> [ExitNotificationAction.none].
///
/// This is intentionally a pure function of the event only. It does **not**
/// depend on the UI isolate, a [SendPort], or any app state, so it behaves
/// identically whether the app is in the foreground, the background, or fully
/// terminated.
ExitNotificationAction exitNotificationActionFor(GeofenceEvent event) {
  switch (event) {
    case GeofenceEvent.exit:
      return ExitNotificationAction.show;
    case GeofenceEvent.enter:
      return ExitNotificationAction.cancel;
    case GeofenceEvent.dwell:
      return ExitNotificationAction.none;
  }
}

/// Performs the notification side-effect for [action].
///
/// Touches only [NotificationService], which each isolate initialises lazily,
/// so it works from the dedicated background isolate that `native_geofence`
/// spins up when the OS delivers a geofence event to a terminated app.
Future<void> applyExitNotificationAction(ExitNotificationAction action) async {
  switch (action) {
    case ExitNotificationAction.show:
      await NotificationService.showExitNotification();
    case ExitNotificationAction.cancel:
      await NotificationService.cancelExitNotification();
    case ExitNotificationAction.none:
      break;
  }
}

/// Top-level entry point invoked by `native_geofence` in a background isolate
/// whenever a geofence transition occurs.
///
/// This callback runs even when the app is in the background **or fully
/// terminated**: the OS (Android `GeofencingClient` / iOS `CLLocationManager`)
/// wakes the process and `native_geofence` starts a background Flutter engine
/// that registers the app's plugins (including `flutter_local_notifications`)
/// and runs this function. That is what makes the exit notification arrive
/// while the app is switched off.
///
/// Behaviour required by the issue:
///   * on [GeofenceEvent.exit]  -> show the "you left the zone" notification;
///   * on [GeofenceEvent.enter] -> clear that notification.
///
/// Forwarding the event to the UI isolate is best-effort: when the app is
/// terminated the lookup returns null and is skipped, but the notification is
/// still delivered from this isolate.
@pragma('vm:entry-point')
Future<void> geofenceTriggered(GeofenceCallbackParams params) async {
  debugPrint(
    'geofenceTriggered: ${params.event.name} '
    'for ${params.geofences.map((g) => g.id).join(', ')}',
  );

  // Notify the UI isolate, if it happens to be alive. Returns null (and is
  // skipped) when the app is terminated — the notification below still fires.
  final SendPort? send = IsolateNameServer.lookupPortByName(kGeofencePortName);
  send?.send(params.event.name);

  await applyExitNotificationAction(exitNotificationActionFor(params.event));
}
