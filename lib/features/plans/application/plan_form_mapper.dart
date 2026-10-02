import 'package:hoberadius_app/core/format/money_limits.dart';
import 'package:hoberadius_app/core/format/number_input.dart';
import 'package:hoberadius_app/core/format/currency.dart';
import 'package:flutter/material.dart';

import '../domain/plan_model.dart';

/// Non-text-field selections that the form tracks separately from the
/// `TextEditingController` map.
///
/// Not here on purpose (web parity): `hotspot_enabled` / `ppp_enabled` are
/// derived by the server from «نوع الخدمة», and `allowed_days` /
/// `allowed_hours_*` are legacy fallbacks overridden by
/// `connection_schedule` / `offer_hours_*`. The form no longer edits them;
/// [buildPlanFromForm] keeps the loaded plan's values untouched.
class PlanFormSelections {
  const PlanFormSelections({
    required this.planType,
    required this.serviceType,
    required this.enabled,
    required this.autoRenew,
    required this.speedControl,
    required this.burstEnabled,
    required this.nightlyUnlimited,
    required this.bindMac,
    required this.bindIp,
    required this.singleUseOnce,
    required this.prepaid,
    required this.planTier,
    required this.loanEnabled,
    required this.speedOverrideAllowed,
    required this.forceMacAddress,
    this.speedUnlimited = false,
    this.sharedSingleSession = false,
    this.offerHoursFrom = '',
    this.offerHoursTo = '',
    this.connectionSchedule = '',
  });

  final String planType;
  final String serviceType;
  final bool enabled;
  final bool autoRenew;
  final bool speedControl;
  final bool burstEnabled;
  final bool nightlyUnlimited;
  final bool bindMac;
  final bool bindIp;
  final bool singleUseOnce;
  final bool prepaid;
  final String planTier;
  final bool loanEnabled;
  final bool speedOverrideAllowed;
  final bool forceMacAddress;

  /// «بلا حدّ للسرعة».
  final bool speedUnlimited;

  /// «بطاقة مشتركة — جلسة واحدة فعّالة».
  final bool sharedSingleSession;

  /// «ساعات الباقة — من / إلى» as HH:MM; '' = not set (no fake default).
  final String offerHoursFrom;
  final String offerHoursTo;

  /// «أيام وساعات السماح» — access-schedule JSON, '' = none.
  final String connectionSchedule;
}

void applyPlanToForm(Plan p, Map<String, TextEditingController> c) {
  c['name']!.text = p.name;
  c['code']!.text = p.code;
  c['description']!.text = p.description;
  c['color']!.text = p.color;
  c['priority']!.text = p.priority.toString();
  c['validity_days']!.text = p.validityDays.toString();
  c['duration_minutes']!.text = p.durationMinutes.toString();
  c['max_daily_minutes']?.text = p.maxDailyMinutes.toString();
  c['session_timeout_sec']!.text = p.sessionTimeoutSec.toString();
  c['idle_timeout_sec']!.text = p.idleTimeoutSec.toString();
  c['quota_total_mb']!.text = p.quotaTotalMb.toString();
  c['quota_daily_mb']!.text = p.quotaDailyMb.toString();
  c['quota_monthly_mb']!.text = p.quotaMonthlyMb.toString();
  c['daily_download_quota_mb']!.text = p.dailyDownloadQuotaMb.toString();
  c['daily_upload_quota_mb']!.text = p.dailyUploadQuotaMb.toString();
  c['daily_combined_quota_mb']!.text = p.dailyCombinedQuotaMb.toString();
  c['monthly_download_quota_mb']!.text = p.monthlyDownloadQuotaMb.toString();
  c['monthly_upload_quota_mb']!.text = p.monthlyUploadQuotaMb.toString();
  c['monthly_combined_quota_mb']!.text = p.monthlyCombinedQuotaMb.toString();
  c['max_loan_minutes']!.text = p.maxLoanMinutes.toString();
  c['allowed_devices_count']!.text = p.allowedDevicesCount.toString();
  c['speed_down_kbps']!.text = p.speedDownKbps.toString();
  c['speed_up_kbps']!.text = p.speedUpKbps.toString();
  c['cir_down_kbps']!.text = p.cirDownKbps.toString();
  c['cir_up_kbps']!.text = p.cirUpKbps.toString();
  c['burst_down_kbps']!.text = p.burstDownKbps.toString();
  c['burst_up_kbps']!.text = p.burstUpKbps.toString();
  c['burst_threshold_kbps']!.text = p.burstThresholdKbps.toString();
  c['burst_time_sec']!.text = p.burstTimeSec.toString();
  c['concurrent_sessions']!.text = p.concurrentSessions.toString();
  c['address_pool']!.text = p.addressPool;
  c['framed_pool']!.text = p.framedPool;
  c['vlan_id']!.text = p.vlanId.toString();
  c['price']!.text = p.price.toString();
  c['currency']!.text = p.currency;
}

