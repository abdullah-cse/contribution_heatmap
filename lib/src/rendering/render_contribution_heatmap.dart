import 'dart:math' as math;
import 'package:contribution_heatmap/src/enum/heatmap_color.dart';
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
/// - Optional split month view with smart empty cell insertion
/// - Optional cell date display inside contribution cells
/// - Dynamic color scaling based on data distribution
///
/// The render object uses a custom layout algorithm optimized for
/// the heatmap's grid structure, minimizing recomputations and
/// providing smooth interaction even with large datasets.
class RenderContributionHeatmap extends RenderBox {
  /// Creates a new render object for the contribution heatmap.
  ///
  /// All visual and behavioral parameters are passed in during construction.
  /// The constructor immediately triggers data processing to prepare for rendering.
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
    required bool showCellDate,
    required TextStyle monthTextStyle,
    required TextStyle weekdayTextStyle,
    required TextStyle cellDateTextStyle,
    required int startWeekday,
    required bool splittedMonthView,
    required HeatmapColor heatmapColor,
    //Color Function(int value)? colorScale,
    void Function(DateTime date, int value)? onCellTap,
    required TextScaler textScaler,
    required Locale locale,
  }) : _entries = entries,
       _minDate = minDate,
       _maxDate = maxDate,
       _cellSize = cellSize,
       _cellSpacing = cellSpacing,
       _cellRadius = cellRadius,
       _padding = padding,
       _showMonthLabels = showMonthLabels,
       _showWeekdayLabels = showWeekdayLabels,
       _showCellDate = showCellDate,
       _monthTextStyle = monthTextStyle,
       _weekdayTextStyle = weekdayTextStyle,
       _cellDateTextStyle = cellDateTextStyle,
       _startWeekday = startWeekday,
       _splittedMonthView = splittedMonthView,
       _heatmapColor = heatmapColor,
       //_colorScale = colorScale,
       _onCellTap = onCellTap,
       _textScaler = textScaler,
       _locale = locale {
    // Initialize the data structures and prepare for rendering
    _rebuildIndex(); // Convert entries to fast lookup map
    _rebuildColorScale(); // Create dynamic color scale
    _initRecognizers(); // Set up gesture handling
  }

  // ✅ PUBLIC PROPERTIES WITH SMART INVALIDATION
  /// Each property setter includes smart invalidation - only triggering
  /// recomputation/repainting when the value actually changes, and only
  /// the minimum required operations (layout vs paint vs both).
  /// Raw contribution data entries to display in the heatmap
  List<ContributionEntry> _entries;
  set entries(List<ContributionEntry> value) {
    if (!identical(_entries, value)) {
      _entries = value;
      _rebuildIndex(); // Data changed: rebuild lookup index
      _rebuildColorScale(); // Data changed: recalculate color scale
      markNeedsLayout(); // May affect grid size and date range
    }
  }

  /// Optional explicit minimum date boundary
  /// If null, computed from entry data
  DateTime? _minDate;
  set minDate(DateTime? value) {
    if (_minDate != value) {
      _minDate = value;
      _recomputeRange(); // Date range changed: recompute all boundaries
      markNeedsLayout(); // Grid dimensions may change
    }
  }

  /// Optional explicit maximum date boundary
  /// If null, computed from entry data
  DateTime? _maxDate;
  set maxDate(DateTime? value) {
    if (_maxDate != value) {
      _maxDate = value;
      _recomputeRange(); // Date range changed: recompute all boundaries
      markNeedsLayout(); // Grid dimensions may change
    }
  }

  /// Size of each contribution cell in logical pixels
  double _cellSize;
  set cellSize(double value) {
    if (_cellSize != value) {
      _cellSize = value;
      markNeedsLayout(); // Cell size affects total widget dimensions
    }
  }

  /// Spacing between cells in logical pixels
  double _cellSpacing;
  set cellSpacing(double value) {
    if (_cellSpacing != value) {
      _cellSpacing = value;
      markNeedsLayout(); // Spacing affects total widget dimensions
    }
  }

  /// Corner radius for rounded rectangle cells
  double _cellRadius;
  set cellRadius(double value) {
    if (_cellRadius != value) {
      _cellRadius = value;
      markNeedsPaint(); // Only affects painting, not layout
    }
  }

  /// Padding around the entire heatmap widget
  EdgeInsets _padding;
  set padding(EdgeInsets value) {
    if (_padding != value) {
      _padding = value;
      markNeedsLayout(); // Padding affects total widget dimensions
    }
  }

  /// Whether to show month abbreviation labels above the grid
  bool _showMonthLabels;
  set showMonthLabels(bool value) {
    if (_showMonthLabels != value) {
      _showMonthLabels = value;
      markNeedsLayout(); // Affects top label space calculation
    }
  }

  /// Whether to show weekday abbreviation labels to the left
  bool _showWeekdayLabels;
  set showWeekdayLabels(bool value) {
    if (_showWeekdayLabels != value) {
      _showWeekdayLabels = value;
      markNeedsLayout(); // Affects left label space calculation
    }
  }

  /// Whether to show date numbers inside each contribution cell
  bool _showCellDate;
  set showCellDate(bool value) {
    if (_showCellDate != value) {
      _showCellDate = value;
      markNeedsPaint(); // Only affects cell painting, not layout
    }
  }

  /// Text style for month labels
  TextStyle _monthTextStyle;
  set monthTextStyle(TextStyle value) {
    if (_monthTextStyle != value) {
      _monthTextStyle = value;
      markNeedsLayout(); // Font size changes affect label space requirements
    }
  }

  /// Text style for weekday labels
  TextStyle _weekdayTextStyle;
  set weekdayTextStyle(TextStyle value) {
    if (_weekdayTextStyle != value) {
      _weekdayTextStyle = value;
      markNeedsLayout(); // Font size changes affect label space requirements
    }
  }

  /// Text style for date numbers displayed inside cells
  TextStyle _cellDateTextStyle;
  set cellDateTextStyle(TextStyle value) {
    if (_cellDateTextStyle != value) {
      _cellDateTextStyle = value;
      markNeedsPaint(); // Only affects cell text painting, not layout
    }
  }

  /// First day of the week (1=Monday through 7=Sunday)
  /// This determines how the grid columns are aligned with calendar weeks
  int _startWeekday;
  set startWeekday(int value) {
    if (_startWeekday != value) {
      _startWeekday = value;
      _recomputeRange(); // Week alignment affects entire date sequence
      markNeedsLayout(); // Grid structure changes completely
    }
  }

  /// Whether to add visual separation (empty columns) between months
  /// This is the core feature that creates month boundaries
  bool _splittedMonthView;
  set splittedMonthView(bool value) {
    if (_splittedMonthView != value) {
      _splittedMonthView = value;
      _rebuildDateSequence(); // Changes how dates are laid out in sequence
      markNeedsLayout(); // Grid width changes significantly
    }
  }

  // /// Custom color mapping function for contribution values
  // /// If null, uses default GitHub-style green scale
  // Color Function(int value)? _colorScale;
  // set colorScale(Color Function(int value)? value) {
  //   if (_colorScale != value) {
  //     _colorScale = value;
  //     markNeedsPaint(); // Only affects cell colors, not layout
  //   }
  // }

  /// Color scheme for the heatmap cells
  HeatmapColor _heatmapColor;
  set heatmapColor(HeatmapColor value) {
    if (_heatmapColor != value) {
      _heatmapColor = value;
      _rebuildColorScale(); // Color scheme changed: recalculate color scale
      markNeedsPaint(); // Only affects cell colors, not layout
    }
  }

  /// Callback for when user taps on a cell
  void Function(DateTime date, int value)? _onCellTap;
  set onCellTap(void Function(DateTime date, int value)? value) {
    if (_onCellTap != value) {
      _onCellTap = value;
      // No invalidation needed - this doesn't affect rendering
    }
  }

  /// Text scaling factor for accessibility support
  TextScaler _textScaler;
  set textScaler(TextScaler value) {
    if (_textScaler != value) {
      _textScaler = value;
      markNeedsLayout(); // Text scaling affects label space requirements
    }
  }

  /// Locale for text rendering and date formatting
  Locale _locale;
  set locale(Locale value) {
    if (_locale != value) {
      _locale = value;
      markNeedsLayout(); // May affect text rendering and month names
    }
  }

  // ✅ INTERNAL STATE MANAGEMENT

  /// Fast O(1) lookup map from normalized dates to contribution values.
  /// Key insight: Using normalized midnight UTC dates ensures consistent
  /// comparison regardless of timezone or time-of-day in input data.
  late Map<DateTime, int> _valueByDate;

  /// Dynamic color scale function calculated from the current data and color scheme.
  late Color Function(int value) _colorScale;

  /// Date range and sequence variables
  late DateTime _actualFirstDate;
  late DateTime _actualLastDate;
  late DateTime _firstDayAligned;
  late DateTime _lastDayAligned;
  late List<DateTime?> _dateSequence;
  int _totalColumns = 0;

  /// Layout helper variables
  late double _leftLabelWidth;
  late double _topLabelHeight;

  /// Gesture recognizer for handling tap events on cells
  TapGestureRecognizer? _tap;

  /// Initializes gesture recognition for tap handling.
  void _initRecognizers() {
    _tap?.dispose();
    _tap = TapGestureRecognizer(debugOwner: this)
      ..onTapUp = (details) {
        if (_onCellTap == null) return;
        final local = globalToLocal(details.globalPosition);
        final tappedDate = _hitTestCell(local);
        if (tappedDate != null) {
          final value = _valueByDate[tappedDate] ?? 0;
          _onCellTap!.call(tappedDate, value);
        }
      };
  }

  @override
  void detach() {
    _tap?.dispose();
    super.detach();
  }

  // ✅ DATA PROCESSING PIPELINE

  /// Converts the raw entries list into a fast lookup map.
  void _rebuildIndex() {
    _valueByDate = {
      for (final entry in _entries)
        HeatmapUtils.dayKey(entry.date): entry.count,
    };
    _recomputeRange();
  }

  /// Creates/updates the dynamic color scale function.
  void _rebuildColorScale() {
    _colorScale = HeatmapUtils.createDynamicColorScale(_entries, _heatmapColor);
  }

  /// Master orchestrator for date range computation.
  void _recomputeRange() {
    _computeActualDateRange();
    _computeAlignedDateRange();
    _rebuildDateSequence();
  }

  /// Determines the actual first and last dates from data or parameters.
  void _computeActualDateRange() {
    if (_entries.isEmpty && _minDate == null && _maxDate == null) {
      final today = DateTime.now();
      _actualLastDate = HeatmapUtils.dayKey(today);
      _actualFirstDate = _actualLastDate.subtract(const Duration(days: 365));
    } else {
      _actualFirstDate =
          _minDate ??
          _entries
              .map((e) => HeatmapUtils.dayKey(e.date))
              .reduce((a, b) => a.isBefore(b) ? a : b);

      _actualLastDate =
          _maxDate ??
          _entries
              .map((e) => HeatmapUtils.dayKey(e.date))
              .reduce((a, b) => a.isAfter(b) ? a : b);
    }
  }

  /// Computes week-aligned boundaries from the actual date range.
  void _computeAlignedDateRange() {
    _firstDayAligned = HeatmapUtils.alignToWeekStart(
      _actualFirstDate,
      _startWeekday,
    );
    _lastDayAligned = HeatmapUtils.alignToWeekEnd(
      _actualLastDate,
      _startWeekday,
    );
  }

  /// Builds the final date sequence based on split month view setting.
  void _rebuildDateSequence() {
    _dateSequence = [];

    if (!_splittedMonthView) {
      DateTime cursor = _firstDayAligned;
      while (!cursor.isAfter(_lastDayAligned)) {
        _dateSequence.add(cursor);
        cursor = cursor.add(const Duration(days: 1));
      }
    } else {
      _buildSplitMonthSequence();
    }

    _totalColumns = (_dateSequence.length / 7).ceil();
  }

  /// Builds the date sequence with intelligent month splitting.
  void _buildSplitMonthSequence() {
    _addLeadingEmptyCells();

    DateTime cursor = _actualFirstDate;
    int? previousMonth;

    while (!cursor.isAfter(_actualLastDate)) {
      final currentMonth = cursor.month;

      if (previousMonth != null && previousMonth != currentMonth) {
        _addMonthSeparator();
      }

      _dateSequence.add(cursor);
      previousMonth = currentMonth;
      cursor = cursor.add(const Duration(days: 1));
    }

    _addTrailingEmptyCells();
  }

  /// Adds empty cells before the first month if needed for week alignment.
  void _addLeadingEmptyCells() {
    final firstDayWeekPosition =
        (_actualFirstDate.weekday - _startWeekday + 7) % 7;
    for (int i = 0; i < firstDayWeekPosition; i++) {
      _dateSequence.add(null);
    }
  }

  /// Adds exactly one full week (7 empty cells) between different months.
  void _addMonthSeparator() {
    for (int i = 0; i < 7; i++) {
      _dateSequence.add(null);
    }
  }

  /// Adds empty cells after the last month if needed to complete the final week.
  void _addTrailingEmptyCells() {
    final lastDayWeekPosition =
        (_actualLastDate.weekday - _startWeekday + 7) % 7;
    final weekEndPosition = 6;

    if (lastDayWeekPosition < weekEndPosition) {
      final emptyCellsNeeded = weekEndPosition - lastDayWeekPosition;
      for (int i = 0; i < emptyCellsNeeded; i++) {
        _dateSequence.add(null);
      }
    }
  }

  // ✅ LAYOUT IMPLEMENTATION

  @override
  void performLayout() {
    _leftLabelWidth = _showWeekdayLabels ? _measureWeekdayLabelsWidth() : 0;
    _topLabelHeight = _showMonthLabels ? _measureMonthLabelHeight() : 0;

    final gridWidth =
        _totalColumns * _cellSize +
        math.max(0, _totalColumns - 1) * _cellSpacing;
    final gridHeight = 7 * _cellSize + 6 * _cellSpacing;

    final desiredSize = Size(
      _padding.left + _leftLabelWidth + gridWidth + _padding.right,
      _padding.top + _topLabelHeight + gridHeight + _padding.bottom,
    );

    size = constraints.constrain(desiredSize);
  }

  /// Measures the vertical space required for month labels.
  double _measureMonthLabelHeight() {
    final textPainter = TextPainter(
      text: TextSpan(text: 'MMM', style: _monthTextStyle),
      textDirection: TextDirection.ltr,
      textScaler: _textScaler,
      locale: _locale,
    )..layout();
    return textPainter.height + 6;
  }

  /// Measures the horizontal space required for weekday labels.
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
    return maxWidth + 8;
  }

  // ✅ PAINTING IMPLEMENTATION

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    final gridOrigin =
        offset +
        Offset(_padding.left + _leftLabelWidth, _padding.top + _topLabelHeight);

    if (_showWeekdayLabels) {
      _paintWeekdayLabels(canvas, offset, gridOrigin);
    }

    if (_showMonthLabels) {
      _paintMonthLabels(canvas, offset, gridOrigin);
    }

    _paintContributionCells(canvas, gridOrigin);
  }

  /// Paints weekday abbreviation labels along the left edge.
  void _paintWeekdayLabels(
    Canvas canvas,
    Offset widgetOffset,
    Offset gridOrigin,
  ) {
    final weekdayNames = HeatmapUtils.weekdayShortNames(_locale, _startWeekday);

    for (int row = 0; row < 7; row++) {
      final name = weekdayNames[row];
      final textPainter = TextPainter(
        text: TextSpan(text: name, style: _weekdayTextStyle),
        textDirection: TextDirection.ltr,
        textScaler: _textScaler,
        locale: _locale,
      )..layout(maxWidth: _leftLabelWidth - 2);

      final labelY =
          gridOrigin.dy +
          row * (_cellSize + _cellSpacing) +
          (_cellSize - textPainter.height) / 2;
      final labelX =
          widgetOffset.dx +
          _padding.left +
          _leftLabelWidth -
          textPainter.width -
          4;

      textPainter.paint(canvas, Offset(labelX, labelY));
    }
  }

  /// Paints month abbreviation labels above the grid.
  void _paintMonthLabels(
    Canvas canvas,
    Offset widgetOffset,
    Offset gridOrigin,
  ) {
    int? lastLabeledMonth;

    for (int column = 0; column < _totalColumns; column++) {
      DateTime? firstDateInColumn;
      for (int row = 0; row < 7; row++) {
        final index = column * 7 + row;
        if (index < _dateSequence.length && _dateSequence[index] != null) {
          firstDateInColumn = _dateSequence[index];
          break;
        }
      }

      if (firstDateInColumn == null) continue;

      final month = firstDateInColumn.month;
      final shouldShowLabel =
          lastLabeledMonth != month &&
          HeatmapUtils.isFirstWeekdayOfMonth(firstDateInColumn);

      if (shouldShowLabel) {
        final label = HeatmapUtils.monthAbbreviation(month, _locale);
        final textPainter = TextPainter(
          text: TextSpan(text: label, style: _monthTextStyle),
          textDirection: TextDirection.ltr,
          textScaler: _textScaler,
          locale: _locale,
        )..layout();

        final labelX = gridOrigin.dx + column * (_cellSize + _cellSpacing);
        final labelY = widgetOffset.dy + _padding.top;

        textPainter.paint(canvas, Offset(labelX, labelY));
        lastLabeledMonth = month;
      }
    }
  }

  /// Paints the contribution cells (the main heatmap content).
  void _paintContributionCells(Canvas canvas, Offset gridOrigin) {
    final roundedRect = RRect.fromRectAndRadius(
      Rect.zero,
      Radius.circular(_cellRadius),
    );
    final paint = Paint();

    for (int i = 0; i < _dateSequence.length; i++) {
      final date = _dateSequence[i];
      if (date == null) continue;

      final column = i ~/ 7;
      final row = i % 7;

      if (column >= _totalColumns) break;

      final value = _valueByDate[date] ?? 0;
      paint.color = _colorScale(value); // Use the dynamic color scale

      final cellX = gridOrigin.dx + column * (_cellSize + _cellSpacing);
      final cellY = gridOrigin.dy + row * (_cellSize + _cellSpacing);
      final cellRect = Rect.fromLTWH(cellX, cellY, _cellSize, _cellSize);

      canvas.drawRRect(
        roundedRect.shift(cellRect.topLeft).scaleRRect(_cellSize, _cellSize),
        paint,
      );

      if (_showCellDate) {
        _paintCellDate(canvas, date, cellRect);
      }
    }
  }

  /// Paints the date number inside a contribution cell.
  void _paintCellDate(Canvas canvas, DateTime date, Rect cellRect) {
    if (_cellSize < 10) return;

    final dateText = date.day.toString();
    final textPainter = TextPainter(
      text: TextSpan(text: dateText, style: _cellDateTextStyle),
      textDirection: TextDirection.ltr,
      textScaler: _textScaler,
      locale: _locale,
    )..layout();

    if (textPainter.width > _cellSize - 2 ||
        textPainter.height > _cellSize - 2) {
      return;
    }

    final textX = cellRect.left + (_cellSize - textPainter.width) / 2;
    final textY = cellRect.top + (_cellSize - textPainter.height) / 2;

    textPainter.paint(canvas, Offset(textX, textY));
  }

  // ✅ HIT TESTING IMPLEMENTATION

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void handleEvent(PointerEvent event, covariant HitTestEntry entry) {
    if (event is PointerDownEvent) {
      _tap?.addPointer(event);
    }
  }

  /// Converts a local screen coordinate to a date (if it hits a valid cell).
  DateTime? _hitTestCell(Offset localPosition) {
    final gridLeft = _padding.left + _leftLabelWidth;
    final gridTop = _padding.top + _topLabelHeight;

    final gridX = localPosition.dx - gridLeft;
    final gridY = localPosition.dy - gridTop;

    if (gridX < 0 || gridY < 0) return null;

    final cellWithSpacingWidth = _cellSize + _cellSpacing;
    final cellWithSpacingHeight = _cellSize + _cellSpacing;

    final column = gridX ~/ cellWithSpacingWidth;
    final row = gridY ~/ cellWithSpacingHeight;

    if (column < 0 || column >= _totalColumns || row < 0 || row >= 7) {
      return null;
    }

    final withinCellX = gridX - column * cellWithSpacingWidth;
    final withinCellY = gridY - row * cellWithSpacingHeight;

    if (withinCellX > _cellSize || withinCellY > _cellSize) return null;

    final index = column * 7 + row;

    if (index >= _dateSequence.length || _dateSequence[index] == null) {
      return null;
    }

    return _dateSequence[index];
  }
}
