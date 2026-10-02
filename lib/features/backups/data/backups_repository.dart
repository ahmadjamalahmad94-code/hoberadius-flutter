import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/backup_model.dart';

class BackupsRepository {
  BackupsRepository(this._api);

  final ApiClient _api;

  Future<BackupStatus> status() async {
    final res = await _api.get('/api/v1/backups/status');
    final data = res['data'];
    return BackupStatus.fromJson(
      data is Map<String, dynamic> ? data : const {},
    );
  }

  /// The web «تشغيل نسخة» (run-all): local copy → license panel (paid
  /// service) → Google Drive, as one list of steps. [full] = full archive
  /// (with the log tables) instead of the lean core copy.
  Future<BackupRunAllResult> runAll({bool full = false}) async {
    final res = await _api.post(
      '/api/v1/backups/run-all',
      body: {'mode': full ? 'full' : 'lean'},
    );
    final data = res['data'];
    return BackupRunAllResult.fromJson(
      data is Map<String, dynamic> ? data : const {},
    );
  }

  /// Google Drive is linked in the customer portal (like the web button):
  /// a short-lived SSO link into it.
  Future<String> drivePortalLink() async {
    final res = await _api.post('/api/v1/backups/google-drive/portal-link');
    final data = res['data'];
    return data is Map ? (data['url'] ?? '').toString() : '';
  }
}

final backupsRepositoryProvider = Provider<BackupsRepository>((ref) {
  return BackupsRepository(ref.watch(apiClientProvider));
});
