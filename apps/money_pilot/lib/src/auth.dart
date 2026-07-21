import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_pilot/src/local_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

final authRepositoryProvider = Provider<LocalAuthRepository>(
  (ref) => LocalAuthRepository(),
);

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(ref.watch(authRepositoryProvider)),
);

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class LocalUser {
  const LocalUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.createdAt,
  });

  final String id;
  final String email;
  final String displayName;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'displayName': displayName,
    'createdAt': createdAt.toIso8601String(),
  };

  factory LocalUser.fromJson(Map<String, dynamic> json) => LocalUser(
    id: json['id'] as String,
    email: json['email'] as String,
    displayName: json['displayName'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

class RegistrationResult {
  const RegistrationResult({required this.user, required this.recoveryCode});

  final LocalUser user;
  final String recoveryCode;
}

class AuthState {
  const AuthState({
    this.initialized = false,
    this.busy = false,
    this.currentUser,
    this.error,
  });

  final bool initialized;
  final bool busy;
  final LocalUser? currentUser;
  final String? error;

  bool get isSignedIn => currentUser != null;
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repository) : super(const AuthState()) {
    unawaited(_restoreSession());
  }

  final LocalAuthRepository _repository;

  Future<void> _restoreSession() async {
    try {
      final user = await _repository.loadActiveUser();
      state = AuthState(initialized: true, currentUser: user);
    } catch (_) {
      state = const AuthState(
        initialized: true,
        error: 'Your local session could not be restored. Sign in again.',
      );
    }
  }

  Future<RegistrationResult> register({
    required String displayName,
    required String email,
    required String password,
  }) async {
    state = AuthState(
      initialized: true,
      busy: true,
      currentUser: state.currentUser,
    );
    try {
      final result = await _repository.register(
        displayName: displayName,
        email: email,
        password: password,
      );
      state = const AuthState(initialized: true);
      return result;
    } on AuthException catch (error) {
      state = AuthState(initialized: true, error: error.message);
      rethrow;
    }
  }

  Future<void> completeRegistration(LocalUser user) async {
    await _repository.activate(user.id);
    state = AuthState(initialized: true, currentUser: user);
  }

  Future<void> login({required String email, required String password}) async {
    state = const AuthState(initialized: true, busy: true);
    try {
      final user = await _repository.login(email: email, password: password);
      state = AuthState(initialized: true, currentUser: user);
    } on AuthException catch (error) {
      state = AuthState(initialized: true, error: error.message);
      rethrow;
    }
  }

  Future<void> resetPassword({
    required String email,
    required String recoveryCode,
    required String newPassword,
  }) async {
    state = const AuthState(initialized: true, busy: true);
    try {
      await _repository.resetPassword(
        email: email,
        recoveryCode: recoveryCode,
        newPassword: newPassword,
      );
      state = const AuthState(initialized: true);
    } on AuthException catch (error) {
      state = AuthState(initialized: true, error: error.message);
      rethrow;
    }
  }

  Future<void> logout() async {
    await _repository.deactivate();
    state = const AuthState(initialized: true);
  }

  Future<void> deleteCurrentAccount(String password) async {
    final user = state.currentUser;
    if (user == null) return;
    state = AuthState(initialized: true, busy: true, currentUser: user);
    try {
      await _repository.deleteAccount(user.id, password);
      await LocalRepository(userId: user.id).clear();
      state = const AuthState(initialized: true);
    } on AuthException catch (error) {
      state = AuthState(
        initialized: true,
        currentUser: user,
        error: error.message,
      );
      rethrow;
    }
  }
}

class LocalAuthRepository {
  static const _storageKey = 'money_pilot_local_accounts_v2';
  static const _maxAttempts = 5;
  static const _lockDuration = Duration(seconds: 30);
  static const _recoveryAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  final Argon2id _passwordHasher = Argon2id(
    parallelism: 1,
    memory: 19456,
    iterations: 2,
    hashLength: 32,
  );

  Future<LocalUser?> loadActiveUser() async {
    final store = await _loadStore();
    final activeId = store.activeUserId;
    if (activeId == null) return null;
    final record = store.credentials
        .where((item) => item.user.id == activeId)
        .firstOrNull;
    if (record == null) {
      await _saveStore(store.copyWith(clearActiveUser: true));
      return null;
    }
    return record.user;
  }

  Future<RegistrationResult> register({
    required String displayName,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = _normalizeEmail(email);
    final cleanName = displayName.trim();
    if (cleanName.length < 2) {
      throw const AuthException('Enter your name using at least 2 characters.');
    }
    if (!_isValidEmail(normalizedEmail)) {
      throw const AuthException('Enter a valid email address.');
    }
    final passwordError = validatePassword(password);
    if (passwordError != null) throw AuthException(passwordError);

    final store = await _loadStore();
    if (store.credentials.any((item) => item.user.email == normalizedEmail)) {
      throw const AuthException('An account with this email already exists.');
    }

    final passwordSalt = _randomBytes(16);
    final recoverySalt = _randomBytes(16);
    final recoveryCode = _newRecoveryCode();
    final user = LocalUser(
      id: base64UrlEncode(_randomBytes(18)).replaceAll('=', ''),
      email: normalizedEmail,
      displayName: cleanName,
      createdAt: DateTime.now().toUtc(),
    );
    final record = _StoredCredential(
      user: user,
      passwordSalt: base64Encode(passwordSalt),
      passwordHash: await _hash(password, passwordSalt),
      recoverySalt: base64Encode(recoverySalt),
      recoveryHash: await _hash(_normalizeRecovery(recoveryCode), recoverySalt),
    );
    await _saveStore(
      store.copyWith(credentials: [...store.credentials, record]),
    );
    return RegistrationResult(user: user, recoveryCode: recoveryCode);
  }

  Future<LocalUser> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = _normalizeEmail(email);
    final store = await _loadStore();
    final index = store.credentials.indexWhere(
      (item) => item.user.email == normalizedEmail,
    );
    if (index == -1) {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      throw const AuthException('Invalid email or password.');
    }
    final record = store.credentials[index];
    final now = DateTime.now().toUtc();
    if (record.lockedUntil != null && record.lockedUntil!.isAfter(now)) {
      final seconds = record.lockedUntil!.difference(now).inSeconds + 1;
      throw AuthException('Too many attempts. Try again in $seconds seconds.');
    }

    final valid = await _verify(
      password,
      base64Decode(record.passwordSalt),
      record.passwordHash,
    );
    if (!valid) {
      final attempts = record.failedAttempts + 1;
      final lockedUntil = attempts >= _maxAttempts
          ? now.add(_lockDuration)
          : null;
      final updated = record.copyWith(
        failedAttempts: lockedUntil == null ? attempts : 0,
        lockedUntil: lockedUntil,
      );
      final records = [...store.credentials]..[index] = updated;
      await _saveStore(store.copyWith(credentials: records));
      if (lockedUntil != null) {
        throw const AuthException(
          'Too many attempts. Signing in is locked for 30 seconds.',
        );
      }
      throw const AuthException('Invalid email or password.');
    }

    final records = [...store.credentials]
      ..[index] = record.copyWith(failedAttempts: 0, clearLockedUntil: true);
    await _saveStore(
      store.copyWith(credentials: records, activeUserId: record.user.id),
    );
    return record.user;
  }

  Future<void> resetPassword({
    required String email,
    required String recoveryCode,
    required String newPassword,
  }) async {
    final passwordError = validatePassword(newPassword);
    if (passwordError != null) throw AuthException(passwordError);
    final store = await _loadStore();
    final index = store.credentials.indexWhere(
      (item) => item.user.email == _normalizeEmail(email),
    );
    if (index == -1) {
      throw const AuthException('The email or recovery code is incorrect.');
    }
    final record = store.credentials[index];
    final valid = await _verify(
      _normalizeRecovery(recoveryCode),
      base64Decode(record.recoverySalt),
      record.recoveryHash,
    );
    if (!valid) {
      throw const AuthException('The email or recovery code is incorrect.');
    }
    final salt = _randomBytes(16);
    final updated = record.copyWith(
      passwordSalt: base64Encode(salt),
      passwordHash: await _hash(newPassword, salt),
      failedAttempts: 0,
      clearLockedUntil: true,
    );
    final records = [...store.credentials]..[index] = updated;
    await _saveStore(store.copyWith(credentials: records));
  }

  Future<void> activate(String userId) async {
    final store = await _loadStore();
    if (!store.credentials.any((item) => item.user.id == userId)) {
      throw const AuthException('Account could not be activated.');
    }
    await _saveStore(store.copyWith(activeUserId: userId));
  }

  Future<void> deactivate() async {
    final store = await _loadStore();
    await _saveStore(store.copyWith(clearActiveUser: true));
  }

  Future<void> deleteAccount(String userId, String password) async {
    final store = await _loadStore();
    final record = store.credentials
        .where((item) => item.user.id == userId)
        .firstOrNull;
    if (record == null ||
        !await _verify(
          password,
          base64Decode(record.passwordSalt),
          record.passwordHash,
        )) {
      throw const AuthException('Password confirmation did not match.');
    }
    await _saveStore(
      store.copyWith(
        credentials: store.credentials
            .where((item) => item.user.id != userId)
            .toList(),
        clearActiveUser: true,
      ),
    );
  }

  static String? validatePassword(String password) {
    if (password.length < 10) return 'Use at least 10 characters.';
    if (!RegExp('[A-Z]').hasMatch(password) ||
        !RegExp('[a-z]').hasMatch(password) ||
        !RegExp('[0-9]').hasMatch(password)) {
      return 'Include uppercase, lowercase, and a number.';
    }
    return null;
  }

  Future<String> _hash(String value, List<int> salt) async {
    final key = await _passwordHasher.deriveKeyFromPassword(
      password: value,
      nonce: salt,
    );
    return base64Encode(await key.extractBytes());
  }

  Future<bool> _verify(String value, List<int> salt, String expected) async {
    final actual = base64Decode(await _hash(value, salt));
    final expectedBytes = base64Decode(expected);
    if (actual.length != expectedBytes.length) return false;
    var difference = 0;
    for (var index = 0; index < actual.length; index += 1) {
      difference |= actual[index] ^ expectedBytes[index];
    }
    return difference == 0;
  }

  Future<_AuthStore> _loadStore() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(_storageKey);
    if (encoded == null) return const _AuthStore(credentials: []);
    try {
      return _AuthStore.fromJson(
        Map<String, dynamic>.from(jsonDecode(encoded) as Map),
      );
    } catch (_) {
      return const _AuthStore(credentials: []);
    }
  }

  Future<void> _saveStore(_AuthStore store) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageKey, jsonEncode(store.toJson()));
  }

  List<int> _randomBytes(int length) {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }

  String _newRecoveryCode() {
    final random = Random.secure();
    final raw = List.generate(
      16,
      (_) => _recoveryAlphabet[random.nextInt(_recoveryAlphabet.length)],
    ).join();
    return [
      raw.substring(0, 4),
      raw.substring(4, 8),
      raw.substring(8, 12),
      raw.substring(12),
    ].join('-');
  }

  String _normalizeEmail(String value) => value.trim().toLowerCase();
  String _normalizeRecovery(String value) =>
      value.replaceAll(RegExp('[^A-Za-z0-9]'), '').toUpperCase();
  bool _isValidEmail(String value) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
}

