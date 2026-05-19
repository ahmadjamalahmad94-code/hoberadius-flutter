/// NAS Device model — mirrors the server-side `NasDevice` DTO.
///
/// `secret` is **write-only**: present on create/update bodies but never
/// returned by the API. The model carries an in-memory `pendingSecret`
/// the form sets when the operator rotates it; we only include the field
/// in the body if it's non-empty.
class NasDevice {
  NasDevice({
    this.id,
    required this.name,
    required this.address,
    this.vendor = 'mikrotik',
    this.nasType = 'hotspot',
    this.shortname = '',
    this.ports = 0,
    this.snmpCommunity = '',
    this.authPort = 1812,
    this.acctPort = 1813,
    this.coaPort = 3799,
    this.apiPort = 8728,
    this.apiUser = '',
    this.apiUseTls = false,
    this.location = '',
    this.coordinates = '',
    this.monitoringEnabled = true,
    this.description = '',
    this.enabled = true,
    this.requireMessageAuthenticator = false,
    this.sshPort = 22,
    this.tags = '',
    this.lastCheckStatus = '',
    this.lastCheckAt,
    this.lastSeenAt,
    this.pendingSecret = '',
    this.pendingApiPassword = '',
  });

  final int? id;
  final String name;
  final String address;
  final String vendor;
  final String nasType;
  final String shortname;
  final int ports;
  final String snmpCommunity;
  final int authPort;
  final int acctPort;
  final int coaPort;
  final int apiPort;
  final String apiUser;
  final bool apiUseTls;
  final String location;
  final String coordinates;
  final bool monitoringEnabled;
  final String description;
  final bool enabled;
  final bool requireMessageAuthenticator;
  final int sshPort;
  final String tags;
  final String lastCheckStatus;
  final DateTime? lastCheckAt;
  final DateTime? lastSeenAt;

  /// Form-only state — never set from the server.
  final String pendingSecret;
  final String pendingApiPassword;

  factory NasDevice.fromJson(Map<String, dynamic> j) => NasDevice(
        id: j['id'] as int?,
        name: (j['name'] ?? '').toString(),
        address: (j['address'] ?? '').toString(),
        vendor: (j['vendor'] ?? 'mikrotik').toString(),
        nasType: (j['nas_type'] ?? 'hotspot').toString(),
        shortname: (j['shortname'] ?? '').toString(),
        ports: _int(j['ports']) ?? 0,
        snmpCommunity: (j['snmp_community'] ?? '').toString(),
        authPort: _int(j['auth_port']) ?? 1812,
        acctPort: _int(j['acct_port']) ?? 1813,
        coaPort: _int(j['coa_port']) ?? 3799,
        apiPort: _int(j['api_port']) ?? 8728,
        apiUser: (j['api_user'] ?? '').toString(),
        apiUseTls: j['api_use_tls'] == true,
        location: (j['location'] ?? '').toString(),
        coordinates: (j['coordinates'] ?? '').toString(),
        monitoringEnabled: j['monitoring_enabled'] != false,
        description: (j['description'] ?? '').toString(),
        enabled: j['enabled'] != false,
        requireMessageAuthenticator: j['require_message_authenticator'] == true,
        sshPort: _int(j['ssh_port']) ?? 22,
        tags: (j['tags'] ?? '').toString(),
        lastCheckStatus: (j['last_check_status'] ?? '').toString(),
        lastCheckAt: _dt(j['last_check_at']),
        lastSeenAt: _dt(j['last_seen_at']),
      );

