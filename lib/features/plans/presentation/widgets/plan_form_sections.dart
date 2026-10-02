import 'package:hoberadius_app/core/format/money_limits.dart';
import 'package:hoberadius_app/core/format/number_input.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/collapsible_section.dart';
import '../../../../shared/widgets/form_field_row.dart';
import '../../../../shared/widgets/hub_access_schedule.dart';
import '../../../../shared/widgets/hub_switch_row.dart';
import '../../../../shared/widgets/hub_unit_input.dart';
import '../../../../shared/widgets/wheel_picker_fields.dart';

/// Muted hint on a field the server stores but no runtime path reads yet
/// (the owner decides on removal; the value still round-trips).
const String kPlanNotAppliedHint = 'لا يُطبَّق حاليًا';

/// «نوع الخدمة» — exactly the web's three choices (the web's two cards
/// combine to Hotspot / PPPoE / Both).
const List<(String, String)> kPlanServiceTypes = [
  ('Hotspot', 'هوت سبوت'),
  ('PPPoE', 'برودباند'),
  ('Both', 'كلاهما (هوت سبوت + برودباند)'),
];

const Map<String, String> _legacyServiceLabels = {
  'hotspot': 'هوت سبوت',
  'pppoe': 'برودباند',
  'broadband': 'برودباند',
  'both': 'كلاهما',
  'balance': 'رصيد',
  'voucher': 'قسيمة',
  'others': 'أخرى',
};

/// The service-type choices for a plan whose stored value is [current]: the
/// three web values, plus the stored value itself when it is anything else
/// (an old «Balance», a lower-case «both», empty…) labelled «… (قديم)» — so
/// opening a plan never changes it and the dropdown never asserts.
List<(String, String)> planServiceTypeOptions(String current) {
  final options = [...kPlanServiceTypes];
  if (!options.any((o) => o.$1 == current)) {
    final known = _legacyServiceLabels[current.trim().toLowerCase()];
    final label = known ?? (current.trim().isEmpty ? 'غير محدّد' : current);
    options.add((current, '$label (قديم)'));
  }
  return options;
}

/// Short numeric field (durations, quotas, speeds) — usually half of a
/// [FormFieldPair].
Widget _numField(
  Map<String, TextEditingController> controllers,
  String key,
  String label, {
  String? hint,
}) =>
    FormFieldRow(
      label: label,
      hint: hint,
      child: TextFormField(
        controller: controllers[key],
        keyboardType: TextInputType.number,
        inputFormatters: numberFieldFormatters,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: (v) =>
            validateNumberInput(v, required: false, decimal: false),
      ),
    );

/// Number + unit (kbps/Mbps, MB/GB, min/hr/day) like the web's
/// `unit_input`. The controller stays the source of truth: it holds the
/// canonical stored number (kbps / MB / minutes), so `planFormNumberError`
/// and `buildPlanFromForm` read it unchanged.
Widget _unitField(
  Map<String, TextEditingController> controllers,
  String key,
  String label, {
  required HubUnitKind kind,
  required List<String> units,
  String? hint,
  bool enabled = true,
}) {
  final ctrl = controllers[key]!;
  return FormFieldRow(
    label: label,
    hint: hint,
    child: HubUnitInput(
      value: parseIntInput(ctrl.text) ?? 0,
      kind: kind,
      units: units,
      enabled: enabled,
      onChanged: (v) => ctrl.text = '$v',
    ),
  );
}

Widget _speedField(
  Map<String, TextEditingController> c,
  String key,
  String label, {
  String? hint,
  bool enabled = true,
}) =>
    _unitField(
      c,
      key,
      label,
      kind: HubUnitKind.speed,
      units: const ['kbps', 'Mbps'],
      hint: hint,
      enabled: enabled,
    );

Widget _quotaField(
  Map<String, TextEditingController> c,
  String key,
  String label, {
  String? hint,
}) =>
    _unitField(
      c,
      key,
      label,
      kind: HubUnitKind.quota,
      units: const ['MB', 'GB'],
      hint: hint,
    );

