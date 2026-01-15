class EmployeeAvailability {
  final int? id;
  final int employeeId;
  final String availabilityType; // 'generic', 'biweekly', 'monthly'
  final int? dayOfWeek; // 0 = Sunday, 6 = Saturday (for generic and biweekly)
  final int? weekNumber; // 1 or 2 (for biweekly only)
  final String? specificDate; // YYYY-MM-DD (for monthly only)
  final String? startTime; // HH:MM format
  final String? endTime; // HH:MM format
  final bool allDay;
  final bool available; // true = available, false = unavailable

  EmployeeAvailability({
    this.id,
    required this.employeeId,
    required this.availabilityType,
    this.dayOfWeek,
    this.weekNumber,
    this.specificDate,
    this.startTime,
    this.endTime,
    required this.allDay,
    required this.available,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employeeId': employeeId,
      'availabilityType': availabilityType,
      'dayOfWeek': dayOfWeek,
      'weekNumber': weekNumber,
      'specificDate': specificDate,
      'startTime': startTime,
      'endTime': endTime,
      'allDay': allDay ? 1 : 0,
      'available': available ? 1 : 0,
    };
  }

  factory EmployeeAvailability.fromMap(Map<String, dynamic> map) {
    return EmployeeAvailability(
      id: map['id'] as int?,
      employeeId: map['employeeId'] as int,
      availabilityType: map['availabilityType'] as String,
      dayOfWeek: map['dayOfWeek'] as int?,
      weekNumber: map['weekNumber'] as int?,
      specificDate: map['specificDate'] as String?,
      startTime: map['startTime'] as String?,
      endTime: map['endTime'] as String?,
      allDay: (map['allDay'] as int) == 1,
      available: (map['available'] as int) == 1,
    );
  }
}
