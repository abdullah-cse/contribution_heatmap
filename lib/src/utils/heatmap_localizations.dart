import 'package:flutter/material.dart';

/// Provides localized weekday and month abbreviations
/// for the contribution heatmap without external dependencies.
///
/// Currently supports:
/// - English (default / fallback)
/// - German
/// - French
/// - Spanish
///
/// If a locale is not recognized, English will be used.
///
/// Example:
/// ```dart
/// final weekdaysEs = HeatmapLocalizations.weekdayShortNames(const Locale('es'));
/// // ['lun.', 'mar.', 'mié.', 'jue.', 'vie.', 'sáb.', 'dom.']
///
/// final monthsEs = HeatmapLocalizations.monthAbbreviations(const Locale('es'));
/// // ['ene.', 'feb.', 'mar.', 'abr.', 'may.', 'jun.', 'jul.', 'ago.', 'sept.', 'oct.', 'nov.', 'dic.']
/// ```
class HeatmapLocalizations {
  /// Weekday short names (Monday → Sunday) per locale.
  static const Map<String, List<String>> _weekdayData = {
    'en': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
    'de': ['Mo.', 'Di.', 'Mi.', 'Do.', 'Fr.', 'Sa.', 'So.'],
    'fr': ['lun.', 'mar.', 'mer.', 'jeu.', 'ven.', 'sam.', 'dim.'],
    'es': ['lun.', 'mar.', 'mié.', 'jue.', 'vie.', 'sáb.', 'dom.'],
  };

  /// Month abbreviations (January → December) per locale.
  static const Map<String, List<String>> _monthData = {
    'en': [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ],
    'de': [
      'Jan.',
      'Feb.',
      'März',
      'Apr.',
      'Mai',
      'Juni',
      'Juli',
      'Aug.',
      'Sept.',
      'Okt.',
      'Nov.',
      'Dez.',
    ],
    'fr': [
      'janv.',
      'févr.',
      'mars',
      'avr.',
      'mai',
      'juin',
      'juil.',
      'août',
      'sept.',
      'oct.',
      'nov.',
      'déc.',
    ],
    'es': [
      'ene.',
      'feb.',
      'mar.',
      'abr.',
      'may.',
      'jun.',
      'jul.',
      'ago.',
      'sept.',
      'oct.',
      'nov.',
      'dic.',
    ],
  };

  /// Returns localized weekday short names.
  ///
  /// Always starts with Monday and ends with Sunday.
  /// Falls back to English if the locale is not supported.
  static List<String> weekdayShortNames(Locale locale) {
    final code = locale.languageCode.toLowerCase();
    return _weekdayData[code] ?? _weekdayData['en']!;
  }

  /// Returns localized month abbreviation.
  ///
  /// [month] must be 1–12.
  /// Falls back to English if the locale is not supported.
  static String monthAbbreviation(int month, Locale locale) {
    final code = locale.languageCode.toLowerCase();
    final months = _monthData[code] ?? _monthData['en']!;
    return months[month - 1];
  }
}
