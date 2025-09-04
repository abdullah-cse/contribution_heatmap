import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import '../models/contribution_entry.dart';
import '../utils/heatmap_utils.dart';

/// Custom RenderBox implementation for high-performance contribution heatmap rendering.
/// 
/// This class handles all the low-level rendering logic including:
/// - Layout calculations for the grid and labels
/// - Efficient painting of cells and text
/// - Hit testing for tap interactions
/// - Memory-efficient data management
/// 
/// The render object uses a custom layout algorithm optimized for
/// the heatmap's grid structure, minimizing recomputations and
/// providing smooth interaction even with large datasets.
class RenderContributionHeatmap extends RenderBox {
  /// Creates a new render object for the contribution heatmap.
  /// 
  /// All parameters are required and define the visual and behavioral
  /// characteristics of the heatmap.
  RenderContributionHeatmap({
    required List<ContributionEntry> entries,
    DateTime? minDate,
    DateTime? maxDate,
    required double cellSize,
    required double cellSpacing,
    required double cellRadius,
    required EdgeInsets padding,
    required bool showMonthLabels,
    required bool showWeekdayLabels,
    required TextStyle monthTextStyle,
    required TextStyle weekdayTextStyle,
    required int startWeekday,
    Color Function(int value)? colorScale,
    void Function(DateTime date, int value)? onCellTap,
    required TextScaler textScaler,
    required Locale locale,
  })  : _entries = entries,
        _minDate = minDate,
        _maxDate = maxDate,
        _cellSize = cellSize,
        _cellSpacing = cellSpacing,
        _cellRadius = cellRadius,
        _padding = padding,
        _showMonthLabels = showMonthLabels,
        _showWeekdayLabels = showWeekdayLabels,
        _monthTextStyle = monthTextStyle,
        _weekdayTextStyle = weekdayTextStyle,
        _startWeekday = startWeekday,
        _colorScale = colorScale,
        _onCellTap = onCellTap,
        _textScaler = textScaler,
        _locale = locale {
    _rebuildIndex();
    _initRecognizers();
  }

  // --- Public Properties with Smart Invalidation ---
  
  /// List of contribution entries to display.
  /// Setting this triggers a complete data rebuild and layout.
  List<ContributionEntry> _entries;
  set entries(List<ContributionEntry> value) {
    if (!identical(_entries, value)) {
      _entries = value;
      _rebuildIndex(); // Rebuild the date->value lookup map
      markNeedsLayout(); // May change the date range and grid size
    }
  }

  /// Optional minimum date for the heatmap range.
  /// If null, derived from the entries data.
  DateTime? _minDate;
  set minDate(DateTime? value) {
    if (_minDate != value) {
      _minDate = value;
      _recomputeRange(); // Recalculate the aligned date range
      markNeedsLayout(); // Grid dimensions may change
    }
  }

  /// Optional maximum date for the heatmap range.
  /// If null, derived from the entries data.
  DateTime? _maxDate;
  set maxDate(DateTime? value) {
    if (_maxDate != value) {
      _maxDate = value;
      _recomputeRange(); // Recalculate the aligned date range
      markNeedsLayout(); // Grid dimensions may change
    }
  }

  /// Size of each contribution cell in logical pixels.
  double _cellSize;
  set cellSize(double value) {
    if (_cellSize != value) {
      _cellSize = value;
      markNeedsLayout(); // Changes overall widget dimensions
    }
  }

  /// Spacing between cells in logical pixels.
  double _cellSpacing;
  set cellSpacing(double value) {
    if (_cellSpacing != value) {
      _cellSpacing = value;
      markNeedsLayout(); // Changes overall widget dimensions
    }
  }

  /// Corner radius for cell rounded rectangles.
  double _cellRadius;
  set cellRadius(double value) {
    if (_cellRadius != value) {
      _cellRadius = value;
      markNeedsPaint(); // Only affects painting, not layout
    }
  }

  /// Padding around the entire heatmap widget.
  EdgeInsets _padding;
  set padding(EdgeInsets value) {
    if (_padding != value) {
      _padding = value;
      markNeedsLayout(); // Changes overall widget dimensions
    }
  }

  /// Whether to show month labels above the heatmap.
  bool _showMonthLabels;
  set showMonthLabels(bool value) {
    if (_showMonthLabels != value) {
      _showMonthLabels = value;
      markNeedsLayout(); // Affects top label space calculation
    }
  }

  /// Whether to show weekday labels to the left of the heatmap.
  bool _showWeekdayLabels;
  set showWeekdayLabels(bool value) {
    if (_showWeekdayLabels != value) {
      _showWeekdayLabels = value;
      markNeedsLayout(); // Affects left label space calculation
    }
  }

