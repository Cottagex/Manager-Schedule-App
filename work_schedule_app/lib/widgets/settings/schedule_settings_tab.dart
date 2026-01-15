import 'package:flutter/material.dart';
import '../../database/settings_dao.dart';
import '../../models/settings.dart';

class ScheduleSettingsTab extends StatefulWidget {
  const ScheduleSettingsTab({super.key});

  @override
  State<ScheduleSettingsTab> createState() => _ScheduleSettingsTabState();
}

class _ScheduleSettingsTabState extends State<ScheduleSettingsTab> {
  final SettingsDao _settingsDao = SettingsDao();
  Settings? _settings;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final s = await _settingsDao.getSettings();
    setState(() => _settings = s);
  }

  Future<void> _save() async {
    if (_settings == null) return;
    await _settingsDao.updateSettings(_settings!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Schedule settings saved")),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_settings == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          const Text("Schedule Settings",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          // Minimum Hours Between Shifts
          TextField(
            decoration: const InputDecoration(
              labelText: "Minimum Hours Between Shifts",
            ),
            keyboardType: TextInputType.number,
            controller: TextEditingController(
              text: _settings!.minimumHoursBetweenShifts.toString(),
            ),
            onChanged: (v) {
              final value = int.tryParse(v) ?? 8;
              setState(() {
                _settings =
                    _settings!.copyWith(minimumHoursBetweenShifts: value);
              });
            },
          ),

          const SizedBox(height: 16),

          // Inventory Day
          DropdownButtonFormField<int>(
            initialValue: _settings!.inventoryDay,
            decoration: const InputDecoration(labelText: "Inventory Day"),
            items: const [
              DropdownMenuItem(value: 1, child: Text("Monday")),
              DropdownMenuItem(value: 2, child: Text("Tuesday")),
              DropdownMenuItem(value: 3, child: Text("Wednesday")),
              DropdownMenuItem(value: 4, child: Text("Thursday")),
              DropdownMenuItem(value: 5, child: Text("Friday")),
              DropdownMenuItem(value: 6, child: Text("Saturday")),
              DropdownMenuItem(value: 7, child: Text("Sunday")),
            ],
            onChanged: (v) {
              setState(() {
                _settings = _settings!.copyWith(inventoryDay: v);
              });
            },
          ),

          const SizedBox(height: 16),

          // Schedule Start Day
          DropdownButtonFormField<int>(
            initialValue: _settings!.scheduleStartDay,
            decoration: const InputDecoration(labelText: "Schedule Start Day"),
            items: const [
              DropdownMenuItem(value: 1, child: Text("Monday")),
              DropdownMenuItem(value: 2, child: Text("Tuesday")),
              DropdownMenuItem(value: 3, child: Text("Wednesday")),
              DropdownMenuItem(value: 4, child: Text("Thursday")),
              DropdownMenuItem(value: 5, child: Text("Friday")),
              DropdownMenuItem(value: 6, child: Text("Saturday")),
              DropdownMenuItem(value: 7, child: Text("Sunday")),
            ],
            onChanged: (v) {
              setState(() {
                _settings = _settings!.copyWith(scheduleStartDay: v);
              });
            },
          ),

          const SizedBox(height: 16),

          // Block overlapping vacations toggle
          SwitchListTile(
            title: const Text('Block overlapping vacations'),
            subtitle: const Text('Prevent creating vacations that overlap existing time off'),
            value: _settings!.blockOverlaps,
            onChanged: (v) {
              setState(() {
                _settings = _settings!.copyWith(blockOverlaps: v);
              });
            },
          ),

          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: _save,
            child: const Text("Save Schedule Settings"),
          ),
        ],
      ),
    );
  }
}
