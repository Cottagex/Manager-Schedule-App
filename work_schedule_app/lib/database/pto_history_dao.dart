import 'package:sqflite/sqflite.dart';
import 'app_database.dart';
import '../models/pto_history.dart';

class PtoHistoryDao {
  Future<Database> get _db async => await AppDatabase.instance.db;

  Future<PtoHistory> ensureHistoryRecord({
    required int employeeId,
    required DateTime trimesterStart,
  }) async {
    final db = await _db;

    final startIso = trimesterStart.toIso8601String();

    // Try to load existing record
    final maps = await db.query(
      'pto_history',
      where: 'employeeId = ? AND trimesterStart = ?',
      whereArgs: [employeeId, startIso],
    );

    if (maps.isNotEmpty) {
      return PtoHistory.fromMap(maps.first);
    }

    // Create new record (NO usedHours column)
    final newRecord = {
      'employeeId': employeeId,
      'trimesterStart': startIso,
      'carryoverHours': 0,
    };

    final id = await db.insert('pto_history', newRecord);

    return PtoHistory(
      id: id,
      employeeId: employeeId,
      trimesterStart: trimesterStart,
      carryoverHours: 0,
    );
  }

  Future<void> updateCarryover(PtoHistory history) async {
    final db = await _db;

    await db.update(
      'pto_history',
      {
        'carryoverHours': history.carryoverHours,
      },
      where: 'id = ?',
      whereArgs: [history.id],
    );
  }
}
