import 'package:contribution_heatmap/contribution_heatmap.dart';
import 'package:contribution_heatmap/src/rendering/render_contribution_heatmap.dart';
import 'package:contribution_heatmap/src/utils/heatmap_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ContributionHeatmap', () {
    testWidgets('renders correctly with default values', (tester) async {
      final entries = [
        ContributionEntry(DateTime(2025, 12, 1), 5),
        ContributionEntry(DateTime(2025, 12, 2), 3),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContributionHeatmap(entries: entries),
          ),
        ),
      );

      final finder = find.byType(ContributionHeatmap);
      expect(finder, findsOneWidget);

      final renderObject =
          tester.renderObject<RenderContributionHeatmap>(finder);
      expect(renderObject.entries, entries);
      expect(renderObject.cellSize, 12);
      expect(renderObject.cellSpacing, 3);
      expect(renderObject.cellRadius, 2);
      expect(renderObject.showMonthLabels, isTrue);
      expect(renderObject.weekdayLabel, WeekdayLabel.full);
      expect(renderObject.heatmapColor, HeatmapColor.green);
    });

    testWidgets('updates render object when properties change', (tester) async {
      final entries1 = [ContributionEntry(DateTime(2025, 12, 1), 7)];
      final entries2 = [ContributionEntry(DateTime(2025, 12, 1), 10)];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContributionHeatmap(
              entries: entries1,
              cellSize: 10,
              heatmapColor: HeatmapColor.green,
            ),
          ),
        ),
      );

      var renderObject = tester.renderObject<RenderContributionHeatmap>(
        find.byType(ContributionHeatmap),
      );
      expect(renderObject.entries, entries1);
      expect(renderObject.cellSize, 10);
      expect(renderObject.heatmapColor, HeatmapColor.green);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContributionHeatmap(
              entries: entries2,
              cellSize: 15,
              heatmapColor: HeatmapColor.blue,
            ),
          ),
        ),
      );

      renderObject = tester.renderObject<RenderContributionHeatmap>(
        find.byType(ContributionHeatmap),
      );
      expect(renderObject.entries, entries2);
      expect(renderObject.cellSize, 15);
      expect(renderObject.heatmapColor, HeatmapColor.blue);
    });

    testWidgets('calculates correct dimensions based on layout parameters',
        (tester) async {
      final entries = [
        ContributionEntry(DateTime(2025, 12, 1), 1), // Monday
      ];
      // 2025-12-01 is Monday.
      // If startWeekday is Monday (default):
      // Week of 2025-12-01 starts Monday Dec 1, 2025.
      // So at least 1 column.

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ContributionHeatmap(
                entries: entries,
                minDate: DateTime(2025, 12, 1),
                maxDate: DateTime(2025, 12, 7), // 1 week
                cellSize: 10,
                cellSpacing: 0,
                padding: EdgeInsets.zero,
                showMonthLabels: false,
                weekdayLabel: WeekdayLabel.none,
                startWeekday: DateTime.monday,
              ),
            ),
          ),
        ),
      );

      final renderObject =
          tester.renderObject(find.byType(ContributionHeatmap)) as RenderBox;

      // 1 week = 1 column (usually, depending on alignment).
      // 2025-12-01 (Mon) to 2025-12-07 (Sun).
      // If start Monday:
      // Col 1: Dec 1 - Dec 7. (Contains both)
      // So likely 1 column.

      // Let's rely on the size calculation logic:
      // Grid height = 7 * size + 6 * spacing
      // Grid width = cols * size + (cols-1) * spacing

      // Here spacing=0. Height = 70.
      expect(renderObject.size.height, 70);
    });

    testWidgets('handles different weekday label configurations',
        (tester) async {
      final entries = [ContributionEntry(DateTime(2025, 12, 1), 1)];

      // Case 1: WeekdayLabel.none
      await tester.pumpWidget(
        MaterialApp(
          home: ContributionHeatmap(
            entries: entries,
            weekdayLabel: WeekdayLabel.none,
          ),
        ),
      );
      var renderObject = tester.renderObject<RenderContributionHeatmap>(
        find.byType(ContributionHeatmap),
      );
      expect(renderObject.weekdayLabel, WeekdayLabel.none);

      // Case 2: WeekdayLabel.githubLike
      await tester.pumpWidget(
        MaterialApp(
          home: ContributionHeatmap(
            entries: entries,
            weekdayLabel: WeekdayLabel.githubLike,
          ),
        ),
      );
      renderObject = tester.renderObject<RenderContributionHeatmap>(
        find.byType(ContributionHeatmap),
      );
      expect(renderObject.weekdayLabel, WeekdayLabel.githubLike);

      // Case 3: WeekdayLabel.full
      await tester.pumpWidget(
        MaterialApp(
          home: ContributionHeatmap(
            entries: entries,
            weekdayLabel: WeekdayLabel.full,
          ),
        ),
      );
      renderObject = tester.renderObject<RenderContributionHeatmap>(
        find.byType(ContributionHeatmap),
      );
      expect(renderObject.weekdayLabel, WeekdayLabel.full);
    });

    testWidgets('handles splittedMonthView', (tester) async {
      final entries = [
        ContributionEntry(DateTime(2025, 12, 31), 1),
        ContributionEntry(DateTime(2026, 1, 1), 1),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: ContributionHeatmap(
            entries: entries,
            splittedMonthView: true,
          ),
        ),
      );

      final renderObject = tester.renderObject<RenderContributionHeatmap>(
        find.byType(ContributionHeatmap),
      );
      expect(renderObject.splittedMonthView, isTrue);
    });

    testWidgets('handles empty entries with min/max dates', (tester) async {
      final minDate = DateTime(2025, 12, 1);
      final maxDate = DateTime(2025, 12, 31);

      await tester.pumpWidget(
        MaterialApp(
          home: ContributionHeatmap(
            entries: [], // Empty
            minDate: minDate,
            maxDate: maxDate,
          ),
        ),
      );

      final finder = find.byType(ContributionHeatmap);
      expect(finder, findsOneWidget);
    });

    testWidgets('handles interactions (onCellTap)', (tester) async {
      int? tappedValue;
      DateTime? tappedDate;

      // Ensure we have a controlled environment
      // Start Monday. 2025-12-01 is Monday, so it's row 0 (0-indexed).
      // Col depends on alignment.
      // Let's pick a date that is definitely in the first column, first row to be easier.
      // 2025-12-01 is Monday.

      final testDate = DateTime(2025, 12, 1); // Monday

      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: ContributionHeatmap(
              entries: [ContributionEntry(testDate, 42)],
              minDate: testDate,
              maxDate: testDate.add(const Duration(days: 6)),
              cellSize: 20,
              cellSpacing: 0,
              padding: EdgeInsets.zero,
              showMonthLabels: false,
              weekdayLabel: WeekdayLabel.none,
              startWeekday: DateTime.monday,
              onCellTap: (date, value) {
                tappedDate = date;
                tappedValue = value;
              },
            ),
          ),
        ),
      );

      // The widget should be (20*1 = 20) wide and (20*7 = 140) high?
      // Wait,
      // If minDate = Dec 1 (Mon) and maxDate = Dec 7 (Sun). That is exactly 1 week.
      // So 1 column.
      // Row 0 is Monday (Dec 1).
      // So the top-left cell should be Dec 1.

      final topLeft = tester.getTopLeft(find.byType(ContributionHeatmap));

      // Tap slightly inside the top-left cell (cell size 20).
      await tester.tapAt(topLeft + const Offset(10, 10));
      await tester.pump();

      expect(tappedDate, isNotNull);
      // Normalized date check (heatmap normalizes to midnight UTC usually)
      expect(HeatmapUtils.dayKey(tappedDate!), HeatmapUtils.dayKey(testDate));
      expect(tappedValue, 42);
    });

    testWidgets('asserts startWeekday range', (tester) async {
      expect(
        () => ContributionHeatmap(
          entries: [],
          startWeekday: 0,
        ),
        throwsAssertionError,
      );

      expect(
        () => ContributionHeatmap(
          entries: [],
          startWeekday: 8,
        ),
        throwsAssertionError,
      );
    });

    testWidgets('showCellDate renders text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ContributionHeatmap(
            entries: [ContributionEntry(DateTime(2025, 12, 1), 5)],
            showCellDate: true,
            cellSize: 20, // Enough space for text
          ),
        ),
      );

      final renderObject = tester.renderObject<RenderContributionHeatmap>(
        find.byType(ContributionHeatmap),
      );
      expect(renderObject.showCellDate, isTrue);

      // Visual verification is hard, but we can check if it pumps without error
    });
  });
}