PlanFormSelections selectionsFromPlan(Plan p) => PlanFormSelections(
      planType: p.planType,
      serviceType: p.serviceType,
      enabled: p.enabled,
      autoRenew: p.autoRenew,
      speedControl: p.speedControlEnabled,
      burstEnabled: p.burstEnabled,
      nightlyUnlimited: p.nightlyUnlimitedEnabled,
      bindMac: p.bindMac,
      bindIp: p.bindIp,
      singleUseOnce: p.singleUseOnce,
      prepaid: p.prepaid,
      planTier: p.planTier,
      loanEnabled: p.loanEnabled,
      speedOverrideAllowed: p.speedOverrideAllowed,
      forceMacAddress: p.forceMacAddress,
      speedUnlimited: p.speedUnlimited,
      sharedSingleSession: p.sharedSingleSession,
      offerHoursFrom: p.offerHoursFrom,
      offerHoursTo: p.offerHoursTo,
      connectionSchedule: p.connectionSchedule,
    );

/// Every numeric field of the plan form with its Arabic label: whole
/// numbers except the price. Checked before saving — a collapsed section's
/// field is not validated by the Form, and «٩», «7.5» or «abc» used to be
/// saved as 0 (r04 N2 / r11 M-3: a free plan with no duration).
const Map<String, String> kPlanNumberFields = {
  'price': 'السعر',
  'priority': 'الأولوية',
  'duration_minutes': 'مدة الوقت',
  'max_daily_minutes': 'حد يومي',
  'validity_days': 'الصلاحية (أيام)',
  'session_timeout_sec': 'مهلة الجلسة (ث)',
  'idle_timeout_sec': 'مهلة الخمول (ث)',
  'quota_total_mb': 'الكوتة الإجمالية (MB)',
  'quota_daily_mb': 'الكوتة اليومية (MB)',
  'quota_monthly_mb': 'الكوتة الشهرية (MB)',
  'daily_download_quota_mb': 'تنزيل يومي (MB)',
  'daily_upload_quota_mb': 'رفع يومي (MB)',
  'daily_combined_quota_mb': 'مجمّع يومي (MB)',
  'monthly_download_quota_mb': 'تنزيل شهري (MB)',
  'monthly_upload_quota_mb': 'رفع شهري (MB)',
  'monthly_combined_quota_mb': 'مجمّع شهري (MB)',
  'speed_down_kbps': 'سرعة التنزيل',
  'speed_up_kbps': 'سرعة الرفع',
  'cir_down_kbps': 'سرعة مضمونة CIR للتنزيل',
  'cir_up_kbps': 'سرعة مضمونة CIR للرفع',
  'burst_down_kbps': 'Burst تنزيل',
  'burst_up_kbps': 'Burst رفع',
  'burst_threshold_kbps': 'عتبة Burst',
  'burst_time_sec': 'زمن Burst',
  'concurrent_sessions': 'الجلسات المتزامنة',
  'vlan_id': 'VLAN',
  'max_loan_minutes': 'أقصى سلفة (د)',
  'allowed_devices_count': 'عدد الأجهزة',
};

/// The first invalid numeric field as «الحقل: السبب», or null.
String? planFormNumberError(Map<String, TextEditingController> c) {
  for (final e in kPlanNumberFields.entries) {
    final ctrl = c[e.key];
    if (ctrl == null) continue;
    final priority = e.key == 'priority';
    final err = validateNumberInput(
      ctrl.text,
      required: false,
      decimal: e.key == 'price',
      min: priority ? kMinPlanPriority : null,
      max: e.key == 'price'
          ? kMaxMoneyAmount
          : (priority ? kMaxPlanPriority : null),
      maxMessage: priority ? 'الأولوية من 1 إلى 10.' : null,
    );
    if (err != null) return '${e.value}: $err';
  }
  return null;
}