  /// Text style for month labels.
  TextStyle _monthTextStyle;
  set monthTextStyle(TextStyle value) {
    if (_monthTextStyle != value) {
      _monthTextStyle = value;
      markNeedsLayout(); // Font size affects label space requirements
    }
  }

  /// Text style for weekday labels.
  TextStyle _weekdayTextStyle;
  set weekdayTextStyle(TextStyle value) {
    if (_weekdayTextStyle != value) {
      _weekdayTextStyle = value;
      markNeedsLayout(); // Font size affects label space requirements
    }
  }

  /// First day of the week (1=Monday, 7=Sunday).
  /// This affects how weeks are aligned in the grid.
  int _startWeekday;
  set startWeekday(int value) {
    if (_startWeekday != value) {
      _startWeekday = value;
      _recomputeRange(); // Week alignment affects the date range
      markNeedsLayout(); // Grid structure changes
    }
  }

  /// Custom color scale function for mapping values to colors.
  /// If null, uses the default GitHub-style scale.
  Color Function(int value)? _colorScale;
  set colorScale(Color Function(int value)? value) {
    if (_colorScale != value) {
      _colorScale = value;
      markNeedsPaint(); // Only affects cell colors
    }
  }

  /// Callback function for cell tap events.
  void Function(DateTime date, int value)? _onCellTap;
  set onCellTap(void Function(DateTime date, int value)? value) {
    if (_onCellTap != value) {
      _onCellTap = value;
      // No marking needed - this doesn't affect rendering
    }
  }

  /// Text scaling factor for accessibility.
  TextScaler _textScaler;
  set textScaler(TextScaler value) {
    if (_textScaler != value) {
      _textScaler = value;
      markNeedsLayout(); // Text size affects label space requirements
    }
  }

  /// Locale for text rendering and potential internationalization.
  Locale _locale;
  set locale(Locale value) {
    if (_locale != value) {
      _locale = value;
      markNeedsLayout(); // May affect text rendering
    }
  }

  // --- Internal State Management ---
  
  /// Fast lookup map from normalized dates to contribution values.
  /// Uses midnight UTC dates as keys for consistent comparison.
  late Map<DateTime, int> _valueByDate;
  
  /// First day of the aligned date range (start of the first week).
  late DateTime _firstDayAligned;
  
  /// Last day of the aligned date range (end of the last week).  
  late DateTime _lastDayAligned;
  
  /// Total number of week columns in the grid.
  int _weeks = 0;

  // --- Layout Helper Variables ---
  
  /// Width required for weekday labels (calculated during layout).
  late double _leftLabelWidth;
  
  /// Height required for month labels (calculated during layout).
  late double _topLabelHeight;

  // --- Gesture Recognition ---
  
  /// Tap gesture recognizer for handling cell interactions.
  TapGestureRecognizer? _tap;

  /// Initialize gesture recognizers for user interaction.
  /// 
  /// Sets up tap detection with proper cleanup to prevent memory leaks.
  void _initRecognizers() {
    _tap?.dispose(); // Clean up any existing recognizer
    _tap = TapGestureRecognizer(debugOwner: this)
      ..onTapUp = (details) {
        if (_onCellTap == null) return;
        
        // Convert global tap position to local coordinates
        final local = globalToLocal(details.globalPosition);
        
        // Determine which cell (if any) was tapped
        final tappedDate = _hitTestCell(local);
        if (tappedDate != null) {
          final value = _valueByDate[tappedDate] ?? 0;
          _onCellTap!.call(tappedDate, value);
        }
      };
  }

  @override
  void detach() {
    // Clean up gesture recognizers to prevent memory leaks
    _tap?.dispose();
    super.detach();
  }

  /// Rebuilds the internal date->value lookup index.
  /// 
  /// This is called whenever the entries list changes.
  /// Creates a fast HashMap for O(1) value lookups during painting.
  void _rebuildIndex() {
    _valueByDate = {
      for (final entry in _entries) 
        HeatmapUtils.dayKey(entry.date): entry.count,
    };
    _recomputeRange();
  }

  /// Recomputes the aligned date range for the heatmap grid.
  /// 
  /// Determines the first and last dates to display, aligned to week boundaries.
  /// If no explicit date range is provided, derives it from the entry data.
  void _recomputeRange() {
    // Handle empty data case - show the last year
    if (_entries.isEmpty && _minDate == null && _maxDate == null) {
      final today = DateTime.now();
      final startDate = HeatmapUtils.dayKey(today)
          .subtract(const Duration(days: 7 * 52 - 1)); // ~1 year ago
      _setAlignedRange(startDate, today);
      return;
    }

    // Determine the actual date range from data or explicit parameters
    DateTime minDate = _minDate ?? 
        _entries.map((e) => HeatmapUtils.dayKey(e.date))
               .reduce((a, b) => a.isBefore(b) ? a : b);
    
    DateTime maxDate = _maxDate ?? 
        _entries.map((e) => HeatmapUtils.dayKey(e.date))
               .reduce((a, b) => a.isAfter(b) ? a : b);
    
    _setAlignedRange(minDate, maxDate);
  }

