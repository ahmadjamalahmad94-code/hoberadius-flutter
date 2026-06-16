import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/collapsible_section.dart';
import '../../../../shared/widgets/form_field_row.dart';
import '../../../../shared/widgets/hub_time_picker_circular.dart';
import '../../../../shared/widgets/hub_toggle_switch.dart';
import '../../../../shared/widgets/wheel_picker_fields.dart';
import '../../../admins/data/admins_repository.dart';
import 'expire_picker.dart';
import 'plan_picker.dart';

/// Number-only text field used across the new parity sections.
class _NumField extends StatelessWidget {
  const _NumField({required this.controller});
  final TextEditingController controller;
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
    );
  }
}

/// Subscriber form — basic identity + plan + expiry.
class SubscriberCoreSection extends StatelessWidget {
  const SubscriberCoreSection({
    super.key,
    required this.controllers,
    required this.isEdit,
    required this.status,
    required this.userType,
    required this.serviceType,
    required this.expireAt,
    required this.onStatusChanged,
    required this.onUserTypeChanged,
    required this.onServiceTypeChanged,
    required this.onExpireChanged,
  });

  final Map<String, TextEditingController> controllers;
  final bool isEdit;
  final String status;
  final String userType;
  final String serviceType;
  final DateTime? expireAt;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onUserTypeChanged;
  final ValueChanged<String> onServiceTypeChanged;
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
            label: 'نوع الخدمة',
            child: DropdownButtonFormField<String>(
              initialValue: const [
                'Hotspot',
                'PPPoE',
                'Balance',
                'Voucher',
                'Others',
              ].contains(serviceType)
                  ? serviceType
                  : 'Hotspot',
              items: const [
                DropdownMenuItem(value: 'Hotspot', child: Text('هوتسبوت')),
                DropdownMenuItem(value: 'PPPoE', child: Text('PPPoE')),
                DropdownMenuItem(value: 'Balance', child: Text('رصيد')),
                DropdownMenuItem(value: 'Voucher', child: Text('كوبون')),
                DropdownMenuItem(value: 'Others', child: Text('أخرى')),
              ],
              onChanged: (v) => onServiceTypeChanged(v ?? 'Hotspot'),
            ),
          ),
          FormFieldRow(
            label: 'الباقة',
            hint: 'اختر باقة من القائمة',
            child: PlanPicker(controller: controllers['plan_id']!),
          ),
          FormFieldRow(
            label: 'السعر المخصص',
            hint: 'اتركه فارغًا لاستخدام سعر الباقة',
            child: TextFormField(
              controller: controllers['custom_price'],
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                suffixText: 'اختياري',
              ),
            ),
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
                DropdownMenuItem(value: 'static', child: Text('عنوان ثابت')),
              ],
              onChanged: (v) => onMtServiceChanged(v ?? 'pppoe'),
            ),
          ),
          FormFieldRow(
            label: 'حد السرعة على الراوتر',
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
      title: 'سمات الريدياس وDNS',
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
      title: 'الشبكة وقيود الاتصال',
      initiallyExpanded: false,
      child: Column(
        children: [
          FormFieldRow(
            label: 'قفل على MAC',
            hint: 'AA:BB:CC:DD:EE:FF',
            child: TextFormField(controller: controllers['mac_lock']),
          ),
          FormFieldRow(
            label: 'العناوين المسموحة (MAC)',
            hint: 'قِيَم MAC مفصولة بفواصل',
            child: TextFormField(controller: controllers['allowed_macs']),
          ),
          FormFieldRow(
            label: 'IP ثابت',
            child: TextFormField(controller: controllers['static_ip']),
          ),
          FormFieldRow(
            label: 'عدد الأجهزة المسموحة',
            hint: 'الحد الأقصى للجلسات المتزامنة',
            child: _NumField(controller: controllers['device_count']!),
          ),
          FormFieldRow(
            label: 'VLAN',
            child: _NumField(controller: controllers['vlan_id']!),
          ),
          FormFieldRow(
            label: 'ملف اتصال الجهاز',
            child:
                TextFormField(controller: controllers['device_connection_file']),
          ),
        ],
      ),
    );
  }
}

