import 'dart:convert';
import 'dart:math';

/// Header the money endpoints read (`/accounts/<u>/{payment,balance,loan,
/// extend,quota/topup}`, `POST /payments`, `POST /loans`, `/loans/<id>/settle`).
/// The server stores the first answer for 24 h and replays it for the same
/// key, so a double tap or a retry after a lost response never records the
/// money twice. Older servers ignore the header.
const kIdempotencyHeader = 'Idempotency-Key';

final Random _secure = Random.secure();

/// Random RFC-4122 v4 UUID (no extra package needed).
String newIdempotencyKey() {
  final b = List<int>.generate(16, (_) => _secure.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  String hex(int from, int to) => b
      .sublist(from, to)
      .map((v) => v.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
}

Map<String, String> idempotencyHeaders(String? key) =>
    key == null || key.isEmpty ? const {} : {kIdempotencyHeader: key};

/// One key per dialog **submission**: retrying the same request (same
/// endpoint + same body) reuses the key so the server can replay the first
/// answer; changing anything (amount, choices…) is a new submission and gets
/// a new key. Call [reset] after a success.
class IdempotencyKeeper {
  String? _fingerprint;
  String? _key;

  String keyFor(String endpoint, Object? body) {
    final fp = '$endpoint|${_stableJson(body)}';
    if (_key == null || fp != _fingerprint) {
      _fingerprint = fp;
      _key = newIdempotencyKey();
    }
    return _key!;
  }

  String? get current => _key;

  void reset() {
    _fingerprint = null;
    _key = null;
  }
}

String _stableJson(Object? value) {
  Object? canon(Object? v) {
    if (v is Map) {
      final keys = v.keys.map((k) => k.toString()).toList()..sort();
      return {for (final k in keys) k: canon(v[k])};
    }
    if (v is List) return v.map(canon).toList();
    return v;
  }

  try {
    return jsonEncode(canon(value));
  } catch (_) {
    return value.toString();
  }
}
