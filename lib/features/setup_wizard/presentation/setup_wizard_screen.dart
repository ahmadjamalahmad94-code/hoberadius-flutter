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
        _RunLifecycleCard(
          runs: overview.recentRuns,
          enabled: overview.safeOperations.canRunLifecycle,
        ),
        const SizedBox(height: AppTokens.s12),
        _RouterServicesCard(runs: overview.recentRuns),
        const SizedBox(height: AppTokens.s12),
        const _DiagnosticsCatalogueCard(),
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
                      ? 'التطبيق يعرض الحالة، يبدأ تشغيلًا جديدًا، ويكمل خطوات الربط المسموحة عبر API محمي. أوامر الراوتر المباشرة تبقى ضمن شاشات محمية بتأكيد واضح.'
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

class _RunLifecycleCard extends ConsumerStatefulWidget {
  const _RunLifecycleCard({required this.runs, required this.enabled});

  final List<SetupWizardRun> runs;
  final bool enabled;

  @override
  ConsumerState<_RunLifecycleCard> createState() => _RunLifecycleCardState();
}

class _RunLifecycleCardState extends ConsumerState<_RunLifecycleCard> {
  final _routerName = TextEditingController(text: 'main-router');
  final _endpoint = TextEditingController(text: 'hoberadius.com');
  final _serverPublicKey = TextEditingController();
  final _routerPublicKey = TextEditingController();
  final _apiUser = TextEditingController(text: 'admin');
  final _apiPassword = TextEditingController();
  String _routerType = 'hotspot';
  int? _runId;
  String? _busyAction;
  SetupWizardScriptResult? _scriptResult;
  SetupWizardRun? _latestRun;

  @override
  void didUpdateWidget(covariant _RunLifecycleCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final validRunIds = widget.runs.map((run) => run.id).toSet();
    if (_runId == null || !validRunIds.contains(_runId)) {
      _runId = widget.runs.isEmpty ? null : widget.runs.first.id;
      _latestRun = widget.runs.isEmpty ? null : widget.runs.first;
    }
  }

  @override
  void dispose() {
    _routerName.dispose();
    _endpoint.dispose();
    _serverPublicKey.dispose();
    _routerPublicKey.dispose();
    _apiUser.dispose();
    _apiPassword.dispose();
    super.dispose();
  }

