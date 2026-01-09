import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);
    
    // Request permissions for iOS
    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    final plugin = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await plugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
  }

  Future<void> scheduleWarrantyNotification({
    required String itemId,
    required String itemName,
    required DateTime expiryDate,
    required bool enabled,
  }) async {
    if (!enabled) {
      await cancelNotification(itemId);
      return;
    }

    final now = DateTime.now();
    final daysUntilExpiry = expiryDate.difference(now).inDays;

    // Schedule notifications at different intervals
    final notificationSchedule = [
      {'days': 30, 'title': 'Warranty Expiring Soon', 'body': '$itemName warranty expires in 30 days'},
      {'days': 7, 'title': 'Warranty Alert', 'body': '$itemName warranty expires in 1 week'},
      {'days': 1, 'title': 'Warranty Expires Tomorrow', 'body': '$itemName warranty expires tomorrow!'},
      {'days': 0, 'title': 'Warranty Expired', 'body': '$itemName warranty has expired today'},
    ];

    // Cancel any existing notifications for this item
    await cancelNotification(itemId);

    // Schedule each notification
    for (var i = 0; i < notificationSchedule.length; i++) {
      final schedule = notificationSchedule[i];
      final daysBeforeExpiry = schedule['days'] as int;
      
      if (daysUntilExpiry >= daysBeforeExpiry) {
        final notificationDate = expiryDate.subtract(Duration(days: daysBeforeExpiry));
        
        if (notificationDate.isAfter(now)) {
          await _scheduleNotification(
            id: _getNotificationId(itemId, i),
            title: schedule['title'] as String,
            body: schedule['body'] as String,
            scheduledDate: notificationDate,
          );
        }
      }
    }
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'warranty_alerts',
      'Warranty Alerts',
      channelDescription: 'Notifications for warranty expiration alerts',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelNotification(String itemId) async {
    // Cancel all 4 possible notifications for this item
    for (var i = 0; i < 4; i++) {
      await _notifications.cancel(_getNotificationId(itemId, i));
    }
  }

  int _getNotificationId(String itemId, int index) {
    // Generate a unique ID for each notification
    // Use hash code of itemId + index to get unique integer
    return (itemId.hashCode + index).abs() % 2147483647;
  }

  Future<void> showImmediateNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'warranty_alerts',
      'Warranty Alerts',
      channelDescription: 'Notifications for warranty expiration alerts',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      title,
      body,
      details,
    );
  }
}
