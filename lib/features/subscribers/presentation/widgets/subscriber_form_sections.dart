import 'package:flutter/material.dart';

import '../../../../shared/widgets/collapsible_section.dart';
import '../../../../shared/widgets/form_field_row.dart';
import '../../../../shared/widgets/hub_time_picker_circular.dart';
import '../../../../shared/widgets/hub_toggle_switch.dart';
import '../../../../shared/widgets/wheel_picker_fields.dart';
import 'expire_picker.dart';
import 'plan_picker.dart';

/// Subscriber form — basic identity + plan + expiry.
class SubscriberCoreSection extends StatelessWidget {
  const SubscriberCoreSection({
    super.key,
    required this.controllers,
    required this.isEdit,
    required this.status,
    required this.userType,
    required this.expireAt,
    required this.onStatusChanged,
    required this.onUserTypeChanged,
    required this.onExpireChanged,
  });

  final Map<String, TextEditingController> controllers;
  final bool isEdit;
  final String status;
  final String userType;
  final DateTime? expireAt;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onUserTypeChanged;
  final ValueChanged<DateTime?> onExpireChanged;

  @override
  Widget build(BuildContext context) {
    return CollapsibleSection(
      storageKey: 'sub.core',
      icon: Icons.person_outline,
      title: 'البيانات الأساسية',
      child: Column(
        children: [
          FormFieldRow(
            label: 'اسم المستخدم',
            required: true,
            child: TextFormField(
              controller: controllers['username'],
              enabled: !isEdit,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
            ),
          ),
          if (!isEdit)
            FormFieldRow(
              label: 'كلمة المرور',
              required: true,
              child: TextFormField(
                controller: controllers['password'],
                obscureText: true,
                validator: (v) => (v == null || v.isEmpty) ? 'مطلوب' : null,
              ),
            ),
          FormFieldRow(
            label: 'الاسم الكامل',
            child: TextFormField(controller: controllers['full_name']),
          ),
          FormFieldRow(
            label: 'الجوال',
            child: TextFormField(controller: controllers['mobile']),
          ),
          FormFieldRow(
            label: 'البريد',
            child: TextFormField(controller: controllers['email']),
          ),
          FormFieldRow(
            label: 'مرجع المستفيد',
            child: TextFormField(controller: controllers['beneficiary_ref']),
          ),
          FormFieldRow(
            label: 'الحالة',
            child: DropdownButtonFormField<String>(
              initialValue: status,
              items: const [
                DropdownMenuItem(value: 'enabled', child: Text('مفعّل')),
                DropdownMenuItem(value: 'disabled', child: Text('معطّل')),
                DropdownMenuItem(value: 'expired', child: Text('منتهي')),
              ],
              onChanged: (v) => onStatusChanged(v ?? 'enabled'),
            ),
          ),
          FormFieldRow(
            label: 'نوع المستخدم',
            child: DropdownButtonFormField<String>(
              initialValue: userType,
              items: const [
                DropdownMenuItem(
                  value: 'subscriber',
                  child: Text('مشترك'),
                ),
                DropdownMenuItem(value: 'card', child: Text('كرت')),
                DropdownMenuItem(value: 'employee', child: Text('موظف')),
              ],
              onChanged: (v) => onUserTypeChanged(v ?? 'subscriber'),
            ),
          ),
          FormFieldRow(
            label: 'الباقة',
            hint: 'اختر باقة من القائمة',
            child: PlanPicker(controller: controllers['plan_id']!),
          ),
          FormFieldRow(
            label: 'تاريخ الانتهاء',
            child: ExpirePicker(value: expireAt, onChange: onExpireChanged),
          ),
          FormFieldRow(
            label: 'ملاحظات',
            child:
                TextFormField(controller: controllers['remark'], maxLines: 2),
          ),
        ],
      ),
    );
  }
}

/// MikroTik / PPP settings section.
class SubscriberMtSection extends StatelessWidget {
  const SubscriberMtSection({
    super.key,
    required this.controllers,
    required this.mtService,
    required this.onMtServiceChanged,
  });

  final Map<String, TextEditingController> controllers;
  final String mtService;
  final ValueChanged<String> onMtServiceChanged;

