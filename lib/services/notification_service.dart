import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  // ১. সার্ভিস ইনিশিয়ালাইজ করা
  static Future<void> init() async {
    tz_data.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // নোটিফিকেশনে ক্লিক করলে কি হবে তা এখানে লিখতে পারেন
      },
    );

    // অ্যান্ড্রয়েড ১৩+ এর জন্য পারমিশন রিকোয়েস্ট
    _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
  }

  // ২. নোটিফিকেশন শিডিউল করা (সঠিক নাম: scheduleReminder)
  static Future<void> scheduleReminder(int id, String title, String body, DateTime scheduledTime) async {
    try {
      // যদি সময়টি বর্তমান সময়ের চেয়ে আগে হয়, তবে ১ সেকেন্ড যোগ করে রিমাইন্ডার সেট করবে যাতে এরর না দেয়
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
            'amar_hisab_reminders',
            'হিসাব রিমাইন্ডার',
            channelDescription: 'আপনার নোট এবং মিটিং রিমাইন্ডারের জন্য',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      print("Notification Scheduled for: $scheduledTime");
    } catch (e) {
      print("Notification Error: $e");
    }
  }

  // ৩. নোটিফিকেশন ক্যানসেল করা
  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }
}