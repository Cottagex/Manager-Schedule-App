class ShiftEntry {
  final String id;
  final DateTime date;
  final String text;

  ShiftEntry({
    required this.id,
    required this.date,
    required this.text,
  });

  ShiftEntry copyWith({
    String? id,
    DateTime? date,
    String? text,
  }) {
    return ShiftEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      text: text ?? this.text,
    );
  }
}
