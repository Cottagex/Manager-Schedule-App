import 'package:flutter/material.dart';
import '../database/employee_dao.dart';
import '../database/settings_dao.dart';
import '../database/pto_history_dao.dart';
import '../database/time_off_dao.dart';
import '../models/employee.dart';
import '../models/settings.dart';
import '../models/time_off_entry.dart';

class TrimesterSummary {
  final String label;
  final DateTime start;
  final DateTime end;

  final int earned;        // typically 30
  final int carryoverIn;   // from previous trimester
  final int available;     // earned + carryoverIn, capped at 40
  final int used;          // PTO used in this trimester (hours)
  final int remaining;     // available - used
  final int carryoverOut;  // min(remaining, maxCarryover)

  TrimesterSummary({
    required this.label,
    required this.start,
    required this.end,
    required this.earned,
    required this.carryoverIn,
    required this.available,
    required this.used,
    required this.remaining,
    required this.carryoverOut,
  });
}

class PtoVacTrackerPage extends StatefulWidget {
  const PtoVacTrackerPage({super.key});

  @override
  State<PtoVacTrackerPage> createState() => _PtoVacTrackerPageState();
}

class _PtoVacTrackerPageState extends State<PtoVacTrackerPage> {
  final EmployeeDao _employeeDao = EmployeeDao();
  final SettingsDao _settingsDao = SettingsDao();
  final PtoHistoryDao _ptoHistoryDao = PtoHistoryDao();
  final TimeOffDao _timeOffDao = TimeOffDao();