class _StoredCredential {
  const _StoredCredential({
    required this.user,
    required this.passwordSalt,
    required this.passwordHash,
    required this.recoverySalt,
    required this.recoveryHash,
    this.failedAttempts = 0,
    this.lockedUntil,
  });

  final LocalUser user;
  final String passwordSalt;
  final String passwordHash;
  final String recoverySalt;
  final String recoveryHash;
  final int failedAttempts;
  final DateTime? lockedUntil;

  _StoredCredential copyWith({
    String? passwordSalt,
    String? passwordHash,
    int? failedAttempts,
    DateTime? lockedUntil,
    bool clearLockedUntil = false,
  }) => _StoredCredential(
    user: user,
    passwordSalt: passwordSalt ?? this.passwordSalt,
    passwordHash: passwordHash ?? this.passwordHash,
    recoverySalt: recoverySalt,
    recoveryHash: recoveryHash,
    failedAttempts: failedAttempts ?? this.failedAttempts,
    lockedUntil: clearLockedUntil ? null : lockedUntil ?? this.lockedUntil,
  );

  Map<String, dynamic> toJson() => {
    'user': user.toJson(),
    'passwordSalt': passwordSalt,
    'passwordHash': passwordHash,
    'recoverySalt': recoverySalt,
    'recoveryHash': recoveryHash,
    'failedAttempts': failedAttempts,
    'lockedUntil': lockedUntil?.toIso8601String(),
  };

