/// Determines which weekday labels to display on the heatmap.
enum WeekdayLabel {
  /// No weekday labels are shown
  none,

  /// GitHub-style labels: only Monday, Wednesday, and Friday
  githubLike,

  /// All weekday labels are shown (Monday through Sunday)
  full,
}