  @override
  Widget build(BuildContext context) {
    return CollapsibleSection(
      storageKey: 'sub.mt',
      icon: Icons.router_outlined,
      title: 'إعدادات الراوتر (MikroTik / PPP)',
      child: Column(
        children: [
          FormFieldRow(
            label: 'الـ profile',
            child: TextFormField(controller: controllers['mt_profile']),
          ),
          FormFieldRow(
            label: 'الخدمة',
            child: DropdownButtonFormField<String>(
              initialValue: mtService,
              items: const [
                DropdownMenuItem(value: 'pppoe', child: Text('اتصال PPPoE')),
                DropdownMenuItem(value: 'hotspot', child: Text('هوتسبوت')),
                DropdownMenuItem(value: 'l2tp', child: Text('L2TP')),
                DropdownMenuItem(value: 'pptp', child: Text('PPTP')),
                DropdownMenuItem(value: 'sstp', child: Text('SSTP')),
                DropdownMenuItem(value: 'static', child: Text('Static')),
              ],
              onChanged: (v) => onMtServiceChanged(v ?? 'pppoe'),
            ),
          ),
          FormFieldRow(
            label: 'Rate Limit',
            hint: 'مثال: 5M/10M أو 5M/10M 6M/12M 4M/8M 30/30',
            child: TextFormField(controller: controllers['mt_rate_limit']),
          ),
          FormFieldRow(
            label: 'مجموعة عناوين IP',
            child: TextFormField(controller: controllers['mt_ip_pool']),
          ),
          FormFieldRow(
            label: 'تعليق',
            child: TextFormField(controller: controllers['mt_comment']),
          ),
        ],
      ),
    );
  }
}

/// RADIUS / DNS attributes section.
class SubscriberRadiusSection extends StatelessWidget {
  const SubscriberRadiusSection({super.key, required this.controllers});

  final Map<String, TextEditingController> controllers;

  @override
  Widget build(BuildContext context) {
    return CollapsibleSection(
      storageKey: 'sub.radius',
      icon: Icons.settings_ethernet,
      title: 'سمات RADIUS / DNS',
      child: Column(
        children: [
          FormFieldRow(
            label: 'خادم DNS الأول',
            child: TextFormField(controller: controllers['dns1']),
          ),
          FormFieldRow(
            label: 'خادم DNS الثاني',
            child: TextFormField(controller: controllers['dns2']),
          ),
          FormFieldRow(
            label: 'الجلسات المتزامنة',
            child: TextFormField(
              controller: controllers['simultaneous_use'],
              keyboardType: TextInputType.number,
            ),
          ),
          FormFieldRow(
            label: 'مهلة الجلسة (ث)',
            child: TextFormField(
              controller: controllers['session_timeout'],
              keyboardType: TextInputType.number,
            ),
          ),
          FormFieldRow(
            label: 'مهلة الخمول (ث)',
            child: TextFormField(
              controller: controllers['idle_timeout'],
              keyboardType: TextInputType.number,
            ),
          ),
          FormFieldRow(
            label: 'معرّف نقطة الاتصال',
            child: TextFormField(controller: controllers['called_station_id']),
          ),
        ],
      ),
    );
  }
}

/// MAC / IP lock section (collapsed by default).
class SubscriberLockSection extends StatelessWidget {
  const SubscriberLockSection({super.key, required this.controllers});

  final Map<String, TextEditingController> controllers;

  @override
  Widget build(BuildContext context) {
    return CollapsibleSection(
      storageKey: 'sub.macip',
      icon: Icons.lock_outline,
      title: 'القفل: MAC / IP',
      initiallyExpanded: false,
      child: Column(
        children: [
          FormFieldRow(
            label: 'قفل على MAC',
            hint: 'AA:BB:CC:DD:EE:FF',
            child: TextFormField(controller: controllers['mac_lock']),
          ),
          FormFieldRow(
            label: 'IP ثابت',
            child: TextFormField(controller: controllers['static_ip']),
          ),
        ],
      ),
    );
  }
}

/// Advanced section — allowed hours + working days + first-use toggle.
class SubscriberAdvancedSection extends StatelessWidget {
  const SubscriberAdvancedSection({
    super.key,
    required this.allowedFrom,
    required this.allowedTo,
    required this.onAllowedHoursChanged,
    required this.workingDays,
    required this.onWorkingDaysChanged,
    required this.disableOnFirstUse,
    required this.onDisableOnFirstUseChanged,
  });

  final String allowedFrom;
  final String allowedTo;
  final void Function(String from, String to) onAllowedHoursChanged;
  final Set<String> workingDays;
  final ValueChanged<Set<String>> onWorkingDaysChanged;
  final bool disableOnFirstUse;
  final ValueChanged<bool> onDisableOnFirstUseChanged;

