import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/visible_error_message.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/status_pill.dart';
import '../data/mikrotik_repository.dart';
import '../domain/mikrotik_program_model.dart';

final _programStateProvider = FutureProvider.autoDispose
    .family<ProgramState, ({int nasId, String kind})>((ref, args) {
  return ref
      .watch(mikrotikRepositoryProvider)
      .programState(args.nasId, kind: args.kind);
});

/// MikroTik network-programming wizard for one router — generate a plan from a
/// hotspot/pppoe spec against the live router state, apply it (confirm + risk
/// gate), or unprogram. Mirrors the web `mt/<id>/program` page.
class MikrotikProgrammingScreen extends ConsumerStatefulWidget {
  const MikrotikProgrammingScreen({super.key, required this.routerId});

  final int routerId;

  @override
  ConsumerState<MikrotikProgrammingScreen> createState() =>
      _MikrotikProgrammingScreenState();
}

class _MikrotikProgrammingScreenState
    extends ConsumerState<MikrotikProgrammingScreen> {
  String _kind = 'hotspot';
  final _fields = <String, TextEditingController>{};

  ProgramPlanResult? _plan;
  ProgramApplyResult? _applyResult;
  bool _planning = false;
  bool _applying = false;
  String? _error;
  bool _filledFromDefaults = false;

  static const _fieldKeys = [
    'interface',
    'cidr',
    'dns_servers',
    'pool_start',
    'pool_end',
    'rate_limit',
    'hotspot_name',
    'gateway',
    'lease_time',
    'profile_name',
    'service_name',
    'local_address',
  ];

  @override
  void initState() {
    super.initState();
    for (final k in _fieldKeys) {
      _fields[k] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _applyDefaults(ProgramState state) {
    if (_filledFromDefaults) return;
    _filledFromDefaults = true;
    state.formFields.forEach((key, value) {
      final c = _fields[key];
      if (c != null && c.text.isEmpty && value != null) {
        c.text = value.toString();
      }
    });
  }

  Map<String, dynamic> _form() => {
        'kind': _kind,
        for (final k in _fieldKeys) k: _fields[k]!.text.trim(),
      };

  @override
  Widget build(BuildContext context) {
    final async =
        ref.watch(_programStateProvider((nasId: widget.routerId, kind: _kind)));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'رجوع',
              onPressed: () => context.go('/router-operations'),
              icon: const Icon(Icons.arrow_forward),
            ),
            Expanded(
              child: Text(
                'برمجة الراوتر',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTokens.sidebarBg,
                      fontWeight: FontWeight.w800,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s12),
        const AppCard(
          child: Row(
            children: [
              Icon(Icons.warning_amber_outlined, color: AppTokens.amber),
              SizedBox(width: AppTokens.s8),
              Expanded(
                child: Text(
                  'هذه الصفحة تكتب إعدادات هوتسبوت/PPPoE على الراوتر مباشرة. '
                  'ولّد الخطّة وراجع الأوامر والمخاطر قبل التطبيق، ويفضّل وجود '
                  'نسخة احتياطية حديثة.',
                  style: TextStyle(color: AppTokens.textMuted),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.s12),
        async.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(AppTokens.s24),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, _) => EmptyState(
            icon: Icons.error_outline,
            title: 'تعذّر جلب حالة الراوتر',
            subtitle: visibleErrorMessage(e),
          ),
          data: (state) {
            _applyDefaults(state);
            return _formCard(state);
          },
        ),
        if (_error != null) ...[
          const SizedBox(height: AppTokens.s12),
          _ErrorBox(message: _error!),
        ],
        if (_plan != null) ...[
          const SizedBox(height: AppTokens.s16),
          _PlanCard(result: _plan!),
        ],
        if (_applyResult != null) ...[
          const SizedBox(height: AppTokens.s16),
          _ApplyResultCard(result: _applyResult!),
        ],
      ],
    );
  }

  Widget _formCard(ProgramState state) {
    final interfaces = state.interfaces;
    return AppCard(
      title:
          'مواصفة البرمجة — ${state.nasName.isEmpty ? '#${widget.routerId}' : state.nasName}',
      icon: Icons.tune_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _kind,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'نوع البرمجة'),
            items: const [
              DropdownMenuItem(value: 'hotspot', child: Text('هوتسبوت')),
              DropdownMenuItem(value: 'pppoe', child: Text('PPPoE')),
            ],
            onChanged: (v) => setState(() {
              _kind = v ?? 'hotspot';
              _plan = null;
              _applyResult = null;
            }),
          ),
          const SizedBox(height: AppTokens.s12),
          if (interfaces.isEmpty)
            _field('interface', 'الواجهة (interface)')
          else
            _interfaceDropdown(interfaces),
          const SizedBox(height: AppTokens.s12),
          _field('cidr', 'الشبكة (CIDR) مثل 10.5.50.1/24'),
          const SizedBox(height: AppTokens.s12),
          _twoCol(
            _field('pool_start', 'بداية النطاق'),
            _field('pool_end', 'نهاية النطاق'),
          ),
          const SizedBox(height: AppTokens.s12),
          _field('dns_servers', 'خوادم DNS'),
          const SizedBox(height: AppTokens.s12),
          _field('rate_limit', 'حدّ السرعة (rate-limit) اختياري'),
          if (_kind == 'hotspot') ...[
            const SizedBox(height: AppTokens.s12),
            _field('hotspot_name', 'اسم الهوتسبوت'),
            const SizedBox(height: AppTokens.s12),
            _twoCol(
              _field('gateway', 'البوابة (gateway)'),
              _field('lease_time', 'مدّة الإيجار'),
            ),
          ] else ...[
            const SizedBox(height: AppTokens.s12),
            _twoCol(
              _field('profile_name', 'اسم البروفايل'),
              _field('service_name', 'اسم الخدمة'),
            ),
            const SizedBox(height: AppTokens.s12),
            _field('local_address', 'العنوان المحلّي (local-address)'),
          ],
          const SizedBox(height: AppTokens.s16),
          Wrap(
            spacing: AppTokens.s8,
            runSpacing: AppTokens.s8,
            children: [
              FilledButton.icon(
                onPressed: _planning ? null : _generatePlan,
                icon: _planning
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.fact_check_outlined),
                label: const Text('توليد الخطّة'),
              ),
              OutlinedButton.icon(
                onPressed: (_plan == null || _applying) ? null : _apply,
                icon: _applying
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.bolt_outlined),
                label: const Text('تطبيق'),
              ),
              OutlinedButton.icon(
                onPressed: _applying ? null : _unprogram,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTokens.redInk,
                ),
                icon: const Icon(Icons.layers_clear_outlined),
                label: const Text('إزالة البرمجة'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _interfaceDropdown(List<String> interfaces) {
    final current = _fields['interface']!.text;
    final value = interfaces.contains(current) ? current : null;
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'الواجهة (interface)'),
      items: interfaces
          .map((i) => DropdownMenuItem(value: i, child: Text(i)))
          .toList(),
      onChanged: (v) => setState(() => _fields['interface']!.text = v ?? ''),
    );
  }

  Widget _field(String key, String label) {
    return TextField(
      controller: _fields[key],
      decoration: InputDecoration(labelText: label),
    );
  }

  Widget _twoCol(Widget a, Widget b) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: a),
        const SizedBox(width: AppTokens.s8),
        Expanded(child: b),
      ],
    );
  }

  Future<void> _generatePlan() async {
    setState(() {
      _planning = true;
      _error = null;
      _applyResult = null;
    });
    try {
      final result = await ref.read(mikrotikRepositoryProvider).programPlan(
            widget.routerId,
            _form(),
          );
      if (!mounted) return;
      setState(() => _plan = result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = visibleErrorMessage(e));
    } finally {
      if (mounted) setState(() => _planning = false);
    }
  }

  Future<void> _apply() async {
    final plan = _plan?.plan;
    if (plan == null) return;
    if (plan.hasRisks) {
      _snack('لا يمكن التطبيق وهناك مخاطر غير معالجة — صحّح المدخلات.');
      return;
    }
    final confirmed = await _confirm(
      title: 'تأكيد تطبيق البرمجة',
      body:
          'سيتم تنفيذ ${plan.commands.length} أمرًا على الراوتر مباشرة. متابعة؟',
      confirmLabel: 'تطبيق',
    );
    if (confirmed != true) return;
    setState(() {
      _applying = true;
      _error = null;
    });
    try {
      final response = await ref
          .read(mikrotikRepositoryProvider)
          .programApply(widget.routerId, _form());
      if (!mounted) return;
      setState(() => _applyResult = response.applyResult);
      _snack(
        response.applyResult.ok
            ? 'تم تطبيق البرمجة بنجاح.'
            : 'اكتمل التطبيق مع ملاحظات — راجع الخطوات.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = visibleErrorMessage(e));
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  Future<void> _unprogram() async {
    final confirmed = await _confirm(
      title: 'إزالة البرمجة',
      body: 'سيتم حذف كل كائنات hoberadius:$_kind من الراوتر. هذا إجراء مدمّر.',
      confirmLabel: 'إزالة',
      danger: true,
    );
    if (confirmed != true) return;
    setState(() {
      _applying = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(mikrotikRepositoryProvider)
          .programUnprogram(widget.routerId, _kind);
      if (!mounted) return;
      setState(() => _applyResult = result);
      _snack(result.ok ? 'تمت الإزالة.' : 'اكتملت الإزالة مع ملاحظات.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = visibleErrorMessage(e));
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool?> _confirm({
    required String title,
    required String body,
    required String confirmLabel,
    bool danger = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: danger
                ? FilledButton.styleFrom(backgroundColor: AppTokens.red)
                : null,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s12),
      decoration: BoxDecoration(
        color: AppTokens.dangerBg,
        borderRadius: BorderRadius.circular(AppTokens.r10),
        border: Border.all(color: AppTokens.dangerMed),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTokens.redInk, size: 18),
          const SizedBox(width: AppTokens.s8),
          Expanded(
            child:
                Text(message, style: const TextStyle(color: AppTokens.redInk)),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.result});
  final ProgramPlanResult result;

  @override
  Widget build(BuildContext context) {
    final plan = result.plan;
    return AppCard(
      title: 'الخطّة المُولّدة',
      icon: Icons.list_alt_outlined,
      actions: [
        StatusPill(
          text: plan.hasRisks ? 'مخاطر' : 'جاهزة',
          tone: plan.hasRisks ? PillTone.red : PillTone.green,
          dot: true,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (result.backupWarning.isNotEmpty)
            _Note(
              icon: Icons.backup_outlined,
              tone: PillTone.amber,
              text: result.backupWarning,
            ),
          _bullets('الملخّص', plan.summary, Icons.check_circle_outline),
          if (plan.warnings.isNotEmpty)
            _bullets('تحذيرات', plan.warnings, Icons.warning_amber_outlined),
          if (plan.risks.isNotEmpty)
            _bullets(
              'مخاطر',
              plan.risks,
              Icons.dangerous_outlined,
              color: AppTokens.redInk,
            ),
          const SizedBox(height: AppTokens.s8),
          Text(
            'الأوامر (${plan.commands.length})',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppTokens.sidebarBg,
            ),
          ),
          const SizedBox(height: AppTokens.s8),
          for (final c in plan.commands)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTokens.s8),
                decoration: BoxDecoration(
                  color: AppTokens.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppTokens.r8),
                  border: Border.all(color: AppTokens.border),
                ),
                child: Text(
                  '${c.path}  ${_attrs(c.attrs)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTokens.textSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _attrs(Map<String, dynamic> attrs) =>
      attrs.entries.map((e) => '${e.key}=${e.value}').join(' ');

  Widget _bullets(
    String title,
    List<String> items,
    IconData icon, {
    Color color = AppTokens.textSecondary,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppTokens.sidebarBg,
            ),
          ),
          const SizedBox(height: 4),
          for (final t in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(t, style: TextStyle(color: color)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.tone, required this.text});
  final IconData icon;
  final PillTone tone;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.s8),
      child: Container(
        padding: const EdgeInsets.all(AppTokens.s12),
        decoration: BoxDecoration(
          color: AppTokens.warningBg,
          borderRadius: BorderRadius.circular(AppTokens.r10),
          border: Border.all(color: AppTokens.warningMed),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppTokens.amberInk),
            const SizedBox(width: AppTokens.s8),
            Expanded(
              child:
                  Text(text, style: const TextStyle(color: AppTokens.amberInk)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApplyResultCard extends StatelessWidget {
  const _ApplyResultCard({required this.result});
  final ProgramApplyResult result;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'نتيجة التنفيذ',
      icon: Icons.task_alt_outlined,
      actions: [
        StatusPill(
          text: result.ok ? 'نجح' : 'بمشاكل',
          tone: result.ok ? PillTone.green : PillTone.red,
          dot: true,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (result.summary.isNotEmpty)
            Text(
              result.summary,
              style: const TextStyle(color: AppTokens.textSecondary),
            ),
          if (result.error.isNotEmpty) ...[
            const SizedBox(height: AppTokens.s8),
            Text(result.error, style: const TextStyle(color: AppTokens.redInk)),
          ],
          if (result.steps.isNotEmpty) ...[
            const SizedBox(height: AppTokens.s8),
            for (final s in result.steps)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      s.ok ? Icons.check_circle : Icons.cancel,
                      size: 16,
                      color: s.ok ? AppTokens.greenInk : AppTokens.redInk,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        s.message.isEmpty
                            ? '${s.path} — ${s.status}'
                            : '${s.path} — ${s.message}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTokens.textSecondary,
                        ),
                      ),
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
