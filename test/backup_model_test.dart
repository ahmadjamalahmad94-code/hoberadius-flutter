import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/backups/domain/backup_model.dart';

void main() {
  test('BackupStatus parses job and recent run fields', () {
    final status = BackupStatus.fromJson({
      'job': {
        'id': 1,
        'name': 'local-manual',
        'schedule': 'manual',
        'target': 'local',
        'last_status': 'success',
        'last_message': 'verified',
        'last_run_at': '2026-05-20T12:00:00Z',
      },
      'recent_runs': [
        {
          'id': '7',
          'status': 'success',
          'path': 'instance/backups/file.sqlite3',
          'message': 'Local SQLite backup verified.',
          'created_at': '2026-05-20T12:01:00Z',
        },
      ],
      'google_drive': {
        'configured': true,
        'connected': false,
        'pending': true,
        'status': 'pending',
        'email': 'owner@example.com',
        'folder_name': 'HobeRadius Backups',
        'last_upload_at': '',
        'last_error': '',
        'message_ar': 'طلب ربط جوجل درايف بانتظار إكمال التحقق من المستخدم.',
      },
    });

    expect(status.job.lastStatus, 'success');
    expect(status.job.lastRunAt, isNotNull);
    expect(status.recentRuns, hasLength(1));
    expect(status.recentRuns.first.id, 7);
    expect(status.recentRuns.first.statusLabel, 'ناجحة');
    expect(status.recentRuns.first.path, contains('backups'));
    expect(status.googleDrive.configured, isTrue);
    expect(status.googleDrive.pending, isTrue);
    expect(status.googleDrive.messageAr, contains('جوجل درايف'));
  });
}
