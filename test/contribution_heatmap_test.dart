import 'package:flutter_test/flutter_test.dart';
import 'package:contribution_heatmap/contribution_heatmap.dart';

void main() {
  test('barrel file exports ContributionEntry', () {
    final entry = ContributionEntry(DateTime(2024, 1, 1), 1);
    expect(entry.count, 1);
  });
}