/// Management section — manager (dropdown of admins), group, pool, balance.
class SubscriberManagementSection extends ConsumerWidget {
  const SubscriberManagementSection({
    super.key,
    required this.controllers,
    required this.managerId,
    required this.onManagerChanged,
  });

  final Map<String, TextEditingController> controllers;
  final int? managerId;
  final ValueChanged<int?> onManagerChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final admins = ref.watch(adminsListProvider);
    return CollapsibleSection(
      storageKey: 'sub.management',
      icon: Icons.manage_accounts_outlined,
      title: 'الإدارة والربط',
      initiallyExpanded: false,
      child: Column(
        children: [
          FormFieldRow(
            label: 'المدير المسؤول',
            hint: 'اختر المدير الذي يتابع هذا الحساب',
            child: admins.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => TextFormField(
                initialValue: managerId?.toString() ?? '',
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'رقم المدير (تعذّر جلب القائمة)',
                ),
                onChanged: (v) => onManagerChanged(int.tryParse(v.trim())),
              ),
              data: (list) => DropdownButtonFormField<int?>(
                initialValue: list.any((a) => a.id == managerId)
                    ? managerId
                    : null,
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('بدون مدير'),
                  ),
                  for (final a in list)
                    DropdownMenuItem<int?>(
                      value: a.id,
                      child: Text(
                        a.fullName.isEmpty ? a.username : a.fullName,
                      ),
                    ),
                ],
                onChanged: onManagerChanged,
              ),
            ),
          ),
          FormFieldRow(
            label: 'المجموعة',
            hint: 'اسم مجموعة المشتركين',
            child: TextFormField(controller: controllers['group']),
          ),
          FormFieldRow(
            label: 'مجموعة العناوين (Pool)',
            child: TextFormField(controller: controllers['pool']),
          ),
          FormFieldRow(
            label: 'الرصيد',
            hint: 'رصيد الحساب الحالي',
            child: _NumField(controller: controllers['balance']!),
          ),
        ],
      ),
    );
  }
}

/// Personal information section.
class SubscriberPersonalSection extends StatelessWidget {
  const SubscriberPersonalSection({
    super.key,
    required this.controllers,
    required this.accountType,
    required this.onAccountTypeChanged,
  });

  final Map<String, TextEditingController> controllers;
  final String accountType;
  final ValueChanged<String> onAccountTypeChanged;

  @override
  Widget build(BuildContext context) {
    return CollapsibleSection(
      storageKey: 'sub.personal',
      icon: Icons.badge_outlined,
      title: 'المعلومات الشخصية',
      initiallyExpanded: false,
      child: Column(
        children: [
          FormFieldRow(
            label: 'نوع الحساب',
            child: DropdownButtonFormField<String>(
              initialValue:
                  accountType == 'Business' ? 'Business' : 'Personal',
              items: const [
                DropdownMenuItem(value: 'Personal', child: Text('شخصي')),
                DropdownMenuItem(value: 'Business', child: Text('تجاري')),
              ],
              onChanged: (v) => onAccountTypeChanged(v ?? 'Personal'),
            ),
          ),
          FormFieldRow(
            label: 'اسم الأب',
            child: TextFormField(controller: controllers['father_name']),
          ),
          FormFieldRow(
            label: 'الرقم الوطني',
            child: TextFormField(controller: controllers['national_id']),
          ),
          FormFieldRow(
            label: 'الجنسية',
            child: TextFormField(controller: controllers['nationality']),
          ),
          FormFieldRow(
            label: 'الدولة',
            child: TextFormField(controller: controllers['country']),
          ),
          FormFieldRow(
            label: 'المدينة',
            child: TextFormField(controller: controllers['city']),
          ),
          FormFieldRow(
            label: 'المنطقة / الحي',
            child: TextFormField(controller: controllers['district']),
          ),
          FormFieldRow(
            label: 'العنوان',
            child: TextFormField(controller: controllers['address']),
          ),
          FormFieldRow(
            label: 'المحافظة / الولاية',
            child: TextFormField(controller: controllers['state']),
          ),
          FormFieldRow(
            label: 'الرمز البريدي',
            child: TextFormField(controller: controllers['zip']),
          ),
          FormFieldRow(
            label: 'الإحداثيات',
            hint: 'lat,lng',
            child: TextFormField(controller: controllers['coordinates']),
          ),
          FormFieldRow(
            label: 'طريقة الدفع المفضلة',
            child: TextFormField(controller: controllers['payment_method']),
          ),
          FormFieldRow(
            label: 'مرجع الدفع',
            child: TextFormField(controller: controllers['payment_reference']),
          ),
        ],
      ),
    );
  }
}

