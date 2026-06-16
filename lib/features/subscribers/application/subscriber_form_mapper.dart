import 'package:flutter/material.dart';

import '../domain/subscriber_model.dart';

/// Form-state container for selections the form does not track in text
/// controllers (dropdowns + toggles + the expiry date + the working
/// days set).
class SubscriberFormSelections {
  const SubscriberFormSelections({
    required this.status,
    required this.userType,
    required this.serviceType,
    required this.accountType,
    required this.managerId,
    required this.mtService,
    required this.subscriptionType,
    required this.expireAt,
    required this.workingDays,
    required this.disableOnFirstUse,
    required this.notifyOnLogin,
    required this.autoRenew,
    required this.bandwidthControlEnabled,
    required this.customSpeed,
    required this.temporarySpeed,
    required this.quotaLimitEnabled,
    required this.connectionTimeLimitEnabled,
    required this.equalShareDownload,
    required this.equalShareUpload,
  });

  final String status;
  final String userType;
  final String serviceType;
  final String accountType;
  final int? managerId;
  final String mtService;
  final String subscriptionType;
  final DateTime? expireAt;
  final Set<String> workingDays;
  final bool disableOnFirstUse;
  final bool notifyOnLogin;
  final bool autoRenew;
  final bool bandwidthControlEnabled;
  final bool customSpeed;
  final bool temporarySpeed;
  final bool quotaLimitEnabled;
  final bool connectionTimeLimitEnabled;
  final bool equalShareDownload;
  final bool equalShareUpload;
}

/// Pours a server-returned [Subscriber] into the form's text
/// controllers. The matching selections (status / dropdowns / toggles)
/// are returned by [selectionsFromSubscriber] so the screen can
/// `setState` once with the full state restored.
void applySubscriberToForm(
  Subscriber s,
  Map<String, TextEditingController> c,
) {
  c['username']!.text = s.username;
  c['full_name']!.text = s.fullName;
  c['mobile']!.text = s.mobile;
  c['email']!.text = s.email;
  c['beneficiary_ref']!.text = s.beneficiaryRef;
  c['remark']!.text = s.remark;
  c['mac_lock']!.text = s.macLock;
  c['static_ip']!.text = s.staticIp;
  c['plan_id']!.text = s.planId?.toString() ?? '';
  c['custom_price']!.text = s.customPrice > 0 ? _moneyInput(s.customPrice) : '';
  c['balance']!.text = s.balance != 0 ? _moneyInput(s.balance) : '';
  // management / personal
  c['group']!.text = s.group;
  c['pool']!.text = s.pool;
  c['father_name']!.text = s.fatherName;
  c['national_id']!.text = s.nationalId;
  c['nationality']!.text = s.nationality;
  c['country']!.text = s.country;
  c['address']!.text = s.address;
  c['city']!.text = s.city;
  c['district']!.text = s.district;
  c['state']!.text = s.state;
  c['zip']!.text = s.zip;
  c['coordinates']!.text = s.coordinates;
  c['payment_method']!.text = s.paymentMethod;
  c['payment_reference']!.text = s.paymentReference;
  // speed
  c['download_speed_kbps']!.text =
      s.downloadSpeedKbps > 0 ? s.downloadSpeedKbps.toString() : '';
  c['upload_speed_kbps']!.text =
      s.uploadSpeedKbps > 0 ? s.uploadSpeedKbps.toString() : '';
  // quota / time
  c['combined_quota_mb']!.text =
      s.combinedQuotaMb > 0 ? s.combinedQuotaMb.toString() : '';
  c['download_quota_mb']!.text =
      s.downloadQuotaMb > 0 ? s.downloadQuotaMb.toString() : '';
  c['upload_quota_mb']!.text =
      s.uploadQuotaMb > 0 ? s.uploadQuotaMb.toString() : '';
  c['total_connection_time_min']!.text =
      s.totalConnectionTimeMin > 0 ? s.totalConnectionTimeMin.toString() : '';
  c['daily_connection_time_min']!.text =
      s.dailyConnectionTimeMin > 0 ? s.dailyConnectionTimeMin.toString() : '';
  // network
  c['vlan_id']!.text = s.vlanId > 0 ? s.vlanId.toString() : '';
  c['device_count']!.text = s.deviceCount > 0 ? s.deviceCount.toString() : '';
  c['allowed_macs']!.text = s.allowedMacs;
  c['device_connection_file']!.text = s.deviceConnectionFile;
  // pppoe
  c['pppoe_username']!.text = s.pppoeUsername;
  c['pppoe_ip']!.text = s.pppoeIp;
  // mikrotik / radius / advanced / notifications / subscription / general
  c['mt_profile']!.text = s.mtProfile;
  c['mt_rate_limit']!.text = s.mtRateLimit;
  c['mt_ip_pool']!.text = s.mtIpPool;
  c['mt_comment']!.text = s.mtComment;
  c['dns1']!.text = s.primaryDnsPpp;
  c['dns2']!.text = s.secondaryDnsPpp;
  c['simultaneous_use']!.text = s.overrideConcurrent.toString();
  c['session_timeout']!.text = s.sessionTimeout?.toString() ?? '';
  c['idle_timeout']!.text = s.idleTimeout?.toString() ?? '';
  c['called_station_id']!.text = s.calledStationId;
  c['allowed_hours']!.text = s.allowedHours;
  c['notify_email']!.text = s.notifyEmail;
  c['notify_mobile']!.text = s.notifyMobile;
  c['subscription_days']!.text = s.subscriptionDays?.toString() ?? '';
  c['notes']!.text = s.notes;
  c['tags']!.text = s.tags.join(', ');
}

