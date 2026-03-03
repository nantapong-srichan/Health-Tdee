import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  Future<void> initNotifications() async {
    // Initialize timezone database and set local timezone from device
    tzdata.initializeTimeZones();
    
    // Try to detect and set device timezone
    try {
      final offset = DateTime.now().timeZoneOffset;
      final offsetHours = offset.inHours;
      final offsetMinutes = offset.inMinutes % 60;
      
      print('Device offset: UTC${offsetHours > 0 ? '+' : ''}$offsetHours:${offsetMinutes.toString().padLeft(2, '0')}');
      
      // List of common IANA timezone names to try based on offset
      // UTC+7 is Asia/Bangkok, Asia/Ho_Chi_Minh, etc.
      List<String> tzCandidates = [];
      
      if (offsetHours == 7 && offsetMinutes == 0) {
        tzCandidates = ['Asia/Bangkok', 'Asia/Ho_Chi_Minh', 'Asia/Phnom_Penh', 'Asia/Vientiane'];
      } else if (offsetHours == 8 && offsetMinutes == 0) {
        tzCandidates = ['Asia/Shanghai', 'Asia/Singapore', 'Australia/Perth', 'Asia/Manila'];
      } else {
        // Fallback: try Etc/GMT with reversed sign
        tzCandidates = ['Etc/GMT${-offsetHours}'];
      }
      
      bool tzSet = false;
      for (final tzName in tzCandidates) {
        try {
          final loc = tz.getLocation(tzName);
          tz.setLocalLocation(loc);
          print('Timezone set to: $tzName');
          tzSet = true;
          break;
        } catch (e) {
          // Try next candidate
        }
      }
      
      if (!tzSet) {
        print('Could not set timezone to any candidate, tz.local may be UTC');
      }
    } catch (e, st) {
      print('Error setting timezone: $e\n$st');
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
      // handle notification tapped logic here if needed
      // print('Notification tapped: ${response.payload}');
    });

    // Request runtime notification permission (Android 13+ / iOS)
    final status = await Permission.notification.request();
    if (!status.isGranted) {
      // Permission denied — notifications may not appear
      return;
    }

    // Create Android notification channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'insulin_reminder_channel',
      'Insulin Reminder',
      description: 'Channel สำหรับแจ้งเตือนการฉีดอินซูลิน',
      importance: Importance.max,
      playSound: true,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // TEST: Show immediate test notification to verify system works
    print('NOTIFICATION TEST: Showing test notification...');
    await _showTestNotification();
  }

  Future<void> scheduleInsulinReminder(int hour, int minute) async {
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);

    print('DEBUG: Current time: $now');
    print('DEBUG: Scheduled time (before adjustment): $scheduledDate');

    // ถ้าเวลาผ่านไปแล้วในวันนี้ ให้ตั้งสำหรับพรุ่งนี้
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
      print('DEBUG: Time passed today, scheduled for tomorrow: $scheduledDate');
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'insulin_reminder_channel',
      'Insulin Reminder',
      importance: Importance.max,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final tzDateTime = tz.TZDateTime.from(scheduledDate, tz.local);
    print('tz.local offset: ${tz.local.name}');
    print('DEBUG: TZDateTime: $tzDateTime');
    print('DEBUG: tz.local: ${tz.local}');
    print('DEBUG: Scheduled ID: ${hour * 100 + minute}');

    try {
      await _notificationsPlugin.zonedSchedule(
        hour * 100 + minute, // Unique ID
        'เตือนการฉีดอินซูลิน',
        'ถึงเวลาฉีดอินซูลินก่อนอาหารแล้ว',
        tzDateTime,
        notificationDetails,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      print('Scheduled insulin reminder for $hour:${minute.toString().padLeft(2, '0')}');
    } catch (e) {
      print('ERROR scheduling reminder: $e');
    }
  }

  Future<void> cancelInsulinReminder(int hour, int minute) async {
    final notificationId = hour * 100 + minute;
    await _notificationsPlugin.cancel(notificationId);
  }

  Future<void> cancelAllReminders() async {
    await _notificationsPlugin.cancelAll();
  }

  Future<void> _showTestNotification() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'insulin_reminder_channel',
      'Insulin Reminder',
      importance: Importance.max,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notificationsPlugin.show(
        999, // Test ID
        'ทดสอบระบบแจ้งเตือน',
        'ถ้าคุณเห็นข้อความนี้ ระบบแจ้งเตือนทำงานได้',
        notificationDetails,
      );
      print('Test notification shown successfully');
    } catch (e) {
      print('ERROR showing test notification: $e');
    }
  }
}
