import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../../core/api/visible_error_message.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/hub_error_state.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/status_pill.dart';
import '../application/setup_wizard_providers.dart';
import '../data/setup_wizard_repository.dart';
import '../domain/setup_wizard_model.dart';

class SetupWizardScreen extends ConsumerStatefulWidget {
  const SetupWizardScreen({super.key});

  @override
  ConsumerState<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends ConsumerState<SetupWizardScreen> {
  bool _creating = false;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(setupWizardOverviewProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'معالج إعداد الراوترات',
          subtitle:
              'متابعة جاهزية الخادم وتشغيلات إعداد الراوتر من عقد الربط الآمن، مع فصل أوامر الراوتر وتعديل بوابة العميل داخل مسارات تشغيل محمية.',
          actions: [
            IconButton(
              tooltip: 'تحديث',
              onPressed: () => ref.invalidate(setupWizardOverviewProvider),
              icon: const Icon(Icons.refresh, color: AppTokens.textSecondary),
            ),
            async.maybeWhen(
              data: (overview) => ElevatedButton.icon(
                onPressed: overview.safeOperations.canCreateRun && !_creating
                    ? _createRun
                    : null,
                icon: _creating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.playlist_add),
                label: Text(_creating ? 'جاري الإنشاء' : 'تشغيل جديد'),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s16),
        async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => HubErrorState(
            title: 'تعذر جلب حالة معالج الإعداد',
            subtitle: visibleErrorMessage(error),
            onRetry: () => ref.invalidate(setupWizardOverviewProvider),
          ),
          data: _body,
        ),
      ],
    );
  }

  Widget _body(SetupWizardOverview overview) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SummaryCards(overview: overview),
        const SizedBox(height: AppTokens.s12),
        _SafetyNotice(safeOperations: overview.safeOperations),
        const SizedBox(height: AppTokens.s12),
        _PhasePlannerCard(
          runs: overview.recentRuns,
          enabled: overview.safeOperations.canPlanPhases,
        ),
        const SizedBox(height: AppTokens.s12),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 980;
            if (!wide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _HealthCard(health: overview.health),
                  const SizedBox(height: AppTokens.s12),
                  _ReadinessCard(readiness: overview.serverReadiness),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _HealthCard(health: overview.health)),
                const SizedBox(width: AppTokens.s12),
                Expanded(
                  child: _ReadinessCard(
                    readiness: overview.serverReadiness,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: AppTokens.s12),
        _RunsCard(runs: overview.recentRuns),
      ],
    );
  }

  Future<void> _createRun() async {
    setState(() => _creating = true);
    try {
      final run = await ref.read(setupWizardRepositoryProvider).createRun();
      ref.invalidate(setupWizardOverviewProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم إنشاء تشغيل رقم ${run.id} للمعالج')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(visibleErrorMessage(error))),
      );
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.overview});

  final SetupWizardOverview overview;

  @override
  Widget build(BuildContext context) {
    final items = [
      _Metric(
        'صحة المعالج',
        overview.health.label,
        Icons.health_and_safety_outlined,
        _healthTone(overview.health.overall),
      ),
      _Metric(
        'جاهزية الخادم',
        overview.serverReadiness.label,
        Icons.vpn_lock_outlined,
        _readinessTone(overview.serverReadiness.status),
      ),
      _Metric(
        'تشغيلات نشطة',
        '${overview.runsSummary.activeCount}',
        Icons.pending_actions_outlined,
        overview.runsSummary.activeCount > 0 ? PillTone.amber : PillTone.green,
      ),
      _Metric(
        'آخر تشغيلات',
        '${overview.runsSummary.recentCount}',
        Icons.history_outlined,
        PillTone.blue,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth >= 980 ? 4 : 2;
        return GridView.count(
          crossAxisCount: cols,
          crossAxisSpacing: AppTokens.s8,
          mainAxisSpacing: AppTokens.s8,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: cols == 4 ? 2.1 : 2.45,
          children: items.map((item) => _MetricCard(item)).toList(),
        );
      },
    );
  }
}

class _SafetyNotice extends StatelessWidget {
  const _SafetyNotice({required this.safeOperations});

