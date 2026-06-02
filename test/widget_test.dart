// Widget tests for the geofence test app's single screen.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:native_geofence_test/main.dart';

void main() {
  testWidgets('Home screen shows the create-geofence button and status', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const GeofenceApp());

    // The single action button is present.
    expect(
      find.widgetWithText(ElevatedButton, 'Create geofence'),
      findsOneWidget,
    );

    // The screen explains the 50 m geofence behaviour.
    expect(find.textContaining('50 m'), findsWidgets);

    // The status text starts in its initial state.
    expect(find.byKey(const Key('status_text')), findsOneWidget);
    expect(find.text('No geofence yet'), findsOneWidget);
  });

  testWidgets('Create geofence button is tappable', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const GeofenceApp());

    final button = find.widgetWithText(ElevatedButton, 'Create geofence');
    final ElevatedButton widget = tester.widget(button);
    expect(widget.onPressed, isNotNull);
  });
}
