import 'dart:convert';

class Plan {
  Plan({
    this.id,
    required this.name,
    this.planType = 'time',
    this.serviceType = 'hotspot',
    this.priceMonthly = 0,
    this.priceYearly = 0,
    this.validityDays,
    this.totalQuotaMb,
    this.totalTimeSeconds,
    // — speed —
    this.downloadKbps,
    this.uploadKbps,
    this.cirDownloadKbps,
    this.cirUploadKbps,
    this.burstDownloadKbps,
    this.burstUploadKbps,
    this.burstThresholdDown,
    this.burstThresholdUp,
    this.burstTime,
    // — meta groups —
    this.mtProfile = '',
    this.mtIpPool = '',
    this.mtRateLimit = '',
    this.notifyOnExpire = false,
    this.notifyOnQuota = false,
    this.workingDays = const <String>[],
    this.allowedHours = '',
    this.autoRenew = false,
    this.notes = '',
    this.tags = const <String>[],
  });

  final int? id;
  final String name;
  final String planType;
  final String serviceType;
  final double priceMonthly;
  final double priceYearly;
  final int? validityDays;
  final int? totalQuotaMb;
  final int? totalTimeSeconds;

  final int? downloadKbps;
  final int? uploadKbps;
  final int? cirDownloadKbps;
  final int? cirUploadKbps;
  final int? burstDownloadKbps;
  final int? burstUploadKbps;
  final int? burstThresholdDown;
  final int? burstThresholdUp;
  final int? burstTime;

  final String mtProfile;
  final String mtIpPool;
  final String mtRateLimit;
  final bool notifyOnExpire;
  final bool notifyOnQuota;
  final List<String> workingDays;
  final String allowedHours;
  final bool autoRenew;
  final String notes;
  final List<String> tags;

  factory Plan.fromJson(Map<String, dynamic> j) {
    final meta = _decodeMeta(j['metadata']);
    final mt = (meta['mikrotik'] ?? {}) as Map<String, dynamic>;
    final notif = (meta['notifications'] ?? {}) as Map<String, dynamic>;
    final adv = (meta['advanced'] ?? {}) as Map<String, dynamic>;
    final sub = (meta['subscription'] ?? {}) as Map<String, dynamic>;
    final gen = (meta['general'] ?? {}) as Map<String, dynamic>;
    return Plan(
      id: j['id'] as int?,
      name: (j['name'] ?? '').toString(),
      planType: (j['plan_type'] ?? 'time').toString(),
      serviceType: (j['service_type'] ?? 'hotspot').toString(),
      priceMonthly: _dbl(j['price_monthly']) ?? 0,
      priceYearly: _dbl(j['price_yearly']) ?? 0,
      validityDays: _int(j['validity_days']),
      totalQuotaMb: _int(j['total_quota_mb']),
      totalTimeSeconds: _int(j['total_time_seconds']),
      downloadKbps: _int(j['download_kbps']),
      uploadKbps: _int(j['upload_kbps']),
      cirDownloadKbps: _int(j['cir_download_kbps']),
      cirUploadKbps: _int(j['cir_upload_kbps']),
      burstDownloadKbps: _int(j['burst_download_kbps']),
      burstUploadKbps: _int(j['burst_upload_kbps']),
      burstThresholdDown: _int(j['burst_threshold_down']),
      burstThresholdUp: _int(j['burst_threshold_up']),
      burstTime: _int(j['burst_time']),
      mtProfile: (mt['profile'] ?? '').toString(),
      mtIpPool: (mt['ip_pool'] ?? '').toString(),
      mtRateLimit: (mt['rate_limit'] ?? '').toString(),
      notifyOnExpire: notif['on_expire'] == true,
      notifyOnQuota: notif['on_quota'] == true,
      workingDays: _strList(adv['working_days']),
      allowedHours: (adv['allowed_hours'] ?? '').toString(),
      autoRenew: sub['auto_renew'] == true,
      notes: (gen['notes'] ?? '').toString(),
      tags: _strList(gen['tags']),
    );
  }

