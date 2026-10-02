import 'package:hoberadius_app/core/format/number_input.dart';
import 'package:hoberadius_app/core/format/money_limits.dart';
import 'package:flutter/material.dart';

import '../domain/subscriber_model.dart';

/// Text-controller keys of the subscriber form (one per text field).
const kSubscriberFormControllerKeys = [
  'username',
  'password',
  'full_name',
  'mobile',
  'email',
  'beneficiary_ref',
  'remark',
  'mac_lock',
  'static_ip',
  'plan_id',
  'custom_price',
  'balance',
  'group',
  'pool',
  'father_name',
  'national_id',
  'nationality',
  'country',
  'address',
  'city',
  'district',
  'state',
  'zip',
  'coordinates',
  'payment_method',
  'payment_reference',
  'download_speed_kbps',
  'upload_speed_kbps',
  'combined_quota_mb',
  'download_quota_mb',
  'upload_quota_mb',
  'total_connection_time_min',
  'daily_connection_time_min',
  'vlan_id',
  'device_count',
  'allowed_macs',
  'device_connection_file',
  'pppoe_username',
  'pppoe_password',
  'pppoe_ip',
  'mt_profile',
  'mt_rate_limit',
  'mt_ip_pool',
  'mt_comment',
  'dns1',
  'dns2',
  'simultaneous_use',
  'session_timeout',
  'idle_timeout',
  'called_station_id',
  'allowed_hours',
  'notify_email',
  'notify_mobile',
  'subscription_days',
  'notes',
  'tags',
  // «إعدادات شبكة متقدمة جدًا» (web metadata keys, enforced on login)
  'net_filter_chain',
  'net_address_list',
  'net_framed_route',
  'net_user_group',
  'net_queue_priority',
  'net_framed_pool',
  'net_acct_interim_sec',
  'net_ppp_extra',
];

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
    this.loginWithoutPassword = false,
    this.deviceLimitMode = '',
    this.connectionSchedule = '',
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

  /// «قسم كلمة المرور» معطَّل (login by name only).
  final bool loginWithoutPassword;

  /// «عند بلوغ حدّ الأجهزة»: '' | reject | replace.
  final String deviceLimitMode;

  /// «الأيام والأوقات المسموحة للاتصال» (access-schedule JSON, '' = none).
  final String connectionSchedule;
}

/// Optional controllers (older callers/tests build a smaller set).
String _text(Map<String, TextEditingController> c, String key) =>
    c[key]?.text.trim() ?? '';

void _put(Map<String, TextEditingController> c, String key, String value) {
  final ctrl = c[key];
  if (ctrl != null) ctrl.text = value;
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
  _put(c, 'net_filter_chain', s.netFilterChain);
  _put(c, 'net_address_list', s.netAddressList);
  _put(c, 'net_framed_route', s.netFramedRoute);
  _put(c, 'net_user_group', s.netUserGroup);
  _put(c, 'net_queue_priority', s.netQueuePriority);
  _put(c, 'net_framed_pool', s.netFramedPool);
  _put(c, 'net_acct_interim_sec', s.netAcctInterimSec);
  _put(c, 'net_ppp_extra', s.netPppExtra);
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
      loginWithoutPassword: s.loginWithoutPassword,
      deviceLimitMode: s.deviceLimitMode,
      connectionSchedule: s.connectionSchedule,
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
      overrideConcurrent: parseIntInput(c['simultaneous_use']!.text) ?? 0,
      vlanId: parseIntInput(c['vlan_id']!.text) ?? 0,
      deviceCount: parseIntInput(c['device_count']!.text) ?? 1,
      allowedMacs: c['allowed_macs']!.text.trim(),
      deviceConnectionFile: c['device_connection_file']!.text.trim(),
      bandwidthControlEnabled: sel.bandwidthControlEnabled,
      downloadSpeedKbps: parseIntInput(c['download_speed_kbps']!.text) ?? 0,
      uploadSpeedKbps: parseIntInput(c['upload_speed_kbps']!.text) ?? 0,
      customSpeed: sel.customSpeed,
      temporarySpeed: sel.temporarySpeed,
      combinedQuotaMb: parseIntInput(c['combined_quota_mb']!.text) ?? 0,
      downloadQuotaMb: parseIntInput(c['download_quota_mb']!.text) ?? 0,
      uploadQuotaMb: parseIntInput(c['upload_quota_mb']!.text) ?? 0,
      totalConnectionTimeMin:
          parseIntInput(c['total_connection_time_min']!.text) ?? 0,
      dailyConnectionTimeMin:
          parseIntInput(c['daily_connection_time_min']!.text) ?? 0,
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
      sessionTimeout: parseIntInput(c['session_timeout']!.text),
      idleTimeout: parseIntInput(c['idle_timeout']!.text),
      calledStationId: c['called_station_id']!.text.trim(),
      allowedHours: c['allowed_hours']!.text.trim(),
      disableOnFirstUse: sel.disableOnFirstUse,
      notifyOnLogin: sel.notifyOnLogin,
      notifyEmail: c['notify_email']!.text.trim(),
      notifyMobile: c['notify_mobile']!.text.trim(),
      subscriptionType: sel.subscriptionType,
      subscriptionDays: parseIntInput(c['subscription_days']!.text),
      notes: c['notes']!.text.trim(),
      tags: c['tags']!
          .text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      loginWithoutPassword: sel.loginWithoutPassword,
      deviceLimitMode: sel.deviceLimitMode,
      connectionSchedule: sel.connectionSchedule,
      netFilterChain: _text(c, 'net_filter_chain'),
      netAddressList: _text(c, 'net_address_list'),
      netFramedRoute: _text(c, 'net_framed_route'),
      netUserGroup: _text(c, 'net_user_group'),
      netQueuePriority: _text(c, 'net_queue_priority'),
      netFramedPool: _text(c, 'net_framed_pool'),
      netAcctInterimSec: _text(c, 'net_acct_interim_sec'),
      netPppExtra: c['net_ppp_extra']?.text.trim() ?? '',
    );

