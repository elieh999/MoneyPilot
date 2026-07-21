import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:money_pilot/src/initial_data.dart';
import 'package:money_pilot/src/local_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'financial snapshot is authenticated, encrypted, and reloadable',
    () async {
      final repository = LocalRepository(userId: 'encrypted-user');
      final data = buildEmptyData(onboardingComplete: true);
      await repository.save(data);

      final preferences = await SharedPreferences.getInstance();
      final raw = preferences.getString(
        'money_pilot_app_data_v2_encrypted-user',
      )!;
      expect(raw, startsWith('mpenc:'));
      expect(raw, isNot(contains('onboardingComplete')));
      expect((await repository.load())?.onboardingComplete, isTrue);
    },
  );

  test('plaintext data migrates once and tampering fails closed', () async {
    final data = buildEmptyData(onboardingComplete: true);
    SharedPreferences.setMockInitialValues({
      'money_pilot_app_data_v2_migration-user': data.encode(),
    });
    final repository = LocalRepository(userId: 'migration-user');
    expect((await repository.load())?.onboardingComplete, isTrue);

    final preferences = await SharedPreferences.getInstance();
    final key = 'money_pilot_app_data_v2_migration-user';
    final encrypted = preferences.getString(key)!;
    expect(encrypted, startsWith('mpenc:'));
    final envelope =
        jsonDecode(utf8.decode(base64Decode(encrypted.substring(6))))
            as Map<String, dynamic>;
    envelope['ciphertext'] = '${envelope['ciphertext']}A';
    await preferences.setString(
      key,
      'mpenc:${base64Encode(utf8.encode(jsonEncode(envelope)))}',
    );
    expect(await repository.load(), isNull);
  });
}
