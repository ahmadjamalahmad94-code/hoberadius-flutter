/// Subscriber model — mirrors the server-side `Subscriber` DTO and the
/// `/api/v1/accounts` `_EDITABLE` whitelist (see `app/api/v1/accounts.py`).
///
/// The Flask API has two storage tiers:
/// * flat columns (working_days, mac_lock, override_concurrent, the personal /
///   balance / speed / quota / network / pppoe fields, ...)
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
    this.balance = 0,
    this.status = 'enabled',
    this.userType = 'subscriber',
    this.serviceType = 'Hotspot',
    this.expireAt,
    this.macLock = '',
    this.staticIp = '',
    this.remark = '',
    // — management —
    this.managerId,
    this.group = '',
    this.pool = '',
    // — personal extras —
    this.fatherName = '',
    this.nationalId = '',
    this.accountType = 'Personal',
    this.nationality = '',
    this.country = '',
    this.address = '',
    this.city = '',
    this.district = '',
    this.state = '',
    this.zip = '',
    this.coordinates = '',
    this.photoUrl = '',
    this.paymentMethod = '',
    this.paymentReference = '',
    // — bandwidth flat overrides —
    this.bandwidthControlEnabled = false,
    this.downloadSpeedKbps = 0,
    this.uploadSpeedKbps = 0,
    this.customSpeed = false,
    this.temporarySpeed = false,
    // — quota / time limits —
    this.combinedQuotaMb = 0,
    this.downloadQuotaMb = 0,
    this.uploadQuotaMb = 0,
    this.totalConnectionTimeMin = 0,
    this.dailyConnectionTimeMin = 0,
    this.quotaLimitEnabled = false,
    this.connectionTimeLimitEnabled = false,
    this.equalShareDownload = false,
    this.equalShareUpload = false,
    // — networking flat —
    this.overrideConcurrent = 0,
    this.vlanId = 0,
    this.deviceCount = 1,
    this.allowedMacs = '',
    this.deviceConnectionFile = '',
    this.primaryDnsPpp = '',
    this.secondaryDnsPpp = '',
    this.callerId = '',
    this.workingDaysCsv = '',
    this.autoRenewal = true,
    // — pppoe / broadband —
    this.pppoeUsername = '',
    this.pppoePassword = '',
    this.pppoeIp = '',
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
  final double balance;
  final String status;
  final String userType;
  final String serviceType;
  final DateTime? expireAt;
  final String macLock;
  final String staticIp;
  final String remark;

  final int? managerId;
  final String group;
  final String pool;

  final String fatherName;
  final String nationalId;
  final String accountType;
  final String nationality;
  final String country;
  final String address;
  final String city;
  final String district;
  final String state;
  final String zip;
  final String coordinates;
  final String photoUrl;
  final String paymentMethod;
  final String paymentReference;

  final bool bandwidthControlEnabled;
  final int downloadSpeedKbps;
  final int uploadSpeedKbps;
  final bool customSpeed;
  final bool temporarySpeed;

  final int combinedQuotaMb;
  final int downloadQuotaMb;
  final int uploadQuotaMb;
  final int totalConnectionTimeMin;
  final int dailyConnectionTimeMin;
  final bool quotaLimitEnabled;
  final bool connectionTimeLimitEnabled;
  final bool equalShareDownload;
  final bool equalShareUpload;

  final int overrideConcurrent;
  final int vlanId;
  final int deviceCount;
  final String allowedMacs;
  final String deviceConnectionFile;
  final String primaryDnsPpp;
  final String secondaryDnsPpp;
  final String callerId;

  /// CSV of two-letter day codes: "sat,sun,mon,tue,wed,thu,fri"
  final String workingDaysCsv;
  final bool autoRenewal;

  final String pppoeUsername;
  final String pppoePassword;
  final String pppoeIp;

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
      balance: _double(j['balance']) ?? 0,
      status: (j['status'] ?? 'enabled').toString(),
      userType: (j['user_type'] ?? 'subscriber').toString(),
      serviceType: (j['service_type'] ?? 'Hotspot').toString(),
      expireAt: _parseDt(j['expire_at']),
      macLock: (j['mac_lock'] ?? '').toString(),
      staticIp: (j['static_ip'] ?? '').toString(),
      remark: (j['remark'] ?? '').toString(),
      managerId: _int(j['manager_id']),
      group: (j['group'] ?? '').toString(),
      pool: (j['pool'] ?? '').toString(),
      fatherName: (j['father_name'] ?? '').toString(),
      nationalId: (j['national_id'] ?? '').toString(),
      accountType: (j['account_type'] ?? 'Personal').toString(),
      nationality: (j['nationality'] ?? '').toString(),
      country: (j['country'] ?? '').toString(),
      address: (j['address'] ?? '').toString(),
      city: (j['city'] ?? '').toString(),
      district: (j['district'] ?? '').toString(),
      state: (j['state'] ?? '').toString(),
      zip: (j['zip'] ?? '').toString(),
      coordinates: (j['coordinates'] ?? '').toString(),
      photoUrl: (j['photo_url'] ?? '').toString(),
      paymentMethod: (j['payment_method'] ?? '').toString(),
      paymentReference: (j['payment_reference'] ?? '').toString(),
      bandwidthControlEnabled: j['bandwidth_control_enabled'] == true,
      downloadSpeedKbps: _int(j['download_speed_kbps']) ?? 0,
      uploadSpeedKbps: _int(j['upload_speed_kbps']) ?? 0,
      customSpeed: j['custom_speed'] == true,
      temporarySpeed: j['temporary_speed'] == true,
      combinedQuotaMb: _int(j['combined_quota_mb']) ?? 0,
      downloadQuotaMb: _int(j['download_quota_mb']) ?? 0,
      uploadQuotaMb: _int(j['upload_quota_mb']) ?? 0,
      totalConnectionTimeMin: _int(j['total_connection_time_min']) ?? 0,
      dailyConnectionTimeMin: _int(j['daily_connection_time_min']) ?? 0,
      quotaLimitEnabled: j['quota_limit_enabled'] == true,
      connectionTimeLimitEnabled: j['connection_time_limit_enabled'] == true,
      equalShareDownload: j['equal_share_download'] == true,
      equalShareUpload: j['equal_share_upload'] == true,
      overrideConcurrent: _int(j['override_concurrent']) ?? 0,
      vlanId: _int(j['vlan_id']) ?? 0,
      deviceCount: _int(j['device_count']) ?? 1,
      allowedMacs: (j['allowed_macs'] ?? '').toString(),
      deviceConnectionFile: (j['device_connection_file'] ?? '').toString(),
      primaryDnsPpp: (j['primary_dns_ppp'] ?? '').toString(),
      secondaryDnsPpp: (j['secondary_dns_ppp'] ?? '').toString(),
      callerId: (j['caller_id'] ?? '').toString(),
      workingDaysCsv: (j['working_days'] ?? '').toString(),
      autoRenewal: j['auto_renewal'] == true || j['auto_renewal'] == 1,
      pppoeUsername: (j['pppoe_username'] ?? '').toString(),
      pppoePassword: (j['pppoe_password'] ?? '').toString(),
      pppoeIp: (j['pppoe_ip'] ?? '').toString(),
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
      'balance': balance,
      'status': status,
      'user_type': userType,
      'service_type': serviceType,
      if (expireAt != null) 'expire_at': expireAt!.toUtc().toIso8601String(),
      'mac_lock': macLock,
      'static_ip': staticIp,
      'remark': remark,
      if (managerId != null) 'manager_id': managerId,
      'group': group,
      'pool': pool,
      'father_name': fatherName,
      'national_id': nationalId,
      'account_type': accountType,
      'nationality': nationality,
      'country': country,
      'address': address,
      'city': city,
      'district': district,
      'state': state,
      'zip': zip,
      'coordinates': coordinates,
      if (photoUrl.isNotEmpty) 'photo_url': photoUrl,
      'payment_method': paymentMethod,
      'payment_reference': paymentReference,
      'bandwidth_control_enabled': bandwidthControlEnabled,
      'download_speed_kbps': downloadSpeedKbps,
      'upload_speed_kbps': uploadSpeedKbps,
      'custom_speed': customSpeed,
      'temporary_speed': temporarySpeed,
      'combined_quota_mb': combinedQuotaMb,
      'download_quota_mb': downloadQuotaMb,
      'upload_quota_mb': uploadQuotaMb,
      'total_connection_time_min': totalConnectionTimeMin,
      'daily_connection_time_min': dailyConnectionTimeMin,
      'quota_limit_enabled': quotaLimitEnabled,
      'connection_time_limit_enabled': connectionTimeLimitEnabled,
      'equal_share_download': equalShareDownload,
      'equal_share_upload': equalShareUpload,
      'override_concurrent': overrideConcurrent,
      'vlan_id': vlanId,
      'device_count': deviceCount,
      'allowed_macs': allowedMacs,
      'device_connection_file': deviceConnectionFile,
      'primary_dns_ppp': primaryDnsPpp,
      'secondary_dns_ppp': secondaryDnsPpp,
      'caller_id': callerId,
      'working_days': workingDaysCsv,
      'auto_renewal': autoRenewal,
      'pppoe_username': pppoeUsername,
      if (pppoePassword.isNotEmpty) 'pppoe_password': pppoePassword,
      'pppoe_ip': pppoeIp,
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
    double? balance,
    String? status,
    String? userType,
    String? serviceType,
    DateTime? expireAt,
    String? macLock,
    String? staticIp,
    String? remark,
    int? managerId,
    String? group,
    String? pool,
    String? fatherName,
    String? nationalId,
    String? accountType,
    String? nationality,
    String? country,
    String? address,
    String? city,
    String? district,
    String? state,
    String? zip,
    String? coordinates,
    String? photoUrl,
    String? paymentMethod,
    String? paymentReference,
    bool? bandwidthControlEnabled,
    int? downloadSpeedKbps,
    int? uploadSpeedKbps,
    bool? customSpeed,
    bool? temporarySpeed,
    int? combinedQuotaMb,
    int? downloadQuotaMb,
    int? uploadQuotaMb,
    int? totalConnectionTimeMin,
    int? dailyConnectionTimeMin,
    bool? quotaLimitEnabled,
    bool? connectionTimeLimitEnabled,
    bool? equalShareDownload,
    bool? equalShareUpload,
    int? overrideConcurrent,
    int? vlanId,
    int? deviceCount,
    String? allowedMacs,
    String? deviceConnectionFile,
    String? primaryDnsPpp,
    String? secondaryDnsPpp,
    String? callerId,
    String? workingDaysCsv,
    bool? autoRenewal,
    String? pppoeUsername,
    String? pppoePassword,
    String? pppoeIp,
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
        balance: balance ?? this.balance,
        status: status ?? this.status,
        userType: userType ?? this.userType,
        serviceType: serviceType ?? this.serviceType,
        expireAt: expireAt ?? this.expireAt,
        macLock: macLock ?? this.macLock,
        staticIp: staticIp ?? this.staticIp,
        remark: remark ?? this.remark,
        managerId: managerId ?? this.managerId,
        group: group ?? this.group,
        pool: pool ?? this.pool,
        fatherName: fatherName ?? this.fatherName,
        nationalId: nationalId ?? this.nationalId,
        accountType: accountType ?? this.accountType,
        nationality: nationality ?? this.nationality,
        country: country ?? this.country,
        address: address ?? this.address,
        city: city ?? this.city,
        district: district ?? this.district,
        state: state ?? this.state,
        zip: zip ?? this.zip,
        coordinates: coordinates ?? this.coordinates,
        photoUrl: photoUrl ?? this.photoUrl,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        paymentReference: paymentReference ?? this.paymentReference,
        bandwidthControlEnabled:
            bandwidthControlEnabled ?? this.bandwidthControlEnabled,
        downloadSpeedKbps: downloadSpeedKbps ?? this.downloadSpeedKbps,
        uploadSpeedKbps: uploadSpeedKbps ?? this.uploadSpeedKbps,
        customSpeed: customSpeed ?? this.customSpeed,
        temporarySpeed: temporarySpeed ?? this.temporarySpeed,
        combinedQuotaMb: combinedQuotaMb ?? this.combinedQuotaMb,
        downloadQuotaMb: downloadQuotaMb ?? this.downloadQuotaMb,
        uploadQuotaMb: uploadQuotaMb ?? this.uploadQuotaMb,
        totalConnectionTimeMin:
            totalConnectionTimeMin ?? this.totalConnectionTimeMin,
        dailyConnectionTimeMin:
            dailyConnectionTimeMin ?? this.dailyConnectionTimeMin,
        quotaLimitEnabled: quotaLimitEnabled ?? this.quotaLimitEnabled,
        connectionTimeLimitEnabled:
            connectionTimeLimitEnabled ?? this.connectionTimeLimitEnabled,
        equalShareDownload: equalShareDownload ?? this.equalShareDownload,
        equalShareUpload: equalShareUpload ?? this.equalShareUpload,
        overrideConcurrent: overrideConcurrent ?? this.overrideConcurrent,
        vlanId: vlanId ?? this.vlanId,
        deviceCount: deviceCount ?? this.deviceCount,
        allowedMacs: allowedMacs ?? this.allowedMacs,
        deviceConnectionFile: deviceConnectionFile ?? this.deviceConnectionFile,
        primaryDnsPpp: primaryDnsPpp ?? this.primaryDnsPpp,
        secondaryDnsPpp: secondaryDnsPpp ?? this.secondaryDnsPpp,
        callerId: callerId ?? this.callerId,
        workingDaysCsv: workingDaysCsv ?? this.workingDaysCsv,
        autoRenewal: autoRenewal ?? this.autoRenewal,
        pppoeUsername: pppoeUsername ?? this.pppoeUsername,
        pppoePassword: pppoePassword ?? this.pppoePassword,
        pppoeIp: pppoeIp ?? this.pppoeIp,
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
