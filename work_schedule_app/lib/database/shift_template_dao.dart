import 'package:sqflite/sqflite.dart';
import '../models/shift_template.dart';
import 'app_database.dart';

class ShiftTemplateDao {
  Future<Database> get _db async => await AppDatabase.instance.db;

  // Get all templates
  Future<List<ShiftTemplate>> getAllTemplates() async {
    final db = await _db;
    final maps = await db.query('shift_templates', orderBy: 'templateName');
    return maps.map((map) => ShiftTemplate.fromMap(map)).toList();
  }

  // Insert a new template
  Future<int> insertTemplate(ShiftTemplate template) async {
    final db = await _db;
    return await db.insert('shift_templates', template.toMap());
  }

  // Update existing template
  Future<int> updateTemplate(ShiftTemplate template) async {
    final db = await _db;
    return await db.update(
      'shift_templates',
      template.toMap(),
      where: 'id = ?',
      whereArgs: [template.id],
    );
  }

  // Delete template
  Future<int> deleteTemplate(int id) async {
    final db = await _db;
    return await db.delete(
      'shift_templates',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Insert default templates if none exist
  Future<void> insertDefaultTemplatesIfMissing() async {
    final existing = await getAllTemplates();
    if (existing.isNotEmpty) return;

    await insertTemplate(ShiftTemplate(templateName: 'Opener', startTime: '06:00'));
    await insertTemplate(ShiftTemplate(templateName: 'Lunch', startTime: '10:00'));
    await insertTemplate(ShiftTemplate(templateName: 'Dinner', startTime: '14:00'));
    await insertTemplate(ShiftTemplate(templateName: 'Closer', startTime: '18:00'));
  }
}
