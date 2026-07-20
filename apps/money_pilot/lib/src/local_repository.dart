import 'package:dio/dio.dart';
import 'package:money_pilot/src/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalRepository {
  LocalRepository({this.userId = 'signed-out'});

  final String userId;
  String get _storageKey => 'money_pilot_app_data_v2_$userId';

  Future<AppData?> load() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(_storageKey);
    if (encoded == null) return null;
    try {
      return AppData.decode(encoded);
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  Future<void> save(AppData data) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageKey, data.encode());
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_storageKey);
  }
}

class DioSyncGateway {
  DioSyncGateway({Dio? client})
    : _client =
          client ??
          Dio(
            BaseOptions(
              baseUrl: 'https://api.moneypilot.example/api/v1',
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 8),
              headers: const {'Accept': 'application/json'},
            ),
          );

  final Dio _client;

  String get configuredEndpoint => _client.options.baseUrl;

  Future<String> sync(AppData data) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!data.settings.cloudSync) return 'Device-only • saved locally';
    // The milestone intentionally queues rather than transmitting private data.
    // A production API adapter can POST through [_client] after authentication.
    return 'Sync demo only • data remains local';
  }
}
