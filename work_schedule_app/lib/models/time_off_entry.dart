class TimeOffEntry {
  final int? id;
  final int employeeId;
  final DateTime date;
  final String timeOffType; // pto / vac / sick
  final int hours;
  final String? vacationGroupId;

  TimeOffEntry({
    required this.id,
    required this.employeeId,
    required this.date,
    required this.timeOffType,
    required this.hours,
    this.vacationGroupId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employeeId': employeeId,
      'date': date.toIso8601String(),
      'timeOffType': timeOffType,
      'hours': hours,
      'vacationGroupId': vacationGroupId,
    };
  }

  factory TimeOffEntry.fromMap(Map<String, dynamic> map) {
    return TimeOffEntry(
      id: map['id'],
      employeeId: map['employeeId'],
      date: DateTime.parse(map['date']),
      timeOffType: map['timeOffType'],
      hours: map['hours'] ?? 0,
      vacationGroupId: map['vacationGroupId'],
    );
  }
}
