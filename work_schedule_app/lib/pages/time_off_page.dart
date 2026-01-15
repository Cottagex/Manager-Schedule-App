import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../database/employee_dao.dart';
import '../database/time_off_dao.dart';
import '../database/settings_dao.dart';
import '../database/job_code_settings_dao.dart';
import '../models/employee.dart';
import '../models/time_off_entry.dart';
import '../models/settings.dart';
import '../services/pto_trimester_service.dart';

class TimeOffPage extends StatefulWidget {
  const TimeOffPage({super.key});

  @override
  State<TimeOffPage> createState() => _TimeOffPageState();
}

class _TimeOffPageState extends State<TimeOffPage> {
  final EmployeeDao _employeeDao = EmployeeDao();
  final TimeOffDao _timeOffDao = TimeOffDao();
  final SettingsDao _settingsDao = SettingsDao();
  final JobCodeSettingsDao _jobCodeSettingsDao = JobCodeSettingsDao();
  late final PtoTrimesterService _ptoService;

  List<Employee> _employees = [];
  Map<int, Employee> _employeeById = {};
  Settings? _settings;

  DateTime _focusedMonth = DateTime.now();
  List<TimeOffEntry> _monthEntries = [];

  DateTime? _selectedDay;
  bool _detailsVisible = false;

  // jobCode -> Color
  final Map<String, Color> _jobCodeColorCache = {};

  @override
  void initState() {
    super.initState();
    _ptoService = PtoTrimesterService(timeOffDao: _timeOffDao);
    _loadSettingsAndData();
  }

  Future<void> _loadSettingsAndData() async {
    final settings = await _settingsDao.getSettings();
    final employees = await _employeeDao.getEmployees();

    setState(() {
      _settings = settings;
      _employees = employees;
      _employeeById = {for (var e in employees) e.id!: e};
    });

    await _preloadJobCodeColors();
    await _loadMonthEntries();
  }

