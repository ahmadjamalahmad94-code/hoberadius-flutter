import 'package:hoberadius_app/core/format/money_limits.dart';
import 'package:hoberadius_app/core/format/number_input.dart';
import 'package:flutter/material.dart';

import '../../../../shared/widgets/collapsible_section.dart';
import '../../../../shared/widgets/form_field_row.dart';
import '../../../../shared/widgets/hub_switch_row.dart';
import '../../../../shared/widgets/wheel_picker_fields.dart';

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

/// Label at the start, switch at the end — the one on/off row style.
Widget _switchRow(String label, bool value, ValueChanged<bool> onChanged) =>
    HubSwitchRow(label: label, value: value, onChanged: onChanged, dense: true);

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
                items: const [
                  DropdownMenuItem(value: 'Hotspot', child: Text('هوتسبوت')),
                  DropdownMenuItem(value: 'PPPoE', child: Text('اتصال PPPoE')),
                  DropdownMenuItem(value: 'Balance', child: Text('رصيد')),
                  DropdownMenuItem(value: 'Voucher', child: Text('قسيمة')),
                  DropdownMenuItem(value: 'Others', child: Text('أخرى')),
                ],
                onChanged: (v) => onServiceTypeChanged(v ?? 'Hotspot'),
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
            second: _numField(
              controllers,
              'duration_minutes',
              'مدّة الاتصال (د)',
              hint: '0 = لا حدّ',
            ),
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
          _numField(controllers, 'quota_total_mb', 'الإجمالي (MB)'),
          FormFieldPair(
            first: _numField(controllers, 'quota_daily_mb', 'يومي (MB)'),
            second: _numField(controllers, 'quota_monthly_mb', 'شهري (MB)'),
          ),
          const Divider(height: 16),
          FormFieldPair(
            first: _numField(
              controllers,
              'daily_download_quota_mb',
              'كوتا تنزيل يومية (MB)',
            ),
            second: _numField(
              controllers,
              'daily_upload_quota_mb',
              'كوتا رفع يومية (MB)',
            ),
          ),
          FormFieldPair(
            first: _numField(
              controllers,
              'monthly_download_quota_mb',
              'كوتا تنزيل شهرية (MB)',
            ),
            second: _numField(
              controllers,
              'monthly_upload_quota_mb',
              'كوتا رفع شهرية (MB)',
            ),
          ),
          FormFieldPair(
            first: _numField(
              controllers,
              'daily_combined_quota_mb',
              'كوتا مدمجة يومية (MB)',
            ),
            second: _numField(
              controllers,
              'monthly_combined_quota_mb',
              'كوتا مدمجة شهرية (MB)',
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
    required this.speedControl,
    required this.onSpeedControlChanged,
    required this.burstEnabled,
    required this.onBurstEnabledChanged,
    required this.nightlyUnlimited,
    required this.onNightlyUnlimitedChanged,
  });

  final Map<String, TextEditingController> controllers;
  final bool speedControl;
  final ValueChanged<bool> onSpeedControlChanged;
  final bool burstEnabled;
  final ValueChanged<bool> onBurstEnabledChanged;
  final bool nightlyUnlimited;
  final ValueChanged<bool> onNightlyUnlimitedChanged;

  @override
  Widget build(BuildContext context) {
    Widget num(String key, String label) => _numField(controllers, key, label);
    return CollapsibleSection(
      storageKey: 'plan.speed',
      icon: Icons.speed,
      title: 'السرعة والتحكم المتقدم',
      child: Column(
        children: [
          FormFieldPair(
            first: num('speed_down_kbps', 'تنزيل (kbps)'),
            second: num('speed_up_kbps', 'رفع (kbps)'),
          ),
          _switchRow(
            'تفعيل التحكم بالسرعة',
            speedControl,
            onSpeedControlChanged,
          ),
          FormFieldPair(
            first: num('cir_down_kbps', 'الحد الأدنى للتنزيل'),
            second: num('cir_up_kbps', 'الحد الأدنى للرفع'),
          ),
          _switchRow(
            'تفعيل دفعة السرعة المؤقتة',
            burstEnabled,
            onBurstEnabledChanged,
          ),
          FormFieldPair(
            first: num('burst_down_kbps', 'دفعة تنزيل مؤقتة'),
            second: num('burst_up_kbps', 'دفعة رفع مؤقتة'),
          ),
          FormFieldPair(
            first: num('burst_threshold_kbps', 'حد دفعة السرعة'),
            second: num('burst_time_sec', 'مدة الدفعة (ث)'),
          ),
          _switchRow(
            'ليلي بلا حدود',
            nightlyUnlimited,
            onNightlyUnlimitedChanged,
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
  });

  final Map<String, TextEditingController> controllers;
  final bool bindMac;
  final bool bindIp;
  final ValueChanged<bool> onBindMacChanged;
  final ValueChanged<bool> onBindIpChanged;

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
            second: _numField(controllers, 'vlan_id', 'معرّف VLAN'),
          ),
          FormFieldPair(
            first: FormFieldRow(
              label: 'مجموعة عناوين IP',
              child: TextFormField(controller: controllers['address_pool']),
            ),
            second: FormFieldRow(
              label: 'مجموعة الاتصال',
              child: TextFormField(controller: controllers['framed_pool']),
            ),
          ),
          _switchRow('قفل على MAC', bindMac, onBindMacChanged),
          _switchRow('قفل على IP', bindIp, onBindIpChanged),
        ],
      ),
    );
  }
}