double _parseMoney(String value) => parseDecimalInput(value) ?? 0;

/// Numeric fields of the subscriber form (all whole numbers except the
/// money ones) with their Arabic labels — checked before saving, also when
/// their section is collapsed (a bad value used to be saved as 0).
const Map<String, String> kSubscriberNumberFields = {
  'custom_price': 'السعر المخصص',
  'balance': 'الرصيد',
  'simultaneous_use': 'الجلسات المتزامنة',
  'vlan_id': 'VLAN',
  'device_count': 'عدد الأجهزة المسموحة',
  'download_speed_kbps': 'سرعة التنزيل',
  'upload_speed_kbps': 'سرعة الرفع',
  'combined_quota_mb': 'الكوتا المدمجة',
  'download_quota_mb': 'كوتا التنزيل',
  'upload_quota_mb': 'كوتا الرفع',
  'total_connection_time_min': 'إجمالي وقت الاتصال',
  'daily_connection_time_min': 'وقت الاتصال اليومي',
  'session_timeout': 'مهلة الجلسة',
  'idle_timeout': 'مهلة الخمول',
  'subscription_days': 'مدّة الاشتراك',
  'net_queue_priority': 'أولوية طابور السرعة',
  'net_acct_interim_sec': 'فترة تحديث الاستهلاك',
};

/// The first invalid numeric field as «الحقل: السبب», or null.
String? subscriberFormNumberError(Map<String, TextEditingController> c) {
  for (final e in kSubscriberNumberFields.entries) {
    final ctrl = c[e.key];
    if (ctrl == null) continue;
    final money = e.key == 'custom_price' || e.key == 'balance';
    final err = validateNumberInput(
      ctrl.text,
      required: false,
      decimal: money,
      max: money ? kMaxMoneyAmount : null,
    );
    if (err != null) return '${e.value}: $err';
  }
  return null;
}

/// The owner's one-year rule for a set expiry: moving it forward by more
/// than a year in one save is refused (the server says the same). An
/// earlier date, or none, is free.
String? validateExpiryJump({
  required DateTime? original,
  required DateTime? next,
  required DateTime now,
  bool creating = false,
}) {
  if (next == null) return null;
  // A NEW subscriber: the server's create rule and wording.
  if (creating) return validateNewSubscriberExpiry(next, now);
  if (next.year > kMaxExpiryYear) return expiryTooFarMessage;
  if (original != null && next.isAtSameMomentAs(original)) return null;
  final anchor = original != null && original.isAfter(now) ? original : now;
  final minutes = next.difference(anchor).inMinutes;
  return validateExtendSpan(minutes);
}

String _moneyInput(double value) {
  if (value == value.truncateToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(2);
}
