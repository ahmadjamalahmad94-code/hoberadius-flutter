import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/lifecycle_model.dart';

class LifecycleRepository {
  LifecycleRepository(this._api);

  final ApiClient _api;

  Future<List<LifecyclePolicy>> listPolicies({String entityType = ''}) async {
    final res = await _api.get(
      '/api/v1/lifecycle/policies',
      query: {
        if (entityType.isNotEmpty) 'entity_type': entityType,
      },
    );
    final data = res['data'];
    final items = data is Map<String, dynamic> ? data['items'] : const [];
    return (items as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(LifecyclePolicy.fromJson)
        .toList();
  }

  Future<LifecyclePolicy> createPolicy(LifecyclePolicy policy) async {
    final res = await _api.post(
      '/api/v1/lifecycle/policies',
      body: policy.toBody(),
    );
    final data = res['data'];
    return LifecyclePolicy.fromJson(
      data is Map<String, dynamic> ? data : const {},
    );
  }

  Future<LifecyclePolicy> updatePolicy(LifecyclePolicy policy) async {
    final res = await _api.patch(
      '/api/v1/lifecycle/policies/${policy.id}',
      body: policy.toBody(),
    );
    final data = res['data'];
    return LifecyclePolicy.fromJson(
      data is Map<String, dynamic> ? data : const {},
    );
  }

  Future<LifecyclePolicy> disablePolicy(int policyId) async {
    final res = await _api.post('/api/v1/lifecycle/policies/$policyId/disable');
    final data = res['data'];
    return LifecyclePolicy.fromJson(
      data is Map<String, dynamic> ? data : const {},
    );
  }

  Future<LifecyclePreview> preview({int limit = 500}) async {
    final res = await _api.post(
      '/api/v1/lifecycle/preview',
      body: {'limit': limit},
    );
    return LifecyclePreview.fromJson(res);
  }

  Future<LifecycleRunResult> run({int limit = 500}) async {
    final res = await _api.post(
      '/api/v1/lifecycle/run',
      body: {'limit': limit},
    );
    return LifecycleRunResult.fromJson(res);
  }
}

final lifecycleRepositoryProvider = Provider<LifecycleRepository>((ref) {
  return LifecycleRepository(ref.watch(apiClientProvider));
});
