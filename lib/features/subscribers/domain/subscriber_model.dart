/// Subscriber model — mirrors the server-side `Subscriber` DTO.
///
/// The Flask API has two storage tiers:
/// * flat columns (working_days, mac_lock, override_concurrent, ...)
/// * a `metadata` JSON column grouping sub-fields the schema does not expose
///   as columns (mikrotik.profile, radius.session_timeout, ...)
///
/// This model exposes a flat surface to the UI; `toCreateBody` / `toPatchBody`
/// dispatch each field to the right place on the wire, and `fromJson` reads
/// both shapes back.
class Subscriber {
  Subscriber({
    this.id,
    required this.username,
    this.password = '',
    this.fullName = '',
    this.mobile = '',
    this.email = '',
    this.beneficiaryRef = '',
    this.planId,
    this.customPrice = 0,
    this.status = 'enabled',
    this.userType = 'subscriber',
    this.serviceType = 'Hotspot',
    this.expireAt,
    this.macLock = '',
    this.staticIp = '',
    this.remark = '',
    // — bandwidth flat overrides —
    this.bandwidthControlEnabled = false,
    this.downloadSpeedKbps = 0,
    this.uploadSpeedKbps = 0,
    // — networking flat —
    this.overrideConcurrent = 0,
    this.primaryDnsPpp = '',
    this.secondaryDnsPpp = '',
    this.callerId = '',
    this.workingDaysCsv = '',
    this.autoRenewal = true,
    // — MikroTik metadata —
    this.mtProfile = '',
    this.mtService = 'pppoe',
    this.mtRateLimit = '',
    this.mtIpPool = '',
    this.mtComment = '',
    // — RADIUS attrs (metadata) —
    this.sessionTimeout,
    this.idleTimeout,
    this.calledStationId = '',
    // — advanced (metadata) —
    this.allowedHours = '',
    this.disableOnFirstUse = false,
    // — notifications (metadata) —
    this.notifyOnLogin = false,
    this.notifyEmail = '',
    this.notifyMobile = '',
    // — subscription policy (metadata) —
    this.subscriptionType = 'fixed',
    this.subscriptionDays,
    // — general (metadata) —
    this.notes = '',
    this.tags = const <String>[],
    // — read-only counters —
    this.usedSeconds = 0,
    this.usedBytesIn = 0,
    this.usedBytesOut = 0,
    this.onlineCount = 0,
    this.lastSeenAt,
    this.firstLoginAt,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final String username;
  final String password;
  final String fullName;
  final String mobile;
  final String email;
  final String beneficiaryRef;
  final int? planId;
  final double customPrice;
  final String status;
  final String userType;
  final String serviceType;
  final DateTime? expireAt;
  final String macLock;
  final String staticIp;
  final String remark;

  final bool bandwidthControlEnabled;
  final int downloadSpeedKbps;
  final int uploadSpeedKbps;

  final int overrideConcurrent;
  final String primaryDnsPpp;
  final String secondaryDnsPpp;
  final String callerId;

  /// CSV of two-letter day codes: "sat,sun,mon,tue,wed,thu,fri"
  final String workingDaysCsv;
  final bool autoRenewal;

  final String mtProfile;
  final String mtService;
  final String mtRateLimit;
  final String mtIpPool;
  final String mtComment;

  final int? sessionTimeout;
  final int? idleTimeout;
  final String calledStationId;

  final String allowedHours;
  final bool disableOnFirstUse;

  final bool notifyOnLogin;
  final String notifyEmail;
  final String notifyMobile;

  final String subscriptionType;
  final int? subscriptionDays;

  final String notes;
  final List<String> tags;

  final int usedSeconds;
  final int usedBytesIn;
  final int usedBytesOut;
  final int onlineCount;
  final DateTime? lastSeenAt;
  final DateTime? firstLoginAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Helper for forms — split/join the CSV.
  List<String> get workingDays => workingDaysCsv.isEmpty
      ? const <String>[]
      : workingDaysCsv
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

  factory Subscriber.fromJson(Map<String, dynamic> j) {
    final meta = (j['metadata'] is Map<String, dynamic>)
        ? j['metadata'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final mt = (meta['mikrotik'] ?? const {}) as Map;
    final rad = (meta['radius'] ?? const {}) as Map;
    final adv = (meta['advanced'] ?? const {}) as Map;
    final notif = (meta['notifications'] ?? const {}) as Map;
    final sub = (meta['subscription'] ?? const {}) as Map;
    final gen = (meta['general'] ?? const {}) as Map;

    return Subscriber(
      id: j['id'] as int?,
      username: (j['username'] ?? '').toString(),
      fullName: (j['full_name'] ?? '').toString(),
      mobile: (j['mobile'] ?? '').toString(),
      email: (j['email'] ?? '').toString(),
      beneficiaryRef: (j['beneficiary_ref'] ?? '').toString(),
      planId: j['plan_id'] as int?,
      customPrice: _double(j['custom_price']) ?? 0,
      status: (j['status'] ?? 'enabled').toString(),
      userType: (j['user_type'] ?? 'subscriber').toString(),
      serviceType: (j['service_type'] ?? 'Hotspot').toString(),
      expireAt: _parseDt(j['expire_at']),
      macLock: (j['mac_lock'] ?? '').toString(),
      staticIp: (j['static_ip'] ?? '').toString(),
      remark: (j['remark'] ?? '').toString(),
      bandwidthControlEnabled: j['bandwidth_control_enabled'] == true,
      downloadSpeedKbps: _int(j['download_speed_kbps']) ?? 0,
      uploadSpeedKbps: _int(j['upload_speed_kbps']) ?? 0,
      overrideConcurrent: _int(j['override_concurrent']) ?? 0,
      primaryDnsPpp: (j['primary_dns_ppp'] ?? '').toString(),
      secondaryDnsPpp: (j['secondary_dns_ppp'] ?? '').toString(),
      callerId: (j['caller_id'] ?? '').toString(),
      workingDaysCsv: (j['working_days'] ?? '').toString(),
      autoRenewal: j['auto_renewal'] == true || j['auto_renewal'] == 1,
      // metadata
      mtProfile: (mt['profile'] ?? '').toString(),
      mtService: (mt['service'] ?? 'pppoe').toString(),
      mtRateLimit: (mt['rate_limit'] ?? '').toString(),
      mtIpPool: (mt['ip_pool'] ?? '').toString(),
      mtComment: (mt['comment'] ?? '').toString(),
      sessionTimeout: _int(rad['session_timeout']),
      idleTimeout: _int(rad['idle_timeout']),
      calledStationId: (rad['called_station_id'] ?? '').toString(),
      allowedHours: (adv['allowed_hours'] ?? '').toString(),
      disableOnFirstUse: adv['disable_on_first_use'] == true,
      notifyOnLogin: notif['on_login'] == true,
      notifyEmail: (notif['email'] ?? '').toString(),
      notifyMobile: (notif['mobile'] ?? '').toString(),
      subscriptionType: (sub['type'] ?? 'fixed').toString(),
      subscriptionDays: _int(sub['days']),
      notes: (gen['notes'] ?? '').toString(),
      tags: _strList(gen['tags']),
      // counters
      usedSeconds: _int(j['used_seconds']) ?? 0,
      usedBytesIn: _int(j['used_bytes_in']) ?? 0,
      usedBytesOut: _int(j['used_bytes_out']) ?? 0,
      onlineCount: _int(j['online_count']) ?? 0,
      lastSeenAt: _parseDt(j['last_seen_at']),
      firstLoginAt: _parseDt(j['first_login_at']),
      createdAt: _parseDt(j['created_at']),
      updatedAt: _parseDt(j['updated_at']),
    );
  }

  Map<String, dynamic> _flat(bool includeUsername) {
    return {
      if (includeUsername) 'username': username,
      if (password.isNotEmpty) 'password': password,
      'full_name': fullName,
      'mobile': mobile,
      'email': email,
      'beneficiary_ref': beneficiaryRef,
      if (planId != null) 'plan_id': planId,
      'custom_price': customPrice,
      'status': status,
      'user_type': userType,
      'service_type': serviceType,
      if (expireAt != null) 'expire_at': expireAt!.toUtc().toIso8601String(),
      'mac_lock': macLock,
      'static_ip': staticIp,
      'remark': remark,
      'bandwidth_control_enabled': bandwidthControlEnabled,
      'download_speed_kbps': downloadSpeedKbps,
      'upload_speed_kbps': uploadSpeedKbps,
      'override_concurrent': overrideConcurrent,
      'primary_dns_ppp': primaryDnsPpp,
      'secondary_dns_ppp': secondaryDnsPpp,
      'caller_id': callerId,
      'working_days': workingDaysCsv,
      'auto_renewal': autoRenewal,
      'metadata': _metadata(),
    };
  }

  Map<String, dynamic> toCreateBody() => _flat(true);
  Map<String, dynamic> toPatchBody() => _flat(false);

  Map<String, dynamic> _metadata() => {
        'mikrotik': {
          'profile': mtProfile,
          'service': mtService,
          'rate_limit': mtRateLimit,
          'ip_pool': mtIpPool,
          'comment': mtComment,
        },
        'radius': {
          if (sessionTimeout != null) 'session_timeout': sessionTimeout,
          if (idleTimeout != null) 'idle_timeout': idleTimeout,
          'called_station_id': calledStationId,
        },
        'advanced': {
          'allowed_hours': allowedHours,
          'disable_on_first_use': disableOnFirstUse,
        },
        'notifications': {
          'on_login': notifyOnLogin,
          'email': notifyEmail,
          'mobile': notifyMobile,
        },
        'subscription': {
          'type': subscriptionType,
          if (subscriptionDays != null) 'days': subscriptionDays,
        },
        'general': {
          'notes': notes,
          'tags': tags,
        },
      };

  static DateTime? _parseDt(Object? v) {
    if (v == null) return null;
    try {
      return DateTime.parse(v.toString().replaceAll('Z', ''));
    } catch (_) {
      return null;
    }
  }

  static int? _int(Object? v) =>
      v == null ? null : (v is int ? v : int.tryParse(v.toString()));

  static double? _double(Object? v) => v == null
      ? null
      : (v is num ? v.toDouble() : double.tryParse(v.toString()));

  static List<String> _strList(Object? v) {
    if (v == null) return const [];
    if (v is List) return v.map((e) => e.toString()).toList();
    if (v is String && v.isNotEmpty) {
      return v.split(',').map((e) => e.trim()).toList();
    }
    return const [];
  }

  Subscriber copyWith({
    int? id,
    String? username,
    String? password,
    String? fullName,
    String? mobile,
    String? email,
    String? beneficiaryRef,
    int? planId,
    double? customPrice,
    String? status,
    String? userType,
    String? serviceType,
    DateTime? expireAt,
    String? macLock,
    String? staticIp,
    String? remark,
    bool? bandwidthControlEnabled,
    int? downloadSpeedKbps,
    int? uploadSpeedKbps,
    int? overrideConcurrent,
    String? primaryDnsPpp,
    String? secondaryDnsPpp,
    String? callerId,
    String? workingDaysCsv,
    bool? autoRenewal,
    String? mtProfile,
    String? mtService,
    String? mtRateLimit,
    String? mtIpPool,
    String? mtComment,
    int? sessionTimeout,
    int? idleTimeout,
    String? calledStationId,
    String? allowedHours,
    bool? disableOnFirstUse,
    bool? notifyOnLogin,
    String? notifyEmail,
    String? notifyMobile,
    String? subscriptionType,
    int? subscriptionDays,
    String? notes,
    List<String>? tags,
  }) =>
      Subscriber(
        id: id ?? this.id,
        username: username ?? this.username,
        password: password ?? this.password,
        fullName: fullName ?? this.fullName,
        mobile: mobile ?? this.mobile,
        email: email ?? this.email,
        beneficiaryRef: beneficiaryRef ?? this.beneficiaryRef,
        planId: planId ?? this.planId,
        customPrice: customPrice ?? this.customPrice,
        status: status ?? this.status,
        userType: userType ?? this.userType,
        serviceType: serviceType ?? this.serviceType,
        expireAt: expireAt ?? this.expireAt,
        macLock: macLock ?? this.macLock,
        staticIp: staticIp ?? this.staticIp,
        remark: remark ?? this.remark,
        bandwidthControlEnabled:
            bandwidthControlEnabled ?? this.bandwidthControlEnabled,
        downloadSpeedKbps: downloadSpeedKbps ?? this.downloadSpeedKbps,
        uploadSpeedKbps: uploadSpeedKbps ?? this.uploadSpeedKbps,
        overrideConcurrent: overrideConcurrent ?? this.overrideConcurrent,
        primaryDnsPpp: primaryDnsPpp ?? this.primaryDnsPpp,
        secondaryDnsPpp: secondaryDnsPpp ?? this.secondaryDnsPpp,
        callerId: callerId ?? this.callerId,
        workingDaysCsv: workingDaysCsv ?? this.workingDaysCsv,
        autoRenewal: autoRenewal ?? this.autoRenewal,
        mtProfile: mtProfile ?? this.mtProfile,
        mtService: mtService ?? this.mtService,
        mtRateLimit: mtRateLimit ?? this.mtRateLimit,
        mtIpPool: mtIpPool ?? this.mtIpPool,
        mtComment: mtComment ?? this.mtComment,
        sessionTimeout: sessionTimeout ?? this.sessionTimeout,
        idleTimeout: idleTimeout ?? this.idleTimeout,
        calledStationId: calledStationId ?? this.calledStationId,
        allowedHours: allowedHours ?? this.allowedHours,
        disableOnFirstUse: disableOnFirstUse ?? this.disableOnFirstUse,
        notifyOnLogin: notifyOnLogin ?? this.notifyOnLogin,
        notifyEmail: notifyEmail ?? this.notifyEmail,
        notifyMobile: notifyMobile ?? this.notifyMobile,
        subscriptionType: subscriptionType ?? this.subscriptionType,
        subscriptionDays: subscriptionDays ?? this.subscriptionDays,
        notes: notes ?? this.notes,
        tags: tags ?? this.tags,
      );
}
