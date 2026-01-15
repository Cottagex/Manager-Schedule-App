import 'package:flutter/material.dart';
import '../../models/job_code_settings.dart';
import '../../database/job_code_settings_dao.dart';

class JobCodeEditor extends StatefulWidget {
  final JobCodeSettings settings;

  const JobCodeEditor({super.key, required this.settings});

  @override
  State<JobCodeEditor> createState() => _JobCodeEditorState();
}

class _JobCodeEditorState extends State<JobCodeEditor> {
  late JobCodeSettings _settings;
  final JobCodeSettingsDao _dao = JobCodeSettingsDao();

  late TextEditingController _hoursController;
  late TextEditingController _vacDaysController;
  late TextEditingController _codeController;
  bool _editingCode = false;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;

    _hoursController = TextEditingController(
      text: _settings.defaultScheduledHours.toString(),
    );
    _vacDaysController = TextEditingController(
      text: _settings.defaultVacationDays.toString(),
    );
    _codeController = TextEditingController(text: _settings.code);
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _vacDaysController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Color _colorFromHex(String hex) {
    String clean = hex.replaceAll('#', '');
    if (clean.length == 6) clean = 'FF$clean';
    return Color(int.parse(clean, radix: 16));
  }

  Future<void> _pickColor() async {
    final colors = [
      '#4285F4', // Blue
      '#DB4437', // Red
      '#8E24AA', // Purple
      '#009688', // Teal
      '#F4B400', // Amber
      '#5E35B1', // Deep Purple
      '#039BE5', // Light Blue
      '#43A047', // Green
      '#F4511E', // Orange
    ];

    final selected = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Select Color"),
          content: SizedBox(
            width: 300,
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: colors.map((hex) {
                return GestureDetector(
                  onTap: () => Navigator.pop(context, hex),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _colorFromHex(hex),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black12),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );

    if (selected != null) {
      setState(() {
        _settings = _settings.copyWith(colorHex: selected);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _editingCode
                      ? TextField(
                          controller: _codeController,
                          decoration: const InputDecoration(labelText: 'Code'),
                        )
                      : Text(
                          _settings.code,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: Icon(_editingCode ? Icons.check : Icons.edit),
                  onPressed: () {
                    setState(() {
                      if (_editingCode) {
                        // Commit editing into local settings object (but don't save DB yet)
                        final newCode = _codeController.text.trim();
                        if (newCode.isNotEmpty) {
                          _settings = JobCodeSettings(
                            code: newCode,
                            hasPTO: _settings.hasPTO,
                            defaultScheduledHours: _settings.defaultScheduledHours,
                            defaultVacationDays: _settings.defaultVacationDays,
                            colorHex: _settings.colorHex,
                          );
                        }
                      }
                      _editingCode = !_editingCode;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // PTO Switch
            SwitchListTile(
              title: const Text("PTO Eligible"),
              value: _settings.hasPTO,
              onChanged: (v) {
                setState(() {
                  _settings = _settings.copyWith(hasPTO: v);
                });
              },
            ),

            // Default Scheduled Hours
            TextField(
              decoration: const InputDecoration(labelText: "Default Scheduled Hours"),
              keyboardType: TextInputType.number,
              controller: _hoursController,
              onChanged: (v) {
                setState(() {
                  _settings = _settings.copyWith(
                    defaultScheduledHours: int.tryParse(v) ?? 0,
                  );
                });
              },
            ),

            // Default Vacation Days
            TextField(
              decoration: const InputDecoration(labelText: "Default Vacation Days"),
              keyboardType: TextInputType.number,
              controller: _vacDaysController,
              onChanged: (v) {
                setState(() {
                  _settings = _settings.copyWith(
                    defaultVacationDays: int.tryParse(v) ?? 0,
                  );
                });
              },
            ),

            const SizedBox(height: 20),

            // Color Picker
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _colorFromHex(_settings.colorHex),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black26),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: _pickColor,
                  child: const Text("Change Color"),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Save Button
            ElevatedButton(
              onPressed: () async {
                final oldCode = widget.settings.code;
                final newCode = _settings.code.trim();

                // Build the final settings record to store
                final finalSettings = JobCodeSettings(
                  code: newCode,
                  hasPTO: _settings.hasPTO,
                  defaultScheduledHours: _settings.defaultScheduledHours,
                  defaultVacationDays: _settings.defaultVacationDays,
                  colorHex: _settings.colorHex,
                );

                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);

                int updated = 0;
                if (newCode != oldCode) {
                  updated = await _dao.renameCode(oldCode, finalSettings);
                } else {
                  await _dao.upsert(finalSettings);
                }

                if (!mounted) return;
                if (updated == -1) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('A job code with that name already exists')),
                  );
                  return;
                }

                // Provide feedback to the user about how many employee assignments were updated
                String message = 'Saved.';
                if (updated > 0) {
                  message = 'Saved. Updated $updated employee(s) to the new job code.';
                }
                messenger.showSnackBar(SnackBar(content: Text(message)));

                navigator.pop();
              },
              child: const Text("Save"),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
