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
    return name.toString().trim().isEmpty ? 'MikroTik' : name.toString();
  }

  String get version => (resource['version'] ?? '').toString();
  String get boardName => (resource['board-name'] ?? '').toString();
  String get uptime => (resource['uptime'] ?? '').toString();
  String get cpuLoad => (resource['cpu-load'] ?? '').toString();
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
