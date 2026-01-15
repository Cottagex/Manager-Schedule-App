import 'package:flutter/material.dart';
import 'schedule_home_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Work Schedule Dashboard"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Select Month",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            DropdownButtonFormField<int>(
              initialValue: selectedMonth,
              decoration: const InputDecoration(
                labelText: "Month",
                border: OutlineInputBorder(),
              ),
              items: List.generate(12, (i) {
                final month = i + 1;
                return DropdownMenuItem(
                  value: month,
                  child: Text(_monthName(month)),
                );
              }),
              onChanged: (value) {
                if (value != null) {
                  setState(() => selectedMonth = value);
                }
              },
            ),

            const SizedBox(height: 20),

            DropdownButtonFormField<int>(
              initialValue: selectedYear,
              decoration: const InputDecoration(
                labelText: "Year",
                border: OutlineInputBorder(),
              ),
              items: List.generate(10, (i) {
                final year = DateTime.now().year - 5 + i;
                return DropdownMenuItem(
                  value: year,
                  child: Text(year.toString()),
                );
              }),
              onChanged: (value) {
                if (value != null) {
                  setState(() => selectedYear = value);
                }
              },
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ScheduleHomePage(
                      year: selectedYear,
                      month: selectedMonth,
                    ),
                  ),
                );
              },
              child: const Padding(
                padding: EdgeInsets.all(12.0),
                child: Text(
                  "Open Schedule",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _monthName(int month) {
    const names = [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December'
    ];
    return names[month - 1];
  }
}
