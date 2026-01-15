import 'package:flutter/material.dart';

/// App-level theme mode that can be listened to and changed at runtime.
final ValueNotifier<ThemeMode> appThemeMode = ValueNotifier(ThemeMode.system);
