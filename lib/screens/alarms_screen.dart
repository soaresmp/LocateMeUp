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
        title: const Text('Location required'),
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
    if (Platform.isAndroid) {
      final info = await _service.ringtoneService.pick();
      if (info != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ringtone: ${info.title}')),
        );
      }
    } else if (Platform.isIOS) {
      await _showIosTonePicker();
    }
  }

  Future<void> _showIosTonePicker() async {
    final tones = await _service.ringtoneService.getAvailableTones();
    if (!mounted || tones.isEmpty) return;
    final current = _service.ringtoneService.selected;
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Select Alarm Tone',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ),
            ...tones.map((tone) => ListTile(
                  title: Text(tone.title),
                  trailing: current?.uri == tone.uri
                      ? const Icon(Icons.check, color: Colors.blue)
                      : null,
                  onTap: () async {
                    await _service.ringtoneService.select(tone);
                    if (mounted) Navigator.pop(ctx);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Tone: ${tone.title}')),
                      );
                    }
                  },
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeCount = _service.activeAlarmCount;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Alarms',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
            if (_service.alarms.isNotEmpty)
              Text(
                activeCount == 0
                    ? 'All alarms off'
                    : '$activeCount alarm${activeCount == 1 ? '' : 's'} active',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.normal,
                  color: activeCount > 0
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
          ],
        ),
        actions: [
          if (Platform.isAndroid || Platform.isIOS)
            IconButton(
              icon: const Icon(Icons.music_note_outlined),
              tooltip: 'Select alarm tone',
              onPressed: _pickRingtone,
            ),
        ],
      ),
      body: Column(
        children: [
          if (_service.isFiring) _buildStopAlarmBanner(theme),
          Expanded(child: _buildAlarmList(theme)),
          if (_bannerAdLoaded && _bannerAd != null)
            SizedBox(
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openMapScreen,
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Add alarm'),
      ),
    );
  }

  Widget _buildStopAlarmBanner(ThemeData theme) {
    return Material(
      color: Colors.red.shade600,
      child: InkWell(
        onTap: () => _service.stopAlarm(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          child: Row(
            children: [
              const Icon(Icons.alarm_off, color: Colors.white, size: 26),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'STOP ALARM',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 0.5,
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Stop',
                  style: TextStyle(
                    color: Colors.red.shade600,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlarmList(ThemeData theme) {
    if (_service.alarms.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_location_alt_outlined,
              size: 72,
              color: theme.colorScheme.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 20),
            Text(
              'No alarms yet',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap "Add alarm" to set a location alarm',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 96),
      itemCount: _service.alarms.length,
      itemBuilder: (context, index) {
        final alarm = _service.alarms[index];
        final pos = _service.currentPosition;
        final distanceMeters =
            pos != null ? alarm.distanceMeters(pos.latitude, pos.longitude) : null;

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
