import 'package:hoberadius_app/core/format/server_time.dart';

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
    // — parity with the web form (all enforced by the policy engine) —
    this.loginWithoutPassword = false,
    this.deviceLimitMode = '',
    this.connectionSchedule = '',
    this.netFilterChain = '',
    this.netAddressList = '',
    this.netFramedRoute = '',
    this.netUserGroup = '',
    this.netQueuePriority = '',
    this.netFramedPool = '',
    this.netAcctInterimSec = '',
    this.netPppExtra = '',
    // — read-only counters —
    this.usedSeconds = 0,
    this.usedBytesIn = 0,
    this.usedBytesOut = 0,
    this.onlineCount = 0,
    this.lastSeenAt,
    this.firstLoginAt,
    this.createdAt,
    this.updatedAt,
    this.rawMetadata = const <String, dynamic>{},
    this.live,
    this.online = false,
    this.accessType = '',
    this.temporaryAccount = false,
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

  /// «قسم كلمة المرور» معطَّل: the subscriber logs in by name only (the
  /// stored password is kept). Read by the policy engine.
  final bool loginWithoutPassword;

  /// «عند بلوغ حدّ الأجهزة»: '' (the panel default) | reject | replace.
  final String deviceLimitMode;

  /// «الأيام والأوقات المسموحة للاتصال» — the server's access-schedule JSON
  /// (`{"windows":[{"days":[..],"from":"HH:MM","to":"HH:MM"}]}`); '' = no
  /// restriction. The server derives `working_days` from it.
  final String connectionSchedule;

  /// «إعدادات شبكة متقدمة جدًا» — the web form's metadata keys
  /// (`mikrotik.mikrotik_*`, `radius.framed_pool|acct_interim_interval_sec|
  /// ppp_attributes_extra`), sent as RADIUS reply attributes on login.
  final String netFilterChain;
  final String netAddressList;
  final String netFramedRoute;
  final String netUserGroup;
  final String netQueuePriority;
  final String netFramedPool;
  final String netAcctInterimSec;
  final String netPppExtra;

  final int usedSeconds;
  final int usedBytesIn;
  final int usedBytesOut;
  final int onlineCount;
  final DateTime? lastSeenAt;
  final DateTime? firstLoginAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// The server's full `metadata` object as loaded. `metadata` is replaced
  /// as a whole by PATCH, so a partial save merges the form's sections into
  /// this instead of dropping keys the app does not edit.
  final Map<String, dynamic> rawMetadata;

  /// The current session when [online], else the LAST one (`live`); null
  /// when the server has none or is older (the list keeps an empty strip).
  final SubscriberLive? live;

  /// Has an open session now (`online`; false on older servers).
  final bool online;

  /// `hotspot` | `broadband` | `both` | '' (unknown / older server).
  final String accessType;

  /// «مؤقت» — on a «استخدام مرة وحدة» plan (server `temporary_account`,
  /// list endpoint only): disabled at expiry, never renewed/extended.
  final bool temporaryAccount;

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
      loginWithoutPassword: j['login_without_password'] == true ||
          j['login_without_password'] == 1,
      deviceLimitMode: (j['device_limit_mode'] ?? '').toString(),
      connectionSchedule: (j['connection_schedule'] ?? '').toString(),
      netFilterChain: _metaStr(mt['mikrotik_filter_chain']),
      netAddressList: _metaStr(mt['mikrotik_address_list']),
      netFramedRoute: _metaStr(mt['mikrotik_framed_route']),
      netUserGroup: _metaStr(mt['mikrotik_user_group']),
      netQueuePriority: _metaStr(mt['mikrotik_queue_priority']),
      netFramedPool: _metaStr(rad['framed_pool']),
      netAcctInterimSec: _metaStr(rad['acct_interim_interval_sec']),
      netPppExtra: _metaStr(rad['ppp_attributes_extra']),
      // counters
      usedSeconds: _int(j['used_seconds']) ?? 0,
      usedBytesIn: _int(j['used_bytes_in']) ?? 0,
      usedBytesOut: _int(j['used_bytes_out']) ?? 0,
      onlineCount: _int(j['online_count']) ?? 0,
      lastSeenAt: _parseDt(j['last_seen_at']),
      firstLoginAt: _parseDt(j['first_login_at']),
      createdAt: _parseDt(j['created_at']),
      updatedAt: _parseDt(j['updated_at']),
      rawMetadata: meta,
      live: SubscriberLive.tryParse(j['live']),
      online: j['online'] == true ||
          (j['live'] is Map && (j['live'] as Map)['online'] == true),
      accessType: (j['access_type'] ?? '').toString().trim().toLowerCase(),
      temporaryAccount: j['temporary_account'] == true,
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
      if (expireAt != null) 'expire_at': toServerUtcIso(expireAt!),
      'mac_lock': macLock,
      'static_ip': staticIp,
      'remark': remark,
      if (managerId != null) 'manager_id': managerId,
      'group': group,
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
      'device_count': deviceCount,
      'allowed_macs': allowedMacs,
      'primary_dns_ppp': primaryDnsPpp,
      'secondary_dns_ppp': secondaryDnsPpp,
      'caller_id': callerId,
      // `working_days` is no longer edited here: the server derives it from
      // `connection_schedule` (the web form's «الأيام والأوقات المسموحة»).
      'connection_schedule': connectionSchedule,
      'login_without_password': loginWithoutPassword,
      'device_limit_mode': deviceLimitMode,
      'auto_renewal': autoRenewal,
      // Retired (owner 2026-10-06, never sent): pool, vlan_id,
      // device_connection_file and the separate PPPoE name/password — a
      // PPPoE subscriber logs in with its own username/password. «IP PPPoE»
      // (pppoe_ip) was merged into «IP ثابت» (static_ip, follow-up
      // 2026-10-06): read for display only, never sent.
      'metadata': _metadata(),
    };
  }

  /// The create body. `balance` is never sent: money enters a wallet only
  /// through «إضافة رصيد» (spend gate + ledger); fix2 servers answer a
  /// restricted manager's opening balance with 403.
  ///
  /// [explicitNoExpiry] («بدون انتهاء» chosen on purpose, no date): sends
  /// `expire_at: null` — the server then never expires the subscriber. An
  /// absent key instead follows the server's `create_without_expiry`
  /// («expired» by default = born expired until renewed).
  Map<String, dynamic> toCreateBody({bool explicitNoExpiry = false}) {
    final body = _flat(true)..remove('balance');
    if (explicitNoExpiry && expireAt == null) body['expire_at'] = null;
    return body;
  }

  /// Fields never written by the edit form: money moves through the balance
  /// / payment actions (with a ledger row), the password through «إعادة كلمة
  /// المرور».
  static const _neverPatched = {'balance', 'password', 'username'};

  /// Network fields whose «empty» is NULL on the server, not "".
  static const _nullWhenEmpty = {'mac_lock', 'static_ip'};

  /// PATCH body with ONLY the fields that differ from [original] (the row as
  /// loaded into the form). Saving an untouched form after another action
  /// (extend, payment, balance) no longer writes the stale expiry/balance
  /// back; `balance` is never sent; an emptied mac_lock/static_ip becomes
  /// null; `metadata` travels only when one of its sections changed, merged
  /// into the server's full metadata.
  Map<String, dynamic> toPatchDiff(Subscriber original) {
    final now = _flat(false);
    final before = original._flat(false);
    final out = <String, dynamic>{};
    final keys = {...now.keys, ...before.keys}
      ..remove('metadata')
      ..removeAll(_neverPatched);
    for (final k in keys) {
      final a = before[k];
      final b = now[k];
      if (_sameValue(k, a, b)) continue;
      if (_nullWhenEmpty.contains(k) && (b == null || b == '')) {
        out[k] = null;
      } else if (b == null && k == 'plan_id') {
        out[k] = null;
      } else if (b == null && k == 'manager_id') {
        out[k] = 0;
      } else if (b == null && k == 'expire_at') {
        out[k] = null;
      } else if (b != null) {
        out[k] = b;
      }
    }
    final metaNow = _metadata();
    final metaBefore = original._metadata();
    if (!_deepEquals(metaNow, metaBefore)) {
      out['metadata'] = _deepMerge(original.rawMetadata, metaNow);
    }
    return out;
  }

  static bool _sameValue(String key, Object? a, Object? b) {
    if (a is num && b is num) {
      final tolerance = key == 'custom_price' ? 0.005 : 1e-9;
      return (a - b).abs() < tolerance;
    }
    if (_nullWhenEmpty.contains(key)) {
      return (a ?? '').toString() == (b ?? '').toString();
    }
    return _deepEquals(a, b);
  }

  static bool _deepEquals(Object? a, Object? b) {
    if (a is Map && b is Map) {
      if (a.length != b.length) return false;
      for (final k in a.keys) {
        if (!b.containsKey(k) || !_deepEquals(a[k], b[k])) return false;
      }
      return true;
    }
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (var i = 0; i < a.length; i++) {
        if (!_deepEquals(a[i], b[i])) return false;
      }
      return true;
    }
    if (a is num && b is num) return a == b;
    return a == b;
  }

  static Map<String, dynamic> _deepMerge(
    Map<String, dynamic> base,
    Map<String, dynamic> over,
  ) {
    final out = <String, dynamic>{...base};
    over.forEach((k, v) {
      final prev = out[k];
      if (v is Map && prev is Map) {
        out[k] = _deepMerge(
          Map<String, dynamic>.from(prev),
          Map<String, dynamic>.from(v),
        );
      } else {
        out[k] = v;
      }
    });
    return out;
  }

  Map<String, dynamic> toPatchBody() => _flat(false);

  Map<String, dynamic> _metadata() => {
        // Retired metadata (owner 2026-10-06 — no reader on the server, the
        // server keeps the stored values): mikrotik profile / rate_limit /
        // ip_pool / comment, radius session/idle timeout + called-station,
        // advanced.disable_on_first_use, notifications.*, subscription.*.
        'mikrotik': {
          'service': mtService,
          'mikrotik_filter_chain': netFilterChain,
          'mikrotik_address_list': netAddressList,
          'mikrotik_framed_route': netFramedRoute,
          'mikrotik_user_group': netUserGroup,
          'mikrotik_queue_priority': netQueuePriority,
        },
        'radius': {
          'framed_pool': netFramedPool,
          'acct_interim_interval_sec': netAcctInterimSec,
          'ppp_attributes_extra': netPppExtra,
        },
        'advanced': {
          'allowed_hours': allowedHours,
        },
        'general': {
          'notes': notes,
          'tags': tags,
        },
      };

  /// Server datetimes are UTC (with or without a trailing «Z»). Read them as
  /// UTC and show them in the phone's local time. Dropping the «Z» used to
  /// read 20:59 UTC as 20:59 LOCAL — and `toJson` then converted that back
  /// to UTC, so every save from the edit form cut the expiry by the UTC
  /// offset (3 h in Palestine).
  static DateTime? _parseDt(Object? v) => parseServerDateTime(v);

  static String _metaStr(Object? v) => v == null ? '' : v.toString();

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
    bool? loginWithoutPassword,
    String? deviceLimitMode,
    String? connectionSchedule,
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
        loginWithoutPassword: loginWithoutPassword ?? this.loginWithoutPassword,
        deviceLimitMode: deviceLimitMode ?? this.deviceLimitMode,
        connectionSchedule: connectionSchedule ?? this.connectionSchedule,
        netFilterChain: netFilterChain,
        netAddressList: netAddressList,
        netFramedRoute: netFramedRoute,
        netUserGroup: netUserGroup,
        netQueuePriority: netQueuePriority,
        netFramedPool: netFramedPool,
        netAcctInterimSec: netAcctInterimSec,
        netPppExtra: netPppExtra,
      );
}

