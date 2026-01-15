import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:work_schedule_app/database/app_database.dart';
import 'package:work_schedule_app/database/settings_dao.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUp(() async {
    await AppDatabase.instance.init(dbPath: ':memory:');
  });

  tearDown(() async {
    await AppDatabase.instance.close();
  });

  test('settings default includes blockOverlaps false and can be updated', () async {
    final dao = SettingsDao();
    final s = await dao.getSettings();
    expect(s.blockOverlaps, false);

    await dao.updateField('blockOverlaps', 1);
    final s2 = await dao.getSettings();
    expect(s2.blockOverlaps, true);
  });
}
