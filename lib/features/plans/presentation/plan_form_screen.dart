import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/collapsible_section.dart';
import '../../../shared/widgets/form_field_row.dart';
import '../../../shared/widgets/page_header.dart';
import '../data/plans_repository.dart';
import '../domain/plan_model.dart';
import 'plans_list_screen.dart';

class PlanFormScreen extends ConsumerStatefulWidget {
  const PlanFormScreen({super.key, this.planId});
  final int? planId;
  bool get isEdit => planId != null;

  @override
  ConsumerState<PlanFormScreen> createState() => _PlanFormScreenState();
}

class _PlanFormScreenState extends ConsumerState<PlanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _c;
  String _planType = 'time';
  String _serviceType = 'Hotspot';
  bool _enabled = true;
  bool _autoRenew = false;
  bool _speedControl = false;
  bool _burstEnabled = false;
  bool _nightlyUnlimited = false;
  bool _hotspotEnabled = false;
  bool _pppEnabled = false;
  bool _bindMac = false;
  bool _bindIp = false;
  bool _singleUseOnce = false;
  bool _prepaid = true;
  String _planTier = 'Personal';
  final Set<String> _allowedDays = {
    'sun',
    'mon',
    'tue',
    'wed',
    'thu',
    'fri',
    'sat',
  };

  bool _loading = false;
  String? _error;
  Plan? _loaded;

  static const _daysAr = [
    'أحد',
    'إثنين',
    'ثلاثاء',
    'أربعاء',
    'خميس',
    'جمعة',
    'سبت',
  ];
  static const _daysKey = ['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'];

  // The fields below are surfaced in the form. Anything not listed here
  // stays at its default (or, in edit mode, at its previously-saved value
  // from `_loaded`) so we never lose server-side state on PATCH.
  static const _fields = <String>[
    'name',
    'code',
    'description',
    'color',
    'priority',
    'validity_days',
    'duration_minutes',
    'session_timeout_sec',
    'idle_timeout_sec',
    'quota_total_mb',
    'quota_daily_mb',
    'quota_monthly_mb',
    'speed_down_kbps',
    'speed_up_kbps',
    'cir_down_kbps',
    'cir_up_kbps',
    'burst_down_kbps',
    'burst_up_kbps',
    'burst_threshold_kbps',
    'burst_time_sec',
    'concurrent_sessions',
    'address_pool',
    'framed_pool',
    'vlan_id',
    'allowed_hours_from',
    'allowed_hours_to',
    'price',
    'currency',
  ];

  @override
  void initState() {
    super.initState();
    _c = {for (final k in _fields) k: TextEditingController()};
    _c['currency']!.text = 'JOD';
    _c['color']!.text = '#2BAACC';
    _c['concurrent_sessions']!.text = '1';
    _c['priority']!.text = '100';
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
      final p = await ref.read(plansRepositoryProvider).get(widget.planId!);
      _populate(p);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _populate(Plan p) {
    _loaded = p;
    _c['name']!.text = p.name;
    _c['code']!.text = p.code;
    _c['description']!.text = p.description;
    _c['color']!.text = p.color;
    _c['priority']!.text = p.priority.toString();
    _c['validity_days']!.text = p.validityDays.toString();
    _c['duration_minutes']!.text = p.durationMinutes.toString();
    _c['session_timeout_sec']!.text = p.sessionTimeoutSec.toString();
    _c['idle_timeout_sec']!.text = p.idleTimeoutSec.toString();
    _c['quota_total_mb']!.text = p.quotaTotalMb.toString();
    _c['quota_daily_mb']!.text = p.quotaDailyMb.toString();
    _c['quota_monthly_mb']!.text = p.quotaMonthlyMb.toString();
    _c['speed_down_kbps']!.text = p.speedDownKbps.toString();
    _c['speed_up_kbps']!.text = p.speedUpKbps.toString();
    _c['cir_down_kbps']!.text = p.cirDownKbps.toString();
    _c['cir_up_kbps']!.text = p.cirUpKbps.toString();
    _c['burst_down_kbps']!.text = p.burstDownKbps.toString();
    _c['burst_up_kbps']!.text = p.burstUpKbps.toString();
    _c['burst_threshold_kbps']!.text = p.burstThresholdKbps.toString();
    _c['burst_time_sec']!.text = p.burstTimeSec.toString();
    _c['concurrent_sessions']!.text = p.concurrentSessions.toString();
    _c['address_pool']!.text = p.addressPool;
    _c['framed_pool']!.text = p.framedPool;
    _c['vlan_id']!.text = p.vlanId.toString();
    _c['allowed_hours_from']!.text = p.allowedHoursFrom;
    _c['allowed_hours_to']!.text = p.allowedHoursTo;
    _c['price']!.text = p.price.toString();
    _c['currency']!.text = p.currency;
    setState(() {
      _planType = p.planType;
      _serviceType = p.serviceType;
      _enabled = p.enabled;
      _autoRenew = p.autoRenew;
      _speedControl = p.speedControlEnabled;
      _burstEnabled = p.burstEnabled;
      _nightlyUnlimited = p.nightlyUnlimitedEnabled;
      _hotspotEnabled = p.hotspotEnabled;
      _pppEnabled = p.pppEnabled;
      _bindMac = p.bindMac;
      _bindIp = p.bindIp;
      _singleUseOnce = p.singleUseOnce;
      _prepaid = p.prepaid;
      _planTier = p.planTier;
      _allowedDays
        ..clear()
        ..addAll(p.allowedDays.isEmpty ? _daysKey : p.allowedDays);
    });
  }

  int _i(String key) => int.tryParse(_c[key]!.text.trim()) ?? 0;
  num _n(String key) => num.tryParse(_c[key]!.text.trim()) ?? 0;
  String _s(String key) => _c[key]!.text.trim();

  Plan _build() {
    final base = _loaded ?? Plan(name: '');
    return base.copyWith(
      name: _s('name'),
      code: _s('code'),
      planType: _planType,
      serviceType: _serviceType,
      description: _s('description'),
      color: _s('color'),
      enabled: _enabled,
      priority: _i('priority'),
      durationMinutes: _i('duration_minutes'),
      validityDays: _i('validity_days'),
      sessionTimeoutSec: _i('session_timeout_sec'),
      idleTimeoutSec: _i('idle_timeout_sec'),
      quotaTotalMb: _i('quota_total_mb'),
      quotaDailyMb: _i('quota_daily_mb'),
      quotaMonthlyMb: _i('quota_monthly_mb'),
      speedDownKbps: _i('speed_down_kbps'),
      speedUpKbps: _i('speed_up_kbps'),
      speedControlEnabled: _speedControl,
      cirDownKbps: _i('cir_down_kbps'),
      cirUpKbps: _i('cir_up_kbps'),
      burstEnabled: _burstEnabled,
      burstDownKbps: _i('burst_down_kbps'),
      burstUpKbps: _i('burst_up_kbps'),
      burstThresholdKbps: _i('burst_threshold_kbps'),
      burstTimeSec: _i('burst_time_sec'),
      nightlyUnlimitedEnabled: _nightlyUnlimited,
      concurrentSessions: _i('concurrent_sessions').clamp(1, 1000),
      addressPool: _s('address_pool'),
      framedPool: _s('framed_pool'),
      vlanId: _i('vlan_id'),
      allowedDays: _allowedDays.isEmpty ? _daysKey : _allowedDays.toList(),
      allowedHoursFrom: _s('allowed_hours_from'),
      allowedHoursTo: _s('allowed_hours_to'),
      price: _n('price'),
      currency: _s('currency').isEmpty ? 'JOD' : _s('currency'),
      planTier: _planTier,
      prepaid: _prepaid,
      autoRenew: _autoRenew,
      singleUseOnce: _singleUseOnce,
      hotspotEnabled: _hotspotEnabled,
      pppEnabled: _pppEnabled,
      bindMac: _bindMac,
      bindIp: _bindIp,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final plan = _build();
      final repo = ref.read(plansRepositoryProvider);
      if (widget.isEdit) {
        await repo.update(widget.planId!, plan);
      } else {
        await repo.create(plan);
      }
      ref.invalidate(plansListProvider);
      if (mounted) context.goNamed('plans');
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الباقة'),
        content: Text('سيُحذف "${_c['name']!.text}" نهائيًا. متأكّد؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
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
      await ref.read(plansRepositoryProvider).delete(widget.planId!);
      ref.invalidate(plansListProvider);
      if (mounted) context.goNamed('plans');
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            title: widget.isEdit ? 'تعديل باقة' : 'باقة جديدة',
            leading: IconButton(
              onPressed: () => context.goNamed('plans'),
              icon: const Icon(Icons.arrow_back),
            ),
            actions: [
              if (_loading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              if (widget.isEdit)
                IconButton(
                  tooltip: 'أرشفة الباقة',
                  onPressed: _loading ? null : _delete,
                  icon: const Icon(Icons.delete_outline, color: AppTokens.red),
                ),
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
              child:
                  Text(_error!, style: const TextStyle(color: AppTokens.red)),
            ),
          ],
          const SizedBox(height: AppTokens.s16),
          CollapsibleSection(
            storageKey: 'plan.core',
            icon: Icons.workspace_premium_outlined,
            title: 'البيانات الأساسية',
            child: Column(
              children: [
                FormFieldRow(
                  label: 'الاسم',
                  required: true,
                  child: TextFormField(
                    controller: _c['name'],
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                  ),
                ),
                FormFieldRow(
                  label: 'الكود',
                  hint: 'معرّف داخلي اختياري',
                  child: TextFormField(controller: _c['code']),
                ),
                FormFieldRow(
                  label: 'نوع الباقة',
                  child: DropdownButtonFormField<String>(
                    initialValue: _planType,
                    items: const [
                      DropdownMenuItem(value: 'time', child: Text('وقت')),
                      DropdownMenuItem(value: 'quota', child: Text('حصة')),
                      DropdownMenuItem(
                        value: 'hybrid',
                        child: Text('وقت وحصة'),
                      ),
                      DropdownMenuItem(
                        value: 'unlimited',
                        child: Text('غير محدود'),
                      ),
                      DropdownMenuItem(
                        value: 'recurring',
                        child: Text('متجدّد'),
                      ),
                    ],
                    onChanged: (v) => setState(() => _planType = v ?? 'time'),
                  ),
                ),
                FormFieldRow(
                  label: 'نوع الخدمة',
                  child: DropdownButtonFormField<String>(
                    initialValue: _serviceType,
                    items: const [
                      DropdownMenuItem(
                        value: 'Hotspot',
                        child: Text('هوتسبوت'),
                      ),
                      DropdownMenuItem(
                        value: 'PPPoE',
                        child: Text('اتصال PPPoE'),
                      ),
                      DropdownMenuItem(value: 'Balance', child: Text('رصيد')),
                      DropdownMenuItem(value: 'Voucher', child: Text('قسيمة')),
                      DropdownMenuItem(value: 'Others', child: Text('أخرى')),
                    ],
                    onChanged: (v) =>
                        setState(() => _serviceType = v ?? 'Hotspot'),
                  ),
                ),
                FormFieldRow(
                  label: 'الأولوية',
                  hint: 'الأقل = الأعلى أولوية',
                  child: TextFormField(
                    controller: _c['priority'],
                    keyboardType: TextInputType.number,
                  ),
                ),
                FormFieldRow(
                  label: 'مفعّلة',
                  child: Switch(
                    value: _enabled,
                    onChanged: (v) => setState(() => _enabled = v),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.s16),
          CollapsibleSection(
            storageKey: 'plan.time',
            icon: Icons.timer_outlined,
            title: 'الوقت والصلاحية',
            child: Column(
              children: [
                FormFieldRow(
                  label: 'الصلاحية (أيام)',
                  child: TextFormField(
                    controller: _c['validity_days'],
                    keyboardType: TextInputType.number,
                  ),
                ),
                FormFieldRow(
                  label: 'مدّة الاتصال (دقائق)',
                  hint: '0 = لا حدّ',
                  child: TextFormField(
                    controller: _c['duration_minutes'],
                    keyboardType: TextInputType.number,
                  ),
                ),
                FormFieldRow(
                  label: 'مهلة الجلسة (ث)',
                  child: TextFormField(
                    controller: _c['session_timeout_sec'],
                    keyboardType: TextInputType.number,
                  ),
                ),
                FormFieldRow(
                  label: 'مهلة الخمول (ث)',
                  child: TextFormField(
                    controller: _c['idle_timeout_sec'],
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.s16),
          CollapsibleSection(
            storageKey: 'plan.quota',
            icon: Icons.data_usage,
            title: 'الحصة',
            initiallyExpanded: false,
            child: Column(
              children: [
                FormFieldRow(
                  label: 'الإجمالي (MB)',
                  child: TextFormField(
                    controller: _c['quota_total_mb'],
                    keyboardType: TextInputType.number,
                  ),
                ),
                FormFieldRow(
                  label: 'يومي (MB)',
                  child: TextFormField(
                    controller: _c['quota_daily_mb'],
                    keyboardType: TextInputType.number,
                  ),
                ),
                FormFieldRow(
                  label: 'شهري (MB)',
                  child: TextFormField(
                    controller: _c['quota_monthly_mb'],
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.s16),
          CollapsibleSection(
            storageKey: 'plan.speed',
            icon: Icons.speed,
            title: 'السرعة والتحكم المتقدم',
            child: Column(
              children: [
                FormFieldRow(
                  label: 'تنزيل (kbps)',
                  child: TextFormField(
                    controller: _c['speed_down_kbps'],
                    keyboardType: TextInputType.number,
                  ),
                ),
                FormFieldRow(
                  label: 'رفع (kbps)',
                  child: TextFormField(
                    controller: _c['speed_up_kbps'],
                    keyboardType: TextInputType.number,
                  ),
                ),
                FormFieldRow(
                  label: 'تفعيل التحكم بالسرعة',
                  child: Switch(
                    value: _speedControl,
                    onChanged: (v) => setState(() => _speedControl = v),
                  ),
                ),
                FormFieldRow(
                  label: 'الحد الأدنى للتنزيل',
                  child: TextFormField(
                    controller: _c['cir_down_kbps'],
                    keyboardType: TextInputType.number,
                  ),
                ),
                FormFieldRow(
                  label: 'الحد الأدنى للرفع',
                  child: TextFormField(
                    controller: _c['cir_up_kbps'],
                    keyboardType: TextInputType.number,
                  ),
                ),
                FormFieldRow(
                  label: 'تفعيل دفعة السرعة المؤقتة',
                  child: Switch(
                    value: _burstEnabled,
                    onChanged: (v) => setState(() => _burstEnabled = v),
                  ),
                ),
                FormFieldRow(
                  label: 'دفعة تنزيل مؤقتة',
                  child: TextFormField(
                    controller: _c['burst_down_kbps'],
                    keyboardType: TextInputType.number,
                  ),
                ),
                FormFieldRow(
                  label: 'دفعة رفع مؤقتة',
                  child: TextFormField(
                    controller: _c['burst_up_kbps'],
                    keyboardType: TextInputType.number,
                  ),
                ),
                FormFieldRow(
                  label: 'حد دفعة السرعة',
                  child: TextFormField(
                    controller: _c['burst_threshold_kbps'],
                    keyboardType: TextInputType.number,
                  ),
                ),
                FormFieldRow(
                  label: 'مدة دفعة السرعة (ثانية)',
                  child: TextFormField(
                    controller: _c['burst_time_sec'],
                    keyboardType: TextInputType.number,
                  ),
                ),
                FormFieldRow(
                  label: 'ليلي بلا حدود',
                  child: Switch(
                    value: _nightlyUnlimited,
                    onChanged: (v) => setState(() => _nightlyUnlimited = v),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.s16),
          CollapsibleSection(
            storageKey: 'plan.session',
            icon: Icons.lan_outlined,
            title: 'الجلسات والشبكة',
            initiallyExpanded: false,
            child: Column(
              children: [
                FormFieldRow(
                  label: 'الجلسات المتزامنة',
                  child: TextFormField(
                    controller: _c['concurrent_sessions'],
                    keyboardType: TextInputType.number,
                  ),
                ),
                FormFieldRow(
                  label: 'مجموعة عناوين IP',
                  child: TextFormField(controller: _c['address_pool']),
                ),
                FormFieldRow(
                  label: 'مجموعة الاتصال',
                  child: TextFormField(controller: _c['framed_pool']),
                ),
                FormFieldRow(
                  label: 'معرّف VLAN',
                  child: TextFormField(
                    controller: _c['vlan_id'],
                    keyboardType: TextInputType.number,
                  ),
                ),
                FormFieldRow(
                  label: 'قفل على MAC',
                  child: Switch(
                    value: _bindMac,
                    onChanged: (v) => setState(() => _bindMac = v),
                  ),
                ),
                FormFieldRow(
                  label: 'قفل على IP',
                  child: Switch(
                    value: _bindIp,
                    onChanged: (v) => setState(() => _bindIp = v),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.s16),
          CollapsibleSection(
            storageKey: 'plan.window',
            icon: Icons.event_available_outlined,
            title: 'نافذة العمل',
            initiallyExpanded: false,
            child: Column(
              children: [
                FormFieldRow(
                  label: 'أيام مسموح بها',
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: List.generate(_daysAr.length, (i) {
                      final k = _daysKey[i];
                      final selected = _allowedDays.contains(k);
                      return FilterChip(
                        label: Text(_daysAr[i]),
                        selected: selected,
                        onSelected: (v) => setState(() {
                          if (v) {
                            _allowedDays.add(k);
                          } else {
                            _allowedDays.remove(k);
                          }
                        }),
                      );
                    }),
                  ),
                ),
                FormFieldRow(
                  label: 'من الساعة',
                  hint: 'مثال: 08:00',
                  child: TextFormField(controller: _c['allowed_hours_from']),
                ),
                FormFieldRow(
                  label: 'حتى الساعة',
                  hint: 'مثال: 22:00',
                  child: TextFormField(controller: _c['allowed_hours_to']),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.s16),
          CollapsibleSection(
            storageKey: 'plan.commerce',
            icon: Icons.payments_outlined,
            title: 'تجاري',
            initiallyExpanded: false,
            child: Column(
              children: [
                FormFieldRow(
                  label: 'السعر',
                  child: TextFormField(
                    controller: _c['price'],
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                FormFieldRow(
                  label: 'العملة',
                  child: TextFormField(controller: _c['currency']),
                ),
                FormFieldRow(
                  label: 'الفئة',
                  child: DropdownButtonFormField<String>(
                    initialValue: _planTier,
                    items: const [
                      DropdownMenuItem(value: 'Personal', child: Text('شخصي')),
                      DropdownMenuItem(value: 'Business', child: Text('تجاري')),
                    ],
                    onChanged: (v) =>
                        setState(() => _planTier = v ?? 'Personal'),
                  ),
                ),
                FormFieldRow(
                  label: 'مدفوع مسبقًا',
                  child: Switch(
                    value: _prepaid,
                    onChanged: (v) => setState(() => _prepaid = v),
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
            storageKey: 'plan.services',
            icon: Icons.toggle_on_outlined,
            title: 'الخدمات',
            initiallyExpanded: false,
            child: Column(
              children: [
                FormFieldRow(
                  label: 'هوتسبوت',
                  child: Switch(
                    value: _hotspotEnabled,
                    onChanged: (v) => setState(() => _hotspotEnabled = v),
                  ),
                ),
                FormFieldRow(
                  label: 'اتصال PPPoE',
                  child: Switch(
                    value: _pppEnabled,
                    onChanged: (v) => setState(() => _pppEnabled = v),
                  ),
                ),
                FormFieldRow(
                  label: 'استخدام واحد فقط',
                  child: Switch(
                    value: _singleUseOnce,
                    onChanged: (v) => setState(() => _singleUseOnce = v),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.s16),
          CollapsibleSection(
            storageKey: 'plan.meta',
            icon: Icons.notes,
            title: 'وصف ولون',
            initiallyExpanded: false,
            child: Column(
              children: [
                FormFieldRow(
                  label: 'الوصف',
                  child:
                      TextFormField(controller: _c['description'], maxLines: 3),
                ),
                FormFieldRow(
                  label: 'لون',
                  hint: 'hex مثال: #2BAACC',
                  child: TextFormField(controller: _c['color']),
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
