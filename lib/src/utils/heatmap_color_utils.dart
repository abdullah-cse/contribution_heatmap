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
          const Color(0xFFE3F2FD), // 0% - Very light blue
          const Color(0xFFBBDEFB), // 10%
          const Color(0xFF90CAF9), // 20%
          const Color(0xFF64B5F6), // 30%
          const Color(0xFF42A5F5), // 40%
          const Color(0xFF2196F3), // 50%
          const Color(0xFF1E88E5), // 60%
          const Color(0xFF1976D2), // 70%
          const Color(0xFF1565C0), // 80%
          const Color(0xFF0D47A1), // 90%
          const Color(0xFF0A3A8A), // 100% - Very dark blue
        ];
        
      case HeatmapColor.green:
        return [
          const Color(0xFFE8F5E8), // 0%
          const Color(0xFFC8E6C9), // 10%
          const Color(0xFFA5D6A7), // 20%
          const Color(0xFF81C784), // 30%
          const Color(0xFF66BB6A), // 40%
          const Color(0xFF4CAF50), // 50%
          const Color(0xFF43A047), // 60%
          const Color(0xFF388E3C), // 70%
          const Color(0xFF2E7D32), // 80%
          const Color(0xFF1B5E20), // 90%
          const Color(0xFF0D4F14), // 100%
        ];
        
      case HeatmapColor.purple:
        return [
          const Color(0xFFF3E5F5), // 0%
          const Color(0xFFE1BEE7), // 10%
          const Color(0xFFCE93D8), // 20%
          const Color(0xFFBA68C8), // 30%
          const Color(0xFFAB47BC), // 40%
          const Color(0xFF9C27B0), // 50%
          const Color(0xFF8E24AA), // 60%
          const Color(0xFF7B1FA2), // 70%
          const Color(0xFF6A1B9A), // 80%
          const Color(0xFF4A148C), // 90%
          const Color(0xFF3A1070), // 100%
        ];
        
      case HeatmapColor.red:
        return [
          const Color(0xFFFFEBEE), // 0%
          const Color(0xFFFFCDD2), // 10%
          const Color(0xFFEF9A9A), // 20%
          const Color(0xFFE57373), // 30%
          const Color(0xFFEF5350), // 40%
          const Color(0xFFF44336), // 50%
          const Color(0xFFE53935), // 60%
          const Color(0xFFD32F2F), // 70%
          const Color(0xFFC62828), // 80%
          const Color(0xFFB71C1C), // 90%
          const Color(0xFF8B1A1A), // 100%
        ];
        
      case HeatmapColor.orange:
        return [
          const Color(0xFFFFE4BC), // 0% - Matches your existing color
          const Color(0xFFFFCC80), // 10%
          const Color(0xFFFFB74D), // 20%
          const Color(0xFFFFA726), // 30%
          const Color(0xFFFF9800), // 40%
          const Color(0xFFFB8C00), // 50%
          const Color(0xFFF57C00), // 60%
          const Color(0xFFEF6C00), // 70%
          const Color(0xFFE65100), // 80%
          const Color(0xFFBF360C), // 90%
          const Color(0xFF8D2600), // 100%
        ];
        
      case HeatmapColor.teal:
        return [
          const Color(0xFFE0F2F1), // 0%
          const Color(0xFFB2DFDB), // 10%
          const Color(0xFF80CBC4), // 20%
          const Color(0xFF4DB6AC), // 30%
          const Color(0xFF26A69A), // 40%
          const Color(0xFF009688), // 50%
          const Color(0xFF00897B), // 60%
          const Color(0xFF00796B), // 70%
          const Color(0xFF00695C), // 80%
          const Color(0xFF004D40), // 90%
          const Color(0xFF003530), // 100%
        ];
        
      case HeatmapColor.pink:
        return [
          const Color(0xFFFCE4EC), // 0%
          const Color(0xFFF8BBD9), // 10%
          const Color(0xFFF48FB1), // 20%
          const Color(0xFFF06292), // 30%
          const Color(0xFFEC407A), // 40%
          const Color(0xFFE91E63), // 50%
          const Color(0xFFD81B60), // 60%
          const Color(0xFFC2185B), // 70%
          const Color(0xFFAD1457), // 80%
          const Color(0xFF880E4F), // 90%
          const Color(0xFF6A0B3D), // 100%
        ];
        
      case HeatmapColor.indigo:
        return [
          const Color(0xFFE8EAF6), // 0%
          const Color(0xFFC5CAE9), // 10%
          const Color(0xFF9FA8DA), // 20%
          const Color(0xFF7986CB), // 30%
          const Color(0xFF5C6BC0), // 40%
          const Color(0xFF3F51B5), // 50%
          const Color(0xFF3949AB), // 60%
          const Color(0xFF303F9F), // 70%
          const Color(0xFF283593), // 80%
          const Color(0xFF1A237E), // 90%
          const Color(0xFF141B65), // 100%
        ];
        
      case HeatmapColor.amber:
        return [
          const Color(0xFFFFF8E1), // 0%
          const Color(0xFFFFECB3), // 10%
          const Color(0xFFFFE082), // 20%
          const Color(0xFFFFD54F), // 30%
          const Color(0xFFFFCA28), // 40%
          const Color(0xFFFFC107), // 50%
          const Color(0xFFFFB300), // 60%
          const Color(0xFFFFA000), // 70%
          const Color(0xFFFF8F00), // 80%
          const Color(0xFFFF6F00), // 90%
          const Color(0xFFE65100), // 100%
        ];
        
      case HeatmapColor.cyan:
        return [
          const Color(0xFFE0F7FA), // 0%
          const Color(0xFFB2EBF2), // 10%
          const Color(0xFF80DEEA), // 20%
          const Color(0xFF4DD0E1), // 30%
          const Color(0xFF26C6DA), // 40%
          const Color(0xFF00BCD4), // 50%
          const Color(0xFF00ACC1), // 60%
          const Color(0xFF0097A7), // 70%
          const Color(0xFF00838F), // 80%
          const Color(0xFF006064), // 90%
          const Color(0xFF004D52), // 100%
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
      case HeatmapColor.blue: return 'Blue';
      case HeatmapColor.green: return 'Green';
      case HeatmapColor.purple: return 'Purple';
      case HeatmapColor.red: return 'Red';
      case HeatmapColor.orange: return 'Orange';
      case HeatmapColor.teal: return 'Teal';
      case HeatmapColor.pink: return 'Pink';
      case HeatmapColor.indigo: return 'Indigo';
      case HeatmapColor.amber: return 'Amber';
      case HeatmapColor.cyan: return 'Cyan';
    }
  }
}