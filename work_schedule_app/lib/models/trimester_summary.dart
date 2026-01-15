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
}
