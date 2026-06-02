import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'constants.dart';

/// Thin wrapper around [FlutterLocalNotificationsPlugin] that knows how to
/// show and clear the single "geofence exit" notification.
///
/// All methods are static because the geofence callback runs in a separate
/// background isolate that does not share state with the UI isolate; each
/// isolate calls [init] lazily before showing or cancelling a notification.
class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /// Initializes the underlying plugin. Safe to call multiple times.
  static Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings);
    _initialized = true;
  }

  /// Shows the notification that informs the user they have left the zone.
  ///
  /// Uses a fixed [kExitNotificationId] so it can later be cancelled by
  /// [cancelExitNotification] when the user re-enters the zone.
  static Future<void> showExitNotification() async {
    await init();

    const androidDetails = AndroidNotificationDetails(
      'geofence_exit',
      'Geofence exit alerts',
      channelDescription: 'Shown when you leave the geofence zone.',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails(
      interruptionLevel: InterruptionLevel.active,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      kExitNotificationId,
      'You left the zone',
      'You exited the geofence. This alert clears when you come back.',
      details,
    );
  }

  /// Cancels the exit notification (called when the user re-enters the zone).
  static Future<void> cancelExitNotification() async {
    await init();
    await _plugin.cancel(kExitNotificationId);
  }
}
