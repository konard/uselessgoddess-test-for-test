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
