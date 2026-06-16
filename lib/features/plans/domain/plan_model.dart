/// Plan (Profile) model — mirrors `AccessPlan` on the server.
///
/// The DTO has 60+ fields; this model exposes the subset that mobile/desktop
/// admins typically edit, plus pass-through round-trip on raw metadata for
/// the advanced groups (general / subscription / advanced / mikrotik /
/// notifications). Anything not listed here flows through `extraFields`
/// untouched, so the API contract doesn't break if the backend grows.
class Plan {
  Plan({
    this.id,
    required this.name,
    this.code = '',
    this.planType = 'time',
    this.serviceType = 'Hotspot',
    this.description = '',
    this.color = '#2BAACC',
    this.enabled = true,
    this.priority = 100,
    // — time / quota
    this.durationMinutes = 0,
    this.validityDays = 0,
    this.maxDailyMinutes = 0,
    this.maxWeeklyMinutes = 0,
    this.maxMonthlyMinutes = 0,
    this.sessionTimeoutSec = 0,
    this.idleTimeoutSec = 0,
    this.quotaTotalMb = 0,
    this.quotaDailyMb = 0,
    this.quotaMonthlyMb = 0,
    this.quotaResetStrategy = 'rolling',
    // RM-H3 split quotas (daily / monthly per-direction)
    this.dailyDownloadQuotaMb = 0,
    this.dailyUploadQuotaMb = 0,
    this.dailyCombinedQuotaMb = 0,
    this.monthlyDownloadQuotaMb = 0,
    this.monthlyUploadQuotaMb = 0,
    this.monthlyCombinedQuotaMb = 0,
    // — speed
    this.speedDownKbps = 0,
    this.speedUpKbps = 0,
    this.speedControlEnabled = false,
    this.cirDownKbps = 0,
    this.cirUpKbps = 0,
    this.burstEnabled = false,
    this.burstDownKbps = 0,
    this.burstUpKbps = 0,
    this.burstThresholdKbps = 0,
    this.burstTimeSec = 0,
    this.nightlyUnlimitedEnabled = false,
    // — sessions / network
    this.concurrentSessions = 1,
    this.addressPool = '',
    this.framedPool = '',
    this.vlanId = 0,
    this.ipv6Pool = '',
    this.bindMac = false,
    this.bindIp = false,
    this.allowedDays = const ['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'],
    this.allowedHoursFrom = '',
    this.allowedHoursTo = '',
    // — commerce
    this.price = 0,
    this.priceCard = 0,
    this.priceBulk = 0,
    this.currency = 'JOD',
    this.planTier = 'Personal',
    this.prepaid = true,
    this.autoRenew = false,
    // — RM-H3 extras
    this.singleUseOnce = false,
    this.maxConsumptionTimes = 0,
    this.ticketValidityDays = 0,
    this.workingHoursLimit = 0,
    this.hotspotEnabled = false,
    this.pppEnabled = false,
    this.loanEnabled = false,
    this.maxLoanMinutes = 0,
    this.speedOverrideAllowed = false,
    this.allowedDevicesCount = 0,
    this.forceMacAddress = false,
    this.offerHoursFrom = '',
    this.offerHoursTo = '',
    // — opaque
    this.metadata = const {},
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final String name;
  final String code;
  final String planType;
  final String serviceType;
  final String description;
  final String color;
  final bool enabled;
  final int priority;

  final int durationMinutes;
  final int validityDays;
  final int maxDailyMinutes;
  final int maxWeeklyMinutes;
  final int maxMonthlyMinutes;
  final int sessionTimeoutSec;
  final int idleTimeoutSec;
  final int quotaTotalMb;
  final int quotaDailyMb;
  final int quotaMonthlyMb;
  final String quotaResetStrategy;
  final int dailyDownloadQuotaMb;
  final int dailyUploadQuotaMb;
  final int dailyCombinedQuotaMb;
  final int monthlyDownloadQuotaMb;
  final int monthlyUploadQuotaMb;
  final int monthlyCombinedQuotaMb;

  final int speedDownKbps;
  final int speedUpKbps;
  final bool speedControlEnabled;
  final int cirDownKbps;
  final int cirUpKbps;
  final bool burstEnabled;
  final int burstDownKbps;
  final int burstUpKbps;
  final int burstThresholdKbps;
  final int burstTimeSec;
  final bool nightlyUnlimitedEnabled;

  final int concurrentSessions;
  final String addressPool;
  final String framedPool;
  final int vlanId;
  final String ipv6Pool;
  final bool bindMac;
  final bool bindIp;
  final List<String> allowedDays;
  final String allowedHoursFrom;
  final String allowedHoursTo;

  final num price;
  final num priceCard;
  final num priceBulk;
  final String currency;
  final String planTier;
  final bool prepaid;
  final bool autoRenew;

  final bool singleUseOnce;
  final int maxConsumptionTimes;
  final int ticketValidityDays;
  final int workingHoursLimit;
  final bool hotspotEnabled;
  final bool pppEnabled;
  final bool loanEnabled;
  final int maxLoanMinutes;
  final bool speedOverrideAllowed;
  final int allowedDevicesCount;
  final bool forceMacAddress;
  final String offerHoursFrom;
  final String offerHoursTo;

  final Map<String, dynamic> metadata;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Plan.fromJson(Map<String, dynamic> j) {
    final meta = (j['metadata'] is Map<String, dynamic>)
        ? j['metadata'] as Map<String, dynamic>
        : const <String, dynamic>{};
    return Plan(
      id: j['id'] as int?,
      name: (j['name'] ?? '').toString(),
      code: (j['code'] ?? '').toString(),
      planType: (j['plan_type'] ?? 'time').toString(),
      serviceType: (j['service_type'] ?? 'Hotspot').toString(),
      description: (j['description'] ?? '').toString(),
      color: (j['color'] ?? '#2BAACC').toString(),
      enabled: j['enabled'] == true || j['enabled'] == 1,
      priority: _int(j['priority']) ?? 100,
      durationMinutes: _int(j['duration_minutes']) ?? 0,
      validityDays: _int(j['validity_days']) ?? 0,
      maxDailyMinutes: _int(j['max_daily_minutes']) ?? 0,
      maxWeeklyMinutes: _int(j['max_weekly_minutes']) ?? 0,
      maxMonthlyMinutes: _int(j['max_monthly_minutes']) ?? 0,
      sessionTimeoutSec: _int(j['session_timeout_sec']) ?? 0,
      idleTimeoutSec: _int(j['idle_timeout_sec']) ?? 0,
      quotaTotalMb: _int(j['quota_total_mb']) ?? 0,
      quotaDailyMb: _int(j['quota_daily_mb']) ?? 0,
      quotaMonthlyMb: _int(j['quota_monthly_mb']) ?? 0,
      quotaResetStrategy: (j['quota_reset_strategy'] ?? 'rolling').toString(),
      dailyDownloadQuotaMb: _int(j['daily_download_quota_mb']) ?? 0,
      dailyUploadQuotaMb: _int(j['daily_upload_quota_mb']) ?? 0,
      dailyCombinedQuotaMb: _int(j['daily_combined_quota_mb']) ?? 0,
      monthlyDownloadQuotaMb: _int(j['monthly_download_quota_mb']) ?? 0,
      monthlyUploadQuotaMb: _int(j['monthly_upload_quota_mb']) ?? 0,
      monthlyCombinedQuotaMb: _int(j['monthly_combined_quota_mb']) ?? 0,
      speedDownKbps: _int(j['speed_down_kbps']) ?? 0,
      speedUpKbps: _int(j['speed_up_kbps']) ?? 0,
      speedControlEnabled: j['speed_control_enabled'] == true,
      cirDownKbps: _int(j['cir_down_kbps']) ?? 0,
      cirUpKbps: _int(j['cir_up_kbps']) ?? 0,
      burstEnabled: j['burst_enabled'] == true,
      burstDownKbps: _int(j['burst_down_kbps']) ?? 0,
      burstUpKbps: _int(j['burst_up_kbps']) ?? 0,
      burstThresholdKbps: _int(j['burst_threshold_kbps']) ?? 0,
      burstTimeSec: _int(j['burst_time_sec']) ?? 0,
      nightlyUnlimitedEnabled: j['nightly_unlimited_enabled'] == true,
      concurrentSessions: _int(j['concurrent_sessions']) ?? 1,
      addressPool: (j['address_pool'] ?? '').toString(),
      framedPool: (j['framed_pool'] ?? '').toString(),
      vlanId: _int(j['vlan_id']) ?? 0,
      ipv6Pool: (j['ipv6_pool'] ?? '').toString(),
      bindMac: j['bind_mac'] == true,
      bindIp: j['bind_ip'] == true,
      allowedDays: _strList(j['allowed_days']),
      allowedHoursFrom: (j['allowed_hours_from'] ?? '').toString(),
      allowedHoursTo: (j['allowed_hours_to'] ?? '').toString(),
      price: _num(j['price']) ?? 0,
      priceCard: _num(j['price_card']) ?? 0,
      priceBulk: _num(j['price_bulk']) ?? 0,
      currency: (j['currency'] ?? 'JOD').toString(),
      planTier: (j['plan_tier'] ?? 'Personal').toString(),
      prepaid: j['prepaid'] == true,
      autoRenew: j['auto_renew'] == true,
      singleUseOnce: j['single_use_once'] == true,
      maxConsumptionTimes: _int(j['max_consumption_times']) ?? 0,
      ticketValidityDays: _int(j['ticket_validity_days']) ?? 0,
      workingHoursLimit: _int(j['working_hours_limit']) ?? 0,
      hotspotEnabled: j['hotspot_enabled'] == true,
      pppEnabled: j['ppp_enabled'] == true,
      loanEnabled: j['loan_enabled'] == true,
      maxLoanMinutes: _int(j['max_loan_minutes']) ?? 0,
      speedOverrideAllowed: j['speed_override_allowed'] == true,
      allowedDevicesCount: _int(j['allowed_devices_count']) ?? 0,
      forceMacAddress: j['force_mac_address'] == true,
      offerHoursFrom: (j['offer_hours_from'] ?? '').toString(),
      offerHoursTo: (j['offer_hours_to'] ?? '').toString(),
      metadata: meta,
      createdAt: _dt(j['created_at']),
      updatedAt: _dt(j['updated_at']),
    );
  }

  Map<String, dynamic> toBody() => {
        'name': name,
        'code': code,
        'plan_type': planType,
        'service_type': serviceType,
        'description': description,
        'color': color,
        'enabled': enabled,
        'priority': priority,
        'duration_minutes': durationMinutes,
        'validity_days': validityDays,
        'max_daily_minutes': maxDailyMinutes,
        'max_weekly_minutes': maxWeeklyMinutes,
        'max_monthly_minutes': maxMonthlyMinutes,
        'session_timeout_sec': sessionTimeoutSec,
        'idle_timeout_sec': idleTimeoutSec,
        'quota_total_mb': quotaTotalMb,
        'quota_daily_mb': quotaDailyMb,
        'quota_monthly_mb': quotaMonthlyMb,
        'quota_reset_strategy': quotaResetStrategy,
        'daily_download_quota_mb': dailyDownloadQuotaMb,
        'daily_upload_quota_mb': dailyUploadQuotaMb,
        'daily_combined_quota_mb': dailyCombinedQuotaMb,
        'monthly_download_quota_mb': monthlyDownloadQuotaMb,
        'monthly_upload_quota_mb': monthlyUploadQuotaMb,
        'monthly_combined_quota_mb': monthlyCombinedQuotaMb,
        'speed_down_kbps': speedDownKbps,
        'speed_up_kbps': speedUpKbps,
        'speed_control_enabled': speedControlEnabled,
        'cir_down_kbps': cirDownKbps,
        'cir_up_kbps': cirUpKbps,
        'burst_enabled': burstEnabled,
        'burst_down_kbps': burstDownKbps,
        'burst_up_kbps': burstUpKbps,
        'burst_threshold_kbps': burstThresholdKbps,
        'burst_time_sec': burstTimeSec,
        'nightly_unlimited_enabled': nightlyUnlimitedEnabled,
        'concurrent_sessions': concurrentSessions,
        'address_pool': addressPool,
        'framed_pool': framedPool,
        'vlan_id': vlanId,
        'ipv6_pool': ipv6Pool,
        'bind_mac': bindMac,
        'bind_ip': bindIp,
        'allowed_days': allowedDays,
        'allowed_hours_from': allowedHoursFrom,
        'allowed_hours_to': allowedHoursTo,
        'price': price,
        'price_card': priceCard,
        'price_bulk': priceBulk,
        'currency': currency,
        'plan_tier': planTier,
        'prepaid': prepaid,
        'auto_renew': autoRenew,
        'single_use_once': singleUseOnce,
        'max_consumption_times': maxConsumptionTimes,
        'ticket_validity_days': ticketValidityDays,
        'working_hours_limit': workingHoursLimit,
        'hotspot_enabled': hotspotEnabled,
        'ppp_enabled': pppEnabled,
        'loan_enabled': loanEnabled,
        'max_loan_minutes': maxLoanMinutes,
        'speed_override_allowed': speedOverrideAllowed,
        'allowed_devices_count': allowedDevicesCount,
        'force_mac_address': forceMacAddress,
        'offer_hours_from': offerHoursFrom,
        'offer_hours_to': offerHoursTo,
        'metadata': metadata,
      };

  static int? _int(Object? v) =>
      v == null ? null : (v is int ? v : int.tryParse(v.toString()));

  static num? _num(Object? v) {
    if (v == null) return null;
    if (v is num) return v;
    return num.tryParse(v.toString());
  }

  static List<String> _strList(Object? v) {
    if (v == null) return const [];
    if (v is List) return v.map((e) => e.toString()).toList();
    if (v is String && v.isNotEmpty) return v.split(',').map((e) => e.trim()).toList();
    return const [];
  }

  static DateTime? _dt(Object? v) {
    if (v == null) return null;
    try {
      return DateTime.parse(v.toString().replaceAll('Z', ''));
    } catch (_) {
      return null;
    }
  }

  Plan copyWith({
    int? id,
    String? name,
    String? code,
    String? planType,
    String? serviceType,
    String? description,
    String? color,
    bool? enabled,
    int? priority,
    int? durationMinutes,
    int? validityDays,
    int? maxDailyMinutes,
    int? maxWeeklyMinutes,
    int? maxMonthlyMinutes,
    int? sessionTimeoutSec,
    int? idleTimeoutSec,
    int? quotaTotalMb,
    int? quotaDailyMb,
    int? quotaMonthlyMb,
    String? quotaResetStrategy,
    int? dailyDownloadQuotaMb,
    int? dailyUploadQuotaMb,
    int? dailyCombinedQuotaMb,
    int? monthlyDownloadQuotaMb,
    int? monthlyUploadQuotaMb,
    int? monthlyCombinedQuotaMb,
    int? speedDownKbps,
    int? speedUpKbps,
    bool? speedControlEnabled,
    int? cirDownKbps,
    int? cirUpKbps,
    bool? burstEnabled,
    int? burstDownKbps,
    int? burstUpKbps,
    int? burstThresholdKbps,
    int? burstTimeSec,
    bool? nightlyUnlimitedEnabled,
    int? concurrentSessions,
    String? addressPool,
    String? framedPool,
    int? vlanId,
    String? ipv6Pool,
    bool? bindMac,
    bool? bindIp,
    List<String>? allowedDays,
    String? allowedHoursFrom,
    String? allowedHoursTo,
    num? price,
    num? priceCard,
    num? priceBulk,
    String? currency,
    String? planTier,
    bool? prepaid,
    bool? autoRenew,
    bool? singleUseOnce,
    int? maxConsumptionTimes,
    int? ticketValidityDays,
    int? workingHoursLimit,
    bool? hotspotEnabled,
    bool? pppEnabled,
    bool? loanEnabled,
    int? maxLoanMinutes,
    bool? speedOverrideAllowed,
    int? allowedDevicesCount,
    bool? forceMacAddress,
    String? offerHoursFrom,
    String? offerHoursTo,
    Map<String, dynamic>? metadata,
  }) => Plan(
        id: id ?? this.id,
        name: name ?? this.name,
        code: code ?? this.code,
        planType: planType ?? this.planType,
        serviceType: serviceType ?? this.serviceType,
        description: description ?? this.description,
        color: color ?? this.color,
        enabled: enabled ?? this.enabled,
        priority: priority ?? this.priority,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        validityDays: validityDays ?? this.validityDays,
        maxDailyMinutes: maxDailyMinutes ?? this.maxDailyMinutes,
        maxWeeklyMinutes: maxWeeklyMinutes ?? this.maxWeeklyMinutes,
        maxMonthlyMinutes: maxMonthlyMinutes ?? this.maxMonthlyMinutes,
        sessionTimeoutSec: sessionTimeoutSec ?? this.sessionTimeoutSec,
        idleTimeoutSec: idleTimeoutSec ?? this.idleTimeoutSec,
        quotaTotalMb: quotaTotalMb ?? this.quotaTotalMb,
        quotaDailyMb: quotaDailyMb ?? this.quotaDailyMb,
        quotaMonthlyMb: quotaMonthlyMb ?? this.quotaMonthlyMb,
        quotaResetStrategy: quotaResetStrategy ?? this.quotaResetStrategy,
        dailyDownloadQuotaMb: dailyDownloadQuotaMb ?? this.dailyDownloadQuotaMb,
        dailyUploadQuotaMb: dailyUploadQuotaMb ?? this.dailyUploadQuotaMb,
        dailyCombinedQuotaMb: dailyCombinedQuotaMb ?? this.dailyCombinedQuotaMb,
        monthlyDownloadQuotaMb:
            monthlyDownloadQuotaMb ?? this.monthlyDownloadQuotaMb,
        monthlyUploadQuotaMb: monthlyUploadQuotaMb ?? this.monthlyUploadQuotaMb,
        monthlyCombinedQuotaMb:
            monthlyCombinedQuotaMb ?? this.monthlyCombinedQuotaMb,
        speedDownKbps: speedDownKbps ?? this.speedDownKbps,
        speedUpKbps: speedUpKbps ?? this.speedUpKbps,
        speedControlEnabled: speedControlEnabled ?? this.speedControlEnabled,
        cirDownKbps: cirDownKbps ?? this.cirDownKbps,
        cirUpKbps: cirUpKbps ?? this.cirUpKbps,
        burstEnabled: burstEnabled ?? this.burstEnabled,
        burstDownKbps: burstDownKbps ?? this.burstDownKbps,
        burstUpKbps: burstUpKbps ?? this.burstUpKbps,
        burstThresholdKbps: burstThresholdKbps ?? this.burstThresholdKbps,
        burstTimeSec: burstTimeSec ?? this.burstTimeSec,
        nightlyUnlimitedEnabled: nightlyUnlimitedEnabled ?? this.nightlyUnlimitedEnabled,
        concurrentSessions: concurrentSessions ?? this.concurrentSessions,
        addressPool: addressPool ?? this.addressPool,
        framedPool: framedPool ?? this.framedPool,
        vlanId: vlanId ?? this.vlanId,
        ipv6Pool: ipv6Pool ?? this.ipv6Pool,
        bindMac: bindMac ?? this.bindMac,
        bindIp: bindIp ?? this.bindIp,
        allowedDays: allowedDays ?? this.allowedDays,
        allowedHoursFrom: allowedHoursFrom ?? this.allowedHoursFrom,
        allowedHoursTo: allowedHoursTo ?? this.allowedHoursTo,
        price: price ?? this.price,
        priceCard: priceCard ?? this.priceCard,
        priceBulk: priceBulk ?? this.priceBulk,
        currency: currency ?? this.currency,
        planTier: planTier ?? this.planTier,
        prepaid: prepaid ?? this.prepaid,
        autoRenew: autoRenew ?? this.autoRenew,
        singleUseOnce: singleUseOnce ?? this.singleUseOnce,
        maxConsumptionTimes: maxConsumptionTimes ?? this.maxConsumptionTimes,
        ticketValidityDays: ticketValidityDays ?? this.ticketValidityDays,
        workingHoursLimit: workingHoursLimit ?? this.workingHoursLimit,
        hotspotEnabled: hotspotEnabled ?? this.hotspotEnabled,
        pppEnabled: pppEnabled ?? this.pppEnabled,
        loanEnabled: loanEnabled ?? this.loanEnabled,
        maxLoanMinutes: maxLoanMinutes ?? this.maxLoanMinutes,
        speedOverrideAllowed: speedOverrideAllowed ?? this.speedOverrideAllowed,
        allowedDevicesCount: allowedDevicesCount ?? this.allowedDevicesCount,
        forceMacAddress: forceMacAddress ?? this.forceMacAddress,
        offerHoursFrom: offerHoursFrom ?? this.offerHoursFrom,
        offerHoursTo: offerHoursTo ?? this.offerHoursTo,
        metadata: metadata ?? this.metadata,
      );
}
