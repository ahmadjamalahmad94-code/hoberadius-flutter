import 'package:hoberadius_app/core/format/money_limits.dart';
import 'package:hoberadius_app/core/format/number_input.dart';
import 'package:hoberadius_app/core/format/currency.dart';
import 'package:flutter/material.dart';

import '../../../shared/widgets/wheel_picker_fields.dart';
import '../domain/plan_model.dart';

/// Non-text-field selections that the form tracks separately from the
/// `TextEditingController` map.
class PlanFormSelections {
  const PlanFormSelections({
    required this.planType,
    required this.serviceType,
    required this.enabled,
    required this.autoRenew,
    required this.speedControl,
    required this.burstEnabled,
    required this.nightlyUnlimited,
    required this.hotspotEnabled,
    required this.pppEnabled,
    required this.bindMac,
    required this.bindIp,
    required this.singleUseOnce,
    required this.prepaid,
    required this.planTier,
    required this.allowedDays,
    required this.loanEnabled,
    required this.speedOverrideAllowed,
    required this.forceMacAddress,
  });

  final String planType;
  final String serviceType;
  final bool enabled;
  final bool autoRenew;
  final bool speedControl;
  final bool burstEnabled;
  final bool nightlyUnlimited;
  final bool hotspotEnabled;
  final bool pppEnabled;
  final bool bindMac;
  final bool bindIp;
  final bool singleUseOnce;
  final bool prepaid;
  final String planTier;
  final Set<String> allowedDays;
  final bool loanEnabled;
  final bool speedOverrideAllowed;
  final bool forceMacAddress;
}

void applyPlanToForm(Plan p, Map<String, TextEditingController> c) {
  c['name']!.text = p.name;
  c['code']!.text = p.code;
  c['description']!.text = p.description;
  c['color']!.text = p.color;
  c['priority']!.text = p.priority.toString();
  c['validity_days']!.text = p.validityDays.toString();
  c['duration_minutes']!.text = p.durationMinutes.toString();
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
  c['allowed_hours_from']!.text = p.allowedHoursFrom;
  c['allowed_hours_to']!.text = p.allowedHoursTo;
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
      hotspotEnabled: p.hotspotEnabled,
      pppEnabled: p.pppEnabled,
      bindMac: p.bindMac,
      bindIp: p.bindIp,
      singleUseOnce: p.singleUseOnce,
      prepaid: p.prepaid,
      planTier: p.planTier,
      allowedDays: Set<String>.from(
        p.allowedDays.isEmpty ? wheelDayKeys : p.allowedDays,
      ),
      loanEnabled: p.loanEnabled,
      speedOverrideAllowed: p.speedOverrideAllowed,
      forceMacAddress: p.forceMacAddress,
    );

/// Every numeric field of the plan form with its Arabic label: whole
/// numbers except the price. Checked before saving — a collapsed section's
/// field is not validated by the Form, and «٩», «7.5» or «abc» used to be
/// saved as 0 (r04 N2 / r11 M-3: a free plan with no duration).
const Map<String, String> kPlanNumberFields = {
  'price': 'السعر',
  'priority': 'الأولوية',
  'duration_minutes': 'مدّة الاتصال (د)',
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
  'cir_down_kbps': 'CIR تنزيل',
  'cir_up_kbps': 'CIR رفع',
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
    final err = validateNumberInput(
      ctrl.text,
      required: false,
      decimal: e.key == 'price',
      max: e.key == 'price' ? kMaxMoneyAmount : null,
    );
    if (err != null) return '${e.value}: $err';
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
    priority: parseInt('priority'),
    durationMinutes: parseInt('duration_minutes'),
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
    allowedDays:
        sel.allowedDays.isEmpty ? wheelDayKeys : sel.allowedDays.toList(),
    allowedHoursFrom: parseStr('allowed_hours_from'),
    allowedHoursTo: parseStr('allowed_hours_to'),
    price: parseNum('price'),
    currency:
        parseStr('currency').isEmpty ? kDefaultCurrency : parseStr('currency'),
    planTier: sel.planTier,
    prepaid: sel.prepaid,
    autoRenew: sel.autoRenew,
    singleUseOnce: sel.singleUseOnce,
    hotspotEnabled: sel.hotspotEnabled,
    pppEnabled: sel.pppEnabled,
    bindMac: sel.bindMac,
    bindIp: sel.bindIp,
    loanEnabled: sel.loanEnabled,
    maxLoanMinutes: parseInt('max_loan_minutes'),
    speedOverrideAllowed: sel.speedOverrideAllowed,
    allowedDevicesCount: parseInt('allowed_devices_count'),
    forceMacAddress: sel.forceMacAddress,
  );
}
