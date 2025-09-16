import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:contribution_heatmap/src/utils/heatmap_localizations.dart';

void main() {
  group('HeatmapLocalizations', () {
    /// Test weekday short names for supported locales
    test('weekdayShortNames returns correct names for supported locales', () {
      // English
      expect(HeatmapLocalizations.weekdayShortNames(const Locale('en')), [
        'Mon',
        'Tue',
        'Wed',
        'Thu',
        'Fri',
        'Sat',
        'Sun',
      ]);

      // German
      expect(HeatmapLocalizations.weekdayShortNames(const Locale('de')), [
        'Mo.',
        'Di.',
        'Mi.',
        'Do.',
        'Fr.',
        'Sa.',
        'So.',
      ]);

      // French
      expect(HeatmapLocalizations.weekdayShortNames(const Locale('fr')), [
        'lun.',
        'mar.',
        'mer.',
        'jeu.',
        'ven.',
        'sam.',
        'dim.',
      ]);

      // Spanish
      expect(HeatmapLocalizations.weekdayShortNames(const Locale('es')), [
        'lun.',
        'mar.',
        'mié.',
        'jue.',
        'vie.',
        'sáb.',
        'dom.',
      ]);
    });

    /// Test fallback to English for unsupported locales
    test('weekdayShortNames falls back to English for unsupported locale', () {
      expect(HeatmapLocalizations.weekdayShortNames(const Locale('it')), [
        'Mon',
        'Tue',
        'Wed',
        'Thu',
        'Fri',
        'Sat',
        'Sun',
      ]);
    });

    /// Test month abbreviations for supported locales
    test(
      'monthAbbreviation returns correct abbreviation for supported locales',
      () {
        // English
        expect(
          HeatmapLocalizations.monthAbbreviation(1, const Locale('en')),
          'Jan',
        );
        expect(
          HeatmapLocalizations.monthAbbreviation(12, const Locale('en')),
          'Dec',
        );

        // German
        expect(
          HeatmapLocalizations.monthAbbreviation(3, const Locale('de')),
          'März',
        );
        expect(
          HeatmapLocalizations.monthAbbreviation(10, const Locale('de')),
          'Okt.',
        );

        // French
        expect(
          HeatmapLocalizations.monthAbbreviation(1, const Locale('fr')),
          'janv.',
        );
        expect(
          HeatmapLocalizations.monthAbbreviation(8, const Locale('fr')),
          'août',
        );

        // Spanish
        expect(
          HeatmapLocalizations.monthAbbreviation(1, const Locale('es')),
          'ene.',
        );
        expect(
          HeatmapLocalizations.monthAbbreviation(7, const Locale('es')),
          'jul.',
        );
      },
    );

    /// Test fallback to English for unsupported locales in month abbreviations
    test('monthAbbreviation falls back to English for unsupported locale', () {
      expect(
        HeatmapLocalizations.monthAbbreviation(5, const Locale('it')),
        'May',
      );
    });

    /// Test that monthAbbreviation throws error if month is out of range
    test('monthAbbreviation throws RangeError if month < 1 or > 12', () {
      final locale = const Locale('en');

      expect(
        () => HeatmapLocalizations.monthAbbreviation(0, locale),
        throwsRangeError,
      );
      expect(
        () => HeatmapLocalizations.monthAbbreviation(13, locale),
        throwsRangeError,
      );
    });
  });
}
