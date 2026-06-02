import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/audit_model.dart';

class AuditQuery {
  const AuditQuery({
    this.actor,
    this.action,
    this.targetType,
    this.targetId,
    this.limit = 200,
  });
  final String? actor;
  final String? action;
  final String? targetType;
  final String? targetId;
  final int limit;

  Map<String, dynamic> toQueryParams() => {
        'limit': limit,
        if (actor != null && actor!.isNotEmpty) 'actor': actor,
        if (action != null && action!.isNotEmpty) 'action': action,
        if (targetType != null && targetType!.isNotEmpty) 'target_type': targetType,
        if (targetId != null && targetId!.isNotEmpty) 'target_id': targetId,
      };
}

class AuditRepository {
  AuditRepository(this._api);
  final ApiClient _api;

  Future<List<AuditEvent>> list(AuditQuery q) async {
    final res = await _api.get('/api/v1/audit', query: q.toQueryParams());
    final items = (res['data']?['items'] ?? const []) as List;
    return items.whereType<Map<String, dynamic>>().map(AuditEvent.fromJson).toList();
  }
}

final auditRepositoryProvider = Provider<AuditRepository>((ref) {
  return AuditRepository(ref.watch(apiClientProvider));
});

final auditQueryProvider = StateProvider.autoDispose<AuditQuery>(
  (_) => const AuditQuery(),
);

final auditListProvider = FutureProvider.autoDispose<List<AuditEvent>>((ref) {
  final q = ref.watch(auditQueryProvider);
  return ref.watch(auditRepositoryProvider).list(q);
});
