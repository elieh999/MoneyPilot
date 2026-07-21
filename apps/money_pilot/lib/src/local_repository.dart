import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:dio/dio.dart';
import 'package:money_pilot/src/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalRepository {
  LocalRepository({this.userId = 'signed-out'});

  final String userId;
  final AesGcm _cipher = AesGcm.with256bits();

  String get _storageKey => 'money_pilot_app_data_v2_$userId';
  String get _keyStorageKey => 'money_pilot_data_key_v1_$userId';

  Future<AppData?> load() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(_storageKey);
    if (encoded == null) return null;
    try {
      if (!encoded.startsWith('mpenc:')) {
        final migrated = AppData.decode(encoded);
        await save(migrated);
        return migrated;
      }
      final envelope = Map<String, dynamic>.from(
        jsonDecode(utf8.decode(base64Decode(encoded.substring(6)))) as Map,
      );
      final clearText = await _cipher.decrypt(
        SecretBox(
          base64Decode(envelope['ciphertext'] as String),
          nonce: base64Decode(envelope['nonce'] as String),
          mac: Mac(base64Decode(envelope['mac'] as String)),
        ),
        secretKey: SecretKey(await _loadOrCreateKey()),
        aad: utf8.encode(_storageKey),
      );
      return AppData.decode(utf8.decode(clearText));
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    } on SecretBoxAuthenticationError {
      return null;
    }
  }

  Future<void> save(AppData data) async {
    final preferences = await SharedPreferences.getInstance();
    final secretBox = await _cipher.encrypt(
      utf8.encode(data.encode()),
      secretKey: SecretKey(await _loadOrCreateKey()),
      aad: utf8.encode(_storageKey),
    );
    final envelope = base64Encode(
      utf8.encode(
        jsonEncode({
          'version': 1,
          'nonce': base64Encode(secretBox.nonce),
          'ciphertext': base64Encode(secretBox.cipherText),
          'mac': base64Encode(secretBox.mac.bytes),
        }),
      ),
    );
    await preferences.setString(_storageKey, 'mpenc:$envelope');
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_storageKey);
    await preferences.remove(_keyStorageKey);
  }

  Future<List<int>> _loadOrCreateKey() async {
    final preferences = await SharedPreferences.getInstance();
    final stored = preferences.getString(_keyStorageKey);
    if (stored != null) return base64Decode(stored);
    final random = Random.secure();
    final key = List<int>.generate(32, (_) => random.nextInt(256));
    await preferences.setString(_keyStorageKey, base64Encode(key));
    return key;
  }
}

class DioSyncGateway {
  DioSyncGateway({Dio? client}) : _client = client ?? Dio();

  final Dio _client;
  String? _accessToken;

  bool get hasSession => _accessToken != null;

  Future<String> connect({
    required String baseUrl,
    required String email,
    required String password,
  }) async {
    final endpoint = _normalizeBaseUrl(baseUrl);
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '$endpoint/api/v1/auth/login',
        data: {'email': email.trim(), 'password': password},
        options: Options(headers: const {'Accept': 'application/json'}),
      );
      _accessToken = response.data?['access_token'] as String?;
      if (_accessToken == null || _accessToken!.isEmpty) {
        return 'API login failed • invalid response';
      }
      return 'API connected • session active';
    } on DioException catch (error) {
      _accessToken = null;
      return _friendlyApiError(error, action: 'API login failed');
    }
  }

  void disconnect() => _accessToken = null;

  Future<String> sync(AppData data) async {
    if (!data.settings.cloudSync) {
      return 'Stored on this device • encrypted locally';
    }
    final endpoint = _normalizeBaseUrl(data.settings.apiBaseUrl);
    try {
      await _client.get<Map<String, dynamic>>(
        '$endpoint/health/ready',
        options: Options(headers: const {'Accept': 'application/json'}),
      );
      if (_accessToken == null) return 'API reachable • sign in to connect';
      await _client.get<Map<String, dynamic>>(
        '$endpoint/api/v1/auth/me',
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $_accessToken',
          },
        ),
      );
      return 'API connected • financial upload remains off';
    } on DioException catch (error) {
      return _friendlyApiError(error, action: 'API check failed');
    }
  }

  String _normalizeBaseUrl(String value) {
    final trimmed = value.trim().replaceFirst(RegExp(r'/+$'), '');
    return trimmed.isEmpty ? 'http://127.0.0.1:8000' : trimmed;
  }

  String _friendlyApiError(DioException error, {required String action}) {
    final status = error.response?.statusCode;
    if (status == 401) return '$action • check email and password';
    if (status != null) return '$action • server returned $status';
    return '$action • server unavailable';
  }
}
