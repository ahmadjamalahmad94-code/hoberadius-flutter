import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/nas_model.dart';

class NasRepository {
  NasRepository(this._api);
  final ApiClient _api;

  Future<List<NasDevice>> list() async {
    final res = await _api.get('/api/v1/nas');
    final items = (res['data']?['items'] ?? const []) as List;
    return items.whereType<Map<String, dynamic>>().map(NasDevice.fromJson).toList();
  }

  Future<NasDevice> get(int id) async {
    final res = await _api.get('/api/v1/nas/$id');
    final d = res['data'];
    return NasDevice.fromJson(d is Map<String, dynamic> ? d : res);
  }

  Future<NasDevice> create(NasDevice d) async {
    final res = await _api.post('/api/v1/nas', body: d.toBody());
    final j = res['data'];
    return NasDevice.fromJson(j is Map<String, dynamic> ? j : res);
  }

  Future<NasDevice> update(int id, NasDevice d) async {
    final res = await _api.patch('/api/v1/nas/$id', body: d.toBody());
    final j = res['data'];
    return NasDevice.fromJson(j is Map<String, dynamic> ? j : res);
  }

  Future<void> delete(int id) => _api.delete('/api/v1/nas/$id');

  Future<NasTestResult> test(int id) async {
    final res = await _api.post('/api/v1/nas/$id/test');
    final d = (res['data'] ?? const {}) as Map<String, dynamic>;
    return NasTestResult.fromJson(d);
  }
}

final nasRepositoryProvider = Provider<NasRepository>((ref) {
  return NasRepository(ref.watch(apiClientProvider));
});
