import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_pilot/src/app_controller.dart';
import 'package:money_pilot/src/initial_data.dart';
import 'package:money_pilot/src/local_repository.dart';
import 'package:money_pilot/src/localization.dart';
import 'package:money_pilot/src/models.dart';
import 'package:money_pilot/src/screens/settings_screen.dart';
import 'package:money_pilot/src/theme.dart';

class _MemoryRepository extends LocalRepository {
  @override
  Future<AppData?> load() async => null;

  @override
  Future<void> save(AppData data) async {}

  @override
  Future<void> clear() async {}
}

void main() {
  setUpAll(() async {
    final loader = FontLoader('NotoSansArabic')
      ..addFont(rootBundle.load('assets/fonts/NotoSansArabic-Variable.ttf'));
    await loader.load();
  });

  testWidgets('Arabic settings contain no English fallback in key controls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = AppController(
      repository: _MemoryRepository(),
      syncGateway: DioSyncGateway(),
      initialData: buildEmptyData(onboardingComplete: true).copyWith(
        settings: const AppSettings(
          languageCode: 'ar',
          themeMode: 'dark',
          themePalette: 'cyan',
          glowEffects: true,
        ),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appControllerProvider.overrideWith((ref) => controller)],
        child: MaterialApp(
          locale: const Locale('ar'),
          theme: AppTheme.dark(
            highContrast: false,
            palette: 'cyan',
            glowEffects: true,
            fontFamily: 'NotoSansArabic',
          ),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const Scaffold(
            body: RepaintBoundary(
              key: Key('arabic-settings-golden'),
              child: SettingsScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('الحساب'), findsOneWidget);
    expect(find.text('تفضيلات المساعد والأمان'), findsOneWidget);
    expect(find.text('ضوابط الخصوصية'), findsOneWidget);
    expect(find.text('Account'), findsNothing);
    expect(find.text('Privacy controls'), findsNothing);
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(const Key('arabic-settings-golden')),
      matchesGoldenFile('goldens/settings_arabic_complete.png'),
    );
  });
}