/// Label at the start, switch at the end — the one on/off row style.
Widget _switchRow(
  String label,
  bool value,
  ValueChanged<bool> onChanged, {
  String? subtitle,
}) =>
    HubSwitchRow(
      label: label,
      subtitle: subtitle,
      value: value,
      onChanged: onChanged,
      dense: true,
    );

class PlanCoreSection extends StatelessWidget {
  const PlanCoreSection({
    super.key,
    required this.controllers,
    required this.planType,
    required this.serviceType,
    required this.enabled,
    required this.onPlanTypeChanged,
    required this.onServiceTypeChanged,
    required this.onEnabledChanged,
  });

  final Map<String, TextEditingController> controllers;
  final String planType;
  final String serviceType;
  final bool enabled;
  final ValueChanged<String> onPlanTypeChanged;
  final ValueChanged<String> onServiceTypeChanged;
  final ValueChanged<bool> onEnabledChanged;

  @override
  Widget build(BuildContext context) {
    return CollapsibleSection(
      storageKey: 'plan.core',
      icon: Icons.workspace_premium_outlined,
      title: 'البيانات الأساسية',
      child: Column(
        children: [
          FormFieldRow(
            label: 'الاسم',
            required: true,
            child: TextFormField(
              controller: controllers['name'],
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
            ),
          ),
          FormFieldPair(
            first: FormFieldRow(
              label: 'نوع الباقة',
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: planType,
                items: const [
                  DropdownMenuItem(value: 'time', child: Text('وقت')),
                  DropdownMenuItem(value: 'quota', child: Text('حصة')),
                  DropdownMenuItem(value: 'hybrid', child: Text('وقت وحصة')),
                  DropdownMenuItem(
                    value: 'unlimited',
                    child: Text('غير محدود'),
                  ),
                  DropdownMenuItem(value: 'recurring', child: Text('متجدّد')),
                ],
                onChanged: (v) => onPlanTypeChanged(v ?? 'time'),
              ),
            ),
            second: FormFieldRow(
              label: 'نوع الخدمة',
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: serviceType,
                items: [
                  for (final (value, label)
                      in planServiceTypeOptions(serviceType))
                    DropdownMenuItem(value: value, child: Text(label)),
                ],
                onChanged: (v) => onServiceTypeChanged(v ?? serviceType),
              ),
            ),
          ),
          FormFieldPair(
            first: FormFieldRow(
              label: 'الكود',
              hint: 'اختياري',
              child: TextFormField(controller: controllers['code']),
            ),
            second: _numField(
              controllers,
              'priority',
              'الأولوية',
              hint: 'من 1 إلى 10 — الأقل = أعلى أولوية (الافتراضي 5)',
            ),
          ),
          _switchRow('مفعّلة', enabled, onEnabledChanged),
        ],
      ),
    );
  }
}

class PlanTimeSection extends StatelessWidget {
  const PlanTimeSection({super.key, required this.controllers});
  final Map<String, TextEditingController> controllers;

  @override
  Widget build(BuildContext context) {
    return CollapsibleSection(
      storageKey: 'plan.time',
      icon: Icons.timer_outlined,
      title: 'الوقت والصلاحية',
      child: Column(
        children: [
          FormFieldPair(
            first: _numField(controllers, 'validity_days', 'الصلاحية (أيام)'),
            second: _unitField(
              controllers,
              'duration_minutes',
              'مدة الوقت',
              kind: HubUnitKind.time,
              units: const ['min', 'hr', 'day'],
              hint: 'كم من الوقت تمنحه الباقة',
            ),
          ),
          _unitField(
            controllers,
            'max_daily_minutes',
            'حد يومي',
            kind: HubUnitKind.time,
            units: const ['min', 'hr'],
            hint: 'أقصى وقت اتصال مسموح في اليوم — 0 = بلا حد',
          ),
          FormFieldPair(
            first: _numField(
              controllers,
              'session_timeout_sec',
              'مهلة الجلسة (ث)',
            ),
            second: _numField(
              controllers,
              'idle_timeout_sec',
              'مهلة الخمول (ث)',
            ),
          ),
        ],
      ),
    );
  }
}

