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

  Future<BackupRun?> runLocalBackup() async {
    final res = await _api.post('/api/v1/backups/run');
    final data = res['data'];
    if (data is! Map<String, dynamic>) return null;
    final run = data['run'];
    return run is Map<String, dynamic> ? BackupRun.fromJson(run) : null;
  }
}

final backupsRepositoryProvider = Provider<BackupsRepository>((ref) {
  return BackupsRepository(ref.watch(apiClientProvider));
});