  SetupWizardRun? get _selectedRun {
    if (_latestRun != null && _latestRun!.id == _runId) return _latestRun;
    for (final run in widget.runs) {
      if (run.id == _runId) return run;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.runs.isEmpty) {
      return const AppCard(
        title: 'إكمال تشغيل المعالج',
        icon: Icons.checklist_rtl_outlined,
        child: EmptyState(
          icon: Icons.playlist_add_outlined,
          title: 'لا يوجد تشغيل لإكماله',
          subtitle: 'أنشئ تشغيلًا جديدًا من أعلى الصفحة ثم أكمل خطواته هنا.',
        ),
      );
    }
    final run = _selectedRun ?? widget.runs.first;
    _runId ??= run.id;
    return AppCard(
      title: 'إكمال تشغيل المعالج',
      icon: Icons.checklist_rtl_outlined,
      actions: [
        StatusPill(
          text: widget.enabled ? 'خطوات متاحة' : 'مقفلة',
          tone: widget.enabled ? PillTone.green : PillTone.neutral,
          dot: true,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SelectBox<int>(
            label: 'تشغيل المعالج',
            value: _runId ?? run.id,
            items: [
              for (final item in widget.runs)
                DropdownMenuItem(
                  value: item.id,
                  child: Text('تشغيل ${item.id} - ${item.stateLabel}'),
                ),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _runId = value;
                _latestRun = widget.runs.firstWhere((item) => item.id == value);
                _scriptResult = null;
              });
            },
          ),
          const SizedBox(height: AppTokens.s12),
          _LifecycleProgress(run: run),
          const SizedBox(height: AppTokens.s12),
          _LifecycleFields(
            routerName: _routerName,
            endpoint: _endpoint,
            serverPublicKey: _serverPublicKey,
            routerPublicKey: _routerPublicKey,
            apiUser: _apiUser,
            apiPassword: _apiPassword,
            routerType: _routerType,
            onRouterTypeChanged: (value) {
              if (value == null) return;
              setState(() => _routerType = value);
            },
          ),
          const SizedBox(height: AppTokens.s12),
          Wrap(
            spacing: AppTokens.s8,
            runSpacing: AppTokens.s8,
            children: [
              _ActionButton(
                label: 'حفظ بيانات الراوتر',
                icon: Icons.router_outlined,
                busy: _busyAction == 'router_info',
                enabled: widget.enabled && run.state == 'COLLECTING',
                onPressed: () => _runAction('router_info'),
              ),
              _ActionButton(
                label: 'توليد سكربت الربط',
                icon: Icons.code_outlined,
                busy: _busyAction == 'generate',
                enabled: widget.enabled && run.state == 'PLANNING',
                onPressed: () => _runAction('generate'),
              ),
              _ActionButton(
                label: 'حفظ مفتاح الراوتر',
                icon: Icons.key_outlined,
                busy: _busyAction == 'submit_key',
                enabled: widget.enabled && run.state == 'AWAITING_HANDSHAKE',
                onPressed: () => _runAction('submit_key'),
              ),
              _ActionButton(
                label: 'تطبيق peer على الخادم',
                icon: Icons.vpn_lock_outlined,
                busy: _busyAction == 'apply_peer',
                enabled: widget.enabled && run.state == 'APPLYING_SERVER_PEER',
                onPressed: () => _runAction('apply_peer'),
              ),
              _ActionButton(
                label: 'تأكيد الاتصال',
                icon: Icons.verified_outlined,
                busy: _busyAction == 'mark_handshake',
                enabled: widget.enabled && run.state == 'VERIFYING',
                onPressed: () => _runAction('mark_handshake'),
              ),
              _ActionButton(
                label: 'تسجيل الراوتر',
                icon: Icons.app_registration_outlined,
                busy: _busyAction == 'register',
                enabled: widget.enabled && run.state == 'REGISTERING',
                onPressed: () => _runAction('register'),
              ),
            ],
          ),
          if (_scriptResult != null) ...[
            const SizedBox(height: AppTokens.s12),
            _GeneratedScriptBox(result: _scriptResult!),
          ],
        ],
      ),
    );
  }

  Future<void> _runAction(String action) async {
    final runId = _runId;
    if (runId == null) return;
    setState(() => _busyAction = action);
    try {
      final repo = ref.read(setupWizardRepositoryProvider);
      SetupWizardRun run;
      if (action == 'router_info') {
        run = await repo.submitRouterInfo(
          runId,
          routerName: _routerName.text.trim(),
          routerType: _routerType,
        );
      } else if (action == 'generate') {
        final result = await repo.generateScript(
          runId,
          endpoint: _endpoint.text.trim(),
          serverPublicKey: _serverPublicKey.text.trim(),
        );
        run = result.run;
        _scriptResult = result;
      } else if (action == 'submit_key') {
        run = await repo.submitPublicKey(
          runId,
          publicKeyOrOutput: _routerPublicKey.text.trim(),
        );
      } else if (action == 'apply_peer') {
        run = await repo.applyServerPeer(runId);
      } else if (action == 'mark_handshake') {
        run = await repo.markHandshake(runId);
      } else {
        run = await repo.registerRouter(
          runId,
          apiUser:
              _apiUser.text.trim().isEmpty ? 'admin' : _apiUser.text.trim(),
          apiPassword: _apiPassword.text,
        );
      }
      ref.invalidate(setupWizardOverviewProvider);
      if (!mounted) return;
      setState(() => _latestRun = run);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تنفيذ الخطوة وتحديث حالة التشغيل')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(visibleErrorMessage(error))),
      );
    } finally {
      if (mounted) setState(() => _busyAction = null);
    }
  }
}

class _RouterServicesCard extends ConsumerStatefulWidget {
  const _RouterServicesCard({required this.runs});

  final List<SetupWizardRun> runs;

  @override
  ConsumerState<_RouterServicesCard> createState() =>
      _RouterServicesCardState();
}

class _RouterServicesCardState extends ConsumerState<_RouterServicesCard> {
  int? _routerId;

  List<SetupWizardRun> get _registeredRuns {
    final seen = <int>{};
    final result = <SetupWizardRun>[];
    for (final run in widget.runs) {
      if (run.nasDeviceId <= 0) continue;
      if (seen.add(run.nasDeviceId)) result.add(run);
    }
    return result;
  }

