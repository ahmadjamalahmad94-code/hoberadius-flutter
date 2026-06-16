import 'package:flutter/material.dart';

import '../../../../shared/widgets/collapsible_section.dart';
import '../../../../shared/widgets/form_field_row.dart';
import '../../../../shared/widgets/wheel_picker_fields.dart';

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
          FormFieldRow(
            label: 'الكود',
            hint: 'معرّف داخلي اختياري',
            child: TextFormField(controller: controllers['code']),
          ),
          FormFieldRow(
            label: 'نوع الباقة',
            child: DropdownButtonFormField<String>(
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
          FormFieldRow(
            label: 'نوع الخدمة',
            child: DropdownButtonFormField<String>(
              initialValue: serviceType,
              items: const [
                DropdownMenuItem(value: 'Hotspot', child: Text('هوتسبوت')),
                DropdownMenuItem(
                  value: 'PPPoE',
                  child: Text('اتصال PPPoE'),
                ),
                DropdownMenuItem(value: 'Balance', child: Text('رصيد')),
                DropdownMenuItem(value: 'Voucher', child: Text('قسيمة')),
                DropdownMenuItem(value: 'Others', child: Text('أخرى')),
              ],
              onChanged: (v) => onServiceTypeChanged(v ?? 'Hotspot'),
            ),
          ),
          FormFieldRow(
            label: 'الأولوية',
            hint: 'الأقل = الأعلى أولوية',
            child: TextFormField(
              controller: controllers['priority'],
              keyboardType: TextInputType.number,
            ),
          ),
          FormFieldRow(
            label: 'مفعّلة',
            child: Switch(value: enabled, onChanged: onEnabledChanged),
          ),
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
          FormFieldRow(
            label: 'الصلاحية (أيام)',
            child: TextFormField(
              controller: controllers['validity_days'],
              keyboardType: TextInputType.number,
            ),
          ),
          FormFieldRow(
            label: 'مدّة الاتصال (دقائق)',
            hint: '0 = لا حدّ',
            child: TextFormField(
              controller: controllers['duration_minutes'],
              keyboardType: TextInputType.number,
            ),
          ),
          FormFieldRow(
            label: 'مهلة الجلسة (ث)',
            child: TextFormField(
              controller: controllers['session_timeout_sec'],
              keyboardType: TextInputType.number,
            ),
          ),
          FormFieldRow(
            label: 'مهلة الخمول (ث)',
            child: TextFormField(
              controller: controllers['idle_timeout_sec'],
              keyboardType: TextInputType.number,
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
          FormFieldRow(
            label: 'الإجمالي (MB)',
            child: TextFormField(
              controller: controllers['quota_total_mb'],
              keyboardType: TextInputType.number,
            ),
          ),
          FormFieldRow(
            label: 'يومي (MB)',
            child: TextFormField(
              controller: controllers['quota_daily_mb'],
              keyboardType: TextInputType.number,
            ),
          ),
          FormFieldRow(
            label: 'شهري (MB)',
            child: TextFormField(
              controller: controllers['quota_monthly_mb'],
              keyboardType: TextInputType.number,
            ),
          ),
          const Divider(height: 24),
          for (final f in const [
            ('daily_download_quota_mb', 'كوتا تنزيل يومية (MB)'),
            ('daily_upload_quota_mb', 'كوتا رفع يومية (MB)'),
            ('daily_combined_quota_mb', 'كوتا مدمجة يومية (MB)'),
            ('monthly_download_quota_mb', 'كوتا تنزيل شهرية (MB)'),
            ('monthly_upload_quota_mb', 'كوتا رفع شهرية (MB)'),
            ('monthly_combined_quota_mb', 'كوتا مدمجة شهرية (MB)'),
          ])
            FormFieldRow(
              label: f.$2,
              child: TextFormField(
                controller: controllers[f.$1],
                keyboardType: TextInputType.number,
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
    Widget num(String key, String label, [String? hint]) => FormFieldRow(
          label: label,
          hint: hint,
          child: TextFormField(
            controller: controllers[key],
            keyboardType: TextInputType.number,
          ),
        );
    return CollapsibleSection(
      storageKey: 'plan.speed',
      icon: Icons.speed,
      title: 'السرعة والتحكم المتقدم',
      child: Column(
        children: [
          num('speed_down_kbps', 'تنزيل (kbps)'),
          num('speed_up_kbps', 'رفع (kbps)'),
          FormFieldRow(
            label: 'تفعيل التحكم بالسرعة',
            child: Switch(
              value: speedControl,
              onChanged: onSpeedControlChanged,
            ),
          ),
          num('cir_down_kbps', 'الحد الأدنى للتنزيل'),
          num('cir_up_kbps', 'الحد الأدنى للرفع'),
          FormFieldRow(
            label: 'تفعيل دفعة السرعة المؤقتة',
            child: Switch(
              value: burstEnabled,
              onChanged: onBurstEnabledChanged,
            ),
          ),
          num('burst_down_kbps', 'دفعة تنزيل مؤقتة'),
          num('burst_up_kbps', 'دفعة رفع مؤقتة'),
          num('burst_threshold_kbps', 'حد دفعة السرعة'),
          num('burst_time_sec', 'مدة دفعة السرعة (ثانية)'),
          FormFieldRow(
            label: 'ليلي بلا حدود',
            child: Switch(
              value: nightlyUnlimited,
              onChanged: onNightlyUnlimitedChanged,
            ),
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
          FormFieldRow(
            label: 'الجلسات المتزامنة',
            child: TextFormField(
              controller: controllers['concurrent_sessions'],
              keyboardType: TextInputType.number,
            ),
          ),
          FormFieldRow(
            label: 'مجموعة عناوين IP',
            child: TextFormField(controller: controllers['address_pool']),
          ),
          FormFieldRow(
            label: 'مجموعة الاتصال',
            child: TextFormField(controller: controllers['framed_pool']),
          ),
          FormFieldRow(
            label: 'معرّف VLAN',
            child: TextFormField(
              controller: controllers['vlan_id'],
              keyboardType: TextInputType.number,
            ),
          ),
          FormFieldRow(
            label: 'قفل على MAC',
            child: Switch(value: bindMac, onChanged: onBindMacChanged),
          ),
          FormFieldRow(
            label: 'قفل على IP',
            child: Switch(value: bindIp, onChanged: onBindIpChanged),
          ),
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
          FormFieldRow(
            label: 'من الساعة',
            child: WheelTimePickerField(
              label: 'من',
              value: controllers['allowed_hours_from']!.text.isEmpty
                  ? '08:00'
                  : controllers['allowed_hours_from']!.text,
              onChanged: onAllowedFromChanged,
            ),
          ),
          FormFieldRow(
            label: 'حتى الساعة',
            child: WheelTimePickerField(
              label: 'إلى',
              value: controllers['allowed_hours_to']!.text.isEmpty
                  ? '22:00'
                  : controllers['allowed_hours_to']!.text,
              onChanged: onAllowedToChanged,
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
          FormFieldRow(
            label: 'السعر',
            child: TextFormField(
              controller: controllers['price'],
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
          ),
          FormFieldRow(
            label: 'العملة',
            child: TextFormField(controller: controllers['currency']),
          ),
          FormFieldRow(
            label: 'الفئة',
            child: DropdownButtonFormField<String>(
              initialValue: planTier,
              items: const [
                DropdownMenuItem(value: 'Personal', child: Text('شخصي')),
                DropdownMenuItem(value: 'Business', child: Text('تجاري')),
              ],
              onChanged: (v) => onPlanTierChanged(v ?? 'Personal'),
            ),
          ),
          FormFieldRow(
            label: 'مدفوع مسبقًا',
            child: Switch(value: prepaid, onChanged: onPrepaidChanged),
          ),
          FormFieldRow(
            label: 'تجديد تلقائي',
            child: Switch(value: autoRenew, onChanged: onAutoRenewChanged),
          ),
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
          FormFieldRow(
            label: 'هوتسبوت',
            child: Switch(
              value: hotspotEnabled,
              onChanged: onHotspotChanged,
            ),
          ),
          FormFieldRow(
            label: 'اتصال PPPoE',
            child: Switch(value: pppEnabled, onChanged: onPppChanged),
          ),
          FormFieldRow(
            label: 'استخدام واحد فقط',
            child: Switch(
              value: singleUseOnce,
              onChanged: onSingleUseChanged,
            ),
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
          FormFieldRow(
            label: 'السماح بالسلف',
            child: Switch(value: loanEnabled, onChanged: onLoanEnabledChanged),
          ),
          FormFieldRow(
            label: 'أقصى دقائق السلفة',
            child: TextFormField(
              controller: controllers['max_loan_minutes'],
              keyboardType: TextInputType.number,
            ),
          ),
          FormFieldRow(
            label: 'السماح بتجاوز السرعة',
            child: Switch(
              value: speedOverrideAllowed,
              onChanged: onSpeedOverrideChanged,
            ),
          ),
          FormFieldRow(
            label: 'عدد الأجهزة المسموحة',
            child: TextFormField(
              controller: controllers['allowed_devices_count'],
              keyboardType: TextInputType.number,
            ),
          ),
          FormFieldRow(
            label: 'إلزام ربط الـ MAC',
            child: Switch(
              value: forceMacAddress,
              onChanged: onForceMacChanged,
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
