import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:native_geofence/native_geofence.dart';

import 'constants.dart';
import 'geofence_service.dart';
import 'notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  await NativeGeofenceManager.instance.initialize();
  runApp(const GeofenceApp());
}

class GeofenceApp extends StatelessWidget {
  const GeofenceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Native Geofence Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ReceivePort _port = ReceivePort();

  String _status = 'No geofence yet';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // Listen for events forwarded by the background geofence callback.
    IsolateNameServer.removePortNameMapping(kGeofencePortName);
    IsolateNameServer.registerPortWithName(_port.sendPort, kGeofencePortName);
    _port.listen((dynamic event) {
      if (!mounted) return;
      setState(() => _status = 'Last event: $event');
    });
  }

  @override
  void dispose() {
    IsolateNameServer.removePortNameMapping(kGeofencePortName);
    _port.close();
    super.dispose();
  }

  Future<void> _createGeofence() async {
    setState(() {
      _busy = true;
      _status = 'Requesting permissions…';
    });
    try {
      final granted = await GeofenceService.requestPermissions();
      if (!granted) {
        _setStatus('Location & notification permissions are required.');
        return;
      }

      _setStatus('Reading your location…');
      final location = await GeofenceService.currentLocation();

      await GeofenceService.create(location);
      _setStatus(
        'Geofence created at '
        '${location.latitude.toStringAsFixed(5)}, '
        '${location.longitude.toStringAsFixed(5)} '
        '(${kGeofenceDiameterMeters.toStringAsFixed(0)} m diameter).',
      );
    } catch (e) {
      _setStatus('Failed to create geofence: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _setStatus(String message) {
    if (!mounted) return;
    setState(() => _status = message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Native Geofence Test')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.my_location, size: 72),
              const SizedBox(height: 24),
              Text(
                'Create a ${kGeofenceDiameterMeters.toStringAsFixed(0)} m '
                'geofence at your current location. You will get a '
                'notification when you leave it, which disappears once you '
                'come back.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _busy ? null : _createGeofence,
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_location_alt),
                label: const Text('Create geofence'),
              ),
              const SizedBox(height: 24),
              Text(
                _status,
                key: const Key('status_text'),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
