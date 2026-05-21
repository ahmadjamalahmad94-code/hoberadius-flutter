import 'card_parsing.dart';

/// Accounting roll-up + recent sessions for a single card, returned
/// nested inside [CardCheckResult.accountingSummary].
class CardAccountingSummary {
  CardAccountingSummary({
    this.sessionsCount = 0,
    this.onlineSessions = 0,
    this.uniqueMacs = 0,
    this.uniqueIps = 0,
    this.uniqueNas = 0,
    this.totalSessionSeconds = 0,
    this.totalUploadBytes = 0,
    this.totalDownloadBytes = 0,
    this.firstSessionAt,
    this.lastSessionAt,
    List<CardMacSummary>? macs,
    List<CardSession>? latestSessions,
  })  : macs = macs ?? const [],
        latestSessions = latestSessions ?? const [];

  final int sessionsCount;
  final int onlineSessions;
  final int uniqueMacs;
  final int uniqueIps;
  final int uniqueNas;
  final int totalSessionSeconds;
  final int totalUploadBytes;
  final int totalDownloadBytes;
  final DateTime? firstSessionAt;
  final DateTime? lastSessionAt;
  final List<CardMacSummary> macs;
  final List<CardSession> latestSessions;

  factory CardAccountingSummary.fromJson(Map<String, dynamic> json) =>
      CardAccountingSummary(
        sessionsCount: cardParseInt(json['sessions_count']) ?? 0,
        onlineSessions: cardParseInt(json['online_sessions']) ?? 0,
        uniqueMacs: cardParseInt(json['unique_macs']) ?? 0,
        uniqueIps: cardParseInt(json['unique_ips']) ?? 0,
        uniqueNas: cardParseInt(json['unique_nas']) ?? 0,
        totalSessionSeconds: cardParseInt(json['total_session_seconds']) ?? 0,
        totalUploadBytes: cardParseInt(json['total_upload_bytes']) ?? 0,
        totalDownloadBytes: cardParseInt(json['total_download_bytes']) ?? 0,
        firstSessionAt: cardParseDate(json['first_session_at']),
        lastSessionAt: cardParseDate(json['last_session_at']),
        macs: (json['macs'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(CardMacSummary.fromJson)
            .toList(),
        latestSessions: (json['latest_sessions'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(CardSession.fromJson)
            .toList(),
      );
}

class CardMacSummary {
  CardMacSummary({
    this.mac = '',
    this.sessionsCount = 0,
    this.onlineSessions = 0,
    this.lastSeenAt,
  });

  final String mac;
  final int sessionsCount;
  final int onlineSessions;
  final DateTime? lastSeenAt;

  factory CardMacSummary.fromJson(Map<String, dynamic> json) => CardMacSummary(
        mac: (json['mac'] ?? '').toString(),
        sessionsCount: cardParseInt(json['sessions_count']) ?? 0,
        onlineSessions: cardParseInt(json['online_sessions']) ?? 0,
        lastSeenAt: cardParseDate(json['last_seen_at']),
      );
}

class CardSession {
  CardSession({
    this.id,
    this.sessionId = '',
    this.uniqueId = '',
    this.startedAt,
    this.updatedAt,
    this.stoppedAt,
    this.online = false,
    this.durationSeconds = 0,
    this.uploadBytes = 0,
    this.downloadBytes = 0,
    this.macAddress,
    this.calledStation,
    this.ipAddress,
    this.ipv6Address,
    this.nasAddress,
    this.nasPort,
    this.nasPortType,
    this.serviceType,
    this.framedProtocol,
    this.connectInfoStart,
    this.connectInfoStop,
    this.terminateCause,
    this.deviceHint,
  });

  final int? id;
  final String sessionId;
  final String uniqueId;
  final DateTime? startedAt;
  final DateTime? updatedAt;
  final DateTime? stoppedAt;
  final bool online;
  final int durationSeconds;
  final int uploadBytes;
  final int downloadBytes;
  final String? macAddress;
  final String? calledStation;
  final String? ipAddress;
  final String? ipv6Address;
  final String? nasAddress;
  final String? nasPort;
  final String? nasPortType;
  final String? serviceType;
  final String? framedProtocol;
  final String? connectInfoStart;
  final String? connectInfoStop;
  final String? terminateCause;
  final String? deviceHint;

  factory CardSession.fromJson(Map<String, dynamic> json) => CardSession(
        id: cardParseInt(json['id']),
        sessionId: (json['session_id'] ?? '').toString(),
        uniqueId: (json['unique_id'] ?? '').toString(),
        startedAt: cardParseDate(json['started_at']),
        updatedAt: cardParseDate(json['updated_at']),
        stoppedAt: cardParseDate(json['stopped_at']),
        online: cardParseBool(json['online']),
        durationSeconds: cardParseInt(json['duration_seconds']) ?? 0,
        uploadBytes: cardParseInt(json['upload_bytes']) ?? 0,
        downloadBytes: cardParseInt(json['download_bytes']) ?? 0,
        macAddress: cardParseStringOrNull(json['mac_address']),
        calledStation: cardParseStringOrNull(json['called_station']),
        ipAddress: cardParseStringOrNull(json['ip_address']),
        ipv6Address: cardParseStringOrNull(json['ipv6_address']),
        nasAddress: cardParseStringOrNull(json['nas_address']),
        nasPort: cardParseStringOrNull(json['nas_port']),
        nasPortType: cardParseStringOrNull(json['nas_port_type']),
        serviceType: cardParseStringOrNull(json['service_type']),
        framedProtocol: cardParseStringOrNull(json['framed_protocol']),
        connectInfoStart: cardParseStringOrNull(json['connect_info_start']),
        connectInfoStop: cardParseStringOrNull(json['connect_info_stop']),
        terminateCause: cardParseStringOrNull(json['terminate_cause']),
        deviceHint: cardParseStringOrNull(json['device_hint']),
      );
}