class PlanQuotaSection extends StatelessWidget {
  const PlanQuotaSection({super.key, required this.controllers});
  final Map<String, TextEditingController> controllers;

  @override
  Widget build(BuildContext context) {
    return CollapsibleSection(
      storageKey: 'plan.quota',
      icon: Icons.data_usage,
      title: 'الحصة',
      initiallyExpanded: false,
      child: Column(
        children: [
          _quotaField(
            controllers,
            'quota_total_mb',
            'كوتا إجمالية',
            hint: '0 = غير محدودة',
          ),
          FormFieldPair(
            first: _quotaField(controllers, 'quota_daily_mb', 'كوتا يومية'),
            second: _quotaField(controllers, 'quota_monthly_mb', 'كوتا شهرية'),
          ),
          const Divider(height: 16),
          FormFieldPair(
            first: _quotaField(
              controllers,
              'daily_download_quota_mb',
              'كوتا تنزيل يومية',
            ),
            second: _quotaField(
              controllers,
              'daily_upload_quota_mb',
              'كوتا رفع يومية',
            ),
          ),
          FormFieldPair(
            first: _quotaField(
              controllers,
              'monthly_download_quota_mb',
              'كوتا تنزيل شهرية',
            ),
            second: _quotaField(
              controllers,
              'monthly_upload_quota_mb',
              'كوتا رفع شهرية',
            ),
          ),
          FormFieldPair(
            first: _quotaField(
              controllers,
              'daily_combined_quota_mb',
              'كوتا يومية مدمجة',
            ),
            second: _quotaField(
              controllers,
              'monthly_combined_quota_mb',
              'كوتا شهرية مدمجة',
            ),
          ),
        ],
      ),
    );
  }
}

class PlanSpeedSection extends StatelessWidget {
  const PlanSpeedSection({
    super.key,
    required this.controllers,
    required this.speedUnlimited,
    required this.onSpeedUnlimitedChanged,
    required this.speedControl,
    required this.onSpeedControlChanged,
    required this.burstEnabled,
    required this.onBurstEnabledChanged,
    required this.nightlyUnlimited,
    required this.onNightlyUnlimitedChanged,
  });

  final Map<String, TextEditingController> controllers;
  final bool speedUnlimited;
  final ValueChanged<bool> onSpeedUnlimitedChanged;
  final bool speedControl;
  final ValueChanged<bool> onSpeedControlChanged;
  final bool burstEnabled;
  final ValueChanged<bool> onBurstEnabledChanged;
  final bool nightlyUnlimited;
  final ValueChanged<bool> onNightlyUnlimitedChanged;

  @override
  Widget build(BuildContext context) {
    Widget dead(String key, String label) =>
        _numField(controllers, key, label, hint: kPlanNotAppliedHint);
    return CollapsibleSection(
      storageKey: 'plan.speed',
      icon: Icons.speed,
      title: 'السرعة والسياسات',
      child: Column(
        children: [
          FormFieldPair(
            first: _speedField(
              controllers,
              'speed_down_kbps',
              'سرعة التنزيل',
              enabled: !speedUnlimited,
            ),
            second: _speedField(
              controllers,
              'speed_up_kbps',
              'سرعة الرفع',
              enabled: !speedUnlimited,
            ),
          ),
          _switchRow(
            'بلا حدّ للسرعة',
            speedUnlimited,
            onSpeedUnlimitedChanged,
            subtitle: 'باقة مفتوحة السرعة. بدونه لا يُقبل صفر في التنزيل '
                'أو الرفع — فالصفر الصامت كان يعني «مفتوح» على الراوتر.',
          ),
          _switchRow(
            'تفعيل التحكم بالسرعة',
            speedControl,
            onSpeedControlChanged,
            subtitle: kPlanNotAppliedHint,
          ),
          FormFieldPair(
            first: _speedField(
              controllers,
              'cir_down_kbps',
              'سرعة مضمونة CIR للتنزيل',
              hint: kPlanNotAppliedHint,
            ),
            second: _speedField(
              controllers,
              'cir_up_kbps',
              'سرعة مضمونة CIR للرفع',
              hint: kPlanNotAppliedHint,
            ),
          ),
          _switchRow(
            'السرعة المؤقتة (Burst)',
            burstEnabled,
            onBurstEnabledChanged,
            subtitle: kPlanNotAppliedHint,
          ),
          FormFieldPair(
            first: dead('burst_down_kbps', 'سرعة Burst التنزيل'),
            second: dead('burst_up_kbps', 'سرعة Burst الرفع'),
          ),
          FormFieldPair(
            first: dead('burst_threshold_kbps', 'حد Burst'),
            second: dead('burst_time_sec', 'مدة Burst (ث)'),
          ),
          _switchRow(
            'غير محدود ليلًا',
            nightlyUnlimited,
            onNightlyUnlimitedChanged,
            subtitle: kPlanNotAppliedHint,
          ),
        ],
      ),
    );
  }
}

