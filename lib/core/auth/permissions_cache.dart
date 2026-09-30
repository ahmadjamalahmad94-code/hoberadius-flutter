import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The last `/api/admin/me` answer of the signed-in admin, kept on the
/// device so a cold start, a reload or an unreachable server does not open
/// the app with EVERY screen visible (f07 N-B1) and does not sign the
/// operator out (f03 N3).
///
/// The copy is bound to the session token (a fingerprint, never the token
/// itself): another admin signing in on the same phone gets a new token, so
/// the previous admin's grants are never reused. Only the fields the app
/// reads are kept (admin, grants, permissions, system, tenant).
abstract class PermissionsCacheStorage {
  Future<String?> read();
  Future<void> write(String value);
  Future<void> clear();
}

class _PrefsPermissionsCacheStorage implements PermissionsCacheStorage {
  static const _key = 'hoberadius.session_grants_v1';

  @override
  Future<String?> read() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_key);
  }

  @override
  Future<void> write(String value) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, value);
  }

  @override
  Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_key);
  }
}

/// In-memory storage (tests, or a platform without preferences).
class MemoryPermissionsCacheStorage implements PermissionsCacheStorage {
  MemoryPermissionsCacheStorage([this.value]);
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String v) async => value = v;

  @override
  Future<void> clear() async => value = null;
}

final permissionsCacheStorageProvider = Provider<PermissionsCacheStorage>(
  (ref) => _PrefsPermissionsCacheStorage(),
);

/// FNV-1a 64-bit of [token] as hex — identifies the session without
/// storing the token a second time.
String tokenFingerprint(String token) {
  // 64-bit FNV-1a split in two 32-bit halves (web-safe integer math).
  var hi = 0xcbf29ce4, lo = 0x84222325;
  const primeHi = 0x00000100, primeLo = 0x000001b3;
  for (final unit in utf8.encode(token)) {
    lo ^= unit;
    // (hi:lo) * (primeHi:primeLo) mod 2^64
    final l0 = (lo & 0xffff) * primeLo;
    final l1 = (lo >>> 16) * primeLo;
    final newLo = (l0 + ((l1 & 0xffff) << 16)) & 0xffffffff;
    final carry = ((l0 >>> 16) + l1) >>> 16;
    final newHi = (hi * primeLo + lo * primeHi + carry) & 0xffffffff;
    hi = newHi;
    lo = newLo;
  }
  String h(int v) => v.toRadixString(16).padLeft(8, '0');
  return '${h(hi)}${h(lo)}';
}

/// The subset of a /me payload worth keeping.
Map<String, dynamic> cacheableMe(Map<String, dynamic> me) => {
      for (final k in const [
        'admin',
        'grants',
        'permissions',
        'system',
        'tenant_id',
      ])
        if (me.containsKey(k)) k: me[k],
    };

/// Reads / writes the saved grants of the CURRENT session token. Never
/// throws: a storage failure only means «no saved copy».
class PermissionsCache {
  PermissionsCache(this._storage);
  final PermissionsCacheStorage _storage;

  /// The saved /me payload for [token], or null (none, other session,
  /// unreadable).
  Future<Map<String, dynamic>?> read(String token) async {
    try {
      final raw = await _storage.read();
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      if (decoded['fp'] != tokenFingerprint(token)) return null;
      final me = decoded['me'];
      return me is Map ? Map<String, dynamic>.from(me) : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> write(String token, Map<String, dynamic> me) async {
    if (token.isEmpty) return;
    try {
      await _storage.write(
        jsonEncode({'fp': tokenFingerprint(token), 'me': cacheableMe(me)}),
      );
    } catch (_) {/* best-effort */}
  }

  Future<void> clear() async {
    try {
      await _storage.clear();
    } catch (_) {/* best-effort */}
  }
}

final permissionsCacheProvider = Provider<PermissionsCache>(
  (ref) => PermissionsCache(ref.watch(permissionsCacheStorageProvider)),
);
