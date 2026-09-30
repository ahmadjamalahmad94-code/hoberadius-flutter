import 'package:hoberadius_app/core/format/number_input.dart';
import 'package:hoberadius_app/core/format/money_limits.dart';
import 'package:hoberadius_app/core/format/input_rules.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_exception.dart';
import '../../../../core/auth/permissions.dart';
import '../../../../shared/widgets/collapsible_section.dart';
import '../../../../shared/widgets/form_field_row.dart';
import '../../../../shared/widgets/hub_time_picker_circular.dart';
import '../../../../shared/widgets/hub_switch_row.dart';
import '../../../../shared/widgets/wheel_picker_fields.dart';
import '../../../admins/data/admins_repository.dart';
import '../../domain/subscriber_model.dart';
import 'expire_picker.dart';
import 'plan_picker.dart';

/// Number-only text field used across the new parity sections: nothing
/// typed is stripped or rewritten; «7.5» in a whole-number field, «-1» or
/// «abc» show an Arabic error instead of being saved as 0.
class _NumField extends StatelessWidget {
  const _NumField({required this.controller});
  final TextEditingController controller;
  bool get decimal => false;
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: decimal ? decimalKeyboard : integerKeyboard,
      inputFormatters: numberFieldFormatters,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (v) =>
          validateNumberInput(v, required: false, decimal: decimal),
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
    this.onRename,
    this.fieldErrors = const {},
    this.explicitNoExpiry = false,
    this.onExplicitNoExpiryChanged,
  });

  /// Create form: «بدون انتهاء» chosen explicitly (`expire_at: null`).
  final bool explicitNoExpiry;
  final ValueChanged<bool>? onExplicitNoExpiryChanged;

  /// The server's Arabic message per field (422 mapped to its input).
  final Map<String, String> fieldErrors;

  /// Edit form: opens «تغيير اسم المستخدم» (the name is the RADIUS key and
  /// changes only through the rename cascade — typing here was dropped).
  final VoidCallback? onRename;

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
    final username = FormFieldRow(
      label: 'اسم المستخدم',
      required: true,
      child: TextFormField(
        controller: controllers['username'],
        // Edit: read-only + «إعادة تسمية» (a typed change was silently
        // dropped — r10 N7). Create: no silent cut at 64 characters, the
        // validator says why instead.
        readOnly: isEdit,
        textDirection: TextDirection.ltr,
        autovalidateMode: isEdit
            ? AutovalidateMode.disabled
            : AutovalidateMode.onUserInteraction,
        decoration: isEdit
            ? InputDecoration(
                errorText: fieldErrors['username'],
                helperText: 'لتغيير الاسم استخدم «إعادة تسمية».',
                suffixIcon: IconButton(
                  tooltip: 'إعادة تسمية',
                  icon: const Icon(Icons.drive_file_rename_outline, size: 20),
                  onPressed: onRename,
                ),
              )
            : InputDecoration(errorText: fieldErrors['username']),
        // Same rule as the rename dialog and the server: Latin letters,
        // digits and . _ - @ only, 3–64 characters.
        validator: (v) => isEdit
            ? null
            : ((v == null || v.trim().isEmpty)
                ? 'مطلوب'
                : validateNewSubscriberUsername(v)),
      ),
    );
    final fullName = FormFieldRow(
      label: 'الاسم الكامل',
      child: TextFormField(controller: controllers['full_name']),
    );
    return CollapsibleSection(
      storageKey: 'sub.core',
      icon: Icons.person_outline,
      title: 'البيانات الأساسية',
      child: Column(
        children: [
          // Short fields ride in pairs — the phone form was one tall column.
          if (isEdit)
            FormFieldPair(first: username, second: fullName)
          else ...[
            FormFieldPair(
              first: username,
              second: FormFieldRow(
                label: 'كلمة المرور',
                required: true,
                child: TextFormField(
                  controller: controllers['password'],
                  obscureText: true,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(kSubscriberPasswordMax),
                  ],
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'مطلوب'
                      : validateNewSubscriberPassword(v),
                ),
              ),
            ),
            fullName,
          ],
          FormFieldPair(
            first: FormFieldRow(
              label: 'الجوال',
              child: TextFormField(
                controller: controllers['mobile'],
                decoration: InputDecoration(errorText: fieldErrors['mobile']),
              ),
            ),
            second: FormFieldRow(
              label: 'البريد',
              child: TextFormField(
                controller: controllers['email'],
                keyboardType: TextInputType.emailAddress,
                textDirection: TextDirection.ltr,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: validateOptionalEmail,
                decoration: InputDecoration(errorText: fieldErrors['email']),
              ),
            ),
          ),
          FormFieldRow(
            label: 'مرجع المستفيد',
            child: TextFormField(controller: controllers['beneficiary_ref']),
          ),
          FormFieldPair(
            first: FormFieldRow(
              label: 'الحالة',
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: status,
                items: const [
                  DropdownMenuItem(value: 'enabled', child: Text('مفعّل')),
                  DropdownMenuItem(value: 'disabled', child: Text('معطّل')),
                  DropdownMenuItem(value: 'expired', child: Text('منتهي')),
                ],
                onChanged: (v) => onStatusChanged(v ?? 'enabled'),
              ),
            ),
            second: FormFieldRow(
              label: 'نوع المستخدم',
              child: DropdownButtonFormField<String>(
                isExpanded: true,
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
          ),
          FormFieldRow(
            label: 'الباقة',
            hint: 'اختر باقة من القائمة',
            child: PlanPicker(controller: controllers['plan_id']!),
          ),
          FormFieldPair(
            first: FormFieldRow(
              label: 'نوع الخدمة',
              // The server accepts hotspot / pppoe / both (fix2 subscriber
              // validation); an older stored value stays selectable so an
              // untouched row is not changed by opening it.
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue:
                    serviceType.trim().isEmpty ? 'Hotspot' : serviceType,
                items: [
                  for (final (value, label) in serviceTypeOptions(serviceType))
                    DropdownMenuItem(value: value, child: Text(label)),
                ],
                onChanged: (v) => onServiceTypeChanged(v ?? 'Hotspot'),
              ),
            ),
            second: FormFieldRow(
              label: 'السعر المخصص',
              child: TextFormField(
                controller: controllers['custom_price'],
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
                // The «leave empty» hint lives inside the field so the pair's
                // labels stay one line each.
                decoration: const InputDecoration(
                  hintText: 'فارغ = سعر الباقة',
                ),
              ),
            ),
          ),
          FormFieldRow(
            label: 'تاريخ الانتهاء',
            child: SubscriberExpiryField(
              isEdit: isEdit,
              value: expireAt,
              onChange: onExpireChanged,
              explicitNoExpiry: explicitNoExpiry,
              onExplicitNoExpiryChanged: onExplicitNoExpiryChanged,
              error: fieldErrors['expire_at'],
            ),
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
            label: 'ملف الراوتر (Profile)',
            child: TextFormField(controller: controllers['mt_profile']),
          ),
          FormFieldRow(
            label: 'الخدمة',
            child: DropdownButtonFormField<String>(
              isExpanded: true,
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
          FormFieldPair(
            first: FormFieldRow(
              label: 'خادم DNS الأول',
              child: TextFormField(controller: controllers['dns1']),
            ),
            second: FormFieldRow(
              label: 'خادم DNS الثاني',
              child: TextFormField(controller: controllers['dns2']),
            ),
          ),
          FormFieldRow(
            label: 'الجلسات المتزامنة',
            child: _NumField(controller: controllers['simultaneous_use']!),
          ),
          FormFieldPair(
            first: FormFieldRow(
              label: 'مهلة الجلسة (ث)',
              child: _NumField(controller: controllers['session_timeout']!),
            ),
            second: FormFieldRow(
              label: 'مهلة الخمول (ث)',
              child: _NumField(controller: controllers['idle_timeout']!),
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
          FormFieldPair(
            first: FormFieldRow(
              label: 'عدد الأجهزة المسموحة',
              hint: 'الحد الأقصى للجلسات المتزامنة',
              child: _NumField(controller: controllers['device_count']!),
            ),
            second: FormFieldRow(
              label: 'VLAN',
              child: _NumField(controller: controllers['vlan_id']!),
            ),
          ),
          FormFieldRow(
            label: 'ملف اتصال الجهاز',
            child: TextFormField(
              controller: controllers['device_connection_file'],
            ),
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
    this.isEdit = false,
  });

  final Map<String, TextEditingController> controllers;

  /// Edit mode shows the balance read-only: money changes go through the
  /// «إضافة رصيد» / «تسجيل دفعة» actions (with a ledger row), never a PATCH.
  final bool isEdit;
  final int? managerId;
  final ValueChanged<int?> onManagerChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // «المدير المسؤول» lists the managers (GET /api/v1/admins): only the
    // owner / a co-owner or an admin holding admins.view may read that list
    // — anyone else would get a 403, so the field is hidden and the server
    // assigns the subscriber to the manager who creates it (p01 D18).
    final showManager =
        canPickResponsibleManager(ref.watch(permissionsProvider));
    final admins = showManager ? ref.watch(adminsListProvider) : null;
    return CollapsibleSection(
      storageKey: 'sub.management',
      icon: Icons.manage_accounts_outlined,
      title: 'الإدارة والربط',
      initiallyExpanded: false,
      child: Column(
        children: [
          if (admins != null &&
              !(admins.hasError && _isForbidden(admins.error)))
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
                  isExpanded: true,
                  initialValue:
                      list.any((a) => a.id == managerId) ? managerId : null,
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
          FormFieldPair(
            first: FormFieldRow(
              label: 'المجموعة',
              hint: 'اسم مجموعة المشتركين',
              child: TextFormField(controller: controllers['group']),
            ),
            second: FormFieldRow(
              label: 'مجموعة العناوين (Pool)',
              child: TextFormField(controller: controllers['pool']),
            ),
          ),
          FormFieldRow(
            label: 'الرصيد',
            hint: isEdit
                ? 'للقراءة فقط — عدّله من إجراء «إضافة رصيد»'
                : 'يُضاف الرصيد بعد الإنشاء من إجراء «إضافة رصيد»',
            child: TextFormField(
              controller: controllers['balance'],
              readOnly: true,
              enabled: false,
              decoration: const InputDecoration(hintText: '0'),
            ),
          ),
        ],
      ),
    );
  }
}

/// The «المدير المسؤول» picker is offered (and its list fetched) only to
/// the owner / a co-owner or an admin holding `admins.view`. On an older
/// server (no permission contract) it stays, as before.
bool canPickResponsibleManager(AppPermissions p) =>
    p.isOwnerLike || p.can('admins.view');

bool _isForbidden(Object? e) => e is ApiException && e.status == 403;

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
              isExpanded: true,
              initialValue: accountType == 'Business' ? 'Business' : 'Personal',
              items: const [
                DropdownMenuItem(value: 'Personal', child: Text('شخصي')),
                DropdownMenuItem(value: 'Business', child: Text('تجاري')),
              ],
              onChanged: (v) => onAccountTypeChanged(v ?? 'Personal'),
            ),
          ),
          FormFieldPair(
            first: FormFieldRow(
              label: 'اسم الأب',
              child: TextFormField(controller: controllers['father_name']),
            ),
            second: FormFieldRow(
              label: 'الرقم الوطني',
              child: TextFormField(controller: controllers['national_id']),
            ),
          ),
          FormFieldPair(
            first: FormFieldRow(
              label: 'الجنسية',
              child: TextFormField(controller: controllers['nationality']),
            ),
            second: FormFieldRow(
              label: 'الدولة',
              child: TextFormField(controller: controllers['country']),
            ),
          ),
          FormFieldPair(
            first: FormFieldRow(
              label: 'المدينة',
              child: TextFormField(controller: controllers['city']),
            ),
            second: FormFieldRow(
              label: 'المنطقة / الحي',
              child: TextFormField(controller: controllers['district']),
            ),
          ),
          FormFieldRow(
            label: 'العنوان',
            child: TextFormField(controller: controllers['address']),
          ),
          FormFieldPair(
            first: FormFieldRow(
              label: 'المحافظة / الولاية',
              child: TextFormField(controller: controllers['state']),
            ),
            second: FormFieldRow(
              label: 'الرمز البريدي',
              child: TextFormField(controller: controllers['zip']),
            ),
          ),
          FormFieldRow(
            label: 'الإحداثيات',
            hint: 'lat,lng',
            child: TextFormField(controller: controllers['coordinates']),
          ),
          FormFieldPair(
            first: FormFieldRow(
              label: 'طريقة الدفع المفضلة',
              child: TextFormField(controller: controllers['payment_method']),
            ),
            second: FormFieldRow(
              label: 'مرجع الدفع',
              child:
                  TextFormField(controller: controllers['payment_reference']),
            ),
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
          HubSwitchRow(
            label: 'سرعة أساسية مخصّصة',
            subtitle: 'قيم ثابتة تتجاوز سرعة الباقة',
            value: bandwidthControlEnabled,
            onChanged: onBandwidthControlChanged,
            dense: true,
          ),
          HubSwitchRow(
            label: 'تفعيل السرعة المخصصة',
            subtitle: 'فعّلها لتطبيق سرعة خاصة بدل سرعة الباقة',
            value: customSpeed,
            onChanged: onCustomSpeedChanged,
            dense: true,
          ),
          FormFieldPair(
            first: FormFieldRow(
              label: 'سرعة التنزيل (kbps)',
              hint: '0 = استخدم قيمة الباقة',
              child: _NumField(controller: controllers['download_speed_kbps']!),
            ),
            second: FormFieldRow(
              label: 'سرعة الرفع (kbps)',
              hint: '0 = استخدم قيمة الباقة',
              child: _NumField(controller: controllers['upload_speed_kbps']!),
            ),
          ),
          // «سرعة مؤقتة» had no effect from this form (r02): a temporary
          // speed is an ACTION on the live session with an end time — it
          // lives in «المتصلون» → «سرعة مؤقتة», not in a saved switch.
          const _TempSpeedHint(),
        ],
      ),
    );
  }
}

