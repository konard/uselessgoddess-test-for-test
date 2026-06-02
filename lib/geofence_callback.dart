import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:native_geofence/native_geofence.dart';

import 'constants.dart';
import 'notification_service.dart';

/// Top-level entry point invoked by `native_geofence` in a background isolate
/// whenever a geofence transition occurs.
///
/// Behaviour required by the issue:
///   * on [GeofenceEvent.exit]  -> show the "you left the zone" notification;
///   * on [GeofenceEvent.enter] -> clear that notification.
///
/// It also forwards the event name to the UI isolate (when the app is running)
/// so the screen can display the current state.
@pragma('vm:entry-point')
Future<void> geofenceTriggered(GeofenceCallbackParams params) async {
  debugPrint(
    'geofenceTriggered: ${params.event.name} '
    'for ${params.geofences.map((g) => g.id).join(', ')}',
  );

  // Notify the UI isolate, if it is alive.
  final SendPort? send = IsolateNameServer.lookupPortByName(kGeofencePortName);
  send?.send(params.event.name);

  switch (params.event) {
    case GeofenceEvent.exit:
      await NotificationService.showExitNotification();
    case GeofenceEvent.enter:
      await NotificationService.cancelExitNotification();
    case GeofenceEvent.dwell:
      // Not used by this app.
      break;
  }
}
