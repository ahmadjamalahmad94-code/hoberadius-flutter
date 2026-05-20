import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const defaultApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:5000',
);

String normalizeApiBaseUrl({
  required String scheme,
  required String host,
}) {
  final selectedScheme = scheme == 'http' ? 'http' : 'https';
  var raw = host.trim();
  if (raw.isEmpty) {
    throw const FormatException('server_required');
  }
  raw = raw.replaceAll(RegExp(r'\s+'), '');
  if (raw.endsWith('/')) raw = raw.substring(0, raw.length - 1);

  final withScheme = raw.startsWith(RegExp(r'https?://'));
  final uri = Uri.tryParse(withScheme ? raw : '$selectedScheme://$raw');
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
    throw const FormatException('server_invalid');
  }
  if (uri.scheme != 'http' && uri.scheme != 'https') {
    throw const FormatException('scheme_invalid');
  }
  return '${uri.scheme}://${uri.authority}';
}

abstract class ApiEndpointStorage {
  Future<String> readBaseUrl();
  Future<void> writeBaseUrl(String baseUrl);
}

class PrefsApiEndpointStorage implements ApiEndpointStorage {
  static const _key = 'hoberadius.api_base_url';

  @override
  Future<String> readBaseUrl() async {
    final p = await SharedPreferences.getInstance();
    final stored = p.getString(_key);
    if (stored == null || stored.trim().isEmpty) return defaultApiBaseUrl;
    return stored;
  }

  @override
  Future<void> writeBaseUrl(String baseUrl) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, baseUrl);
  }
}

final apiEndpointStorageProvider = Provider<ApiEndpointStorage>((ref) {
  return PrefsApiEndpointStorage();
});