class PlanSessionSection extends StatelessWidget {
  const PlanSessionSection({
    super.key,
    required this.controllers,
    required this.bindMac,
    required this.bindIp,
    required this.onBindMacChanged,
    required this.onBindIpChanged,
    required this.sharedSingleSession,
    required this.onSharedSingleSessionChanged,
  });

  final Map<String, TextEditingController> controllers;
  final bool bindMac;
  final bool bindIp;
  final ValueChanged<bool> onBindMacChanged;
  final ValueChanged<bool> onBindIpChanged;
  final bool sharedSingleSession;
  final ValueChanged<bool> onSharedSingleSessionChanged;

  @override
  Widget build(BuildContext context) {
    return CollapsibleSection(
      storageKey: 'plan.session',
      icon: Icons.lan_outlined,
      title: 'الجلسات والشبكة',
      initiallyExpanded: false,
      child: Column(
        children: [
          FormFieldPair(
            first: _numField(
              controllers,
              'concurrent_sessions',
              'الجلسات المتزامنة',
            ),
            second: _numField(
              controllers,
              'vlan_id',
              'معرّف VLAN',
              hint: kPlanNotAppliedHint,
            ),
          ),
          _switchRow(
            'بطاقة مشتركة — جلسة واحدة فعّالة',
            sharedSingleSession,
            onSharedSingleSessionChanged,
            subtitle: 'الدخول الجديد يفصل القديم — لبطاقة يتشاركها زبائن '
                'المحل واحدًا تلو الآخر (يُطبَّق عند بدء جلسة الجديد).',
          ),
          FormFieldPair(
            first: FormFieldRow(
              label: 'قائمة عناوين (Address-List)',
              hint: 'تُرسَل للراوتر Mikrotik-Address-List',
              child: TextFormField(controller: controllers['address_pool']),
            ),
            second: FormFieldRow(
              label: 'نطاق عناوين الجلسات (Pool)',
              hint: 'المجمّع الذي تُمنح منه IP للجلسات',
              child: TextFormField(controller: controllers['framed_pool']),
            ),
          ),
          _switchRow(
            'ربط MAC',
            bindMac,
            onBindMacChanged,
            subtitle: kPlanNotAppliedHint,
          ),
          _switchRow(
            'ربط IP',
            bindIp,
            onBindIpChanged,
            subtitle: kPlanNotAppliedHint,
          ),
        ],
      ),
    );
  }
}

/// «أيام وساعات السماح» — the web's enforced inputs: «ساعات الباقة»
/// (`offer_hours_from/to`, empty = not set) and the access schedule
/// (`connection_schedule`). The legacy `allowed_days` / `allowed_hours_*`
/// fallbacks are no longer edited here (their stored values are kept).
class PlanWindowSection extends StatelessWidget {
  const PlanWindowSection({
    super.key,
    required this.offerHoursFrom,
    required this.offerHoursTo,
    required this.connectionSchedule,
    required this.onOfferHoursFromChanged,
    required this.onOfferHoursToChanged,
    required this.onConnectionScheduleChanged,
  });

  final String offerHoursFrom;
  final String offerHoursTo;

