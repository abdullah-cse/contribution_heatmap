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
/// - Optional split month view with smart empty cell insertion
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
    required TextStyle monthTextStyle,
    required TextStyle weekdayTextStyle,
    required int startWeekday,
    required bool splittedMonthView,
    Color Function(int value)? colorScale,
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
       _monthTextStyle = monthTextStyle,
       _weekdayTextStyle = weekdayTextStyle,
       _startWeekday = startWeekday,
       _splittedMonthView = splittedMonthView,
       _colorScale = colorScale,
       _onCellTap = onCellTap,
       _textScaler = textScaler,
       _locale = locale {
    // Initialize the data structures and prepare for rendering
    _rebuildIndex(); // Convert entries to fast lookup map
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

  /// Custom color mapping function for contribution values
  /// If null, uses default GitHub-style green scale
  Color Function(int value)? _colorScale;
  set colorScale(Color Function(int value)? value) {
    if (_colorScale != value) {
      _colorScale = value;
      markNeedsPaint(); // Only affects cell colors, not layout
    }
  }

  /// Callback for when user taps on a cell
  /// Receives the date and contribution value for that cell
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

  /// The actual first date from the data or explicit minDate parameter.
  /// This is NOT aligned to week boundaries - it's the real data boundary.
  /// Example: If data starts Jan 15, this is Jan 15 (not the Monday of that week).
  late DateTime _actualFirstDate;

  /// The actual last date from the data or explicit maxDate parameter.
  /// This is NOT aligned to week boundaries - it's the real data boundary.
  /// Example: If data ends Dec 20, this is Dec 20 (not the Sunday of that week).
  late DateTime _actualLastDate;

  /// First day of the overall date range, aligned to week boundaries.
  /// This ensures the grid starts on the correct weekday.
  /// Example: If _actualFirstDate is Jan 15 (Wed) and week starts Monday,
  /// this would be Jan 13 (the Monday of that week).
  late DateTime _firstDayAligned;

  /// Last day of the overall date range, aligned to week boundaries.
  /// This ensures the grid ends on the correct weekday.
  /// Example: If _actualLastDate is Dec 20 (Fri) and week starts Monday,
  /// this would be Dec 22 (the Sunday of that week).
  late DateTime _lastDayAligned;

  /// The core data structure: sequential list representing exactly what gets rendered.
  ///
  /// Each element is either:
  /// - DateTime: A real date that gets painted as a contribution cell
  /// - null: An empty space (for month separators or week alignment)
  ///
  /// The index in this list directly corresponds to grid position:
  /// - column = index ~/ 7
  /// - row = index % 7
  ///
  /// This makes painting and hit testing extremely efficient.
  late List<DateTime?> _dateSequence;

  /// Total number of columns in the final rendered grid.
  /// Calculated as (_dateSequence.length / 7).ceil() since each column has 7 rows.
  int _totalColumns = 0;

  // ✅ LAYOUT HELPER VARIABLES

  /// Width required for weekday labels (measured during layout)
  late double _leftLabelWidth;

  /// Height required for month labels (measured during layout)
  late double _topLabelHeight;

  // ✅ GESTURE RECOGNITION SETUP

  /// Gesture recognizer for handling tap events on cells
  TapGestureRecognizer? _tap;

  /// Initializes gesture recognition for tap handling.
  /// Sets up proper cleanup to prevent memory leaks.
  void _initRecognizers() {
    _tap?.dispose(); // Clean up any existing recognizer
    _tap = TapGestureRecognizer(debugOwner: this)
      ..onTapUp = (details) {
        // Only process taps if there's a callback registered
        if (_onCellTap == null) return;

        // Convert global tap position to local widget coordinates
        final local = globalToLocal(details.globalPosition);

        // Determine which date (if any) was tapped
        final tappedDate = _hitTestCell(local);
        if (tappedDate != null) {
          // Look up the contribution value for that date
          final value = _valueByDate[tappedDate] ?? 0;
          _onCellTap!.call(tappedDate, value);
        }
      };
  }

  @override
  void detach() {
    // Essential cleanup to prevent memory leaks when widget is removed
    _tap?.dispose();
    super.detach();
  }

  // ✅ DATA PROCESSING PIPELINE

  /// Step 1: Converts the raw entries list into a fast lookup map.
  ///
  /// This is called whenever the entries data changes. Creates a HashMap
  /// for O(1) value lookups during painting, which is crucial for performance
  /// when rendering thousands of cells.
  ///
  /// Key normalization ensures consistent date comparison regardless of
  /// timezone or time-of-day variations in the input data.
  void _rebuildIndex() {
    _valueByDate = {
      for (final entry in _entries)
        HeatmapUtils.dayKey(entry.date): entry.count,
    };
    // Trigger the rest of the processing pipeline
    _recomputeRange();
  }

  /// Step 2: Master orchestrator for date range computation.
  ///
  /// This method coordinates the entire date processing pipeline:
  /// 1. Determines actual date boundaries from data
  /// 2. Computes week-aligned boundaries for grid layout
  /// 3. Builds the final date sequence with smart month splitting
  void _recomputeRange() {
    _computeActualDateRange(); // Step 2a: Find real data boundaries
    _computeAlignedDateRange(); // Step 2b: Align to week boundaries
    _rebuildDateSequence(); // Step 2c: Create final layout sequence
  }

  /// Step 2a: Determines the actual first and last dates from data or parameters.
  ///
  /// Priority order:
  /// 1. Explicit minDate/maxDate parameters (if provided)
  /// 2. Computed from entries data (earliest/latest dates)
  /// 3. Default fallback (last year from today) if no data
  ///
  /// These represent the real data boundaries, NOT week-aligned boundaries.
  void _computeActualDateRange() {
    if (_entries.isEmpty && _minDate == null && _maxDate == null) {
      // Fallback case: No data and no explicit range
      // Show approximately one year ending today
      final today = DateTime.now();
      _actualLastDate = HeatmapUtils.dayKey(today);
      _actualFirstDate = _actualLastDate.subtract(const Duration(days: 365));
    } else {
      // Normal case: Use explicit parameters or derive from data
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

  /// Step 2b: Computes week-aligned boundaries from the actual date range.
  ///
  /// The grid must start and end on correct weekdays to maintain proper
  /// column alignment. This expands the actual date range to encompass
  /// complete weeks.
  ///
  /// Example: If actual range is Jan 15 (Wed) to Dec 20 (Fri)
  /// and weeks start on Monday, this creates:
  /// - _firstDayAligned = Jan 13 (Monday of Jan 15's week)
  /// - _lastDayAligned = Dec 22 (Sunday of Dec 20's week)
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

  /// Step 2c: Builds the final date sequence based on split month view setting.
  ///
  /// This creates the _dateSequence that directly represents what gets rendered.
  /// The sequence includes both real dates and null values for empty spaces.
  void _rebuildDateSequence() {
    _dateSequence = [];

    if (!_splittedMonthView) {
      // Simple case: Continuous sequence from aligned start to aligned end
      // Every day gets rendered as a cell, no gaps or separators
      DateTime cursor = _firstDayAligned;
      while (!cursor.isAfter(_lastDayAligned)) {
        _dateSequence.add(cursor);
        cursor = cursor.add(const Duration(days: 1));
      }
    } else {
      // Complex case: Smart month splitting with minimal empty spaces
      _buildSplitMonthSequence();
    }

    // Calculate how many columns we'll need to display this sequence
    // Since each column has 7 rows, we divide by 7 and round up
    _totalColumns = (_dateSequence.length / 7).ceil();
  }

  /// Builds the date sequence with intelligent month splitting.
  ///
  /// This is the core algorithm for split month view. It creates a sequence
  /// that includes:
  /// 1. Minimal leading empty cells (only if first date doesn't align with week start)
  /// 2. All actual dates with full 7-cell separators between months
  /// 3. Minimal trailing empty cells (only if last date doesn't end on week end)
  ///
  /// The goal is optimal space usage while maintaining clear month boundaries.
  void _buildSplitMonthSequence() {
    // Phase 1: Add leading empty cells if the first month doesn't start
    // on the week start day. This ensures proper week alignment.
    _addLeadingEmptyCells();

    // Phase 2: Add all actual dates with month separators
    // This is the main content of the heatmap
    DateTime cursor = _actualFirstDate;
    int? previousMonth;

    while (!cursor.isAfter(_actualLastDate)) {
      final currentMonth = cursor.month;

      // Insert a visual separator when we encounter a new month
      // (except for the very first month, which has no predecessor)
      if (previousMonth != null && previousMonth != currentMonth) {
        _addMonthSeparator();
      }

      // Add the actual date to the sequence
      _dateSequence.add(cursor);
      previousMonth = currentMonth;
      cursor = cursor.add(const Duration(days: 1));
    }

    // Phase 3: Add trailing empty cells if the last month doesn't end
    // on the week end day. This completes the final week.
    _addTrailingEmptyCells();
  }

  /// Adds empty cells before the first month if needed for week alignment.
  ///
  /// Example: If first date is Jan 3 (Wednesday) and week starts on Monday:
  /// - Week positions: Mon=0, Tue=1, Wed=2, Thu=3, Fri=4, Sat=5, Sun=6
  /// - Jan 3 is at position 2, so we need 2 empty cells for positions 0,1
  /// - Result: [null, null, Jan3, Jan4, Jan5, Jan6, Jan7]
  ///
  /// If first date already aligns with week start (position 0), no empty
  /// cells are added.
  void _addLeadingEmptyCells() {
    final firstDayWeekPosition =
        (_actualFirstDate.weekday - _startWeekday + 7) % 7;
    // Only add empty cells if we're not already at the start of the week
    for (int i = 0; i < firstDayWeekPosition; i++) {
      _dateSequence.add(null);
    }
  }

  /// Adds exactly one full week (7 empty cells) between different months.
  ///
  /// This creates clear visual separation between months while maintaining
  /// the grid structure. The 7-cell gap ensures month boundaries are obvious
  /// even in dense contribution data.
  void _addMonthSeparator() {
    for (int i = 0; i < 7; i++) {
      _dateSequence.add(null);
    }
  }

  /// Adds empty cells after the last month if needed to complete the final week.
  ///
  /// Example: If last date is Dec 20 (Friday) and week starts on Monday:
  /// - Week positions: Mon=0, Tue=1, Wed=2, Thu=3, Fri=4, Sat=5, Sun=6
  /// - Dec 20 is at position 4, so we need 2 empty cells for positions 5,6
  /// - Result: [Dec16, Dec17, Dec18, Dec19, Dec20, null, null]
  ///
  /// If last date already ends on the week end (position 6), no empty
  /// cells are added.
  void _addTrailingEmptyCells() {
    final lastDayWeekPosition =
        (_actualLastDate.weekday - _startWeekday + 7) % 7;
    final weekEndPosition = 6; // Last position in a week (0-indexed)

    // Only add empty cells if we haven't reached the end of the week yet
    if (lastDayWeekPosition < weekEndPosition) {
      final emptyCellsNeeded = weekEndPosition - lastDayWeekPosition;
      for (int i = 0; i < emptyCellsNeeded; i++) {
        _dateSequence.add(null);
      }
    }
  }

  // ✅ LAYOUT IMPLEMENTATION

  /// Calculates the required size for the entire widget.
  ///
  /// Layout process:
  /// 1. Measure space needed for labels (if enabled)
  /// 2. Calculate grid dimensions based on cell count and spacing
  /// 3. Add padding to get total widget size
  /// 4. Apply parent constraints to get final size
  @override
  void performLayout() {
    // Step 1: Measure label space requirements
    _leftLabelWidth = _showWeekdayLabels ? _measureWeekdayLabelsWidth() : 0;
    _topLabelHeight = _showMonthLabels ? _measureMonthLabelHeight() : 0;

    // Step 2: Calculate core grid dimensions
    // Grid width = (columns * cell_size) + (spacing_between_columns)
    final gridWidth =
        _totalColumns * _cellSize +
        math.max(0, _totalColumns - 1) * _cellSpacing;
    // Grid height = (7_rows * cell_size) + (spacing_between_rows)
    final gridHeight = 7 * _cellSize + 6 * _cellSpacing;

    // Step 3: Calculate total widget size including padding and labels
    final desiredSize = Size(
      _padding.left + _leftLabelWidth + gridWidth + _padding.right,
      _padding.top + _topLabelHeight + gridHeight + _padding.bottom,
    );

    // Step 4: Apply parent layout constraints
    size = constraints.constrain(desiredSize);
  }

  /// Measures the vertical space required for month labels.
  ///
  /// Uses a representative text sample to determine height requirements.
  /// Includes a small gap below the labels for visual separation.
  double _measureMonthLabelHeight() {
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'MMM',
        style: _monthTextStyle,
      ), // Sample month abbrev
      textDirection: TextDirection.ltr,
      textScaler: _textScaler,
      locale: _locale,
    )..layout();
    return textPainter.height + 6; // Text height + visual gap
  }

  /// Measures the horizontal space required for weekday labels.
  ///
  /// Calculates the maximum width needed by any weekday abbreviation
  /// to ensure all labels fit comfortably.
  double _measureWeekdayLabelsWidth() {
    final weekdayNames = HeatmapUtils.weekdayShortNames(_locale, _startWeekday);
    double maxWidth = 0;

    // Find the widest weekday label
    for (final name in weekdayNames) {
      final textPainter = TextPainter(
        text: TextSpan(text: name, style: _weekdayTextStyle),
        textDirection: TextDirection.ltr,
        textScaler: _textScaler,
        locale: _locale,
      )..layout();
      maxWidth = math.max(maxWidth, textPainter.width);
    }
    return maxWidth + 8; // Max text width + visual gap to grid
  }

  // ✅ PAINTING IMPLEMENTATION

  /// Main painting method that orchestrates all visual rendering.
  ///
  /// Painting order is important for proper layering:
  /// 1. Weekday labels (leftmost, behind grid)
  /// 2. Month labels (topmost, behind grid)
  /// 3. Contribution cells (foreground, main content)
  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;

    // Calculate where the contribution grid starts
    // This accounts for padding and label space
    final gridOrigin =
        offset +
        Offset(_padding.left + _leftLabelWidth, _padding.top + _topLabelHeight);

    // Paint labels first (they go behind the grid visually)
    if (_showWeekdayLabels) {
      _paintWeekdayLabels(canvas, offset, gridOrigin);
    }

    if (_showMonthLabels) {
      _paintMonthLabels(canvas, offset, gridOrigin);
    }

    // Paint the main content (contribution cells)
    _paintContributionCells(canvas, gridOrigin);
  }

  /// Paints weekday abbreviation labels along the left edge.
  ///
  /// Each label is positioned to align with its corresponding row in the grid.
  /// Labels are right-aligned in the available space for clean appearance.
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
      )..layout(maxWidth: _leftLabelWidth - 2); // Leave small margin

      // Center the label vertically with its corresponding grid row
      final labelY =
          gridOrigin.dy +
          row * (_cellSize + _cellSpacing) +
          (_cellSize - textPainter.height) / 2;

      // Right-align the text within the available label space
      final labelX =
          widgetOffset.dx +
          _padding.left +
          _leftLabelWidth -
          textPainter.width -
          4; // 4px gap from grid

      textPainter.paint(canvas, Offset(labelX, labelY));
    }
  }

  /// Paints month abbreviation labels above the grid.
  ///
  /// Labels appear above the first week of each new month. The algorithm
  /// scans each column to find the first valid date and checks if it
  /// represents a new month that should get a label.
  void _paintMonthLabels(
    Canvas canvas,
    Offset widgetOffset,
    Offset gridOrigin,
  ) {
    int? lastLabeledMonth;

    // Scan each column in the grid
    for (int column = 0; column < _totalColumns; column++) {
      // Find the first valid (non-null) date in this column
      DateTime? firstDateInColumn;
      for (int row = 0; row < 7; row++) {
        final index = column * 7 + row;
        if (index < _dateSequence.length && _dateSequence[index] != null) {
          firstDateInColumn = _dateSequence[index];
          break;
        }
      }

      // Skip columns that contain only empty cells (month separators)
      if (firstDateInColumn == null) continue;

      final month = firstDateInColumn.month;

      // Show a label if this is the first column containing a new month
      // and the date qualifies as a "first weekday of the month"
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

        // Position the label above this column
        final labelX = gridOrigin.dx + column * (_cellSize + _cellSpacing);
        final labelY = widgetOffset.dy + _padding.top;

        textPainter.paint(canvas, Offset(labelX, labelY));
        lastLabeledMonth = month;
      }
    }
  }

  /// Paints the contribution cells (the main heatmap content).
  ///
  /// This iterates through the date sequence and paints each valid date
  /// as a colored rounded rectangle. Empty cells (nulls) are skipped.
  ///
  /// Performance optimization: Reuses paint objects to minimize allocations.
  void _paintContributionCells(Canvas canvas, Offset gridOrigin) {
    // Prepare reusable objects for efficient painting
    final roundedRect = RRect.fromRectAndRadius(
      Rect.zero,
      Radius.circular(_cellRadius),
    );
    final paint = Paint();

    // Paint each cell in the date sequence
    for (int i = 0; i < _dateSequence.length; i++) {
      final date = _dateSequence[i];

      // Skip empty cells (month separators or alignment spaces)
      if (date == null) continue;

      // Calculate grid position from sequence index
      final column = i ~/ 7; // Integer division for column
      final row = i % 7; // Remainder for row

      // Safety check: don't paint beyond our calculated columns
      if (column >= _totalColumns) break;

      // Look up contribution value and determine color
      final value = _valueByDate[date] ?? 0;
      paint.color =
          _colorScale?.call(value) ?? HeatmapUtils.defaultColorScale(value);

      // Calculate pixel position for this cell
      final cellX = gridOrigin.dx + column * (_cellSize + _cellSpacing);
      final cellY = gridOrigin.dy + row * (_cellSize + _cellSpacing);
      final cellRect = Rect.fromLTWH(cellX, cellY, _cellSize, _cellSize);

      // Draw the rounded rectangle cell
      canvas.drawRRect(
        roundedRect.shift(cellRect.topLeft).scaleRRect(_cellSize, _cellSize),
        paint,
      );
    }
  }

  // ✅ HIT TESTING IMPLEMENTATION

  /// Indicates this widget should receive hit test events.
  /// This enables tap detection on the heatmap.
  @override
  bool hitTestSelf(Offset position) => true;

  /// Handles pointer events and forwards tap events to the gesture recognizer.
  @override
  void handleEvent(PointerEvent event, covariant HitTestEntry entry) {
    if (event is PointerDownEvent) {
      _tap?.addPointer(event);
    }
  }

  /// Converts a local screen coordinate to a date (if it hits a valid cell).
  ///
  /// This performs the reverse calculation of the painting process:
  /// 1. Convert screen coordinates to grid coordinates
  /// 2. Calculate which column and row were tapped
  /// 3. Verify the tap is within cell bounds (not in spacing areas)
  /// 4. Map grid position back to date sequence index
  /// 5. Return the corresponding date (or null if invalid)
  ///
  /// Returns null for:
  /// - Taps outside the grid area
  /// - Taps in spacing between cells
  /// - Taps on empty cells (month separators)
  /// - Taps beyond the valid date range
  DateTime? _hitTestCell(Offset localPosition) {
    // Step 1: Calculate grid boundaries within the widget
    final gridLeft = _padding.left + _leftLabelWidth;
    final gridTop = _padding.top + _topLabelHeight;

    // Step 2: Convert widget-relative coordinates to grid-relative coordinates
    final gridX = localPosition.dx - gridLeft;
    final gridY = localPosition.dy - gridTop;

    // Step 3: Early exit if tap is outside the grid area
    if (gridX < 0 || gridY < 0) return null;

    // Step 4: Calculate cell dimensions including spacing
    // Each "cell unit" includes the cell itself plus spacing to the next cell
    final cellWithSpacingWidth = _cellSize + _cellSpacing;
    final cellWithSpacingHeight = _cellSize + _cellSpacing;

    // Step 5: Determine which grid cell was tapped
    final column = gridX ~/ cellWithSpacingWidth; // Integer division
    final row = gridY ~/ cellWithSpacingHeight;

    // Step 6: Validate grid coordinates are within bounds
    if (column < 0 || column >= _totalColumns || row < 0 || row >= 7) {
      return null;
    }

    // Step 7: Check if tap is within the actual cell (not in spacing area)
    // Calculate position within the cell unit
    final withinCellX = gridX - column * cellWithSpacingWidth;
    final withinCellY = gridY - row * cellWithSpacingHeight;

    // Reject taps that fall in the spacing areas between cells
    if (withinCellX > _cellSize || withinCellY > _cellSize) return null;

    // Step 8: Convert grid position to date sequence index
    final index = column * 7 + row;

    // Step 9: Validate index and ensure it represents a real date
    if (index >= _dateSequence.length || _dateSequence[index] == null) {
      return null; // Empty cell or out of bounds
    }

    // Step 10: Return the date for this cell
    return _dateSequence[index];
  }
}
