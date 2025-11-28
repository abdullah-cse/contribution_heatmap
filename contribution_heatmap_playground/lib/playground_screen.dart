import 'dart:async';
import 'package:contribution_heatmap/contribution_heatmap.dart';
import 'package:contribution_heatmap_playground/code_preview.dart';
import 'package:syntax_highlight/syntax_highlight.dart';
import 'random_entries.dart';
import 'package:flutter/material.dart';

class PlaygroundScreen extends StatefulWidget {
  const PlaygroundScreen({super.key});

  @override
  State<PlaygroundScreen> createState() => _PlaygroundScreenState();
}

class _PlaygroundScreenState extends State<PlaygroundScreen> {
  late List<ContributionEntry> entries;
  List<int> cellSizes = [14, 16, 18, 20, 22, 24];
  double defaultCellSize = 18;

  double cellSpacing = 4;

  List<int> cellRadius = [0, 4, 8, 10, 12, 14];
  int defaultRadius = 4;

  bool splitMonthView = false;
  bool showCellDate = false;
  bool showWeekdayLabels = true;
  bool showMonthLabels = true;
  final List<String> weekdays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun'
  ];
  int startWeekday = DateTime.monday;

  final heatMapColors = {
    Colors.blue: HeatmapColor.blue,
    Colors.green: HeatmapColor.green,
    Colors.purple: HeatmapColor.purple,
    Colors.red: HeatmapColor.red,
    Colors.orange: HeatmapColor.orange,
    Colors.teal: HeatmapColor.teal,
    Colors.pink: HeatmapColor.pink,
    Colors.indigo: HeatmapColor.indigo,
    Colors.amber: HeatmapColor.amber,
    Colors.cyan: HeatmapColor.cyan,
  };
  HeatmapColor selectedColor = HeatmapColor.green;

  late Highlighter _highlighter;
  bool _highlighterReady = false;

  @override
  void initState() {
    super.initState();
    entries = generateRandomContributionEntries();
    _initHighlighter();
  }

  Future<void> _initHighlighter() async {
    await Highlighter.initialize(['dart']);
    // ignore: use_build_context_synchronously
    final theme = await HighlighterTheme.loadForContext(context);
    _highlighter = Highlighter(language: 'dart', theme: theme);
    if (mounted) {
      setState(() {
        _highlighterReady = true;
      });
    }
  }

  String generateCodeSnippet() {
    final now = DateTime.now();
    final minDate = DateTime(now.year, now.month - 6, now.day);

    final startWeekdayLiteral = _weekdayLiteral(startWeekday);

    return '''
ContributionHeatmap(
  heatmapColor: HeatmapColor.${selectedColor.name},
  showMonthLabels: $showMonthLabels,
  showWeekdayLabels: $showWeekdayLabels,
  splittedMonthView: $splitMonthView,
  showCellDate: $showCellDate,
  startWeekday: $startWeekdayLiteral,
  cellRadius: ${defaultRadius.toDouble()},
  cellSize: ${defaultCellSize.toDouble()},
  minDate: DateTime(${minDate.year}, ${minDate.month}, ${minDate.day}),
  maxDate: DateTime.now(),
  entries: entries,
  onCellTap: (date, value) {
    print('Tapped: \$date with \$value contributions');
  },
);
''';
  }

  String _weekdayLiteral(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'DateTime.monday';
      case DateTime.tuesday:
        return 'DateTime.tuesday';
      case DateTime.wednesday:
        return 'DateTime.wednesday';
      case DateTime.thursday:
        return 'DateTime.thursday';
      case DateTime.friday:
        return 'DateTime.friday';
      case DateTime.saturday:
        return 'DateTime.saturday';
      case DateTime.sunday:
        return 'DateTime.sunday';
      default:
        return weekday.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final sideBySide = width >= 900;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Contribution Heatmap Playground'),
      ),
      body: sideBySide ? _buildSideBySide(context) : _buildStacked(context),
    );
  }

  Widget _buildSideBySide(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final codePanelWidth = (screenWidth * 0.35).clamp(320.0, screenWidth * 0.6);

    return Row(
      children: [
        // Left: preview & controls (flexible)
        Expanded(
          flex: 2,
          child: _buildLeftColumn(),
        ),

        // Right: code preview (flexible 35% of screen)
        Container(
          width: codePanelWidth,
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _highlighterReady
                ? CodePreviewPane(
                    code: generateCodeSnippet(),
                    highlighter: _highlighter,
                  )
                : const Center(child: CircularProgressIndicator()),
          ),
        ),
      ],
    );
  }

  Widget _buildStacked(BuildContext context) {
    return Column(
      children: [
        Expanded(child: _buildLeftColumn()),
        const Divider(height: 1),
        SizedBox(
          height: 320,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: _highlighterReady
                ? CodePreviewPane(
                    code: generateCodeSnippet(),
                    highlighter: _highlighter,
                  )
                : const Center(child: CircularProgressIndicator()),
          ),
        ),
      ],
    );
  }

  Widget _buildLeftColumn() {
    final now = DateTime.now();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        spacing: 6,
        children: [
          ContributionHeatmap(
            heatmapColor: selectedColor,
            showMonthLabels: showMonthLabels,
            showWeekdayLabels: showWeekdayLabels,
            splittedMonthView: splitMonthView,
            showCellDate: showCellDate,
            startWeekday: startWeekday,
            cellRadius: defaultRadius.toDouble(),
            cellSize: defaultCellSize.toDouble(),
            minDate: DateTime(now.year, now.month - 6, now.day),
            maxDate: DateTime.now(),
            entries: entries,
            onCellTap: (date, value) {
              print('Tapped: $date with $value contributions');
            },
          ),
          const Divider(),
          ListTile(title: const Text('Cell Size')),
          Wrap(
            spacing: 6,
            children: List.generate(cellSizes.length, (index) {
              final selectedSize = cellSizes[index];
              return ChoiceChip(
                label: Text('$selectedSize'),
                selected: defaultCellSize == selectedSize,
                onSelected: (_) {
                  setState(() {
                    defaultCellSize = selectedSize.toDouble();
                  });
                },
              );
            }),
          ),
          ListTile(title: const Text('Cell Radius')),
          Wrap(
            spacing: 6,
            children: List.generate(cellRadius.length, (index) {
              final selectedRadius = cellRadius[index];
              return ChoiceChip(
                label: Text('$selectedRadius'),
                selected: defaultRadius == selectedRadius,
                onSelected: (_) {
                  setState(() {
                    defaultRadius = selectedRadius;
                  });
                },
              );
            }),
          ),
          ListTile(title: const Text('Week Starts On')),
          Wrap(
            spacing: 6,
            children: List.generate(weekdays.length, (index) {
              final dayName = weekdays[index];
              final dayNumber = index + 1; // Convert to 1–7

              return ChoiceChip(
                label: Text(dayName),
                selected: startWeekday == dayNumber,
                onSelected: (_) {
                  setState(() {
                    startWeekday = dayNumber;
                  });
                },
              );
            }),
          ),
          ListTile(title: const Text('Select Heatmap Color')),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(heatMapColors.length, (index) {
              final color = heatMapColors.keys.elementAt(index);
              final colorValue = heatMapColors.values.elementAt(index);
              final isSelected = selectedColor == colorValue;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedColor = colorValue;
                  });
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: color,
                        size: 22,
                      ),
                    if (isSelected) const SizedBox(width: 6),
                    Wrap(
                      children: [
                        SizedBox.square(
                          dimension: 22,
                          child: ColoredBox(color: color.shade300),
                        ),
                        SizedBox.square(
                          dimension: 22,
                          child: ColoredBox(color: color),
                        ),
                        SizedBox.square(
                          dimension: 22,
                          child: ColoredBox(color: color.shade700),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Split Month View'),
            value: splitMonthView,
            onChanged: (v) {
              setState(() {
                splitMonthView = v;
              });
            },
          ),
          SwitchListTile(
            title: const Text('Show Cell Date'),
            value: showCellDate,
            onChanged: (v) {
              setState(() {
                showCellDate = v;
              });
            },
          ),
          SwitchListTile(
            title: const Text('Show Weekday Labels'),
            value: showWeekdayLabels,
            onChanged: (v) {
              setState(() {
                showWeekdayLabels = v;
              });
            },
          ),
          SwitchListTile(
            title: const Text('Show Month Labels'),
            value: showMonthLabels,
            onChanged: (v) {
              setState(() {
                showMonthLabels = v;
              });
            },
          ),
        ],
      ),
    );
  }
}
