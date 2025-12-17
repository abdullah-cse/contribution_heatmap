import 'package:contribution_heatmap/src/enum/heatmap_color.dart';
import 'package:flutter/material.dart';
import '../models/contribution_entry.dart';

/// Utility class for generating dynamic color scales based on contribution data.
class HeatmapColorUtils {
  /// Generates a dynamic color scale function based on the selected color scheme
  /// and the actual contribution data distribution.
  ///
  /// This method analyzes the contribution entries to find the maximum value,
  /// then creates 11 color levels (0%, 10%, 20%, ..., 100%) where:
  /// - 0% represents no contributions (value = 0)
  /// - 100% represents the highest contribution value in the dataset
  /// - Other percentiles are calculated proportionally
  ///
  /// [entries] - The contribution data to analyze
  /// [heatmapColor] - The color scheme to use
  ///
  /// Returns a function that maps contribution values to colors
  static Color Function(int value) createColorScale(
    List<ContributionEntry> entries,
    HeatmapColor heatmapColor,
  ) {
    // Find the maximum contribution value in the dataset
    final maxValue = entries.isEmpty
        ? 0
        : entries.map((e) => e.count).reduce((a, b) => a > b ? a : b);

    // If no contributions exist, return a function that always returns the base color
    if (maxValue <= 0) {
      return (int value) => _getColorAtIntensity(heatmapColor, 0);
    }

    // Get the color palette for the selected scheme
    final colorPalette = _getColorPalette(heatmapColor);

    return (int value) {
      // Handle zero contributions
      if (value <= 0) return colorPalette[0]; // 0% intensity

      // Calculate the percentage intensity (0.0 to 1.0)
      final intensity = (value / maxValue).clamp(0.0, 1.0);

      // Map to one of our 11 color levels (0-10)
      final colorIndex = (intensity * 10).round().clamp(0, 10);

      return colorPalette[colorIndex];
    };
  }

  /// Alternative method that allows custom intensity levels.
  /// This version calculates percentiles from the actual data distribution
  /// rather than using linear scaling from 0 to max.
  ///
  /// [entries] - The contribution data to analyze
  /// [heatmapColor] - The color scheme to use
  /// [usePercentiles] - If true, uses data percentiles; if false, uses linear scaling
  ///
  /// Returns a function that maps contribution values to colors
  static Color Function(int value) createPercentileColorScale(
    List<ContributionEntry> entries,
    HeatmapColor heatmapColor, {
    bool usePercentiles = false,
  }) {
    if (entries.isEmpty) {
      return (int value) => _getColorAtIntensity(heatmapColor, 0);
    }

    final values = entries.map((e) => e.count).where((v) => v > 0).toList();
    if (values.isEmpty) {
      return (int value) => _getColorAtIntensity(heatmapColor, 0);
    }

    values.sort();
    final colorPalette = _getColorPalette(heatmapColor);

    if (!usePercentiles) {
      // Use the simpler linear scaling approach
      return createColorScale(entries, heatmapColor);
    }

    // Calculate percentile thresholds
    final thresholds = <int>[];
    for (int i = 1; i <= 10; i++) {
      final percentile = i / 10.0;
      final index = ((values.length - 1) * percentile).round();
      thresholds.add(values[index]);
    }

    return (int value) {
      if (value <= 0) return colorPalette[0]; // 0% intensity

      // Find which threshold this value exceeds
      int colorIndex = 10; // Default to highest intensity
      for (int i = 0; i < thresholds.length; i++) {
        if (value <= thresholds[i]) {
          colorIndex = i + 1; // +1 because index 0 is reserved for zero values
          break;
        }
      }

      return colorPalette[colorIndex];
    };
  }

