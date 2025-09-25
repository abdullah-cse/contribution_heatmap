import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:contribution_heatmap/src/utils/heatmap_utils.dart';

void main() {
  group('HeatmapUtils.dayKey', () {
    group('Basic Date Normalization', () {
      test('normalizes local DateTime to UTC midnight preserving date', () {
        final input = DateTime(2025, 9, 25, 14, 30, 45, 123);
        final result = HeatmapUtils.dayKey(input);
        
        expect(result, equals(DateTime.utc(2025, 9, 25)));
        expect(result.isUtc, isTrue);
        expect(result.hour, equals(0));
        expect(result.minute, equals(0));
        expect(result.second, equals(0));
        expect(result.millisecond, equals(0));
      });

      test('preserves date components exactly as provided', () {
        final testCases = [
          DateTime(2025, 1, 1, 23, 59, 59),
          DateTime(2025, 12, 31, 0, 0, 1),
          DateTime(2024, 2, 29, 12, 30), // Leap year
          DateTime(2025, 2, 28, 12, 30), // Non-leap year
        ];

        for (final input in testCases) {
          final result = HeatmapUtils.dayKey(input);
          expect(result.year, equals(input.year));
          expect(result.month, equals(input.month));
          expect(result.day, equals(input.day));
          expect(result.isUtc, isTrue);
        }
      });

      test('handles midnight input correctly', () {
        final midnight = DateTime(2025, 9, 25, 0, 0, 0);
        final result = HeatmapUtils.dayKey(midnight);
        
        expect(result, equals(DateTime.utc(2025, 9, 25)));
      });
    });

    group('Timezone Scenarios', () {
      test('preserves local date regardless of timezone offset', () {
        // Simulate different timezone scenarios by using the date components
        // that users in different timezones would provide
        
        // Bangladesh user at 2 AM Sept 25th (UTC+6)
        final bangladeshInput = DateTime(2025, 9, 25, 2, 0);
        final bdResult = HeatmapUtils.dayKey(bangladeshInput);
        expect(bdResult, equals(DateTime.utc(2025, 9, 25)));
        
        // US East Coast user at 11.30 PM Sept 24th (UTC-4)
        final usInput = DateTime(2025, 9, 24, 23, 30);
        final usResult = HeatmapUtils.dayKey(usInput);
        expect(usResult, equals(DateTime.utc(2025, 9, 24)));
        
        // London user at noon Sept 25th (UTC+1)
        final ukInput = DateTime(2025, 9, 25, 12, 0);
        final ukResult = HeatmapUtils.dayKey(ukInput);
        expect(ukResult, equals(DateTime.utc(2025, 9, 25)));
        
        // Each user sees their contribution on the date they expect
      });

      test('handles edge-of-day times correctly', () {
        // Just after midnight
        final justAfterMidnight = DateTime(2025, 9, 25, 0, 0, 1);
        expect(HeatmapUtils.dayKey(justAfterMidnight), 
               equals(DateTime.utc(2025, 9, 25)));
        
        // Just before midnight
        final justBeforeMidnight = DateTime(2025, 9, 25, 23, 59, 59);
        expect(HeatmapUtils.dayKey(justBeforeMidnight), 
               equals(DateTime.utc(2025, 9, 25)));
      });

      test('handles UTC input correctly', () {
        final utcInput = DateTime.utc(2025, 9, 25, 14, 30);
        final result = HeatmapUtils.dayKey(utcInput);
        
        expect(result, equals(DateTime.utc(2025, 9, 25)));
        expect(result.isUtc, isTrue);
      });
    });

    group('DST Transition Scenarios', () {
      test('handles spring forward dates (DST begins)', () {
        // In 2025, DST typically begins on March 9th in US
        // Test dates around this transition
        final beforeDST = DateTime(2025, 3, 8, 14, 30);
        final duringDST = DateTime(2025, 3, 9, 3, 30); // After 2 AM jump
        final afterDST = DateTime(2025, 3, 10, 14, 30);
        
        expect(HeatmapUtils.dayKey(beforeDST), equals(DateTime.utc(2025, 3, 8)));
        expect(HeatmapUtils.dayKey(duringDST), equals(DateTime.utc(2025, 3, 9)));
        expect(HeatmapUtils.dayKey(afterDST), equals(DateTime.utc(2025, 3, 10)));
      });

      test('handles fall back dates (DST ends)', () {
        // In 2025, DST typically ends on November 2nd in US
        // Test dates around this transition
        final beforeFallBack = DateTime(2025, 11, 1, 14, 30);
        final duringFallBack = DateTime(2025, 11, 2, 1, 30); // During repeated hour
        final afterFallBack = DateTime(2025, 11, 3, 14, 30);
        
        expect(HeatmapUtils.dayKey(beforeFallBack), equals(DateTime.utc(2025, 11, 1)));
        expect(HeatmapUtils.dayKey(duringFallBack), equals(DateTime.utc(2025, 11, 2)));
        expect(HeatmapUtils.dayKey(afterFallBack), equals(DateTime.utc(2025, 11, 3)));
      });

      test('produces consistent results across DST boundaries', () {
        // Same date should produce same result regardless of when it's processed
        final springForwardDate = DateTime(2025, 3, 9, 14, 30);
        final fallBackDate = DateTime(2025, 11, 2, 14, 30);
        
        final springResult1 = HeatmapUtils.dayKey(springForwardDate);
        final springResult2 = HeatmapUtils.dayKey(springForwardDate);
        expect(springResult1, equals(springResult2));
        
        final fallResult1 = HeatmapUtils.dayKey(fallBackDate);
        final fallResult2 = HeatmapUtils.dayKey(fallBackDate);
        expect(fallResult1, equals(fallResult2));
      });
    });

    group('Edge Cases and Boundary Conditions', () {
      test('handles leap year dates', () {
        // 2024 is a leap year
        final leapDay = DateTime(2024, 2, 29, 12, 0);
        final result = HeatmapUtils.dayKey(leapDay);
        expect(result, equals(DateTime.utc(2024, 2, 29)));
        
        // Day before leap day
        final beforeLeap = DateTime(2024, 2, 28, 12, 0);
        expect(HeatmapUtils.dayKey(beforeLeap), equals(DateTime.utc(2024, 2, 28)));
        
        // Day after leap day
        final afterLeap = DateTime(2024, 3, 1, 12, 0);
        expect(HeatmapUtils.dayKey(afterLeap), equals(DateTime.utc(2024, 3, 1)));
      });

      test('handles year boundaries', () {
        final newYearsEve = DateTime(2024, 12, 31, 23, 59);
        final newYearsDay = DateTime(2025, 1, 1, 0, 1);
        
        expect(HeatmapUtils.dayKey(newYearsEve), equals(DateTime.utc(2024, 12, 31)));
        expect(HeatmapUtils.dayKey(newYearsDay), equals(DateTime.utc(2025, 1, 1)));
      });

      test('handles month boundaries', () {
        final endOfMonth = DateTime(2025, 1, 31, 23, 59);
        final startOfNextMonth = DateTime(2025, 2, 1, 0, 1);
        
        expect(HeatmapUtils.dayKey(endOfMonth), equals(DateTime.utc(2025, 1, 31)));
        expect(HeatmapUtils.dayKey(startOfNextMonth), equals(DateTime.utc(2025, 2, 1)));
      });

      test('handles extreme dates', () {
        // Very early date
        final earlyDate = DateTime(1900, 1, 1, 12, 0);
        expect(HeatmapUtils.dayKey(earlyDate), equals(DateTime.utc(1900, 1, 1)));
        
        // Far future date
        final futureDate = DateTime(2100, 12, 31, 12, 0);
        expect(HeatmapUtils.dayKey(futureDate), equals(DateTime.utc(2100, 12, 31)));
      });
    });

    group('Consistency and Idempotency', () {
      test('is idempotent - same input always gives same output', () {
        final input = DateTime(2025, 9, 25, 14, 30, 45);
        final result1 = HeatmapUtils.dayKey(input);
        final result2 = HeatmapUtils.dayKey(input);
        final result3 = HeatmapUtils.dayKey(input);
        
        expect(result1, equals(result2));
        expect(result2, equals(result3));
      });

      test('normalizing already normalized date returns same result', () {
        final input = DateTime(2025, 9, 25, 14, 30);
        final normalized = HeatmapUtils.dayKey(input);
        final doubleNormalized = HeatmapUtils.dayKey(normalized);
        
        expect(normalized, equals(doubleNormalized));
      });

      test('different times on same date produce same result', () {
        final morning = DateTime(2025, 9, 25, 9, 0);
        final afternoon = DateTime(2025, 9, 25, 15, 30);
        final evening = DateTime(2025, 9, 25, 22, 45);
        
        final expected = DateTime.utc(2025, 9, 25);
        
        expect(HeatmapUtils.dayKey(morning), equals(expected));
        expect(HeatmapUtils.dayKey(afternoon), equals(expected));
        expect(HeatmapUtils.dayKey(evening), equals(expected));
      });
    });

    group('Real-world Usage Patterns', () {
      test('handles typical contribution entry patterns', () {
        // Simulate how users might create contribution entries
        final now = DateTime.now();
        final yesterday = now.subtract(const Duration(days: 1));
        
        // All should normalize to their respective dates
        final normalizedNow = HeatmapUtils.dayKey(now);
        final normalizedYesterday = HeatmapUtils.dayKey(yesterday);

        
        // Verify they're different days (unless today happens to be same as yesterday, etc.)
        expect(normalizedNow.year, equals(now.year));
        expect(normalizedNow.month, equals(now.month));
        expect(normalizedNow.day, equals(now.day));
        
        expect(normalizedYesterday.year, equals(yesterday.year));
        expect(normalizedYesterday.month, equals(yesterday.month));
        expect(normalizedYesterday.day, equals(yesterday.day));
      });

      test('works correctly for contribution data aggregation', () {
        // Multiple entries on the same date should map to same key
        final entries = [
          DateTime(2025, 9, 25, 9, 0),   // Morning
          DateTime(2025, 9, 25, 12, 30), // Noon
          DateTime(2025, 9, 25, 18, 45), // Evening
          DateTime(2025, 9, 25, 23, 59), // Late night
        ];
        
        final normalizedKeys = entries.map(HeatmapUtils.dayKey).toSet();
        
        // All should map to the same key
        expect(normalizedKeys.length, equals(1));
        expect(normalizedKeys.first, equals(DateTime.utc(2025, 9, 25)));
      });
    });
  });

  group('HeatmapUtils.alignToWeekStart', () {
    test('aligns dates to Monday start correctly', () {
      // Wednesday, January 17, 2024
      final wednesday = DateTime(2024, 1, 17);
      final mondayStart = HeatmapUtils.alignToWeekStart(wednesday, DateTime.monday);
      
      // Should return Monday, January 15, 2024
      expect(mondayStart, equals(DateTime.utc(2024, 1, 15)));
      expect(mondayStart.weekday, equals(DateTime.monday));
    });

    test('aligns dates to Sunday start correctly', () {
      // Wednesday, January 17, 2024
      final wednesday = DateTime(2024, 1, 17);
      final sundayStart = HeatmapUtils.alignToWeekStart(wednesday, DateTime.sunday);
      
      // Should return Sunday, January 14, 2024
      expect(sundayStart, equals(DateTime.utc(2024, 1, 14)));
      expect(sundayStart.weekday, equals(DateTime.sunday));
    });

    test('handles week boundaries correctly', () {
      // Test across month boundary
      final firstOfMonth = DateTime(2024, 2, 1); // Thursday
      final mondayStart = HeatmapUtils.alignToWeekStart(firstOfMonth, DateTime.monday);
      
      // Should return Monday of previous month
      expect(mondayStart.month, equals(1)); // January
      expect(mondayStart.day, equals(29));
      expect(mondayStart.weekday, equals(DateTime.monday));
    });

    test('returns same date if already at week start', () {
      final monday = DateTime(2024, 1, 15); // Already Monday
      final result = HeatmapUtils.alignToWeekStart(monday, DateTime.monday);
      
      expect(result, equals(DateTime.utc(2024, 1, 15)));
    });
  });

  group('HeatmapUtils.alignToWeekEnd', () {
    test('aligns dates to week end correctly', () {
      final monday = DateTime(2024, 1, 15);
      final weekEnd = HeatmapUtils.alignToWeekEnd(monday, DateTime.monday);
      
      // Should return Sunday, January 21, 2024
      expect(weekEnd, equals(DateTime.utc(2024, 1, 21)));
      expect(weekEnd.weekday, equals(DateTime.sunday));
    });

    test('handles cross-month boundaries', () {
      final endOfJan = DateTime(2024, 1, 30); // Tuesday
      final weekEnd = HeatmapUtils.alignToWeekEnd(endOfJan, DateTime.monday);
      
      // Week should end on Sunday in February
      expect(weekEnd.month, equals(2)); // February
      expect(weekEnd.weekday, equals(DateTime.sunday));
    });
  });

  group('HeatmapUtils.isFirstWeekdayOfMonth', () {
    test('identifies first week of month correctly', () {
      expect(HeatmapUtils.isFirstWeekdayOfMonth(DateTime(2024, 1, 1)), isTrue);
      expect(HeatmapUtils.isFirstWeekdayOfMonth(DateTime(2024, 1, 7)), isTrue);
      expect(HeatmapUtils.isFirstWeekdayOfMonth(DateTime(2024, 1, 8)), isFalse);
      expect(HeatmapUtils.isFirstWeekdayOfMonth(DateTime(2024, 1, 15)), isFalse);
    });
  });

  group('HeatmapUtils.defaultColorScale', () {
    test('returns correct colors for different contribution levels', () {
      expect(HeatmapUtils.defaultColorScale(0), equals(const Color(0xFFFFE4BC)));
      expect(HeatmapUtils.defaultColorScale(-1), equals(const Color(0xFFFFE4BC)));
      expect(HeatmapUtils.defaultColorScale(1), equals(Colors.orange.shade200));
      expect(HeatmapUtils.defaultColorScale(2), equals(Colors.orange.shade400));
      expect(HeatmapUtils.defaultColorScale(4), equals(Colors.orange.shade500));
      expect(HeatmapUtils.defaultColorScale(6), equals(Colors.orange.shade600));
      expect(HeatmapUtils.defaultColorScale(8), equals(Colors.orange.shade700));
      expect(HeatmapUtils.defaultColorScale(10), equals(Colors.orange.shade800));
      expect(HeatmapUtils.defaultColorScale(15), equals(Colors.orange.shade900));
    });
  });
}