  @override
  void didUpdateWidget(covariant _RouterServicesCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _ensureRouterSelection();
  }

  @override
  Widget build(BuildContext context) {
    final registered = _registeredRuns;
    if (registered.isEmpty) {
      return const AppCard(
        title: 'خدمات الراوتر بعد التسجيل',
        icon: Icons.hub_outlined,
        child: EmptyState(
          icon: Icons.router_outlined,
          title: 'لا يوجد راوتر مسجل بعد',
          subtitle:
              'أكمل تشغيل المعالج حتى خطوة تسجيل الراوتر، ثم تظهر هنا حالة الخدمات المستلمة من الراوتر.',
        ),
      );
    }
    _ensureRouterSelection();
    final routerId = _routerId ?? registered.first.nasDeviceId;
    final catalogue = ref.watch(setupWizardRouterServiceCatalogueProvider);
    final status = ref.watch(setupWizardRouterServicesStatusProvider(routerId));
    return AppCard(
      title: 'خدمات الراوتر بعد التسجيل',
      icon: Icons.hub_outlined,
      actions: [
        IconButton(
          tooltip: 'تحديث حالة الخدمات',
          onPressed: () {
            ref.invalidate(setupWizardRouterServiceCatalogueProvider);
            ref.invalidate(setupWizardRouterServicesStatusProvider(routerId));
          },
          icon: const Icon(Icons.refresh_outlined),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SelectBox<int>(
            label: 'الراوتر المسجل',
            value: routerId,
            items: [
              for (final run in registered)
                DropdownMenuItem(
                  value: run.nasDeviceId,
                  child: Text(_registeredRouterLabel(run)),
                ),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _routerId = value);
            },
          ),
          const SizedBox(height: AppTokens.s12),
          catalogue.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => HubErrorState(
              title: 'تعذر جلب كتالوج الخدمات',
              subtitle: visibleErrorMessage(error),
              onRetry: () =>
                  ref.invalidate(setupWizardRouterServiceCatalogueProvider),
            ),
            data: (cards) => status.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => HubErrorState(
                title: 'تعذر جلب حالة الخدمات',
                subtitle: visibleErrorMessage(error),
                onRetry: () => ref.invalidate(
                  setupWizardRouterServicesStatusProvider(routerId),
                ),
              ),
              data: (state) => _RouterServicesGrid(
                cards: cards,
                status: state,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _ensureRouterSelection() {
    final registered = _registeredRuns;
    final ids = registered.map((run) => run.nasDeviceId).toSet();
    if (_routerId == null || !ids.contains(_routerId)) {
      _routerId = registered.isEmpty ? null : registered.first.nasDeviceId;
    }
  }
}

class _RouterServicesGrid extends StatelessWidget {
  const _RouterServicesGrid({required this.cards, required this.status});

  final List<SetupWizardRouterServiceCard> cards;
  final SetupWizardRouterServicesStatus status;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return const EmptyState(
        icon: Icons.miscellaneous_services_outlined,
        title: 'لا توجد خدمات معرفة',
        subtitle: 'لم يرجع الخادم كتالوج خدمات الراوتر لهذا الإصدار.',
      );
    }
    final statusByKey = {for (final item in status.services) item.key: item};
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 980
            ? 3
            : constraints.maxWidth >= 640
                ? 2
                : 1;
        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: AppTokens.s8,
          mainAxisSpacing: AppTokens.s8,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: columns == 1 ? 3.2 : 2.5,
          children: [
            for (final card in cards)
              _RouterServiceTile(
                card: card,
                status: statusByKey[card.key],
              ),
          ],
        );
      },
    );
  }
}

class _RouterServiceTile extends StatelessWidget {
  const _RouterServiceTile({required this.card, required this.status});

  final SetupWizardRouterServiceCard card;
  final SetupWizardRouterServiceStatus? status;

