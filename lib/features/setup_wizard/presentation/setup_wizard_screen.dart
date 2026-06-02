import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
              'متابعة جاهزية الخادم وتشغيلات إعداد الراوتر من عقد الربط الآمن. هذه الصفحة لا تطبق أوامر على الراوتر ولا تعدل بوابة العميل.',
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
            text: safeOperations.canApplyRouterChanges ? 'تطبيق مباشر' : 'قراءة آمنة',
            tone: safeOperations.canApplyRouterChanges ? PillTone.red : PillTone.green,
            dot: true,
          ),
        ],
      ),
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
              subtitle: 'فحص الجاهزية غير مفعل أو لم يرجع الخادم تفاصيل إضافية.',
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
              subtitle: 'ابدأ تشغيلًا جديدًا عند تجهيز راوتر جديد، ثم أكمل التطبيق من شاشة الويب المحمية.',
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
