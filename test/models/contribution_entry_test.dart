import 'package:flutter_test/flutter_test.dart';
import 'package:contribution_heatmap/contribution_heatmap.dart';

void main() {
  group('ContributionEntry', () {
    test('should correctly store date and count', () {
      final entry = ContributionEntry(DateTime(2024, 1, 15), 5);

      expect(entry.date.year, 2024);
      expect(entry.date.month, 1);
      expect(entry.date.day, 15);
      expect(entry.count, 5);
    });

    test('should throw assertion if count is negative', () {
      expect(() => ContributionEntry(DateTime.now(), -1), throwsA(isA<AssertionError>()));
    });

    test('equality works with same date and count', () {
      final e1 = ContributionEntry(DateTime(2024, 1, 1), 3);
      final e2 = ContributionEntry(DateTime(2024, 1, 1), 3);

      expect(e1, equals(e2));
      expect(e1.hashCode, equals(e2.hashCode));
    });

    test('equality fails if count differs', () {
      final e1 = ContributionEntry(DateTime(2024, 1, 1), 3);
      final e2 = ContributionEntry(DateTime(2024, 1, 1), 5);

      expect(e1 == e2, isFalse);
    });
  });
}