  final SetupWizardSafeOperations safeOperations;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppTokens.s16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_outline, color: AppTokens.brandInk),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'حدود التشغيل من التطبيق',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  safeOperations.reason.isEmpty
                      ? 'التطبيق يعرض الحالة ويبدأ تشغيلًا جديدًا فقط. تطبيق أوامر الراوتر يتم من شاشة الويب المحمية.'
                      : safeOperations.reason,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTokens.textSecondary,
                        height: 1.5,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTokens.s8),
          StatusPill(
            text: safeOperations.canApplyRouterChanges
                ? 'تطبيق مباشر'
                : 'قراءة آمنة',
            tone: safeOperations.canApplyRouterChanges
                ? PillTone.red
                : PillTone.green,
            dot: true,
          ),
        ],
      ),
    );
  }
}

class _PhasePlannerCard extends ConsumerStatefulWidget {
  const _PhasePlannerCard({required this.runs, required this.enabled});

  final List<SetupWizardRun> runs;
  final bool enabled;

  @override
  ConsumerState<_PhasePlannerCard> createState() => _PhasePlannerCardState();
}

class _PhasePlannerCardState extends ConsumerState<_PhasePlannerCard> {
  final Map<String, TextEditingController> _controllers = {};
  String _phase = 'internet';
  String _serviceKey = 'walled_garden';
  int? _runId;
  bool _planning = false;
  bool _natEnabled = true;
  SetupWizardPhasePlanResponse? _result;

  @override
  void initState() {
    super.initState();
    _setDefaults(_phase);
  }

  @override
  void didUpdateWidget(covariant _PhasePlannerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final validRunIds = widget.runs.map((run) => run.id).toSet();
    if (_runId == null || !validRunIds.contains(_runId)) {
      _runId = widget.runs.isEmpty ? null : widget.runs.first.id;
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _controller(String key, {String fallback = ''}) {
    return _controllers.putIfAbsent(
      key,
      () => TextEditingController(text: fallback),
    );
  }

  @override
  Widget build(BuildContext context) {
    final phases = ref.watch(setupWizardPhasePlannersProvider);
    return AppCard(
      title: 'تخطيط مرحلة تشغيل',
      icon: Icons.route_outlined,
      actions: [
        StatusPill(
          text: widget.enabled ? 'تخطيط متاح' : 'غير متاح',
          tone: widget.enabled ? PillTone.green : PillTone.neutral,
          dot: true,
        ),
      ],
      child: phases.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => HubErrorState(
          title: 'تعذر جلب مراحل المعالج',
          subtitle: visibleErrorMessage(error),
          onRetry: () => ref.invalidate(setupWizardPhasePlannersProvider),
        ),
        data: (items) {
          if (widget.runs.isEmpty) {
            return const EmptyState(
              icon: Icons.playlist_add_outlined,
              title: 'ابدأ تشغيلًا قبل التخطيط',
              subtitle:
                  'أنشئ تشغيلًا جديدًا ثم اختر المرحلة لتوليد الخطة والسكربت.',
            );
          }
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.route_outlined,
              title: 'لا توجد مراحل متاحة',
              subtitle: 'الخادم لم يرجع قائمة مراحل معالج الإعداد.',
            );
          }
          _ensureSelectedPhase(items);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PhasePlannerControls(
                runs: widget.runs,
                phases: items,
                selectedRunId: _runId ?? widget.runs.first.id,
                selectedPhase: _phase,
                onRunChanged: (value) => setState(() => _runId = value),
                onPhaseChanged: (value) {
                  if (value == null || value == _phase) return;
                  setState(() {
                    _phase = value;
                    _result = null;
                    _setDefaults(value);
                  });
                },
              ),
              const SizedBox(height: AppTokens.s12),
              _PhaseInputFields(
                phase: _phase,
                serviceKey: _serviceKey,
                natEnabled: _natEnabled,
                controller: _controller,
                onServiceChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _serviceKey = value;
                    _result = null;
                    _setDefaults(_phase);
                  });
                },
                onNatChanged: (value) => setState(() => _natEnabled = value),
              ),
              const SizedBox(height: AppTokens.s12),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: widget.enabled && !_planning ? _plan : null,
                    icon: _planning
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_fix_high_outlined),
                    label: Text(_planning ? 'جاري التخطيط' : 'توليد الخطة'),
                  ),
                  const SizedBox(width: AppTokens.s8),
                  TextButton.icon(
                    onPressed: () => setState(() {
                      _result = null;
                      _setDefaults(_phase);
                    }),
                    icon: const Icon(Icons.refresh_outlined),
                    label: const Text('إعادة تعبئة'),
                  ),
                ],
              ),
              if (_result != null) ...[
                const SizedBox(height: AppTokens.s12),
                _PhasePlanResultView(result: _result!),
              ],
            ],
          );
        },
      ),
    );
  }

  void _ensureSelectedPhase(List<SetupWizardPhasePlanner> phases) {
    if (!phases.any((item) => item.phase == _phase)) {
      _phase = phases.first.phase;
      _setDefaults(_phase);
    }
  }

  void _setDefaults(String phase) {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    _natEnabled = true;
    final defaults = _defaultsFor(phase, _serviceKey);
    for (final entry in defaults.entries) {
      _controller(entry.key, fallback: entry.value);
    }
  }

  Future<void> _plan() async {
    final runId = _runId ?? (widget.runs.isEmpty ? null : widget.runs.first.id);
    if (runId == null) return;
    setState(() => _planning = true);
    try {
      final result = await ref.read(setupWizardRepositoryProvider).phasePlan(
            runId,
            _phase,
            inputs: _inputsForCurrentPhase(),
          );
      if (!mounted) return;
      setState(() => _result = result);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(visibleErrorMessage(error))),
      );
    } finally {
      if (mounted) setState(() => _planning = false);
    }
  }

  Map<String, dynamic> _inputsForCurrentPhase() {
    final text = {
      for (final entry in _controllers.entries)
        entry.key: entry.value.text.trim(),
    };
    if (_phase == 'internet') {
      return {
        'source_type': text['source_type'] ?? 'dhcp',
        'interface': text['interface'] ?? 'ether1',
        'nat_enabled': _natEnabled,
      };
    }
    if (_phase == 'hotspot') {
      return {
        'mode': 'manual',
        'selected_interfaces': _csv(text['selected_interfaces']),
        'subnet_base': text['subnet_base'],
        'radius_secret': text['radius_secret'],
        'router_vpn_ip': text['router_vpn_ip'],
      };
    }
    if (_phase == 'broadband') {
      return {
        'mode': 'manual',
        'selected_interfaces': _csv(text['selected_interfaces']),
        'local_address': text['local_address'],
        'remote_pool_cidr': text['remote_pool_cidr'],
      };
    }
    if (_phase == 'added_services') {
      final inputs = <String, dynamic>{'service_key': _serviceKey};
      if (_serviceKey == 'site_exit_public_ip') {
        inputs['destinations'] = _csv(text['destinations']);
        inputs['wireguard_interface_name'] = text['wireguard_interface_name'];
      } else {
        inputs['domains'] = _csv(text['domains']);
      }
      return inputs;
    }
    return text;
  }
}

