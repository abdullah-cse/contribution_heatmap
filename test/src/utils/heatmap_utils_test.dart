import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:contribution_heatmap/src/utils/heatmap_utils.dart';

void main() {
  group('HeatmapUtils', () {
    test('dayKey normalizes to midnight', () {
      final dt = DateTime(2024, 1, 15, 14, 30);
      final key = HeatmapUtils.dayKey(dt);
      expect(key.hour, 0);
      expect(key.minute, 0);
      expect(key.year, 2024);
      expect(key.month, 1);
      expect(key.day, 15);
    });

    test('alignToWeekStart works for Monday', () {
      final wednesday = DateTime(2024, 1, 17); // Wednesday
      final monday = HeatmapUtils.alignToWeekStart(wednesday, DateTime.monday);
      expect(monday.weekday, DateTime.monday);
      expect(monday.day, lessThanOrEqualTo(wednesday.day));
    });

    test('alignToWeekEnd works for Monday', () {
      final wednesday = DateTime(2024, 1, 17);
      final weekEnd = HeatmapUtils.alignToWeekEnd(wednesday, DateTime.monday);
      expect(
        weekEnd
            .difference(
              HeatmapUtils.alignToWeekStart(wednesday, DateTime.monday),
            )
            .inDays,
        6,
      );
    });

    test('weekdayShortNames rotates correctly', () {
      final namesMon = HeatmapUtils.weekdayShortNames(
        const Locale('en'),
        DateTime.monday,
      );
      expect(namesMon.first, 'Mon');
      final namesSun = HeatmapUtils.weekdayShortNames(
        const Locale('en'),
        DateTime.sunday,
      );
      expect(namesSun.first, 'Sun');
      expect(namesSun.length, 7);
    });

    test('monthAbbreviation returns correct value', () {
      expect(HeatmapUtils.monthAbbreviation(1, Locale('en')), 'Jan');
      expect(HeatmapUtils.monthAbbreviation(12, Locale('en')), 'Dec');
    });

    test('isFirstWeekdayOfMonth', () {
      expect(HeatmapUtils.isFirstWeekdayOfMonth(DateTime(2024, 1, 2)), true);
      expect(HeatmapUtils.isFirstWeekdayOfMonth(DateTime(2024, 1, 15)), false);
    });
    test('githubLikeRows returns correct rows for Monday start', () {
      final rows = HeatmapUtils.githubLikeRows(DateTime.monday);
      // Monday (0), Wednesday (2), Friday (4) when starting on Monday
      expect(rows, containsAll([0, 2, 4]));
      expect(rows.length, 3);
    });

    test('githubLikeRows returns correct rows for Sunday start', () {
      final rows = HeatmapUtils.githubLikeRows(DateTime.sunday);
      // Monday (1), Wednesday (3), Friday (5) when starting on Sunday
      expect(rows, containsAll([1, 3, 5]));
      expect(rows.length, 3);
    });
  });
}
