import 'package:flutter_test/flutter_test.dart';
import 'package:money_pilot/src/auth.dart';
import 'package:money_pilot/src/initial_data.dart';
import 'package:money_pilot/src/local_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const primaryTestPassword = 'FirstPass123'; // gitleaks:allow
  const replacementTestPassword = 'SecondPass456'; // gitleaks:allow
  const incorrectTestPassword = 'WrongPass123'; // gitleaks:allow

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'local account supports registration, login, recovery, and deletion without storing secrets',
    () async {
      final repository = LocalAuthRepository();
      final registration = await repository.register(
        displayName: 'Alex Tester',
        email: 'TEST.USER@example.com',
        password: primaryTestPassword,
      );

      expect(registration.user.email, 'test.user@example.com');
      expect(registration.recoveryCode.replaceAll('-', ''), hasLength(16));
      expect(await repository.loadActiveUser(), isNull);

      final preferences = await SharedPreferences.getInstance();
      final stored = preferences.getString('money_pilot_local_accounts_v2')!;
      expect(stored, isNot(contains(primaryTestPassword)));
      expect(stored, isNot(contains(registration.recoveryCode)));

      expect(
        () => repository.login(
          email: 'test.user@example.com',
          password: incorrectTestPassword,
        ),
        throwsA(isA<AuthException>()),
      );

      final signedIn = await repository.login(
        email: 'test.user@example.com',
        password: primaryTestPassword,
      );
      expect(signedIn.id, registration.user.id);
      expect((await repository.loadActiveUser())?.id, registration.user.id);

      await repository.deactivate();
      expect(await repository.loadActiveUser(), isNull);

      await repository.resetPassword(
        email: 'test.user@example.com',
        recoveryCode: registration.recoveryCode,
        newPassword: replacementTestPassword,
      );
      final recovered = await repository.login(
        email: 'test.user@example.com',
        password: replacementTestPassword,
      );
      expect(recovered.id, registration.user.id);

      await repository.deleteAccount(recovered.id, replacementTestPassword);
      expect(await repository.loadActiveUser(), isNull);
      await expectLater(
        repository.login(
          email: 'test.user@example.com',
          password: replacementTestPassword,
        ),
        throwsA(isA<AuthException>()),
      );
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test('financial records are isolated by local account id', () async {
    final first = LocalRepository(userId: 'first-user');
    final second = LocalRepository(userId: 'second-user');

    await first.save(buildEmptyData().copyWith(onboardingComplete: true));

    expect((await first.load())?.onboardingComplete, isTrue);
    expect(await second.load(), isNull);
  });
}
