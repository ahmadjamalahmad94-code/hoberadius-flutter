import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/plan_model.dart';

class PlansRepository {
  PlansRepository(this._api);
  final ApiClient _api;

  Future<List<Plan>> list() async {
    final res = await _api.get('/api/v1/profiles');
    final items = (res['data']?['items'] ?? res['items'] ?? []) as List;
    return items.whereType<Map<String, dynamic>>().map(Plan.fromJson).toList();
  }

  Future<Plan> get(int id) async {
    final res = await _api.get('/api/v1/profiles/$id');
    final d = res['data'];
    return Plan.fromJson(d is Map<String, dynamic> ? d : res);
  }
}

final plansRepositoryProvider = Provider<PlansRepository>((ref) {
  return PlansRepository(ref.watch(apiClientProvider));
});
