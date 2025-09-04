import 'package:flutter/material.dart';
import '../models/contribution_entry.dart';
import '../rendering/render_contribution_heatmap.dart';


/// A high-performance GitHub-like contribution heatmap widget.

/// ## Basic Usage:
/// ```dart
/// ContributionHeatmap(
///   entries: [
///     ContributionEntry(DateTime(2024, 1, 15), 5),
///     ContributionEntry(DateTime(2024, 1, 16), 3),
///     // ... more entries
///   ],
///   onCellTap: (date, value) {
///     print('Tapped: $date with $value contributions');
///   },
/// )
/// ```

class ContributionHeatmap extends LeafRenderObjectWidget {
  /// List of contribution entries to display.
  /// 
  /// Each entry represents a day's contribution count. The widget will
  /// automatically determine the date range and create an appropriate grid.
  /// Days with no entries will be shown as empty (with the lowest color intensity).
  final List<ContributionEntry> entries;

  /// Optional minimum date for the heatmap range.
  /// 
  /// If provided, the heatmap will start from this date regardless of
  /// the earliest entry in [entries]. If null, the range is derived
  /// automatically from the entry dates.
  /// 
  /// Example:
  /// ```dart
  /// minDate: DateTime(2023, 1, 1), // Always show from start of year
  /// ```
  final DateTime? minDate;

  /// Optional maximum date for the heatmap range.
  /// 
  /// If provided, the heatmap will end at this date regardless of
  /// the latest entry in [entries]. If null, the range is derived
  /// automatically from the entry dates.
  /// 
  /// Example:
  /// ```dart
  /// maxDate: DateTime.now(), // Always show up to today
  /// ```
  final DateTime? maxDate;

  /// Size of each contribution cell in logical pixels.
  /// 
  /// Larger values create bigger cells but require more space.
  /// GitHub uses approximately 10-11px cells.
  /// 
  /// Defaults to 12.0.
  final double cellSize;

  /// Spacing between contribution cells in logical pixels.
  /// 
  /// This creates the visual separation between cells in the grid.
  /// GitHub uses approximately 2-3px spacing.
  /// 
  /// Defaults to 3.0.
  final double cellSpacing;

  /// Corner radius for cell rounded rectangles in logical pixels.
  /// 
  /// Use 0 for square cells, or a small value for subtle rounding.
  /// Values larger than cellSize/2 will create circular cells.
  /// 
  /// Defaults to 2.0.
  final double cellRadius;

  /// Padding around the entire heatmap widget.
  /// 
  /// This provides space between the heatmap and its container.
  /// The padding is applied outside the labels and grid.
  /// 
  /// Defaults to EdgeInsets.all(16).
  final EdgeInsets padding;

  /// Whether to show month labels above the heatmap.
  /// 
  /// Month labels appear above the first week of each month,
  /// helping users understand the time progression.
  /// 
  /// Defaults to true.
  final bool showMonthLabels;

  /// Whether to show weekday labels to the left of the heatmap.
  /// 
  /// Weekday labels show abbreviated day names (Mon, Tue, etc.)
  /// for each row, helping users understand the weekly pattern.
  /// 
  /// Defaults to true.
  final bool showWeekdayLabels;

  /// Text style for month labels.
  /// 
  /// If null, uses the default text style from the current theme
  /// with a font size of 12px. The style should have good contrast
  /// against the background for accessibility.
  final TextStyle? monthTextStyle;

  /// Text style for weekday labels.
  /// 
  /// If null, uses the default text style from the current theme
  /// with a font size of 11px. The style should have good contrast
  /// against the background for accessibility.
  final TextStyle? weekdayTextStyle;

  /// First day of the week for grid alignment.
  /// 
  /// This determines how weeks are aligned in the grid columns:
  /// - DateTime.monday (1) - Week starts on Monday
  /// - DateTime.tuesday (2) - Week starts on Tuesday
  /// - ... and so on ...
  /// - DateTime.sunday (7) - Week starts on Sunday
  /// 
  /// Most regions use Monday (ISO 8601), but some use Sunday.
  /// 
  /// Defaults to DateTime.monday.
  final int startWeekday;

  /// Custom color scale function for mapping contribution values to colors.
  /// 
  /// If provided, this function will be called for each cell to determine
  /// its color based on the contribution count. If null, uses a default
  /// GitHub-style green color scale.
  /// 
  /// Example:
  /// ```dart
  /// colorScale: (value) {
  ///   if (value == 0) return Colors.grey[100]!;
  ///   if (value <= 2) return Colors.blue[200]!;
  ///   if (value <= 5) return Colors.blue[400]!;
  ///   return Colors.blue[600]!;
  /// },
  /// ```
  final Color Function(int value)? colorScale;

