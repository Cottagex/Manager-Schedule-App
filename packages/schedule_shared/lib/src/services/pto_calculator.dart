import '../models/trimester_summary.dart';
import '../models/time_off_entry.dart';

/// Pure calculation service for PTO trimesters.
/// This doesn't depend on any database - it takes data as input.
class PtoCalculator {
  /// Get trimester date ranges for a given year
  static List<Map<String, dynamic>> getTrimesterRanges(int year) {
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

  /// Calculate PTO used in a date range from a list of time-off entries
  static int calculatePtoUsedInRange(
    List<TimeOffEntry> entries,
    DateTime start,
    DateTime end,
  ) {
    int total = 0;
    for (final entry in entries) {
      if (entry.timeOffType == 'pto' &&
          !entry.date.isBefore(start) &&
          !entry.date.isAfter(end)) {
        total += entry.hours;
      }
    }
    return total;
  }

  /// Calculate trimester summaries from a list of time-off entries
  /// 
  /// [ptoEntries] should contain all PTO entries for the employee for the year
  /// [year] is the year to calculate for (defaults to current year)
  /// [initialCarryover] is the carryover from the previous year's last trimester
  static List<TrimesterSummary> calculateTrimesterSummaries(
    List<TimeOffEntry> ptoEntries, {
    int? year,
    int initialCarryover = 0,
  }) {
    final y = year ?? DateTime.now().year;
    final trimesters = getTrimesterRanges(y);
    final List<TrimesterSummary> summaries = [];

    int carryover = initialCarryover;

    for (final t in trimesters) {
      final start = t["start"] as DateTime;
      final end = t["end"] as DateTime;
      final label = t["label"] as String;

      // PTO used in this trimester
      final used = calculatePtoUsedInRange(ptoEntries, start, end);

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

  /// Get the trimester summary containing a specific date
  static TrimesterSummary? getSummaryForDate(
    List<TrimesterSummary> summaries,
    DateTime date,
  ) {
    for (final summary in summaries) {
      if (summary.containsDate(date)) {
        return summary;
      }
    }
    return null;
  }

  /// Get remaining PTO hours for a specific date
  static int getRemainingForDate(
    List<TrimesterSummary> summaries,
    DateTime date,
  ) {
    final summary = getSummaryForDate(summaries, date);
    return summary?.remaining ?? 0;
  }

  /// Determine which trimester a date falls into (1, 2, or 3)
  static int getTrimesterNumber(DateTime date) {
    if (date.month >= 1 && date.month <= 4) return 1;
    if (date.month >= 5 && date.month <= 8) return 2;
    return 3;
  }

  /// Get the current trimester for today
  static int get currentTrimester => getTrimesterNumber(DateTime.now());
}
