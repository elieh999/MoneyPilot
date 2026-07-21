import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_pilot/src/initial_data.dart';
import 'package:money_pilot/src/local_repository.dart';
import 'package:money_pilot/src/models.dart';

void main() {
  test('API session authenticates and verifies the current user', () async {
    final requests = <RequestOptions>[];
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests.add(options);
            if (options.path.endsWith('/auth/login')) {
              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {'access_token': 'test-token'},
                ),
              );
            } else {
              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {'status': 'ready'},
                ),
              );
            }
          },
        ),
      );
    final gateway = DioSyncGateway(client: dio);

    expect(
      await gateway.connect(
        baseUrl: 'http://localhost:8000/',
        email: 'person@example.com',
        password: 'not-persisted', // gitleaks:allow
      ),
      'API connected • session active',
    );
    final data = buildEmptyData().copyWith(
      settings: const AppSettings(cloudSync: true),
    );
    expect(
      await gateway.sync(data),
      'API connected • financial upload remains off',
    );
    expect(requests, hasLength(3));
    expect(requests.last.headers['Authorization'], 'Bearer test-token');
  });

  test('local mode does not make a network request', () async {
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) =>
              fail('Network should not be used in local mode.'),
        ),
      );
    final gateway = DioSyncGateway(client: dio);
    expect(
      await gateway.sync(buildEmptyData()),
      'Stored on this device • encrypted locally',
    );
  });
}
