class ShiftRunner {
  final int? id;
  final DateTime date;
  final String shiftType; // 'open', 'lunch', 'dinner', 'close'
  final String runnerName;

  // Shift time definitions
  static const Map<String, Map<String, String>> shiftTimes = {
    'open': {'start': '04:30', 'end': '11:00', 'label': 'Open'},
    'lunch': {'start': '11:00', 'end': '15:00', 'label': 'Lunch'},
    'dinner': {'start': '15:00', 'end': '20:00', 'label': 'Dinner'},
    'close': {'start': '20:00', 'end': '01:00', 'label': 'Close'},
  };

  static const List<String> shiftOrder = ['open', 'lunch', 'dinner', 'close'];

  ShiftRunner({
    this.id,
    required this.date,
    required this.shiftType,
    required this.runnerName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      'shiftType': shiftType,
      'runnerName': runnerName,
    };
  }

  factory ShiftRunner.fromMap(Map<String, dynamic> map) {
    final dateParts = (map['date'] as String).split('-');
    return ShiftRunner(
      id: map['id'] as int?,
      date: DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
      ),
      shiftType: map['shiftType'] as String,
      runnerName: map['runnerName'] as String,
    );
  }

  ShiftRunner copyWith({
    int? id,
    DateTime? date,
    String? shiftType,
    String? runnerName,
  }) {
    return ShiftRunner(
      id: id ?? this.id,
      date: date ?? this.date,
      shiftType: shiftType ?? this.shiftType,
      runnerName: runnerName ?? this.runnerName,
    );
  }

  /// Get the shift type based on a time
  static String? getShiftTypeForTime(int hour, int minute) {
    final timeValue = hour * 60 + minute;
    
    // Open: 4:30 AM - 11:00 AM (270 - 660)
    if (timeValue >= 270 && timeValue < 660) return 'open';
    // Lunch: 11:00 AM - 3:00 PM (660 - 900)
    if (timeValue >= 660 && timeValue < 900) return 'lunch';
    // Dinner: 3:00 PM - 8:00 PM (900 - 1200)
    if (timeValue >= 900 && timeValue < 1200) return 'dinner';
    // Close: 8:00 PM - 1:00 AM (1200 - 1440 or 0 - 60)
    if (timeValue >= 1200 || timeValue < 60) return 'close';
    
    return null;
  }

  static String getLabelForType(String type) {
    return shiftTimes[type]?['label'] ?? type;
  }
}