  factory _StoredCredential.fromJson(Map<String, dynamic> json) =>
      _StoredCredential(
        user: LocalUser.fromJson(
          Map<String, dynamic>.from(json['user'] as Map),
        ),
        passwordSalt: json['passwordSalt'] as String,
        passwordHash: json['passwordHash'] as String,
        recoverySalt: json['recoverySalt'] as String,
        recoveryHash: json['recoveryHash'] as String,
        failedAttempts: json['failedAttempts'] as int? ?? 0,
        lockedUntil: json['lockedUntil'] == null
            ? null
            : DateTime.parse(json['lockedUntil'] as String),
      );
}

class _AuthStore {
  const _AuthStore({required this.credentials, this.activeUserId});

  final List<_StoredCredential> credentials;
  final String? activeUserId;

  _AuthStore copyWith({
    List<_StoredCredential>? credentials,
    String? activeUserId,
    bool clearActiveUser = false,
  }) => _AuthStore(
    credentials: credentials ?? this.credentials,
    activeUserId: clearActiveUser ? null : activeUserId ?? this.activeUserId,
  );

  Map<String, dynamic> toJson() => {
    'credentials': credentials.map((item) => item.toJson()).toList(),
    'activeUserId': activeUserId,
  };

  factory _AuthStore.fromJson(Map<String, dynamic> json) => _AuthStore(
    credentials: (json['credentials'] as List? ?? const [])
        .map(
          (item) => _StoredCredential.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList(),
    activeUserId: json['activeUserId'] as String?,
  );
}
