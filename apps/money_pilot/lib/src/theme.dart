import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color navy = Color(0xFF10253F);
  static const Color mint = Color(0xFF26C18A);
  static const Color sky = Color(0xFF4E7BEF);

  static ThemeData light({
    required bool highContrast,
    String palette = 'ocean',
    bool glowEffects = false,
    String? fontFamily,
  }) => _build(
    Brightness.light,
    highContrast: highContrast,
    palette: palette,
    glowEffects: glowEffects,
    fontFamily: fontFamily,
  );

  static ThemeData dark({
    required bool highContrast,
    String palette = 'ocean',
    bool glowEffects = false,
    String? fontFamily,
  }) => _build(
    Brightness.dark,
    highContrast: highContrast,
    palette: palette,
    glowEffects: glowEffects,
    fontFamily: fontFamily,
  );

  static ThemeData _build(
    Brightness brightness, {
    required bool highContrast,
    required String palette,
    required bool glowEffects,
    String? fontFamily,
  }) {
    final dark = brightness == Brightness.dark;
    final colors = _palette(palette, dark);
    final seed = highContrast ? (dark ? Colors.cyanAccent : navy) : colors.seed;
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
      primary: highContrast ? (dark ? Colors.cyanAccent : navy) : colors.seed,
      secondary: highContrast
          ? (dark ? Colors.yellowAccent : navy)
          : colors.accent,
      surface: colors.surface,
    );
    final outline = highContrast
        ? (dark ? Colors.white : Colors.black)
        : scheme.outlineVariant;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      visualDensity: VisualDensity.standard,
      textTheme: Typography.material2021(platform: TargetPlatform.windows).black
          .apply(
            bodyColor: scheme.onSurface,
            displayColor: scheme.onSurface,
            fontFamily: fontFamily,
          ),
      cardTheme: CardThemeData(
        elevation: glowEffects ? 7 : 0,
        shadowColor: glowEffects
            ? colors.seed.withValues(alpha: dark ? 0.48 : 0.25)
            : Colors.transparent,
        color: colors.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: outline, width: highContrast ? 2 : 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.input,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: outline),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: glowEffects ? 4 : 0,
          shadowColor: colors.seed.withValues(alpha: 0.55),
          minimumSize: const Size(44, 46),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(44, 46),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: DividerThemeData(color: outline, space: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      tooltipTheme: TooltipThemeData(
        waitDuration: const Duration(milliseconds: 400),
        textStyle: TextStyle(color: scheme.onInverseSurface),
      ),
    );
  }

  static ThemeMode modeFrom(String value) => switch (value) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  static ({Color seed, Color accent, Color surface, Color card, Color input})
  _palette(String value, bool dark) => switch (value) {
    'cyan' => (
      seed: const Color(0xFF00A9C7),
      accent: const Color(0xFF2DE2E6),
      surface: dark ? const Color(0xFF07191D) : const Color(0xFFF1FCFD),
      card: dark ? const Color(0xFF0E252B) : Colors.white,
      input: dark ? const Color(0xFF123039) : const Color(0xFFE8F8FA),
    ),
    'forest' => (
      seed: const Color(0xFF19704B),
      accent: const Color(0xFF74C69D),
      surface: dark ? const Color(0xFF091711) : const Color(0xFFF3FAF6),
      card: dark ? const Color(0xFF12251C) : Colors.white,
      input: dark ? const Color(0xFF183127) : const Color(0xFFEAF5EE),
    ),
    'violet' => (
      seed: const Color(0xFF7654D6),
      accent: const Color(0xFFB794F6),
      surface: dark ? const Color(0xFF151022) : const Color(0xFFF8F5FE),
      card: dark ? const Color(0xFF211A31) : Colors.white,
      input: dark ? const Color(0xFF2B2340) : const Color(0xFFF0EBFA),
    ),
    'sunset' => (
      seed: const Color(0xFFE16647),
      accent: const Color(0xFFF4B860),
      surface: dark ? const Color(0xFF21110D) : const Color(0xFFFFF8F4),
      card: dark ? const Color(0xFF301A15) : Colors.white,
      input: dark ? const Color(0xFF3C241D) : const Color(0xFFFFEFE7),
    ),
    _ => (
      seed: sky,
      accent: mint,
      surface: dark ? const Color(0xFF111821) : const Color(0xFFF7F9FC),
      card: dark ? const Color(0xFF18212C) : Colors.white,
      input: dark ? const Color(0xFF1C2734) : const Color(0xFFF2F5FA),
    ),
  };
}