/// Service types the server accepts (case-insensitively), and the
/// dropdown items for [current]: its stored spelling is kept (opening a row
/// never changes it), an older value (Balance/Voucher…) stays listed.
List<(String, String)> serviceTypeOptions(String current) {
  const canonical = [
    ('Hotspot', 'هوتسبوت'),
    ('PPPoE', 'PPPoE'),
    ('both', 'كلاهما'),
  ];
  final cur = current.trim();
  final out = <(String, String)>[];
  var matched = cur.isEmpty;
  for (final (v, label) in canonical) {
    if (!matched && v.toLowerCase() == cur.toLowerCase()) {
      out.add((current, label));
      matched = true;
    } else {
      out.add((v, label));
    }
  }
  if (!matched) out.add((current, legacyServiceTypeLabel(current)));
  return out;
}

/// Arabic label of an older stored service type.
String legacyServiceTypeLabel(String v) => switch (v.trim().toLowerCase()) {
      'balance' => 'رصيد (قديم)',
      'voucher' => 'كوبون (قديم)',
      'others' => 'أخرى (قديم)',
      'hotspot' => 'هوتسبوت',
      'pppoe' => 'PPPoE',
      _ => '$v (قديم)',
    };

class _TempSpeedHint extends StatelessWidget {
  const _TempSpeedHint();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        'السرعة المؤقتة تُطبَّق على الجلسة المتصلة من «المتصلون» ← '
        '«سرعة مؤقتة» (بمدّة بالدقائق أو الساعات أو الأيام).',
        style: Theme.of(context).textTheme.bodySmall,
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
          FormFieldPair(
            first: FormFieldRow(
              label: 'كوتا التنزيل (MB)',
              hint: '0 = غير محدودة',
              child: _NumField(controller: controllers['download_quota_mb']!),
            ),
            second: FormFieldRow(
              label: 'كوتا الرفع (MB)',
              hint: '0 = غير محدودة',
              child: _NumField(controller: controllers['upload_quota_mb']!),
            ),
          ),
          FormFieldPair(
            first: FormFieldRow(
              label: 'إجمالي وقت الاتصال (دقيقة)',
              hint: '0 = بلا حد',
              child: _NumField(
                controller: controllers['total_connection_time_min']!,
              ),
            ),
            second: FormFieldRow(
              label: 'وقت الاتصال اليومي (دقيقة)',
              hint: '0 = بلا حد',
              child: _NumField(
                controller: controllers['daily_connection_time_min']!,
              ),
            ),
          ),
          HubSwitchRow(
            label: 'تطبيق حد الكوتا',
            value: quotaLimitEnabled,
            onChanged: onQuotaLimitChanged,
            dense: true,
          ),
          HubSwitchRow(
            label: 'تطبيق حد وقت الاتصال',
            value: connectionTimeLimitEnabled,
            onChanged: onConnectionTimeLimitChanged,
            dense: true,
          ),
          HubSwitchRow(
            label: 'توزيع متساوٍ للتنزيل',
            value: equalShareDownload,
            onChanged: onEqualShareDownloadChanged,
            dense: true,
          ),
          HubSwitchRow(
            label: 'توزيع متساوٍ للرفع',
            value: equalShareUpload,
            onChanged: onEqualShareUploadChanged,
            dense: true,
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
          HubSwitchRow(
            label: 'تعطيل تلقائي بعد أول استخدام',
            value: disableOnFirstUse,
            onChanged: onDisableOnFirstUseChanged,
            dense: true,
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
          HubSwitchRow(
            label: 'تنبيه عند الدخول',
            value: notifyOnLogin,
            onChanged: onNotifyOnLoginChanged,
            dense: true,
          ),
          FormFieldPair(
            first: FormFieldRow(
              label: 'بريد التنبيهات',
              child: TextFormField(
                controller: controllers['notify_email'],
                keyboardType: TextInputType.emailAddress,
                textDirection: TextDirection.ltr,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: validateOptionalEmail,
              ),
            ),
            second: FormFieldRow(
              label: 'جوال التنبيهات',
              child: TextFormField(controller: controllers['notify_mobile']),
            ),
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
          FormFieldPair(
            first: FormFieldRow(
              label: 'نوع الاشتراك',
              child: DropdownButtonFormField<String>(
                isExpanded: true,
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
            second: FormFieldRow(
              label: 'مدّة الاشتراك (أيام)',
              child: _NumField(controller: controllers['subscription_days']!),
            ),
          ),
          HubSwitchRow(
            label: 'تجديد تلقائي',
            value: autoRenew,
            onChanged: onAutoRenewChanged,
            dense: true,
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
