import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores the API bearer token.
///
/// On mobile/desktop uses flutter_secure_storage (keychain/keystore).
/// On web falls back to SharedPreferences because secure_storage doesn't
/// support web keychain APIs; web cookies aren't an option here because the
/// app must work cross-origin against the Flask backend.
abstract class TokenStorage {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> clear();
}

class _SecureTokenStorage implements TokenStorage {
  static const _key = 'hoberadius.api_token';
  final _s = const FlutterSecureStorage();

  @override
  Future<String?> read() => _s.read(key: _key);

  @override
  Future<void> write(String token) => _s.write(key: _key, value: token);

  @override
  Future<void> clear() => _s.delete(key: _key);
}

class _PrefsTokenStorage implements TokenStorage {
  static const _key = 'hoberadius.api_token';

  @override
  Future<String?> read() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_key);
  }

  @override
  Future<void> write(String token) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, token);
  }

  @override
  Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_key);
  }
}

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return kIsWeb ? _PrefsTokenStorage() : _SecureTokenStorage();
});
