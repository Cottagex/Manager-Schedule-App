import '../database/time_off_dao.dart';
import '../models/trimester_summary.dart';

class PtoTrimesterService {
  final TimeOffDao _timeOffDao;

  PtoTrimesterService({TimeOffDao? timeOffDao})
      : _timeOffDao = timeOffDao ?? TimeOffDao();

  List<Map<String, dynamic>> _getTrimesterRanges(int year) {
    return [
      {
        "label": "Trimester 1",
        "start": DateTime(year, 1, 1),
        "end": DateTime(year, 4, 30),
      },
      {
        "label": "Trimester 2",
        "start": DateTime(year, 5, 1),
        "end": DateTime(year, 8, 31),
      },
      {
        "label": "Trimester 3",
        "start": DateTime(year, 9, 1),
        "end": DateTime(year, 12, 31),
      },
    ];
  }

  Future<List<TrimesterSummary>> calculateTrimesterSummaries(
    int employeeId, {
    int? year,
  }) async {
    final y = year ?? DateTime.now().year;

    final trimesters = _getTrimesterRanges(y);
    final List<TrimesterSummary> summaries = [];

    int carryover = 0; // starts at 0 for Trimester 1

    for (final t in trimesters) {
      final start = t["start"] as DateTime;
      final end = t["end"] as DateTime;
      final label = t["label"] as String;

      // PTO used in this trimester
      final used =
          await _timeOffDao.getPtoUsedInRange(employeeId, start, end);

      // Earned is always 30
      const earned = 30;

      // Available = earned + carryover, capped at 40
      final available = (earned + carryover).clamp(0, 40);

      // Remaining
      final remaining = available - used;

      // Carryover out = min(remaining, 10), never negative
      final carryoverOut = remaining.clamp(0, 10);

      summaries.add(
        TrimesterSummary(
          label: label,
          start: start,
          end: end,
          earned: earned,
          carryoverIn: carryover,
          available: available,
          used: used,
          remaining: remaining,
          carryoverOut: carryoverOut,
        ),
      );

      // Next trimester starts with this carryover
      carryover = carryoverOut;
    }

    return summaries;
  }

  /// Returns the remaining PTO (hours) for the given [employeeId] for the
  /// trimester containing [date]. If no trimester is found, returns 0.
  Future<int> getRemainingForDate(int employeeId, DateTime date) async {
    final summaries =
        await calculateTrimesterSummaries(employeeId, year: date.year);

    for (final s in summaries) {
      if (!date.isBefore(s.start) && !date.isAfter(s.end)) {
        return s.remaining;
      }
    }

    return 0;
  }
}
