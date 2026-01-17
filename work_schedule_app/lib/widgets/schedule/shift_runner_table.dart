import 'package:flutter/material.dart';
import '../../database/shift_runner_dao.dart';
import '../../database/shift_runner_color_dao.dart';
import '../../database/employee_dao.dart';
import '../../database/time_off_dao.dart';
import '../../database/employee_availability_dao.dart';
import '../../models/shift_runner.dart';
import '../../models/shift_runner_color.dart';
import '../../models/employee.dart';

class ShiftRunnerTable extends StatefulWidget {
  final DateTime weekStart;
  final VoidCallback? onChanged;

  const ShiftRunnerTable({super.key, required this.weekStart, this.onChanged});

  @override
  State<ShiftRunnerTable> createState() => _ShiftRunnerTableState();
}

class _ShiftRunnerTableState extends State<ShiftRunnerTable> {
  final ShiftRunnerDao _dao = ShiftRunnerDao();
  final ShiftRunnerColorDao _colorDao = ShiftRunnerColorDao();
  final EmployeeDao _employeeDao = EmployeeDao();
  final TimeOffDao _timeOffDao = TimeOffDao();
  final EmployeeAvailabilityDao _availabilityDao = EmployeeAvailabilityDao();

  List<ShiftRunner> _runners = [];
  List<Employee> _employees = [];
  Map<String, String> _colors = {};
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(ShiftRunnerTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weekStart != widget.weekStart) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    final weekEnd = widget.weekStart.add(const Duration(days: 6));
    final runners = await _dao.getForDateRange(widget.weekStart, weekEnd);
    final employees = await _employeeDao.getEmployees();
    final colors = await _colorDao.getColorMap();

