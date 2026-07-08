import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:contribution_heatmap/contribution_heatmap.dart';

void main() {
  group('ContributionHeatmap Custom Colors', () {
    testWidgets('respects customColor', (WidgetTester tester) async {
      final entries = [ContributionEntry(DateTime(2024, 1, 1), 1)];
      const customColor = Colors.deepPurple;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContributionHeatmap(
              entries: entries,
              customColor: customColor,
            ),
          ),
        ),
      );

      final widget =
          tester.widget<ContributionHeatmap>(find.byType(ContributionHeatmap));
      expect(widget.customColor, equals(customColor));
      expect(widget.heatmapColor, isNull); // Default is null now
    });

    testWidgets('respects customColorScale', (WidgetTester tester) async {
      final entries = [ContributionEntry(DateTime(2024, 1, 1), 1)];
      Color customScale(int value) => Colors.red;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContributionHeatmap(
              entries: entries,
              customColorScale: customScale,
            ),
          ),
        ),
      );

      final widget =
          tester.widget<ContributionHeatmap>(find.byType(ContributionHeatmap));
      expect(widget.customColorScale, equals(customScale));
    });
  });
}
