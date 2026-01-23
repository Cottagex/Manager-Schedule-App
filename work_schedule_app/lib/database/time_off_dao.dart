import 'package:sqflite/sqflite.dart';
import 'app_database.dart';
import '../models/time_off_entry.dart';
import '../services/auto_sync_service.dart';

class TimeOffDao {
  Future<Database> get _db async => AppDatabase.instance.db;

  // ------------------------------------------------------------
  // GET ALL TIME OFF
  // ------------------------------------------------------------
  Future<List<TimeOffEntry>> getAllTimeOff() async {
    final db = await _db;
    final result = await db.query('time_off', orderBy: 'date ASC');
    return result.map((row) => TimeOffEntry.fromMap(row)).toList();
  }

  // ------------------------------------------------------------
  // GET ALL TIME OFF FOR A MONTH
  // ------------------------------------------------------------
  Future<List<TimeOffEntry>> getAllTimeOffForMonth(int year, int month) async {
    final db = await _db;

    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0);

    final result = await db.query(
      'time_off',
      where: 'date >= ? AND date <= ?',
      whereArgs: [
        start.toIso8601String(),
        end.toIso8601String(),
      ],
      orderBy: 'date ASC',
    );

    return result.map((row) => TimeOffEntry.fromMap(row)).toList();
  }

  // ------------------------------------------------------------
  // INSERT
  // ------------------------------------------------------------
  Future<int> insertTimeOff(TimeOffEntry entry) async {
    final db = await _db;
    final id = await db.insert('time_off', entry.toMap());
    
    // Notify auto-sync service of the change
    AutoSyncService.instance.onTimeOffDataChanged();
    
    return id;
  }

  // ------------------------------------------------------------
  // UPDATE
  // ------------------------------------------------------------
  Future<int> updateTimeOff(TimeOffEntry entry) async {
    final db = await _db;
    if (entry.id == null) throw Exception("Missing ID");
    final result = await db.update(
      'time_off',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
    
    // Notify auto-sync service of the change
    AutoSyncService.instance.onTimeOffDataChanged();
    
    return result;
  }

  // ------------------------------------------------------------
  // DELETE
  // ------------------------------------------------------------
  Future<int> deleteTimeOff(int id) async {
    final db = await _db;
    final result = await db.delete(
      'time_off',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    // Notify auto-sync service of the change
    AutoSyncService.instance.onTimeOffDataChanged();
    
    return result;
  }

  // ------------------------------------------------------------
  // DELETE VACATION GROUP
  // ------------------------------------------------------------
  Future<int> deleteVacationGroup(String groupId) async {
    final db = await _db;
    final result = await db.delete(
      'time_off',
      where: 'vacationGroupId = ?',
      whereArgs: [groupId],
    );
    
    // Notify auto-sync service of the change
    AutoSyncService.instance.onTimeOffDataChanged();
    
    return result;
  }

  // ------------------------------------------------------------
  // CHECK FOR EXISTING TIME OFF IN RANGE
  // ------------------------------------------------------------
  Future<bool> hasTimeOffInRange(int employeeId, DateTime start, DateTime end) async {
    final db = await _db;

    final result = await db.rawQuery('''
      SELECT COUNT(*) AS total
      FROM time_off
      WHERE employeeId = ?
        AND date >= ?
        AND date <= ?
    ''', [employeeId, start.toIso8601String(), end.toIso8601String()]);

    final total = result.first['total'] as num?;
    return (total?.toInt() ?? 0) > 0;
  }

  // ------------------------------------------------------------
  // GET ENTRIES BY VACATION GROUP
  // ------------------------------------------------------------
  Future<List<TimeOffEntry>> getEntriesByGroup(String groupId) async {
    final db = await _db;
    final result = await db.query(
      'time_off',
      where: 'vacationGroupId = ?',
      whereArgs: [groupId],
      orderBy: 'date ASC',
    );

    return result.map((row) => TimeOffEntry.fromMap(row)).toList();
  }

  // ------------------------------------------------------------
  // PTO HOURS USED IN RANGE
  // ------------------------------------------------------------
  Future<int> getPtoUsedInRange(
      int employeeId, DateTime start, DateTime end) async {
    final db = await _db;

    final result = await db.rawQuery('''
      SELECT SUM(hours) AS total
      FROM time_off
      WHERE employeeId = ?
        AND date >= ?
        AND date <= ?
        AND timeOffType = 'pto'
    ''', [
      employeeId,
      start.toIso8601String(),
      end.toIso8601String(),
    ]);

    final total = result.first['total'] as num?;
    return total?.toInt() ?? 0;
  }

  // ------------------------------------------------------------
  // GET ENTRIES IN RANGE (for overlap details)
  // ------------------------------------------------------------
  Future<List<TimeOffEntry>> getTimeOffInRange(int employeeId, DateTime start, DateTime end) async {
    final db = await _db;

    final result = await db.query(
      'time_off',
      where: 'employeeId = ? AND date >= ? AND date <= ?',
      whereArgs: [employeeId, start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date ASC',
    );

    return result.map((row) => TimeOffEntry.fromMap(row)).toList();
  }
}
