/// Data models for the contribution heatmap widget.
/// Example:
/// ```dart
/// final entry = ContributionEntry(DateTime(2024, 1, 15), 5);
/// ```
class ContributionEntry {
  /// The date of the contribution (day-level precision).
  /// Time components are ignored - only year, month, and day matter.
  final DateTime date;

  /// The number of contributions made on this date.
  /// Should be >= 0. Higher values will be rendered with darker colors.
  final int count;

  const ContributionEntry(this.date, this.count)
      : assert(count >= 0, 'ContributionEntry\'s Count must be non-negative');

  @override
  String toString() =>
      'ContributionEntry(${date.toIso8601String().split('T')[0]}, $count)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContributionEntry &&
          runtimeType == other.runtimeType &&
          date.year == other.date.year &&
          date.month == other.date.month &&
          date.day == other.date.day &&
          count == other.count;

  @override
  int get hashCode => Object.hash(date.year, date.month, date.day, count);
}
