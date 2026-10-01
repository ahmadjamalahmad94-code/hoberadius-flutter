import 'package:hoberadius_app/core/format/server_time.dart';

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
    this.userType = 'subscriber',
    this.userTypeLabel = '',
    this.state = 'online',
    this.stateLabel = '',
    this.stateColor = 'green',
    this.accountStatus,
    this.subscriberId,
    this.cardId,
    this.cardBatchId,
    this.expiresAt,
    this.accessType = '',
    this.cardTimeKnown = false,
    this.cardUsedSeconds,
    this.cardRemainingSeconds,
    this.cardBudgetSeconds,
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
  final String userType;
  final String userTypeLabel;
  final String state;
  final String stateLabel;
  final String stateColor;
  final String? accountStatus;
  final int? subscriberId;
  final int? cardId;
  final int? cardBatchId;
  final DateTime? expiresAt;

  /// `hotspot` | `broadband` | '' (unknown / older server).
  final String accessType;

  /// The server sent the card time fields (`card_used_seconds` …). Older
  /// servers do not — the tile then keeps its router / start-time row.
  final bool cardTimeKnown;
  final int? cardUsedSeconds;

  /// Null with [cardTimeKnown] = an unlimited card.
  final int? cardRemainingSeconds;
  final int? cardBudgetSeconds;

  bool get isCard => userType == 'card';
  bool get isSubscriber => userType == 'subscriber';

  factory OnlineSession.fromJson(Map<String, dynamic> j) => OnlineSession(
        id: j['id'] as int?,
        username: (j['username'] ?? '').toString(),
        sessionId: (j['session_id'] ?? '').toString(),
        nasIpAddress:
            _s(j['nas_ip_address'] ?? j['nas_address'] ?? j['nas_id']),
        framedIpAddress: _s(j['framed_ip_address'] ?? j['framed_ip']),
        callingStationId: _s(j['calling_station_id'] ?? j['mac_address']),
        calledStationId: (j['called_station_id'] ?? '').toString(),
        nasPortId: (j['nas_port_id'] ?? '').toString(),
        startedAt: _dt(j['started_at']),
        lastUpdateAt: _dt(j['last_update_at']),
        bytesIn: _int(j['bytes_in']) ?? 0,
        bytesOut: _int(j['bytes_out']) ?? 0,
        sessionTime: _int(j['session_time']) ?? 0,
        userType: _normalizeType(j['user_type']),
        userTypeLabel: _s(j['user_type_label']),
        state: _s(j['state']).isEmpty ? 'online' : _s(j['state']),
        stateLabel: _s(j['state_label']),
        stateColor:
            _s(j['state_color']).isEmpty ? 'green' : _s(j['state_color']),
        accountStatus: _nullableString(j['account_status']),
        subscriberId: _int(j['subscriber_id']),
        cardId: _int(j['card_id']),
        cardBatchId: _int(j['card_batch_id']),
        expiresAt: _dt(j['expires_at']),
        accessType: _s(j['access_type']).trim().toLowerCase(),
        cardTimeKnown: _normalizeType(j['user_type']) == 'card' &&
            (j.containsKey('card_used_seconds') ||
                j.containsKey('card_remaining_seconds')),
        cardUsedSeconds: _int(j['card_used_seconds']),
        cardRemainingSeconds: _int(j['card_remaining_seconds']),
        cardBudgetSeconds: _int(j['card_budget_seconds']),
      );

  static DateTime? _dt(Object? v) {
    if (v == null) return null;
    try {
      return parseServerDateTime(v);
    } catch (_) {
      return null;
    }
  }

  static int? _int(Object? v) =>
      v == null ? null : (v is num ? v.toInt() : int.tryParse(v.toString()));

  static String _s(Object? v) => v == null ? '' : v.toString();

  static String? _nullableString(Object? v) {
    final value = _s(v);
    return value.isEmpty ? null : value;
  }

  static String _normalizeType(Object? value) {
    final raw = _s(value).toLowerCase().trim();
    if (raw == 'card' || raw == 'cards') return 'card';
    return 'subscriber';
  }
}

class AccountingSessionHistory {
  AccountingSessionHistory({
    this.id,
    required this.username,
    required this.sessionId,
    this.nasIpAddress = '',
    this.framedIpAddress = '',
    this.callingStationId = '',
    this.startedAt,
    this.stoppedAt,
    this.updatedAt,
    this.bytesIn = 0,
    this.bytesOut = 0,
    this.sessionTime = 0,
    this.terminateCause = '',
  });

  final int? id;
  final String username;
  final String sessionId;
  final String nasIpAddress;
  final String framedIpAddress;
  final String callingStationId;
  final DateTime? startedAt;
  final DateTime? stoppedAt;
  final DateTime? updatedAt;
  final int bytesIn;
  final int bytesOut;
  final int sessionTime;
  final String terminateCause;

  bool get isOnline => stoppedAt == null;

  factory AccountingSessionHistory.fromJson(Map<String, dynamic> json) {
    return AccountingSessionHistory(
      id: OnlineSession._int(json['radacctid'] ?? json['id']),
      username: OnlineSession._s(json['username']),
      sessionId: OnlineSession._s(json['acctsessionid'] ?? json['session_id']),
      nasIpAddress:
          OnlineSession._s(json['nasipaddress'] ?? json['nas_ip_address']),
      framedIpAddress: OnlineSession._s(
        json['framedipaddress'] ?? json['framed_ip_address'],
      ),
      callingStationId: OnlineSession._s(
        json['callingstationid'] ?? json['calling_station_id'],
      ),
      startedAt: OnlineSession._dt(json['acctstarttime'] ?? json['started_at']),
      stoppedAt: OnlineSession._dt(json['acctstoptime'] ?? json['stopped_at']),
      updatedAt: OnlineSession._dt(json['acctupdatetime'] ?? json['update_at']),
      bytesIn:
          OnlineSession._int(json['acctinputoctets'] ?? json['bytes_in']) ?? 0,
      bytesOut:
          OnlineSession._int(json['acctoutputoctets'] ?? json['bytes_out']) ??
              0,
      sessionTime:
          OnlineSession._int(json['acctsessiontime'] ?? json['session_time']) ??
              0,
      terminateCause: OnlineSession._s(
        json['acctterminatecause'] ?? json['terminate_cause'],
      ),
    );
  }
}
