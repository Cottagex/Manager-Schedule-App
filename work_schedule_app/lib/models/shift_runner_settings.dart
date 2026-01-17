class ShiftRunnerSettings {
  final String shiftType; // 'open', 'lunch', 'dinner', 'close'
  final String? customLabel; // Custom display name (null = use default)
  final String? shiftRangeStart; // Shift runner time range start (HH:mm)
  final String? shiftRangeEnd; // Shift runner time range end (HH:mm)
  final String? defaultStartTime; // Default employee shift start time (HH:mm)
  final String? defaultEndTime; // Default employee shift end time (HH:mm)

  // Default time ranges for each shift type (shift runner ranges)
  static const Map<String, Map<String, String>> defaultTimes = {
    'open': {'start': '04:30', 'end': '11:00'},
    'lunch': {'start': '11:00', 'end': '15:00'},
    'dinner': {'start': '15:00', 'end': '20:00'},
    'close': {'start': '20:00', 'end': '01:00'},
  };

  // Default labels
  static const Map<String, String> defaultLabels = {
    'open': 'Open',
    'lunch': 'Lunch',
    'dinner': 'Dinner',
    'close': 'Close',
  };

  ShiftRunnerSettings({
    required this.shiftType,
    this.customLabel,
    this.shiftRangeStart,
    this.shiftRangeEnd,
    this.defaultStartTime,
    this.defaultEndTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'shiftType': shiftType,
      'customLabel': customLabel,
      'shiftRangeStart': shiftRangeStart,
      'shiftRangeEnd': shiftRangeEnd,
      'defaultStartTime': defaultStartTime,
      'defaultEndTime': defaultEndTime,
    };
  }

  factory ShiftRunnerSettings.fromMap(Map<String, dynamic> map) {
    return ShiftRunnerSettings(
      shiftType: map['shiftType'] as String,
      customLabel: map['customLabel'] as String?,
      shiftRangeStart: map['shiftRangeStart'] as String?,
      shiftRangeEnd: map['shiftRangeEnd'] as String?,
      defaultStartTime: map['defaultStartTime'] as String?,
      defaultEndTime: map['defaultEndTime'] as String?,
    );
  }

  /// Get the display label (custom or default)
  String get displayLabel => customLabel ?? defaultLabels[shiftType] ?? shiftType;

  /// Get the effective shift range start (custom or default)
  String get effectiveShiftRangeStart =>
      shiftRangeStart ?? defaultTimes[shiftType]?['start'] ?? '00:00';

  /// Get the effective shift range end (custom or default)
  String get effectiveShiftRangeEnd =>
      shiftRangeEnd ?? defaultTimes[shiftType]?['end'] ?? '00:00';

  /// Get the effective employee shift start time (custom or default)
  String get effectiveStartTime =>
      defaultStartTime ?? defaultTimes[shiftType]?['start'] ?? '00:00';

  /// Get the effective employee shift end time (custom or default)
  String get effectiveEndTime =>
      defaultEndTime ?? defaultTimes[shiftType]?['end'] ?? '00:00';

  /// Check if this has custom shift range
  bool get hasCustomShiftRange =>
      shiftRangeStart != null || shiftRangeEnd != null;

  /// Check if this has custom employee shift
  bool get hasCustomEmployeeShift =>
      defaultStartTime != null || defaultEndTime != null;

  /// Check if this has any custom settings
  bool get hasCustomSettings =>
      customLabel != null || hasCustomShiftRange || hasCustomEmployeeShift;

  ShiftRunnerSettings copyWith({
    String? shiftType,
    String? customLabel,
    String? shiftRangeStart,
    String? shiftRangeEnd,
    String? defaultStartTime,
    String? defaultEndTime,
    bool clearCustomLabel = false,
    bool clearShiftRangeStart = false,
    bool clearShiftRangeEnd = false,
    bool clearDefaultStartTime = false,
    bool clearDefaultEndTime = false,
  }) {
    return ShiftRunnerSettings(
      shiftType: shiftType ?? this.shiftType,
      customLabel: clearCustomLabel ? null : (customLabel ?? this.customLabel),
      shiftRangeStart: clearShiftRangeStart ? null : (shiftRangeStart ?? this.shiftRangeStart),
      shiftRangeEnd: clearShiftRangeEnd ? null : (shiftRangeEnd ?? this.shiftRangeEnd),
      defaultStartTime: clearDefaultStartTime ? null : (defaultStartTime ?? this.defaultStartTime),
      defaultEndTime: clearDefaultEndTime ? null : (defaultEndTime ?? this.defaultEndTime),
    );
  }
}
