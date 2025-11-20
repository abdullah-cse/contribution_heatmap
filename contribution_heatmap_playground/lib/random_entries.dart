import 'dart:math';
import 'package:contribution_heatmap/contribution_heatmap.dart';

List<ContributionEntry> generateRandomContributionEntries({
  int count = 80,
}) {
  final now = DateTime.now();
  final sixMonthsAgo = DateTime(now.year, now.month - 6, now.day);
  final random = Random();

  List<ContributionEntry> entries = [];

  for (int i = 0; i < count; i++) {
    final difference = now.difference(sixMonthsAgo).inDays;
    final randomDayOffset = random.nextInt(difference + 1);
    final date = sixMonthsAgo.add(Duration(days: randomDayOffset));
    final value = 1 + random.nextInt(10);

    entries.add(ContributionEntry(date, value));
  }

  return entries;
}
