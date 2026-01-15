class PtoHistory {
  final int? id;
  final int employeeId;
  final DateTime trimesterStart;
  final int carryoverHours;

  PtoHistory({
    this.id,
    required this.employeeId,
    required this.trimesterStart,
    required this.carryoverHours,
  });

  factory PtoHistory.fromMap(Map<String, dynamic> map) {
    return PtoHistory(
      id: map['id'],
      employeeId: map['employeeId'],
      trimesterStart: DateTime.parse(map['trimesterStart']),
      carryoverHours: map['carryoverHours'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employeeId': employeeId,
      'trimesterStart': trimesterStart.toIso8601String(),
      'carryoverHours': carryoverHours,
    };
  }
}