  @override
  Widget build(BuildContext context) {
    final state = status?.status ?? 'unknown';
    return Container(
      padding: const EdgeInsets.all(AppTokens.s12),
      decoration: BoxDecoration(
        color: AppTokens.soft,
        borderRadius: BorderRadius.circular(AppTokens.r8),
        border: Border.all(color: AppTokens.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTokens.brandSoft,
              borderRadius: BorderRadius.circular(AppTokens.r8),
            ),
            alignment: Alignment.center,
            child: Icon(
              _routerServiceIcon(card.key),
              size: 18,
              color: AppTokens.brandInk,
            ),
          ),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        card.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    const SizedBox(width: AppTokens.s8),
                    StatusPill(
                      text: status?.statusLabel ??
                          setupWizardRouterServiceStatusLabel(state),
                      tone: _routerServiceTone(state),
                      dot: true,
                    ),
                  ],
                ),
                if (card.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    card.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTokens.textSecondary,
                          height: 1.35,
                        ),
                  ),
                ],
                if (card.phasesCount > 0) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${card.phasesCount} مراحل إعداد',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTokens.textMuted,
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

class _DiagnosticsCatalogueCard extends ConsumerWidget {
  const _DiagnosticsCatalogueCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diagnostics = ref.watch(setupWizardDiagnosticsCatalogueProvider);
    return AppCard(
      title: 'دليل تشخيص معالج الإعداد',
      icon: Icons.manage_search_outlined,
      actions: [
        IconButton(
          tooltip: 'تحديث دليل التشخيص',
          onPressed: () =>
              ref.invalidate(setupWizardDiagnosticsCatalogueProvider),
          icon: const Icon(Icons.refresh_outlined),
        ),
      ],
      child: diagnostics.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => HubErrorState(
          title: 'تعذر جلب دليل التشخيص',
          subtitle: visibleErrorMessage(error),
          onRetry: () =>
              ref.invalidate(setupWizardDiagnosticsCatalogueProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.manage_search_outlined,
              title: 'لا توجد تشخيصات معرفة',
              subtitle:
                  'عند توفر كتالوج التشخيص من الخادم ستظهر هنا الأسباب وخطوات الإصلاح لكل مرحلة.',
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'هذا الدليل يشرح رسائل التعطل قبل التطبيق العملي، ويعرض السبب وخطوة الإصلاح وأمر الفحص عند توفره.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTokens.textSecondary,
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: AppTokens.s12),
              for (final item in items.take(8)) ...[
                _DiagnosticCatalogueRow(diagnostic: item),
                const Divider(height: 1),
              ],
              if (items.length > 8) ...[
                const SizedBox(height: AppTokens.s8),
                Text(
                  'يعرض التطبيق أهم ${items.take(8).length} تشخيصات من أصل ${items.length}. استخدم البحث في الويب للتفاصيل الكاملة عند الحاجة.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTokens.textMuted,
                      ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _DiagnosticCatalogueRow extends StatelessWidget {
  const _DiagnosticCatalogueRow({required this.diagnostic});

  final SetupWizardDiagnostic diagnostic;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      diagnostic.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      diagnostic.phaseLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTokens.textMuted,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTokens.s8),
              StatusPill(
                text: diagnostic.severityLabel,
                tone: _diagnosticSeverityTone(diagnostic.severity),
                dot: true,
              ),
            ],
          ),
          if (diagnostic.explanation.isNotEmpty) ...[
            const SizedBox(height: AppTokens.s8),
            Text(
              diagnostic.explanation,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTokens.textSecondary,
                    height: 1.45,
                  ),
            ),
          ],
          if (diagnostic.cause.isNotEmpty || diagnostic.fix.isNotEmpty) ...[
            const SizedBox(height: AppTokens.s8),
            Wrap(
              spacing: AppTokens.s8,
              runSpacing: AppTokens.s8,
              children: [
                if (diagnostic.cause.isNotEmpty)
                  _InfoChip(
                    icon: Icons.help_outline,
                    label: 'السبب',
                    value: diagnostic.cause,
                  ),
                if (diagnostic.fix.isNotEmpty)
                  _InfoChip(
                    icon: Icons.build_outlined,
                    label: 'الإصلاح',
                    value: diagnostic.fix,
                  ),
              ],
            ),
          ],
          if (diagnostic.inspectCommand.isNotEmpty) ...[
            const SizedBox(height: AppTokens.s8),
            Container(
              padding: const EdgeInsets.all(AppTokens.s8),
              decoration: BoxDecoration(
                color: AppTokens.soft,
                borderRadius: BorderRadius.circular(AppTokens.r8),
                border: Border.all(color: AppTokens.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      diagnostic.inspectCommand,
                      textDirection: TextDirection.ltr,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                            color: AppTokens.sidebarBg,
                          ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'نسخ أمر الفحص',
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: diagnostic.inspectCommand),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم نسخ أمر الفحص')),
                      );
                    },
                    icon: const Icon(Icons.copy_outlined),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTokens.brandSoft,
        borderRadius: BorderRadius.circular(AppTokens.r8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.s8,
          vertical: AppTokens.s8,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppTokens.brandInk),
            const SizedBox(width: 6),
            Text(
              '$label: $value',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTokens.brandInk,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LifecycleFields extends StatelessWidget {
  const _LifecycleFields({
    required this.routerName,
    required this.endpoint,
    required this.serverPublicKey,
    required this.routerPublicKey,
    required this.apiUser,
    required this.apiPassword,
    required this.routerType,
    required this.onRouterTypeChanged,
  });

  final TextEditingController routerName;
  final TextEditingController endpoint;
  final TextEditingController serverPublicKey;
  final TextEditingController routerPublicKey;
  final TextEditingController apiUser;
  final TextEditingController apiPassword;
  final String routerType;
  final ValueChanged<String?> onRouterTypeChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        final fields = [
          _InputBox(
            label: 'اسم الراوتر',
            controller: routerName,
            hint: 'main-router',
          ),
          _SelectBox<String>(
            label: 'نوع الراوتر',
            value: routerType,
            items: const [
              DropdownMenuItem(value: 'hotspot', child: Text('بوابة دخول')),
              DropdownMenuItem(value: 'pppoe', child: Text('اشتراكات PPPoE')),
              DropdownMenuItem(value: 'mixed', child: Text('مختلط')),
            ],
            onChanged: onRouterTypeChanged,
          ),
          _InputBox(
            label: 'عنوان الخادم العام',
            controller: endpoint,
            hint: 'hoberadius.com',
          ),
          _InputBox(
            label: 'مفتاح الخادم العام',
            controller: serverPublicKey,
            hint: 'WireGuard public key',
          ),
          _InputBox(
            label: 'مفتاح الراوتر أو المخرجات',
            controller: routerPublicKey,
            hint: 'HOBERADIUS_PUBLIC_KEY=...',
          ),
          _InputBox(
            label: 'مستخدم API على الراوتر',
            controller: apiUser,
            hint: 'admin',
          ),
          _InputBox(
            label: 'كلمة مرور API على الراوتر',
            controller: apiPassword,
            hint: 'تترك فارغة إذا أنشأها السكربت',
          ),
        ];
        if (!wide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final field in fields) ...[
                field,
                const SizedBox(height: AppTokens.s8),
              ],
            ],
          );
        }
        return Wrap(
          spacing: AppTokens.s8,
          runSpacing: AppTokens.s8,
          children: [
            for (final field in fields) SizedBox(width: 260, child: field),
          ],
        );
      },
    );
  }
}

