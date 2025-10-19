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

    // ==========================================================
    // ===          FONTOS RÉSZ AZ IOS MŰKÖDÉSHEZ             ===
    // ==========================================================
    // Ez a blokk mondja meg a csomagnak, hogy iOS-en kérjen engedélyt
    // a hang, a jelvény (piros pötty az ikonon) és a felugró értesítés megjelenítésére.
    const DarwinInitializationSettings darwinSettings =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    // ==========================================================

    final InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    // Itt történik a plugin inicializálása a fenti beállításokkal.
    // iOS-en ez a hívás fogja feldobni az engedélykérő ablakot az app első indulásakor.
    await _notificationsPlugin.initialize(settings);
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    // Android specifikus, futásidejű engedélykérés a pontos riasztásokhoz
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

    // Az értesítés időzítése
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
        // iOS beállítások (egyelőre alap, de a hangot engedélyezi)
        iOS: DarwinNotificationDetails(
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
    );
    print('Értesítés időzítve: "$title", ekkor: $scheduledDate');
  }

  Future<void> scheduleWeeklyNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTenAM(),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'altalanos_emlekezteto_csatorna',
          'Általános Emlékeztetők',
          channelDescription: 'Hetente ismétlődő emlékeztetők.',
        ),
        iOS: DarwinNotificationDetails(
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
    print('Heti értesítés időzítve: "$title"');
  }

  tz.TZDateTime _nextInstanceOfTenAM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
    tz.TZDateTime(tz.local, now.year, now.month, now.day, 10);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
    // iOS-en az init() végzi az engedélykérést, itt nincs külön teendő.
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
    print('Minden korábbi értesítés törölve.');
  }
}