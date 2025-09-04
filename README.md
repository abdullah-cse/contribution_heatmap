# Contribution Heatmap 🔥

A high-performance, GitHub-like contribution heatmap widget for Flutter. This widget provides a visual representation of contribution data over time, similar to GitHub's contribution graph.

## ✨ Features

- **🚀 Ultra-High Performance**: Custom RenderBox implementation with optimized rendering pipeline
- **👆 Interactive**: Full tap support with proper hit testing and gesture handling
- **🎨 Fully Customizable**: Colors, sizing, labels, and layout options
- **♿ Accessibility Ready**: Supports text scaling and high contrast modes
- **🌍 Internationalized**: Locale-aware text rendering with customizable start weekdays  
- **💾 Memory Efficient**: Optimized data structures minimize memory usage and GC pressure
- **🔧 Smart Invalidation**: Only recomputes what's needed, not on every frame

## 📱 Demo

The heatmap displays contribution data as a grid where:
- Each column represents a week
- Each row represents a day of the week  
- Cell colors indicate contribution intensity
- Interactive cells show detailed information on tap

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

The basic data structure for contribution data:

```dart
class ContributionEntry {
  final DateTime date;  // Day-level precision
  final int count;      // Number of contributions (>= 0)
  
  const ContributionEntry(this.date, this.count);
}
```

**Example data generation:**

```dart
List<ContributionEntry> generateSampleData() {
  final data = <ContributionEntry>[];
  final now = DateTime.now();
  
  // Generate data for the past year
  for (int i = 0; i < 365; i++) {
    final date = now.subtract(Duration(days: i));
    final contributions = Random().nextInt(20); // 0-19 contributions
    
    if (contributions > 0) {
      data.add(ContributionEntry(date, contributions));
    }
  }
  
  return data;
}
```

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

## 🎯 Default Color Scale

The widget uses a GitHub-inspired 5-level color scale by default:

- **0 contributions**: Light gray (`#E5EDEB`)
- **1-2 contributions**: Light green (`#C6E48B`)
- **3-5 contributions**: Medium green (`#7BC96F`)
- **6-10 contributions**: Dark green (`#239A3B`)
- **11+ contributions**: Darkest green (`#196127`)


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

## 🛠️ Technical Implementation

### Custom RenderBox

The widget uses Flutter's low-level rendering system for maximum performance:

```dart
class RenderContributionHeatmap extends RenderBox {
  // Efficient layout calculation
  @override
  void performLayout() { ... }
  
  // Optimized painting with minimal allocations
  @override
  void paint(PaintingContext context, Offset offset) { ... }
  
  // Smart hit testing for interactions
  @override
  bool hitTestSelf(Offset position) => true;
}
```

### Smart Invalidation

The render object only recomputes what's necessary:

- **Layout changes**: Cell size, spacing, padding modifications
- **Paint changes**: Color scale, radius modifications  
- **Data changes**: Entry list modifications trigger index rebuild

### Gesture Handling

Proper lifecycle management prevents memory leaks:

```dart
void _initRecognizers() {
  _tap?.dispose(); // Clean up existing recognizer
  _tap = TapGestureRecognizer(debugOwner: this)
    ..onTapUp = _handleTapUp;
}

@override
void detach() {
  _tap?.dispose(); // Prevent memory leaks
  super.detach();
}
```

## 🧪 Testing

Run the example app to see the widget in action:

```bash
flutter run
```

The example demonstrates:
- Sample data generation
- Interactive cell tapping
- GitHub-style dark theme
- Feature highlights and documentation

## 📝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

## 📄 License

This project is licensed under the BSD 3-Clause License - see the LICENSE file for details.

## 👍 Acknowledgments

- Inspired by GitHub's contribution graph
- Built with Flutter's powerful custom rendering system
- Optimized for performance and accessibility
