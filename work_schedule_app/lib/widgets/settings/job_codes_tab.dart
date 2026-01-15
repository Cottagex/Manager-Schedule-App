import 'package:flutter/material.dart';
import '../../../database/job_code_settings_dao.dart';
import '../../../models/job_code_settings.dart';
import 'job_code_editor.dart';

class JobCodesTab extends StatefulWidget {
  const JobCodesTab({super.key});

  @override
  State<JobCodesTab> createState() => _JobCodesTabState();
}

class _JobCodesTabState extends State<JobCodesTab> {
  final JobCodeSettingsDao _dao = JobCodeSettingsDao();
  List<JobCodeSettings> _codes = [];

  @override
  void initState() {
    super.initState();
    _loadCodes();
  }

  Future<void> _loadCodes() async {
    final list = await _dao.getAll();
    setState(() => _codes = list);
  }

  Future<void> _addJobCode() async {
    String code = "";

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("New Job Code"),
          content: TextField(
            decoration: const InputDecoration(labelText: "Code Name"),
            onChanged: (v) => code = v,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (code.trim().isEmpty) return;

                final newCode = JobCodeSettings(
                  code: code.trim(),
                  hasPTO: false,
                  defaultScheduledHours: 0,
                  defaultVacationDays: 0,
                  colorHex: '#4285F4',
                );

                await _dao.upsert(newCode);
                if (!mounted) return;
                Navigator.of(this.context).pop();
                await _loadCodes();
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  void _edit(JobCodeSettings settings) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => JobCodeEditor(settings: settings),
    );
    await _loadCodes();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _addJobCode,
          child: const Text("Add Job Code"),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            itemCount: _codes.length,
            itemBuilder: (context, index) {
              final jc = _codes[index];
              return ListTile(
                title: Text(jc.code),
                subtitle: Text(
                  "PTO: ${jc.hasPTO ? 'Yes' : 'No'} • "
                  "Hours: ${jc.defaultScheduledHours} • "
                  "Vacation Days: ${jc.defaultVacationDays}",
                ),
                onTap: () => _edit(jc),
              );
            },
          ),
        ),
      ],
    );
  }
}
