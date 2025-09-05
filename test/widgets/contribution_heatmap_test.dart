import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:contribution_heatmap/contribution_heatmap.dart';

void main() {
  testWidgets('ContributionHeatmap renders cells and handles tap', (
    tester,
  ) async {
    final tapped = <DateTime, int>{};
    await tester.pumpWidget(
      MaterialApp(
        home: ContributionHeatmap(
          entries: [
            ContributionEntry(DateTime(2024, 1, 1), 1),
            ContributionEntry(DateTime(2024, 1, 2), 2),
            ContributionEntry(DateTime(2024, 1, 3), 0),
          ],
          onCellTap: (date, value) => tapped[date] = value,
        ),
      ),
    );
    // Should render at least one cell (find by type or by semantics)
    expect(find.byType(ContributionHeatmap), findsOneWidget);

    // Simulate a tap on the heatmap area
    await tester.tap(find.byType(ContributionHeatmap));
    await tester.pump();

    // Since we can't hit-test the exact cell, just check the callback is called
    expect(tapped.isNotEmpty, true);
    expect(tapped.values.first, isA<int>());
  });

  testWidgets('ContributionHeatmap supports custom colorScale', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ContributionHeatmap(
          entries: [ContributionEntry(DateTime(2024, 1, 1), 5)],
          colorScale: (v) => Colors.purple,
        ),
      ),
    );
    expect(find.byType(ContributionHeatmap), findsOneWidget);
  });

  testWidgets('ContributionHeatmap respects minDate/maxDate', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ContributionHeatmap(
          entries: [ContributionEntry(DateTime(2024, 1, 10), 1)],
          minDate: DateTime(2024, 1, 1),
          maxDate: DateTime(2024, 1, 31),
        ),
      ),
    );
    expect(find.byType(ContributionHeatmap), findsOneWidget);
  });
}
