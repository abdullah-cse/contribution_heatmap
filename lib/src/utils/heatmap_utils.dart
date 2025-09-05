import 'package:flutter/material.dart';

/// Utility functions and extensions for the contribution heatmap.
///
/// This file contains helper methods for date calculations,
/// color scaling, and other utility functions used throughout
/// the heatmap implementation.
class HeatmapUtils {
  /// Normalizes a DateTime to midnight (local time) for consistent map keys.
  ///
  /// This ensures that all dates are compared at the day level,
  /// ignoring time components.
  ///
  /// Example:
  /// ```dart
  /// final normalized = HeatmapUtils.dayKey(DateTime(2024, 1, 15, 14, 30));
  /// // Returns: DateTime(2024, 1, 15, 0, 0, 0)
  /// ```
  static DateTime dayKey(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Aligns a date to the start of its week based on the specified start weekday.
  ///
  /// [date] - The date to align
  /// [startWeekday] - The first day of the week (1=Monday, 7=Sunday)
  ///
  /// Returns the Monday (or specified start day) of the week containing [date].
  ///
  /// Example:
  /// ```dart
  /// final wednesday = DateTime(2024, 1, 17); // Wednesday
  /// final monday = HeatmapUtils.alignToWeekStart(wednesday, DateTime.monday);
  /// // Returns: DateTime(2024, 1, 15) - the Monday of that week
  /// ```
  static DateTime alignToWeekStart(DateTime date, int startWeekday) {
    final weekday = date.weekday; // 1=Monday, 7=Sunday
    int diff = weekday - startWeekday;
    if (diff < 0) diff += 7; // Handle week wraparound
    return dayKey(date).subtract(Duration(days: diff));
  }

  /// Aligns a date to the end of its week based on the specified start weekday.
  ///
  /// [date] - The date to align
  /// [startWeekday] - The first day of the week (1=Monday, 7=Sunday)
  ///
  /// Returns the last day of the week containing [date].
  static DateTime alignToWeekEnd(DateTime date, int startWeekday) {
    final weekStart = alignToWeekStart(date, startWeekday);
    return weekStart.add(const Duration(days: 6));
  }

  /// Generates localized weekday short names based on start weekday preference.
  ///
  /// [locale] - The locale for localization (currently uses English fallback)
  /// [startWeekday] - The first day of the week (1=Monday, 7=Sunday)
  ///
  /// Returns a list of 7 short weekday names in display order.
  ///
  /// Example:
  /// ```dart
  /// final names = HeatmapUtils.weekdayShortNames(Locale('en'), DateTime.monday);
  /// // Returns: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
  /// ```
  static List<String> weekdayShortNames(Locale locale, int startWeekday) {
    // TODO: Add proper i18n support using DateFormat
    const allNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // Calculate rotation to put startWeekday at index 0
    final rotateBy = startWeekday - DateTime.monday; // 0-6

    return [for (int i = 0; i < 7; i++) allNames[(i + rotateBy) % 7]];
  }

  /// Returns abbreviated month name for the given month number.
  ///
  /// [month] - Month number (1-12)
  ///
  /// Currently returns English abbreviations.
  /// TODO: Add proper i18n support.
  static String monthAbbreviation(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  /// Checks if a date represents the first occurrence of its month in a week column.
  ///
  /// This is used to determine when to show month labels in the heatmap.
  /// A month label is shown when we encounter the first week that contains
  /// any day from a new month.
  ///
  /// [date] - The date to check (should be the start of a week)
  ///
  /// Returns true if this is the first week containing this month.
  static bool isFirstWeekdayOfMonth(DateTime date) {
    // If the date is in the first week of the month (day 1-7), show the label
    return date.day <= 7;
  }

  /// Returns the appropriate color for the given contribution level.
  static Color defaultColorScale(int value) {
    if (value <= 0) return const Color(0xFFFFE4BC); // Empty/no contributions
    if (value == 1) return Colors.orange.shade200;
    if (value == 2) return Colors.orange.shade400;
    if (value <= 4) return Colors.orange.shade500;
    if (value <= 6) return Colors.orange.shade600;
    if (value <= 8) return Colors.orange.shade700;
    if (value <= 10) return Colors.orange.shade800;
    return Colors.orange.shade900; //  High activity
  }
}

/// Extension methods for RRect to support scaling operations.
///
/// This extension adds utility methods to RRect that are needed
/// for efficient rendering in the heatmap widget.
extension RRectExtensions on RRect {
  /// Scales an RRect to the specified dimensions while preserving corner radii.
  ///
  /// This is used to create rounded rectangles for heatmap cells
  /// with consistent corner radius regardless of cell size.
  ///
  /// [width] - Target width for the scaled RRect
  /// [height] - Target height for the scaled RRect
  ///
  /// Returns a new RRect with the specified dimensions.
  RRect scaleRRect(double width, double height) {
    final rect = Rect.fromLTWH(left, top, width, height);
    return RRect.fromRectAndCorners(
      rect,
      topLeft: Radius.circular(tlRadiusX),
      topRight: Radius.circular(trRadiusX),
      bottomLeft: Radius.circular(blRadiusX),
      bottomRight: Radius.circular(brRadiusX),
    );
  }
}
