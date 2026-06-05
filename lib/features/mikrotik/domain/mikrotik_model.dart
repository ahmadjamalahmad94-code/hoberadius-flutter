class MikrotikConfig {
  const MikrotikConfig({
    this.id,
    required this.name,
    required this.host,
    required this.port,
    required this.username,
    required this.useTls,
    required this.verifyTls,
    required this.timeoutSec,
    required this.enabled,
  });

  final int? id;
  final String name;
  final String host;
  final int port;
  final String username;
  final bool useTls;
  final bool verifyTls;
  final int timeoutSec;
  final bool enabled;

  factory MikrotikConfig.fromJson(Map<String, dynamic> json) {
    return MikrotikConfig(
      id: _asIntOrNull(json['id']),
      name: (json['name'] ?? '').toString(),
      host: (json['host'] ?? '').toString(),
      port: _asInt(json['port'], fallback: 8728),
      username: (json['username'] ?? '').toString(),
      useTls: json['use_tls'] == true,
      verifyTls: json['verify_tls'] != false,
      timeoutSec: _asInt(json['timeout_sec'], fallback: 10),
      enabled: json['enabled'] != false,
    );
  }

  Map<String, dynamic> toBody({String password = ''}) {
    return {
      'name': name,
      'host': host,
      'port': port,
      'username': username,
      'use_tls': useTls,
      'verify_tls': verifyTls,
      'timeout_sec': timeoutSec,
      'enabled': enabled,
      if (password.trim().isNotEmpty) 'password': password.trim(),
    };
  }
}

class MikrotikTestResult {
  const MikrotikTestResult({
    required this.connected,
    required this.identity,
    required this.resource,
  });

  final bool connected;
  final Map<String, dynamic> identity;
  final Map<String, dynamic> resource;

  factory MikrotikTestResult.fromJson(Map<String, dynamic> json) {
    return MikrotikTestResult(
      connected: json['connected'] == true,
      identity: _map(json['identity']),
      resource: _map(json['resource']),
    );
  }

  String get displayName {
    final name = identity['name'] ?? identity['identity'] ?? '';
    return name.toString().trim().isEmpty ? 'ميكروتك' : name.toString();
  }

  String get version => (resource['version'] ?? '').toString();
  String get boardName => (resource['board-name'] ?? '').toString();
  String get uptime => (resource['uptime'] ?? '').toString();
  String get cpuLoad => (resource['cpu-load'] ?? '').toString();
}

class MikrotikRouterOverview {
  const MikrotikRouterOverview({
    required this.routerId,
    required this.name,
    required this.anyOk,
    required this.allOk,
    required this.connection,
    required this.sections,
  });

  final int routerId;
  final String name;
  final bool anyOk;
  final bool allOk;
  final Map<String, dynamic> connection;
  final Map<String, MikrotikOverviewSection> sections;

  factory MikrotikRouterOverview.fromJson(Map<String, dynamic> json) {
    final rawSections = _map(json['sections']);
    return MikrotikRouterOverview(
      routerId: _asInt(json['router_id']),
      name: (json['name'] ?? '').toString(),
      anyOk: json['any_ok'] == true,
      allOk: json['all_ok'] == true,
      connection: _map(json['connection']),
      sections: rawSections.map(
        (key, value) => MapEntry(
          key,
          MikrotikOverviewSection.fromJson(_map(value)),
        ),
      ),
    );
  }

  String get modeLabel {
    final mode = (connection['mode'] ?? '').toString();
    return switch (mode) {
      'vpn' => 'عبر النفق',
      'direct' => 'مباشر',
      _ => mode.isEmpty ? 'غير محدد' : mode,
    };
  }

  String get dialAddress => (connection['address'] ?? '').toString();

  MikrotikOverviewSection? section(String key) => sections[key];
}

class MikrotikOverviewSection {
  const MikrotikOverviewSection({
    required this.ok,
    required this.data,
    required this.error,
    required this.tookMs,
    required this.cached,
    required this.dialedAddress,
    required this.mode,
  });

  final bool ok;
  final Object? data;
  final String error;
  final int tookMs;
  final bool cached;
  final String dialedAddress;
  final String mode;

  factory MikrotikOverviewSection.fromJson(Map<String, dynamic> json) {
    return MikrotikOverviewSection(
      ok: json['ok'] == true,
      data: json['data'],
      error: (json['error'] ?? '').toString(),
      tookMs: _asInt(json['took_ms']),
      cached: json['cached'] == true,
      dialedAddress: (json['dialed_address'] ?? '').toString(),
      mode: (json['mode'] ?? '').toString(),
    );
  }

