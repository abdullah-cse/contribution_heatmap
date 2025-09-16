# Contribution Heatmap

[![License: BSD-3-Clause](https://badgen.net/static/license/BSD-3-Clause/blue)](https://opensource.org/licenses/BSD-3-Clause) [![Pub Version](https://badgen.net/pub/v/contribution_heatmap)](https://pub.dev/packages/contribution_heatmap/versions) [![Pub Likes](https://badgen.net/pub/likes/contribution_heatmap)](https://pub.dev/packages/contribution_heatmap/score) [![Pub Monthly Downloads](https://badgen.net/pub/dm/contribution_heatmap?color=purple)](https://pub.dev/packages/contribution_heatmap/score)
[![Github Stars](https://badgen.net/github/stars/abdullah-cse/contribution_heatmap?icon=github)](https://github.com/abdullah-cse/contribution_heatmap/stargazers) [![Github Open Isssues](https://badgen.net/github/open-issues/abdullah-cse/contribution_heatmap/?icon=github)](https://github.com/abdullah-cse/contribution_heatmap/issues) [![Github Pull Request](https://badgen.net/github/open-prs/abdullah-cse/contribution_heatmap/?icon=github)](https://github.com/abdullah-cse/contribution_heatmap/pulls) [![Github Last Commit](https://badgen.net/github/last-commit/abdullah-cse/contribution_heatmap/?icon=github)](https://github.com/abdullah-cse/contribution_heatmap/commits/main/)
[![X (formerly Twitter) Follow](https://badgen.net/static/Follow/@abdullahPBD/black?icon=twitter)](https://x.com/abdullahPDB)


A high-performance, GitHub-like contribution heatmap widget for Flutter. This widget provides a visual representation of contribution data over time, similar to GitHub's contribution graph with proper i18n support.

![Contribution Heatmap Rounded Cell](/example/heatmap_macos_rounded.png)
![Contribution Heatmap](/example/heatmap_macos.png)

## ✨ Features

- **🚀 Ultra-High Performance**: Custom RenderBox implementation with optimized rendering pipeline
- **👆 Interactive**: Full tap support with proper hit testing and gesture handling
- **🎨 Fully Customizable**: Colors, sizing, labels, and layout options
- **♿ Accessibility Ready**: Supports text scaling and high contrast modes
- **🌍 Internationalized**: Locale-aware text rendering with customizable start weekdays  
- **💾 Memory Efficient**: Optimized data structures minimize memory usage and GC pressure
- **🔧 Smart Invalidation**: Only recomputes what's needed, not on every frame


## 🚀 Quick Start

### Basic Usage

```dart
import 'package:flutter/material.dart';
import 'package:contribution_heatmap/contribution_heatmap.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ContributionHeatmap(
      entries: [
        ContributionEntry(DateTime(2025, 8, 15), 5),
        ContributionEntry(DateTime(2025, 8, 16), 3),
        ContributionEntry(DateTime(2025, 8, 17), 8),
        // Add more entries...
      ],
      onCellTap: (date, value) {
        print('Tapped: $date with $value contributions');
      },
    );
  }
}
```

### Advanced Usage

```dart
ContributionHeatmap(
  entries: myContributionData,
  
  // Custom date range
  minDate: DateTime(2025, 1, 1),
  maxDate: DateTime.now(),
  
  // Visual customization
  cellSize: 14.0,
  cellSpacing: 4.0,
  cellRadius: 3.0,
  padding: EdgeInsets.all(20),
  
  // Custom color scale
  colorScale: (value) {
    if (value == 0) return Colors.grey[100]!;
    if (value <= 2) return Colors.green[200]!;
    if (value <= 5) return Colors.green[400]!;
    return Colors.green[600]!;
  },
  
  // Custom text styles
  monthTextStyle: TextStyle(
    color: Colors.grey[600],
    fontSize: 12,
    fontWeight: FontWeight.w500,
  ),
  weekdayTextStyle: TextStyle(
    color: Colors.grey[500],
    fontSize: 11,
  ),
  
  // Week starts on Sunday (US style)
  startWeekday: DateTime.sunday,
  
  // Handle cell interactions
  onCellTap: (date, value) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${date.toIso8601String().split('T')[0]}'),
        content: Text('$value contributions on this date'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  },
)
```

## 📊 Data Model

### ContributionEntry

The Data structure for contribution data:

```dart
class ContributionEntry {
  final DateTime date;  // Day-level precision
  final int count;      // Number of contributions (>= 0)
  const ContributionEntry(this.date, this.count);
}
```
## 🌍 i18n Support
Currently, this package supports English (EN) and
- 🇫🇷 French (fr-FR)
- 🇩🇪 German (de-DE)
- 🇪🇸 Spanish (es-ES)

More languages will be added soon.

Exemple de Contribution Heatmap en français (fr-FR)
![Exemple de Contribution Heatmap en français (fr-FR)](/example/fr-FR.png)

## 🎨 Customization Options

### Visual Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `cellSize` | `double` | `12.0` | Size of each contribution cell |
| `cellSpacing` | `double` | `3.0` | Spacing between cells |
| `cellRadius` | `double` | `2.0` | Corner radius for rounded cells |
| `padding` | `EdgeInsets` | `EdgeInsets.all(16)` | Outer padding around widget |

### Labels & Text

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `showMonthLabels` | `bool` | `true` | Show month names above the heatmap |
| `showWeekdayLabels` | `bool` | `true` | Show day names on the left |
| `monthTextStyle` | `TextStyle?` | `null` | Custom style for month labels |
| `weekdayTextStyle` | `TextStyle?` | `null` | Custom style for weekday labels |

### Date & Layout

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `minDate` | `DateTime?` | `null` | Override minimum date (auto-calculated if null) |
| `maxDate` | `DateTime?` | `null` | Override maximum date (auto-calculated if null) |
| `startWeekday` | `int` | `DateTime.monday` | First day of week (1=Mon, 7=Sun) |

### Colors & Interaction

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `colorScale` | `Color Function(int)?` | `null` | Custom color mapping function |
| `onCellTap` | `void Function(DateTime, int)?` | `null` | Callback for cell tap events |


## ⚡ Performance Characteristics

### Rendering Performance
- **O(1)** cell value lookups during painting
- **Custom RenderBox** implementation bypasses widget rebuilds
- **Smart invalidation** - only recomputes when properties actually change
- **Efficient hit testing** with proper bounds checking

### Memory Efficiency
- **HashMap-based** data structure for fast lookups
- **Minimal object allocation** during painting
- **Proper gesture recognizer cleanup** prevents memory leaks
- **Optimized text rendering** with cached TextPainter objects

### Scalability
- Handles **thousands of data points** efficiently
- **Constant time complexity** for cell rendering
- **Responsive layout** adapts to available space
- **Smooth interactions** even with large datasets

## 📝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.