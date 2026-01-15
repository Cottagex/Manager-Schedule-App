import 'package:sqflite/sqflite.dart';
import '../models/shift_template.dart';
import 'app_database.dart';

class ShiftTemplateDao {
  Future<Database> get _db async => await AppDatabase.instance.db;

  // Get all templates for a specific job code
  Future<List<ShiftTemplate>> getTemplatesForJobCode(String jobCode) async {
    final db = await _db;
    final maps = await db.query(
      'shift_templates',
      where: 'jobCode = ?',
      whereArgs: [jobCode],
      orderBy: 'templateName',
    );
    return maps.map((map) => ShiftTemplate.fromMap(map)).toList();
  }

  // Get all templates
  Future<List<ShiftTemplate>> getAllTemplates() async {
    final db = await _db;
    final maps = await db.query('shift_templates', orderBy: 'jobCode, templateName');
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

  // Delete all templates for a job code
  Future<int> deleteTemplatesForJobCode(String jobCode) async {
    final db = await _db;
    return await db.delete(
      'shift_templates',
      where: 'jobCode = ?',
      whereArgs: [jobCode],
    );
  }

  // Insert default templates for a job code if they don't exist
  Future<void> insertDefaultTemplatesIfMissing(String jobCode) async {
    final existing = await getTemplatesForJobCode(jobCode);
    if (existing.isEmpty) {
      // Add default templates
      await insertTemplate(ShiftTemplate(jobCode: jobCode, templateName: 'Opener', startTime: '06:00'));
      await insertTemplate(ShiftTemplate(jobCode: jobCode, templateName: 'Lunch', startTime: '10:00'));
      await insertTemplate(ShiftTemplate(jobCode: jobCode, templateName: 'Dinner', startTime: '14:00'));
      await insertTemplate(ShiftTemplate(jobCode: jobCode, templateName: 'Closer', startTime: '18:00'));
    }
  }
}