  /// Sets the aligned date range and calculates the number of week columns.
  /// 
  /// [minDate] - The earliest date to include
  /// [maxDate] - The latest date to include
  /// 
  /// Both dates are aligned to week boundaries based on [_startWeekday].
  void _setAlignedRange(DateTime minDate, DateTime maxDate) {
    _firstDayAligned = HeatmapUtils.alignToWeekStart(minDate, _startWeekday);
    _lastDayAligned = HeatmapUtils.alignToWeekEnd(maxDate, _startWeekday);
    
    // Calculate number of complete weeks needed
    final totalDays = _lastDayAligned.difference(_firstDayAligned).inDays + 1;
    _weeks = (totalDays / 7).ceil();
  }

  // --- Layout Implementation ---

  @override
  void performLayout() {
    // Calculate space required for labels
    _leftLabelWidth = _showWeekdayLabels ? _measureWeekdayLabelsWidth() : 0;
    _topLabelHeight = _showMonthLabels ? _measureMonthLabelHeight() : 0;

    // Calculate grid dimensions
    final gridWidth = _weeks * _cellSize + math.max(0, _weeks - 1) * _cellSpacing;
    final gridHeight = 7 * _cellSize + 6 * _cellSpacing; // Always 7 rows

    // Calculate total widget size
    final desiredSize = Size(
      _padding.left + _leftLabelWidth + gridWidth + _padding.right,
      _padding.top + _topLabelHeight + gridHeight + _padding.bottom,
    );

    // Apply layout constraints
    size = constraints.constrain(desiredSize);
  }

  /// Measures the height needed for month labels.
  /// 
  /// Uses a sample text to determine the required vertical space.
  double _measureMonthLabelHeight() {
    final textPainter = TextPainter(
      text: TextSpan(text: 'MMM', style: _monthTextStyle),
      textDirection: TextDirection.ltr,
      textScaler: _textScaler,
      locale: _locale,
    )..layout();
    
    return textPainter.height + 6; // Text height + gap below labels
  }

  /// Measures the width needed for weekday labels.
  /// 
  /// Calculates the maximum width needed for any weekday abbreviation.
  double _measureWeekdayLabelsWidth() {
    final weekdayNames = HeatmapUtils.weekdayShortNames(_locale, _startWeekday);
    double maxWidth = 0;
    
    for (final name in weekdayNames) {
      final textPainter = TextPainter(
        text: TextSpan(text: name, style: _weekdayTextStyle),
        textDirection: TextDirection.ltr,
        textScaler: _textScaler,
        locale: _locale,
      )..layout();
      
      maxWidth = math.max(maxWidth, textPainter.width);
    }
    
    return maxWidth + 8; // Max text width + gap to the right
  }

  // --- Painting Implementation ---

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    
    // Calculate the origin point for the contribution grid
    final gridOrigin = offset + Offset(
      _padding.left + _leftLabelWidth, 
      _padding.top + _topLabelHeight
    );

    // Paint weekday labels on the left side
    if (_showWeekdayLabels) {
      _paintWeekdayLabels(canvas, offset, gridOrigin);
    }

    // Paint month labels at the top
    if (_showMonthLabels) {
      _paintMonthLabels(canvas, offset, gridOrigin);
    }