  List<Employee> _employees = [];
  Settings? _settings;
  List<TimeOffEntry> _allEntries = [];
  int _selectedTrimesterYear = DateTime.now().year;
  int? _selectedEmployeeId;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadAll();
  }

  Future<void> _loadAll() async {
    try {
      final employees = await _employeeDao.getEmployees();
      final settings = await _settingsDao.getSettings();
      final entries = await _timeOffDao.getAllTimeOff();

      setState(() {
        _employees = employees;
        _settings = settings;

        // All entries (model enforces non-nullable fields)
        _allEntries = entries;

        // Default selected employee to first in list (if any)
        _selectedEmployeeId = employees.isNotEmpty ? employees.first.id : null;
      });
    } catch (e) {
      debugPrint("Tracker load error: $e");
      setState(() {
        _employees = [];
        _settings = null;
        _allEntries = [];
      });
    }
  }

  // ---------------------------------------------------------------------------
  // TRIMESTER LOGIC
  // ---------------------------------------------------------------------------

  DateTime _trimesterStart(DateTime date) {
    final y = date.year;
    final m = date.month;

    if (m >= 1 && m <= 4) return DateTime(y, 1, 1);
    if (m >= 5 && m <= 8) return DateTime(y, 5, 1);
    return DateTime(y, 9, 1);
  }

  List<Map<String, dynamic>> _getTrimesterRanges(int year) {
    return [
      {
        "label": "Trimester 1",
        "start": DateTime(year, 1, 1),
        "end": DateTime(year, 4, 30),
      },
      {
        "label": "Trimester 2",
        "start": DateTime(year, 5, 1),
        "end": DateTime(year, 8, 31),
      },
      {
        "label": "Trimester 3",
        "start": DateTime(year, 9, 1),
        "end": DateTime(year, 12, 31),
      },
    ];
  }

  // ---------------------------------------------------------------------------
  // PTO CALCULATION (SUMMARY CARD, CRASH-PROOF)
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> _calculatePto(Employee e) async {
    try {
      if (_settings == null) {
        return {
          'allowance': 0,
          'carryover': 0,
          'used': 0,
          'remaining': 0,
        };
      }

      final settings = _settings!;
      final now = DateTime.now();
      final trimesterStart = _trimesterStart(now);

      final history = await _ptoHistoryDao.ensureHistoryRecord(
        employeeId: e.id ?? 0,
        trimesterStart: trimesterStart,
      );

      // PTO entries using new schema
      final ptoCount = _allEntries.where((entry) {
        if (entry.employeeId != e.id) return false;
        if (entry.timeOffType != "pto") return false;
        return _trimesterStart(entry.date) == trimesterStart;
      }).length;

      final usedHours = ptoCount * settings.ptoHoursPerRequest;

      final isFirstTrimester =
          trimesterStart.month == 1 && trimesterStart.day == 1;

      int carryover;
      if (isFirstTrimester) {
        carryover = 0;
      } else {
        final unused =
            (settings.ptoHoursPerTrimester + history.carryoverHours) -
                usedHours;

        carryover = unused > 0
            ? unused.clamp(0, settings.maxCarryoverHours)
            : 0;
      }

      final remaining =
          (settings.ptoHoursPerTrimester + carryover) - usedHours;

      return {
        'allowance': settings.ptoHoursPerTrimester,
        'carryover': carryover,
        'used': usedHours,
        'remaining': remaining,
      };
    } catch (e) {
      debugPrint("PTO calc error: $e");
      return {
        'allowance': 0,
        'carryover': 0,
        'used': 0,
        'remaining': 0,
      };
    }
  }

  // ---------------------------------------------------------------------------
  // PTO TRIMESTER BREAKDOWN (30 / 40 / 10 LOGIC)
  // ---------------------------------------------------------------------------

  List<TrimesterSummary> _calculateTrimesterSummaries(Employee e, {int? year}) {
    final settings = _settings;
    if (settings == null || e.id == null) {
      return [];
    }

    final int earnedPerTrimester = settings.ptoHoursPerTrimester; // should be 30
    const int maxCap = 40; // hard cap per your rule
    final int maxCarryover = settings.maxCarryoverHours; // should be 10

    final yr = year ?? DateTime.now().year;
    final trimesters = _getTrimesterRanges(yr);

    int carryover = 0;
    final List<TrimesterSummary> summaries = [];

    for (final t in trimesters) {
      final label = t['label'] as String;
      final start = t['start'] as DateTime;
      final end = t['end'] as DateTime;

      // Count PTO entries in this trimester
      final ptoCount = _allEntries.where((entry) {
        if (entry.employeeId != e.id) return false;
        if (entry.timeOffType != "pto") return false;
        final d = entry.date;
        return !d.isBefore(start) && !d.isAfter(end);
      }).length;

      final usedHours = ptoCount * settings.ptoHoursPerRequest;

      // Available = earned + carryover, capped at 40
      int available = earnedPerTrimester + carryover;
      if (available > maxCap) available = maxCap;

      final remaining = available - usedHours;

      int carryoverOut = 0;
      if (remaining > 0) {
        carryoverOut = remaining;
        if (carryoverOut > maxCarryover) {
          carryoverOut = maxCarryover;
        }
      }

      summaries.add(
        TrimesterSummary(
          label: label,
          start: start,
          end: end,
          earned: earnedPerTrimester,
          carryoverIn: carryover,
          available: available,
          used: usedHours,
          remaining: remaining,
          carryoverOut: carryoverOut,
        ),
      );

      carryover = carryoverOut;
    }

    return summaries;
  }

  // ---------------------------------------------------------------------------
  // VACATION WEEKS (CRASH-PROOF)
  // ---------------------------------------------------------------------------

  int _vacationWeeksUsed(Employee e) {
    try {
      final Set<String> groups = {};
      for (final entry in _allEntries) {
        if (entry.employeeId != e.id) continue;
        if (entry.timeOffType != "vac") continue;
        final gid = entry.vacationGroupId;
        if (gid == null || gid.isEmpty) continue;
        groups.add(gid);
      }

      return groups.length;
    } catch (e) {
      debugPrint("Vacation calc error: $e");
      return 0;
    }
  }

  int _vacationWeeksAllowed(Employee e) {
    try {
      return e.vacationWeeksAllowed;
    } catch (e) {
      debugPrint("Vacation allowed calc error: $e");
      return 0;
    }
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_settings == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("PTO / VAC Tracker"),
      ),
      body: RefreshIndicator(
        onRefresh: _loadAll,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildPtoSummaryTable(),
              const SizedBox(height: 24),
              _buildPtoTrimesterBreakdownSection(),
              const SizedBox(height: 32),
              _buildVacationSection(),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PTO SUMMARY TABLE (TOP)
  // ---------------------------------------------------------------------------

  Widget _buildPtoSummaryTable() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadAllPtoSummaries(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final rows = snapshot.data!;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "PTO summary",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text("Employee")),
                      DataColumn(label: Text("Allowance")),
                      DataColumn(label: Text("Carryover")),
                      DataColumn(label: Text("Used")),
                      DataColumn(label: Text("Remaining")),
                    ],
                    rows: rows.map((row) {
                      return DataRow(
                        cells: [
                          DataCell(Text(row['name'] ?? '')),
                          DataCell(Text("${row['allowance']}h")),
                          DataCell(Text("${row['carryover']}h")),
                          DataCell(Text("${row['used']}h")),
                          DataCell(Text("${row['remaining']}h")),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _loadAllPtoSummaries() async {
    try {
      List<Map<String, dynamic>> list = [];

      for (final e in _employees) {
        if (e.id == null) continue;

        final pto = await _calculatePto(e);

        list.add({
          'name': e.name,
          'allowance': pto['allowance'] ?? 0,
          'carryover': pto['carryover'] ?? 0,
          'used': pto['used'] ?? 0,
          'remaining': pto['remaining'] ?? 0,
        });
      }

      return list;
    } catch (e) {
      debugPrint("PTO summary load error: $e");
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // PTO TRIMESTER BREAKDOWN SECTION
  // ---------------------------------------------------------------------------

  Widget _buildPtoTrimesterBreakdownSection() {
    if (_employees.isEmpty || _settings == null) {
      return const SizedBox.shrink();
    }

    final currentYear = DateTime.now().year;
    final previousYear = currentYear - 1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "PTO History",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                DropdownButton<int>(
                  value: _selectedTrimesterYear,
                  items: [previousYear, currentYear]
                      .map((y) => DropdownMenuItem<int>(
                            value: y,
                            child: Text(y.toString()),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _selectedTrimesterYear = v);
                  },
                ),
              ],
            ),
            const Divider(),

            // Employee selector dropdown (single employee view)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButton<int?>(
                      value: _selectedEmployeeId,
                      hint: const Text('Select employee'),
                      isExpanded: true,
                      items: _employees
                          .where((ev) => ev.id != null)
                          .map((ev) => DropdownMenuItem<int?>(
                                value: ev.id,
                                child: Text(ev.name),
                              ))
                          .toList(),
                      onChanged: (v) {
                        setState(() => _selectedEmployeeId = v);
                      },
                    ),
                  ),
                ],
              ),
            ),

            Builder(
              builder: (_) {
                final selected = _employees.firstWhere((ev) => ev.id == _selectedEmployeeId, orElse: () => _employees.first);
                final summaries = _calculateTrimesterSummaries(selected, year: _selectedTrimesterYear);
                if (summaries.isEmpty) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [


                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 640),
                          child: DefaultTabController(
                            length: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                TabBar(
                                  labelColor: Theme.of(context).colorScheme.primary,
                                  unselectedLabelColor: Colors.grey,
                                  tabs: const [
                                    Tab(text: 'T1'),
                                    Tab(text: 'T2'),
                                    Tab(text: 'T3'),
                                  ],
                                ),
                                SizedBox(
                                  height: 140,
                                  child: TabBarView(
                                    children: [
                                      for (final t in summaries)
                                        SingleChildScrollView(
                                          child: Padding(
                                            padding: const EdgeInsets.only(top: 12, left: 8, right: 8),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                Text(
                                                  "${_formatDate(t.start)} – ${_formatDate(t.end)}",
                                                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                                                ),
                                                const SizedBox(height: 8),
                                                Text("Earned: ${t.earned} hrs"),
                                                Text("Carryover In: ${t.carryoverIn} hrs"),
                                                Text("Available: ${t.available} hrs"),
                                                Text("Used: ${t.used} hrs"),
                                                Text("Remaining: ${t.remaining} hrs"),
                                                Text("Carryover Out: ${t.carryoverOut} hrs"),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    return "${d.month}/${d.day}/${d.year}";
  }

  // ---------------------------------------------------------------------------
  // VACATION SECTION
  // ---------------------------------------------------------------------------

  Widget _buildVacationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Vacation Tracking",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            ..._employees.map((e) => _buildVacationRow(e)),
          ],
        ),
      ),
    );
  }

  Widget _buildVacationRow(Employee e) {
    final used = _vacationWeeksUsed(e);
    final allowed = _vacationWeeksAllowed(e);
    final remaining = allowed - used;

    return ListTile(
      title: Text(e.name),
      subtitle: Text("Used: $used / $allowed weeks"),
      trailing: Text(
        "Remaining: $remaining",
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}
