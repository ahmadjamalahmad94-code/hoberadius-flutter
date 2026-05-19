class NasDevice {
  NasDevice({
    this.id,
    required this.name,
    required this.ipAddress,
    this.secret = '',
    this.nasType = 'mikrotik',
    this.authPort = 1812,
    this.acctPort = 1813,
    this.apiPort = 8728,
    this.snmpCommunity = '',
    this.snmpVersion = 'v2c',
    this.disabled = false,
    this.location = '',
    this.notes = '',
    this.lastCheckStatus,
    this.lastCheckMs,
    this.lastCheckAt,
  });

  final int? id;
  final String name;
  final String ipAddress;
  final String secret;
  final String nasType;
  final int authPort;
  final int acctPort;
  final int apiPort;
  final String snmpCommunity;
  final String snmpVersion;
  final bool disabled;
  final String location;
  final String notes;
  final String? lastCheckStatus;
  final int? lastCheckMs;
  final DateTime? lastCheckAt;

  factory NasDevice.fromJson(Map<String, dynamic> j) => NasDevice(
        id: j['id'] as int?,
        name: (j['name'] ?? '').toString(),
        ipAddress: (j['ip_address'] ?? j['short_name'] ?? '').toString(),
        secret: (j['secret'] ?? '').toString(),
        nasType: (j['nas_type'] ?? j['type'] ?? 'mikrotik').toString(),
        authPort: _int(j['auth_port']) ?? 1812,
        acctPort: _int(j['acct_port']) ?? 1813,
        apiPort: _int(j['api_port']) ?? 8728,
        snmpCommunity: (j['snmp_community'] ?? '').toString(),
        snmpVersion: (j['snmp_version'] ?? 'v2c').toString(),
        disabled: j['disabled'] == true || j['enabled'] == false,
        location: (j['location'] ?? '').toString(),
        notes: (j['notes'] ?? '').toString(),
        lastCheckStatus: j['last_check_status']?.toString(),
        lastCheckMs: _int(j['last_check_ms']),
        lastCheckAt: _parseDt(j['last_check_at']),
      );

  Map<String, dynamic> toBody() => {
        'name': name,
        'ip_address': ipAddress,
        if (secret.isNotEmpty) 'secret': secret,
        'nas_type': nasType,
        'auth_port': authPort,
        'acct_port': acctPort,
        'api_port': apiPort,
        'snmp_community': snmpCommunity,
        'snmp_version': snmpVersion,
        'disabled': disabled,
        'location': location,
        'notes': notes,
      };

  static int? _int(Object? v) =>
      v == null ? null : (v is int ? v : int.tryParse(v.toString()));

  static DateTime? _parseDt(Object? v) {
    if (v == null) return null;
    try {
      return DateTime.parse(v.toString().replaceAll('Z', ''));
    } catch (_) {
      return null;
    }
  }

  NasDevice copyWith({
    int? id,
    String? name,
    String? ipAddress,
    String? secret,
    String? nasType,
    int? authPort,
    int? acctPort,
    int? apiPort,
    String? snmpCommunity,
    String? snmpVersion,
    bool? disabled,
    String? location,
    String? notes,
  }) => NasDevice(
        id: id ?? this.id,
        name: name ?? this.name,
        ipAddress: ipAddress ?? this.ipAddress,
        secret: secret ?? this.secret,
        nasType: nasType ?? this.nasType,
        authPort: authPort ?? this.authPort,
        acctPort: acctPort ?? this.acctPort,
        apiPort: apiPort ?? this.apiPort,
        snmpCommunity: snmpCommunity ?? this.snmpCommunity,
        snmpVersion: snmpVersion ?? this.snmpVersion,
        disabled: disabled ?? this.disabled,
        location: location ?? this.location,
        notes: notes ?? this.notes,
        lastCheckStatus: lastCheckStatus,
        lastCheckMs: lastCheckMs,
        lastCheckAt: lastCheckAt,
      );
}

class NasTestResult {
  NasTestResult({required this.ok, this.status, this.ms, this.message});
  final bool ok;
  final String? status;
  final int? ms;
  final String? message;

  factory NasTestResult.fromJson(Map<String, dynamic> j) => NasTestResult(
        ok: j['ok'] == true || j['status'] == 'ok',
        status: j['status']?.toString(),
        ms: (j['ms'] is int) ? j['ms'] as int : int.tryParse('${j['ms']}'),
        message: j['message']?.toString(),
      );
}
