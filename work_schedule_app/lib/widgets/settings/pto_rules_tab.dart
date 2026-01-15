import 'package:flutter/material.dart';
import '../../database/settings_dao.dart';
import '../../models/settings.dart';

class PtoRulesTab extends StatefulWidget {
  const PtoRulesTab({super.key});

  @override
  State<PtoRulesTab> createState() => _PtoRulesTabState();
}

class _PtoRulesTabState extends State<PtoRulesTab> {
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
      const SnackBar(content: Text("PTO settings saved")),
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
          const Text("PTO Rules", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          TextField(
            decoration: const InputDecoration(labelText: "PTO Hours Per Trimester"),
            keyboardType: TextInputType.number,
            controller: TextEditingController(text: _settings!.ptoHoursPerTrimester.toString()),
            onChanged: (v) {
              final value = int.tryParse(v) ?? 0;
              setState(() {
                _settings = _settings!.copyWith(ptoHoursPerTrimester: value);
              });
            },
          ),

          TextField(
            decoration: const InputDecoration(labelText: "PTO Hours Per Request"),
            keyboardType: TextInputType.number,
            controller: TextEditingController(text: _settings!.ptoHoursPerRequest.toString()),
            onChanged: (v) {
              final value = int.tryParse(v) ?? 0;
              setState(() {
                _settings = _settings!.copyWith(ptoHoursPerRequest: value);
              });
            },
          ),

          TextField(
            decoration: const InputDecoration(labelText: "Max Carryover Hours"),
            keyboardType: TextInputType.number,
            controller: TextEditingController(text: _settings!.maxCarryoverHours.toString()),
            onChanged: (v) {
              final value = int.tryParse(v) ?? 0;
              setState(() {
                _settings = _settings!.copyWith(maxCarryoverHours: value);
              });
            },
          ),

          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _save,
            child: const Text("Save PTO Settings"),
          ),
        ],
      ),
    );
  }
}
