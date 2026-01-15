import 'package:sqflite/sqflite.dart';
import '../models/employee.dart';
import 'app_database.dart';

class EmployeeDao {
  Future<List<Employee>> getEmployees() async {
    final db = await AppDatabase.instance.db;
    final result = await db.query('employees', orderBy: 'name ASC');
    return result.map((row) => Employee.fromMap(row)).toList();
  }

  Future<int> insertEmployee(Employee employee) async {
    final db = await AppDatabase.instance.db;
    return await db.insert(
      'employees',
      employee.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateEmployee(Employee employee) async {
    final db = await AppDatabase.instance.db;

    if (employee.id == null) {
      throw Exception("Cannot update employee without an ID");
    }

    return await db.update(
      'employees',
      employee.toMap(),
      where: 'id = ?',
      whereArgs: [employee.id],
    );
  }

  Future<int> deleteEmployee(int id) async {
    final db = await AppDatabase.instance.db;
    return await db.delete(
      'employees',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