  @override
  Widget build(BuildContext context) {
    return CollapsibleSection(
      storageKey: 'sub.advanced',
      icon: Icons.tune,
      title: 'إعدادات متقدّمة',
      initiallyExpanded: false,
      child: Column(
        children: [
          FormFieldRow(
            label: 'ساعات السماح',
            child: Row(
              children: [
                Expanded(
                  child: HubTimePickerCircular(
                    value: allowedFrom,
                    onChanged: (from) => onAllowedHoursChanged(from, allowedTo),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: HubTimePickerCircular(
                    value: allowedTo,
                    onChanged: (to) => onAllowedHoursChanged(allowedFrom, to),
                  ),
                ),
              ],
            ),
          ),
          FormFieldRow(
            label: 'أيام العمل',
            child: WheelDaysPickerField(
              selectedKeys: workingDays,
              onChanged: onWorkingDaysChanged,
            ),
          ),
          FormFieldRow(
            label: 'تعطيل تلقائي بعد أول استخدام',
            child: HubToggleSwitch(
              value: disableOnFirstUse,
              onChanged: onDisableOnFirstUseChanged,
            ),
          ),
        ],
      ),
    );
  }
}

/// Notifications section — toggle + email + mobile.
class SubscriberNotificationsSection extends StatelessWidget {
  const SubscriberNotificationsSection({
    super.key,
    required this.controllers,
    required this.notifyOnLogin,
    required this.onNotifyOnLoginChanged,
  });

  final Map<String, TextEditingController> controllers;
  final bool notifyOnLogin;
  final ValueChanged<bool> onNotifyOnLoginChanged;

  @override
  Widget build(BuildContext context) {
    return CollapsibleSection(
      storageKey: 'sub.notif',
      icon: Icons.notifications_outlined,
      title: 'التنبيهات',
      initiallyExpanded: false,
      child: Column(
        children: [
          FormFieldRow(
            label: 'تنبيه عند الدخول',
            child: HubToggleSwitch(
              value: notifyOnLogin,
              onChanged: onNotifyOnLoginChanged,
            ),
          ),
          FormFieldRow(
            label: 'بريد التنبيهات',
            child: TextFormField(controller: controllers['notify_email']),
          ),
          FormFieldRow(
            label: 'جوال التنبيهات',
            child: TextFormField(controller: controllers['notify_mobile']),
          ),
        ],
      ),
    );
  }
}

/// Subscription section — type + days + auto-renew toggle.
class SubscriberSubscriptionSection extends StatelessWidget {
  const SubscriberSubscriptionSection({
    super.key,
    required this.controllers,
    required this.subscriptionType,
    required this.onSubscriptionTypeChanged,
    required this.autoRenew,
    required this.onAutoRenewChanged,
  });

  final Map<String, TextEditingController> controllers;
  final String subscriptionType;
  final ValueChanged<String> onSubscriptionTypeChanged;
  final bool autoRenew;
  final ValueChanged<bool> onAutoRenewChanged;

  @override
  Widget build(BuildContext context) {
    return CollapsibleSection(
      storageKey: 'sub.subscription',
      icon: Icons.subscriptions_outlined,
      title: 'الاشتراك',
      initiallyExpanded: false,
      child: Column(
        children: [
          FormFieldRow(
            label: 'نوع الاشتراك',
            child: DropdownButtonFormField<String>(
              initialValue: subscriptionType,
              items: const [
                DropdownMenuItem(value: 'fixed', child: Text('ثابت')),
                DropdownMenuItem(value: 'rolling', child: Text('متجدّد')),
                DropdownMenuItem(
                  value: 'prepaid',
                  child: Text('مدفوع مسبقًا'),
                ),
              ],
              onChanged: (v) => onSubscriptionTypeChanged(v ?? 'fixed'),
            ),
          ),
          FormFieldRow(
            label: 'مدّة الاشتراك (أيام)',
            child: TextFormField(
              controller: controllers['subscription_days'],
              keyboardType: TextInputType.number,
            ),
          ),
          FormFieldRow(
            label: 'تجديد تلقائي',
            child: HubToggleSwitch(
              value: autoRenew,
              onChanged: onAutoRenewChanged,
            ),
          ),
        ],
      ),
    );
  }
}

/// General section — notes + tags.
class SubscriberGeneralSection extends StatelessWidget {
  const SubscriberGeneralSection({super.key, required this.controllers});

  final Map<String, TextEditingController> controllers;

  @override
  Widget build(BuildContext context) {
    return CollapsibleSection(
      storageKey: 'sub.general',
      icon: Icons.notes,
      title: 'عام',
      initiallyExpanded: false,
      child: Column(
        children: [
          FormFieldRow(
            label: 'ملاحظات',
            child:
                TextFormField(controller: controllers['notes'], maxLines: 3),
          ),
          FormFieldRow(
            label: 'وسوم',
            hint: 'قِيَم مفصولة بفواصل',
            child: TextFormField(controller: controllers['tags']),
          ),
        ],
      ),
    );
  }
}
