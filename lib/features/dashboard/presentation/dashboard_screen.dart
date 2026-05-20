import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../data/dashboard_repository.dart';
import '../domain/dashboard_model.dart';

final dashboardFutureProvider = FutureProvider.autoDispose<DashboardMetrics>((ref) {
  return ref.watch(dashboardRepositoryProvider).fetch();
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dashboardFutureProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'لوحة التحكم',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppTokens.navy900,
                  ),
            ),
            const Spacer(),
            IconButton(
              tooltip: 'تحديث',
              onPressed: () => ref.invalidate(dashboardFutureProvider),
              icon: const Icon(Icons.refresh, color: AppTokens.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s16),
        async.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppTokens.s40),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => EmptyState(
            icon: Icons.error_outline,
            title: 'تعذّر جلب بيانات اللوحة',
            subtitle: '$e',
          ),
          data: (m) => _DashboardBody(metrics: m),
        ),
      ],
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.metrics});
  final DashboardMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MetricGrid(metrics: metrics),
        const SizedBox(height: AppTokens.s20),
        if (metrics.cpuPct != null || metrics.ramPct != null || metrics.diskPct != null)
          _SystemHealth(metrics: metrics),
        const SizedBox(height: AppTokens.s20),
        AppCard(
          title: 'آخر النشاطات',
          icon: Icons.history,
          child: metrics.recentEvents.isEmpty
              ? const EmptyState(title: 'لا توجد أحداث بعد')
              : Column(
                  children: metrics.recentEvents
                      .map((e) => _EventRow(event: e))
                      .toList(),
                ),
        ),
      ],
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});
  final DashboardMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _MetricTile(
        icon: Icons.person_outline,
        label: 'إجمالي المشتركين',
        value: '${metrics.subscribers}',
        tone: AppTokens.cyan500,
      ),
      _MetricTile(
        icon: Icons.online_prediction,
        label: 'متّصلون الآن',
        value: '${metrics.onlineNow}',
        tone: AppTokens.green,
      ),
      _MetricTile(
        icon: Icons.workspace_premium_outlined,
        label: 'الباقات',
        value: '${metrics.plans}',
        tone: AppTokens.purple,
      ),
      _MetricTile(
        icon: Icons.credit_card_outlined,
        label: 'الكروت المُولَّدة',
        value: '${metrics.totalCards}',
        sub: '${metrics.usedCards} مُستخدَمة',
        tone: AppTokens.orange,
      ),
      _MetricTile(
        icon: Icons.router_outlined,
        label: 'أجهزة الشبكة',
        value: '${metrics.nasDevices}',
        tone: AppTokens.navy700,
      ),
    ];
    return LayoutBuilder(
      builder: (ctx, c) {
        final cols = c.maxWidth >= 1100
            ? 5
            : c.maxWidth >= 800
                ? 3
                : c.maxWidth >= 540
                    ? 2
                    : 1;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: cols,
          mainAxisSpacing: AppTokens.s16,
          crossAxisSpacing: AppTokens.s16,
          childAspectRatio: 2.2,
          children: tiles,
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.tone,
    this.sub,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color tone;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.s16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: tone.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: tone, size: 22),
            ),
            const SizedBox(width: AppTokens.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppTokens.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      color: AppTokens.navy900,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (sub != null)
                    Text(
                      sub!,
                      style: const TextStyle(
                        color: AppTokens.textMuted,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SystemHealth extends StatelessWidget {
  const _SystemHealth({required this.metrics});
  final DashboardMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'صحة النظام',
      icon: Icons.monitor_heart_outlined,
      child: Row(
        children: [
          Expanded(child: _Bar(label: 'المعالج', pct: metrics.cpuPct)),
          const SizedBox(width: AppTokens.s16),
          Expanded(child: _Bar(label: 'الذاكرة', pct: metrics.ramPct)),
          const SizedBox(width: AppTokens.s16),
          Expanded(child: _Bar(label: 'القرص', pct: metrics.diskPct)),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.label, required this.pct});
  final String label;
  final double? pct;

  @override
  Widget build(BuildContext context) {
    final val = pct ?? 0;
    final color = val >= 80
        ? AppTokens.red
        : val >= 60
            ? AppTokens.orange
            : AppTokens.cyan500;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppTokens.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              pct == null ? '—' : '${pct!.toStringAsFixed(0)}٪',
              style: TextStyle(color: color, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: pct == null ? null : (val / 100).clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: const Color(0xFFEFF2F7),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event});
  final DashboardEvent event;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.s8),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 8, color: AppTokens.cyan500),
          const SizedBox(width: AppTokens.s8),
          Expanded(
            child: Text(
              '${event.action} — ${event.targetType}',
              style: const TextStyle(color: AppTokens.textPrimary),
            ),
          ),
          Text(
            event.actor,
            style: const TextStyle(color: AppTokens.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
