import 'package:flutter/material.dart';
import '../widgets/schedule/schedule_view.dart';

class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: ScheduleView(),
        ),
      ),
    );
  }
}
