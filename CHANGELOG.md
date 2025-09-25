## [0.3.1-dev.1] - 2025-09-25

- fix(render_heatmap): `DateTime` midnight or DST(Daylight Saving Time) releted bug
- test(heatmap_utils): Unit🧪 test for `dayKey` normalization with UTC.

## [0.3.0] - 2025-09-22

- feat(heatmap_ui): Add `showCellDate` property to display day numbers inside contribution cells
- feat(heatmap_ui): Add `cellDateTextStyle` property for customizing cell date text appearance
- perf(render): Optimize cell date painting with reusable TextPainter objects and smart visibility checks
- docs(readme): Add cell date display section with comprehensive examples and API documentation

## [0.2.0] - 2025-09-21

- feat(heatmap_ui): Add `splittedMonthView` for visual separation between months.
- docs(readme): Update readme file with `splittedMonthView`

## [0.1.0] - 2025-09-16

- feat(i18n): Add i18n Support for French, German, Spanish locale.
- test(heatmap_localization): Add Unit test for French, German,Spanish locale
- docs(readme): Add i18n support section.

## [0.0.5] - 2025-09-15

- docs(readme): Add various info badges.

## [0.0.4] - 2025-09-08

- refactor: Material import replaced with Widgets import.
- docs(readme): Remove Github Star badge.

## [0.0.3] - 2025-09-05

- style: Add Topics for visibility.

## [0.0.2] - 2025-09-04

- style: format code with `dart format .` (#2)
- Better Readme

## [0.0.1] - 2025-09-04

- Initial release
- feat(ui): Add GitHub-like contribution heatmap
- feat(ui): Full customization: colors, cell size, labels
- feat(tap handle): Interactive tap handling
- perf(heatmap): High-performance RenderBox implementation