import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:work_schedule_app/database/app_database.dart';
import 'package:work_schedule_app/database/time_off_dao.dart';
import 'package:work_schedule_app/database/employee_dao.dart';
import 'package:work_schedule_app/database/settings_dao.dart';
import 'package:work_schedule_app/services/pto_trimester_service.dart';
import 'package:work_schedule_app/models/employee.dart';
import 'package:work_schedule_app/models/time_off_entry.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUp(() async {
    await AppDatabase.instance.init(dbPath: ':memory:');
  });

  tearDown(() async {
    await AppDatabase.instance.close();
  });

  test('pto added as full day is counted in trimester summary', () async {
    final employeeDao = EmployeeDao();
    final timeOffDao = TimeOffDao();
    final settingsDao = SettingsDao();
    final ptoService = PtoTrimesterService(timeOffDao: timeOffDao);

    final id = await employeeDao.insertEmployee(Employee(name: 'PTO Tester', jobCode: 'assistant'));

    final settings = await settingsDao.getSettings();
    final ptoHours = settings.ptoHoursPerRequest;

    final now = DateTime.now();
    final ptoDate = DateTime(now.year, 3, 3);

    await timeOffDao.insertTimeOff(TimeOffEntry(id: null, employeeId: id, date: ptoDate, timeOffType: 'pto', hours: ptoHours, vacationGroupId: null));

    final summaries = await ptoService.calculateTrimesterSummaries(id);

    expect(summaries[0].used, ptoHours);
  });

  test('multi-day PTO blocked if not enough remaining in trimester', () async {
    final employeeDao = EmployeeDao();
    final timeOffDao = TimeOffDao();
    final settingsDao = SettingsDao();
    final ptoService = PtoTrimesterService(timeOffDao: timeOffDao);

    final id = await employeeDao.insertEmployee(Employee(name: 'PTO Insufficient', jobCode: 'assistant'));

    final settings = await settingsDao.getSettings();
    final hoursPerDay = settings.ptoHoursPerRequest;

    final now = DateTime.now();
    final startDate = DateTime(now.year, 3, 1);

    final days = 4; // 4 * 8 = 32 > default 30 earned
    final requestedHours = days * hoursPerDay;

    final remaining = await ptoService.getRemainingForDate(id, startDate);

    expect(remaining < requestedHours, isTrue);
  });

  test('multi-day PTO allowed when enough remaining and consumed by inserts', () async {
    final employeeDao = EmployeeDao();
    final timeOffDao = TimeOffDao();
    final settingsDao = SettingsDao();
    final ptoService = PtoTrimesterService(timeOffDao: timeOffDao);

    final id = await employeeDao.insertEmployee(Employee(name: 'PTO Allowed', jobCode: 'assistant'));

    final settings = await settingsDao.getSettings();
    final hoursPerDay = settings.ptoHoursPerRequest;

    final now = DateTime.now();
    final startDate = DateTime(now.year, 3, 1);

    final days = 3; // 3 * 8 = 24 <= default 30
    final requestedHours = days * hoursPerDay;

    final remaining = await ptoService.getRemainingForDate(id, startDate);
    expect(remaining >= requestedHours, isTrue);

    final groupId = 'test-group-pto';
    for (int i = 0; i < days; i++) {
      await timeOffDao.insertTimeOff(TimeOffEntry(id: null, employeeId: id, date: startDate.add(Duration(days: i)), timeOffType: 'pto', hours: hoursPerDay, vacationGroupId: groupId));
    }

    final used = await timeOffDao.getPtoUsedInRange(id, startDate, DateTime(now.year, 4, 30));
    expect(used, requestedHours);
  });
}

