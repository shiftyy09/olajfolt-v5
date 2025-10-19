// lib/szolgaltatasok/ertesites_szolgaltatas.dart
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class ErtesitesSzolgaltatas {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@drawable/ic_stat_notification');
    const DarwinInitializationSettings darwinSettings =
    DarwinInitializationSettings();
    final InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );
    await _notificationsPlugin.initialize(settings);
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    if (Platform.isAndroid) {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        final bool? canScheduleExactAlarms =
        await androidImplementation.canScheduleExactNotifications();
        if (canScheduleExactAlarms != true) {
          await androidImplementation.requestExactAlarmsPermission();
        }
      }
    }

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'karbantartas_csatorna_id',
          'Karbantartás Értesítések',
          channelDescription: 'Értesítések a közelgő karbantartásokról.',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@drawable/ic_stat_notification',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
    );
    print('Értesítés időzítve: "$title", ekkor: $scheduledDate');
  }

  // ÚJ FÜGGVÉNY: Hetente ismétlődő értesítés
  Future<void> scheduleWeeklyNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTenAM(), // Időzítés minden héten reggel 10-re
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'altalanos_emlekezteto_csatorna',
          'Általános Emlékeztetők',
          channelDescription: 'Hetente ismétlődő emlékeztetők.',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents:
      DateTimeComponents.dayOfWeekAndTime, // Ismétlés alapja
    );
    print('Heti értesítés időzítve: "$title"');
  }

  // Segédfüggvény, ami kiszámolja a következő reggel 10 órát
  tz.TZDateTime _nextInstanceOfTenAM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
    tz.TZDateTime(tz.local, now.year, now.month, now.day, 10);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    // Ez a logika most a következő napra időzít, de a matchDateTimeComponents miatt hetente fog ismétlődni.
    return scheduledDate;
  }

  Future<void> requestPermissions() async {
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
    print('Minden korábbi értesítés törölve.');
  }
}