  /// The schedule JSON string ('' = none).
  final String connectionSchedule;
  final ValueChanged<String> onOfferHoursFromChanged;
  final ValueChanged<String> onOfferHoursToChanged;

  /// Fired with the encoded schedule ('' when every window is removed).
  final ValueChanged<String> onConnectionScheduleChanged;

  @override
  Widget build(BuildContext context) {
    return CollapsibleSection(
      storageKey: 'plan.window',
      icon: Icons.event_available_outlined,
      title: 'أيام وساعات السماح',
      initiallyExpanded: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FormFieldPair(
            first: FormFieldRow(
              label: 'ساعات الباقة — من',
              hint: 'بداية الفترة اليومية',
              child: PlanOptionalTimeField(
                value: offerHoursFrom,
                onChanged: onOfferHoursFromChanged,
              ),
            ),
            second: FormFieldRow(
              label: 'ساعات الباقة — إلى',
              hint: 'نهاية الفترة اليومية',
              child: PlanOptionalTimeField(
                value: offerHoursTo,
                onChanged: onOfferHoursToChanged,
              ),
            ),
          ),
          HubAccessSchedule(
            value: AccessSchedule.parse(connectionSchedule),
            // Short on purpose: the shared header's title row does not wrap,
            // so the web's long title overflowed at phone width.
            title: 'الأيام والأوقات',
            onChanged: (v) => onConnectionScheduleChanged(v.encode()),
          ),
        ],
      ),
    );
  }
}

