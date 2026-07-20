import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_pilot/src/app_controller.dart';
import 'package:money_pilot/src/initial_data.dart';
import 'package:money_pilot/src/local_repository.dart';
import 'package:money_pilot/src/localization.dart';
import 'package:money_pilot/src/models.dart';
import 'package:money_pilot/src/screens/calendar_screen.dart';

class _MemoryRepository extends LocalRepository {
  @override
  Future<AppData?> load() async => null;

  @override
  Future<void> save(AppData data) async {}

  @override
  Future<void> clear() async {}
}

void main() {
  testWidgets('calendar renders smoothly on mobile in Arabic RTL', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final now = DateTime.now();
    final controller = AppController(
      repository: _MemoryRepository(),
      syncGateway: DioSyncGateway(),
      initialData: buildEmptyData(onboardingComplete: true).copyWith(
        settings: const AppSettings(languageCode: 'ar'),
        transactions: [
          FinanceTransaction(
            id: 'coffee',
            accountId: 'cash',
            categoryId: 'dining',
            title: 'قهوة',
            amountMinor: -500,
            date: now,
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appControllerProvider.overrideWith((ref) => controller)],
        child: const MaterialApp(
          locale: Locale('ar'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(body: CalendarScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('تقويم المصروفات'), findsOneWidget);
    expect(find.byKey(Key('calendar-day-${now.day}')), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(CalendarScreen))),
      TextDirection.rtl,
    );
    expect(tester.takeException(), isNull);
  });
}
