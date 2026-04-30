import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/alarm_service.dart';
import '../widgets/alarm_tile.dart';
import 'map_screen.dart';

class AlarmsScreen extends StatefulWidget {
  final AlarmService alarmService;

  const AlarmsScreen({super.key, required this.alarmService});

  @override
  State<AlarmsScreen> createState() => _AlarmsScreenState();
}

class _AlarmsScreenState extends State<AlarmsScreen> with WidgetsBindingObserver {
  BannerAd? _bannerAd;
  bool _bannerAdLoaded = false;

  AlarmService get _service => widget.alarmService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _service.addListener(_rebuild);
    _loadBannerAd();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _service.requestLocationPermission();
    }
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-2903696223935150/8238257216',
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _bannerAdLoaded = true),
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          _bannerAd = null;
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _service.removeListener(_rebuild);
    WidgetsBinding.instance.removeObserver(this);
    _bannerAd?.dispose();
    super.dispose();
  }

  void _showPermissionAlert() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cannot LocateYouUp'),
        content: const Text('Please enable Location Services to use alarms.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Geolocator.openAppSettings();
            },
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  void _openMapScreen() {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => MapScreen(
          onAlarmsAdded: (newAlarms) {
            for (final alarm in newAlarms) {
              _service.addAlarm(alarm);
            }
          },
        ),
      ),
    );
  }

  Future<void> _pickRingtone() async {
    final info = await _service.ringtoneService.pick();
    if (info != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ringtone: ${info.title}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Alarms'),
        actions: [
          if (Platform.isAndroid)
            IconButton(
              icon: const Icon(Icons.music_note),
              tooltip: 'Select ringtone',
              onPressed: _pickRingtone,
            ),
          IconButton(
            icon: const Icon(Icons.add_location_alt),
            tooltip: 'Add alarm',
            onPressed: _openMapScreen,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_service.isFiring) _buildStopAlarmBanner(),
          Expanded(child: _buildAlarmList()),
          if (_bannerAdLoaded && _bannerAd != null)
            SizedBox(
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
        ],
      ),
    );
  }

  Widget _buildStopAlarmBanner() {
    return Material(
      color: Colors.red,
      child: InkWell(
        onTap: () => _service.stopAlarm(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Row(
            children: [
              const Icon(Icons.alarm_off, color: Colors.white, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'STOP ALARM',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    if (_service.firingAlarmTitle != null)
                      Text(
                        'Arrived at ${_service.firingAlarmTitle}',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.touch_app, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlarmList() {
    if (_service.alarms.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No alarms yet.\nTap + to add a location alarm.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: _service.alarms.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final alarm = _service.alarms[index];
        final pos = _service.currentPosition;
        final distanceMeters = pos != null
            ? alarm.distanceMeters(pos.latitude, pos.longitude)
            : null;

        return AlarmTile(
          alarm: alarm,
          distanceMeters: distanceMeters,
          isLocationEnabled: _service.isLocationAuthorized,
          onToggle: (value) {
            if (!_service.isLocationAuthorized) {
              _showPermissionAlert();
              return;
            }
            _service.toggleAlarm(alarm, value: value);
          },
          onDelete: () => _service.deleteAlarm(alarm),
        );
      },
    );
  }
}
