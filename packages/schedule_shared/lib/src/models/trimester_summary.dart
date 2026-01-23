/// Summary of PTO usage for a single trimester
class TrimesterSummary {
  final String label;
  final DateTime start;
  final DateTime end;

  final int earned;        // always 30
  final int carryoverIn;   // from previous trimester
  final int available;     // earned + carryoverIn, capped at 40
  final int used;          // PTO used in this trimester
  final int remaining;     // available - used
  final int carryoverOut;  // min(remaining, 10)

  TrimesterSummary({
    required this.label,
    required this.start,
    required this.end,
    required this.earned,
    required this.carryoverIn,
    required this.available,
    required this.used,
    required this.remaining,
    required this.carryoverOut,
  });

  /// Convert to a map for JSON serialization
  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
      'earned': earned,
      'carryoverIn': carryoverIn,
      'available': available,
      'used': used,
      'remaining': remaining,
      'carryoverOut': carryoverOut,
    };
  }

  /// Create from a map
  factory TrimesterSummary.fromMap(Map<String, dynamic> map) {
    return TrimesterSummary(
      label: map['label'],
      start: DateTime.parse(map['start']),
      end: DateTime.parse(map['end']),
      earned: map['earned'],
      carryoverIn: map['carryoverIn'],
      available: map['available'],
      used: map['used'],
      remaining: map['remaining'],
      carryoverOut: map['carryoverOut'],
    );
  }

  /// Check if a date falls within this trimester
  bool containsDate(DateTime date) {
    return !date.isBefore(start) && !date.isAfter(end);
  }

  @override
  String toString() {
    return 'TrimesterSummary($label: earned=$earned, carryIn=$carryoverIn, available=$available, used=$used, remaining=$remaining, carryOut=$carryoverOut)';
  }
}
