import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/employee.dart';
import '../widgets/schedule/schedule_view.dart';

class SchedulePdfService {
  /// Generate a PDF for the weekly schedule
  static Future<Uint8List> generateWeeklyPdf({
    required DateTime weekStart,
    required List<Employee> employees,
    required List<ShiftPlaceholder> shifts,
  }) async {
    final pdf = pw.Document();
    
    // Calculate week end
    final weekEnd = weekStart.add(const Duration(days: 6));
    final weekTitle = 'Week of ${_formatDate(weekStart)} - ${_formatDate(weekEnd)}';
    
    // Day names
    final dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    
    // Generate days for the week
    final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter.landscape,
        margin: const pw.EdgeInsets.all(20),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              weekTitle,
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Generated: ${_formatDateTime(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 10),
          ],
        ),
        build: (context) => [
          _buildScheduleTable(employees, days, dayNames, shifts),
        ],
      ),
    );

    return pdf.save();
  }

  /// Generate a PDF for the monthly schedule
  static Future<Uint8List> generateMonthlyPdf({
    required int year,
    required int month,
    required List<Employee> employees,
    required List<ShiftPlaceholder> shifts,
  }) async {
    final pdf = pw.Document();
    
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final monthTitle = '${monthNames[month - 1]} $year Schedule';
    
    // Get first and last day of month
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    
    // Find Sunday before or on first day
    final startDate = firstDay.subtract(Duration(days: firstDay.weekday % 7));
    
    // Build weeks
    final weeks = <List<DateTime>>[];
    var currentDate = startDate;
    while (currentDate.isBefore(lastDay) || currentDate.month == month) {
      final week = List.generate(7, (i) => currentDate.add(Duration(days: i)));
      weeks.add(week);
      currentDate = currentDate.add(const Duration(days: 7));
      if (weeks.length >= 6) break;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter.landscape,
        margin: const pw.EdgeInsets.all(20),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              monthTitle,
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Generated: ${_formatDateTime(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 10),
          ],
        ),
        build: (context) => [
          // Build a compact monthly view
          _buildMonthlyCalendar(employees, weeks, month, shifts),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildScheduleTable(
    List<Employee> employees,
    List<DateTime> days,
    List<String> dayNames,
    List<ShiftPlaceholder> shifts,
  ) {
    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellAlignment: pw.Alignment.center,
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellHeight: 40,
      headers: [
        'Employee',
        ...days.map((d) => '${dayNames[d.weekday % 7]}\n${d.month}/${d.day}'),
      ],
      data: employees.map((emp) {
        return [
          emp.name,
          ...days.map((day) {
            final dayShifts = shifts.where((s) =>
              s.employeeId == emp.id &&
              s.start.year == day.year &&
              s.start.month == day.month &&
              s.start.day == day.day
            ).toList();
            
            if (dayShifts.isEmpty) return '';
            
            return dayShifts.map((s) {
              if (_isLabelOnly(s.text)) {
                return s.text.toUpperCase();
              }
              return '${_formatTime(s.start)}-${_formatTime(s.end)}';
            }).join('\n');
          }),
        ];
      }).toList(),
    );
  }

  static pw.Widget _buildMonthlyCalendar(
    List<Employee> employees,
    List<List<DateTime>> weeks,
    int targetMonth,
    List<ShiftPlaceholder> shifts,
  ) {
    final dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    
    return pw.Column(
      children: [
        // Day headers
        pw.Row(
          children: [
            pw.Container(
              width: 60,
              child: pw.Text('', style: const pw.TextStyle(fontSize: 8)),
            ),
            ...dayNames.map((d) => pw.Expanded(
              child: pw.Container(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                padding: const pw.EdgeInsets.all(4),
                child: pw.Center(
                  child: pw.Text(d, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                ),
              ),
            )),
          ],
        ),
        // Weeks
        ...weeks.map((week) => pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Date column
              pw.Container(
                width: 60,
                padding: const pw.EdgeInsets.all(2),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: week.map((day) => pw.Container(
                    height: 12,
                    child: pw.Text(
                      '${day.month}/${day.day}',
                      style: pw.TextStyle(
                        fontSize: 7,
                        color: day.month != targetMonth ? PdfColors.grey500 : PdfColors.black,
                      ),
                    ),
                  )).toList(),
                ),
              ),
              // Employee data for each day
              ...week.map((day) => pw.Expanded(
                child: pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border(left: pw.BorderSide(color: PdfColors.grey300)),
                    color: day.month != targetMonth ? PdfColors.grey100 : null,
                  ),
                  padding: const pw.EdgeInsets.all(2),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: employees.take(5).map((emp) {
                      final dayShifts = shifts.where((s) =>
                        s.employeeId == emp.id &&
                        s.start.year == day.year &&
                        s.start.month == day.month &&
                        s.start.day == day.day
                      ).toList();
                      
                      String shiftText = '-';
                      if (dayShifts.isNotEmpty) {
                        final s = dayShifts.first;
                        if (_isLabelOnly(s.text)) {
                          shiftText = s.text.toUpperCase();
                        } else {
                          shiftText = '${_formatTimeShort(s.start)}-${_formatTimeShort(s.end)}';
                        }
                      }
                      
                      return pw.Container(
                        height: 12,
                        child: pw.Text(
                          '${emp.name.split(' ').first}: $shiftText',
                          style: const pw.TextStyle(fontSize: 5),
                          maxLines: 1,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              )),
            ],
          ),
        )),
      ],
    );
  }

  static bool _isLabelOnly(String text) {
    final t = text.toLowerCase();
    return t == 'off' || t == 'pto' || t == 'vac' || t == 'req off';
  }

  static String _formatDate(DateTime d) => '${d.month}/${d.day}/${d.year}';
  
  static String _formatDateTime(DateTime d) => 
    '${d.month}/${d.day}/${d.year} ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
  
  static String _formatTime(DateTime d) {
    final hour = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${d.minute.toString().padLeft(2, '0')}$ampm';
  }
  
  static String _formatTimeShort(DateTime d) {
    final hour = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    return '$hour:${d.minute.toString().padLeft(2, '0')}';
  }

  /// Print the schedule directly
  static Future<void> printSchedule(Uint8List pdfBytes, String title) async {
    await Printing.layoutPdf(
      onLayout: (_) => pdfBytes,
      name: title,
    );
  }

  /// Share/save the PDF
  static Future<void> sharePdf(Uint8List pdfBytes, String filename) async {
    await Printing.sharePdf(bytes: pdfBytes, filename: filename);
  }
}
