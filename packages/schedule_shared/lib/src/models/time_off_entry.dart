import 'package:cloud_firestore/cloud_firestore.dart';

class TimeOffEntry {
  final int? id;
  final int employeeId;
  final DateTime date;
  final String timeOffType; // pto / vac / sick
  final int hours;
  final String? vacationGroupId;
  final bool isAllDay;
  final String? startTime; // format: "HH:mm"
  final String? endTime;   // format: "HH:mm"

  TimeOffEntry({
    this.id,
    required this.employeeId,
    required this.date,
    required this.timeOffType,
    required this.hours,
    this.vacationGroupId,
    this.isAllDay = true,
    this.startTime,
    this.endTime,
  });

  TimeOffEntry copyWith({
    int? id,
    int? employeeId,
    DateTime? date,
    String? timeOffType,
    int? hours,
    String? vacationGroupId,
    bool? isAllDay,
    String? startTime,
    String? endTime,
  }) {
    return TimeOffEntry(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      date: date ?? this.date,
      timeOffType: timeOffType ?? this.timeOffType,
      hours: hours ?? this.hours,
      vacationGroupId: vacationGroupId ?? this.vacationGroupId,
      isAllDay: isAllDay ?? this.isAllDay,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  /// Convert to SQLite map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employeeId': employeeId,
      'date': date.toIso8601String(),
      'timeOffType': timeOffType,
      'hours': hours,
      'vacationGroupId': vacationGroupId,
      'isAllDay': isAllDay ? 1 : 0,
      'startTime': startTime,
      'endTime': endTime,
    };
  }

  /// Create from SQLite map
  factory TimeOffEntry.fromMap(Map<String, dynamic> map) {
    return TimeOffEntry(
      id: map['id'],
      employeeId: map['employeeId'],
      date: DateTime.parse(map['date']),
      timeOffType: map['timeOffType'],
      hours: map['hours'] ?? 0,
      vacationGroupId: map['vacationGroupId'],
      isAllDay: (map['isAllDay'] ?? 1) == 1,
      startTime: map['startTime'],
      endTime: map['endTime'],
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'employeeId': employeeId,
      'date': Timestamp.fromDate(date),
      'timeOffType': timeOffType,
      'hours': hours,
      'vacationGroupId': vacationGroupId,
      'isAllDay': isAllDay,
      'startTime': startTime,
      'endTime': endTime,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Create from Firestore document
  factory TimeOffEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TimeOffEntry(
      id: data['id'],
      employeeId: data['employeeId'],
      date: (data['date'] as Timestamp).toDate(),
      timeOffType: data['timeOffType'],
      hours: data['hours'] ?? 0,
      vacationGroupId: data['vacationGroupId'],
      isAllDay: data['isAllDay'] ?? true,
      startTime: data['startTime'],
      endTime: data['endTime'],
    );
  }

  /// Returns a human-readable time range string
  String get timeRangeDisplay {
    if (isAllDay) return 'All Day';
    if (startTime == null || endTime == null) return 'All Day';
    return '$startTime - $endTime';
  }

  @override
  String toString() {
    return 'TimeOffEntry(id: $id, employeeId: $employeeId, date: $date, type: $timeOffType, hours: $hours)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimeOffEntry &&
        other.id == id &&
        other.employeeId == employeeId &&
        other.date == date &&
        other.timeOffType == timeOffType;
  }

  @override
  int get hashCode => Object.hash(id, employeeId, date, timeOffType);
}
