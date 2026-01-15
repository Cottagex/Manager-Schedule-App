class ScheduleNote {
  final int? id;
  final DateTime date;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;

  ScheduleNote({
    this.id,
    required this.date,
    required this.note,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ScheduleNote.fromMap(Map<String, dynamic> map) {
    final dateStr = map['date'] as String;
    final dateParts = dateStr.split('-');
    
    return ScheduleNote(
      id: map['id'] as int?,
      date: DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
      ),
      note: map['note'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  ScheduleNote copyWith({
    int? id,
    DateTime? date,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ScheduleNote(
      id: id ?? this.id,
      date: date ?? this.date,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'ScheduleNote(id: $id, date: $date, note: $note)';
}
