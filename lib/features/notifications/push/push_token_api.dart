import '../../../core/api/api_client.dart';

/// Device push-token registration calls (kept transport-agnostic + free of any
/// firebase import so they're unit-testable on any host). The backend stores
/// the token per tenant/admin (auth via the app's existing Bearer token).
///
/// Backend contract (radius-module — app/api/v1/devices.py):
///   POST   /api/v1/devices/push-token   { token, platform }
///   DELETE /api/v1/devices/push-token   { token }   (token in BODY, not path)
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
    // The backend (push_token_unregister) reads the token from the JSON body at
    // the base path — there is no `/push-token/<token>` route — so send it in
    // the body, not the URL.
    return _api.delete(
      '/api/v1/devices/push-token',
      body: {'token': token},
    );
  }
}