class PlanWindowSection extends StatelessWidget {
  const PlanWindowSection({
    super.key,
    required this.controllers,
    required this.allowedDays,
    required this.onAllowedDaysChanged,
    required this.onAllowedFromChanged,
    required this.onAllowedToChanged,
  });

  final Map<String, TextEditingController> controllers;
  final Set<String> allowedDays;
  final ValueChanged<Set<String>> onAllowedDaysChanged;
  final ValueChanged<String> onAllowedFromChanged;
  final ValueChanged<String> onAllowedToChanged;

  @override
  Widget build(BuildContext context) {
    return CollapsibleSection(
      storageKey: 'plan.window',
      icon: Icons.event_available_outlined,
      title: 'نافذة العمل',
      initiallyExpanded: false,
      child: Column(
        children: [
          FormFieldRow(
            label: 'أيام مسموح بها',
            child: WheelDaysPickerField(
              selectedKeys: allowedDays,
              onChanged: onAllowedDaysChanged,
            ),
          ),
          FormFieldPair(
            first: FormFieldRow(
              label: 'من الساعة',
              child: WheelTimePickerField(
                label: 'من',
                value: controllers['allowed_hours_from']!.text.isEmpty
                    ? '08:00'
                    : controllers['allowed_hours_from']!.text,
                onChanged: onAllowedFromChanged,
              ),
            ),
            second: FormFieldRow(
              label: 'حتى الساعة',
              child: WheelTimePickerField(
                label: 'إلى',
                value: controllers['allowed_hours_to']!.text.isEmpty
                    ? '22:00'
                    : controllers['allowed_hours_to']!.text,
                onChanged: onAllowedToChanged,
              ),
            ),
          ),
        ],
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
          _switchRow('مدفوع مسبقًا', prepaid, onPrepaidChanged),
          _switchRow('تجديد تلقائي', autoRenew, onAutoRenewChanged),
        ],
      ),
    );
  }
}

class PlanServicesSection extends StatelessWidget {
  const PlanServicesSection({
    super.key,
    required this.hotspotEnabled,
    required this.pppEnabled,
    required this.singleUseOnce,
    required this.onHotspotChanged,
    required this.onPppChanged,
    required this.onSingleUseChanged,
  });

  final bool hotspotEnabled;
  final bool pppEnabled;
  final bool singleUseOnce;
  final ValueChanged<bool> onHotspotChanged;
  final ValueChanged<bool> onPppChanged;
  final ValueChanged<bool> onSingleUseChanged;

  @override
  Widget build(BuildContext context) {
    return CollapsibleSection(
      storageKey: 'plan.services',
      icon: Icons.toggle_on_outlined,
      title: 'الخدمات',
      initiallyExpanded: false,
      child: Column(
        children: [
          _switchRow('هوتسبوت', hotspotEnabled, onHotspotChanged),
          _switchRow('اتصال PPPoE', pppEnabled, onPppChanged),
          _switchRow('استخدام واحد فقط', singleUseOnce, onSingleUseChanged),
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
            'السماح بتجاوز السرعة',
            speedOverrideAllowed,
            onSpeedOverrideChanged,
          ),
          _switchRow('إلزام ربط الـ MAC', forceMacAddress, onForceMacChanged),
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