  /// Returns a palette of 11 colors (0% to 100% intensity) for the given color scheme.
  static List<Color> _getColorPalette(HeatmapColor heatmapColor) {
    switch (heatmapColor) {
      case HeatmapColor.blue:
        return [
          const Color(0xFFE3F2FD), // 0%
          const Color(0xFFCEE4F7), // 10%
          const Color(0xFFBAD6F1), // 20%
          const Color(0xFFA5C8EB), // 30%
          const Color(0xFF91BAE5), // 40%
          const Color(0xFF7CACDF), // 50%
          const Color(0xFF679DD8), // 60%
          const Color(0xFF538FD2), // 70%
          const Color(0xFF3E81CC), // 80%
          const Color(0xFF2A73C6), // 90%
          const Color(0xFF1565C0), // 100%
        ];

      case HeatmapColor.green:
        return [
          const Color(0xFFE8F5E8), // 0%
          const Color(0xFFD5E9D6), // 10%
          const Color(0xFFC3DDC4), // 20%
          const Color(0xFFB0D1B1), // 30%
          const Color(0xFF9EC59F), // 40%
          const Color(0xFF8BB98D), // 50%
          const Color(0xFF78AD7B), // 60%
          const Color(0xFF66A169), // 70%
          const Color(0xFF539556), // 80%
          const Color(0xFF418944), // 90%
          const Color(0xFF2E7D32), // 100%
        ];

      case HeatmapColor.purple:
        return [
          const Color(0xFFF3E5F5), // 0%
          const Color(0xFFE5D1EC), // 10%
          const Color(0xFFD8BDE3), // 20%
          const Color(0xFFCAA8DA), // 30%
          const Color(0xFFBC94D1), // 40%
          const Color(0xFFAF80C8), // 50%
          const Color(0xFFA16CBE), // 60%
          const Color(0xFF9358B5), // 70%
          const Color(0xFF8543AC), // 80%
          const Color(0xFF782FA3), // 90%
          const Color(0xFF6A1B9A), // 100%
        ];

      case HeatmapColor.red:
        return [
          const Color(0xFFFFEBEE), // 0%
          const Color(0xFFF9D8DA), // 10%
          const Color(0xFFF4C4C6), // 20%
          const Color(0xFFEEB1B3), // 30%
          const Color(0xFFE89D9F), // 40%
          const Color(0xFFE38A8B), // 50%
          const Color(0xFFDD7677), // 60%
          const Color(0xFFD76363), // 70%
          const Color(0xFFD14F50), // 80%
          const Color(0xFFCC3C3C), // 90%
          const Color(0xFFC62828), // 100%
        ];

      case HeatmapColor.orange:
        return [
          const Color(0xFFFFE4BC), // 0%
          const Color(0xFFFDD5A9), // 10%
          const Color(0xFFFAC796), // 20%
          const Color(0xFFF8B884), // 30%
          const Color(0xFFF5A971), // 40%
          const Color(0xFFF39B5E), // 50%
          const Color(0xFFF08C4B), // 60%
          const Color(0xFFEE7D38), // 70%
          const Color(0xFFEB6E26), // 80%
          const Color(0xFFE96013), // 90%
          const Color(0xFFE65100), // 100%
        ];

      case HeatmapColor.teal:
        return [
          const Color(0xFFE0F2F1), // 0%
          const Color(0xFFCAE4E2), // 10%
          const Color(0xFFB3D7D3), // 20%
          const Color(0xFF9DC9C4), // 30%
          const Color(0xFF86BBB5), // 40%
          const Color(0xFF70AEA7), // 50%
          const Color(0xFF5AA098), // 60%
          const Color(0xFF439289), // 70%
          const Color(0xFF2D847A), // 80%
          const Color(0xFF16776B), // 90%
          const Color(0xFF00695C), // 100%
        ];

      case HeatmapColor.pink:
        return [
          const Color(0xFFFCE4EC), // 0%
          const Color(0xFFF4CFDD), // 10%
          const Color(0xFFECBACE), // 20%
          const Color(0xFFE4A6BF), // 30%
          const Color(0xFFDC91B0), // 40%
          const Color(0xFFD57CA2), // 50%
          const Color(0xFFCD6793), // 60%
          const Color(0xFFC55284), // 70%
          const Color(0xFFBD3E75), // 80%
          const Color(0xFFB52966), // 90%
          const Color(0xFFAD1457), // 100%
        ];

      case HeatmapColor.indigo:
        return [
          const Color(0xFFE8EAF6), // 0%
          const Color(0xFFD5D8EC), // 10%
          const Color(0xFFC2C6E2), // 20%
          const Color(0xFFAEB4D8), // 30%
          const Color(0xFF9BA2CE), // 40%
          const Color(0xFF8890C5), // 50%
          const Color(0xFF757DBB), // 60%
          const Color(0xFF626BB1), // 70%
          const Color(0xFF4E59A7), // 80%
          const Color(0xFF3B479D), // 90%
          const Color(0xFF283593), // 100%
        ];

      case HeatmapColor.amber:
        return [
          const Color(0xFFFFF8E1), // 0%
          const Color(0xFFFFEECB), // 10%
          const Color(0xFFFFE3B4), // 20%
          const Color(0xFFFFD99E), // 30%
          const Color(0xFFFFCE87), // 40%
          const Color(0xFFFFC471), // 50%
          const Color(0xFFFFB95A), // 60%
          const Color(0xFFFFAF44), // 70%
          const Color(0xFFFFA42D), // 80%
          const Color(0xFFFF9A17), // 90%
          const Color(0xFFFF8F00), // 100%
        ];

      case HeatmapColor.cyan:
        return [
          const Color(0xFFE0F7FA), // 0%
          const Color(0xFFCAEBEF), // 10%
          const Color(0xFFB3E0E5), // 20%
          const Color(0xFF9DD4DA), // 30%
          const Color(0xFF86C9CF), // 40%
          const Color(0xFF70BDC5), // 50%
          const Color(0xFF5AB1BA), // 60%
          const Color(0xFF43A6AF), // 70%
          const Color(0xFF2D9AA4), // 80%
          const Color(0xFF168F9A), // 90%
          const Color(0xFF00838F), // 100%
        ];
    }
  }

  /// Helper method to get a color at a specific intensity level (0-10).
  static Color _getColorAtIntensity(HeatmapColor heatmapColor, int intensity) {
    final palette = _getColorPalette(heatmapColor);
    return palette[intensity.clamp(0, 10)];
  }

  /// Returns a human-readable name for the color scheme.
  static String getColorName(HeatmapColor color) {
    switch (color) {
      case HeatmapColor.blue:
        return 'Blue';
      case HeatmapColor.green:
        return 'Green';
      case HeatmapColor.purple:
        return 'Purple';
      case HeatmapColor.red:
        return 'Red';
      case HeatmapColor.orange:
        return 'Orange';
      case HeatmapColor.teal:
        return 'Teal';
      case HeatmapColor.pink:
        return 'Pink';
      case HeatmapColor.indigo:
        return 'Indigo';
      case HeatmapColor.amber:
        return 'Amber';
      case HeatmapColor.cyan:
        return 'Cyan';
    }
  }
}
