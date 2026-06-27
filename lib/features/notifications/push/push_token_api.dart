import '../../../core/api/api_client.dart';

/// Device push-token registration calls (kept transport-agnostic + free of any
/// firebase import so they're unit-testable on any host). The backend stores
/// the token per tenant/admin (auth via the app's existing Bearer token).
///
/// Backend contract (radius-module, app/api/v1/devices.py):
///   POST   /api/v1/devices/push-token   { token, platform, app_version? }
///   DELETE /api/v1/devices/push-token   { token }   ← token in JSON body
class PushTokenApi {
  const PushTokenApi(this._api);
  final ApiClient _api;

  Future<void> register(
    String token, {
    String platform = 'android',
    String appVersion = '',
  }) {
    return _api.post(
      '/api/v1/devices/push-token',
      body: {
        'token': token,
        'platform': platform,
        if (appVersion.isNotEmpty) 'app_version': appVersion,
      },
    );
  }

  Future<void> unregister(String token) {
    return _api.delete(
      '/api/v1/devices/push-token',
      body: {'token': token},
    );
  }
}
