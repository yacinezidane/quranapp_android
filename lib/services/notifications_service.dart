import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../config/debug_config.dart';

// ============================================
// NOTIFICATION SERVICE
// ============================================

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();
  static final AudioPlayer _audioPlayer = AudioPlayer();

  // Channel configuration
  static const String _channelId = 'adhan_channel';
  static const String _channelName = 'أذان الصلاة';
  static const String _channelDescription = 'إشعارات مواقيت الصلاة';
  static const String _soundFileName = 'adan'; // without .mp3 extension

  /// Initialize notifications system
  static Future<void> initialize() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Africa/Algiers'));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        DebugConfig.log('Notification tapped: ${details.payload}'); // ← USE DEBUG LOG
      },
    );

    await _requestPermissions();

    DebugConfig.log('Notification Service initialized'); // ← USE DEBUG LOG
  }

  static Future<void> _requestPermissions() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      final notificationPermission = await androidPlugin.requestNotificationsPermission();
      DebugConfig.log('Notification permission: $notificationPermission');

      final exactAlarmPermission = await androidPlugin.requestExactAlarmsPermission();
      DebugConfig.log('Exact alarm permission: $exactAlarmPermission');
    }
  }

  static Future<void> showInstantNotification(String prayerName) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(_soundFileName),
      enableVibration: true,
      // vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      ongoing: false,
      autoCancel: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _plugin.show(
      0,
      'حان وقت الصلاة ⏰',
      'حان الآن وقت صلاة $prayerName',
      notificationDetails,
      payload: prayerName,
    );

    DebugConfig.log('Instant notification shown for $prayerName');
  }

  static Future<void> scheduleNotification({
    required int id,
    required String prayerName,
    required DateTime scheduleTime,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(_soundFileName),
      enableVibration: true,
      // vibrationPattern: Int64List.fromList([0, 1000, 500, 1000])! as Int64List?,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      ongoing: false,
      autoCancel: true,
      showWhen: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _plugin.zonedSchedule(
      id,
      'حان وقت الصلاة ⏰',
      'حان الآن وقت صلاة $prayerName',
      tz.TZDateTime.from(scheduleTime, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: prayerName,
    );

    DebugConfig.log('Scheduled notification #$id for $prayerName at $scheduleTime');
  }

  static Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
    DebugConfig.log('All notifications cancelled');
  }

  static Future<List<PendingNotificationRequest>>
  getPendingNotifications() async {
    final pending = await _plugin.pendingNotificationRequests();
    DebugConfig.log('Pending notifications: ${pending.length}');
    return pending;
  }

  /// Dispose audio player
  static Future<void> dispose() async {
    await _audioPlayer.dispose();
    debugPrint('🔇 Audio player disposed');
  }
}