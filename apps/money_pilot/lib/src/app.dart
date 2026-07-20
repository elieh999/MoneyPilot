import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_pilot/src/app_controller.dart';
import 'package:money_pilot/src/localization.dart';
import 'package:money_pilot/src/router.dart';
import 'package:money_pilot/src/theme.dart';

class MoneyPilotApp extends ConsumerWidget {
  const MoneyPilotApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(
      appControllerProvider.select((data) => data.settings),
    );
    final router = ref.watch(routerProvider);
    final fontFamily = settings.languageCode == 'ar' ? 'NotoSansArabic' : null;
    return MaterialApp.router(
      title: 'MoneyPilot',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(
        highContrast: settings.highContrast,
        palette: settings.themePalette,
        glowEffects: settings.glowEffects,
        fontFamily: fontFamily,
      ),
      darkTheme: AppTheme.dark(
        highContrast: settings.highContrast,
        palette: settings.themePalette,
        glowEffects: settings.glowEffects,
        fontFamily: fontFamily,
      ),
      highContrastTheme: AppTheme.light(
        highContrast: true,
        palette: settings.themePalette,
        glowEffects: settings.glowEffects,
        fontFamily: fontFamily,
      ),
      highContrastDarkTheme: AppTheme.dark(
        highContrast: true,
        palette: settings.themePalette,
        glowEffects: settings.glowEffects,
        fontFamily: fontFamily,
      ),
      themeMode: AppTheme.modeFrom(settings.themeMode),
      locale: Locale(settings.languageCode),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: MediaQuery.textScalerOf(
            context,
          ).clamp(minScaleFactor: 0.85, maxScaleFactor: 1.6),
        ),
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
