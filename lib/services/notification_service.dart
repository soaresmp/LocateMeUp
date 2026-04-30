import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  void Function()? onStopRequested;

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onResponse,
    );

    const channel = AndroidNotificationChannel(
      'alarm_channel',
      'Location Alarms',
      description: 'Notifications for location-based alarms',
      importance: Importance.max,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  void _onResponse(NotificationResponse response) {
    if (response.actionId == 'stop_alarm') {
      onStopRequested?.call();
    }
  }

  Future<void> showAlarmNotification({
    required String id,
    required String locationTitle,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'alarm_channel',
      'Location Alarms',
      channelDescription: 'Notifications for location-based alarms',
      importance: Importance.max,
      priority: Priority.high,
      playSound: false,
      ongoing: true,
      autoCancel: false,
      actions: [
        AndroidNotificationAction('stop_alarm', 'Stop'),
      ],
    );
    const iosDetails = DarwinNotificationDetails(badgeNumber: 1);
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.show(
      id.hashCode,
      'Wake Up!',
      'You are arriving at $locationTitle',
      details,
    );
  }

  Future<void> cancelNotification(String id) async {
    await _plugin.cancel(id.hashCode);
  }
}