class _PhasePlannerControls extends StatelessWidget {
  const _PhasePlannerControls({
    required this.runs,
    required this.phases,
    required this.selectedRunId,
    required this.selectedPhase,
    required this.onRunChanged,
    required this.onPhaseChanged,
  });

  final List<SetupWizardRun> runs;
  final List<SetupWizardPhasePlanner> phases;
  final int selectedRunId;
  final String selectedPhase;
  final ValueChanged<int?> onRunChanged;
  final ValueChanged<String?> onPhaseChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        final runPicker = _SelectBox<int>(
          label: 'تشغيل المعالج',
          value: selectedRunId,
          items: [
            for (final run in runs)
              DropdownMenuItem(
                value: run.id,
                child: Text('تشغيل ${run.id} - ${run.stateLabel}'),
              ),
          ],
          onChanged: onRunChanged,
        );
        final phasePicker = _SelectBox<String>(
          label: 'المرحلة',
          value: selectedPhase,
          items: [
            for (final phase in phases)
              DropdownMenuItem(
                value: phase.phase,
                child: Text(phase.title),
              ),
          ],
          onChanged: onPhaseChanged,
        );
        if (!wide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              runPicker,
              const SizedBox(height: AppTokens.s8),
              phasePicker,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: runPicker),
            const SizedBox(width: AppTokens.s8),
            Expanded(child: phasePicker),
          ],
        );
      },
    );
  }
}