/// Speed-override section (mirrors web "السرعة").
class SubscriberSpeedSection extends StatelessWidget {
  const SubscriberSpeedSection({
    super.key,
    required this.controllers,
    required this.bandwidthControlEnabled,
    required this.onBandwidthControlChanged,
    required this.customSpeed,
    required this.onCustomSpeedChanged,
    required this.temporarySpeed,
    required this.onTemporarySpeedChanged,
  });

  final Map<String, TextEditingController> controllers;
  final bool bandwidthControlEnabled;
  final ValueChanged<bool> onBandwidthControlChanged;
  final bool customSpeed;
  final ValueChanged<bool> onCustomSpeedChanged;
  final bool temporarySpeed;
  final ValueChanged<bool> onTemporarySpeedChanged;

  @override
  Widget build(BuildContext context) {
    return CollapsibleSection(
      storageKey: 'sub.speed',
      icon: Icons.speed_outlined,
      title: 'السرعة',
      initiallyExpanded: false,
      child: Column(
        children: [
          FormFieldRow(
            label: 'سرعة أساسية مخصّصة',
            hint: 'قيم ثابتة تتجاوز سرعة الباقة',
            child: HubToggleSwitch(
              value: bandwidthControlEnabled,
              onChanged: onBandwidthControlChanged,
            ),
          ),
          FormFieldRow(
            label: 'تفعيل السرعة المخصصة',
            hint: 'فعّلها لتطبيق سرعة خاصة بدل سرعة الباقة',
            child: HubToggleSwitch(
              value: customSpeed,
              onChanged: onCustomSpeedChanged,
            ),
          ),
          FormFieldRow(
            label: 'سرعة التنزيل (kbps)',
            hint: '0 = استخدم قيمة الباقة',
            child: _NumField(controller: controllers['download_speed_kbps']!),
          ),
          FormFieldRow(
            label: 'سرعة الرفع (kbps)',
            hint: '0 = استخدم قيمة الباقة',
            child: _NumField(controller: controllers['upload_speed_kbps']!),
          ),
          FormFieldRow(
            label: 'سرعة مؤقتة',
            hint: 'رفع مؤقت بدون تغيير الباقة',
            child: HubToggleSwitch(
              value: temporarySpeed,
              onChanged: onTemporarySpeedChanged,
            ),
          ),
        ],
      ),
    );
  }
}

/// Quota + connection-time limits section (mirrors web "الحصة والوقت").
class SubscriberQuotaSection extends StatelessWidget {
  const SubscriberQuotaSection({
    super.key,
    required this.controllers,
    required this.quotaLimitEnabled,
    required this.onQuotaLimitChanged,
    required this.connectionTimeLimitEnabled,
    required this.onConnectionTimeLimitChanged,
    required this.equalShareDownload,
    required this.onEqualShareDownloadChanged,
    required this.equalShareUpload,
    required this.onEqualShareUploadChanged,
  });