// ── Username / password rules (create form = rename dialog = server) ─────────

/// The server's rule for a subscriber login name (`^[A-Za-z0-9._@-]{1,64}$`,
/// the same check the rename endpoint always had): Latin letters, digits and
/// «. _ - @», no spaces, no Arabic/emoji, no «/» (it made the account
/// unreachable by URL). The app also asks for at least 3 characters, like the
/// rename dialog.
final RegExp kSubscriberUsernamePattern = RegExp(r'^[A-Za-z0-9._@\-]+$');
const int kSubscriberUsernameMin = 3;
const int kSubscriberUsernameMax = 64;

/// Minimum subscriber password length — the same minimum the web applies to
/// card-user / marketplace passwords (4). A one-character password was
/// accepted before.
const int kSubscriberPasswordMin = 4;
const int kSubscriberPasswordMax = 64;

/// Arabic error for an invalid login name, or `null` when it is fine.
String? validateSubscriberUsernameFormat(String value) {
  final v = value.trim();
  if (v.isEmpty) return 'اسم المستخدم مطلوب.';
  if (v.contains(RegExp(r'\s'))) return 'اسم المستخدم بدون مسافات.';
  if (v.length < kSubscriberUsernameMin) {
    return 'اسم المستخدم $kSubscriberUsernameMin أحرف على الأقل.';
  }
  if (v.length > kSubscriberUsernameMax) {
    return 'اسم المستخدم $kSubscriberUsernameMax حرفًا على الأكثر.';
  }
  if (!kSubscriberUsernamePattern.hasMatch(v)) {
    return 'أحرف لاتينية وأرقام و . _ - @ فقط.';
  }
  return null;
}