/// The server's rule (`plans._validate`): a 0 download or upload speed is
/// refused unless «بلا حدّ للسرعة» is on — a silent 0 meant «open» on the
/// router. Checked before saving so the message shows without a round trip.
String? planFormSpeedError(
  Map<String, TextEditingController> c, {
  required bool speedUnlimited,
}) {
  if (speedUnlimited) return null;
  final down = parseIntInput(c['speed_down_kbps']?.text ?? '') ?? 0;
  final up = parseIntInput(c['speed_up_kbps']?.text ?? '') ?? 0;
  if (down == 0 || up == 0) {
    return 'السرعة مطلوبة (تنزيل ورفع) — أو علّم «بلا حدّ للسرعة» صراحةً '
        'إن كانت الباقة مفتوحة.';
  }
  return null;
}

Plan buildPlanFromForm(
  Map<String, TextEditingController> c,
  PlanFormSelections sel, {
  Plan? base,
}) {
  // Strict readers (Arabic-Indic digits and «٫» accepted); the screen
  // refuses the save first when [planFormNumberError] finds a bad value.
  int parseInt(String key) => parseIntInput(c[key]!.text) ?? 0;
  num parseNum(String key) => parseNumberInput(c[key]!.text) ?? 0;
  String parseStr(String key) => c[key]!.text.trim();

  return (base ?? Plan(name: '')).copyWith(
    name: parseStr('name'),
    code: parseStr('code'),
    planType: sel.planType,
    serviceType: sel.serviceType,
    description: parseStr('description'),
    color: parseStr('color'),
    enabled: sel.enabled,
    // Empty = «not chosen» = 5 (the server's default).
    priority: parseIntInput(c['priority']!.text) ?? kDefaultPlanPriority,
    durationMinutes: parseInt('duration_minutes'),
    maxDailyMinutes: c['max_daily_minutes'] == null
        ? null
        : parseInt('max_daily_minutes'),
    validityDays: parseInt('validity_days'),
    sessionTimeoutSec: parseInt('session_timeout_sec'),
    idleTimeoutSec: parseInt('idle_timeout_sec'),
    quotaTotalMb: parseInt('quota_total_mb'),
    quotaDailyMb: parseInt('quota_daily_mb'),
    quotaMonthlyMb: parseInt('quota_monthly_mb'),
    dailyDownloadQuotaMb: parseInt('daily_download_quota_mb'),
    dailyUploadQuotaMb: parseInt('daily_upload_quota_mb'),
    dailyCombinedQuotaMb: parseInt('daily_combined_quota_mb'),
    monthlyDownloadQuotaMb: parseInt('monthly_download_quota_mb'),
    monthlyUploadQuotaMb: parseInt('monthly_upload_quota_mb'),
    monthlyCombinedQuotaMb: parseInt('monthly_combined_quota_mb'),
    speedDownKbps: parseInt('speed_down_kbps'),
    speedUpKbps: parseInt('speed_up_kbps'),
    speedControlEnabled: sel.speedControl,
    speedUnlimited: sel.speedUnlimited,
    cirDownKbps: parseInt('cir_down_kbps'),
    cirUpKbps: parseInt('cir_up_kbps'),
    burstEnabled: sel.burstEnabled,
    burstDownKbps: parseInt('burst_down_kbps'),
    burstUpKbps: parseInt('burst_up_kbps'),
    burstThresholdKbps: parseInt('burst_threshold_kbps'),
    burstTimeSec: parseInt('burst_time_sec'),
    nightlyUnlimitedEnabled: sel.nightlyUnlimited,
    concurrentSessions: parseInt('concurrent_sessions').clamp(1, 1000),
    addressPool: parseStr('address_pool'),
    framedPool: parseStr('framed_pool'),
    vlanId: parseInt('vlan_id'),
    sharedSingleSession: sel.sharedSingleSession,
    offerHoursFrom: sel.offerHoursFrom.trim(),
    offerHoursTo: sel.offerHoursTo.trim(),
    connectionSchedule: sel.connectionSchedule.trim(),
    price: parseNum('price'),
    currency:
        parseStr('currency').isEmpty ? kDefaultCurrency : parseStr('currency'),
    planTier: sel.planTier,
    prepaid: sel.prepaid,
    autoRenew: sel.autoRenew,
    singleUseOnce: sel.singleUseOnce,
    bindMac: sel.bindMac,
    bindIp: sel.bindIp,
    loanEnabled: sel.loanEnabled,
    maxLoanMinutes: parseInt('max_loan_minutes'),
    speedOverrideAllowed: sel.speedOverrideAllowed,
    allowedDevicesCount: parseInt('allowed_devices_count'),
    forceMacAddress: sel.forceMacAddress,
  );
}
