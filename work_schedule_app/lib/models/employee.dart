class Employee {
  final int? id;
  final String name;
  final String jobCode;

  // NEW FIELDS
  final int vacationWeeksAllowed;
  final int vacationWeeksUsed;

  Employee({
    this.id,
    required this.name,
    required this.jobCode,
    this.vacationWeeksAllowed = 0,
    this.vacationWeeksUsed = 0,
  });

  Employee copyWith({
    int? id,
    String? name,
    String? jobCode,
    int? vacationWeeksAllowed,
    int? vacationWeeksUsed,
  }) {
    return Employee(
      id: id ?? this.id,
      name: name ?? this.name,
      jobCode: jobCode ?? this.jobCode,
      vacationWeeksAllowed:
          vacationWeeksAllowed ?? this.vacationWeeksAllowed,
      vacationWeeksUsed: vacationWeeksUsed ?? this.vacationWeeksUsed,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'jobCode': jobCode,
      'vacationWeeksAllowed': vacationWeeksAllowed,
      'vacationWeeksUsed': vacationWeeksUsed,
    };
  }

  factory Employee.fromMap(Map<String, dynamic> map) {
    return Employee(
      id: map['id'],
      name: map['name'],
      jobCode: map['jobCode'],
      vacationWeeksAllowed: map['vacationWeeksAllowed'] ?? 0,
      vacationWeeksUsed: map['vacationWeeksUsed'] ?? 0,
    );
  }
}
