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

int _asInt(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse((value ?? '').toString()) ?? fallback;
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
