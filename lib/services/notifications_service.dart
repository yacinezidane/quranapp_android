import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

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
    // Initialize timezone
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Africa/Algiers'));

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    // Initialize plugin
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // When user taps notification, play adhan
        _playAdhan();
      },
    );

    // Request permissions
    await _requestPermissions();

    debugPrint('✅ Notification Service initialized');
  }

  /// Request Android permissions
  static Future<void> _requestPermissions() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      // Request notification permission (Android 13+)
      final notificationPermission =
      await androidPlugin.requestNotificationsPermission();
      debugPrint('📱 Notification permission: $notificationPermission');

      // Request exact alarm permission (Android 12+)
      final exactAlarmPermission =
      await androidPlugin.requestExactAlarmsPermission();
      debugPrint('⏰ Exact alarm permission: $exactAlarmPermission');
    }
  }

  /// Play adhan audio
  static Future<void> _playAdhan() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      await _audioPlayer.play(AssetSource('sounds/adan.mp3'), volume: 1.0);
      debugPrint('🔊 Playing Adhan');
    } catch (e) {
      debugPrint('❌ Error playing Adhan: $e');
    }
  }

  /// Show instant notification (for testing)
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
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _plugin.show(
      0,
      'حان وقت الصلاة ⏰',
      'حان الآن وقت صلاة $prayerName',
      notificationDetails,
    );

    debugPrint('📢 Instant notification shown for $prayerName');
  }

  /// Schedule a notification for a specific time
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
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _plugin.zonedSchedule(
      id,
      'حان وقت الصلاة ⏰',
      'حان الآن وقت صلاة $prayerName',
      tz.TZDateTime.from(scheduleTime, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    debugPrint('📅 Scheduled notification #$id for $prayerName at $scheduleTime');
  }

  /// Cancel all scheduled notifications
  static Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
    debugPrint('🗑️ All notifications cancelled');
  }

  /// Get list of pending notifications
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    final pending = await _plugin.pendingNotificationRequests();
    debugPrint('📋 Pending notifications: ${pending.length}');
    return pending;
  }

  /// Dispose audio player
  static Future<void> dispose() async {
    await _audioPlayer.dispose();
    debugPrint('🔇 Audio player disposed');
  }
}