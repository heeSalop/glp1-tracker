import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  DatabaseHelper._();
  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'glp1_tracker.db');
    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE medication_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medication_name TEXT NOT NULL,
        medication_type TEXT NOT NULL,
        dose REAL NOT NULL,
        dose_unit TEXT NOT NULL,
        injection_site TEXT,
        notes TEXT,
        logged_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE medication_settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medication_name TEXT NOT NULL,
        medication_type TEXT NOT NULL,
        dose REAL NOT NULL,
        dose_unit TEXT NOT NULL,
        frequency TEXT NOT NULL,
        reminder_hour INTEGER,
        reminder_minute INTEGER,
        reminder_day INTEGER,
        is_active INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE weight_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        weight REAL NOT NULL,
        weight_unit TEXT NOT NULL DEFAULT 'lbs',
        logged_at TEXT NOT NULL,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE measurement_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        waist REAL,
        hips REAL,
        chest REAL,
        left_arm REAL,
        right_arm REAL,
        left_thigh REAL,
        right_thigh REAL,
        unit TEXT NOT NULL DEFAULT 'in',
        logged_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE nutrition_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        meal_name TEXT NOT NULL,
        meal_type TEXT NOT NULL,
        calories REAL DEFAULT 0,
        protein REAL DEFAULT 0,
        carbs REAL DEFAULT 0,
        fat REAL DEFAULT 0,
        fiber REAL DEFAULT 0,
        logged_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE water_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        unit TEXT NOT NULL DEFAULT 'oz',
        logged_at TEXT NOT NULL
      )
    ''');
  }

  // ─── MEDICATION LOGS ───────────────────────────────────────────────────
  Future<int> insertMedicationLog(Map<String, dynamic> log) async =>
      (await database).insert('medication_logs', log);

  Future<List<Map<String, dynamic>>> getMedicationLogs() async =>
      (await database).query('medication_logs', orderBy: 'logged_at DESC');

  Future<int> deleteMedicationLog(int id) async =>
      (await database).delete('medication_logs', where: 'id = ?', whereArgs: [id]);

  Future<List<Map<String, dynamic>>> getInjectionSiteHistory({int limit = 20}) async =>
      (await database).query(
        'medication_logs',
        columns: ['injection_site', 'logged_at'],
        where: 'injection_site IS NOT NULL AND injection_site != ""',
        orderBy: 'logged_at DESC',
        limit: limit,
      );

  // ─── MEDICATION SETTINGS ───────────────────────────────────────────────
  Future<int> insertMedicationSetting(Map<String, dynamic> s) async =>
      (await database).insert('medication_settings', s);

  Future<List<Map<String, dynamic>>> getMedicationSettings() async =>
      (await database).query('medication_settings', where: 'is_active = 1');

  Future<int> deleteMedicationSetting(int id) async =>
      (await database).delete('medication_settings', where: 'id = ?', whereArgs: [id]);

  // ─── WEIGHT LOGS ───────────────────────────────────────────────────────
  Future<int> insertWeightLog(Map<String, dynamic> log) async =>
      (await database).insert('weight_logs', log);

  Future<List<Map<String, dynamic>>> getWeightLogs() async =>
      (await database).query('weight_logs', orderBy: 'logged_at ASC');

  Future<int> deleteWeightLog(int id) async =>
      (await database).delete('weight_logs', where: 'id = ?', whereArgs: [id]);

  // ─── MEASUREMENT LOGS ──────────────────────────────────────────────────
  Future<int> insertMeasurementLog(Map<String, dynamic> log) async =>
      (await database).insert('measurement_logs', log);

  Future<List<Map<String, dynamic>>> getMeasurementLogs() async =>
      (await database).query('measurement_logs', orderBy: 'logged_at DESC');

  // ─── NUTRITION LOGS ────────────────────────────────────────────────────
  Future<int> insertNutritionLog(Map<String, dynamic> log) async =>
      (await database).insert('nutrition_logs', log);

  Future<List<Map<String, dynamic>>> getNutritionLogs({String? datePrefix}) async {
    final db = await database;
    if (datePrefix != null) {
      return db.query('nutrition_logs',
          where: 'logged_at LIKE ?',
          whereArgs: ['$datePrefix%'],
          orderBy: 'logged_at DESC');
    }
    return db.query('nutrition_logs', orderBy: 'logged_at DESC');
  }

  Future<int> deleteNutritionLog(int id) async =>
      (await database).delete('nutrition_logs', where: 'id = ?', whereArgs: [id]);

  // ─── WATER LOGS ────────────────────────────────────────────────────────
  Future<int> insertWaterLog(Map<String, dynamic> log) async =>
      (await database).insert('water_logs', log);

  Future<List<Map<String, dynamic>>> getWaterLogs({String? datePrefix}) async {
    final db = await database;
    if (datePrefix != null) {
      return db.query('water_logs',
          where: 'logged_at LIKE ?',
          whereArgs: ['$datePrefix%'],
          orderBy: 'logged_at DESC');
    }
    return db.query('water_logs', orderBy: 'logged_at DESC');
  }

  Future<int> deleteWaterLog(int id) async =>
      (await database).delete('water_logs', where: 'id = ?', whereArgs: [id]);
}
