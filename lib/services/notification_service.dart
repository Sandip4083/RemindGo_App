import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'remindgo_channel';
  static const String _channelName = 'RemindGo Reminders';
  static const String _alarmChannelId = 'remindgo_alarm_channel';
  static const String _alarmChannelName = 'RemindGo Alarms';

  static Future<void> initialize() async {
    tzdata.initializeTimeZones();

    final tzName = await _localTimeZone();
    tz.setLocalLocation(tz.getLocation(tzName));

    await _requestPermissions();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print("Notification tapped: ${response.payload}");
      },
    );

    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Reminder pre-alert notifications',
      importance: Importance.high,
      playSound: true,
    );

    const alarmChannel = AndroidNotificationChannel(
      _alarmChannelId,
      _alarmChannelName,
      description: 'Main alarm notifications with custom sound',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(androidChannel);
    await androidPlugin?.createNotificationChannel(alarmChannel);

    print("✅ NotificationService initialized with TZ=$tzName");
  }

  static Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      await Permission.notification.request();
      await Permission.audio.request();
      await Permission.scheduleExactAlarm.request();

      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        await androidPlugin.requestNotificationsPermission();
        await androidPlugin.requestExactAlarmsPermission();
      }
    }
  }

  static Future<String?> getSelectedAlarmSound() async {
    final prefs = await SharedPreferences.getInstance();
    final uri = prefs.getString('alarm_sound_uri');

    if (uri != null && uri.isNotEmpty) {
      final audioPermission = await Permission.audio.status;
      if (!audioPermission.isGranted) {
        print("⚠️ Audio permission denied, using default");
        return null;
      }
    }

    return uri;
  }

  static Future<void> schedulePreAndMain({
    required int preId,
    required int mainId,
    required String title,
    required DateTime mainTime,
    required int preAlertMinutes,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;

    if (!notificationsEnabled) {
      print("⚠️ Notifications disabled. Skipping schedule.");
      return;
    }

    final preTime = mainTime.subtract(Duration(minutes: preAlertMinutes));

    if (preTime.isAfter(DateTime.now())) {
      await _scheduleNotification(
        id: preId,
        title: 'Reminder Soon',
        body: '$title in $preAlertMinutes minutes',
        scheduledDate: tz.TZDateTime.from(preTime, tz.local),
        isMainAlarm: false,
      );
    }

    if (mainTime.isAfter(DateTime.now())) {
      await _scheduleNotification(
        id: mainId,
        title: '🔔 Reminder',
        body: title,
        scheduledDate: tz.TZDateTime.from(mainTime, tz.local),
        isMainAlarm: true,
      );
    }
  }

  static Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required bool isMainAlarm,
  }) async {
    AndroidNotificationSound? sound;

    if (isMainAlarm) {
      final customUri = await getSelectedAlarmSound();
      if (customUri != null && customUri.isNotEmpty) {
        print("🎵 Using CUSTOM sound: $customUri");
        sound = UriAndroidNotificationSound(customUri);
      } else {
        print("🎵 Using DEFAULT alarm sound");
        sound = const RawResourceAndroidNotificationSound('alarm_sound');
      }
    }

    final androidDetails = AndroidNotificationDetails(
      isMainAlarm ? _alarmChannelId : _channelId,
      isMainAlarm ? _alarmChannelName : _channelName,
      channelDescription: isMainAlarm
          ? 'Main alarm with custom sound'
          : 'Pre-alert notifications',
      importance: isMainAlarm ? Importance.max : Importance.high,
      priority: Priority.high,
      playSound: true,
      sound: sound,
      enableVibration: isMainAlarm,
      vibrationPattern: isMainAlarm
          ? Int64List.fromList([0, 1000, 500, 1000])
          : Int64List.fromList([0, 500]),
      fullScreenIntent: isMainAlarm,
      category: isMainAlarm ? AndroidNotificationCategory.alarm : null,
      visibility: NotificationVisibility.public,
      autoCancel: true,
      timeoutAfter: isMainAlarm ? 60000 : 10000,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(body, contentTitle: title),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    print("⏰ Scheduled [$id] at $scheduledDate (Main: $isMainAlarm)");
  }

  static Future<void> cancel(int id) async {
    await _plugin.cancel(id);
  }

  static Future<void> cancelMultiple(List<int> ids) async {
    for (final id in ids) {
      await cancel(id);
    }
  }

  static Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }

  static Future<String> _localTimeZone() async {
    try {
      final offset = DateTime.now().timeZoneOffset;
      if (offset.inHours == 5 && offset.inMinutes == 330) {
        return "Asia/Kolkata";
      }
      return "UTC";
    } catch (_) {
      return "UTC";
    }
  }

  static int generateId() {
    return DateTime.now().millisecondsSinceEpoch.remainder(100000) +
        Random().nextInt(1000);
  }

  static Future<void> playTestAlarm(String? soundUri) async {
    if (soundUri != null && soundUri.isNotEmpty) {
      final status = await Permission.audio.request();
      if (!status.isGranted) {
        print("⚠️ Audio permission denied");
        soundUri = null;
      }
    }

    final sound = (soundUri != null && soundUri.isNotEmpty)
        ? UriAndroidNotificationSound(soundUri)
        : const RawResourceAndroidNotificationSound('alarm_sound');

    final androidDetails = AndroidNotificationDetails(
      _alarmChannelId,
      _alarmChannelName,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: sound,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
      timeoutAfter: 5000,
      autoCancel: true,
      fullScreenIntent: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
    );

    await _plugin.show(
      99999,
      '🔔 Test Alarm',
      'Testing alarm sound',
      NotificationDetails(android: androidDetails, iOS: iosDetails),
    );

    await Future.delayed(const Duration(seconds: 5));
    await cancel(99999);
  }
}