class _PhaseInputFields extends StatelessWidget {
  const _PhaseInputFields({
    required this.phase,
    required this.serviceKey,
    required this.natEnabled,
    required this.controller,
    required this.onServiceChanged,
    required this.onNatChanged,
  });

  final String phase;
  final String serviceKey;
  final bool natEnabled;
  final TextEditingController Function(String key, {String fallback})
      controller;
  final ValueChanged<String?> onServiceChanged;
  final ValueChanged<bool> onNatChanged;

  @override
  Widget build(BuildContext context) {
    final fields = _fieldsFor(phase, serviceKey);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (phase == 'added_services') ...[
          _SelectBox<String>(
            label: 'الخدمة الإضافية',
            value: serviceKey,
            items: const [
              DropdownMenuItem(
                value: 'walled_garden',
                child: Text('مواقع مفتوحة بدون تسجيل دخول'),
              ),
              DropdownMenuItem(value: 'block_sites', child: Text('حجب مواقع')),
              DropdownMenuItem(
                value: 'site_exit_public_ip',
                child: Text('تغيير عنوان الخروج العام'),
              ),
            ],
            onChanged: onServiceChanged,
          ),
          const SizedBox(height: AppTokens.s8),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 760;
            final widgets = [
              for (final field in fields) _fieldWidget(field),
            ];
            if (!wide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final widget in widgets) ...[
                    widget,
                    const SizedBox(height: AppTokens.s8),
                  ],
                ],
              );
            }
            return Wrap(
              spacing: AppTokens.s8,
              runSpacing: AppTokens.s8,
              children: [
                for (final widget in widgets)
                  SizedBox(width: 260, child: widget),
              ],
            );
          },
        ),
        if (phase == 'internet') ...[
          const SizedBox(height: AppTokens.s8),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: natEnabled,
            onChanged: onNatChanged,
            title: const Text('تفعيل NAT لهذا المنفذ'),
            subtitle:
                const Text('اتركه مفعلًا إذا كان هذا منفذ الإنترنت الرئيسي.'),
          ),
        ],
      ],
    );
  }

  Widget _fieldWidget(String field) {
    if (field == 'source_type') {
      final source = controller(field);
      final value =
          _internetSourceValues.contains(source.text) ? source.text : 'dhcp';
      source.text = value;
      return _SelectBox<String>(
        label: setupWizardInputLabel(field),
        value: value,
        items: const [
          DropdownMenuItem(value: 'dhcp', child: Text('تلقائي عبر DHCP')),
          DropdownMenuItem(value: 'static', child: Text('عنوان ثابت')),
          DropdownMenuItem(value: 'pppoe', child: Text('اتصال PPPoE')),
          DropdownMenuItem(value: 'vlan', child: Text('شبكة VLAN')),
        ],
        onChanged: (value) {
          if (value != null) source.text = value;
        },
      );
    }
    return _InputBox(
      label: setupWizardInputLabel(field),
      controller: controller(field),
      hint: _hintFor(field),
    );
  }
}

class _PhasePlanResultView extends StatelessWidget {
  const _PhasePlanResultView({required this.result});

  final SetupWizardPhasePlanResponse result;

