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
import 'package:money_pilot/src/screens/coach_screen.dart';
import 'package:money_pilot/src/theme.dart';

import 'golden_test_support.dart';

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

  testWidgets('coach panel renders at reported width and replies in Arabic', (
    tester,
  ) async {
    useCrossPlatformGoldenComparator(Uri.parse('test/coach_screen_test.dart'));
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(883, 1014);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final controller = AppController(
      repository: _MemoryRepository(),
      syncGateway: DioSyncGateway(),
      initialData: buildEmptyData(
        onboardingComplete: true,
      ).copyWith(settings: const AppSettings(languageCode: 'ar')),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appControllerProvider.overrideWith((ref) => controller)],
        child: MaterialApp(
          locale: const Locale('ar'),
          theme: AppTheme.light(
            highContrast: false,
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
              key: Key('coach-golden'),
              child: CoachScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ما الذي تريد أن نحلّله؟'), findsOneWidget);
    expect(find.byKey(const Key('coach-message-field')), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(CoachScreen))),
      TextDirection.rtl,
    );
    expect(tester.takeException(), isNull);

    await tester.enterText(
      find.byKey(const Key('coach-message-field')),
      'مرحبا',
    );
    await tester.tap(find.byKey(const Key('coach-send-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(find.text('مرحبا'), findsOneWidget);
    expect(find.textContaining('مساحة العمل فارغة'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(const Key('coach-golden')),
      matchesGoldenFile('goldens/coach_arabic_reply.png'),
    );
  });
}