/// A HH:MM picker that can stay EMPTY («غير محدّد») — no fake 08:00/22:00
/// default that would be saved without the user choosing it.
class PlanOptionalTimeField extends StatelessWidget {
  const PlanOptionalTimeField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final empty = value.trim().isEmpty;
    return InkWell(
      borderRadius: BorderRadius.circular(AppTokens.r10),
      onTap: () async {
        final picked =
            await showWheelTimePicker(context, empty ? '00:00' : value);
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          suffixIcon: empty
              ? const Icon(Icons.schedule_outlined)
              : IconButton(
                  tooltip: 'مسح',
                  icon: const Icon(Icons.close),
                  onPressed: () => onChanged(''),
                ),
        ),
        child: Text(
          empty ? 'غير محدّد' : value,
          style: TextStyle(
            color: empty ? AppTokens.textMuted : AppTokens.sidebarBg,
            fontWeight: empty ? FontWeight.w600 : FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class PlanCommerceSection extends StatelessWidget {
  const PlanCommerceSection({
    super.key,
    required this.controllers,
    required this.planTier,
    required this.prepaid,
    required this.autoRenew,
    required this.onPlanTierChanged,
    required this.onPrepaidChanged,
    required this.onAutoRenewChanged,
  });

  final Map<String, TextEditingController> controllers;
  final String planTier;
  final bool prepaid;
  final bool autoRenew;
  final ValueChanged<String> onPlanTierChanged;
  final ValueChanged<bool> onPrepaidChanged;
  final ValueChanged<bool> onAutoRenewChanged;

  @override
  Widget build(BuildContext context) {
    return CollapsibleSection(
      storageKey: 'plan.commerce',
      icon: Icons.payments_outlined,
      title: 'تجاري',
      initiallyExpanded: false,
      child: Column(
        children: [
          FormFieldPair(
            first: FormFieldRow(
              label: 'السعر',
              child: TextFormField(
                controller: controllers['price'],
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: numberFieldFormatters,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (v) => validateNumberInput(
                  v,
                  required: false,
                  max: kMaxMoneyAmount,
                ),
              ),
            ),
            second: FormFieldRow(
              label: 'العملة',
              child: TextFormField(controller: controllers['currency']),
            ),
          ),
          FormFieldRow(
            label: 'الفئة',
            hint: kPlanNotAppliedHint,
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: planTier,
              items: const [
                DropdownMenuItem(value: 'Personal', child: Text('شخصي')),
                DropdownMenuItem(value: 'Business', child: Text('تجاري')),
              ],
              onChanged: (v) => onPlanTierChanged(v ?? 'Personal'),
            ),
          ),
          _switchRow(
            'مدفوع مسبقًا',
            prepaid,
            onPrepaidChanged,
            subtitle: kPlanNotAppliedHint,
          ),
          _switchRow(
            'تجديد تلقائي',
            autoRenew,
            onAutoRenewChanged,
            subtitle: kPlanNotAppliedHint,
          ),
        ],
      ),
    );
  }
}

/// Consumption options. The old «هوتسبوت» / «اتصال PPPoE» switches are gone:
/// the server derives `hotspot_enabled` / `ppp_enabled` from «نوع الخدمة»
/// (web parity), so they are no longer edited here.
class PlanServicesSection extends StatelessWidget {
  const PlanServicesSection({
    super.key,
    required this.singleUseOnce,
    required this.onSingleUseChanged,
  });

  final bool singleUseOnce;
  final ValueChanged<bool> onSingleUseChanged;

  @override
  Widget build(BuildContext context) {
    return CollapsibleSection(
      storageKey: 'plan.services',
      icon: Icons.toggle_on_outlined,
      title: 'الاستهلاك',
      initiallyExpanded: false,
      child: Column(
        children: [
          _switchRow(
            'استخدام مرة واحدة',
            singleUseOnce,
            onSingleUseChanged,
            subtitle: kPlanNotAppliedHint,
          ),
        ],
      ),
    );
  }
}

/// Loan / speed-override / device-binding policy section (RM-H3 fields).
class PlanLoanDeviceSection extends StatelessWidget {
  const PlanLoanDeviceSection({
    super.key,
    required this.controllers,
    required this.loanEnabled,
    required this.onLoanEnabledChanged,
    required this.speedOverrideAllowed,
    required this.onSpeedOverrideChanged,
    required this.forceMacAddress,
    required this.onForceMacChanged,
  });

  final Map<String, TextEditingController> controllers;
  final bool loanEnabled;
  final ValueChanged<bool> onLoanEnabledChanged;
  final bool speedOverrideAllowed;
  final ValueChanged<bool> onSpeedOverrideChanged;
  final bool forceMacAddress;
  final ValueChanged<bool> onForceMacChanged;

  @override
  Widget build(BuildContext context) {
    return CollapsibleSection(
      storageKey: 'plan.loan_device',
      icon: Icons.policy_outlined,
      title: 'السلف والأجهزة',
      initiallyExpanded: false,
      child: Column(
        children: [
          _switchRow('السماح بالسلف', loanEnabled, onLoanEnabledChanged),
          _switchRow(
            'تجاوز سرعة المستفيد',
            speedOverrideAllowed,
            onSpeedOverrideChanged,
            subtitle: kPlanNotAppliedHint,
          ),
          _switchRow(
            'إلزام ربط الـ MAC',
            forceMacAddress,
            onForceMacChanged,
            subtitle: kPlanNotAppliedHint,
          ),
          const SizedBox(height: 4),
          FormFieldPair(
            first: _numField(
              controllers,
              'max_loan_minutes',
              'أقصى دقائق السلفة',
            ),
            second: _numField(
              controllers,
              'allowed_devices_count',
              'عدد الأجهزة المسموحة',
              hint: kPlanNotAppliedHint,
            ),
          ),
        ],
      ),
    );
  }
}

class PlanMetaSection extends StatelessWidget {
  const PlanMetaSection({super.key, required this.controllers});
  final Map<String, TextEditingController> controllers;

  @override
  Widget build(BuildContext context) {
    return CollapsibleSection(
      storageKey: 'plan.meta',
      icon: Icons.notes,
      title: 'وصف ولون',
      initiallyExpanded: false,
      child: Column(
        children: [
          FormFieldRow(
            label: 'الوصف',
            child: TextFormField(
              controller: controllers['description'],
              maxLines: 3,
            ),
          ),
          FormFieldRow(
            label: 'لون',
            hint: 'hex مثال: #2BAACC',
            child: TextFormField(controller: controllers['color']),
          ),
        ],
      ),
    );
  }
}
