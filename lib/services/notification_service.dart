import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    // flutter_local_notifications ^22.3.0 requires named parameters
    await _flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification tapped: ${response.payload}');
      },
    );

    _isInitialized = true;
  }

  Future<void> requestPermission() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      await androidImplementation?.requestNotificationsPermission();
      await androidImplementation?.requestExactAlarmsPermission();
    }
  }

  int _generateNotificationId(String taskId) {
    return taskId.hashCode;
  }

  Future<void> scheduleTaskReminder(
    String taskId,
    String title,
    DateTime reminderAt,
  ) async {
    if (reminderAt.isBefore(DateTime.now())) {
      debugPrint('Reminder time is in the past. Not scheduling.');
      return;
    }

    final int notificationId = _generateNotificationId(taskId);
    final tz.TZDateTime scheduledDate = tz.TZDateTime.from(
      reminderAt,
      tz.local,
    );

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'task_reminders_channel',
          'Task Reminders',
          channelDescription: 'Notifications for task reminders',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id: notificationId,
      title: 'Task Reminder: $title',
      body: 'It is time to work on your task!',
      scheduledDate: scheduledDate,
      notificationDetails: platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: taskId,
    );

    debugPrint(
      'Scheduled notification $notificationId for task $taskId at $scheduledDate',
    );
  }

  Future<void> cancelTaskReminder(String taskId) async {
    final int notificationId = _generateNotificationId(taskId);
    await _flutterLocalNotificationsPlugin.cancel(id: notificationId);
    debugPrint('Cancelled notification $notificationId for task $taskId');
  }

  Future<void> rescheduleTaskReminder(
    String taskId,
    String title,
    DateTime reminderAt,
  ) async {
    await cancelTaskReminder(taskId);
    await scheduleTaskReminder(taskId, title, reminderAt);
  }
}
