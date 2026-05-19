class OnlineSession {
  OnlineSession({
    this.id,
    required this.username,
    this.sessionId = '',
    this.nasIpAddress = '',
    this.framedIpAddress = '',
    this.callingStationId = '',
    this.calledStationId = '',
    this.nasPortId = '',
    this.startedAt,
    this.lastUpdateAt,
    this.bytesIn = 0,
    this.bytesOut = 0,
    this.sessionTime = 0,
  });

  final int? id;
  final String username;
  final String sessionId;
  final String nasIpAddress;
  final String framedIpAddress;
  final String callingStationId;
  final String calledStationId;
  final String nasPortId;
  final DateTime? startedAt;
  final DateTime? lastUpdateAt;
  final int bytesIn;
  final int bytesOut;
  final int sessionTime;

  factory OnlineSession.fromJson(Map<String, dynamic> j) => OnlineSession(
        id: j['id'] as int?,
        username: (j['username'] ?? '').toString(),
        sessionId: (j['session_id'] ?? '').toString(),
        nasIpAddress: (j['nas_ip_address'] ?? '').toString(),
        framedIpAddress: (j['framed_ip_address'] ?? '').toString(),
        callingStationId: (j['calling_station_id'] ?? '').toString(),
        calledStationId: (j['called_station_id'] ?? '').toString(),
        nasPortId: (j['nas_port_id'] ?? '').toString(),
        startedAt: _dt(j['started_at']),
        lastUpdateAt: _dt(j['last_update_at']),
        bytesIn: _int(j['bytes_in']) ?? 0,
        bytesOut: _int(j['bytes_out']) ?? 0,
        sessionTime: _int(j['session_time']) ?? 0,
      );

  static DateTime? _dt(Object? v) {
    if (v == null) return null;
    try {
      return DateTime.parse(v.toString().replaceAll('Z', ''));
    } catch (_) {
      return null;
    }
  }

  static int? _int(Object? v) =>
      v == null ? null : (v is int ? v : int.tryParse(v.toString()));
}
