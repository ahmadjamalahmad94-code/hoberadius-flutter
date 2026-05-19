import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/nas_model.dart';

class NasRepository {
  NasRepository(this._api);
  final ApiClient _api;

  Future<List<NasDevice>> list() async {
    final res = await _api.get('/api/v1/nas');
    final items = (res['data']?['items'] ?? res['items'] ?? []) as List;
    return items.whereType<Map<String, dynamic>>().map(NasDevice.fromJson).toList();
  }

  /// Endpoint to be wired on the Flask side; until then this will surface a
  /// 404 from the api client, which the UI handles gracefully.
  Future<NasTestResult> test(int id) async {
    final res = await _api.post('/api/v1/nas/$id/test');
    final d = (res['data'] ?? res) as Map<String, dynamic>;
    return NasTestResult.fromJson(d);
  }
}

final nasRepositoryProvider = Provider<NasRepository>((ref) {
  return NasRepository(ref.watch(apiClientProvider));
});
