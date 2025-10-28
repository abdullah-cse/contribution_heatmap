import 'package:flutter/material.dart';
import 'package:contribution_heatmap/contribution_heatmap.dart';

void main() {
  runApp(const HeatmapExampleApp());
}

class HeatmapExampleApp extends StatelessWidget {
  const HeatmapExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const ExampleHomePage(),
    );
  }
}

class ExampleHomePage extends StatelessWidget {
  const ExampleHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Contribution Heatmap Example'),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ContributionHeatmap(
          heatmapColor: HeatmapColor.green,
          startWeekday: DateTime.monday,
          cellRadius: 5,
          minDate: DateTime(2025, 4, 1), // Start date: March 1, 2025
          maxDate: DateTime.now(), // End date: Today
          cellSize: 19,
          splittedMonthView: false, // Visual separation between months
          showCellDate: false, // Show date numbers inside cells
          entries: [
            ContributionEntry(DateTime(2025, 4, 23), 5),
            ContributionEntry(DateTime(2025, 4, 24), 7),
            ContributionEntry(DateTime(2025, 4, 25), 6),
            ContributionEntry(DateTime(2025, 4, 29), 5),
            ContributionEntry(DateTime(2025, 5, 3), 5),
            ContributionEntry(DateTime(2025, 5, 5), 5),
            ContributionEntry(DateTime(2025, 5, 11), 5),
            ContributionEntry(DateTime(2025, 5, 12), 5),
            ContributionEntry(DateTime(2025, 5, 18), 7),
            ContributionEntry(DateTime(2025, 5, 20), 7),
            ContributionEntry(DateTime(2025, 5, 24), 6),
            ContributionEntry(DateTime(2025, 6, 9), 8),
            ContributionEntry(DateTime(2025, 6, 10), 9),
            ContributionEntry(DateTime(2025, 6, 11), 6),
            ContributionEntry(DateTime(2025, 6, 12), 8),
            ContributionEntry(DateTime(2025, 6, 13), 7),
            ContributionEntry(DateTime(2025, 6, 14), 8),
            ContributionEntry(DateTime(2025, 6, 15), 6),
            ContributionEntry(DateTime(2025, 6, 19), 8),
            ContributionEntry(DateTime(2025, 6, 26), 5),
            ContributionEntry(DateTime(2025, 7, 3), 7),
            ContributionEntry(DateTime(2025, 7, 7), 7),
            ContributionEntry(DateTime(2025, 7, 8), 3),
            ContributionEntry(DateTime(2025, 7, 9), 4),
            ContributionEntry(DateTime(2025, 7, 10), 5),
            ContributionEntry(DateTime(2025, 7, 11), 5),
            ContributionEntry(DateTime(2025, 7, 12), 6),
            ContributionEntry(DateTime(2025, 7, 13), 7),
            ContributionEntry(DateTime(2025, 7, 28), 5),
            ContributionEntry(DateTime(2025, 7, 29), 4),
            ContributionEntry(DateTime(2025, 7, 30), 3),
            ContributionEntry(DateTime(2025, 7, 31), 6),
            ContributionEntry(DateTime(2025, 8, 1), 7),
            ContributionEntry(DateTime(2025, 8, 2), 4),
            ContributionEntry(DateTime(2025, 8, 3), 3),
            ContributionEntry(DateTime(2025, 8, 5), 5),
            ContributionEntry(DateTime(2025, 8, 13), 5),
            ContributionEntry(DateTime(2025, 8, 19), 5),
            ContributionEntry(DateTime(2025, 8, 25), 5),
            ContributionEntry(DateTime(2025, 8, 26), 4),
            ContributionEntry(DateTime(2025, 8, 27), 3),
            ContributionEntry(DateTime(2025, 8, 28), 2),
            ContributionEntry(DateTime(2025, 8, 29), 7),
            ContributionEntry(DateTime(2025, 8, 30), 4),
            ContributionEntry(DateTime(2025, 8, 31), 3),
            ContributionEntry(DateTime(2025, 9, 8), 8),
            ContributionEntry(DateTime(2025, 9, 11), 5),

            // You can add more entries...
          ],
          onCellTap: (date, value) {
            print('Tapped: $date with $value contributions');
          },
        ),
      ),
    );
  }
}
