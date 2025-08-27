import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Initialize Notification Service
  static Future<void> initialize() async {
    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosInitSettings =
        DarwinInitializationSettings();

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: iosInitSettings,
    );

    await _notificationsPlugin.initialize(initSettings);
    tz.initializeTimeZones(); // Required for scheduling
  }

  // Show Immediate Notification
  static Future<void> showInstantNotification(String title, String body) async {
    const NotificationDetails notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'task_channel',
        'Task Reminders',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );

    await _notificationsPlugin.show(0, title, body, notificationDetails);
  }

  // Schedule Notification (5 min before + on time)
  static Future<void> scheduleTaskNotifications(
    DateTime taskTime,
    String taskName,
  ) async {
    // Pre-reminder 5 min before
    final preReminderTime = taskTime.subtract(const Duration(minutes: 5));

    await _notificationsPlugin.zonedSchedule(
      0,
      'Reminder',
      'Your task "$taskName" starts in 5 minutes!',
      tz.TZDateTime.from(preReminderTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_channel',
          'Task Reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    // Alarm at exact time
    await _notificationsPlugin.zonedSchedule(
      1,
      'Task Time!',
      'Your task "$taskName" starts now!',
      tz.TZDateTime.from(taskTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_channel',
          'Task Reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
