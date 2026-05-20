import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/collapsible_section.dart';
import '../../../shared/widgets/form_field_row.dart';
import '../../plans/data/plans_repository.dart';
import '../../plans/domain/plan_model.dart';
import '../data/subscribers_repository.dart';
import '../domain/subscriber_model.dart';

final _plansForPickerProvider = FutureProvider.autoDispose<List<Plan>>((ref) {
  return ref.watch(plansRepositoryProvider).list();
});

class SubscriberFormScreen extends ConsumerStatefulWidget {
  const SubscriberFormScreen({super.key, this.username});
  final String? username;
  bool get isEdit => username != null;

  @override
  ConsumerState<SubscriberFormScreen> createState() => _SubscriberFormScreenState();
}

class _SubscriberFormScreenState extends ConsumerState<SubscriberFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _c;
  String _status = 'enabled';
  String _userType = 'subscriber';
  String _mtService = 'pppoe';
  String _subscriptionType = 'fixed';
  DateTime? _expireAt;
  final Set<String> _workingDays = {};
  bool _disableOnFirstUse = false;
  bool _notifyOnLogin = false;
  bool _autoRenew = false;
  bool _loading = false;
  String? _error;

  static const _daysAr = ['أحد', 'إثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة', 'سبت'];
  static const _daysKey = ['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'];

  @override
  void initState() {
    super.initState();
    _c = {
      for (final k in [
        'username', 'password', 'full_name', 'mobile', 'email', 'beneficiary_ref',
        'remark', 'mac_lock', 'static_ip', 'plan_id',
        'mt_profile', 'mt_rate_limit', 'mt_ip_pool', 'mt_comment',
        'dns1', 'dns2', 'simultaneous_use', 'session_timeout', 'idle_timeout',
        'called_station_id', 'allowed_hours',
        'notify_email', 'notify_mobile', 'subscription_days', 'notes', 'tags',
      ])
        k: TextEditingController(),
    };
    if (widget.isEdit) _loadExisting();
  }

  @override
  void dispose() {
    for (final ctrl in _c.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _loadExisting() async {
    setState(() => _loading = true);
    try {
      final s = await ref.read(subscribersRepositoryProvider).get(widget.username!);
      _populate(s);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _populate(Subscriber s) {
    _c['username']!.text = s.username;
    _c['full_name']!.text = s.fullName;
    _c['mobile']!.text = s.mobile;
    _c['email']!.text = s.email;
    _c['beneficiary_ref']!.text = s.beneficiaryRef;
    _c['remark']!.text = s.remark;
    _c['mac_lock']!.text = s.macLock;
    _c['static_ip']!.text = s.staticIp;
    _c['plan_id']!.text = s.planId?.toString() ?? '';
    _c['mt_profile']!.text = s.mtProfile;
    _c['mt_rate_limit']!.text = s.mtRateLimit;
    _c['mt_ip_pool']!.text = s.mtIpPool;
    _c['mt_comment']!.text = s.mtComment;
    _c['dns1']!.text = s.primaryDnsPpp;
    _c['dns2']!.text = s.secondaryDnsPpp;
    _c['simultaneous_use']!.text = s.overrideConcurrent.toString();
    _c['session_timeout']!.text = s.sessionTimeout?.toString() ?? '';
    _c['idle_timeout']!.text = s.idleTimeout?.toString() ?? '';
    _c['called_station_id']!.text = s.calledStationId;
    _c['allowed_hours']!.text = s.allowedHours;
    _c['notify_email']!.text = s.notifyEmail;
    _c['notify_mobile']!.text = s.notifyMobile;
    _c['subscription_days']!.text = s.subscriptionDays?.toString() ?? '';
    _c['notes']!.text = s.notes;
    _c['tags']!.text = s.tags.join(', ');
    setState(() {
      _status = s.status;
      _userType = s.userType;
      _mtService = s.mtService;
      _subscriptionType = s.subscriptionType;
      _expireAt = s.expireAt;
      _workingDays
        ..clear()
        ..addAll(s.workingDays);
      _disableOnFirstUse = s.disableOnFirstUse;
      _notifyOnLogin = s.notifyOnLogin;
      _autoRenew = s.autoRenewal;
    });
  }

  Subscriber _build() => Subscriber(
        username: _c['username']!.text.trim(),
        password: _c['password']!.text,
        fullName: _c['full_name']!.text.trim(),
        mobile: _c['mobile']!.text.trim(),
        email: _c['email']!.text.trim(),
        beneficiaryRef: _c['beneficiary_ref']!.text.trim(),
        planId: int.tryParse(_c['plan_id']!.text.trim()),
        status: _status,
        userType: _userType,
        expireAt: _expireAt,
        macLock: _c['mac_lock']!.text.trim(),
        staticIp: _c['static_ip']!.text.trim(),
        remark: _c['remark']!.text.trim(),
        primaryDnsPpp: _c['dns1']!.text.trim(),
        secondaryDnsPpp: _c['dns2']!.text.trim(),
        overrideConcurrent: int.tryParse(_c['simultaneous_use']!.text.trim()) ?? 0,
        workingDaysCsv: _workingDays.join(','),
        autoRenewal: _autoRenew,
        mtProfile: _c['mt_profile']!.text.trim(),
        mtService: _mtService,
        mtRateLimit: _c['mt_rate_limit']!.text.trim(),
        mtIpPool: _c['mt_ip_pool']!.text.trim(),
        mtComment: _c['mt_comment']!.text.trim(),
        sessionTimeout: int.tryParse(_c['session_timeout']!.text.trim()),
        idleTimeout: int.tryParse(_c['idle_timeout']!.text.trim()),
        calledStationId: _c['called_station_id']!.text.trim(),
        allowedHours: _c['allowed_hours']!.text.trim(),
        disableOnFirstUse: _disableOnFirstUse,
        notifyOnLogin: _notifyOnLogin,
        notifyEmail: _c['notify_email']!.text.trim(),
        notifyMobile: _c['notify_mobile']!.text.trim(),
        subscriptionType: _subscriptionType,
        subscriptionDays: int.tryParse(_c['subscription_days']!.text.trim()),
        notes: _c['notes']!.text.trim(),
        tags: _c['tags']!.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
      );

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final s = _build();
      final repo = ref.read(subscribersRepositoryProvider);
      if (widget.isEdit) {
        await repo.update(s);
      } else {
        await repo.create(s);
      }
      if (mounted) context.goNamed('subscribers');
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleStatus() async {
    final u = widget.username;
    if (u == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(subscribersRepositoryProvider);
      if (_status == 'disabled') {
        await repo.enable(u);
        setState(() => _status = 'enabled');
        _snack('تم التفعيل');
      } else {
        await repo.disable(u);
        setState(() => _status = 'disabled');
        _snack('تم التعطيل');
      }
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showExtendDialog() async {
    final ctrl = TextEditingController(text: '60');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تمديد الاشتراك'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'الدقائق',
            hintText: 'مثال: 1440 (يوم)',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('تمديد')),
        ],
      ),
    );
    if (ok != true) return;
    final mins = int.tryParse(ctrl.text.trim());
    if (mins == null || mins <= 0) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final newExpire = await ref.read(subscribersRepositoryProvider)
          .extendTime(widget.username!, mins);
      if (mounted) setState(() => _expireAt = newExpire);
      _snack('تم التمديد $mins دقيقة');
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showResetPwDialog() async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إعادة تعيين كلمة المرور'),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'كلمة المرور الجديدة'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('تعيين')),
        ],
      ),
    );
    if (ok != true) return;
    final pw = ctrl.text;
    if (pw.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(subscribersRepositoryProvider)
          .resetPassword(widget.username!, pw);
      _snack('تمّ تحديث كلمة المرور');
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showDeleteConfirm() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف المشترك'),
        content: Text('سيُحذف "${widget.username}" نهائيًا. متأكّد؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTokens.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(subscribersRepositoryProvider).delete(widget.username!);
      if (mounted) context.goNamed('subscribers');
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => context.goNamed('subscribers'),
                icon: const Icon(Icons.arrow_back),
              ),
              Expanded(
                child: Text(
                  widget.isEdit ? 'تعديل مشترك' : 'مشترك جديد',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppTokens.navy900,
                      ),
                ),
              ),
              if (_loading)
                const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              if (widget.isEdit) ...[
                const SizedBox(width: AppTokens.s8),
                OutlinedButton.icon(
                  onPressed: _loading
                      ? null
                      : () => context.goNamed(
                            'subscriber-finance',
                            pathParameters: {'username': widget.username!},
                          ),
                  icon: const Icon(Icons.account_balance_wallet_outlined),
                  label: const Text('الدفعات والسلف'),
                ),
                const SizedBox(width: AppTokens.s8),
                _ActionMenu(
                  isDisabled: _status == 'disabled',
                  onToggle: _loading ? null : _toggleStatus,
                  onExtend: _loading ? null : _showExtendDialog,
                  onResetPw: _loading ? null : _showResetPwDialog,
                  onDelete: _loading ? null : _showDeleteConfirm,
                ),
              ],
              const SizedBox(width: AppTokens.s8),
              ElevatedButton.icon(
                onPressed: _loading ? null : _submit,
                icon: const Icon(Icons.save_outlined),
                label: const Text('حفظ'),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: AppTokens.s12),
            Container(
              padding: const EdgeInsets.all(AppTokens.s12),
              decoration: BoxDecoration(
                color: const Color(0xFFFDE9E9),
                borderRadius: BorderRadius.circular(AppTokens.r10),
              ),
              child: Text(_error!, style: const TextStyle(color: AppTokens.red)),
            ),
          ],
          const SizedBox(height: AppTokens.s16),
          CollapsibleSection(
            storageKey: 'sub.core',
            icon: Icons.person_outline,
            title: 'البيانات الأساسية',
            child: Column(
              children: [
                FormFieldRow(
                  label: 'اسم المستخدم',
                  required: true,
                  child: TextFormField(
                    controller: _c['username'],
                    enabled: !widget.isEdit,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                  ),
                ),
                if (!widget.isEdit)
                  FormFieldRow(
                    label: 'كلمة المرور',
                    required: true,
                    child: TextFormField(
                      controller: _c['password'],
                      obscureText: true,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'مطلوب' : null,
                    ),
                  ),
                FormFieldRow(label: 'الاسم الكامل', child: TextFormField(controller: _c['full_name'])),
                FormFieldRow(label: 'الجوال', child: TextFormField(controller: _c['mobile'])),
                FormFieldRow(label: 'البريد', child: TextFormField(controller: _c['email'])),
                FormFieldRow(label: 'مرجع المستفيد', child: TextFormField(controller: _c['beneficiary_ref'])),
                FormFieldRow(
                  label: 'الحالة',
                  child: DropdownButtonFormField<String>(
                    initialValue: _status,
                    items: const [
                      DropdownMenuItem(value: 'enabled', child: Text('مفعّل')),
                      DropdownMenuItem(value: 'disabled', child: Text('معطّل')),
                      DropdownMenuItem(value: 'expired', child: Text('منتهي')),
                    ],
                    onChanged: (v) => setState(() => _status = v ?? 'enabled'),
                  ),
                ),
                FormFieldRow(
                  label: 'نوع المستخدم',
                  child: DropdownButtonFormField<String>(
                    initialValue: _userType,
                    items: const [
                      DropdownMenuItem(value: 'subscriber', child: Text('مشترك')),
                      DropdownMenuItem(value: 'card', child: Text('كرت')),
                      DropdownMenuItem(value: 'employee', child: Text('موظف')),
                    ],
                    onChanged: (v) => setState(() => _userType = v ?? 'subscriber'),
                  ),
                ),
                FormFieldRow(
                  label: 'الباقة',
                  hint: 'اختر باقة من القائمة',
                  child: _PlanPicker(
                    controller: _c['plan_id']!,
                  ),
                ),
                FormFieldRow(
                  label: 'تاريخ الانتهاء',
                  child: _ExpirePicker(
                    value: _expireAt,
                    onChange: (d) => setState(() => _expireAt = d),
                  ),
                ),
                FormFieldRow(label: 'ملاحظات', child: TextFormField(controller: _c['remark'], maxLines: 2)),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.s16),
          CollapsibleSection(
            storageKey: 'sub.mt',
            icon: Icons.router_outlined,
            title: 'إعدادات الراوتر (MikroTik / PPP)',
            child: Column(
              children: [
                FormFieldRow(label: 'الـ profile', child: TextFormField(controller: _c['mt_profile'])),
                FormFieldRow(
                  label: 'الخدمة',
                  child: DropdownButtonFormField<String>(
                    initialValue: _mtService,
                    items: const [
                      DropdownMenuItem(value: 'pppoe', child: Text('PPPoE')),
                      DropdownMenuItem(value: 'hotspot', child: Text('Hotspot')),
                      DropdownMenuItem(value: 'l2tp', child: Text('L2TP')),
                      DropdownMenuItem(value: 'pptp', child: Text('PPTP')),
                      DropdownMenuItem(value: 'sstp', child: Text('SSTP')),
                      DropdownMenuItem(value: 'static', child: Text('Static')),
                    ],
                    onChanged: (v) => setState(() => _mtService = v ?? 'pppoe'),
                  ),
                ),
                FormFieldRow(
                  label: 'Rate Limit',
                  hint: 'مثال: 5M/10M أو 5M/10M 6M/12M 4M/8M 30/30',
                  child: TextFormField(controller: _c['mt_rate_limit']),
                ),
                FormFieldRow(label: 'IP Pool', child: TextFormField(controller: _c['mt_ip_pool'])),
                FormFieldRow(label: 'تعليق', child: TextFormField(controller: _c['mt_comment'])),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.s16),
          CollapsibleSection(
            storageKey: 'sub.radius',
            icon: Icons.settings_ethernet,
            title: 'سمات RADIUS / DNS',
            child: Column(
              children: [
                FormFieldRow(label: 'DNS1', child: TextFormField(controller: _c['dns1'])),
                FormFieldRow(label: 'DNS2', child: TextFormField(controller: _c['dns2'])),
                FormFieldRow(
                  label: 'الجلسات المتزامنة',
                  child: TextFormField(
                    controller: _c['simultaneous_use'],
                    keyboardType: TextInputType.number,
                  ),
                ),
                FormFieldRow(
                  label: 'مهلة الجلسة (ث)',
                  child: TextFormField(
                    controller: _c['session_timeout'],
                    keyboardType: TextInputType.number,
                  ),
                ),
                FormFieldRow(
                  label: 'مهلة الخمول (ث)',
                  child: TextFormField(
                    controller: _c['idle_timeout'],
                    keyboardType: TextInputType.number,
                  ),
                ),
                FormFieldRow(label: 'Called-Station-Id', child: TextFormField(controller: _c['called_station_id'])),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.s16),
          CollapsibleSection(
            storageKey: 'sub.macip',
            icon: Icons.lock_outline,
            title: 'القفل: MAC / IP',
            initiallyExpanded: false,
            child: Column(
              children: [
                FormFieldRow(
                  label: 'قفل على MAC',
                  hint: 'AA:BB:CC:DD:EE:FF',
                  child: TextFormField(controller: _c['mac_lock']),
                ),
                FormFieldRow(label: 'IP ثابت', child: TextFormField(controller: _c['static_ip'])),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.s16),
          CollapsibleSection(
            storageKey: 'sub.advanced',
            icon: Icons.tune,
            title: 'إعدادات متقدّمة',
            initiallyExpanded: false,
            child: Column(
              children: [
                FormFieldRow(
                  label: 'ساعات السماح',
                  hint: 'مثال: 08:00-22:00',
                  child: TextFormField(controller: _c['allowed_hours']),
                ),
                FormFieldRow(
                  label: 'أيام العمل',
                  child: Wrap(
                    spacing: 6, runSpacing: 6,
                    children: List.generate(_daysAr.length, (i) {
                      final k = _daysKey[i];
                      final selected = _workingDays.contains(k);
                      return FilterChip(
                        label: Text(_daysAr[i]),
                        selected: selected,
                        onSelected: (v) => setState(() {
                          if (v) {
                            _workingDays.add(k);
                          } else {
                            _workingDays.remove(k);
                          }
                        }),
                      );
                    }),
                  ),
                ),
                FormFieldRow(
                  label: 'تعطيل تلقائي بعد أول استخدام',
                  child: Switch(
                    value: _disableOnFirstUse,
                    onChanged: (v) => setState(() => _disableOnFirstUse = v),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.s16),
          CollapsibleSection(
            storageKey: 'sub.notif',
            icon: Icons.notifications_outlined,
            title: 'التنبيهات',
            initiallyExpanded: false,
            child: Column(
              children: [
                FormFieldRow(
                  label: 'تنبيه عند الدخول',
                  child: Switch(
                    value: _notifyOnLogin,
                    onChanged: (v) => setState(() => _notifyOnLogin = v),
                  ),
                ),
                FormFieldRow(label: 'بريد التنبيهات', child: TextFormField(controller: _c['notify_email'])),
                FormFieldRow(label: 'جوال التنبيهات', child: TextFormField(controller: _c['notify_mobile'])),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.s16),
          CollapsibleSection(
            storageKey: 'sub.subscription',
            icon: Icons.subscriptions_outlined,
            title: 'الاشتراك',
            initiallyExpanded: false,
            child: Column(
              children: [
                FormFieldRow(
                  label: 'نوع الاشتراك',
                  child: DropdownButtonFormField<String>(
                    initialValue: _subscriptionType,
                    items: const [
                      DropdownMenuItem(value: 'fixed', child: Text('ثابت')),
                      DropdownMenuItem(value: 'rolling', child: Text('متجدّد')),
                      DropdownMenuItem(value: 'prepaid', child: Text('مدفوع مسبقًا')),
                    ],
                    onChanged: (v) => setState(() => _subscriptionType = v ?? 'fixed'),
                  ),
                ),
                FormFieldRow(
                  label: 'مدّة الاشتراك (أيام)',
                  child: TextFormField(
                    controller: _c['subscription_days'],
                    keyboardType: TextInputType.number,
                  ),
                ),
                FormFieldRow(
                  label: 'تجديد تلقائي',
                  child: Switch(
                    value: _autoRenew,
                    onChanged: (v) => setState(() => _autoRenew = v),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.s16),
          CollapsibleSection(
            storageKey: 'sub.general',
            icon: Icons.notes,
            title: 'عام',
            initiallyExpanded: false,
            child: Column(
              children: [
                FormFieldRow(label: 'ملاحظات', child: TextFormField(controller: _c['notes'], maxLines: 3)),
                FormFieldRow(
                  label: 'وسوم',
                  hint: 'قِيَم مفصولة بفواصل',
                  child: TextFormField(controller: _c['tags']),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.s40),
        ],
      ),
    );
  }
}

class _ExpirePicker extends StatelessWidget {
  const _ExpirePicker({required this.value, required this.onChange});
  final DateTime? value;
  final ValueChanged<DateTime?> onChange;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('yyyy-MM-dd');
    return Row(
      children: [
        Expanded(
          child: InputDecorator(
            decoration: const InputDecoration(),
            child: Text(value == null ? 'بدون انتهاء' : df.format(value!)),
          ),
        ),
        const SizedBox(width: AppTokens.s8),
        IconButton(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: value ?? DateTime.now().add(const Duration(days: 30)),
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
            );
            if (picked != null) onChange(picked);
          },
          icon: const Icon(Icons.calendar_today_outlined),
        ),
        if (value != null)
          IconButton(
            onPressed: () => onChange(null),
            icon: const Icon(Icons.clear),
          ),
      ],
    );
  }
}

/// Plan dropdown backed by /api/v1/profiles. Falls back to a plain numeric
/// text field if the list cannot load — admins keep working offline-friendly
/// instead of being blocked by a transient network error.
class _PlanPicker extends ConsumerWidget {
  const _PlanPicker({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_plansForPickerProvider);
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: LinearProgressIndicator(minHeight: 4),
      ),
      error: (e, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'معرّف الباقة (يدوي)',
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  size: 14, color: AppTokens.orange,),
              const SizedBox(width: 4),
              const Expanded(
                child: Text(
                  'تعذّر جلب قائمة الباقات — أدخل المعرّف يدويًا',
                  style: TextStyle(color: AppTokens.textMuted, fontSize: 12),
                ),
              ),
              TextButton(
                onPressed: () => ref.invalidate(_plansForPickerProvider),
                child: const Text('إعادة'),
              ),
            ],
          ),
        ],
      ),
      data: (plans) {
        if (plans.isEmpty) {
          return Row(
            children: [
              const Expanded(
                child: Text(
                  'لا توجد باقات بعد. أنشئ باقة من قسم الباقات.',
                  style: TextStyle(color: AppTokens.textMuted),
                ),
              ),
              TextButton.icon(
                onPressed: () => GoRouter.of(context).goNamed('plan-new'),
                icon: const Icon(Icons.add),
                label: const Text('إضافة'),
              ),
            ],
          );
        }
        final current = int.tryParse(controller.text.trim());
        final exists = plans.any((p) => p.id == current);
        return DropdownButtonFormField<int?>(
          initialValue: exists ? current : null,
          isExpanded: true,
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('— بدون باقة —'),
            ),
            ...plans.map(
              (p) => DropdownMenuItem<int?>(
                value: p.id,
                child: Text(
                  '${p.name}${p.code.isNotEmpty ? "  •  ${p.code}" : ""}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
          onChanged: (v) {
            controller.text = v?.toString() ?? '';
          },
        );
      },
    );
  }
}

class _ActionMenu extends StatelessWidget {
  const _ActionMenu({
    required this.isDisabled,
    required this.onToggle,
    required this.onExtend,
    required this.onResetPw,
    required this.onDelete,
  });

  final bool isDisabled;
  final VoidCallback? onToggle;
  final VoidCallback? onExtend;
  final VoidCallback? onResetPw;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'إجراءات',
      icon: const Icon(Icons.more_vert),
      onSelected: (v) {
        switch (v) {
          case 'toggle': onToggle?.call();
          case 'extend': onExtend?.call();
          case 'reset': onResetPw?.call();
          case 'delete': onDelete?.call();
        }
      },
      itemBuilder: (ctx) => [
        PopupMenuItem(
          value: 'toggle',
          child: Row(children: [
            Icon(isDisabled ? Icons.check_circle_outline : Icons.block,
                size: 18, color: isDisabled ? AppTokens.green : AppTokens.orange,),
            const SizedBox(width: 8),
            Text(isDisabled ? 'تفعيل' : 'تعطيل'),
          ],),
        ),
        const PopupMenuItem(
          value: 'extend',
          child: Row(children: [
            Icon(Icons.timer_outlined, size: 18, color: AppTokens.cyan500),
            SizedBox(width: 8),
            Text('تمديد الوقت'),
          ],),
        ),
        const PopupMenuItem(
          value: 'reset',
          child: Row(children: [
            Icon(Icons.password, size: 18, color: AppTokens.navy700),
            SizedBox(width: 8),
            Text('إعادة كلمة المرور'),
          ],),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          child: Row(children: [
            Icon(Icons.delete_outline, size: 18, color: AppTokens.red),
            SizedBox(width: 8),
            Text('حذف', style: TextStyle(color: AppTokens.red)),
          ],),
        ),
      ],
    );
  }
}
