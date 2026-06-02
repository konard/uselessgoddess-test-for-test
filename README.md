# native_geofence_test

A small Flutter application that exercises the
[`native_geofence`](https://pub.dev/packages/native_geofence) plugin.

## What it does

The app has a single screen with one **Create geofence** button. When pressed it:

1. Requests location (foreground + background) and notification permissions.
2. Reads the device's current GPS location.
3. Registers a geofence centred on that location with a **50 m diameter**
   (25 m radius) that listens for *enter* and *exit* transitions.

Geofence behaviour:

- When you **exit** the zone, a notification *"You left the zone"* is shown.
- When you **enter** the zone again, that same notification is **cleared**.

This matches the requirements in
[issue #1](https://github.com/uselessgoddess/test-for-test/issues/1).

## Background & terminated-app notifications

The exit notification is delivered **even when the app is in the background or
fully switched off** — it does not need to be running.

How it works:

- `native_geofence` registers the zone with the OS region-monitoring service
  (Android `GeofencingClient`, iOS `CLLocationManager`). The OS — not the app —
  watches your location.
- When you cross the boundary, the OS wakes the process and `native_geofence`
  starts a dedicated **background Flutter isolate** that runs
  [`geofenceTriggered`](lib/geofence_callback.dart). That isolate registers the
  app's plugins (including `flutter_local_notifications`) on its own, so the
  notification is posted without the UI ever being alive.
- Forwarding the event to the on-screen status text is best-effort: if the UI
  isolate is gone, the lookup is simply skipped and the notification still
  fires.

What makes this work:

| Platform | Enabler |
| -------- | ------- |
| Android  | Background-location permission (**"Allow all the time"**), the `native_geofence` broadcast receivers / foreground service and `RECEIVE_BOOT_COMPLETED` (re-registers geofences after reboot), all declared in [`AndroidManifest.xml`](android/app/src/main/AndroidManifest.xml) |
| iOS      | `NSLocationAlwaysAndWhenInUseUsageDescription`, the `location` background mode, and `NativeGeofencePlugin.setPluginRegistrantCallback` in [`AppDelegate.swift`](ios/Runner/AppDelegate.swift) so the relaunched background isolate can post notifications |

### Verifying it manually

1. Run the app, press **Create geofence**, and grant location
   **"Allow all the time"** plus notification permission.
2. Fully close the app (swipe it from the recents/app switcher).
3. Move ~30 m away (or use the emulator's location controls / a mock-location
   app to jump outside the 50 m circle). A *"You left the zone"* notification
   appears even though the app is closed.
4. Move back inside the circle — the notification clears.

> Note: the Android emulator only fires geofence events when something is
> actively reading the device location. Open Google Maps once to get a fix, as
> documented in the [`native_geofence` README](https://pub.dev/packages/native_geofence#known-issues).

## Platform requirements

| Platform | Minimum version |
| -------- | --------------- |
| Android  | API 23 (6.0)    |
| iOS      | 14.0            |

## Project layout

| File | Responsibility |
| ---- | -------------- |
| `lib/main.dart` | App entry point + single-screen UI |
| `lib/constants.dart` | Shared constants (radius, ids, port name) |
| `lib/geofence_service.dart` | Permissions, current location, `buildGeofence`, register/remove |
| `lib/geofence_callback.dart` | Background isolate callback: notify on exit, clear on enter |
| `lib/notification_service.dart` | Wrapper around `flutter_local_notifications` |

## Running

```bash
flutter pub get
flutter run
```

Grant the location permission **"Allow all the time"** so geofence events fire
while the app is in the background.

## Testing

```bash
flutter analyze
flutter test
```

- `test/geofence_test.dart` — unit tests asserting the geofence is built with a
  25 m radius (50 m diameter) and enter/exit triggers.
- `test/widget_test.dart` — widget tests for the single screen.

## Continuous integration

`.github/workflows/ci.yml` runs on every push and pull request:

1. **Analyze & test** — `dart format` check, `flutter analyze`, `flutter test`.
2. **Build Android** — builds a debug APK and uploads it as an artifact.
3. **Build iOS** — builds the iOS app without code signing.