  final Map<String, TextEditingController> controllers;
  final bool quotaLimitEnabled;
  final ValueChanged<bool> onQuotaLimitChanged;
  final bool connectionTimeLimitEnabled;
  final ValueChanged<bool> onConnectionTimeLimitChanged;
  final bool equalShareDownload;
  final ValueChanged<bool> onEqualShareDownloadChanged;
  final bool equalShareUpload;
  final ValueChanged<bool> onEqualShareUploadChanged;

  @override
  Widget build(BuildContext context) {
    return CollapsibleSection(
      storageKey: 'sub.quota',
      icon: Icons.data_usage_outlined,
      title: 'الحصة والوقت',
      initiallyExpanded: false,
      child: Column(
        children: [
          FormFieldRow(
            label: 'كوتا مدمجة (MB)',
            hint: 'تحلّ محل كوتا التنزيل/الرفع. 0 = غير محدودة',
            child: _NumField(controller: controllers['combined_quota_mb']!),
          ),
          FormFieldRow(
            label: 'كوتا التنزيل (MB)',
            hint: '0 = غير محدودة',
            child: _NumField(controller: controllers['download_quota_mb']!),
          ),
          FormFieldRow(
            label: 'كوتا الرفع (MB)',
            hint: '0 = غير محدودة',
            child: _NumField(controller: controllers['upload_quota_mb']!),
          ),
          FormFieldRow(
            label: 'إجمالي وقت الاتصال (دقيقة)',
            hint: '0 = بلا حد',
            child:
                _NumField(controller: controllers['total_connection_time_min']!),
          ),
          FormFieldRow(
            label: 'وقت الاتصال اليومي (دقيقة)',
            hint: '0 = بلا حد',
            child:
                _NumField(controller: controllers['daily_connection_time_min']!),
          ),
          FormFieldRow(
            label: 'تطبيق حد الكوتا',
            child: HubToggleSwitch(
              value: quotaLimitEnabled,
              onChanged: onQuotaLimitChanged,
            ),
          ),
          FormFieldRow(
            label: 'تطبيق حد وقت الاتصال',
            child: HubToggleSwitch(
              value: connectionTimeLimitEnabled,
              onChanged: onConnectionTimeLimitChanged,
            ),
          ),
          FormFieldRow(
            label: 'توزيع متساوٍ للتنزيل',
            child: HubToggleSwitch(
              value: equalShareDownload,
              onChanged: onEqualShareDownloadChanged,
            ),
          ),
          FormFieldRow(
            label: 'توزيع متساوٍ للرفع',
            child: HubToggleSwitch(
              value: equalShareUpload,
              onChanged: onEqualShareUploadChanged,
            ),
          ),
        ],
      ),
    );
  }
}

/// PPPoE / broadband section (mirrors web "البرودباند").
class SubscriberPppoeSection extends StatelessWidget {
  const SubscriberPppoeSection({super.key, required this.controllers});

  final Map<String, TextEditingController> controllers;

  @override
  Widget build(BuildContext context) {
    return CollapsibleSection(
      storageKey: 'sub.pppoe',
      icon: Icons.cable_outlined,
      title: 'البرودباند (PPPoE)',
      initiallyExpanded: false,
      child: Column(
        children: [
          FormFieldRow(
            label: 'اسم دخول البرودباند',
            hint: 'اتركه فارغًا لاستخدام اسم الدخول الأساسي',
            child: TextFormField(controller: controllers['pppoe_username']),
          ),
          FormFieldRow(
            label: 'كلمة مرور البرودباند',
            hint: 'اتركها فارغة لاستخدام كلمة المرور الأساسية',
            child: TextFormField(
              controller: controllers['pppoe_password'],
              obscureText: true,
            ),
          ),
          FormFieldRow(
            label: 'عنوان البرودباند',
            child: TextFormField(controller: controllers['pppoe_ip']),
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
            child: TextFormField(controller: controllers['notes'], maxLines: 3),
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