/// Username of a NEW subscriber (create form).
String? validateNewSubscriberUsername(String value) =>
    validateSubscriberUsernameFormat(value);

/// Password of a new subscriber / a password reset.
String? validateNewSubscriberPassword(String value) {
  if (value.isEmpty) return 'كلمة المرور مطلوبة.';
  if (value.trim().isEmpty) return 'كلمة المرور لا تكون مسافات فقط.';
  if (value.length < kSubscriberPasswordMin) {
    return 'كلمة المرور $kSubscriberPasswordMin أحرف على الأقل.';
  }
  if (value.length > kSubscriberPasswordMax) {
    return 'كلمة المرور $kSubscriberPasswordMax حرفًا على الأكثر.';
  }
  return null;
}

/// The `live` block of a subscriber row: the open session, or the last one.
/// `bytesIn` = the user's UPLOAD (رفع), `bytesOut` = DOWNLOAD (تنزيل) —
/// RFC 2866 octets, the same mapping as «المتصلون».
class SubscriberLive {
  const SubscriberLive({
    required this.online,
    this.bytesIn = 0,
    this.bytesOut = 0,
    this.framedIp = '',
    this.startedAt,
    this.stoppedAt,
    this.sessionTime = 0,
    this.accessType = '',
  });

  final bool online;
  final int bytesIn;
  final int bytesOut;
  final String framedIp;
  final DateTime? startedAt;
  final DateTime? stoppedAt;
  final int sessionTime;
  final String accessType;

  static SubscriberLive? tryParse(Object? raw) {
    if (raw is! Map) return null;
    int n(Object? v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}') ?? 0;
    DateTime? dt(Object? v) {
      if (v == null || '$v'.trim().isEmpty) return null;
      try {
        return parseServerDateTime(v);
      } catch (_) {
        return null;
      }
    }

    final ip = raw['framed_ip'] ?? raw['framed_ip_address'];
    return SubscriberLive(
      online: raw['online'] == true,
      bytesIn: n(raw['bytes_in']),
      bytesOut: n(raw['bytes_out']),
      framedIp: ip == null ? '' : '$ip'.trim(),
      startedAt: dt(raw['started_at']),
      stoppedAt: dt(raw['stopped_at']),
      sessionTime: n(raw['session_time']),
      accessType: '${raw['access_type'] ?? ''}'.trim().toLowerCase(),
    );
  }

  /// Seconds to show: an open session counts up from its start (the stored
  /// session_time only moves on each interim update); a closed one shows
  /// its recorded length.
  int durationSeconds(DateTime now) {
    final start = startedAt;
    if (online && start != null) {
      final live = now.difference(start).inSeconds;
      if (live > sessionTime) return live;
    }
    return sessionTime;
  }
}
