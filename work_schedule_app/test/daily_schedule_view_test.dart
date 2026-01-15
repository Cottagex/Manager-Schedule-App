import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:work_schedule_app/widgets/schedule/schedule_view.dart';
import 'package:work_schedule_app/models/employee.dart';

void main() {
  testWidgets('Daily view shows shifts sorted by start time', (WidgetTester tester) async {
    final date = DateTime(2026, 1, 14);
    final employees = [
      Employee(id: 1, name: 'Alice', jobCode: 'gm'),
      Employee(id: 2, name: 'Bob', jobCode: 'assistant'),
      Employee(id: 3, name: 'Charlie', jobCode: 'swing'),
    ];

    final shifts = [
      // Bob at 09:00
      ShiftPlaceholder(employeeId: 2, start: DateTime(date.year, date.month, date.day, 9), end: DateTime(date.year, date.month, date.day, 17), text: 'Shift'),
      // Alice at 07:00
      ShiftPlaceholder(employeeId: 1, start: DateTime(date.year, date.month, date.day, 7, 0), end: DateTime(date.year, date.month, date.day, 15), text: 'Shift'),
      // Charlie at 12:00
      ShiftPlaceholder(employeeId: 3, start: DateTime(date.year, date.month, date.day, 12), end: DateTime(date.year, date.month, date.day, 20), text: 'Shift'),
    ];

    await tester.pumpWidget(MaterialApp(home: Scaffold(body: DailyScheduleView(date: date, employees: employees, shifts: shifts))));
    await tester.pumpAndSettle();

    // Verify the ListTiles are ordered: Alice (07:00), Bob (09:00), Charlie (12:00)
    final listTiles = tester.widgetList<ListTile>(find.byType(ListTile)).toList();
    expect(listTiles.length, 3);

    expect((listTiles[0].title as Text).data, 'Alice');
    expect((listTiles[1].title as Text).data, 'Bob');
    expect((listTiles[2].title as Text).data, 'Charlie');
  });
}
