import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/medicine.dart';
import '../models/reminder.dart';
import '../models/history.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('medicinereminder.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE medicines (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        dosage TEXT NOT NULL,
        type TEXT NOT NULL,
        color TEXT NOT NULL,
        notes TEXT,
        stock INTEGER NOT NULL,
        startDate TEXT NOT NULL,
        endDate TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medicineId INTEGER NOT NULL,
        time TEXT NOT NULL,
        repeatType TEXT NOT NULL,
        days TEXT,
        isActive INTEGER NOT NULL,
        FOREIGN KEY (medicineId) REFERENCES medicines (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medicineId INTEGER NOT NULL,
        reminderId INTEGER NOT NULL,
        date TEXT NOT NULL,
        status TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (medicineId) REFERENCES medicines (id) ON DELETE CASCADE,
        FOREIGN KEY (reminderId) REFERENCES reminders (id) ON DELETE CASCADE
      )
    ''');
  }

  // --- Medicine & Reminder Transactional Operations ---

  Future<int> insertMedicine(Medicine medicine, List<Reminder> reminders) async {
    final db = await instance.database;
    return await db.transaction((txn) async {
      final medicineId = await txn.insert('medicines', medicine.toMap());
      
      for (var reminder in reminders) {
        final reminderMap = reminder.copyWith(medicineId: medicineId).toMap();
        await txn.insert('reminders', reminderMap);
      }
      return medicineId;
    });
  }

  Future<int> updateMedicine(Medicine medicine, List<Reminder> newReminders) async {
    final db = await instance.database;
    return await db.transaction((txn) async {
      final count = await txn.update(
        'medicines',
        medicine.toMap(),
        where: 'id = ?',
        whereArgs: [medicine.id],
      );

      await txn.delete(
        'reminders',
        where: 'medicineId = ?',
        whereArgs: [medicine.id],
      );

      for (var reminder in newReminders) {
        final reminderMap = reminder.copyWith(medicineId: medicine.id).toMap();
        await txn.insert('reminders', reminderMap);
      }

      return count;
    });
  }

  Future<int> deleteMedicine(int id) async {
    final db = await instance.database;
    return await db.transaction((txn) async {
      await txn.delete('history', where: 'medicineId = ?', whereArgs: [id]);
      await txn.delete('reminders', where: 'medicineId = ?', whereArgs: [id]);
      return await txn.delete('medicines', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<List<Medicine>> getAllMedicines() async {
    final db = await instance.database;
    final result = await db.query('medicines', orderBy: 'createdAt DESC');
    return result.map((json) => Medicine.fromMap(json)).toList();
  }

  Future<Medicine?> getMedicineById(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'medicines',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Medicine.fromMap(maps.first);
    } else {
      return null;
    }
  }

  // --- Reminders ---

  Future<List<Reminder>> getRemindersForMedicine(int medicineId) async {
    final db = await instance.database;
    final result = await db.query(
      'reminders',
      where: 'medicineId = ?',
      whereArgs: [medicineId],
    );
    return result.map((json) => Reminder.fromMap(json)).toList();
  }

  Future<List<Reminder>> getAllReminders() async {
    final db = await instance.database;
    final result = await db.query('reminders');
    return result.map((json) => Reminder.fromMap(json)).toList();
  }

  Future<int> updateReminderStatus(int id, bool isActive) async {
    final db = await instance.database;
    return await db.update(
      'reminders',
      {'isActive': isActive ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- History ---

  Future<int> insertHistory(History history) async {
    final db = await instance.database;
    
    final existing = await db.query(
      'history',
      where: 'medicineId = ? AND reminderId = ? AND date = ?',
      whereArgs: [history.medicineId, history.reminderId, history.date],
    );

    if (existing.isNotEmpty) {
      return await db.update(
        'history',
        history.toMap(),
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    } else {
      return await db.insert('history', history.toMap());
    }
  }

  Future<List<History>> getAllHistory() async {
    final db = await instance.database;
    final result = await db.query('history', orderBy: 'date DESC, createdAt DESC');
    return result.map((json) => History.fromMap(json)).toList();
  }

  Future<List<History>> getHistoryByDate(String date) async {
    final db = await instance.database;
    final result = await db.query(
      'history',
      where: 'date = ?',
      whereArgs: [date],
    );
    return result.map((json) => History.fromMap(json)).toList();
  }

  Future<int> deleteHistoryForMedicine(int medicineId) async {
    final db = await instance.database;
    return await db.delete(
      'history',
      where: 'medicineId = ?',
      whereArgs: [medicineId],
    );
  }

  Future<String> getDatabasePath() async {
    final dbPath = await getDatabasesPath();
    return join(dbPath, 'medicinereminder.db');
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