  /// Build a POST/PATCH body. `secret`/`api_password` are sent only when
  /// the form supplied a non-empty value; otherwise the server keeps the
  /// previously-stored value (a PATCH no-op).
  Map<String, dynamic> toBody() => {
        'name': name,
        'address': address,
        'vendor': vendor,
        'nas_type': nasType,
        'shortname': shortname,
        'ports': ports,
        'snmp_community': snmpCommunity,
        'auth_port': authPort,
        'acct_port': acctPort,
        'coa_port': coaPort,
        'api_port': apiPort,
        'api_user': apiUser,
        'api_use_tls': apiUseTls,
        'location': location,
        'coordinates': coordinates,
        'monitoring_enabled': monitoringEnabled,
        'description': description,
        'enabled': enabled,
        'require_message_authenticator': requireMessageAuthenticator,
        'ssh_port': sshPort,
        'tags': tags,
        if (pendingSecret.isNotEmpty) 'secret': pendingSecret,
        if (pendingApiPassword.isNotEmpty) 'api_password': pendingApiPassword,
      };

  NasDevice copyWith({
    int? id,
    String? name,
    String? address,
    String? vendor,
    String? nasType,
    String? shortname,
    int? ports,
    String? snmpCommunity,
    int? authPort,
    int? acctPort,
    int? coaPort,
    int? apiPort,
    String? apiUser,
    bool? apiUseTls,
    String? location,
    String? coordinates,
    bool? monitoringEnabled,
    String? description,
    bool? enabled,
    bool? requireMessageAuthenticator,
    int? sshPort,
    String? tags,
    String? pendingSecret,
    String? pendingApiPassword,
  }) => NasDevice(
        id: id ?? this.id,
        name: name ?? this.name,
        address: address ?? this.address,
        vendor: vendor ?? this.vendor,
        nasType: nasType ?? this.nasType,
        shortname: shortname ?? this.shortname,
        ports: ports ?? this.ports,
        snmpCommunity: snmpCommunity ?? this.snmpCommunity,
        authPort: authPort ?? this.authPort,
        acctPort: acctPort ?? this.acctPort,
        coaPort: coaPort ?? this.coaPort,
        apiPort: apiPort ?? this.apiPort,
        apiUser: apiUser ?? this.apiUser,
        apiUseTls: apiUseTls ?? this.apiUseTls,
        location: location ?? this.location,
        coordinates: coordinates ?? this.coordinates,
        monitoringEnabled: monitoringEnabled ?? this.monitoringEnabled,
        description: description ?? this.description,
        enabled: enabled ?? this.enabled,
        requireMessageAuthenticator:
            requireMessageAuthenticator ?? this.requireMessageAuthenticator,
        sshPort: sshPort ?? this.sshPort,
        tags: tags ?? this.tags,
        lastCheckStatus: lastCheckStatus,
        lastCheckAt: lastCheckAt,
        lastSeenAt: lastSeenAt,
        pendingSecret: pendingSecret ?? this.pendingSecret,
        pendingApiPassword: pendingApiPassword ?? this.pendingApiPassword,
      );

  static int? _int(Object? v) =>
      v == null ? null : (v is int ? v : int.tryParse(v.toString()));

  static DateTime? _dt(Object? v) {
    if (v == null) return null;
    try {
      return DateTime.parse(v.toString().replaceAll('Z', ''));
    } catch (_) {
      return null;
    }
  }
}

class NasTestResult {
  NasTestResult({
    required this.ok,
    required this.status,
    required this.ms,
    this.message = '',
    this.ip = '',
    this.port = 0,
  });

  final bool ok;
  final String status;
  final int ms;
  final String message;
  final String ip;
  final int port;

  factory NasTestResult.fromJson(Map<String, dynamic> j) => NasTestResult(
        ok: j['ok'] == true || j['status'] == 'reachable',
        status: (j['status'] ?? 'unknown').toString(),
        ms: (j['ms'] is int) ? j['ms'] as int : (int.tryParse('${j['ms']}') ?? 0),
        message: (j['message'] ?? '').toString(),
        ip: (j['ip'] ?? '').toString(),
        port: (j['port'] is int) ? j['port'] as int : (int.tryParse('${j['port']}') ?? 0),
      );
}
