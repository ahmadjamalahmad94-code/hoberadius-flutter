import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/collapsible_section.dart';
import '../../../shared/widgets/form_field_row.dart';
import '../data/plans_repository.dart';
import '../domain/plan_model.dart';

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
  String _serviceType = 'hotspot';
  bool _notifyOnExpire = false;
  bool _notifyOnQuota = false;
  bool _autoRenew = false;
  final Set<String> _workingDays = {};
  bool _loading = false;
  String? _error;

  static const _daysAr = ['أحد', 'إثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة', 'سبت'];
  static const _daysKey = ['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'];

  @override
  void initState() {
    super.initState();
    _c = {
      for (final k in [
        'name', 'price_monthly', 'price_yearly', 'validity_days',
        'total_quota_mb', 'total_time_seconds',
        'download_kbps', 'upload_kbps',
        'cir_download_kbps', 'cir_upload_kbps',
        'burst_download_kbps', 'burst_upload_kbps',
        'burst_threshold_down', 'burst_threshold_up', 'burst_time',
        'mt_profile', 'mt_ip_pool', 'mt_rate_limit',
        'allowed_hours', 'notes', 'tags',
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
      final p = await ref.read(plansRepositoryProvider).get(widget.planId!);
      _populate(p);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _populate(Plan p) {
    _c['name']!.text = p.name;
    _c['price_monthly']!.text = p.priceMonthly.toString();
    _c['price_yearly']!.text = p.priceYearly.toString();
    _c['validity_days']!.text = p.validityDays?.toString() ?? '';
    _c['total_quota_mb']!.text = p.totalQuotaMb?.toString() ?? '';
    _c['total_time_seconds']!.text = p.totalTimeSeconds?.toString() ?? '';
    _c['download_kbps']!.text = p.downloadKbps?.toString() ?? '';
    _c['upload_kbps']!.text = p.uploadKbps?.toString() ?? '';
    _c['cir_download_kbps']!.text = p.cirDownloadKbps?.toString() ?? '';
    _c['cir_upload_kbps']!.text = p.cirUploadKbps?.toString() ?? '';
    _c['burst_download_kbps']!.text = p.burstDownloadKbps?.toString() ?? '';
    _c['burst_upload_kbps']!.text = p.burstUploadKbps?.toString() ?? '';
    _c['burst_threshold_down']!.text = p.burstThresholdDown?.toString() ?? '';
    _c['burst_threshold_up']!.text = p.burstThresholdUp?.toString() ?? '';
    _c['burst_time']!.text = p.burstTime?.toString() ?? '';
    _c['mt_profile']!.text = p.mtProfile;
    _c['mt_ip_pool']!.text = p.mtIpPool;
    _c['mt_rate_limit']!.text = p.mtRateLimit;
    _c['allowed_hours']!.text = p.allowedHours;
    _c['notes']!.text = p.notes;
    _c['tags']!.text = p.tags.join(', ');
    setState(() {
      _planType = p.planType;
      _serviceType = p.serviceType;
      _notifyOnExpire = p.notifyOnExpire;
      _notifyOnQuota = p.notifyOnQuota;
      _autoRenew = p.autoRenew;
      _workingDays
        ..clear()
        ..addAll(p.workingDays);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _error = 'هذه الواجهة جاهزة، لكن الـ endpoint POST /api/v1/profiles لم يُضَف بعد على Flask.';
    });
    // Placeholder until Flask exposes plan CUD over /api/v1/profiles.
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
                onPressed: () => context.goNamed('plans'),
                icon: const Icon(Icons.arrow_back),
              ),
              Text(
                widget.isEdit ? 'تعديل باقة' : 'باقة جديدة',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTokens.navy900,
                    ),
              ),
              const Spacer(),
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
                color: const Color(0xFFFFF1DF),
                borderRadius: BorderRadius.circular(AppTokens.r10),
              ),
              child: Text(_error!, style: const TextStyle(color: AppTokens.orange)),
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
                  label: 'اسم الباقة',
                  required: true,
                  child: TextFormField(
                    controller: _c['name'],
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                  ),
                ),
                FormFieldRow(
                  label: 'نوع الباقة',
                  child: DropdownButtonFormField<String>(
                    value: _planType,
                    items: const [
                      DropdownMenuItem(value: 'time', child: Text('وقت')),
                      DropdownMenuItem(value: 'quota', child: Text('حصة')),
                      DropdownMenuItem(value: 'mixed', child: Text('وقت وحصة')),
                      DropdownMenuItem(value: 'unlimited', child: Text('غير محدود')),
                    ],
                    onChanged: (v) => setState(() => _planType = v ?? 'time'),
                  ),
                ),
                FormFieldRow(
                  label: 'نوع الخدمة',
                  child: DropdownButtonFormField<String>(
                    value: _serviceType,
                    items: const [
                      DropdownMenuItem(value: 'hotspot', child: Text('هوتسبوت')),
                      DropdownMenuItem(value: 'pppoe', child: Text('PPPoE')),
                      DropdownMenuItem(value: 'voucher', child: Text('قسيمة')),
                      DropdownMenuItem(value: 'other', child: Text('أخرى')),
                    ],
                    onChanged: (v) => setState(() => _serviceType = v ?? 'hotspot'),
                  ),
                ),
                FormFieldRow(
                  label: 'السعر الشهري',
                  child: TextFormField(
                    controller: _c['price_monthly'],
                    keyboardType: TextInputType.number,
                  ),
                ),
                FormFieldRow(
                  label: 'السعر السنوي',
                  child: TextFormField(
                    controller: _c['price_yearly'],
                    keyboardType: TextInputType.number,
                  ),
                ),
                FormFieldRow(
                  label: 'صلاحية (أيام)',
                  child: TextFormField(
                    controller: _c['validity_days'],
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
            title: 'السرعة (CIR / Burst)',
            child: Column(
              children: [
                FormFieldRow(label: 'تنزيل (kbps)', child: TextFormField(controller: _c['download_kbps'], keyboardType: TextInputType.number)),
                FormFieldRow(label: 'رفع (kbps)', child: TextFormField(controller: _c['upload_kbps'], keyboardType: TextInputType.number)),
                FormFieldRow(label: 'CIR تنزيل', child: TextFormField(controller: _c['cir_download_kbps'], keyboardType: TextInputType.number)),
                FormFieldRow(label: 'CIR رفع', child: TextFormField(controller: _c['cir_upload_kbps'], keyboardType: TextInputType.number)),
                FormFieldRow(label: 'Burst تنزيل', child: TextFormField(controller: _c['burst_download_kbps'], keyboardType: TextInputType.number)),
                FormFieldRow(label: 'Burst رفع', child: TextFormField(controller: _c['burst_upload_kbps'], keyboardType: TextInputType.number)),
                FormFieldRow(label: 'حد Burst تنزيل', child: TextFormField(controller: _c['burst_threshold_down'], keyboardType: TextInputType.number)),
                FormFieldRow(label: 'حد Burst رفع', child: TextFormField(controller: _c['burst_threshold_up'], keyboardType: TextInputType.number)),
                FormFieldRow(label: 'زمن Burst', child: TextFormField(controller: _c['burst_time'], keyboardType: TextInputType.number)),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.s16),
          CollapsibleSection(
            storageKey: 'plan.quota',
            icon: Icons.data_usage,
            title: 'الحصة والوقت',
            initiallyExpanded: false,
            child: Column(
              children: [
                FormFieldRow(label: 'إجمالي الحصة (MB)', child: TextFormField(controller: _c['total_quota_mb'], keyboardType: TextInputType.number)),
                FormFieldRow(label: 'إجمالي الوقت (ث)', child: TextFormField(controller: _c['total_time_seconds'], keyboardType: TextInputType.number)),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.s16),
          CollapsibleSection(
            storageKey: 'plan.mt',
            icon: Icons.router_outlined,
            title: 'إعدادات الراوتر',
            initiallyExpanded: false,
            child: Column(
              children: [
                FormFieldRow(label: 'الـ profile', child: TextFormField(controller: _c['mt_profile'])),
                FormFieldRow(label: 'IP Pool', child: TextFormField(controller: _c['mt_ip_pool'])),
                FormFieldRow(label: 'Rate Limit', child: TextFormField(controller: _c['mt_rate_limit'])),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.s16),
          CollapsibleSection(
            storageKey: 'plan.notif',
            icon: Icons.notifications_outlined,
            title: 'التنبيهات',
            initiallyExpanded: false,
            child: Column(
              children: [
                FormFieldRow(
                  label: 'تنبيه عند الانتهاء',
                  child: Switch(
                    value: _notifyOnExpire,
                    onChanged: (v) => setState(() => _notifyOnExpire = v),
                  ),
                ),
                FormFieldRow(
                  label: 'تنبيه عند انتهاء الحصة',
                  child: Switch(
                    value: _notifyOnQuota,
                    onChanged: (v) => setState(() => _notifyOnQuota = v),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.s16),
          CollapsibleSection(
            storageKey: 'plan.advanced',
            icon: Icons.tune,
            title: 'متقدّم',
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
            storageKey: 'plan.general',
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