class _LifecycleProgress extends StatelessWidget {
  const _LifecycleProgress({required this.run});

  final SetupWizardRun run;

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
          Row(
            children: [
              Expanded(
                child: Text(
                  'الحالة الحالية: ${run.stateLabel}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              StatusPill(
                text: run.isTerminal ? 'نهائية' : 'قيد التشغيل',
                tone: run.isTerminal ? PillTone.neutral : PillTone.blue,
                dot: true,
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s8),
          Text(
            _nextLifecycleHint(run.state),
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.busy,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool busy;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: enabled && !busy ? onPressed : null,
      icon: busy
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon),
      label: Text(busy ? 'جاري التنفيذ' : label),
    );
  }
}

class _GeneratedScriptBox extends StatelessWidget {
  const _GeneratedScriptBox({required this.result});

  final SetupWizardScriptResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s12),
      decoration: BoxDecoration(
        color: AppTokens.warningBg,
        borderRadius: BorderRadius.circular(AppTokens.r8),
        border: Border.all(color: AppTokens.warningMed),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'سكربت الربط الموحد',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppTokens.warningFg,
                      ),
                ),
              ),
              TextButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: result.script));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم نسخ سكربت الربط')),
                  );
                },
                icon: const Icon(Icons.copy_outlined),
                label: const Text('نسخ'),
              ),
            ],
          ),
          if (result.warning.isNotEmpty) ...[
            const SizedBox(height: AppTokens.s8),
            Text(
              result.warning,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTokens.warningFg,
                    height: 1.4,
                  ),
            ),
          ],
          const SizedBox(height: AppTokens.s8),
          SelectableText(
            [
              if (result.shortCode.isNotEmpty)
                'رمز السكربت: ${result.shortCode}',
              if (result.expiresAt.isNotEmpty) 'ينتهي في: ${result.expiresAt}',
            ].join('  •  '),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTokens.warningFg,
                ),
          ),
          const SizedBox(height: AppTokens.s8),
          Container(
            constraints: const BoxConstraints(maxHeight: 260),
            padding: const EdgeInsets.all(AppTokens.s12),
            decoration: BoxDecoration(
              color: AppTokens.card,
              borderRadius: BorderRadius.circular(AppTokens.r8),
              border: Border.all(color: AppTokens.warningMed),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                result.script,
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
      ),
    );
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
                  'ابدأ تشغيلًا جديدًا عند تجهيز راوتر جديد، ثم أكمل الخطوات المتاحة من التطبيق مع متابعة التشخيصات والجاهزية.',
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
                    if (run.nasDeviceId > 0) 'رقم الراوتر: ${run.nasDeviceId}',
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

