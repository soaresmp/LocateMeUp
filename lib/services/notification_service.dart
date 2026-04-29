import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _plugin.initialize(settings);

    // Create the Android notification channel
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
      playSound: true,
    );
    const iosDetails = DarwinNotificationDetails(badgeNumber: 1);
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.show(
      id.hashCode,
      'Wake Up',
      'You are arriving at $locationTitle',
      details,
    );
  }
}
