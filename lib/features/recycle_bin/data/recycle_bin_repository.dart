import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/recycle_bin_model.dart';

class RecycleBinRepository {
  RecycleBinRepository(this._api);

  final ApiClient _api;

  Future<List<RecycleBinItem>> list({String entityType = ''}) async {
    final res = await _api.get(
      '/api/v1/recycle-bin',
      query: {
        if (entityType.isNotEmpty) 'entity_type': entityType,
      },
    );
    final items = (res['data']?['items'] ?? const []) as List;
    return items
        .whereType<Map<String, dynamic>>()
        .map(RecycleBinItem.fromJson)
        .toList();
  }

  Future<void> restore(RecycleBinItem item) async {
    await _api
        .post('/api/v1/recycle-bin/${item.entityType}/${item.id}/restore');
  }

  /// Permanently archives a soft-deleted item (web recycle_bin archive).
  Future<void> archive(RecycleBinItem item) async {
    await _api
        .post('/api/v1/recycle-bin/${item.entityType}/${item.id}/archive');
  }
}

final recycleBinRepositoryProvider = Provider<RecycleBinRepository>((ref) {
  return RecycleBinRepository(ref.watch(apiClientProvider));
});
