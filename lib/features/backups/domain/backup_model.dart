import 'package:hoberadius_app/core/format/server_time.dart';

class BackupStatus {
  const BackupStatus({
    required this.job,
    required this.recentRuns,
    required this.googleDrive,
  });

  final BackupJob job;
  final List<BackupRun> recentRuns;
  final BackupGoogleDriveStatus googleDrive;

  factory BackupStatus.fromJson(Map<String, dynamic> json) {
    final runs = (json['recent_runs'] ?? const []) as List;
    return BackupStatus(
      job: BackupJob.fromJson(
        json['job'] is Map<String, dynamic>
            ? json['job'] as Map<String, dynamic>
            : const {},
      ),
      recentRuns: runs
          .whereType<Map<String, dynamic>>()
          .map(BackupRun.fromJson)
          .toList(),
      googleDrive: BackupGoogleDriveStatus.fromJson(
        json['google_drive'] is Map<String, dynamic>
            ? json['google_drive'] as Map<String, dynamic>
            : const {},
      ),
    );
  }
}

class BackupGoogleDriveStatus {
  const BackupGoogleDriveStatus({
    required this.configured,
    required this.connected,
    required this.pending,
    required this.status,
    required this.email,
    required this.folderName,
    required this.lastUploadAt,
    required this.lastError,
    required this.messageAr,
    this.linkVia = '',
  });

  final bool configured;
  final bool connected;
  final bool pending;
  final String status;
  final String email;
  final String folderName;
  final String lastUploadAt;
  final String lastError;
  final String messageAr;

  /// `customer_portal` on servers where Drive is linked through the customer
  /// portal SSO (the web button); empty on older servers.
  final String linkVia;

  factory BackupGoogleDriveStatus.fromJson(Map<String, dynamic> json) {
    return BackupGoogleDriveStatus(
      configured: _asBool(json['configured']),
      connected: _asBool(json['connected']),
      pending: _asBool(json['pending']),
      status: (json['status'] ?? 'not_configured').toString(),
      email: (json['email'] ?? '').toString(),
      folderName: (json['folder_name'] ?? 'HobeRadius Backups').toString(),
      lastUploadAt: (json['last_upload_at'] ?? '').toString(),
      lastError: (json['last_error'] ?? '').toString(),
      messageAr:
          (json['message_ar'] ?? 'جوجل درايف غير مفعل حاليًا').toString(),
      linkVia: (json['link_via'] ?? '').toString(),
    );
  }
}

class BackupJob {
  const BackupJob({
    required this.id,
    required this.name,
    required this.schedule,
    required this.target,
    required this.lastStatus,
    required this.lastMessage,
    required this.lastRunAt,
    this.lastStatusLabel = '',
  });

  final int id;
  final String name;
  final String schedule;
  final String target;
  final String lastStatus;
  final String lastMessage;
  final DateTime? lastRunAt;

  /// Server Arabic `last_status_label` (or `status_label`); optional.
  final String lastStatusLabel;

  /// The server's label when sent, else the app's mapping of [lastStatus].
  String get statusText => lastStatusLabel.isNotEmpty
      ? lastStatusLabel
      : backupStatusLabel(lastStatus);

  factory BackupJob.fromJson(Map<String, dynamic> json) {
    return BackupJob(
      id: _asInt(json['id']),
      name: (json['name'] ?? '').toString(),
      schedule: (json['schedule'] ?? '').toString(),
      target: (json['target'] ?? '').toString(),
      lastStatus: (json['last_status'] ?? 'never_run').toString(),
      lastMessage: (json['last_message'] ?? '').toString(),
      lastRunAt: parseServerDateTime(json['last_run_at']),
      lastStatusLabel: (json['last_status_label'] ?? json['status_label'] ?? '')
          .toString()
          .trim(),
    );
  }
}

class BackupRun {
  const BackupRun({
    required this.id,
    required this.status,
    required this.path,
    required this.message,
    required this.createdAt,
    this.serverStatusLabel = '',
  });

  final int id;
  final String status;

  /// `status_label` from the server (optional).
  final String serverStatusLabel;
  final String path;
  final String message;
  final DateTime? createdAt;

  factory BackupRun.fromJson(Map<String, dynamic> json) {
    return BackupRun(
      id: _asInt(json['id']),
      status: (json['status'] ?? '').toString(),
      path: (json['path'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      createdAt: parseServerDateTime(json['created_at']),
      serverStatusLabel: (json['status_label'] ?? '').toString().trim(),
    );
  }

  String get statusLabel => serverStatusLabel.isNotEmpty
      ? serverStatusLabel
      : backupStatusLabel(status);
}

/// One step of the run-all backup (`local` / `panel` / `drive`).
class BackupRunStep {
  const BackupRunStep({
    required this.key,
    required this.label,
    required this.status,
    required this.message,
  });

  final String key;
  final String label;

  /// `success` / `failed` / `skipped`.
  final String status;
  final String message;

  factory BackupRunStep.fromJson(Map<String, dynamic> json) => BackupRunStep(
        key: (json['key'] ?? '').toString(),
        label: (json['label'] ?? '').toString(),
        status: (json['status'] ?? '').toString(),
        message: (json['message'] ?? '').toString(),
      );

  String get statusLabel => backupStatusLabel(status);
}

/// `POST /api/v1/backups/run-all` — the web «تشغيل نسخة» (local → panel →
/// Drive). [ok] follows the local copy, like the web.
class BackupRunAllResult {
  const BackupRunAllResult({
    required this.ok,
    required this.mode,
    required this.steps,
  });

  final bool ok;
  final String mode;
  final List<BackupRunStep> steps;

  factory BackupRunAllResult.fromJson(Map<String, dynamic> json) {
    final raw = json['steps'];
    return BackupRunAllResult(
      ok: _asBool(json['ok']),
      mode: (json['mode'] ?? 'lean').toString(),
      steps: raw is List
          ? raw
              .whereType<Map<String, dynamic>>()
              .map(BackupRunStep.fromJson)
              .toList()
          : const [],
    );
  }
}

/// Arabic for a backup job / run status (`never_run` was shown raw, R11 L-2).
String backupStatusLabel(String status) =>
    switch (status.trim().toLowerCase()) {
      'success' || 'ok' || 'done' || 'completed' => 'ناجحة',
      'failed' || 'error' => 'فشلت',
      'running' => 'قيد التنفيذ',
      'pending' || 'queued' => 'بانتظار التنفيذ',
      'skipped' => 'تم تجاوزها',
      'never_run' || 'never' => 'لم تُشغَّل بعد',
      '' => 'غير محددة',
      _ => 'حالة غير معروفة',
    };

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

bool _asBool(Object? value) {
  if (value is bool) return value;
  final text = value?.toString().trim().toLowerCase();
  if (text == null || text.isEmpty) return false;
  return ['1', 'true', 'yes', 'on'].contains(text);
}
