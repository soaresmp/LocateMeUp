import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import '../models/alarm.dart';
import 'notification_service.dart';
import 'ringtone_service.dart';
import 'storage_service.dart';

class AlarmService extends ChangeNotifier {
  static const _locationChannel = MethodChannel('com.locatemeup/location');

  final StorageService _storage = StorageService();
  final RingtoneService ringtoneService = RingtoneService();

  List<Alarm> alarms = [];
  Position? currentPosition;
  bool isLocationAuthorized = false;
  bool isFiring = false;
  String? firingAlarmTitle;
  String? _firingAlarmId;

  StreamSubscription<Position>? _locationSubscription;

  int get activeAlarmCount => alarms.where((a) => a.isOn).length;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  Future<void> loadAlarms() async {
    alarms = await _storage.loadAlarms();
    await ringtoneService.load();
    await requestLocationPermission();
    _updateLocationMonitoring();
    notifyListeners();
  }

  Future<bool> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    isLocationAuthorized = permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
    notifyListeners();
    return isLocationAuthorized;
  }

  // ── Alarm CRUD ─────────────────────────────────────────────────────────────

  void addAlarm(Alarm alarm) {
    alarms.add(alarm);
    _storage.saveAlarms(alarms);
    _updateLocationMonitoring();
    notifyListeners();
  }

  void deleteAlarm(Alarm alarm) {
    alarm.isOn = false;
    alarms.remove(alarm);
    _storage.saveAlarms(alarms);
    _updateLocationMonitoring();
    notifyListeners();
  }

  void toggleAlarm(Alarm alarm, {required bool value}) {
    alarm.isOn = value;
    _storage.saveAlarms(alarms);
    _updateLocationMonitoring();
    notifyListeners();
  }

  // ── Stop alarm ─────────────────────────────────────────────────────────────

  Future<void> stopAlarm() async {
    await ringtoneService.stop();
    if (_firingAlarmId != null) {
      await NotificationService.instance.cancelNotification(_firingAlarmId!);
      _firingAlarmId = null;
    }
    isFiring = false;
    firingAlarmTitle = null;
    notifyListeners();
  }

  // ── Location monitoring ────────────────────────────────────────────────────

  void _updateLocationMonitoring() {
    if (activeAlarmCount > 0 && isLocationAuthorized) {
      _startLocationMonitoring();
      _startForegroundService();
    } else {
      _stopLocationMonitoring();
      _stopForegroundService();
    }
  }

  Future<void> _startForegroundService() async {
    if (!Platform.isAndroid) return;
    try {
      await _locationChannel.invokeMethod<void>('startService');
    } catch (_) {}
  }

  Future<void> _stopForegroundService() async {
    if (!Platform.isAndroid) return;
    try {
      await _locationChannel.invokeMethod<void>('stopService');
    } catch (_) {}
  }

  void _startLocationMonitoring() {
    if (_locationSubscription != null) return;
    const settings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 100,
    );
    _locationSubscription =
        Geolocator.getPositionStream(locationSettings: settings).listen(_onLocationUpdate);
  }

  void _stopLocationMonitoring() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
  }

  void _onLocationUpdate(Position position) {
    currentPosition = position;
    _checkAlarms(position);
    notifyListeners();
  }

  void _checkAlarms(Position position) {
    bool changed = false;
    for (final alarm in alarms) {
      if (alarm.isOn && alarm.isInRegion(position.latitude, position.longitude)) {
        alarm.isOn = false;
        changed = true;
        isFiring = true;
        firingAlarmTitle = alarm.title;
        _firingAlarmId = alarm.id;
        NotificationService.instance.showAlarmNotification(
          id: alarm.id,
          locationTitle: alarm.title,
        );
        ringtoneService.play();
      }
    }
    if (changed) {
      _storage.saveAlarms(alarms);
    }
  }

  @override
  void dispose() {
    _stopLocationMonitoring();
    ringtoneService.dispose();
    super.dispose();
  }
}