  @override
  Widget build(BuildContext context) {
    final plan = result.plan;
    return Container(
      padding: const EdgeInsets.all(AppTokens.s12),
      decoration: BoxDecoration(
        border: Border.all(color: AppTokens.border),
        borderRadius: BorderRadius.circular(AppTokens.r8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  setupWizardPhaseLabel(result.phase),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              StatusPill(
                text: plan.canApply ? 'جاهزة للمعاينة' : 'تحتاج استكمال',
                tone: plan.canApply ? PillTone.green : PillTone.amber,
                dot: true,
              ),
            ],
          ),
          if (plan.notes.isNotEmpty) ...[
            const SizedBox(height: AppTokens.s8),
            for (final note in plan.notes.take(4))
              Text(
                '• $note',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTokens.textSecondary,
                      height: 1.45,
                    ),
              ),
          ],
          if (plan.warnings.isNotEmpty) ...[
            const SizedBox(height: AppTokens.s8),
            _PlainListBox(
              title: 'تنبيهات قبل التطبيق',
              items: plan.warnings,
              tone: PillTone.amber,
            ),
          ],
          if (result.diagnostics.isNotEmpty) ...[
            const SizedBox(height: AppTokens.s8),
            for (final diagnostic in result.diagnostics.take(3)) ...[
              _DiagnosticBox(diagnostic: diagnostic),
              const SizedBox(height: AppTokens.s8),
            ],
          ],
          if (plan.script.isNotEmpty) ...[
            const SizedBox(height: AppTokens.s8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'سكربت RouterOS الناتج',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: plan.script));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم نسخ السكربت')),
                    );
                  },
                  icon: const Icon(Icons.copy_outlined),
                  label: const Text('نسخ'),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.s8),
            Container(
              constraints: const BoxConstraints(maxHeight: 260),
              padding: const EdgeInsets.all(AppTokens.s12),
              decoration: BoxDecoration(
                color: AppTokens.soft,
                borderRadius: BorderRadius.circular(AppTokens.r8),
                border: Border.all(color: AppTokens.border),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  plan.script,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    height: 1.35,
                    color: AppTokens.textPrimary,
                  ),
                ),
              ),
            ),
          ],
          if (plan.validationCommands.isNotEmpty) ...[
            const SizedBox(height: AppTokens.s8),
            _PlainListBox(
              title: 'أوامر التحقق',
              items: plan.validationCommands,
              tone: PillTone.blue,
            ),
          ],
        ],
      ),
    );
  }
}

class _PlainListBox extends StatelessWidget {
  const _PlainListBox({
    required this.title,
    required this.items,
    required this.tone,
  });

  final String title;
  final List<String> items;
  final PillTone tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s12),
      decoration: BoxDecoration(
        color: AppTokens.soft,
        borderRadius: BorderRadius.circular(AppTokens.r8),
        border: Border.all(color: AppTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StatusPill(text: title, tone: tone, dot: true),
          const SizedBox(height: AppTokens.s8),
          for (final item in items.take(6))
            Text(
              '• $item',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTokens.textSecondary,
                    height: 1.45,
                  ),
            ),
        ],
      ),
    );
  }
}

class _SelectBox<T> extends StatelessWidget {
  const _SelectBox({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(labelText: label),
    );
  }
}

class _InputBox extends StatelessWidget {
  const _InputBox({
    required this.label,
    required this.controller,
    required this.hint,
  });

  final String label;
  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }
}

class _HealthCard extends StatelessWidget {
  const _HealthCard({required this.health});

  final SetupWizardHealth health;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'صحة معالج الإعداد',
      icon: Icons.health_and_safety_outlined,
      actions: [
        StatusPill(
          text: health.label,
          tone: _healthTone(health.overall),
          dot: true,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (health.checks.isEmpty)
            const EmptyState(
              icon: Icons.fact_check_outlined,
              title: 'لا توجد فحوص صحة مفصلة',
              subtitle: 'الخادم لم يرجع عناصر فحص مفصلة لهذه البيئة.',
            )
          else
            for (final check in health.checks.take(8)) ...[
              _CheckRow(
                title: check.title,
                subtitle: _safeArabicDetail(check.details),
                statusLabel: check.statusLabel,
                tone: _checkTone(check.status),
              ),
              const Divider(height: 1),
            ],
          if (health.checkedAt.isNotEmpty) ...[
            const SizedBox(height: AppTokens.s12),
            Text(
              'آخر فحص: ${health.checkedAt}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTokens.textMuted,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReadinessCard extends StatelessWidget {
  const _ReadinessCard({required this.readiness});

  final SetupWizardServerReadiness readiness;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'جاهزية خادم الربط',
      icon: Icons.vpn_lock_outlined,
      actions: [
        StatusPill(
          text: readiness.label,
          tone: _readinessTone(readiness.status),
          dot: true,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (readiness.nextAction.isNotEmpty) ...[
            Text(
              readiness.nextAction,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTokens.textSecondary,
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: AppTokens.s12),
          ],
          if (readiness.diagnostics.isNotEmpty) ...[
            for (final diagnostic in readiness.diagnostics.take(3)) ...[
              _DiagnosticBox(diagnostic: diagnostic),
              const SizedBox(height: AppTokens.s8),
            ],
            const SizedBox(height: AppTokens.s4),
          ],
          if (readiness.checks.isEmpty)
            const EmptyState(
              icon: Icons.rule_outlined,
              title: 'لا توجد فحوص جاهزية',
              subtitle:
                  'فحص الجاهزية غير مفعل أو لم يرجع الخادم تفاصيل إضافية.',
            )
          else
            for (final check in readiness.checks.take(10)) ...[
              _CheckRow(
                title: check.label,
                subtitle: _safeArabicDetail(check.detail),
                statusLabel: check.statusLabel,
                tone: _readinessCheckTone(check.status),
              ),
              const Divider(height: 1),
            ],
        ],
      ),
    );
  }
}

class _RunsCard extends StatelessWidget {
  const _RunsCard({required this.runs});

  final List<SetupWizardRun> runs;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'آخر تشغيلات المعالج',
      icon: Icons.history_outlined,
      child: runs.isEmpty
          ? const EmptyState(
              icon: Icons.playlist_add_check_outlined,
              title: 'لا توجد تشغيلات بعد',
              subtitle:
                  'ابدأ تشغيلًا جديدًا عند تجهيز راوتر جديد، ثم أكمل التطبيق من شاشة الويب المحمية.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final run in runs) ...[
                  _RunRow(run: run),
                  const Divider(height: 1),
                ],
              ],
            ),
    );
  }
}

