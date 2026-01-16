class ShiftTemplate {
  final int? id;
  final String templateName;
  final String startTime; // HH:MM format

  ShiftTemplate({
    this.id,
    required this.templateName,
    required this.startTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'templateName': templateName,
      'startTime': startTime,
    };
  }

  factory ShiftTemplate.fromMap(Map<String, dynamic> map) {
    return ShiftTemplate(
      id: map['id'] as int?,
      templateName: map['templateName'] as String,
      startTime: map['startTime'] as String,
    );
  }

  ShiftTemplate copyWith({
    int? id,
    String? templateName,
    String? startTime,
  }) {
    return ShiftTemplate(
      id: id ?? this.id,
      templateName: templateName ?? this.templateName,
      startTime: startTime ?? this.startTime,
    );
  }
}
