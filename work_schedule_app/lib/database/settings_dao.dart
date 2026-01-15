import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/settings.dart';
import 'app_database.dart';

class SettingsDao {
  static const int _settingsId = 1;

  // ---------------------------------------------------------------------------
  // GET SETTINGS (returns a strongly-typed Settings object)
  // ---------------------------------------------------------------------------
  Future<Settings> getSettings() async {
    final db = await AppDatabase.instance.db;

    final result = await db.query(
      'settings',
      where: 'id = ?',
      whereArgs: [_settingsId],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return Settings.fromMap(result.first);
    }

    // If no row exists, create defaults and return them
    await insertDefaultSettings();
    return getSettings();
  }

  // ---------------------------------------------------------------------------
  // INSERT DEFAULT SETTINGS
  // ---------------------------------------------------------------------------
  Future<void> insertDefaultSettings() async {
    final db = await AppDatabase.instance.db;

    const defaultSettings = Settings(
      id: _settingsId,
      ptoHoursPerTrimester: 30,
      ptoHoursPerRequest: 8,
      maxCarryoverHours: 10,
      assistantVacationDays: 6,
      swingVacationDays: 7,
      minimumHoursBetweenShifts: 8,
      inventoryDay: 1,
      scheduleStartDay: 1,
      blockOverlaps: false,
    );

    await db.insert(
      'settings',
      defaultSettings.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ---------------------------------------------------------------------------
  // UPDATE ENTIRE SETTINGS ROW
  // ---------------------------------------------------------------------------
  Future<void> updateSettings(Settings settings) async {
    final db = await AppDatabase.instance.db;

    await db.update(
      'settings',
      settings.toMap(),
      where: 'id = ?',
      whereArgs: [_settingsId],
    );
  }

  // ---------------------------------------------------------------------------
  // UPDATE A SINGLE FIELD
  // ---------------------------------------------------------------------------
  Future<void> updateField(String field, dynamic value) async {
    final db = await AppDatabase.instance.db;

    await db.update(
      'settings',
      {field: value},
      where: 'id = ?',
      whereArgs: [_settingsId],
    );
  }
}
