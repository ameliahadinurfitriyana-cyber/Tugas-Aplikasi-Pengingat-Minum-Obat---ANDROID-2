import 'dart:io';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/medicine.dart';
import '../models/reminder.dart';
import '../models/history.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class MedicineProvider extends ChangeNotifier {
  List<Medicine> _medicines = [];
  List<Reminder> _reminders = [];
  List<History> _history = [];
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;

  List<Medicine> get medicines => _medicines;
  List<Reminder> get reminders => _reminders;
  List<History> get history => _history;
  bool get isDarkMode => _isDarkMode;
  bool get notificationsEnabled => _notificationsEnabled;

  final DatabaseService _dbService = DatabaseService.instance;
  final NotificationService _notifService = NotificationService.instance;

  MedicineProvider() {
    _loadPreferences();
    refreshData();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
    notifyListeners();
  }

  Future<void> toggleDarkMode(bool value) async {
    _isDarkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
    notifyListeners();
  }

  Future<void> toggleNotifications(bool value) async {
    _notificationsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', value);
    
    if (value) {
      await rescheduleAllNotifications();
    } else {
      await _notifService.cancelAllNotifications();
    }
    notifyListeners();
  }

  Future<void> refreshData() async {
    _medicines = await _dbService.getAllMedicines();
    _reminders = await _dbService.getAllReminders();
    _history = await _dbService.getAllHistory();
    notifyListeners();
  }

  Future<void> addMedicine(Medicine medicine, List<Reminder> reminders) async {
    final medicineId = await _dbService.insertMedicine(medicine, reminders);
    final insertedMedicine = medicine.copyWith(id: medicineId);
    final insertedReminders = await _dbService.getRemindersForMedicine(medicineId);

    if (_notificationsEnabled) {
      await _notifService.scheduleMedicineNotifications(insertedMedicine, insertedReminders);
    }
    await refreshData();
  }

  Future<void> updateMedicine(Medicine medicine, List<Reminder> reminders) async {
    final oldReminders = await _dbService.getRemindersForMedicine(medicine.id!);
    await _notifService.cancelMedicineNotifications(medicine, oldReminders);

    await _dbService.updateMedicine(medicine, reminders);

    final updatedReminders = await _dbService.getRemindersForMedicine(medicine.id!);
    if (_notificationsEnabled) {
      await _notifService.scheduleMedicineNotifications(medicine, updatedReminders);
    }
    await refreshData();
  }

  Future<void> deleteMedicine(int id) async {
    final idx = _medicines.indexWhere((m) => m.id == id);
    if (idx != -1) {
      final medicine = _medicines[idx];
      final oldReminders = await _dbService.getRemindersForMedicine(id);
      await _notifService.cancelMedicineNotifications(medicine, oldReminders);
    }

    await _dbService.deleteMedicine(id);
    await refreshData();
  }

  Future<void> recordHistory(int medicineId, int reminderId, String status) async {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final hist = History(
      medicineId: medicineId,
      reminderId: reminderId,
      date: todayStr,
      status: status,
      createdAt: DateTime.now(),
    );

    await _dbService.insertHistory(hist);

    if (status == 'Taken') {
      final idx = _medicines.indexWhere((m) => m.id == medicineId);
      if (idx != -1) {
        final medicine = _medicines[idx];
        if (medicine.stock > 0) {
          final updatedStock = medicine.stock - 1;
          final updatedMed = medicine.copyWith(stock: updatedStock);
          final medReminders = await _dbService.getRemindersForMedicine(medicineId);
          await _dbService.updateMedicine(updatedMed, medReminders);
        }
      }
    }

    await refreshData();
  }

  bool shouldReminderOccur(Reminder reminder, Medicine medicine, DateTime date) {
    final cleanDate = DateTime(date.year, date.month, date.day);
    final startClean = DateTime(medicine.startDate.year, medicine.startDate.month, medicine.startDate.day);
    final endClean = DateTime(medicine.endDate.year, medicine.endDate.month, medicine.endDate.day);

    if (cleanDate.isBefore(startClean) || cleanDate.isAfter(endClean)) {
      return false;
    }

    if (reminder.repeatType == 'Every Day') {
      return true;
    }

    if (reminder.repeatType == 'Mon-Fri') {
      return date.weekday >= 1 && date.weekday <= 5;
    }

    if (reminder.repeatType == 'Custom') {
      final dayNames = {
        1: ['Monday', 'Mon', 'Senin', 'Sen'],
        2: ['Tuesday', 'Tue', 'Selasa', 'Sel'],
        3: ['Wednesday', 'Wed', 'Rabu', 'Rab'],
        4: ['Thursday', 'Thu', 'Kamis', 'Kam'],
        5: ['Friday', 'Fri', 'Jumat', 'Jum'],
        6: ['Saturday', 'Sat', 'Sabtu', 'Sab'],
        7: ['Sunday', 'Sun', 'Minggu', 'Min'],
      };

      final todayNames = dayNames[date.weekday] ?? [];
      for (var name in todayNames) {
        if (reminder.days.any((d) => d.toLowerCase() == name.toLowerCase())) {
          return true;
        }
      }
    }

    return false;
  }

  List<MedicineScheduleItem> getSchedulesForDate(DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final List<MedicineScheduleItem> items = [];

    for (var medicine in _medicines) {
      final medReminders = _reminders.where((r) => r.medicineId == medicine.id).toList();
      for (var reminder in medReminders) {
        if (shouldReminderOccur(reminder, medicine, date)) {
          final histEntry = _history.firstWhere(
            (h) => h.medicineId == medicine.id && h.reminderId == reminder.id && h.date == dateStr,
            orElse: () => History(id: -1, medicineId: -1, reminderId: -1, date: '', status: 'Pending', createdAt: DateTime.now()),
          );

          String status = histEntry.status;

          if (histEntry.id == -1) {
            final parts = reminder.time.split(':');
            if (parts.length >= 2) {
              final hr = int.tryParse(parts[0]) ?? 0;
              final mn = int.tryParse(parts[1]) ?? 0;
              final reminderTime = DateTime(date.year, date.month, date.day, hr, mn);
              
              if (DateTime.now().isAfter(reminderTime)) {
                status = 'Missed';
              }
            }
          }

          items.add(MedicineScheduleItem(
            medicine: medicine,
            reminder: reminder,
            status: status,
            time: reminder.time,
            historyId: histEntry.id == -1 ? null : histEntry.id,
          ));
        }
      }
    }

    items.sort((a, b) => a.time.compareTo(b.time));
    return items;
  }

  double getAdherenceRate() {
    if (_history.isEmpty) return 100.0;
    
    final takenCount = _history.where((h) => h.status == 'Taken').length;
    final totalCount = _history.length;
    
    if (totalCount == 0) return 100.0;
    return (takenCount / totalCount) * 100;
  }

  Map<String, int> getHistoryStatusCounts() {
    int taken = 0;
    int skipped = 0;
    int missed = 0;

    for (var h in _history) {
      if (h.status == 'Taken') taken++;
      if (h.status == 'Skipped') skipped++;
      if (h.status == 'Missed') missed++;
    }

    final todaySchedules = getSchedulesForDate(DateTime.now());
    for (var sched in todaySchedules) {
      if (sched.status == 'Missed' && sched.historyId == null) {
        missed++;
      }
    }

    return {
      'Taken': taken,
      'Skipped': skipped,
      'Missed': missed,
    };
  }

  Future<void> rescheduleAllNotifications() async {
    await _notifService.cancelAllNotifications();
    if (!_notificationsEnabled) return;

    for (var medicine in _medicines) {
      final medReminders = _reminders.where((r) => r.medicineId == medicine.id).toList();
      await _notifService.scheduleMedicineNotifications(medicine, medReminders);
    }
  }

  Future<String?> backupDatabase() async {
    try {
      final dbPath = await _dbService.getDatabasePath();
      final File dbFile = File(dbPath);

      if (await dbFile.exists()) {
        String backupPath;
        if (Platform.isAndroid) {
          final extDirs = await getExternalStorageDirectories(type: StorageDirectory.documents);
          if (extDirs != null && extDirs.isNotEmpty) {
            backupPath = p.join(extDirs.first.path, 'medicinereminder_backup.db');
          } else {
            final extDir = await getExternalStorageDirectory();
            backupPath = p.join(extDir!.path, 'medicinereminder_backup.db');
          }
        } else {
          final docDir = await getApplicationDocumentsDirectory();
          backupPath = p.join(docDir.path, 'medicinereminder_backup.db');
        }

        final backupFile = File(backupPath);
        await backupFile.parent.create(recursive: true);
        await dbFile.copy(backupFile.path);
        developer.log("Database backed up to: $backupPath");
        return backupPath;
      }
    } catch (e) {
      developer.log("Error backing up database: $e");
    }
    return null;
  }

  Future<bool> restoreDatabase() async {
    try {
      final dbPath = await _dbService.getDatabasePath();
      
      String backupPath;
      if (Platform.isAndroid) {
        final extDirs = await getExternalStorageDirectories(type: StorageDirectory.documents);
        if (extDirs != null && extDirs.isNotEmpty) {
          backupPath = p.join(extDirs.first.path, 'medicinereminder_backup.db');
        } else {
          final extDir = await getExternalStorageDirectory();
          backupPath = p.join(extDir!.path, 'medicinereminder_backup.db');
        }
      } else {
        final docDir = await getApplicationDocumentsDirectory();
        backupPath = p.join(docDir.path, 'medicinereminder_backup.db');
      }

      final File backupFile = File(backupPath);

      if (await backupFile.exists()) {
        await _dbService.close();
        
        final File dbFile = File(dbPath);
        await backupFile.copy(dbFile.path);
        
        await refreshData();
        await rescheduleAllNotifications();
        developer.log("Database restored from: $backupPath");
        return true;
      }
    } catch (e) {
      developer.log("Error restoring database: $e");
    }
    return false;
  }
}

class MedicineScheduleItem {
  final Medicine medicine;
  final Reminder reminder;
  final String status; // "Taken", "Skipped", "Missed", "Pending"
  final String time;
  final int? historyId;

  MedicineScheduleItem({
    required this.medicine,
    required this.reminder,
    required this.status,
    required this.time,
    this.historyId,
  });
}
