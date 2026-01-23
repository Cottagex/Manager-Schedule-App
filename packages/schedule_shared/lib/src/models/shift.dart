import 'package:cloud_firestore/cloud_firestore.dart';

class Shift {
  final int? id;
  final int employeeId;
  final DateTime startTime;
  final DateTime endTime;
  final String? label;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? publishedAt; // When this was synced to Firestore

  Shift({
    this.id,
    required this.employeeId,
    required this.startTime,
    required this.endTime,
    this.label,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.publishedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Shift copyWith({
    int? id,
    int? employeeId,
    DateTime? startTime,
    DateTime? endTime,
    String? label,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? publishedAt,
  }) {
    return Shift(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      label: label ?? this.label,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      publishedAt: publishedAt ?? this.publishedAt,
    );
  }

  /// Convert to SQLite map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employeeId': employeeId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'label': label,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from SQLite map
  factory Shift.fromMap(Map<String, dynamic> map) {
    return Shift(
      id: map['id'] as int?,
      employeeId: map['employeeId'] as int,
      startTime: DateTime.parse(map['startTime'] as String),
      endTime: DateTime.parse(map['endTime'] as String),
      label: map['label'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'employeeId': employeeId,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'label': label,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'publishedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Create from Firestore document
  factory Shift.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Shift(
      id: data['id'] as int?,
      employeeId: data['employeeId'] as int,
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      label: data['label'] as String?,
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      publishedAt: (data['publishedAt'] as Timestamp?)?.toDate(),
    );
  }

  @override
  String toString() {
    return 'Shift(id: $id, employeeId: $employeeId, start: $startTime, end: $endTime, label: $label)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Shift &&
        other.id == id &&
        other.employeeId == employeeId &&
        other.startTime == startTime &&
        other.endTime == endTime;
  }

  @override
  int get hashCode => Object.hash(id, employeeId, startTime, endTime);
}
