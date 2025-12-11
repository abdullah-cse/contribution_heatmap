import 'package:flutter_test/flutter_test.dart';
import 'package:contribution_heatmap/contribution_heatmap.dart';

void main() {
  group('ContributionEntry', () {
    test('should correctly store date and count', () {
      final date = DateTime(2024, 1, 15);
      final entry = ContributionEntry(date, 5);

      expect(entry.date, date);
      expect(entry.count, 5);
    });

    test('should throw assertion if count is negative', () {
      expect(
        () => ContributionEntry(DateTime.now(), -1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('equality works with same date and count', () {
      final date = DateTime(2024, 1, 1);
      final e1 = ContributionEntry(date, 3);
      final e2 = ContributionEntry(date, 3);

      expect(e1, equals(e2));
      expect(e1.hashCode, equals(e2.hashCode));
    });

    test('equality fails if count differs', () {
      final date = DateTime(2024, 1, 1);
      final e1 = ContributionEntry(date, 3);
      final e2 = ContributionEntry(date, 5);

      expect(e1, isNot(equals(e2)));
    });

    test('equality fails if date differs', () {
      final e1 = ContributionEntry(DateTime(2024, 1, 1), 3);
      final e2 = ContributionEntry(DateTime(2024, 1, 2), 3);

      expect(e1, isNot(equals(e2)));
    });

    test('should allow zero count', () {
      // Zero is valid, negative is not.
      final entry = ContributionEntry(DateTime(2024, 1, 1), 0);
      expect(entry.count, 0);
    });
  });
}
