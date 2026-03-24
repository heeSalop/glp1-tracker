import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../services/notification_service.dart';

class AppProvider extends ChangeNotifier {
  final _db = DatabaseHelper.instance;

  List<Map<String, dynamic>> medicationLogs = [];
  List<Map<String, dynamic>> medicationSettings = [];
  List<Map<String, dynamic>> weightLogs = [];
  List<Map<String, dynamic>> measurementLogs = [];
  List<Map<String, dynamic>> todayNutritionLogs = [];
  List<Map<String, dynamic>> allNutritionLogs = [];
  List<Map<String, dynamic>> todayWaterLogs = [];
  List<Map<String, dynamic>> injectionSiteHistory = [];

  String get todayPrefix => DateFormat('yyyy-MM-dd').format(DateTime.now());

  Future<void> loadAll() async {
    await Future.wait([
      loadMedication(),
      loadWeight(),
      loadNutrition(),
      loadWater(),
      loadInjectionSites(),
    ]);
  }

  // ─── MEDICATION ─────────────────────────────────────────────────────────
  Future<void> loadMedication() async {
    medicationLogs = await _db.getMedicationLogs();
    medicationSettings = await _db.getMedicationSettings();
    notifyListeners();
  }

  Future<void> logMedication({
    required String name,
    required String type,
    required double dose,
    required String doseUnit,
    String? site,
    String? notes,
  }) async {
    await _db.insertMedicationLog({
      'medication_name': name,
      'medication_type': type,
      'dose': dose,
      'dose_unit': doseUnit,
      'injection_site': site,
      'notes': notes,
      'logged_at': DateTime.now().toIso8601String(),
    });
    await loadMedication();
    await loadInjectionSites();
  }

  Future<void> deleteMedicationLog(int id) async {
    await _db.deleteMedicationLog(id);
    await loadMedication();
  }

  Future<void> addMedicationSetting({
    required String name,
    required String type,
    required double dose,
    required String doseUnit,
    required String frequency,
    int? reminderHour,
    int? reminderMinute,
    int? reminderDay,
  }) async {
    final id = await _db.insertMedicationSetting({
      'medication_name': name,
      'medication_type': type,
      'dose': dose,
      'dose_unit': doseUnit,
      'frequency': frequency,
      'reminder_hour': reminderHour,
      'reminder_minute': reminderMinute,
      'reminder_day': reminderDay,
      'is_active': 1,
    });

    // Schedule notification if reminder time set
    if (reminderHour != null && reminderMinute != null) {
      final time = TimeOfDay(hour: reminderHour, minute: reminderMinute);
      if (frequency == 'weekly' && reminderDay != null) {
        await NotificationService.instance.scheduleWeeklyReminder(
          id: id,
          title: '💉 $name Reminder',
          body: 'Time for your ${dose}${doseUnit} dose of $name!',
          weekday: reminderDay,
          time: time,
        );
      } else {
        await NotificationService.instance.scheduleDailyReminder(
          id: id,
          title: '💊 $name Reminder',
          body: 'Time for your ${dose}${doseUnit} dose of $name!',
          time: time,
        );
      }
    }

    await loadMedication();
  }

  Future<void> deleteMedicationSetting(int id) async {
    await NotificationService.instance.cancelReminder(id);
    await _db.deleteMedicationSetting(id);
    await loadMedication();
  }

  // ─── INJECTION SITES ────────────────────────────────────────────────────
  Future<void> loadInjectionSites() async {
    injectionSiteHistory = await _db.getInjectionSiteHistory(limit: 30);
    notifyListeners();
  }

  /// Returns a map of site -> DateTime of last use (null = never used)
  Map<String, DateTime?> get siteLastUsed {
    final sites = [
      'Left Abdomen', 'Right Abdomen',
      'Left Upper Arm', 'Right Upper Arm',
      'Left Thigh', 'Right Thigh',
      'Left Buttock', 'Right Buttock',
    ];
    final Map<String, DateTime?> result = {for (var s in sites) s: null};
    for (final entry in injectionSiteHistory) {
      final site = entry['injection_site'] as String?;
      if (site != null && result.containsKey(site) && result[site] == null) {
        result[site] = DateTime.parse(entry['logged_at'] as String);
      }
    }
    return result;
  }

  // ─── WEIGHT ─────────────────────────────────────────────────────────────
  Future<void> loadWeight() async {
    weightLogs = await _db.getWeightLogs();
    measurementLogs = await _db.getMeasurementLogs();
    notifyListeners();
  }

  Future<void> logWeight(double weight, String unit, {String? notes}) async {
    await _db.insertWeightLog({
      'weight': weight,
      'weight_unit': unit,
      'logged_at': DateTime.now().toIso8601String(),
      'notes': notes,
    });
    await loadWeight();
  }

  Future<void> deleteWeightLog(int id) async {
    await _db.deleteWeightLog(id);
    await loadWeight();
  }

  Future<void> logMeasurements(Map<String, dynamic> data) async {
    await _db.insertMeasurementLog({
      ...data,
      'logged_at': DateTime.now().toIso8601String(),
    });
    await loadWeight();
  }

  double? get latestWeight =>
      weightLogs.isEmpty ? null : (weightLogs.last['weight'] as num).toDouble();
  String get weightUnit =>
      weightLogs.isEmpty ? 'lbs' : (weightLogs.last['weight_unit'] as String);

  // ─── NUTRITION ───────────────────────────────────────────────────────────
  Future<void> loadNutrition() async {
    todayNutritionLogs = await _db.getNutritionLogs(datePrefix: todayPrefix);
    allNutritionLogs = await _db.getNutritionLogs();
    notifyListeners();
  }

  Future<void> logMeal({
    required String name,
    required String type,
    double calories = 0,
    double protein = 0,
    double carbs = 0,
    double fat = 0,
    double fiber = 0,
  }) async {
    await _db.insertNutritionLog({
      'meal_name': name,
      'meal_type': type,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'logged_at': DateTime.now().toIso8601String(),
    });
    await loadNutrition();
  }

  Future<void> deleteNutritionLog(int id) async {
    await _db.deleteNutritionLog(id);
    await loadNutrition();
  }

  double get todayCalories => _sumField(todayNutritionLogs, 'calories');
  double get todayProtein => _sumField(todayNutritionLogs, 'protein');
  double get todayCarbs => _sumField(todayNutritionLogs, 'carbs');
  double get todayFat => _sumField(todayNutritionLogs, 'fat');
  double get todayFiber => _sumField(todayNutritionLogs, 'fiber');

  // ─── WATER ───────────────────────────────────────────────────────────────
  Future<void> loadWater() async {
    todayWaterLogs = await _db.getWaterLogs(datePrefix: todayPrefix);
    notifyListeners();
  }

  Future<void> logWater(double amount, String unit) async {
    await _db.insertWaterLog({
      'amount': amount,
      'unit': unit,
      'logged_at': DateTime.now().toIso8601String(),
    });
    await loadWater();
  }

  Future<void> deleteWaterLog(int id) async {
    await _db.deleteWaterLog(id);
    await loadWater();
  }

  double get todayWaterOz {
    double total = 0;
    for (final log in todayWaterLogs) {
      double amt = (log['amount'] as num).toDouble();
      if (log['unit'] == 'mL') amt /= 29.5735;
      if (log['unit'] == 'cups') amt *= 8;
      total += amt;
    }
    return total;
  }

  // ─── HELPERS ─────────────────────────────────────────────────────────────
  double _sumField(List<Map<String, dynamic>> logs, String field) =>
      logs.fold(0.0, (sum, log) => sum + ((log[field] as num?)?.toDouble() ?? 0));
}
