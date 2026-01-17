import 'package:sqflite/sqflite.dart';
import '../models/shift_type.dart';
import 'app_database.dart';

class ShiftTypeDao {
  /// Get all shift types ordered by sortOrder
  Future<List<ShiftType>> getAll() async {
    final db = await AppDatabase.instance.db;
    final results = await db.query(
      'shift_types',
      orderBy: 'sortOrder ASC',
    );
    return results.map((row) => ShiftType.fromMap(row)).toList();
  }

  /// Get a shift type by key
  Future<ShiftType?> getByKey(String key) async {
    final db = await AppDatabase.instance.db;
    final results = await db.query(
      'shift_types',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (results.isEmpty) return null;
    return ShiftType.fromMap(results.first);
  }

  /// Insert or update a shift type
  Future<int> upsert(ShiftType shiftType) async {
    final db = await AppDatabase.instance.db;
    return await db.insert(
      'shift_types',
      shiftType.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Insert a new shift type
  Future<int> insert(ShiftType shiftType) async {
    final db = await AppDatabase.instance.db;
    return await db.insert('shift_types', shiftType.toMap());
  }

  /// Update an existing shift type
  Future<int> update(ShiftType shiftType) async {
    final db = await AppDatabase.instance.db;
    return await db.update(
      'shift_types',
      shiftType.toMap(),
      where: 'id = ?',
      whereArgs: [shiftType.id],
    );
  }

  /// Delete a shift type by id
  Future<int> delete(int id) async {
    final db = await AppDatabase.instance.db;
    return await db.delete(
      'shift_types',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete a shift type by key
  Future<int> deleteByKey(String key) async {
    final db = await AppDatabase.instance.db;
    return await db.delete(
      'shift_types',
      where: 'key = ?',
      whereArgs: [key],
    );
  }

  /// Update sort orders for multiple shift types
  Future<void> updateSortOrders(List<ShiftType> shiftTypes) async {
    final db = await AppDatabase.instance.db;
    final batch = db.batch();
    for (int i = 0; i < shiftTypes.length; i++) {
      batch.update(
        'shift_types',
        {'sortOrder': i},
        where: 'id = ?',
        whereArgs: [shiftTypes[i].id],
      );
    }
    await batch.commit(noResult: true);
  }

  /// Insert default shift types if the table is empty
  Future<void> insertDefaultsIfEmpty() async {
    final db = await AppDatabase.instance.db;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM shift_types'),
    );
    
    if (count == 0) {
      final batch = db.batch();
      for (final defaultType in ShiftType.defaults) {
        batch.insert('shift_types', defaultType);
      }
      await batch.commit(noResult: true);
    }
  }

  /// Get shift types as a map (key -> ShiftType)
  Future<Map<String, ShiftType>> getAsMap() async {
    final types = await getAll();
    return {for (final t in types) t.key: t};
  }

  /// Get ordered keys
  Future<List<String>> getOrderedKeys() async {
    final types = await getAll();
    return types.map((t) => t.key).toList();
  }

  /// Get labels map (for ShiftRunner compatibility)
  Future<Map<String, String>> getLabelsMap() async {
    final types = await getAll();
    return {for (final t in types) t.key: t.label};
  }

  /// Get colors map (for ShiftRunner compatibility)
  Future<Map<String, String>> getColorsMap() async {
    final types = await getAll();
    return {for (final t in types) t.key: t.colorHex};
  }

  /// Get the next sort order value
  Future<int> getNextSortOrder() async {
    final db = await AppDatabase.instance.db;
    final result = await db.rawQuery(
      'SELECT MAX(sortOrder) as maxOrder FROM shift_types',
    );
    final maxOrder = result.first['maxOrder'] as int?;
    return (maxOrder ?? -1) + 1;
  }
}
