import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_pilot/src/app_controller.dart';
import 'package:money_pilot/src/initial_data.dart';
import 'package:money_pilot/src/local_repository.dart';
import 'package:money_pilot/src/localization.dart';
import 'package:money_pilot/src/models.dart';
import 'package:money_pilot/src/screens/settings_screen.dart';

class _MemoryRepository extends LocalRepository {
  AppData? saved;

  @override
  Future<AppData?> load() async => saved;

  @override
  Future<void> save(AppData data) async => saved = data;

  @override
  Future<void> clear() async => saved = null;
}

void main() {
  testWidgets('French settings are fully localized and palette persists', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = AppController(
      repository: _MemoryRepository(),
      syncGateway: DioSyncGateway(),
      initialData: buildEmptyData(
        onboardingComplete: true,
      ).copyWith(settings: const AppSettings(languageCode: 'fr')),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appControllerProvider.overrideWith((ref) => controller)],
        child: const MaterialApp(
          locale: Locale('fr'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(body: SettingsScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Compte'), findsOneWidget);
    expect(find.text('Préférences du Coach et de sécurité'), findsOneWidget);
    expect(find.text('Contrôles de confidentialité'), findsOneWidget);
    expect(find.text('Account'), findsNothing);
    expect(find.text('Privacy controls'), findsNothing);

    await tester.ensureVisible(find.byKey(const Key('palette-forest')));
    await tester.tap(find.byKey(const Key('palette-forest')));
    await tester.pumpAndSettle();
    expect(controller.state.settings.themePalette, 'forest');
  });

  testWidgets('financial wipe requires explicit WIPE confirmation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = AppController(
      repository: _MemoryRepository(),
      syncGateway: DioSyncGateway(),
      initialData: buildEmptyData(onboardingComplete: true).copyWith(
        settings: const AppSettings(languageCode: 'fr', themePalette: 'forest'),
        accounts: const [
          MoneyAccount(
            id: 'checking',
            name: 'Checking',
            type: 'Checking',
            balanceMinor: 10000,
            colorValue: 0,
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appControllerProvider.overrideWith((ref) => controller)],
        child: const MaterialApp(
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(body: SettingsScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final clearButton = find.byKey(const Key('clear-financial-data-button'));
    await tester.ensureVisible(clearButton);
    await tester.pumpAndSettle();
    await tester.tap(clearButton);
    await tester.pumpAndSettle();

    final confirm = find.byKey(const Key('confirm-wipe-button'));
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
    await tester.enterText(
      find.byKey(const Key('wipe-confirmation-field')),
      'WIPE',
    );
    await tester.pump();
    expect(tester.widget<FilledButton>(confirm).onPressed, isNotNull);
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(controller.state.accounts, isEmpty);
    expect(controller.state.settings.languageCode, 'fr');
    expect(controller.state.settings.themePalette, 'forest');
    expect(controller.state.categories, isNotEmpty);
  });
}
