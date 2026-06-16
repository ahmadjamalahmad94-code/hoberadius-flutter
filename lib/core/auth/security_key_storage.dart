import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores the per-deployment **API security key** sent as `X-API-Key` on every
/// request.
///
/// The web `/api/v1` now enforces a valid API key on all endpoints (the global
/// `install_global_api_auth_guard` hardening). The key is a per-VPS value the
/// operator pastes once on the connection screen — it is NOT hardcoded and is
/// kept alongside the endpoint URL, not derived from the login.
///
/// Storage backend mirrors [TokenStorage]: secure keychain/keystore on
/// mobile/desktop, SharedPreferences on web (no secure-storage web API).
abstract class SecurityKeyStorage {
  Future<String?> read();
  Future<void> write(String key);
  Future<void> clear();
}

class _SecureSecurityKeyStorage implements SecurityKeyStorage {
  static const _key = 'hoberadius.api_security_key';
  final _s = const FlutterSecureStorage();

  @override
  Future<String?> read() => _s.read(key: _key);

  @override
  Future<void> write(String key) => _s.write(key: _key, value: key);

  @override
  Future<void> clear() => _s.delete(key: _key);
}

class _PrefsSecurityKeyStorage implements SecurityKeyStorage {
  static const _key = 'hoberadius.api_security_key';

  @override
  Future<String?> read() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_key);
  }

  @override
  Future<void> write(String key) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, key);
  }

  @override
  Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_key);
  }
}

final securityKeyStorageProvider = Provider<SecurityKeyStorage>((ref) {
  return kIsWeb ? _PrefsSecurityKeyStorage() : _SecureSecurityKeyStorage();
});
