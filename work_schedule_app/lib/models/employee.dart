class Employee {
  final int? id;
  final String name;
  final String jobCode;

  // Firebase sync fields
  final String? email;
  final String? uid; // Firebase Auth UID

  // Vacation tracking
  final int vacationWeeksAllowed;
  final int vacationWeeksUsed;

  Employee({
    this.id,
    required this.name,
    required this.jobCode,
    this.email,
    this.uid,
    this.vacationWeeksAllowed = 0,
    this.vacationWeeksUsed = 0,
  });

  Employee copyWith({
    int? id,
    String? name,
    String? jobCode,
    String? email,
    String? uid,
    int? vacationWeeksAllowed,
    int? vacationWeeksUsed,
  }) {
    return Employee(
      id: id ?? this.id,
      name: name ?? this.name,
      jobCode: jobCode ?? this.jobCode,
      email: email ?? this.email,
      uid: uid ?? this.uid,
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
      'email': email,
      'uid': uid,
      'vacationWeeksAllowed': vacationWeeksAllowed,
      'vacationWeeksUsed': vacationWeeksUsed,
    };
  }

  factory Employee.fromMap(Map<String, dynamic> map) {
    return Employee(
      id: map['id'],
      name: map['name'],
      jobCode: map['jobCode'],
      email: map['email'],
      uid: map['uid'],
      vacationWeeksAllowed: map['vacationWeeksAllowed'] ?? 0,
      vacationWeeksUsed: map['vacationWeeksUsed'] ?? 0,
    );
  }
}