class _RunRow extends StatelessWidget {
  const _RunRow({required this.run});

  final SetupWizardRun run;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.s8),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppTokens.brandSoft,
              borderRadius: BorderRadius.circular(AppTokens.r6),
            ),
            alignment: Alignment.center,
            child: Text(
              '${run.id}',
              style: const TextStyle(
                color: AppTokens.brandInk,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  run.routerName.isEmpty
                      ? 'تشغيل بدون اسم راوتر بعد'
                      : run.routerName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    if (run.routerTypeLabel.isNotEmpty)
                      'النوع: ${run.routerTypeLabel}',
                    if (run.routerVpnAddress.isNotEmpty)
                      'عنوان النفق: ${run.routerVpnAddress}',
                    if (run.updatedAt.isNotEmpty) 'آخر تحديث: ${run.updatedAt}',
                  ].join('  •  '),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTokens.textMuted,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTokens.s8),
          StatusPill(
            text: run.stateLabel,
            tone: run.isTerminal ? PillTone.neutral : PillTone.blue,
            dot: true,
          ),
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    required this.tone,
  });

  final String title;
  final String subtitle;
  final String statusLabel;
  final PillTone tone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.s8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTokens.textMuted,
                          height: 1.35,
                        ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppTokens.s8),
          StatusPill(text: statusLabel, tone: tone, dot: true),
        ],
      ),
    );
  }
}

class _DiagnosticBox extends StatelessWidget {
  const _DiagnosticBox({required this.diagnostic});

