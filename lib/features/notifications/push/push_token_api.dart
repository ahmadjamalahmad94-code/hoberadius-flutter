import '../../../core/api/api_client.dart';

/// Device push-token registration calls (kept transport-agnostic + free of any
/// firebase import so they're unit-testable on any host). The backend stores
/// the token per tenant/admin (auth via the app's existing Bearer token).
///
/// Backend contract (radius-module):
///   POST   /api/v1/devices/push-token        { token, platform }
///   DELETE /api/v1/devices/push-token/<token>
class PushTokenApi {
  const PushTokenApi(this._api);
  final ApiClient _api;

  Future<void> register(String token, {String platform = 'android'}) {
    return _api.post(
      '/api/v1/devices/push-token',
      body: {'token': token, 'platform': platform},
    );
  }

  Future<void> unregister(String token) {
    return _api.delete('/api/v1/devices/push-token/$token');
  }
}
