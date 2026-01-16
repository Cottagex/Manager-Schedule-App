import 'package:flutter/material.dart';
import '../../database/shift_template_dao.dart';
import '../../models/shift_template.dart';

class ShiftTemplatesTab extends StatefulWidget {
  const ShiftTemplatesTab({super.key});

  @override
  State<ShiftTemplatesTab> createState() => _ShiftTemplatesTabState();
}

class _ShiftTemplatesTabState extends State<ShiftTemplatesTab> {
  final ShiftTemplateDao _templateDao = ShiftTemplateDao();

  List<ShiftTemplate> _templates = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _templateDao.insertDefaultTemplatesIfMissing();
    final allTemplates = await _templateDao.getAllTemplates();

    setState(() {
      _templates = allTemplates;
    });
  }

  Future<void> _addTemplate() async {
    String name = '';
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Shift Template'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Template Name'),
                onChanged: (v) => name = v,
                autofocus: true,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Start Time'),
                trailing: Text('${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}'),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: startTime,
                  );
                  if (picked != null) {
                    setDialogState(() {
                      startTime = picked;
                    });
                  }
                },
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
                if (name.trim().isEmpty) return;
                
                final template = ShiftTemplate(
                  templateName: name.trim(),
                  startTime: '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
                );
                
                await _templateDao.insertTemplate(template);
                Navigator.pop(context);
                _loadData();
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editTemplate(ShiftTemplate template) async {
    String name = template.templateName;
    final parts = template.startTime.split(':');
    TimeOfDay startTime = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Shift Template'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Template Name'),
                controller: TextEditingController(text: name),
                onChanged: (v) => name = v,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Start Time'),
                trailing: Text('${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}'),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: startTime,
                  );
                  if (picked != null) {
                    setDialogState(() {
                      startTime = picked;
                    });
                  }
                },
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
                if (name.trim().isEmpty) return;
                
                final updated = template.copyWith(
                  templateName: name.trim(),
                  startTime: '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
                );
                
                await _templateDao.updateTemplate(updated);
                Navigator.pop(context);
                _loadData();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteTemplate(ShiftTemplate template) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Template'),
        content: Text('Delete "${template.templateName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && template.id != null) {
      await _templateDao.deleteTemplate(template.id!);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final templates = _templates;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Shift Templates',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create custom shift templates (shared across all job codes). When applied, duration uses the employee\'s job code default daily hours.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton.icon(
              onPressed: _addTemplate,
              icon: const Icon(Icons.add),
              label: const Text('Add Template'),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: templates.isEmpty
                ? const Center(child: Text('No templates yet'))
                : ListView.builder(
                    itemCount: templates.length,
                    itemBuilder: (context, index) {
                      final template = templates[index];

                      return Card(
                        child: ListTile(
                          title: Text(template.templateName),
                          subtitle: Text('Starts at ${template.startTime}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _editTemplate(template),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _deleteTemplate(template),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
