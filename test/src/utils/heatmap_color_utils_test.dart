import 'package:contribution_heatmap/src/enum/heatmap_color.dart';
import 'package:contribution_heatmap/src/models/contribution_entry.dart';
import 'package:contribution_heatmap/src/utils/heatmap_color_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HeatmapColorUtils', () {
    group('createColorScale', () {
      test('returns base color for empty entries', () {
        final scale = HeatmapColorUtils.createColorScale([], HeatmapColor.blue);
        expect(scale(0), const Color(0xFFE3F2FD)); // 0% blue
        expect(scale(10), const Color(0xFFE3F2FD));
      });

      test('returns base color when max value is 0', () {
        final entries = <ContributionEntry>[
          ContributionEntry(DateTime(2023, 1, 1), 0),
        ];
        final scale =
            HeatmapColorUtils.createColorScale(entries, HeatmapColor.green);
        expect(scale(0), const Color(0xFFE8F5E8)); // 0% green
        expect(scale(10), const Color(0xFFE8F5E8));
      });

      test('scales correctly for linear distribution', () {
        final entries = <ContributionEntry>[
          ContributionEntry(DateTime(2023, 1, 1), 0),
          ContributionEntry(DateTime(2023, 1, 2), 10), // Max
        ];

        final scale =
            HeatmapColorUtils.createColorScale(entries, HeatmapColor.blue);

        // 0 -> 0%
        expect(scale(0), const Color(0xFFE3F2FD));
        // 10 -> 100%
        expect(scale(10), const Color(0xFF1565C0)); // New 100% color

        // 5 -> 50%
        // 5/10 = 0.5 intensity -> index 5
        expect(scale(5), const Color(0xFF7CACDF));
      });

      test('clamps values exceeding max', () {
        final entries = <ContributionEntry>[
          ContributionEntry(DateTime(2023, 1, 1), 10),
        ];
        final scale =
            HeatmapColorUtils.createColorScale(entries, HeatmapColor.red);

        // Max is 10. Pass 20. Intensity = 2.0 -> clamped to 1.0 -> index 10.
        expect(scale(20), const Color(0xFFC62828)); // 100% red
      });

      test(
          'handles negative values by treating them as 0 for lookup (effectively)',
          () {
        final entries = <ContributionEntry>[
          ContributionEntry(DateTime(2023, 1, 1), 10),
        ];
        final scale =
            HeatmapColorUtils.createColorScale(entries, HeatmapColor.blue);

        // Code check: if (value <= 0) return colorPalette[0];
        expect(scale(-5), const Color(0xFFE3F2FD));
      });
    });

    group('createPercentileColorScale', () {
      test('falls back to linear if usePercentiles is false', () {
        final entries = <ContributionEntry>[
          ContributionEntry(DateTime(2023, 1, 1), 0),
          ContributionEntry(DateTime(2023, 1, 2), 10),
        ];
        // Same as createColorScale
        final scale = HeatmapColorUtils.createPercentileColorScale(
            entries, HeatmapColor.blue,
            usePercentiles: false);
        expect(scale(5), const Color(0xFF7CACDF));
      });

      test('returns base color if no positive values exist', () {
        final entries = <ContributionEntry>[
          ContributionEntry(DateTime(2023, 1, 1), 0),
        ];
        final scale = HeatmapColorUtils.createPercentileColorScale(
            entries, HeatmapColor.blue,
            usePercentiles: true);
        expect(scale(1), const Color(0xFFE3F2FD));
      });

      test('uses percentiles distribution', () {
        // Create 10 values: 1, 2, ... 10
        final entries = List<ContributionEntry>.generate(
          10,
          (i) => ContributionEntry(
              DateTime(2023, 1, 1).add(Duration(days: i)), i + 1),
        );

        final scale = HeatmapColorUtils.createPercentileColorScale(
            entries, HeatmapColor.blue,
            usePercentiles: true);

        // 1 is the lowest positive value, should act as a low threshold
        // The implementation calculates thresholds based on percentiles of the values list.
        // values = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
        // sorted = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

        // 0 -> 0%
        expect(scale(0), const Color(0xFFE3F2FD));

        // Max value 10 should be max color
        expect(scale(10), const Color(0xFF1565C0));

        // Test that it doesn't crash
        for (int i = 1; i <= 10; i++) {
          expect(scale(i), isA<Color>());
        }
      });
    });

    group('getColorName', () {
      test('returns correct names for all enums', () {
        final expectedNames = {
          HeatmapColor.blue: 'Blue',
          HeatmapColor.green: 'Green',
          HeatmapColor.purple: 'Purple',
          HeatmapColor.red: 'Red',
          HeatmapColor.orange: 'Orange',
          HeatmapColor.teal: 'Teal',
          HeatmapColor.pink: 'Pink',
          HeatmapColor.indigo: 'Indigo',
          HeatmapColor.amber: 'Amber',
          HeatmapColor.cyan: 'Cyan',
        };

        for (var entry in expectedNames.entries) {
          expect(HeatmapColorUtils.getColorName(entry.key), entry.value);
        }
      });
    });

    group('Color Palette Correctness', () {
      // Check a sampling of colors to ensure the new interpolation worked and no crashes
      test('Green palette checks', () {
        final entries = <ContributionEntry>[
          ContributionEntry(DateTime.now(), 10)
        ];
        final scale =
            HeatmapColorUtils.createColorScale(entries, HeatmapColor.green);
        expect(scale(0), const Color(0xFFE8F5E8));
        expect(scale(10), const Color(0xFF2E7D32));
      });

      test('Orange palette checks', () {
        final entries = <ContributionEntry>[
          ContributionEntry(DateTime.now(), 10)
        ];
        final scale =
            HeatmapColorUtils.createColorScale(entries, HeatmapColor.orange);
        expect(scale(0), const Color(0xFFFFE4BC));
        expect(scale(10), const Color(0xFFE65100));
      });
    });
  });
}
