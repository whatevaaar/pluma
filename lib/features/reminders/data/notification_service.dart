import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Schedules the daily writing reminder as a local notification.
///
/// Fully offline — no server, no push service. Wraps
/// [FlutterLocalNotificationsPlugin] so the rest of the app depends on this
/// small surface instead of the plugin directly.
class NotificationService {
  NotificationService([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  static const _dailyReminderId = 1001;
  static const _channelId = 'daily_reminder';

  bool _initialized = false;

  /// Initializes the plugin and the timezone database. Safe to call more than
  /// once.
  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    try {
      final localName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localName));
    } on Object catch (e) {
      // Fall back to UTC rather than crashing if the platform can't report a
      // zone; the reminder time will be off but the app stays functional.
      debugPrint('[NotificationService] timezone lookup failed: $e');
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      // Permissions are requested explicitly when the user enables reminders.
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: darwin),
    );
    _initialized = true;
  }

  /// Asks the OS for permission to show notifications. Returns whether it was
  /// granted. Call before scheduling on first enable.
  Future<bool> requestPermissions() async {
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    return true;
  }

  /// (Re)schedules the daily reminder at [hour]:[minute], repeating every day.
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    await init();
    await cancelReminder();
    await _plugin.zonedSchedule(
      _dailyReminderId,
      'Es hora de escribir ✍️',
      'Dedica unos minutos a tus palabras.',
      _nextInstanceOf(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Recordatorios diarios',
          channelDescription: 'Recordatorio para escribir cada día',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      // Repeat daily at the same wall-clock time.
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelReminder() => _plugin.cancel(_dailyReminderId);

  /// The next [hour]:[minute] in local time — today if still ahead, else
  /// tomorrow.
  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
