import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:work_schedule_app/database/app_database.dart';
import 'package:work_schedule_app/database/employee_dao.dart';
import 'package:work_schedule_app/pages/time_off_page.dart';
import 'package:work_schedule_app/models/employee.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUp(() async {
    await AppDatabase.instance.init(dbPath: ':memory:');
  });

  tearDown(() async {
    await AppDatabase.instance.close();
  });

  testWidgets('create multi-day PTO with hours input and delete the group', (WidgetTester tester) async {
    final employeeDao = EmployeeDao();
    await employeeDao.insertEmployee(Employee(name: 'UI PTO', jobCode: 'assistant'));

    await tester.pumpWidget(const MaterialApp(home: TimeOffPage()));

    // Let async init finish
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Tap today's day cell
    final today = DateTime.now().day;
    await tester.tap(find.text('$today').first);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // FAB should appear
    final fab = find.byType(FloatingActionButton);
    expect(fab, findsOneWidget);

    await tester.tap(fab);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Select employee
    await tester.tap(find.text('UI PTO'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Select PTO
    await tester.tap(find.text('PTO'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // PTO Request dialog - enter hours and days
    expect(find.text('PTO Request'), findsOneWidget);

    // Enter hours = 8
    await tester.enterText(find.byType(TextField).at(0), '8');

    // Enter days = 2
    await tester.enterText(find.byType(TextField).at(1), '2');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Tap the day to reveal details
    await tester.tap(find.text('$today').first);
    await tester.pumpAndSettle(const Duration(seconds: 1));
    // There should be two entries for the PTO (each showing 1d)
    expect(find.text('UI PTO – PTO 1d'), findsNWidgets(2));

    // Open popup menu on first entry and delete the group
    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete Group (entire PTO)'));
    await tester.pumpAndSettle();

    // Confirm deletion
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    // Details should no longer show the PTO entries
    expect(find.text('UI PTO – PTO 1d'), findsNothing);
  });
}