    // Paint the contribution cells
    _paintContributionCells(canvas, gridOrigin);
  }

  /// Paints weekday labels along the left edge of the heatmap.
  void _paintWeekdayLabels(Canvas canvas, Offset widgetOffset, Offset gridOrigin) {
    final weekdayNames = HeatmapUtils.weekdayShortNames(_locale, _startWeekday);
    
    for (int row = 0; row < 7; row++) {
      final name = weekdayNames[row];
      final textPainter = TextPainter(
        text: TextSpan(text: name, style: _weekdayTextStyle),
        textDirection: TextDirection.ltr,
        textScaler: _textScaler,
        locale: _locale,
      )..layout(maxWidth: _leftLabelWidth - 2);

      // Center the label vertically with its corresponding row
      final labelY = gridOrigin.dy + row * (_cellSize + _cellSpacing) + 
                    (_cellSize - textPainter.height) / 2;
      
      // Right-align the text in the available space
      final labelX = widgetOffset.dx + _padding.left + _leftLabelWidth - 
                     textPainter.width - 4;

      textPainter.paint(canvas, Offset(labelX, labelY));
    }
  }

  /// Paints month labels along the top edge of the heatmap.
  void _paintMonthLabels(Canvas canvas, Offset widgetOffset, Offset gridOrigin) {
    DateTime cursor = _firstDayAligned;
    int weekIndex = 0;
    int? lastLabeledMonth;

    // Iterate through each week column
    while (!cursor.isAfter(_lastDayAligned)) {
      final month = cursor.month;
      
      // Show label if this is the first week containing a new month
      final shouldShowLabel = lastLabeledMonth != month && 
                             HeatmapUtils.isFirstWeekdayOfMonth(cursor);
      
      if (shouldShowLabel) {
        final label = HeatmapUtils.monthAbbreviation(month);
        final textPainter = TextPainter(
          text: TextSpan(text: label, style: _monthTextStyle),
          textDirection: TextDirection.ltr,
          textScaler: _textScaler,
          locale: _locale,
        )..layout();

        final labelX = gridOrigin.dx + weekIndex * (_cellSize + _cellSpacing);
        final labelY = widgetOffset.dy + _padding.top;

        textPainter.paint(canvas, Offset(labelX, labelY));
        lastLabeledMonth = month;
      }
      
      cursor = cursor.add(const Duration(days: 7)); // Move to next week
      weekIndex++;
    }
  }

  /// Paints the grid of contribution cells.
  void _paintContributionCells(Canvas canvas, Offset gridOrigin) {
    // Prepare reusable objects for efficient painting
    final roundedRect = RRect.fromRectAndRadius(
      Rect.zero, 
      Radius.circular(_cellRadius)
    );
    final paint = Paint();

    // Paint each cell in the grid
    for (int week = 0; week < _weeks; week++) {
      for (int row = 0; row < 7; row++) {
        final date = _dateForCell(week, row);
        
        // Skip cells outside the valid date range
        if (date.isBefore(_firstDayAligned) || date.isAfter(_lastDayAligned)) {
          continue;
        }

        // Get contribution value and determine color
        final value = _valueByDate[date] ?? 0;
        paint.color = _colorScale?.call(value) ?? 
                     HeatmapUtils.defaultColorScale(value);

        // Calculate cell position
        final cellX = gridOrigin.dx + week * (_cellSize + _cellSpacing);
        final cellY = gridOrigin.dy + row * (_cellSize + _cellSpacing);
        final cellRect = Rect.fromLTWH(cellX, cellY, _cellSize, _cellSize);

        // Draw the rounded rectangle cell
        canvas.drawRRect(
          roundedRect.shift(cellRect.topLeft).scaleRRect(_cellSize, _cellSize),
          paint
        );
      }
    }
  }

  // --- Hit Testing Implementation ---

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void handleEvent(PointerEvent event, covariant HitTestEntry entry) {
    if (event is PointerDownEvent) {
      _tap?.addPointer(event);
    }
  }

  /// Maps a local screen coordinate to a date (if it hits a valid cell).
  /// 
  /// [localPosition] - Position relative to this widget's top-left corner
  /// 
  /// Returns the date corresponding to the tapped cell, or null if the
  /// position doesn't correspond to a valid cell.
  DateTime? _hitTestCell(Offset localPosition) {
    // Calculate grid boundaries
    final gridLeft = _padding.left + _leftLabelWidth;
    final gridTop = _padding.top + _topLabelHeight;
    
    // Convert to grid-relative coordinates
    final gridX = localPosition.dx - gridLeft;
    final gridY = localPosition.dy - gridTop;
    
    // Check if position is within grid bounds
    if (gridX < 0 || gridY < 0) return null;

    // Calculate cell dimensions including spacing
    final cellWithSpacingWidth = _cellSize + _cellSpacing;
    final cellWithSpacingHeight = _cellSize + _cellSpacing;

    // Determine which grid cell was tapped
    final week = gridX ~/ cellWithSpacingWidth;
    final row = gridY ~/ cellWithSpacingHeight;
    
    // Validate grid coordinates
    if (week < 0 || week >= _weeks || row < 0 || row >= 7) return null;

    // Check if tap is within the cell (not in spacing area)
    final withinCellX = gridX - week * cellWithSpacingWidth;
    final withinCellY = gridY - row * cellWithSpacingHeight;
    if (withinCellX > _cellSize || withinCellY > _cellSize) return null;

    // Calculate the date for this cell
    final date = _dateForCell(week, row);
    
    // Ensure date is within valid range
    if (date.isBefore(_firstDayAligned) || date.isAfter(_lastDayAligned)) {
      return null;
    }
    
    return date;
  }

  /// Computes the date represented by a specific grid cell.
  /// 
  /// [week] - Column index (0 to _weeks-1)
  /// [row] - Row index (0 to 6, representing days of the week)
  /// 
  /// Returns the date corresponding to the specified grid position.
  DateTime _dateForCell(int week, int row) {
    return _firstDayAligned.add(Duration(days: week * 7 + row));
  }
}