  /// Callback function called when a cell is tapped.
  /// 
  /// Provides the date and contribution value for the tapped cell.
  /// Use this to show tooltips, navigate to details, or perform
  /// other actions based on the selected day.
  /// 
  /// Example:
  /// ```dart
  /// onCellTap: (date, value) {
  ///   showDialog(
  ///     context: context,
  ///     builder: (context) => AlertDialog(
  ///       title: Text('${date.toIso8601String().split('T')[0]}'),
  ///       content: Text('$value contributions'),
  ///     ),
  ///   );
  /// },
  /// ```
  final void Function(DateTime date, int value)? onCellTap;

  /// Creates a new contribution heatmap widget.
  /// 
  /// The [entries] parameter is required and should contain the contribution
  /// data to visualize. All other parameters are optional and have sensible
  /// defaults for most use cases.
  const ContributionHeatmap({
    super.key,
    required this.entries,
    this.minDate,
    this.maxDate,
    this.cellSize = 12,
    this.cellSpacing = 3,
    this.cellRadius = 2,
    this.padding = const EdgeInsets.all(16),
    this.showMonthLabels = true,
    this.showWeekdayLabels = true,
    this.monthTextStyle,
    this.weekdayTextStyle,
    this.startWeekday = DateTime.monday,
    this.colorScale,
    this.onCellTap,
  }) : assert(startWeekday >= DateTime.monday && startWeekday <= DateTime.sunday,
             'startWeekday must be between DateTime.monday (1) and DateTime.sunday (7)');

  @override
  RenderObject createRenderObject(BuildContext context) {
    // Get accessibility and localization settings from the context
    final textScaler = MediaQuery.textScalerOf(context);
    final locale = Localizations.localeOf(context);
    
    // Create default text styles if none provided
    final defaultTextStyle = DefaultTextStyle.of(context).style;
    final resolvedMonthStyle = (monthTextStyle ?? 
        defaultTextStyle.copyWith(fontSize: 12))
        .copyWith(height: 1.0); // Ensure consistent line height
    final resolvedWeekdayStyle = (weekdayTextStyle ?? 
        defaultTextStyle.copyWith(fontSize: 11))
        .copyWith(height: 1.0); // Ensure consistent line height
    
    return RenderContributionHeatmap(
      entries: entries,
      minDate: minDate,
      maxDate: maxDate,
      cellSize: cellSize,
      cellSpacing: cellSpacing,
      cellRadius: cellRadius,
      padding: padding,
      showMonthLabels: showMonthLabels,
      showWeekdayLabels: showWeekdayLabels,
      monthTextStyle: resolvedMonthStyle,
      weekdayTextStyle: resolvedWeekdayStyle,
      startWeekday: startWeekday,
      colorScale: colorScale,
      onCellTap: onCellTap,
      textScaler: textScaler,
      locale: locale,
    );
  }

  @override
  void updateRenderObject(BuildContext context, covariant RenderContributionHeatmap renderObject) {
    // Update the render object when widget properties change
    final textScaler = MediaQuery.textScalerOf(context);
    final locale = Localizations.localeOf(context);
    final defaultTextStyle = DefaultTextStyle.of(context).style;
    
    final resolvedMonthStyle = (monthTextStyle ?? 
        defaultTextStyle.copyWith(fontSize: 12))
        .copyWith(height: 1.0);
    final resolvedWeekdayStyle = (weekdayTextStyle ?? 
        defaultTextStyle.copyWith(fontSize: 11))
        .copyWith(height: 1.0);

    // Update all properties - the render object will handle smart invalidation
    renderObject
      ..entries = entries
      ..minDate = minDate
      ..maxDate = maxDate
      ..cellSize = cellSize
      ..cellSpacing = cellSpacing
      ..cellRadius = cellRadius
      ..padding = padding
      ..showMonthLabels = showMonthLabels
      ..showWeekdayLabels = showWeekdayLabels
      ..monthTextStyle = resolvedMonthStyle
      ..weekdayTextStyle = resolvedWeekdayStyle
      ..startWeekday = startWeekday
      ..colorScale = colorScale
      ..onCellTap = onCellTap
      ..textScaler = textScaler
      ..locale = locale;
  }
}