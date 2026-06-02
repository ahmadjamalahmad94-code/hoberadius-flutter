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
      messageAr: (json['message_ar'] ?? 'جوجل درايف غير مفعل حاليًا').toString(),
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
  });

  final int id;
  final String name;
  final String schedule;
  final String target;
  final String lastStatus;
  final String lastMessage;
  final DateTime? lastRunAt;

  factory BackupJob.fromJson(Map<String, dynamic> json) {
    return BackupJob(
      id: _asInt(json['id']),
      name: (json['name'] ?? '').toString(),
      schedule: (json['schedule'] ?? '').toString(),
      target: (json['target'] ?? '').toString(),
      lastStatus: (json['last_status'] ?? 'never_run').toString(),
      lastMessage: (json['last_message'] ?? '').toString(),
      lastRunAt: DateTime.tryParse((json['last_run_at'] ?? '').toString()),
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
  });

  final int id;
  final String status;
  final String path;
  final String message;
  final DateTime? createdAt;

  factory BackupRun.fromJson(Map<String, dynamic> json) {
    return BackupRun(
      id: _asInt(json['id']),
      status: (json['status'] ?? '').toString(),
      path: (json['path'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
    );
  }
}

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
