import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_pilot/src/localization.dart';
import 'package:money_pilot/src/models.dart';
import 'package:money_pilot/src/theme.dart';
import 'package:money_pilot/src/ui_translations.dart';
import 'package:money_pilot/src/ui_translations_extra.dart';

void main() {
  test('French and Arabic phrase catalogs have identical complete keys', () {
    expect(frenchUiPhrases.keys.toSet(), arabicUiPhrases.keys.toSet());
    expect(
      frenchUiPhrasesExtra.keys.toSet(),
      arabicUiPhrasesExtra.keys.toSet(),
    );
    expect(frenchUiPhrases.length, greaterThan(250));
  });

  test('selected locale translates settings, safety, and feature content', () {
    const french = AppLocalizations(Locale('fr'));
    const arabic = AppLocalizations(Locale('ar'));
    const required = [
      'Account',
      'Coach & safety preferences',
      'Coaching style',
      'Privacy controls',
      'Share anonymous diagnostics',
      'Clear all financial data?',
      'Spending calendar',
      'Electric cyan',
      'Deep forest',
      'Glow effects',
    ];

    for (final phrase in required) {
      expect(french.translate(phrase), isNot(phrase), reason: phrase);
      expect(arabic.translate(phrase), isNot(phrase), reason: phrase);
    }
    expect(french.translate('12 local records'), '12 enregistrements locaux');
    expect(arabic.translate('12 local records'), '12 سجلاً محلياً');
  });

  test('settings preserve validated palette and glow preferences', () {
    final restored = AppSettings.fromJson(
      const AppSettings(
        languageCode: 'ar',
        themePalette: 'forest',
        glowEffects: true,
      ).toJson(),
    );

    expect(restored.languageCode, 'ar');
    expect(restored.themePalette, 'forest');
    expect(restored.glowEffects, isTrue);
    expect(
      AppSettings.fromJson({'themePalette': 'invalid'}).themePalette,
      'ocean',
    );
    expect(
      const AppLocalizations(Locale('fr')).navLabel('/calendar'),
      'Calendrier',
    );
    expect(
      const AppLocalizations(Locale('ar')).navLabel('/calendar'),
      'التقويم',
    );
  });

  test('theme palettes and glow produce distinct publishable themes', () {
    final ocean = AppTheme.dark(highContrast: false);
    final forest = AppTheme.dark(
      highContrast: false,
      palette: 'forest',
      glowEffects: true,
    );

    expect(forest.colorScheme.primary, isNot(ocean.colorScheme.primary));
    expect(forest.cardTheme.elevation, greaterThan(0));
    expect(ocean.cardTheme.elevation, 0);
  });
}