  Map<String, dynamic> get firstRow {
    final raw = data;
    if (raw is List && raw.isNotEmpty) return _map(raw.first);
    return _map(raw);
  }
}

class MikrotikLiveSnapshot {
  const MikrotikLiveSnapshot({
    required this.routerId,
    required this.sections,
  });

  final int routerId;
  final List<MikrotikLiveSection> sections;

  bool get anyOk => sections.any((section) => section.ok);

  int get totalRows => sections.fold<int>(
        0,
        (total, section) => total + section.rowCount,
      );

  int get failedSections => sections.where((section) => !section.ok).length;

  MikrotikLiveSection? section(String key) {
    for (final section in sections) {
      if (section.key == key) return section;
    }
    return null;
  }
}

class MikrotikActionResult {
  const MikrotikActionResult({
    required this.ok,
    required this.routerId,
    required this.message,
    required this.error,
    required this.backupId,
    required this.backupName,
    required this.routerFilename,
    required this.newName,
    required this.raw,
  });

  final bool ok;
  final int routerId;
  final String message;
  final String error;
  final int? backupId;
  final String backupName;
  final String routerFilename;
  final String newName;
  final Map<String, dynamic> raw;

  factory MikrotikActionResult.fromJson(Map<String, dynamic> json) {
    final ok = json['ok'] != false;
    final message = _string(json['message']);
    final error = _string(json['error']);
    return MikrotikActionResult(
      ok: ok,
      routerId: _asInt(json['router_id']),
      message: message.isNotEmpty
          ? message
          : ok
              ? 'تم تنفيذ الأمر بنجاح.'
              : 'تعذر تنفيذ الأمر على الراوتر.',
      error: error,
      backupId: _asIntOrNull(json['backup_id']),
      backupName: _string(json['backup_name']),
      routerFilename: _string(json['router_filename']),
      newName: _string(json['new_name']),
      raw: json,
    );
  }

  String get visibleMessage {
    if (ok) return message;
    return error.isEmpty ? message : error;
  }
}

class MikrotikRouterBackup {
  const MikrotikRouterBackup({
    required this.id,
    required this.name,
    required this.filename,
    required this.routerFilename,
    required this.sizeBytes,
    required this.status,
    required this.routerStatus,
    required this.manifestSummary,
    required this.createdAt,
    required this.restoredAt,
    required this.restoredBy,
    required this.reason,
    required this.notes,
    required this.hasBlob,
  });

  final int id;
  final String name;
  final String filename;
  final String routerFilename;
  final int sizeBytes;
  final String status;
  final String routerStatus;
  final String manifestSummary;
  final String createdAt;
  final String restoredAt;
  final String restoredBy;
  final String reason;
  final String notes;
  final bool hasBlob;

  factory MikrotikRouterBackup.fromJson(Map<String, dynamic> json) {
    return MikrotikRouterBackup(
      id: _asInt(json['id']),
      name: _string(json['name']),
      filename: _string(json['filename']),
      routerFilename: _string(json['router_filename']),
      sizeBytes: _asInt(json['size_bytes']),
      status: _string(json['status'], fallback: 'saved'),
      routerStatus: _string(json['router_status'], fallback: 'on_router'),
      manifestSummary: _string(json['manifest_summary']),
      createdAt: _string(json['created_at']),
      restoredAt: _string(json['restored_at']),
      restoredBy: _string(json['restored_by']),
      reason: _string(json['reason']),
      notes: _string(json['notes']),
      hasBlob: _bool(json['has_blob']),
    );
  }

  String get displayName {
    for (final value in [name, filename, routerFilename]) {
      final clean = value.trim();
      if (clean.isNotEmpty) return clean;
    }
    return 'نسخة بدون اسم';
  }

  String get routerStatusLabel => switch (routerStatus) {
        'on_router' => 'موجودة على الراوتر',
        'saved' => 'محفوظة في اللوحة',
        'restored' => 'تمت استعادتها',
        _ => 'حالة غير معروفة',
      };

  bool get canRestoreFromRouter => routerStatus == 'on_router';
}

class MikrotikRouterBackupsPage {
  const MikrotikRouterBackupsPage({
    required this.routerId,
    required this.count,
    required this.backups,
  });

  final int routerId;
  final int count;
  final List<MikrotikRouterBackup> backups;

  factory MikrotikRouterBackupsPage.fromJson(Map<String, dynamic> json) {
    final raw = json['backups'];
    final backups = raw is List
        ? raw
            .whereType<Map<String, dynamic>>()
            .map(MikrotikRouterBackup.fromJson)
            .toList()
        : const <MikrotikRouterBackup>[];
    return MikrotikRouterBackupsPage(
      routerId: _asInt(json['router_id']),
      count: _asInt(json['count'], fallback: backups.length),
      backups: backups,
    );
  }
}

