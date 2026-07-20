import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_pilot/src/app.dart';
import 'package:money_pilot/src/auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FastAuthRepository extends LocalAuthRepository {
  @override
  Future<LocalUser?> loadActiveUser() async => null;

  @override
  Future<RegistrationResult> register({
    required String displayName,
    required String email,
    required String password,
  }) async {
    return RegistrationResult(
      user: LocalUser(
        id: 'widget-user',
        email: email,
        displayName: displayName,
        createdAt: DateTime(2026),
      ),
      recoveryCode: 'ABCD-EFGH-JKLM-NPQR',
    );
  }

  @override
  Future<void> activate(String userId) async {}
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'account creation opens a genuinely empty workspace',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(_FastAuthRepository()),
          ],
          child: const MoneyPilotApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Sign in'), findsWidgets);

      await tester.tap(find.text('New to MoneyPilot? Create an account'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('auth-name-field')),
        'Test User',
      );
      await tester.enterText(
        find.byKey(const Key('auth-email-field')),
        'test@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('auth-password-field')),
        'StrongPass123',
      );
      await tester.ensureVisible(
        find.byKey(const Key('create-account-button')),
      );
      tester.testTextInput.hide();
      await tester.pump();
      tester
          .widget<FilledButton>(find.byKey(const Key('create-account-button')))
          .onPressed!();
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Save your recovery code'), findsOneWidget);
      expect(find.byKey(const Key('recovery-code')), findsOneWidget);
      await tester.tap(find.byKey(const Key('saved-recovery-code')));
      await tester.pumpAndSettle();

      expect(find.text('Empty by design'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const Key('open-empty-workspace-button')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      tester
          .widget<FilledButton>(
            find.byKey(const Key('open-empty-workspace-button')),
          )
          .onPressed!();
      await tester.pumpAndSettle();

      expect(find.text('SAFE TO SPEND'), findsOneWidget);
      expect(find.text('No transactions yet'), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Overview'), findsAtLeastNWidgets(1));
      expect(find.text('Coach'), findsAtLeastNWidgets(1));
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
