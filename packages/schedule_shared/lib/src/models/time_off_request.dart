import 'package:cloud_firestore/cloud_firestore.dart';

/// Status of a time-off request
enum TimeOffRequestStatus {
  pending,
  approved,
  denied,
}

/// A time-off request submitted by an employee
class TimeOffRequest {
  final String? id; // Firestore document ID
  final int employeeId;
  final String employeeEmail;
  final String employeeName;
  final DateTime date;
  final String timeOffType; // pto / vac / sick
  final int hours;
  final bool isAllDay;
  final String? startTime;
  final String? endTime;
  final String? vacationGroupId;
  final TimeOffRequestStatus status;
  final bool autoApproved;
  final DateTime requestedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? denialReason;
  final String? notes;

  TimeOffRequest({
    this.id,
    required this.employeeId,
    required this.employeeEmail,
    required this.employeeName,
    required this.date,
    required this.timeOffType,
    required this.hours,
    this.isAllDay = true,
    this.startTime,
    this.endTime,
    this.vacationGroupId,
    this.status = TimeOffRequestStatus.pending,
    this.autoApproved = false,
    DateTime? requestedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.denialReason,
    this.notes,
  }) : requestedAt = requestedAt ?? DateTime.now();

  TimeOffRequest copyWith({
    String? id,
    int? employeeId,
    String? employeeEmail,
    String? employeeName,
    DateTime? date,
    String? timeOffType,
    int? hours,
    bool? isAllDay,
    String? startTime,
    String? endTime,
    String? vacationGroupId,
    TimeOffRequestStatus? status,
    bool? autoApproved,
    DateTime? requestedAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? denialReason,
    String? notes,
  }) {
    return TimeOffRequest(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeEmail: employeeEmail ?? this.employeeEmail,
      employeeName: employeeName ?? this.employeeName,
      date: date ?? this.date,
      timeOffType: timeOffType ?? this.timeOffType,
      hours: hours ?? this.hours,
      isAllDay: isAllDay ?? this.isAllDay,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      vacationGroupId: vacationGroupId ?? this.vacationGroupId,
      status: status ?? this.status,
      autoApproved: autoApproved ?? this.autoApproved,
      requestedAt: requestedAt ?? this.requestedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      denialReason: denialReason ?? this.denialReason,
      notes: notes ?? this.notes,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'employeeId': employeeId,
      'employeeEmail': employeeEmail,
      'employeeName': employeeName,
      'date': Timestamp.fromDate(date),
      'timeOffType': timeOffType,
      'hours': hours,
      'isAllDay': isAllDay,
      'startTime': startTime,
      'endTime': endTime,
      'vacationGroupId': vacationGroupId,
      'status': status.name,
      'autoApproved': autoApproved,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'reviewedBy': reviewedBy,
      'denialReason': denialReason,
      'notes': notes,
    };
  }

  /// Create from Firestore document
  factory TimeOffRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TimeOffRequest(
      id: doc.id,
      employeeId: data['employeeId'],
      employeeEmail: data['employeeEmail'] ?? '',
      employeeName: data['employeeName'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      timeOffType: data['timeOffType'] ?? 'pto',
      hours: data['hours'] ?? 0,
      isAllDay: data['isAllDay'] ?? true,
      startTime: data['startTime'],
      endTime: data['endTime'],
      vacationGroupId: data['vacationGroupId'],
      status: TimeOffRequestStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => TimeOffRequestStatus.pending,
      ),
      autoApproved: data['autoApproved'] ?? false,
      requestedAt: (data['requestedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reviewedAt: (data['reviewedAt'] as Timestamp?)?.toDate(),
      reviewedBy: data['reviewedBy'],
      denialReason: data['denialReason'],
      notes: data['notes'],
    );
  }

  /// Check if this request requires manager approval
  /// Returns true if: vacation OR would exceed 2 entries for the day
  static bool requiresApproval({
    required String timeOffType,
    required int existingEntriesForDay,
  }) {
    // All vacation requests require approval
    if (timeOffType == 'vac') return true;
    
    // PTO/sick require approval if 2+ entries already exist for the day
    return existingEntriesForDay >= 2;
  }

  /// Returns a human-readable time range string
  String get timeRangeDisplay {
    if (isAllDay) return 'All Day';
    if (startTime == null || endTime == null) return 'All Day';
    return '$startTime - $endTime';
  }

  /// Returns a human-readable status string
  String get statusDisplay {
    switch (status) {
      case TimeOffRequestStatus.pending:
        return 'Pending';
      case TimeOffRequestStatus.approved:
        return autoApproved ? 'Auto-Approved' : 'Approved';
      case TimeOffRequestStatus.denied:
        return 'Denied';
    }
  }

  @override
  String toString() {
    return 'TimeOffRequest(id: $id, employee: $employeeName, date: $date, type: $timeOffType, status: $status)';
  }
}
