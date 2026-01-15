import 'package:flutter/material.dart';
import '../../../models/trimester_summary.dart';

class TrimesterBreakdown extends StatelessWidget {
  final List<TrimesterSummary> summaries;

  const TrimesterBreakdown({super.key, required this.summaries});

  @override
  Widget build(BuildContext context) {
    if (summaries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "PTO Trimester Breakdown",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...summaries.map((t) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.label,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    "${_formatDate(t.start)} – ${_formatDate(t.end)}",
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text("Earned: ${t.earned} hrs"),
                  Text("Carryover In: ${t.carryoverIn} hrs"),
                  Text("Available: ${t.available} hrs"),
                  Text("Used: ${t.used} hrs"),
                  Text("Remaining: ${t.remaining} hrs"),
                  Text("Carryover Out: ${t.carryoverOut} hrs"),
                  const Divider(height: 24),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    return "${d.month}/${d.day}/${d.year}";
  }
}
