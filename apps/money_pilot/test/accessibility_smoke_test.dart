import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_pilot/src/app_controller.dart';
import 'package:money_pilot/src/local_repository.dart';
import 'package:money_pilot/src/models.dart';
import 'package:money_pilot/src/shell.dart';
import 'package:money_pilot/src/widgets/common.dart';

class _MemoryRepository extends LocalRepository {
  @override
  Future<AppData?> load() async => null;

  @override
  Future<void> save(AppData data) async {}

  @override
  Future<void> clear() async {}
}

AppController _controller() => AppController(
  repository: _MemoryRepository(),
  syncGateway: DioSyncGateway(),
  initialData: const AppData(
    accounts: [],
    categories: [],
    transactions: [],
    budgets: [],
    bills: [],
    goals: [],
    messages: [],
    settings: AppSettings(),
    onboardingComplete: true,
  ),
);

Widget _shell() {
  final controller = _controller();
  return ProviderScope(
    overrides: [appControllerProvider.overrideWith((ref) => controller)],
    child: MaterialApp(
      home: AppShell(
        location: '/dashboard',
        child: PageFrame(
          title: 'Overview',
          subtitle: 'A clear snapshot of the current plan.',
          child: const MetricCard(
            label: 'Safe to spend',
            value: r'$2,050.00',
            detail: 'After bills and reserves',
            icon: Icons.shield_outlined,
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'compact shell exposes bottom navigation and financial semantics',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(_shell());
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      for (final label in ['Overview', 'Activity', 'Plan', 'Coach', 'More']) {
        expect(find.text(label), findsAtLeastNWidgets(1));
      }
      expect(find.bySemanticsLabel(RegExp(r'MoneyPilot AI')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'Overview page')), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          RegExp(r'Safe to spend.*\$2,050\.00.*After bills and reserves'),
        ),
        findsOneWidget,
      );
      expect(find.byTooltip('Add transaction (Ctrl+N)'), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets(
    'expanded shell replaces bottom navigation with full destinations',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1280, 900);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_shell());
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text('MoneyPilot'), findsOneWidget);
      for (final destination in appDestinations) {
        expect(
          find.text(destination.label),
          findsAtLeastNWidgets(1),
          reason: destination.label,
        );
      }
      expect(find.text('Add transaction'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'Overview page')), findsOneWidget);
    },
  );
}
