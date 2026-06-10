import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    await init();
  }

  static Future<void> init() async {
    tz_data.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // ✅ Channel ID must match the one used in home_screen.dart
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'r',                                 // ✅ same as in _scheduleNotification
      'রিমাইন্ডার',
      description: 'আপনার নোট এবং মিটিং রিমাইন্ডারের জন্য',
      importance: Importance.max,
      showBadge: true,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
      },
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> scheduleReminder(
      int id, String title, String body, DateTime scheduledTime) async {
    try {
      if (scheduledTime.isBefore(DateTime.now())) {
        scheduledTime = DateTime.now().add(const Duration(seconds: 1));
      }

      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'r',                               // ✅ same channel ID
            'রিমাইন্ডার',
            channelDescription: 'আপনার নোট এবং মিটিং রিমাইন্ডারের জন্য',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      print("✅ Notification scheduled for: $scheduledTime");
    } catch (e) {
      print("❌ Notification error: $e");
    }
  }

  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }
}