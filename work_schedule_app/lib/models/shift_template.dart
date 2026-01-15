class ShiftTemplate {
  final int? id;
  final String jobCode;
  final String templateName;
  final String startTime; // HH:MM format

  ShiftTemplate({
    this.id,
    required this.jobCode,
    required this.templateName,
    required this.startTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'jobCode': jobCode,
      'templateName': templateName,
      'startTime': startTime,
    };
  }

  factory ShiftTemplate.fromMap(Map<String, dynamic> map) {
    return ShiftTemplate(
      id: map['id'] as int?,
      jobCode: map['jobCode'] as String,
      templateName: map['templateName'] as String,
      startTime: map['startTime'] as String,
    );
  }

  ShiftTemplate copyWith({
    int? id,
    String? jobCode,
    String? templateName,
    String? startTime,
  }) {
    return ShiftTemplate(
      id: id ?? this.id,
      jobCode: jobCode ?? this.jobCode,
      templateName: templateName ?? this.templateName,
      startTime: startTime ?? this.startTime,
    );
  }
}
