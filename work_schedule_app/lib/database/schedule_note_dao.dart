import 'package:sqflite/sqflite.dart';
import 'app_database.dart';
import '../models/schedule_note.dart';

class ScheduleNoteDao {
  Future<Database> get _db async => await AppDatabase.instance.db;

  /// Create the schedule_notes table
  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS schedule_notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        note TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');
    
    // Create index for faster queries by date
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_schedule_notes_date 
      ON schedule_notes(date)
    ''');
  }

  /// Insert or update a note (upsert)
  Future<int> upsert(ScheduleNote note) async {
    final db = await _db;
    final existing = await getByDate(note.date);
    
    if (existing != null) {
      // Update existing note
      return await db.update(
        'schedule_notes',
        note.copyWith(id: existing.id, updatedAt: DateTime.now()).toMap(),
        where: 'id = ?',
        whereArgs: [existing.id],
      );
    } else {
      // Insert new note
      return await db.insert('schedule_notes', note.toMap());
    }
  }

  /// Delete a note by date
  Future<int> deleteByDate(DateTime date) async {
    final db = await _db;
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return await db.delete(
      'schedule_notes',
      where: 'date = ?',
      whereArgs: [dateStr],
    );
  }

  /// Get a note for a specific date
  Future<ScheduleNote?> getByDate(DateTime date) async {
    final db = await _db;
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final maps = await db.query(
      'schedule_notes',
      where: 'date = ?',
      whereArgs: [dateStr],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return ScheduleNote.fromMap(maps.first);
  }

  /// Get all notes
  Future<List<ScheduleNote>> getAll() async {
    final db = await _db;
    final maps = await db.query('schedule_notes', orderBy: 'date ASC');
    return maps.map((m) => ScheduleNote.fromMap(m)).toList();
  }

  /// Get notes for a date range
  Future<List<ScheduleNote>> getByDateRange(DateTime start, DateTime end) async {
    final db = await _db;
    final startStr = '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
    final endStr = '${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';
    
    final maps = await db.query(
      'schedule_notes',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startStr, endStr],
      orderBy: 'date ASC',
    );
    return maps.map((m) => ScheduleNote.fromMap(m)).toList();
  }

  /// Get notes for a specific week
  Future<Map<DateTime, ScheduleNote>> getByWeek(DateTime anyDayInWeek) async {
    // Find Sunday of the week
    final sunday = anyDayInWeek.subtract(Duration(days: anyDayInWeek.weekday % 7));
    final startOfWeek = DateTime(sunday.year, sunday.month, sunday.day);
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    final notes = await getByDateRange(startOfWeek, endOfWeek);
    final result = <DateTime, ScheduleNote>{};
    for (final note in notes) {
      final dateKey = DateTime(note.date.year, note.date.month, note.date.day);
      result[dateKey] = note;
    }
    return result;
  }

  /// Get notes for a specific month
  Future<Map<DateTime, ScheduleNote>> getByMonth(int year, int month) async {
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 0);
    
    final notes = await getByDateRange(startOfMonth, endOfMonth);
    final result = <DateTime, ScheduleNote>{};
    for (final note in notes) {
      final dateKey = DateTime(note.date.year, note.date.month, note.date.day);
      result[dateKey] = note;
    }
    return result;
  }

  /// Get notes for a full calendar month view (includes visible days from adjacent months)
  Future<Map<DateTime, ScheduleNote>> getByCalendarMonth(int year, int month) async {
    final firstDayOfMonth = DateTime(year, month, 1);
    final lastDayOfMonth = DateTime(year, month + 1, 0);
    
    // Find the Sunday before or on the first day (start of first visible week)
    final calendarStart = firstDayOfMonth.subtract(
      Duration(days: firstDayOfMonth.weekday % 7),
    );
    
    // Find the Saturday after or on the last day (end of last visible week)
    final daysUntilSaturday = (6 - lastDayOfMonth.weekday % 7) % 7;
    final calendarEnd = lastDayOfMonth.add(Duration(days: daysUntilSaturday));
    
    final notes = await getByDateRange(calendarStart, calendarEnd);
    final result = <DateTime, ScheduleNote>{};
    for (final note in notes) {
      final dateKey = DateTime(note.date.year, note.date.month, note.date.day);
      result[dateKey] = note;
    }
    return result;
  }
}