  final SetupWizardDiagnostic diagnostic;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s12),
      decoration: BoxDecoration(
        color: AppTokens.warningBg,
        borderRadius: BorderRadius.circular(AppTokens.r10),
        border: Border.all(color: AppTokens.warningMed),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppTokens.warningFg, size: 18),
          const SizedBox(width: AppTokens.s8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  diagnostic.title.isEmpty ? 'تنبيه جاهزية' : diagnostic.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTokens.warningFg,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                if (diagnostic.explanation.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    diagnostic.explanation,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTokens.warningFg,
                          height: 1.4,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric {
  const _Metric(this.label, this.value, this.icon, this.tone);
  final String label;
  final String value;
  final IconData icon;
  final PillTone tone;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(this.metric);

  final _Metric metric;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppTokens.s16),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTokens.brandSoft,
              borderRadius: BorderRadius.circular(AppTokens.r10),
            ),
            alignment: Alignment.center,
            child: Icon(metric.icon, color: AppTokens.brandInk),
          ),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  metric.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTokens.textMuted,
                      ),
                ),
                const SizedBox(height: 6),
                StatusPill(text: metric.value, tone: metric.tone, dot: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

PillTone _healthTone(String status) => switch (status) {
      'healthy' => PillTone.green,
      'degraded' => PillTone.amber,
      'critical' => PillTone.red,
      _ => PillTone.neutral,
    };

PillTone _readinessTone(String status) => switch (status) {
      'ready' => PillTone.green,
      'partial' => PillTone.amber,
      'blocked' => PillTone.red,
      'disabled' => PillTone.neutral,
      _ => PillTone.neutral,
    };

PillTone _checkTone(String status) => switch (status) {
      'ok' => PillTone.green,
      'warn' => PillTone.amber,
      'fail' => PillTone.red,
      _ => PillTone.neutral,
    };

PillTone _readinessCheckTone(String status) => switch (status) {
      'success' => PillTone.green,
      'warning' => PillTone.amber,
      'blocked' => PillTone.red,
      'disabled' => PillTone.neutral,
      _ => PillTone.neutral,
    };

String _safeArabicDetail(String value) {
  final text = value.trim();
  if (text.isEmpty) return '';
  if (_containsArabic(text)) return text;
  return 'تفاصيل تقنية متاحة من الخادم، وتحتاج صياغة عربية في المصدر.';
}

List<String> _fieldsFor(String phase, String serviceKey) {
  if (phase == 'internet') return const ['source_type', 'interface'];
  if (phase == 'vpn_radius') {
    return const [
      'router_vpn_ip',
      'vps_vpn_ip',
      'vps_public_endpoint',
      'radius_secret',
      'server_public_key',
    ];
  }
  if (phase == 'hotspot') {
    return const [
      'selected_interfaces',
      'subnet_base',
      'radius_secret',
      'router_vpn_ip',
    ];
  }
  if (phase == 'broadband') {
    return const [
      'selected_interfaces',
      'local_address',
      'remote_pool_cidr',
    ];
  }
  if (phase == 'added_services') {
    if (serviceKey == 'site_exit_public_ip') {
      return const ['destinations', 'wireguard_interface_name'];
    }
    return const ['domains'];
  }
  return const [];
}

const _internetSourceValues = {'dhcp', 'static', 'pppoe', 'vlan'};

Map<String, String> _defaultsFor(String phase, String serviceKey) {
  if (phase == 'internet') {
    return const {'source_type': 'dhcp', 'interface': 'ether1'};
  }
  if (phase == 'vpn_radius') {
    return const {
      'router_vpn_ip': '10.10.0.5',
      'vps_vpn_ip': '10.10.0.1',
      'vps_public_endpoint': 'hoberadius.com',
      'radius_secret': '',
      'server_public_key': '',
    };
  }
  if (phase == 'hotspot') {
    return const {
      'selected_interfaces': 'ether2',
      'subnet_base': '10.99.0.0/16',
      'radius_secret': '',
      'router_vpn_ip': '10.10.0.5',
    };
  }
  if (phase == 'broadband') {
    return const {
      'selected_interfaces': 'ether3',
      'local_address': '192.168.50.1',
      'remote_pool_cidr': '192.168.50.0/24',
    };
  }
  if (phase == 'added_services') {
    if (serviceKey == 'site_exit_public_ip') {
      return const {
        'destinations': 'speedtest.net',
        'wireguard_interface_name': 'hr-wg',
      };
    }
    return const {'domains': 'example.com'};
  }
  return const {};
}

String _hintFor(String field) {
  return switch (field) {
    'source_type' => 'dhcp',
    'interface' => 'ether1',
    'router_vpn_ip' => '10.10.0.5',
    'vps_vpn_ip' => '10.10.0.1',
    'vps_public_endpoint' => 'hoberadius.com أو IP الخادم',
    'radius_secret' => 'اكتب السر المتفق عليه',
    'server_public_key' => 'مفتاح WireGuard العام للخادم',
    'selected_interfaces' => 'ether2, ether3',
    'subnet_base' => '10.99.0.0/16',
    'local_address' => '192.168.50.1',
    'remote_pool_cidr' => '192.168.50.0/24',
    'domains' => 'example.com, portal.example.com',
    'destinations' => 'speedtest.net, 1.1.1.1',
    'wireguard_interface_name' => 'hr-wg',
    _ => '',
  };
}

List<String> _csv(String? value) {
  final raw = (value ?? '').trim();
  if (raw.isEmpty) return const [];
  return raw
      .split(RegExp(r'[\n,]+'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
}

bool _containsArabic(String value) {
  return value.runes.any(
    (r) =>
        (r >= 0x0600 && r <= 0x06FF) ||
        (r >= 0x0750 && r <= 0x077F) ||
        (r >= 0x08A0 && r <= 0x08FF) ||
        (r >= 0xFB50 && r <= 0xFDFF) ||
        (r >= 0xFE70 && r <= 0xFEFF),
  );
}
