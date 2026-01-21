import 'package:flutter/material.dart';
import '../models/store_hours.dart';

/// Shows a custom time picker dialog with Open/Close quick-select buttons.
/// The buttons set the time to the store's opening or closing time for the given day.
Future<TimeOfDay?> showCustomTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
  int? dayOfWeek,
}) async {
  // Get store hours for the specific day
  final storeHours = StoreHours.cached;
  final effectiveDayOfWeek = dayOfWeek ?? DateTime.now().weekday;

  // Parse store open/close times
  TimeOfDay parseStoreTime(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 9,
      minute: int.tryParse(parts[1]) ?? 0,
    );
  }

  final storeOpenTime = parseStoreTime(storeHours.getOpenTimeForDay(effectiveDayOfWeek));
  final storeCloseTime = parseStoreTime(storeHours.getCloseTimeForDay(effectiveDayOfWeek));

  String formatTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final mm = t.minute.toString().padLeft(2, '0');
    final suffix = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$mm $suffix';
  }

  TimeOfDay selectedTime = initialTime;

  return showDialog<TimeOfDay>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            contentPadding: EdgeInsets.zero,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Time picker content
                SizedBox(
                  height: 280,
                  child: TimePickerDialog(
                    initialTime: selectedTime,
                    cancelText: '',
                    confirmText: '',
                    helpText: 'Select time',
                  ),
                ),
                // Open/Close buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context, storeOpenTime);
                          },
                          icon: const Icon(Icons.store, size: 16),
                          label: Text('Open (${formatTime(storeOpenTime)})', 
                            style: const TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context, storeCloseTime);
                          },
                          icon: const Icon(Icons.store_mall_directory, size: 16),
                          label: Text('Close (${formatTime(storeCloseTime)})', 
                            style: const TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  // Show the actual time picker and get the result
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: selectedTime,
                  );
                  if (picked != null && context.mounted) {
                    Navigator.pop(context, picked);
                  }
                },
                child: const Text('Pick Time'),
              ),
            ],
          );
        },
      );
    },
  );
}

/// A simpler approach: wrap showTimePicker to add store hours buttons
/// This shows the standard time picker, then shows a dialog to confirm or use store hours
Future<TimeOfDay?> showTimePickerWithStoreHours({
  required BuildContext context,
  required TimeOfDay initialTime,
  int? dayOfWeek,
}) async {
  // Get store hours for the specific day
  final storeHours = StoreHours.cached;
  final effectiveDayOfWeek = dayOfWeek ?? DateTime.now().weekday;

  // Parse store open/close times
  TimeOfDay parseStoreTime(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 9,
      minute: int.tryParse(parts[1]) ?? 0,
    );
  }

  final storeOpenTime = parseStoreTime(storeHours.getOpenTimeForDay(effectiveDayOfWeek));
  final storeCloseTime = parseStoreTime(storeHours.getCloseTimeForDay(effectiveDayOfWeek));

  String formatTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final mm = t.minute.toString().padLeft(2, '0');
    final suffix = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$mm $suffix';
  }

  // Helper function to open the time picker
  Future<void> openTimePicker(BuildContext ctx) async {
    final picked = await showTimePicker(
      context: ctx,
      initialTime: initialTime,
    );
    if (picked != null && ctx.mounted) {
      Navigator.pop(ctx, picked);
    }
  }

  // Show a dialog with options: Open, Close, or Custom (opens time picker)
  return showDialog<TimeOfDay>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Select Time'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Current time display - tappable to open time picker
            InkWell(
              onTap: () => openTimePicker(context),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  formatTime(initialTime),
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Quick select buttons
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context, storeOpenTime),
              icon: const Icon(Icons.store),
              label: Text('Store Open (${formatTime(storeOpenTime)})'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context, storeCloseTime),
              icon: const Icon(Icons.store_mall_directory),
              label: Text('Store Close (${formatTime(storeCloseTime)})'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => openTimePicker(context),
              icon: const Icon(Icons.access_time),
              label: const Text('Choose Custom Time'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      );
    },
  );
}
