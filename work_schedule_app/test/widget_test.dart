// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:work_schedule_app/main.dart';

void _initTestDb() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}

void main() {
  testWidgets('App loads and shows navigation title', (WidgetTester tester) async {
    // Initialize FFI DB for tests that exercise DB-backed widgets.
    _initTestDb();

    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the initial navigation title is present.
    expect(find.text('Schedule'), findsWidgets);
  });
}