PillTone _routerServiceTone(String status) => switch (status) {
      'active' => PillTone.green,
      'inactive' => PillTone.neutral,
      'unknown' => PillTone.amber,
      _ => PillTone.neutral,
    };

PillTone _diagnosticSeverityTone(String severity) => switch (severity) {
      'error' || 'critical' => PillTone.red,
      'warning' || 'warn' => PillTone.amber,
      _ => PillTone.blue,
    };

IconData _routerServiceIcon(String key) {
  return switch (key) {
    'hotspot' => Icons.wifi_outlined,
    'broadband' => Icons.settings_input_component_outlined,
    'block-sites' => Icons.block_outlined,
    'open-sites' => Icons.check_circle_outline,
    'public-ip' => Icons.public_outlined,
    'remote-access' => Icons.vpn_key_outlined,
    _ => Icons.miscellaneous_services_outlined,
  };
}

String _registeredRouterLabel(SetupWizardRun run) {
  final name =
      run.routerName.trim().isEmpty ? 'راوتر بدون اسم' : run.routerName;
  return '$name - رقم الراوتر ${run.nasDeviceId}';
}

String _safeArabicDetail(String value) {
  final text = value.trim();
  if (text.isEmpty) return '';
  if (_containsArabic(text)) return text;
  return 'تفاصيل تقنية متاحة من الخادم، وتحتاج صياغة عربية في المصدر.';
}

String _nextLifecycleHint(String state) {
  return switch (state) {
    'COLLECTING' =>
      'أدخل اسم الراوتر ونوعه، ثم احفظ بيانات الراوتر للانتقال إلى التخطيط.',
    'PLANNING' =>
      'أدخل عنوان الخادم العام ومفتاح الخادم العام، ثم ولّد سكربت الربط والصقه في الراوتر.',
    'AWAITING_HANDSHAKE' =>
      'بعد تشغيل السكربت على الراوتر، الصق مفتاح الراوتر العام أو مخرجات السكربت هنا.',
    'APPLYING_SERVER_PEER' =>
      'طبّق peer على الخادم حتى يتعرف الخادم على الراوتر داخل النفق.',
    'VERIFYING' =>
      'عند نجاح الاتصال أو ظهور handshake، أكد الاتصال للانتقال إلى التسجيل.',
    'REGISTERING' =>
      'سجل الراوتر في النظام حتى يظهر ضمن أجهزة الشبكة وإدارة MikroTik.',
    'COMPLETE' =>
      'اكتمل هذا التشغيل. تستطيع إدارة الراوتر من صفحات الشبكة والخدمات.',
    'BLOCKED' => 'هذا التشغيل متوقف ويحتاج مراجعة التشخيص قبل المتابعة.',
    _ => 'راجع حالة التشغيل الحالية واختر الخطوة المتاحة فقط.',
  };
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