    if (mounted) {
      setState(() {
        _runners = runners;
        _employees = employees;
        _colors = colors;
      });
    }
  }

  String? _getRunnerForCell(DateTime day, String shiftType) {
    final runner = _runners.cast<ShiftRunner?>().firstWhere(
      (r) =>
          r != null &&
          r.date.year == day.year &&
          r.date.month == day.month &&
          r.date.day == day.day &&
          r.shiftType == shiftType,
      orElse: () => null,
    );
    return runner?.runnerName;
  }

  Future<void> _editRunner(
    DateTime day,
    String shiftType,
    String? currentName,
  ) async {
    // Get the shift times for availability check
    final shiftInfo = ShiftRunner.shiftTimes[shiftType]!;
    final startTime = shiftInfo['start']!;
    final endTime = shiftInfo['end']!;

    // Load available employees for this shift
    final availableEmployees = await _getAvailableEmployees(
      day,
      startTime,
      endTime,
    );

    if (!mounted) return;

    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) {
        return _ShiftRunnerSearchDialog(
          day: day,
          shiftType: shiftType,
          currentName: currentName,
          availableEmployees: availableEmployees,
          shiftColor: _getShiftColor(shiftType),
        );
      },
    );

    if (result != null) {
      if (result.isEmpty) {
        await _dao.clear(day, shiftType);
      } else {
        await _dao.upsert(
          ShiftRunner(date: day, shiftType: shiftType, runnerName: result),
        );
      }
      await _loadData();
      widget.onChanged?.call();
    }
  }

  Future<List<Employee>> _getAvailableEmployees(
    DateTime day,
    String startTime,
    String endTime,
  ) async {
    final availableList = <Employee>[];
    final timeOffList = await _timeOffDao.getAllTimeOff();
    final dateStr =
        '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

    for (final employee in _employees) {
      // Check time-off
      final hasTimeOff = timeOffList.any(
        (t) =>
            t.employeeId == employee.id &&
            '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}-${t.date.day.toString().padLeft(2, '0')}' ==
                dateStr &&
            t.isAllDay, // Only exclude if it's all-day time off
      );

      if (hasTimeOff) continue;

      // Check availability pattern
      final availability = await _availabilityDao.isAvailable(
        employee.id!,
        day,
        startTime,
        endTime,
      );
      if (availability['available'] == true) {
        availableList.add(employee);
      }
    }

    return availableList;
  }

  @override
  Widget build(BuildContext context) {
    final days = List.generate(
      7,
      (i) => widget.weekStart.add(Duration(days: i)),
    );
    final shiftTypes = ShiftRunner.shiftOrder;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        children: [
          // Header with expand/collapse
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(12),
                  bottom: _isExpanded ? Radius.zero : const Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Shift Runner',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const Spacer(),
                  Text(
                    _isExpanded ? 'Click to collapse' : 'Click to expand',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),

          // Table content
          if (_isExpanded)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Table(
                  defaultColumnWidth: const FixedColumnWidth(80),
                  columnWidths: const {
                    0: FixedColumnWidth(60), // Shift type column
                  },
                  border: TableBorder.all(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                  children: [
                    // Header row with days
                    TableRow(
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withOpacity(0.5),
                      ),
                      children: [
                        _buildHeaderCell(''),
                        ...days.map(
                          (d) => _buildHeaderCell(
                            '${_dayAbbr(d.weekday)}\n${d.month}/${d.day}',
                          ),
                        ),
                      ],
                    ),
                    // Rows for each shift type
                    ...shiftTypes.map((shiftType) {
                      return TableRow(
                        children: [
                          _buildShiftTypeCell(shiftType),
                          ...days.map((day) {
                            final runner = _getRunnerForCell(day, shiftType);
                            return _buildRunnerCell(day, shiftType, runner);
                          }),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    return Container(
      padding: const EdgeInsets.all(6),
      alignment: Alignment.center,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }

  Widget _buildShiftTypeCell(String shiftType) {
    return Container(
      padding: const EdgeInsets.all(6),
      alignment: Alignment.center,
      color: _getShiftColor(shiftType).withOpacity(0.2),
      child: Text(
        ShiftRunner.getLabelForType(shiftType),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 11,
          color: _getShiftColor(shiftType),
        ),
      ),
    );
  }

  Widget _buildRunnerCell(DateTime day, String shiftType, String? runner) {
    final hasRunner = runner != null && runner.isNotEmpty;

    return InkWell(
      onTap: () => _editRunner(day, shiftType, runner),
      child: Container(
        padding: const EdgeInsets.all(4),
        alignment: Alignment.center,
        constraints: const BoxConstraints(minHeight: 36),
        decoration: BoxDecoration(
          color: hasRunner ? _getShiftColor(shiftType).withOpacity(0.1) : null,
        ),
        child: Text(
          runner ?? '',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: hasRunner ? Colors.black87 : Colors.grey,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Color _getShiftColor(String shiftType) {
    final hex =
        _colors[shiftType] ??
        ShiftRunnerColor.defaultColors[shiftType] ??
        '#808080';
    final cleanHex = hex.replaceFirst('#', '');
    return Color(int.parse('FF$cleanHex', radix: 16));
  }

  String _dayAbbr(int weekday) {
    const abbrs = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return abbrs[weekday];
  }
}

class _ShiftRunnerSearchDialog extends StatefulWidget {
  final DateTime day;
  final String shiftType;
  final String? currentName;
  final List<Employee> availableEmployees;
  final Color shiftColor;

  const _ShiftRunnerSearchDialog({
    required this.day,
    required this.shiftType,
    required this.currentName,
    required this.availableEmployees,
    required this.shiftColor,
  });

  @override
  State<_ShiftRunnerSearchDialog> createState() =>
      _ShiftRunnerSearchDialogState();
}

class _ShiftRunnerSearchDialogState extends State<_ShiftRunnerSearchDialog> {
  late TextEditingController _searchController;
  List<Employee> _filteredEmployees = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredEmployees = widget.availableEmployees;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterEmployees(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredEmployees = widget.availableEmployees;
      } else {
        _filteredEmployees = widget.availableEmployees
            .where(
              (emp) => emp.name.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final shiftInfo = ShiftRunner.shiftTimes[widget.shiftType]!;

    return AlertDialog(
      title: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: widget.shiftColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${ShiftRunner.getLabelForType(widget.shiftType)} Runner',
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  '${widget.day.month}/${widget.day.day} • ${shiftInfo['start']} - ${shiftInfo['end']}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search employees...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _filterEmployees('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: _filterEmployees,
            ),
            const SizedBox(height: 12),
            Text(
              'Available Employees (${_filteredEmployees.length})',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            // Employee list
            SizedBox(
              height: 200,
              child: _filteredEmployees.isEmpty
                  ? Center(
                      child: Text(
                        _searchController.text.isEmpty
                            ? 'No available employees for this shift'
                            : 'No matching employees',
                        style: TextStyle(color: Colors.grey[500], fontSize: 13),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredEmployees.length,
                      itemBuilder: (context, index) {
                        final emp = _filteredEmployees[index];
                        final isCurrentRunner = widget.currentName == emp.name;

                        return ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          tileColor: isCurrentRunner
                              ? widget.shiftColor.withOpacity(0.1)
                              : null,
                          leading: CircleAvatar(
                            radius: 14,
                            backgroundColor: widget.shiftColor.withOpacity(0.2),
                            child: Text(
                              emp.name.isNotEmpty
                                  ? emp.name[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: widget.shiftColor,
                              ),
                            ),
                          ),
                          title: Text(
                            emp.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isCurrentRunner
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            emp.jobCode,
                            style: const TextStyle(fontSize: 11),
                          ),
                          trailing: isCurrentRunner
                              ? Icon(
                                  Icons.check_circle,
                                  size: 18,
                                  color: widget.shiftColor,
                                )
                              : null,
                          onTap: () => Navigator.pop(context, emp.name),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        if (widget.currentName != null && widget.currentName!.isNotEmpty)
          TextButton(
            onPressed: () => Navigator.pop(context, ''),
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
      ],
    );
  }
}
