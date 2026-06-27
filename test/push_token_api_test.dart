import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/core/api/api_client.dart';
import 'package:hoberadius_app/core/api/api_endpoint_storage.dart';
import 'package:hoberadius_app/core/auth/token_storage.dart';
import 'package:hoberadius_app/features/notifications/push/push_token_api.dart';

class _MemTokenStorage implements TokenStorage {
  @override
  Future<void> clear() async {}
  @override
  Future<String?> read() async => 'tkn';
  @override
  Future<void> write(String token) async {}
}

class _MemEndpointStorage implements ApiEndpointStorage {
  @override
  Future<String> readBaseUrl() async => 'http://127.0.0.1:5000';
  @override
  Future<void> writeBaseUrl(String baseUrl) async {}
}

void main() {
  late ApiClient client;
  late List<RequestOptions> captured;

  setUp(() {
    client = ApiClient(_MemTokenStorage(), _MemEndpointStorage());
    captured = [];
    client.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, h) {
          captured.add(o);
          h.resolve(
            Response(
              requestOptions: o,
              statusCode: 200,
              data: const {'ok': true, 'data': <String, dynamic>{}},
            ),
          );
        },
      ),
    );
  });

  test('register posts token + platform=android to the device endpoint',
      () async {
    await PushTokenApi(client).register('FCMTOKEN123');
    expect(captured, hasLength(1));
    final req = captured.single;
    expect(req.method, 'POST');
    expect(req.path, '/api/v1/devices/push-token');
    expect(req.data, {'token': 'FCMTOKEN123', 'platform': 'android'});
  });

  test('unregister DELETEs with token in the JSON body', () async {
    await PushTokenApi(client).unregister('FCMTOKEN123');
    expect(captured, hasLength(1));
    final req = captured.single;
    expect(req.method, 'DELETE');
    expect(req.path, '/api/v1/devices/push-token');
    expect(req.data, {'token': 'FCMTOKEN123'});
  });
}