class MikrotikLiveSection {
  const MikrotikLiveSection({
    required this.key,
    required this.title,
    required this.path,
    required this.ok,
    required this.rows,
    required this.summary,
    required this.error,
    required this.tookMs,
    required this.cached,
    required this.dialedAddress,
    required this.mode,
    required this.count,
  });

  final String key;
  final String title;
  final String path;
  final bool ok;
  final List<Map<String, dynamic>> rows;
  final Map<String, dynamic> summary;
  final String error;
  final int tookMs;
  final bool cached;
  final String dialedAddress;
  final String mode;
  final int count;

  factory MikrotikLiveSection.fromJson({
    required String key,
    required String title,
    required String path,
    required Map<String, dynamic> json,
  }) {
    final payload = json.containsKey('data') ? json['data'] : json;
    final rows = _rows(payload, fallback: json);
    final summary = _summary(payload);
    final explicitCount = _asIntOrNull(json['count']) ??
        _asIntOrNull(summary['count']) ??
        _asIntOrNull(summary['total']);
    return MikrotikLiveSection(
      key: key,
      title: title,
      path: path,
      ok: json['ok'] != false,
      rows: rows,
      summary: summary,
      error: (json['error'] ?? '').toString(),
      tookMs: _asInt(json['took_ms']),
      cached: json['cached'] == true,
      dialedAddress: (json['dialed_address'] ?? '').toString(),
      mode: (json['mode'] ?? '').toString(),
      count: explicitCount ?? (rows.isNotEmpty ? rows.length : summary.length),
    );
  }

  factory MikrotikLiveSection.failed({
    required String key,
    required String title,
    required String path,
    required String error,
  }) {
    return MikrotikLiveSection(
      key: key,
      title: title,
      path: path,
      ok: false,
      rows: const [],
      summary: const {},
      error: error,
      tookMs: 0,
      cached: false,
      dialedAddress: '',
      mode: '',
      count: 0,
    );
  }

  int get rowCount => rows.isNotEmpty ? rows.length : count;

  bool get hasData => rows.isNotEmpty || summary.isNotEmpty || count > 0;
}

int _asInt(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse((value ?? '').toString()) ?? fallback;
}

bool _bool(Object? value) {
  if (value is bool) return value;
  final text = (value ?? '').toString().trim().toLowerCase();
  return text == 'true' || text == '1' || text == 'yes' || text == 'on';
}

String _string(Object? value, {String fallback = ''}) {
  final text = (value ?? '').toString().trim();
  return text.isEmpty ? fallback : text;
}

int? _asIntOrNull(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

Map<String, dynamic> _map(Object? value) {
  return value is Map<String, dynamic> ? value : const {};
}

List<Map<String, dynamic>> _rows(
  Object? payload, {
  required Map<String, dynamic> fallback,
}) {
  final fromPayload = _rowsFromObject(payload);
  if (fromPayload.isNotEmpty) return fromPayload;
  for (final key in const [
    'items',
    'rows',
    'interfaces',
    'addresses',
    'routes',
    'neighbors',
    'sessions',
    'queues',
    'rules',
    'files',
    'backups',
    'logs',
  ]) {
    final fromFallback = _rowsFromObject(fallback[key]);
    if (fromFallback.isNotEmpty) return fromFallback;
  }
  return const [];
}

List<Map<String, dynamic>> _rowsFromObject(Object? value) {
  if (value is List) {
    return value.whereType<Map<String, dynamic>>().toList();
  }
  if (value is Map<String, dynamic>) {
    for (final key in const [
      'items',
      'rows',
      'interfaces',
      'addresses',
      'routes',
      'neighbors',
      'sessions',
      'queues',
      'rules',
      'files',
      'backups',
      'logs',
    ]) {
      final nested = _rowsFromObject(value[key]);
      if (nested.isNotEmpty) return nested;
    }
    if (value.isNotEmpty) return [value];
  }
  return const [];
}

Map<String, dynamic> _summary(Object? payload) {
  final map = _map(payload);
  if (map.isEmpty) return const {};
  final listKeys = {
    'items',
    'rows',
    'interfaces',
    'addresses',
    'routes',
    'neighbors',
    'sessions',
    'queues',
    'rules',
    'files',
    'backups',
    'logs',
  };
  return Map.fromEntries(
    map.entries.where((entry) => !listKeys.contains(entry.key)),
  );
}
