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

  Future<LicenseFileState> licenseFile() async {
    final res = await _api.get('/api/v1/system/license-file');
    return LicenseFileState.fromJson(_data(res));
  }

  Future<Map<String, dynamic>> syncLicenseContract() async {
    final res = await _api.post('/api/v1/system/admin-bridge/license-sync');
    return _data(res);
  }

  Future<Map<String, dynamic>> syncIdentity() async {
    final res = await _api.post('/api/v1/system/admin-bridge/identity-sync');
    return _data(res);
  }

  Future<Map<String, dynamic>> sendHeartbeatProbe() async {
    final res = await _api.post(
      '/api/v1/system/admin-bridge/heartbeat',
      body: const {'dry_run': true},
    );
    return _data(res);
  }

  Future<BridgeEventsState> bridgeEvents() async {
    final res = await _api.get('/api/v1/system/admin-bridge/events');
    return BridgeEventsState.fromJson(_data(res));
  }

  Future<Map<String, dynamic>> capacityStatus() async {
    final res = await _api.get('/api/v1/system/admin-bridge/capacity-status');
    return _data(res);
  }

  Future<Map<String, dynamic>> usageReport() async {
    final res = await _api.get('/api/v1/system/admin-bridge/usage-report');
    return _data(res);
  }

  /// Backup restore via the licensing bridge. `restorePoll` lists restorable
  /// references; `restoreSnapshot` previews one; `restoreApply` applies it.
  Future<Map<String, dynamic>> restorePoll() async {
    final res = await _api.post('/api/v1/system/admin-bridge/restore/poll');
    return _data(res);
  }

  Future<Map<String, dynamic>> restoreSnapshot(String reference) async {
    final res = await _api.post(
      '/api/v1/system/admin-bridge/restore/$reference/snapshot',
    );
    return _data(res);
  }

  Future<Map<String, dynamic>> restoreApply(String reference) async {
    final res = await _api.post(
      '/api/v1/system/admin-bridge/restore/$reference/apply',
    );
    return _data(res);
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
