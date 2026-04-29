import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'screens/alarms_screen.dart';
import 'services/alarm_service.dart';
import 'services/notification_service.dart';

final AlarmService alarmService = AlarmService();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  await NotificationService.instance.initialize();
  await alarmService.loadAlarms();
  runApp(const LocateMeUpApp());
}

class LocateMeUpApp extends StatelessWidget {
  const LocateMeUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LocateMeUp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      home: AlarmsScreen(alarmService: alarmService),
    );
  }
}
