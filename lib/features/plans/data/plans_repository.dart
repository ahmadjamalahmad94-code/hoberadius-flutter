import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/plan_model.dart';

class PlansRepository {
  PlansRepository(this._api);
  final ApiClient _api;

  Future<List<Plan>> list() async {
    final res = await _api.get('/api/v1/profiles');
    final items = (res['data']?['items'] ?? res['items'] ?? const []) as List;
    return items.whereType<Map<String, dynamic>>().map(Plan.fromJson).toList();
  }

  Future<Plan> get(int id) async {
    final res = await _api.get('/api/v1/profiles/$id');
    final d = res['data'];
    return Plan.fromJson(d is Map<String, dynamic> ? d : res);
  }

  Future<Plan> create(Plan p) async {
    final res = await _api.post('/api/v1/profiles', body: p.toBody());
    final d = res['data'];
    return Plan.fromJson(d is Map<String, dynamic> ? d : res);
  }

  Future<Plan> update(int id, Plan p) async {
    final res = await _api.patch('/api/v1/profiles/$id', body: p.toBody());
    final d = res['data'];
    return Plan.fromJson(d is Map<String, dynamic> ? d : res);
  }

  Future<void> delete(int id) => _api.delete('/api/v1/profiles/$id');
}

final plansRepositoryProvider = Provider<PlansRepository>((ref) {
  return PlansRepository(ref.watch(apiClientProvider));
});
