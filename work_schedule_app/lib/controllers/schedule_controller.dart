import 'dart:math';
import '../models/shift_entry.dart';

class ScheduleController {
  final List<ShiftEntry> _entries = [];

  List<ShiftEntry> entriesForDay(DateTime day) {
    return _entries.where((e) =>
      e.date.year == day.year &&
      e.date.month == day.month &&
      e.date.day == day.day
    ).toList();
  }

  void addEntry(DateTime day, String text) {
    _entries.add(
      ShiftEntry(
        id: _randomId(),
        date: day,
        text: text,
      ),
    );
  }

  void deleteEntry(String id) {
    _entries.removeWhere((e) => e.id == id);
  }

  void updateEntry(ShiftEntry updated) {
    final index = _entries.indexWhere((e) => e.id == updated.id);
    if (index != -1) {
      _entries[index] = updated;
    }
  }

  String _randomId() {
    return '${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(1 << 32)}';
  }
}
