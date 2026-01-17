class ShiftType {
  final int? id;
  final String key; // Unique identifier like 'open', 'lunch', 'custom_1'
  final String label; // Display name
  final int sortOrder;
  final String rangeStart; // Shift runner time range start (HH:mm)
  final String rangeEnd; // Shift runner time range end (HH:mm)
  final String defaultShiftStart; // Default employee shift start (HH:mm)
  final String defaultShiftEnd; // Default employee shift end (HH:mm)
  final String colorHex;

  // Default shift types
  static const List<Map<String, dynamic>> defaults = [
    {
      'key': 'open',
      'label': 'Open',
      'sortOrder': 0,
      'rangeStart': '04:30',
      'rangeEnd': '11:00',
      'defaultShiftStart': '04:30',
      'defaultShiftEnd': '11:00',
      'colorHex': '#FF9800',
    },
    {
      'key': 'lunch',
      'label': 'Lunch',
      'sortOrder': 1,
      'rangeStart': '11:00',
      'rangeEnd': '15:00',
      'defaultShiftStart': '11:00',
      'defaultShiftEnd': '15:00',
      'colorHex': '#4CAF50',
    },
    {
      'key': 'dinner',
      'label': 'Dinner',
      'sortOrder': 2,
      'rangeStart': '15:00',
      'rangeEnd': '20:00',
      'defaultShiftStart': '15:00',
      'defaultShiftEnd': '20:00',
      'colorHex': '#2196F3',
    },
    {
      'key': 'close',
      'label': 'Close',
      'sortOrder': 3,
      'rangeStart': '20:00',
      'rangeEnd': '01:00',
      'defaultShiftStart': '20:00',
      'defaultShiftEnd': '01:00',
      'colorHex': '#9C27B0',
    },
  ];

  /// Get default shift types as ShiftType objects
  static List<ShiftType> get defaultShiftTypes =>
      defaults.map((d) => ShiftType.fromMap(d)).toList();

  ShiftType({
    this.id,
    required this.key,
    required this.label,
    required this.sortOrder,
    required this.rangeStart,
    required this.rangeEnd,
    required this.defaultShiftStart,
    required this.defaultShiftEnd,
    required this.colorHex,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'key': key,
      'label': label,
      'sortOrder': sortOrder,
      'rangeStart': rangeStart,
      'rangeEnd': rangeEnd,
      'defaultShiftStart': defaultShiftStart,
      'defaultShiftEnd': defaultShiftEnd,
      'colorHex': colorHex,
    };
  }

  factory ShiftType.fromMap(Map<String, dynamic> map) {
    return ShiftType(
      id: map['id'] as int?,
      key: map['key'] as String,
      label: map['label'] as String,
      sortOrder: map['sortOrder'] as int,
      rangeStart: map['rangeStart'] as String,
      rangeEnd: map['rangeEnd'] as String,
      defaultShiftStart: map['defaultShiftStart'] as String,
      defaultShiftEnd: map['defaultShiftEnd'] as String,
      colorHex: map['colorHex'] as String,
    );
  }

  ShiftType copyWith({
    int? id,
    String? key,
    String? label,
    int? sortOrder,
    String? rangeStart,
    String? rangeEnd,
    String? defaultShiftStart,
    String? defaultShiftEnd,
    String? colorHex,
  }) {
    return ShiftType(
      id: id ?? this.id,
      key: key ?? this.key,
      label: label ?? this.label,
      sortOrder: sortOrder ?? this.sortOrder,
      rangeStart: rangeStart ?? this.rangeStart,
      rangeEnd: rangeEnd ?? this.rangeEnd,
      defaultShiftStart: defaultShiftStart ?? this.defaultShiftStart,
      defaultShiftEnd: defaultShiftEnd ?? this.defaultShiftEnd,
      colorHex: colorHex ?? this.colorHex,
    );
  }

  /// Generate a unique key for a new custom shift
  static String generateKey() {
    return 'custom_${DateTime.now().millisecondsSinceEpoch}';
  }
}
