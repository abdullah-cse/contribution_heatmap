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
      expect(weekEnd.difference(HeatmapUtils.alignToWeekStart(wednesday, DateTime.monday)).inDays, 6);
    });

    test('weekdayShortNames rotates correctly', () {
      final namesMon = HeatmapUtils.weekdayShortNames(const Locale('en'), DateTime.monday);
      expect(namesMon.first, 'Mon');
      final namesSun = HeatmapUtils.weekdayShortNames(const Locale('en'), DateTime.sunday);
      expect(namesSun.first, 'Sun');
      expect(namesSun.length, 7);
    });

    test('monthAbbreviation returns correct value', () {
      expect(HeatmapUtils.monthAbbreviation(1), 'Jan');
      expect(HeatmapUtils.monthAbbreviation(12), 'Dec');
    });

    test('isFirstWeekdayOfMonth', () {
      expect(HeatmapUtils.isFirstWeekdayOfMonth(DateTime(2024, 1, 2)), true);
      expect(HeatmapUtils.isFirstWeekdayOfMonth(DateTime(2024, 1, 15)), false);
    });

    test('defaultColorScale returns correct color', () {
      expect(HeatmapUtils.defaultColorScale(0), const Color(0xFFFFE4BC));
      expect(HeatmapUtils.defaultColorScale(1), isA<Color>());
      expect(HeatmapUtils.defaultColorScale(10), isA<Color>());
      expect(HeatmapUtils.defaultColorScale(100), isA<Color>());
    });
  });
}