  Map<String, dynamic> toBody() => {
        'name': name,
        'plan_type': planType,
        'service_type': serviceType,
        'price_monthly': priceMonthly,
        'price_yearly': priceYearly,
        if (validityDays != null) 'validity_days': validityDays,
        if (totalQuotaMb != null) 'total_quota_mb': totalQuotaMb,
        if (totalTimeSeconds != null) 'total_time_seconds': totalTimeSeconds,
        if (downloadKbps != null) 'download_kbps': downloadKbps,
        if (uploadKbps != null) 'upload_kbps': uploadKbps,
        if (cirDownloadKbps != null) 'cir_download_kbps': cirDownloadKbps,
        if (cirUploadKbps != null) 'cir_upload_kbps': cirUploadKbps,
        if (burstDownloadKbps != null) 'burst_download_kbps': burstDownloadKbps,
        if (burstUploadKbps != null) 'burst_upload_kbps': burstUploadKbps,
        if (burstThresholdDown != null) 'burst_threshold_down': burstThresholdDown,
        if (burstThresholdUp != null) 'burst_threshold_up': burstThresholdUp,
        if (burstTime != null) 'burst_time': burstTime,
        'metadata': jsonEncode({
          'mikrotik': {
            'profile': mtProfile,
            'ip_pool': mtIpPool,
            'rate_limit': mtRateLimit,
          },
          'notifications': {
            'on_expire': notifyOnExpire,
            'on_quota': notifyOnQuota,
          },
          'advanced': {
            'working_days': workingDays,
            'allowed_hours': allowedHours,
          },
          'subscription': {
            'auto_renew': autoRenew,
          },
          'general': {
            'notes': notes,
            'tags': tags,
          },
        }),
      };

  static int? _int(Object? v) =>
      v == null ? null : (v is int ? v : int.tryParse(v.toString()));

  static double? _dbl(Object? v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static List<String> _strList(Object? v) {
    if (v == null) return const [];
    if (v is List) return v.map((e) => e.toString()).toList();
    return const [];
  }

  static Map<String, dynamic> _decodeMeta(Object? raw) {
    if (raw == null) return {};
    if (raw is Map<String, dynamic>) return raw;
    if (raw is String && raw.isNotEmpty) {
      try {
        final j = jsonDecode(raw);
        return j is Map<String, dynamic> ? j : {};
      } catch (_) {}
    }
    return {};
  }

  Plan copyWith({
    int? id,
    String? name,
    String? planType,
    String? serviceType,
    double? priceMonthly,
    double? priceYearly,
    int? validityDays,
    int? totalQuotaMb,
    int? totalTimeSeconds,
    int? downloadKbps,
    int? uploadKbps,
    int? cirDownloadKbps,
    int? cirUploadKbps,
    int? burstDownloadKbps,
    int? burstUploadKbps,
    int? burstThresholdDown,
    int? burstThresholdUp,
    int? burstTime,
    String? mtProfile,
    String? mtIpPool,
    String? mtRateLimit,
    bool? notifyOnExpire,
    bool? notifyOnQuota,
    List<String>? workingDays,
    String? allowedHours,
    bool? autoRenew,
    String? notes,
    List<String>? tags,
  }) => Plan(
        id: id ?? this.id,
        name: name ?? this.name,
        planType: planType ?? this.planType,
        serviceType: serviceType ?? this.serviceType,
        priceMonthly: priceMonthly ?? this.priceMonthly,
        priceYearly: priceYearly ?? this.priceYearly,
        validityDays: validityDays ?? this.validityDays,
        totalQuotaMb: totalQuotaMb ?? this.totalQuotaMb,
        totalTimeSeconds: totalTimeSeconds ?? this.totalTimeSeconds,
        downloadKbps: downloadKbps ?? this.downloadKbps,
        uploadKbps: uploadKbps ?? this.uploadKbps,
        cirDownloadKbps: cirDownloadKbps ?? this.cirDownloadKbps,
        cirUploadKbps: cirUploadKbps ?? this.cirUploadKbps,
        burstDownloadKbps: burstDownloadKbps ?? this.burstDownloadKbps,
        burstUploadKbps: burstUploadKbps ?? this.burstUploadKbps,
        burstThresholdDown: burstThresholdDown ?? this.burstThresholdDown,
        burstThresholdUp: burstThresholdUp ?? this.burstThresholdUp,
        burstTime: burstTime ?? this.burstTime,
        mtProfile: mtProfile ?? this.mtProfile,
        mtIpPool: mtIpPool ?? this.mtIpPool,
        mtRateLimit: mtRateLimit ?? this.mtRateLimit,
        notifyOnExpire: notifyOnExpire ?? this.notifyOnExpire,
        notifyOnQuota: notifyOnQuota ?? this.notifyOnQuota,
        workingDays: workingDays ?? this.workingDays,
        allowedHours: allowedHours ?? this.allowedHours,
        autoRenew: autoRenew ?? this.autoRenew,
        notes: notes ?? this.notes,
        tags: tags ?? this.tags,
      );
}