SubscriberFormSelections selectionsFromSubscriber(Subscriber s) =>
    SubscriberFormSelections(
      status: s.status,
      userType: s.userType,
      serviceType: s.serviceType,
      accountType: s.accountType.isEmpty ? 'Personal' : s.accountType,
      managerId: s.managerId,
      mtService: s.mtService,
      subscriptionType: s.subscriptionType,
      expireAt: s.expireAt,
      workingDays: Set<String>.from(s.workingDays),
      disableOnFirstUse: s.disableOnFirstUse,
      notifyOnLogin: s.notifyOnLogin,
      autoRenew: s.autoRenewal,
      bandwidthControlEnabled: s.bandwidthControlEnabled,
      customSpeed: s.customSpeed,
      temporarySpeed: s.temporarySpeed,
      quotaLimitEnabled: s.quotaLimitEnabled,
      connectionTimeLimitEnabled: s.connectionTimeLimitEnabled,
      equalShareDownload: s.equalShareDownload,
      equalShareUpload: s.equalShareUpload,
    );

/// Builds a [Subscriber] from the form's controllers + selections.
Subscriber buildSubscriberFromForm(
  Map<String, TextEditingController> c,
  SubscriberFormSelections sel,
) =>
    Subscriber(
      username: c['username']!.text.trim(),
      password: c['password']!.text,
      fullName: c['full_name']!.text.trim(),
      mobile: c['mobile']!.text.trim(),
      email: c['email']!.text.trim(),
      beneficiaryRef: c['beneficiary_ref']!.text.trim(),
      planId: int.tryParse(c['plan_id']!.text.trim()),
      customPrice: _parseMoney(c['custom_price']!.text),
      balance: _parseMoney(c['balance']!.text),
      status: sel.status,
      userType: sel.userType,
      serviceType: sel.serviceType,
      accountType: sel.accountType,
      managerId: sel.managerId,
      group: c['group']!.text.trim(),
      pool: c['pool']!.text.trim(),
      fatherName: c['father_name']!.text.trim(),
      nationalId: c['national_id']!.text.trim(),
      nationality: c['nationality']!.text.trim(),
      country: c['country']!.text.trim(),
      address: c['address']!.text.trim(),
      city: c['city']!.text.trim(),
      district: c['district']!.text.trim(),
      state: c['state']!.text.trim(),
      zip: c['zip']!.text.trim(),
      coordinates: c['coordinates']!.text.trim(),
      paymentMethod: c['payment_method']!.text.trim(),
      paymentReference: c['payment_reference']!.text.trim(),
      expireAt: sel.expireAt,
      macLock: c['mac_lock']!.text.trim(),
      staticIp: c['static_ip']!.text.trim(),
      remark: c['remark']!.text.trim(),
      primaryDnsPpp: c['dns1']!.text.trim(),
      secondaryDnsPpp: c['dns2']!.text.trim(),
      overrideConcurrent: int.tryParse(c['simultaneous_use']!.text.trim()) ?? 0,
      vlanId: int.tryParse(c['vlan_id']!.text.trim()) ?? 0,
      deviceCount: int.tryParse(c['device_count']!.text.trim()) ?? 1,
      allowedMacs: c['allowed_macs']!.text.trim(),
      deviceConnectionFile: c['device_connection_file']!.text.trim(),
      bandwidthControlEnabled: sel.bandwidthControlEnabled,
      downloadSpeedKbps: int.tryParse(c['download_speed_kbps']!.text.trim()) ?? 0,
      uploadSpeedKbps: int.tryParse(c['upload_speed_kbps']!.text.trim()) ?? 0,
      customSpeed: sel.customSpeed,
      temporarySpeed: sel.temporarySpeed,
      combinedQuotaMb: int.tryParse(c['combined_quota_mb']!.text.trim()) ?? 0,
      downloadQuotaMb: int.tryParse(c['download_quota_mb']!.text.trim()) ?? 0,
      uploadQuotaMb: int.tryParse(c['upload_quota_mb']!.text.trim()) ?? 0,
      totalConnectionTimeMin:
          int.tryParse(c['total_connection_time_min']!.text.trim()) ?? 0,
      dailyConnectionTimeMin:
          int.tryParse(c['daily_connection_time_min']!.text.trim()) ?? 0,
      quotaLimitEnabled: sel.quotaLimitEnabled,
      connectionTimeLimitEnabled: sel.connectionTimeLimitEnabled,
      equalShareDownload: sel.equalShareDownload,
      equalShareUpload: sel.equalShareUpload,
      pppoeUsername: c['pppoe_username']!.text.trim(),
      pppoePassword: c['pppoe_password']!.text,
      pppoeIp: c['pppoe_ip']!.text.trim(),
      workingDaysCsv: sel.workingDays.join(','),
      autoRenewal: sel.autoRenew,
      mtProfile: c['mt_profile']!.text.trim(),
      mtService: sel.mtService,
      mtRateLimit: c['mt_rate_limit']!.text.trim(),
      mtIpPool: c['mt_ip_pool']!.text.trim(),
      mtComment: c['mt_comment']!.text.trim(),
      sessionTimeout: int.tryParse(c['session_timeout']!.text.trim()),
      idleTimeout: int.tryParse(c['idle_timeout']!.text.trim()),
      calledStationId: c['called_station_id']!.text.trim(),
      allowedHours: c['allowed_hours']!.text.trim(),
      disableOnFirstUse: sel.disableOnFirstUse,
      notifyOnLogin: sel.notifyOnLogin,
      notifyEmail: c['notify_email']!.text.trim(),
      notifyMobile: c['notify_mobile']!.text.trim(),
      subscriptionType: sel.subscriptionType,
      subscriptionDays: int.tryParse(c['subscription_days']!.text.trim()),
      notes: c['notes']!.text.trim(),
      tags: c['tags']!
          .text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
    );

double _parseMoney(String value) {
  final normalized = value.trim().replaceAll(',', '.');
  if (normalized.isEmpty) return 0;
  final parsed = double.tryParse(normalized);
  if (parsed == null) return 0;
  return parsed;
}

String _moneyInput(double value) {
  if (value == value.truncateToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(2);
}
