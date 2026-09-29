import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/auth/permissions.dart';
import '../data/tools_repository.dart';
import '../domain/tools_models.dart';

final radiusLogProvider = FutureProvider.autoDispose<RadiusLogSnapshot>((ref) {
  return ref.watch(toolsRepositoryProvider).radiusLog();
});

/// Per-tool permission map for the tools screen (fix2-final):
/// - `grants.tools` of /api/admin/me (or the login answer) when sent;
/// - else `GET /api/v1/tools` (`allowed` map, or `items[].allowed`);
/// - else null = unknown (older server): every tool is shown, as before,
///   and the server answers what it refuses with its Arabic reason.
///
/// Owner / co-owner and the legacy contract never ask the server.
final toolsAccessProvider =
    FutureProvider.autoDispose<Map<String, bool>?>((ref) async {
  final perms = ref.watch(permissionsProvider);
  if (perms.legacy || perms.isOwner) return null;
  if (perms.tools != null) return perms.tools;
  try {
    final res = await ref
        .read(apiClientProvider)
        .get('/api/v1/tools', background: true);
    return parseToolsAccess(res['data']);
  } catch (_) {
    return null; // an older server has no /api/v1/tools — show all
  }
});

/// `GET /api/v1/tools` data → tool key → allowed (null when unusable).
Map<String, bool>? parseToolsAccess(Object? data) {
  if (data is! Map) return null;
  final allowed = data['allowed'];
  if (allowed is Map && allowed.isNotEmpty) {
    return {for (final e in allowed.entries) '${e.key}': e.value == true};
  }
  final items = data['items'];
  if (items is List && items.isNotEmpty) {
    final out = <String, bool>{
      for (final i in items)
        if (i is Map && '${i['key'] ?? ''}'.isNotEmpty)
          '${i['key']}': i['allowed'] == true,
    };
    return out.isEmpty ? null : out;
  }
  return null;
}

/// The tools to show for [access] (null = all), in tab order.
List<String> visibleToolKeys(Map<String, bool>? access) => [
      for (final k in kToolKeys)
        if (access == null || access[k] == true) k,
    ];
