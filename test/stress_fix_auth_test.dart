import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/core/api/api_client.dart';
import 'package:hoberadius_app/core/api/api_endpoint_storage.dart';
import 'package:hoberadius_app/core/api/api_exception.dart';
import 'package:hoberadius_app/core/api/visible_error_message.dart';
import 'package:hoberadius_app/core/auth/auth_controller.dart';
import 'package:hoberadius_app/core/auth/token_storage.dart';

import 'support/fake_api.dart';

class _Tokens implements TokenStorage {
  _Tokens(this.token);
  String? token;
  @override
  Future<void> clear() async => token = null;
  @override
  Future<String?> read() async => token;
  @override
  Future<void> write(String t) async => token = t;
}

class _Endpoint implements ApiEndpointStorage {
  @override
  Future<String> readBaseUrl() async => 'http://127.0.0.1:5000';
  @override
  Future<void> writeBaseUrl(String baseUrl) async {}
}

void main() {
  test('403 keeps the server Arabic reason (view-only manager)', () async {
    final adapter = RecordingAdapter(
      (_) => FakeResponse.error(
        403,
        'forbidden',
        'لا تملك صلاحية تعديل المشتركين.',
      ),
    );
    final api = fakeApiClient(adapter);
    try {
      await api.patch('/api/v1/accounts/u', body: {'full_name': 'x'});
      fail('should throw');
    } catch (e) {
      expect(visibleErrorMessage(e), 'لا تملك صلاحية تعديل المشتركين.');
    }
  });

  test('login lockout 429 is shown at once (no retries) in Arabic', () async {
    final adapter = RecordingAdapter(
      (_) => FakeResponse.error(
        429,
        'rate_limited',
        'محاولات دخول فاشلة كثيرة. أعد المحاولة بعد 14 دقيقة.',
      ),
    );
    final api = ApiClient(
      _Tokens(null),
      _Endpoint(),
      config: const ApiClientConfig(maxRetries: 3),
    );
    api.dio.httpClientAdapter = adapter;
    try {
      await api.post('/api/admin/login', body: {'username': 'a'});
      fail('should throw');
    } on ApiException catch (e) {
      expect(e.status, 429);
      expect(e.message, contains('محاولات دخول فاشلة'));
    }
    expect(adapter.requests, hasLength(1));
  });

  test('401 on an authenticated call signs out with the server message',
      () async {
    final tokens = _Tokens('live-token');
    final adapter = RecordingAdapter((r) {
      if (r.path == '/api/admin/me') {
        return FakeResponse.ok({
          'admin': {'id': 1, 'username': 'owner'},
        });
      }
      return FakeResponse.error(
        401,
        'token_revoked',
        'تم إنهاء هذه الجلسة بعد تغيير كلمة المرور.',
      );
    });
    final container = ProviderContainer(
      overrides: [
        tokenStorageProvider.overrideWithValue(tokens),
        apiEndpointStorageProvider.overrideWithValue(_Endpoint()),
        apiClientProvider.overrideWithValue(fakeApiClient(adapter)),
      ],
    );
    addTearDown(container.dispose);
    container.read(authControllerProvider);
    // let _restore() finish
    for (var i = 0; i < 20; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(container.read(authControllerProvider).isAuthenticated, isTrue);
    await expectLater(
      container.read(apiClientProvider).get('/api/v1/accounts'),
      throwsA(isA<ApiException>()),
    );
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    final auth = container.read(authControllerProvider);
    expect(auth.isAuthenticated, isFalse);
    expect(auth.error, contains('تم إنهاء هذه الجلسة'));
    expect(tokens.token, isNull);
  });
}
