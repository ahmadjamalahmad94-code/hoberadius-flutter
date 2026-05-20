import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/system_operations_model.dart';

class SystemOperationsRepository {
  SystemOperationsRepository(this._api);

  final ApiClient _api;

  Future<SystemStatus> status() async {
    final res = await _api.get('/api/v1/system/status');
    return SystemStatus.fromJson(_data(res));
  }

  Future<SystemDiagnostics> diagnostics() async {
    final res = await _api.get('/api/v1/system/diagnostics');
    return SystemDiagnostics.fromJson(_data(res));
  }

  Future<SyncQueueState> syncQueue({String? status}) async {
    final res = await _api.get(
      '/api/v1/system/sync',
      query: {
        if (status != null && status.isNotEmpty && status != 'all')
          'status': status,
      },
    );
    return SyncQueueState.fromJson(_data(res));
  }

  Future<SyncJob?> retrySyncJob(int id) async {
    final res = await _api.post('/api/v1/system/sync/$id/retry');
    final job = _data(res)['job'];
    return job is Map<String, dynamic> ? SyncJob.fromJson(job) : null;
  }

  Future<SyncJob?> cancelSyncJob(int id) async {
    final res = await _api.post('/api/v1/system/sync/$id/cancel');
    final job = _data(res)['job'];
    return job is Map<String, dynamic> ? SyncJob.fromJson(job) : null;
  }

  Future<ReconcileResult> reconcile() async {
    final res = await _api.post('/api/v1/system/reconcile');
    return ReconcileResult.fromJson(_data(res));
  }

  Map<String, dynamic> _data(Map<String, dynamic> response) {
    final data = response['data'];
    return data is Map<String, dynamic> ? data : const {};
  }
}

final systemOperationsRepositoryProvider =
    Provider<SystemOperationsRepository>((ref) {
  return SystemOperationsRepository(ref.watch(apiClientProvider));
});