  Future<void> _preloadJobCodeColors() async {
    for (final e in _employees) {
      final code = e.jobCode;
      if (_jobCodeColorCache.containsKey(code)) continue;

      final hex = await _jobCodeSettingsDao.getColorForJobCode(code);
      _jobCodeColorCache[code] = _colorFromHex(hex);
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadMonthEntries() async {
    final entries = await _timeOffDao.getAllTimeOffForMonth(
      _focusedMonth.year,
      _focusedMonth.month,
    );
    setState(() => _monthEntries = entries);
  }

  Map<int, Employee> get _employeeByIdSafe =>
      _employeeById.isEmpty ? {for (var e in _employees) e.id!: e} : _employeeById;

  List<List<DateTime>> _generateMonth(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final weekday = first.weekday;
    final daysToSubtract = weekday % 7;
    final start = first.subtract(Duration(days: daysToSubtract));
    final last = DateTime(month.year, month.month + 1, 0);

    List<List<DateTime>> weeks = [];
    DateTime current = start;

    while (current.isBefore(last) || current.weekday != DateTime.sunday) {
      List<DateTime> week = [];
      for (int i = 0; i < 7; i++) {
        week.add(current);
        current = current.add(const Duration(days: 1));
      }
      weeks.add(week);
    }
    return weeks;
  }

  int _countForDay(DateTime day) {
    final ids = _monthEntries.where((e) =>
        e.date.year == day.year &&
        e.date.month == day.month &&
        e.date.day == day.day).map((e) => e.employeeId).toSet();
    return ids.length;
  }

  List<TimeOffEntry> _entriesForSelectedDay() {
    if (_selectedDay == null) return [];
    final d = _selectedDay!;
    return _monthEntries.where((e) =>
        e.date.year == d.year &&
        e.date.month == d.month &&
        e.date.day == d.day).toList();
  }

  void _changeMonth(int delta) async {
    setState(() {
      _focusedMonth = DateTime(
        _focusedMonth.year,
        _focusedMonth.month + delta,
        1,
      );
      _selectedDay = null;
      _detailsVisible = false;
    });
    await _loadMonthEntries();
  }

  void _onDayTapped(DateTime day) {
    if (day.month != _focusedMonth.month) return;
    setState(() {
      _selectedDay = day;
      _detailsVisible = true;
    });
  }

  String _monthName(int month) {
    const names = [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December'
    ];
    return names[month - 1];
  }

  Color _colorFromHex(String hex) {
    String clean = hex.replaceAll('#', '');
    if (clean.length == 6) {
      clean = 'FF$clean';
    }
    final value = int.tryParse(clean, radix: 16) ?? 0xFF4285F4;
    return Color(value);
  }

  Color _colorForEntry(TimeOffEntry entry) {
    final emp = _employeeByIdSafe[entry.employeeId];
    final code = emp?.jobCode;
    if (code == null) return Colors.grey;

    final cached = _jobCodeColorCache[code];
    if (cached != null) return cached;

    return Colors.grey;
  }

  String _timeOffLabel(TimeOffEntry e) {
    final emp = _employeeByIdSafe[e.employeeId];
    final name = emp?.name ?? 'Unknown';
    if (e.timeOffType == 'vac') {
      final days = (e.hours / 8).round();
      return '$name – Vacation ${days}d';
    } else if (e.timeOffType == 'sick') {
      final days = (e.hours / 8).round();
      return '$name – Requested ${days}d';
    } else if (e.timeOffType == 'pto') {
      final perDay = _settings?.ptoHoursPerRequest ?? 8;
      final days = (e.hours / perDay).round();
      return '$name – PTO ${days}d';
    } else {
      final type = e.timeOffType.toUpperCase();
      final days = (e.hours / 8).round();
      return '$name – $type ${days}d';
    }
  }

  Future<void> _addTimeOff(DateTime day) async {
    if (_employees.isEmpty) return;

    final employee = await _selectEmployee();
    if (employee == null) return;

    final type = await _selectTimeOffType();
    if (type == null) return;

    if (type == 'vac') {
      final days = await _selectVacationDays();
      if (days == null) return;

      final start = day;
      final end = day.add(Duration(days: days - 1));

      // Check for overlaps and gather conflicting entries
      final conflicts = await _timeOffDao.getTimeOffInRange(employee.id!, start, end);
      if (conflicts.isNotEmpty) {
        if (_settings?.blockOverlaps == true) {
          if (!mounted) return;
          await showDialog<void>(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Overlap Blocked'),
                content: SizedBox(
                  width: 360,
                  height: 160,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: conflicts.map((c) => Text('${c.date.toIso8601String().split('T').first} — ${c.timeOffType.toUpperCase()}')).toList(),
                    ),
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
                ],
              );
            },
          );
          return;
        }

        if (!mounted) return;
        final proceed = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Overlap Detected'),
              content: SizedBox(
                width: 360,
                height: 160,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('This employee already has time off overlapping the selected dates:'),
                      const SizedBox(height: 8),
                      ...conflicts.map((c) => Text('${c.date.toIso8601String().split('T').first} — ${c.timeOffType.toUpperCase()}')),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Proceed')),
              ],
            );
          },
        );
        if (proceed != true) return;
      }

      final groupId = const Uuid().v4();

      for (int i = 0; i < days; i++) {
        final entry = TimeOffEntry(
          id: null,
          employeeId: employee.id!,
          date: day.add(Duration(days: i)),
          timeOffType: 'vac',
          hours: 8, // 1 day = 8 hours
          vacationGroupId: groupId,
        );
        await _timeOffDao.insertTimeOff(entry);
      }
    } else if (type == 'pto') {
      // PTO requests: ask for hours (per-day) via dropdown (linked to settings) and number of days.
      final ptoInput = await _selectPtoHoursAndDays();
      if (ptoInput == null) return;

      final hoursPerDay = ptoInput['hours']!;
      final days = ptoInput['days']!;

      final start = day;
      final end = day.add(Duration(days: days - 1));

      final requestedHours = hoursPerDay * days;

      // Check PTO remaining for the trimester
      final remaining = await _ptoService.getRemainingForDate(employee.id!, start);
      if (requestedHours > remaining) {
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Insufficient PTO'),
              content: Text('This employee has only $remaining hour(s) remaining in the trimester, which is less than the requested $requestedHours hour(s).'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
              ],
            );
          },
        );
        return;
      }

      // Check for overlaps across the full range and show details
      final conflicts = await _timeOffDao.getTimeOffInRange(employee.id!, start, end);
      if (conflicts.isNotEmpty) {
        if (_settings?.blockOverlaps == true) {
          if (!mounted) return;
          await showDialog<void>(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Overlap Blocked'),
                content: SizedBox(
                  width: 360,
                  height: 160,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: conflicts.map((c) => Text('${c.date.toIso8601String().split('T').first} — ${c.timeOffType.toUpperCase()}')).toList(),
                    ),
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
                ],
              );
            },
          );
          return;
        }

        if (!mounted) return;
        final proceed = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Overlap Detected'),
              content: SizedBox(
                width: 360,
                height: 160,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('This employee already has time off overlapping the selected dates:'),
                      const SizedBox(height: 8),
                      ...conflicts.map((c) => Text('${c.date.toIso8601String().split('T').first} — ${c.timeOffType.toUpperCase()}')),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Proceed')),
              ],
            );
          },
        );
        if (proceed != true) return;
      }

      final groupId = const Uuid().v4();
      for (int i = 0; i < days; i++) {
        final entry = TimeOffEntry(
          id: null,
          employeeId: employee.id!,
          date: day.add(Duration(days: i)),
          timeOffType: 'pto',
          hours: hoursPerDay,
          vacationGroupId: groupId,
        );
        await _timeOffDao.insertTimeOff(entry);
      }
    } else if (type == 'sick') {
      // Full-day requested (sick/requested)
      final hours = _settings?.ptoHoursPerRequest ?? 8;

      // Check for overlap (single-day) and show details
      final conflicts = await _timeOffDao.getTimeOffInRange(employee.id!, day, day);
      if (conflicts.isNotEmpty) {
        if (_settings?.blockOverlaps == true) {
          if (!mounted) return;
          await showDialog<void>(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Overlap Blocked'),
                content: SizedBox(
                  width: 360,
                  height: 160,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: conflicts.map((c) => Text('${c.date.toIso8601String().split('T').first} — ${c.timeOffType.toUpperCase()}')).toList(),
                    ),
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
                ],
              );
            },
          );
          return;
        }

        // Ask the user if they'd still like to proceed
        if (!mounted) return;
        final proceed = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Overlap Detected'),
              content: SizedBox(
                width: 360,
                height: 160,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('This employee already has time off on this date:'),
                      const SizedBox(height: 8),
                      ...conflicts.map((c) => Text('${c.date.toIso8601String().split('T').first} — ${c.timeOffType.toUpperCase()}')),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Proceed')),
              ],
            );
          },
        );
        if (proceed != true) return;
      }

      final entry = TimeOffEntry(
        id: null,
        employeeId: employee.id!,
        date: day,
        timeOffType: type,
        hours: hours,
        vacationGroupId: null,
      );

      await _timeOffDao.insertTimeOff(entry);
    } else {
      final h = await _selectHours();
      if (h == null) return;

      final entry = TimeOffEntry(
        id: null,
        employeeId: employee.id!,
        date: day,
        timeOffType: type,
        hours: h,
        vacationGroupId: null,
      );

      await _timeOffDao.insertTimeOff(entry);
    }

    await _loadMonthEntries();
  }

  Future<Employee?> _selectEmployee() async {
    if (!mounted) return null;
    return showDialog<Employee>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Employee'),
          content: SizedBox(
            width: 300,
            height: 300,
            child: ListView(
              children: _employees.map((e) {
                return ListTile(
                  title: Text(e.name),
                  onTap: () => Navigator.of(context).pop(e),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Future<String?> _selectTimeOffType() async {
    if (!mounted) return null;
    return showDialog<String>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Select Time Off Type'),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'pto'),
              child: const Text('PTO'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'vac'),
              child: const Text('Vacation'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'sick'),
              child: const Text('Requested'),
            ),
          ],
        );
      },
    );
  }

  Future<int?> _selectHours() async {
    final controller = TextEditingController(text: '8');
    if (!mounted) return null;
    return showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hours'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Hours',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final h = int.tryParse(controller.text);
                Navigator.pop(context, h);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<int?> _selectVacationDays() async {
    final controller = TextEditingController(text: '1');
    if (!mounted) return null;
    return showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Days'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Days',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final d = int.tryParse(controller.text);
                Navigator.pop(context, d);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  /// Shows a dialog that collects the PTO hours-per-day (via text input)
  /// and number of days for the request. The returned map contains keys
  /// 'hours' and 'days'. Returns null if canceled.
  Future<Map<String,int>?> _selectPtoHoursAndDays() async {
    final daysController = TextEditingController(text: '1');
    final hoursController = TextEditingController(text: (_settings?.ptoHoursPerRequest ?? 8).toString());

    if (!mounted) return null;
    final result = await showDialog<Map<String,int>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('PTO Request'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: hoursController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Hours per day'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: daysController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Days'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(onPressed: () {
              final h = int.tryParse(hoursController.text) ?? (_settings?.ptoHoursPerRequest ?? 8);
              final d = int.tryParse(daysController.text) ?? 1;
              Navigator.pop(context, {'hours': h, 'days': d});
            }, child: const Text('OK')),
          ],
        );
      },
    );

    return result;
  }

  Future<void> _deleteEntry(TimeOffEntry entry) async {
    if (entry.id == null) return;
    if (entry.vacationGroupId != null) {
      // Deleting any entry that is part of a vacation group deletes the whole group
      await _deleteVacationGroup(entry.vacationGroupId!);
      return;
    }

    await _timeOffDao.deleteTimeOff(entry.id!);
    await _loadMonthEntries();
  }

  Future<void> _deleteVacationGroup(String groupId) async {
    // Confirm deletion and show details
    final entries = await _timeOffDao.getEntriesByGroup(groupId);
    if (entries.isEmpty) return;

    final employeeId = entries.first.employeeId;
    final employeeName = _employeeByIdSafe[employeeId]?.name ?? 'Employee';
    final count = entries.length;

    final type = entries.first.timeOffType;
    final typeLabel = type == 'vac' ? 'vacation' : type == 'pto' ? 'PTO' : 'requested';

    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Group'),
          content: Text('Delete $typeLabel for $employeeName covering $count day(s)? This will remove all days in the group.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
          ],
        );
      },
    );

    // Re-check mounted after awaiting the dialog to avoid operating on an unmounted
    // widget (linter: use_build_context_synchronously).
    if (!mounted) return;

    if (confirm == true) {
      await _timeOffDao.deleteVacationGroup(groupId);
      if (!mounted) return;
      await _loadMonthEntries();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_settings == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final weeks = _generateMonth(_focusedMonth);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Time Off"),
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              await _loadSettingsAndData();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLegend(),
                  const SizedBox(height: 16),
                  _buildMonthHeader(),
                  const SizedBox(height: 8),
                  _buildWeekdayHeader(),
                  const SizedBox(height: 8),
                  _buildCalendarGrid(weeks),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Dim overlay when the details panel is visible. Tapping dismisses it.
          if (_detailsVisible && _selectedDay != null && _entriesForSelectedDay().isNotEmpty)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() {
                  _detailsVisible = false;
                  _selectedDay = null;
                }),
                child: Container(
                  color: const Color.fromRGBO(0, 0, 0, 0.35),
                ),
              ),
            ),

          // Sliding right-hand details panel
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            right: (_detailsVisible && _selectedDay != null && _entriesForSelectedDay().isNotEmpty) ? 0 : -360,
            top: 0,
            bottom: 0,
            width: 360,
            child: Material(
              elevation: 12,
              color: Theme.of(context).cardColor,
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedDay == null ? '' : "${_monthName(_selectedDay!.month)} ${_selectedDay!.day}, ${_selectedDay!.year}",
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(() {
                              _detailsVisible = false;
                              _selectedDay = null;
                            }),
                          ),
                        ],
                      ),
                      const Divider(),
                      _buildDayDetails(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _selectedDay != null
          ? FloatingActionButton(
              onPressed: () => _addTimeOff(_selectedDay!),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildLegend() {
    final entries = <Widget>[];

    void addLegendItem(String label, String codeKey) {
      final color = _jobCodeColorCache[codeKey] ?? Colors.grey;
      entries.add(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 14,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          Text(label),
          const SizedBox(width: 16),
        ],
      ));
    }

    addLegendItem('Assistant', 'assistant');
    addLegendItem('Swing', 'swing');
    addLegendItem('GM', 'gm');
    addLegendItem('MIT', 'mit');
    addLegendItem('Breakfast Mgr', 'breakfast mgr');

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: entries,
    );
  }

  Widget _buildMonthHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: () => _changeMonth(-1),
          icon: const Icon(Icons.chevron_left),
        ),
        Text(
          "${_monthName(_focusedMonth.month)} ${_focusedMonth.year}",
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          onPressed: () => _changeMonth(1),
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  Widget _buildWeekdayHeader() {
    const labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final labelStyle = TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: labels
          .map(
            (d) => Expanded(
              child: Center(
                child: Text(
                  d,
                  style: labelStyle,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildCalendarGrid(List<List<DateTime>> weeks) {
    return Column(
      children: weeks.map((week) {
        return Row(
          children: week.map((day) {
            final isCurrentMonth = day.month == _focusedMonth.month;
            final isToday = DateTime.now().year == day.year &&
                DateTime.now().month == day.month &&
                DateTime.now().day == day.day;
            final isSelected = _selectedDay != null &&
                _selectedDay!.year == day.year &&
                _selectedDay!.month == day.month &&
                _selectedDay!.day == day.day;

            final count = _countForDay(day);

            return Expanded(
              child: GestureDetector(
                onTap: () => _onDayTapped(day),
                onDoubleTap: () {
                  if (day.month != _focusedMonth.month) return;
                  _addTimeOff(day);
                },
                child: Container(
                  margin: const EdgeInsets.all(2),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.blue.shade100
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: isToday
                        ? Border.all(color: Colors.blue, width: 1.5)
                        : null,
                  ),
                  child: Column(
                    children: [
                      Text(
                        "${day.day}",
                        style: TextStyle(
                          color: isCurrentMonth
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).disabledColor,
                          fontWeight:
                              count > 0 ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      if (count > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            "$count",
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.redAccent,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  Widget _buildDayDetails() {
    final entries = _entriesForSelectedDay();
    if (entries.isEmpty || _selectedDay == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: entries.map((e) {
            final color = _colorForEntry(e);
            final label = _timeOffLabel(e);

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: color,
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              title: Text(label),
              subtitle: Text(
                "Group: ${e.vacationGroupId ?? 'N/A'}",
                style: const TextStyle(fontSize: 12),
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'delete') {
                    await _deleteEntry(e);
                  } else if (value == 'delete_group' &&
                      e.vacationGroupId != null) {
                    await _deleteVacationGroup(e.vacationGroupId!);
                  }
                },
                itemBuilder: (context) {
                  return <PopupMenuEntry<String>>[
                    if (e.vacationGroupId == null)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete Entry'),
                      ),
                    if (e.vacationGroupId != null)
                      PopupMenuItem(
                        value: 'delete_group',
                        child: Text('Delete Group (entire ${e.timeOffType.toUpperCase()})'),
                      ),
                  ];
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
