# Contribution Heatmap

[![License: BSD-3-Clause](https://badgen.net/static/license/BSD-3-Clause/blue)](https://opensource.org/licenses/BSD-3-Clause) [![Pub Version](https://badgen.net/pub/v/contribution_heatmap)](https://pub.dev/packages/contribution_heatmap/versions) [![Pub Likes](https://badgen.net/pub/likes/contribution_heatmap)](https://pub.dev/packages/contribution_heatmap/score) [![Pub Monthly Downloads](https://badgen.net/pub/dm/contribution_heatmap?color=purple)](https://pub.dev/packages/contribution_heatmap/score)
[![Github Stars](https://badgen.net/github/stars/abdullah-cse/contribution_heatmap?icon=github)](https://github.com/abdullah-cse/contribution_heatmap/stargazers) [![Github Open Isssues](https://badgen.net/github/open-issues/abdullah-cse/contribution_heatmap/?icon=github)](https://github.com/abdullah-cse/contribution_heatmap/issues) [![Github Pull Request](https://badgen.net/github/open-prs/abdullah-cse/contribution_heatmap/?icon=github)](https://github.com/abdullah-cse/contribution_heatmap/pulls) [![Github Last Commit](https://badgen.net/github/last-commit/abdullah-cse/contribution_heatmap/?icon=github)](https://github.com/abdullah-cse/contribution_heatmap/commits/main/)
[![X (formerly Twitter) Follow](https://badgen.net/static/Follow/@abdullahPBD/blue?icon=twitter)](https://x.com/abdullahPDB)



A high-performance, GitHub-like contribution heatmap widget for Flutter. This widget provides a visual representation of contribution data over time, similar to GitHub's contribution graph with proper i18n support and intelligent month separation.

![Contribution Heatmap minimal Screenshot](/example/screenshots/contribution_heatmap_minial.png)
![Contribution Heatmap with splittdMonthView and showDate](/example/screenshots/splitMonthViewWithDate.png)

## ✨ Features

- **🚀 Ultra-High Performance**: Custom RenderBox implementation with optimized rendering pipeline
- **👆 Interactive**: Full tap support with proper hit testing and gesture handling
- **🎨 Fully Customizable**: Colors, sizing, labels, and layout options
- **📅 Split Month View**: Visual month separation with intelligent empty cell insertion
- **📊 Cell Date Display**: NEW! Show day numbers inside contribution cells
- **♿ Accessibility Ready**: Supports text scaling and high contrast modes
- **🌍 Internationalized**: Locale-aware text rendering with customizable start weekdays  
- **💾 Memory Efficient**: Optimized data structures minimize memory usage and GC pressure
- **🔧 Smart Invalidation**: Only recomputes what's needed, not on every frame

## Visual Playground
Visit our [Visual Playground](https://ch.abdullah.com.bd) Website, play with ContributionHeatmap, Copy the generated code, and seamlessly integrate them into your project. This is the quickest way! 🥰

![ContributionHeatmap Playground](/example/screenshots/ch_playground.png)


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
        ContributionEntry(DateTime(2025, 11, 15), 5),
        ContributionEntry(DateTime(2025, 11, 16), 3),
        ContributionEntry(DateTime(2025, 11, 17), 8),
        // Add more entries...
      ],
      onCellTap: (date, value) {
        print('Tapped: $date with $value contributions');
      },
    );
  }
}
```

### 📅 Split Month View

Enable clear visual separation between months with intelligent spacing:

```dart
ContributionHeatmap(
  entries: myContributionData,
  splittedMonthView: true, // Adds visual gaps between months
  onCellTap: (date, value) {
    print('Tapped: $date with $value contributions');
  },
)
```


### Cell Date Display (NEW!)

Show day numbers inside each contribution cell for easier date identification:

```dart
ContributionHeatmap(
  entries: myContributionData,
  showCellDate: true, // Show date numbers inside cells
  cellSize: 16.0, // Larger cells work better with text
  cellDateTextStyle: TextStyle(
    fontSize: 8,
    color: Colors.white,
    fontWeight: FontWeight.bold,
  ),
  onCellTap: (date, value) {
    print('$date: $value contributions');
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
![Exemple de Contribution Heatmap en français (fr-FR)](/example/screenshots/fr-FR.png)

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
| `showCellDate` | `bool` | `false` |  Show date numbers inside cells |
| `cellDateTextStyle` | `TextStyle?` | `null` | Custom style for cell date numbers |
| `monthTextStyle` | `TextStyle?` | `null` | Custom style for month labels |
| `weekdayTextStyle` | `TextStyle?` | `null` | Custom style for weekday labels |


### Date & Layout

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `minDate` | `DateTime?` | `null` | Override minimum date (auto-calculated if null) |
| `maxDate` | `DateTime?` | `null` | Override maximum date (auto-calculated if null) |
| `startWeekday` | `int` | `DateTime.monday` | First day of week (1=Mon, 7=Sun) |
| `splittedMonthView` | `bool` | `false` |  Enable visual month separation |

### Colors & Interaction

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `heatmapColor` | `HeatmapColor` | `green` | **NEW!** Available color schemes for the contribution heatmap. |
| `onCellTap` | `void Function(DateTime, int)?` | `null` | Callback for cell tap events |

## ⚡ Performance Characteristics

### Rendering Performance
- **O(1)** cell value lookups during painting
- **Custom RenderBox** implementation bypasses widget rebuilds
- **Smart invalidation** - only recomputes when properties actually change
- **Efficient hit testing** with proper bounds checking
- **Optimized split month rendering** with minimal computational overhead
- **Intelligent cell date rendering** with automatic size detection

### Memory Efficiency
- **HashMap-based** data structure for fast lookups
- **Minimal object allocation** during painting
- **Proper gesture recognizer cleanup** prevents memory leaks
- **Optimized text rendering** with cached TextPainter objects
- **Linear date sequence** for efficient split month calculations

### Scalability
- Handles **thousands of data points** efficiently
- **Constant time complexity** for cell rendering
- **Responsive layout** adapts to available space
- **Smooth interactions** even with large datasets and split months

## 📝 Contributing

Feel free to contribute! Check out the [guides](/CONTRIBUTING.md) for more information.


## ❤️‍🔥 Enjoying this package?

Here are a few ways you can show support:
- ⭐️ Star it on [GitHub](https://github.com/abdullah-cse/contribution_heatmap) – stars help others discover it!
- 👍 Give it a thumbs up on pub.dev – every bit of appreciation counts!
- 👉 Try my [TypeFast app](https://web.typefast.app), a fun way to sharpen your touch typing skills with games.
- 👉  Explore more of my [work!](https://abdullah.com.bd)