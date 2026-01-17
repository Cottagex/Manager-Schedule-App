import 'package:sqflite/sqflite.dart';
import '../models/shift_runner_settings.dart';
import 'app_database.dart';

class ShiftRunnerSettingsDao {
  Future<ShiftRunnerSettings?> getSettings(String shiftType) async {
    final db = await AppDatabase.instance.db;
    final results = await db.query(
      'shift_runner_settings',
      where: 'shiftType = ?',
      whereArgs: [shiftType],
    );

    if (results.isEmpty) return null;
    return ShiftRunnerSettings.fromMap(results.first);
  }

  Future<Map<String, ShiftRunnerSettings>> getAllSettings() async {
    final db = await AppDatabase.instance.db;
    final results = await db.query('shift_runner_settings');

    final map = <String, ShiftRunnerSettings>{};
    for (final row in results) {
      final settings = ShiftRunnerSettings.fromMap(row);
      map[settings.shiftType] = settings;
    }
    return map;
  }

  Future<void> upsert(ShiftRunnerSettings settings) async {
    final db = await AppDatabase.instance.db;
    await db.insert(
      'shift_runner_settings',
      settings.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(String shiftType) async {
    final db = await AppDatabase.instance.db;
    await db.delete(
      'shift_runner_settings',
      where: 'shiftType = ?',
      whereArgs: [shiftType],
    );
  }

  /// Get the custom label for a shift type, or null if using default
  Future<String?> getCustomLabel(String shiftType) async {
    final settings = await getSettings(shiftType);
    return settings?.customLabel;
  }

  /// Get all custom labels as a map (shiftType -> label)
  Future<Map<String, String>> getLabelsMap() async {
    final allSettings = await getAllSettings();
    final map = <String, String>{};
    
    for (final shiftType in ShiftRunnerSettings.defaultLabels.keys) {
      final settings = allSettings[shiftType];
      map[shiftType] = settings?.displayLabel ?? 
          ShiftRunnerSettings.defaultLabels[shiftType]!;
    }
    
    return map;
  }

  /// Get the default shift times for a shift type
  Future<Map<String, String>> getDefaultShiftTimes(String shiftType) async {
    final settings = await getSettings(shiftType);
    return {
      'start': settings?.effectiveStartTime ?? 
          ShiftRunnerSettings.defaultTimes[shiftType]?['start'] ?? '00:00',
      'end': settings?.effectiveEndTime ?? 
          ShiftRunnerSettings.defaultTimes[shiftType]?['end'] ?? '00:00',
    };
  }

  /// Get the shift runner time range for a shift type
  Future<Map<String, String>> getShiftRange(String shiftType) async {
    final settings = await getSettings(shiftType);
    return {
      'start': settings?.effectiveShiftRangeStart ?? 
          ShiftRunnerSettings.defaultTimes[shiftType]?['start'] ?? '00:00',
      'end': settings?.effectiveShiftRangeEnd ?? 
          ShiftRunnerSettings.defaultTimes[shiftType]?['end'] ?? '00:00',
    };
  }

  /// Get all shift ranges as a map
  Future<Map<String, Map<String, String>>> getAllShiftRanges() async {
    final allSettings = await getAllSettings();
    final map = <String, Map<String, String>>{};
    
    for (final shiftType in ShiftRunnerSettings.defaultTimes.keys) {
      final settings = allSettings[shiftType];
      map[shiftType] = {
        'start': settings?.effectiveShiftRangeStart ?? 
            ShiftRunnerSettings.defaultTimes[shiftType]!['start']!,
        'end': settings?.effectiveShiftRangeEnd ?? 
            ShiftRunnerSettings.defaultTimes[shiftType]!['end']!,
      };
    }
    
    return map;
  }
}
