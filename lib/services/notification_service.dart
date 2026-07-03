import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'dart:developer' as developer;
import 'package:intl/intl.dart';
import '../models/medicine.dart';
import '../models/reminder.dart';
import '../models/history.dart';
import 'database_service.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  NotificationService._init();

  Future<void> initialize() async {
    tz.initializeTimeZones();
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      final String timeZoneName = timezoneInfo.identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      developer.log("Error setting local timezone: $e");
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
  }

  Future<void> requestPermissions() async {
    final androidImplementation =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();
    }
  }

  static void onDidReceiveNotificationResponse(NotificationResponse details) {
    _handleNotificationAction(details);
  }

  @pragma('vm:entry-point')
  static void notificationTapBackground(NotificationResponse details) {
    _handleNotificationAction(details);
  }

  static Future<void> _handleNotificationAction(NotificationResponse details) async {
    final payload = details.payload;
    if (payload == null) return;

    final parts = payload.split('|');
    if (parts.length < 5) return;

    final medicineId = int.tryParse(parts[0]);
    final reminderId = int.tryParse(parts[1]);
    final medicineName = parts[2];
    final dosage = parts[3];
    final timeStr = parts[4];

    if (medicineId == null || reminderId == null) return;

    final todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    if (details.actionId == 'action_taken') {
      final history = History(
        medicineId: medicineId,
        reminderId: reminderId,
        date: todayDate,
        status: 'Taken',
        createdAt: DateTime.now(),
      );
      await DatabaseService.instance.insertHistory(history);
      
      final medicine = await DatabaseService.instance.getMedicineById(medicineId);
      if (medicine != null && medicine.stock > 0) {
        await DatabaseService.instance.updateMedicine(
          medicine.copyWith(stock: medicine.stock - 1),
          await DatabaseService.instance.getRemindersForMedicine(medicineId),
        );
      }
    } else if (details.actionId == 'action_skipped') {
      final history = History(
        medicineId: medicineId,
        reminderId: reminderId,
        date: todayDate,
        status: 'Skipped',
        createdAt: DateTime.now(),
      );
      await DatabaseService.instance.insertHistory(history);
    } else if (details.actionId == 'action_snooze') {
      await instance.scheduleSnoozeNotification(
        medicineId: medicineId,
        reminderId: reminderId,
        medicineName: medicineName,
        dosage: dosage,
        timeStr: timeStr,
      );
    }
  }

  Future<void> scheduleSnoozeNotification({
    required int medicineId,
    required int reminderId,
    required String medicineName,
    required String dosage,
    required String timeStr,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'medicare_snooze_channel',
      'MediCare Snooze Notifications',
      channelDescription: 'Channel untuk notifikasi tunda minum obat',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);
    final payload = "$medicineId|$reminderId|$medicineName|$dosage|$timeStr";

    final scheduledTime = tz.TZDateTime.now(tz.local).add(const Duration(minutes: 10));
    final snoozeId = reminderId + 10000;

    await _localNotifications.zonedSchedule(
      id: snoozeId,
      title: 'Saatnya Minum Obat (Ditunda) 💊',
      body: '$medicineName - $dosage',
      scheduledDate: scheduledTime,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  Future<void> scheduleMedicineNotifications(Medicine medicine, List<Reminder> reminders) async {
    final cleanHex = medicine.color.replaceFirst('#', '');
    int colorVal = 0xff3b82f6;
    if (cleanHex.length == 6) {
      colorVal = int.parse('ff$cleanHex', radix: 16);
    } else if (cleanHex.length == 8) {
      colorVal = int.parse(cleanHex, radix: 16);
    }
    final notificationColor = Color(colorVal);

    for (var reminder in reminders) {
      if (!reminder.isActive) continue;

      final parts = reminder.time.split(':');
      if (parts.length < 2) continue;
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;

      final androidDetails = AndroidNotificationDetails(
        'medicare_reminder_channel',
        'MediCare Reminders',
        channelDescription: 'Channel untuk pengingat jadwal minum obat harian',
        importance: Importance.max,
        priority: Priority.high,
        color: notificationColor,
        actions: <AndroidNotificationAction>[
          const AndroidNotificationAction(
            'action_taken',
            '✅ Sudah diminum',
            showsUserInterface: false,
          ),
          const AndroidNotificationAction(
            'action_snooze',
            '⏰ Ingatkan lagi',
            showsUserInterface: false,
          ),
          const AndroidNotificationAction(
            'action_skipped',
            '❌ Lewati',
            showsUserInterface: false,
          ),
        ],
      );

      final details = NotificationDetails(android: androidDetails);
      final payload = "${medicine.id}|${reminder.id}|${medicine.name}|${medicine.dosage}|${reminder.time}";

      if (reminder.repeatType == 'Every Day') {
        await _scheduleDaily(reminder.id!, medicine.name, medicine.dosage, hour, minute, details, payload);
      } else if (reminder.repeatType == 'Mon-Fri') {
        for (int i = 1; i <= 5; i++) {
          final id = reminder.id! * 10 + i;
          await _scheduleWeekly(id, medicine.name, medicine.dosage, hour, minute, i, details, payload);
        }
      } else if (reminder.repeatType == 'Custom') {
        final dayMap = {
          'Senin': 1, 'Sen': 1, 'Monday': 1, 'Mon': 1,
          'Selasa': 2, 'Sel': 2, 'Tuesday': 2, 'Tue': 2,
          'Rabu': 3, 'Rab': 3, 'Wednesday': 3, 'Wed': 3,
          'Kamis': 4, 'Kam': 4, 'Thursday': 4, 'Thu': 4,
          'Jumat': 5, 'Jum': 5, 'Friday': 5, 'Fri': 5,
          'Sabtu': 6, 'Sab': 6, 'Saturday': 6, 'Sat': 6,
          'Minggu': 7, 'Min': 7, 'Sunday': 7, 'Sun': 7,
        };
        for (var dayStr in reminder.days) {
          final weekday = dayMap[dayStr];
          if (weekday != null) {
            final id = reminder.id! * 10 + weekday;
            await _scheduleWeekly(id, medicine.name, medicine.dosage, hour, minute, weekday, details, payload);
          }
        }
      }
    }
  }

  Future<void> _scheduleDaily(
    int id,
    String title,
    String dosage,
    int hour,
    int minute,
    NotificationDetails details,
    String payload,
  ) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _localNotifications.zonedSchedule(
      id: id,
      title: 'Saatnya Minum Obat 💊',
      body: '$title - $dosage',
      scheduledDate: scheduledDate,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  Future<void> _scheduleWeekly(
    int id,
    String title,
    String dosage,
    int hour,
    int minute,
    int weekday,
    NotificationDetails details,
    String payload,
  ) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    while (scheduledDate.weekday != weekday || scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _localNotifications.zonedSchedule(
      id: id,
      title: 'Saatnya Minum Obat 💊',
      body: '$title - $dosage',
      scheduledDate: scheduledDate,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: payload,
    );
  }

  Future<void> cancelReminderNotifications(int reminderId) async {
    await _localNotifications.cancel(id: reminderId);
    for (int i = 1; i <= 7; i++) {
      await _localNotifications.cancel(id: reminderId * 10 + i);
    }
    await _localNotifications.cancel(id: reminderId + 10000);
  }

  Future<void> cancelMedicineNotifications(Medicine medicine, List<Reminder> reminders) async {
    for (var reminder in reminders) {
      await cancelReminderNotifications(reminder.id!);
    }
  }

  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }
}
