import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/page_header.dart';
import '../../admin_control/application/admin_control_providers.dart';
import '../application/plan_form_controller.dart';
import '../application/plan_form_mapper.dart';
import 'widgets/plan_form_dialogs.dart';
import 'widgets/plan_form_sections.dart';

/// Plan create / edit form. Text controllers + selections live here;
/// async actions go through [planFormActionProvider]; sections render
/// the long set of fields.
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
  bool _loanEnabled = false;
  bool _speedOverrideAllowed = false;
  bool _forceMacAddress = false;
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

  // Form fields not listed here keep their default (or, in edit mode,
  // their previously-saved value via `_loaded`) so we never lose
  // server-side state on PATCH.
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
    'daily_download_quota_mb',
    'daily_upload_quota_mb',
    'daily_combined_quota_mb',
    'monthly_download_quota_mb',
    'monthly_upload_quota_mb',
    'monthly_combined_quota_mb',
    'max_loan_minutes',
    'allowed_devices_count',
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

  // Used to preserve fields not surfaced in the form on PATCH.
  dynamic _loaded;

  @override
  void initState() {
    super.initState();
    _c = {for (final k in _fields) k: TextEditingController()};
    _c['currency']!.text = ref.read(tenantCurrencyProvider);
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

  PlanFormSelections get _selections => PlanFormSelections(
        planType: _planType,
        serviceType: _serviceType,
        enabled: _enabled,
        autoRenew: _autoRenew,
        speedControl: _speedControl,
        burstEnabled: _burstEnabled,
        nightlyUnlimited: _nightlyUnlimited,
        hotspotEnabled: _hotspotEnabled,
        pppEnabled: _pppEnabled,
        bindMac: _bindMac,
        bindIp: _bindIp,
        singleUseOnce: _singleUseOnce,
        prepaid: _prepaid,
        planTier: _planTier,
        allowedDays: _allowedDays,
        loanEnabled: _loanEnabled,
        speedOverrideAllowed: _speedOverrideAllowed,
        forceMacAddress: _forceMacAddress,
      );

  Future<void> _loadExisting() async {
    final result = await ref
        .read(planFormActionProvider.notifier)
        .load(widget.planId!);
    if (!mounted || result.plan == null) return;
    _loaded = result.plan;
    applyPlanToForm(result.plan!, _c);
    final sel = selectionsFromPlan(result.plan!);
    setState(() {
      _planType = sel.planType;
      _serviceType = sel.serviceType;
      _enabled = sel.enabled;
      _autoRenew = sel.autoRenew;
      _speedControl = sel.speedControl;
      _burstEnabled = sel.burstEnabled;
      _nightlyUnlimited = sel.nightlyUnlimited;
      _hotspotEnabled = sel.hotspotEnabled;
      _pppEnabled = sel.pppEnabled;
      _bindMac = sel.bindMac;
      _bindIp = sel.bindIp;
      _singleUseOnce = sel.singleUseOnce;
      _prepaid = sel.prepaid;
      _loanEnabled = sel.loanEnabled;
      _speedOverrideAllowed = sel.speedOverrideAllowed;
      _forceMacAddress = sel.forceMacAddress;
      _planTier = sel.planTier;
      _allowedDays
        ..clear()
        ..addAll(sel.allowedDays);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final plan = buildPlanFromForm(_c, _selections, base: _loaded);
    final err = await ref
        .read(planFormActionProvider.notifier)
        .submit(plan, id: widget.planId);
    if (!mounted || err != null) return;
    context.goNamed('plans');
  }

  Future<void> _delete() async {
    final ok = await confirmDeletePlan(context, _c['name']!.text);
    if (!mounted || !ok) return;
    final err = await ref
        .read(planFormActionProvider.notifier)
        .delete(widget.planId!);
    if (!mounted || err != null) return;
    context.goNamed('plans');
  }

  @override
  Widget build(BuildContext context) {
    final action = ref.watch(planFormActionProvider);
    final loading = action.loading;
    final error = action.error;
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
              if (loading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              if (widget.isEdit)
                IconButton(
                  tooltip: 'أرشفة الباقة',
                  onPressed: loading ? null : _delete,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppTokens.red,
                  ),
                ),
              ElevatedButton.icon(
                onPressed: loading ? null : _submit,
                icon: const Icon(Icons.save_outlined),
                label: const Text('حفظ'),
              ),
            ],
          ),
          if (error != null) ...[
            const SizedBox(height: AppTokens.s12),
            Container(
              padding: const EdgeInsets.all(AppTokens.s12),
              decoration: BoxDecoration(
                color: AppTokens.dangerBg,
                borderRadius: BorderRadius.circular(AppTokens.r10),
              ),
              child:
                  Text(error, style: const TextStyle(color: AppTokens.red)),
            ),
          ],
          const SizedBox(height: AppTokens.s16),
          PlanCoreSection(
            controllers: _c,
            planType: _planType,
            serviceType: _serviceType,
            enabled: _enabled,
            onPlanTypeChanged: (v) => setState(() => _planType = v),
            onServiceTypeChanged: (v) => setState(() => _serviceType = v),
            onEnabledChanged: (v) => setState(() => _enabled = v),
          ),
          const SizedBox(height: AppTokens.s16),
          PlanTimeSection(controllers: _c),
          const SizedBox(height: AppTokens.s16),
          PlanQuotaSection(controllers: _c),
          const SizedBox(height: AppTokens.s16),
          PlanSpeedSection(
            controllers: _c,
            speedControl: _speedControl,
            onSpeedControlChanged: (v) => setState(() => _speedControl = v),
            burstEnabled: _burstEnabled,
            onBurstEnabledChanged: (v) => setState(() => _burstEnabled = v),
            nightlyUnlimited: _nightlyUnlimited,
            onNightlyUnlimitedChanged: (v) =>
                setState(() => _nightlyUnlimited = v),
          ),
          const SizedBox(height: AppTokens.s16),
          PlanSessionSection(
            controllers: _c,
            bindMac: _bindMac,
            bindIp: _bindIp,
            onBindMacChanged: (v) => setState(() => _bindMac = v),
            onBindIpChanged: (v) => setState(() => _bindIp = v),
          ),
          const SizedBox(height: AppTokens.s16),
          PlanWindowSection(
            controllers: _c,
            allowedDays: _allowedDays,
            onAllowedDaysChanged: (days) => setState(() {
              _allowedDays
                ..clear()
                ..addAll(days);
            }),
            onAllowedFromChanged: (value) =>
                setState(() => _c['allowed_hours_from']!.text = value),
            onAllowedToChanged: (value) =>
                setState(() => _c['allowed_hours_to']!.text = value),
          ),
          const SizedBox(height: AppTokens.s16),
          PlanCommerceSection(
            controllers: _c,
            planTier: _planTier,
            prepaid: _prepaid,
            autoRenew: _autoRenew,
            onPlanTierChanged: (v) => setState(() => _planTier = v),
            onPrepaidChanged: (v) => setState(() => _prepaid = v),
            onAutoRenewChanged: (v) => setState(() => _autoRenew = v),
          ),
          const SizedBox(height: AppTokens.s16),
          PlanServicesSection(
            hotspotEnabled: _hotspotEnabled,
            pppEnabled: _pppEnabled,
            singleUseOnce: _singleUseOnce,
            onHotspotChanged: (v) => setState(() => _hotspotEnabled = v),
            onPppChanged: (v) => setState(() => _pppEnabled = v),
            onSingleUseChanged: (v) => setState(() => _singleUseOnce = v),
          ),
          const SizedBox(height: AppTokens.s16),
          PlanLoanDeviceSection(
            controllers: _c,
            loanEnabled: _loanEnabled,
            onLoanEnabledChanged: (v) => setState(() => _loanEnabled = v),
            speedOverrideAllowed: _speedOverrideAllowed,
            onSpeedOverrideChanged: (v) =>
                setState(() => _speedOverrideAllowed = v),
            forceMacAddress: _forceMacAddress,
            onForceMacChanged: (v) => setState(() => _forceMacAddress = v),
          ),
          const SizedBox(height: AppTokens.s16),
          PlanMetaSection(controllers: _c),
          const SizedBox(height: AppTokens.s40),
        ],
      ),
    );
  }
}
