import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/alarm.dart';
import 'notification_service.dart';
import 'storage_service.dart';

class AlarmService extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<Alarm> alarms = [];
  Position? currentPosition;
  bool isLocationAuthorized = false;

  StreamSubscription<Position>? _locationSubscription;

  int get activeAlarmCount => alarms.where((a) => a.isOn).length;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  Future<void> loadAlarms() async {
    alarms = await _storage.loadAlarms();
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

  // ── Location monitoring ────────────────────────────────────────────────────

  void _updateLocationMonitoring() {
    if (activeAlarmCount > 0 && isLocationAuthorized) {
      _startLocationMonitoring();
    } else {
      _stopLocationMonitoring();
    }
  }

  void _startLocationMonitoring() {
    if (_locationSubscription != null) return;
    const settings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 100, // metres — mirrors iOS defaultDistanceFilter
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
        NotificationService.instance.showAlarmNotification(
          id: alarm.id,
          locationTitle: alarm.title,
        );
        _playAlarmSound();
      }
    }
    if (changed) {
      _storage.saveAlarms(alarms);
    }
  }

  Future<void> _playAlarmSound() async {
    await _audioPlayer.play(AssetSource('wakeup.mp3'));
  }

  @override
  void dispose() {
    _stopLocationMonitoring();
    _audioPlayer.dispose();
    super.dispose();
  }
}
