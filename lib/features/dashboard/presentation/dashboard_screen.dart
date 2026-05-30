import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/hub_error_state.dart';
import '../../../shared/widgets/page_header.dart';
import '../data/dashboard_repository.dart';
import '../domain/dashboard_model.dart';

final dashboardFutureProvider =
    FutureProvider.autoDispose<DashboardMetrics>((ref) {
  return ref.watch(dashboardRepositoryProvider).fetch();
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dashboardFutureProvider);
    final p = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'لوحة التحكم',
          actions: [
            IconButton(
              tooltip: 'تحديث',
              onPressed: () => ref.invalidate(dashboardFutureProvider),
              icon: Icon(Icons.refresh, color: p.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s16),
        async.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppTokens.s40),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => HubErrorState(
            title: 'تعذّر جلب بيانات اللوحة',
            subtitle: 'افحص اتصال التطبيق بالريدياس ثم حاول التحديث مرة أخرى.',
            onRetry: () => ref.invalidate(dashboardFutureProvider),
            showToastOnce: true,
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
        if (metrics.cpuPct != null ||
            metrics.ramPct != null ||
            metrics.diskPct != null)
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

enum _MetricTone { brand, success, warning, info }

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
        tone: _MetricTone.brand,
        primary: true,
      ),
      _MetricTile(
        icon: Icons.online_prediction,
        label: 'متّصلون الآن',
        value: '${metrics.onlineNow}',
        tone: _MetricTone.success,
      ),
      _MetricTile(
        icon: Icons.workspace_premium_outlined,
        label: 'الباقات',
        value: '${metrics.plans}',
        tone: _MetricTone.brand,
      ),
      _MetricTile(
        icon: Icons.credit_card_outlined,
        label: 'الكروت المُولَّدة',
        value: '${metrics.totalCards}',
        sub: '${metrics.usedCards} مُستخدَمة',
        tone: _MetricTone.warning,
      ),
      _MetricTile(
        icon: Icons.router_outlined,
        label: 'أجهزة الشبكة',
        value: '${metrics.nasDevices}',
        tone: _MetricTone.info,
      ),
    ];
    return LayoutBuilder(
      builder: (ctx, c) {
        final cols = c.maxWidth >= 1100
            ? 5
            : c.maxWidth >= 760
                ? 3
                : 2;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: cols,
          mainAxisSpacing: AppTokens.s12,
          crossAxisSpacing: AppTokens.s12,
          childAspectRatio: c.maxWidth < 520 ? 1.45 : 2.2,
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
    this.primary = false,
  });
  final IconData icon;
  final String label;
  final String value;
  final _MetricTone tone;
  final String? sub;
  final bool primary;

  ({Color bg, Color fg, Color valueFg, Gradient? gradient}) _palette(
    AppPalette p,
  ) {
    if (primary) {
      return (
        bg: Colors.transparent,
        fg: Colors.white,
        valueFg: Colors.white,
        gradient: p.brandGradient,
      );
    }
    final (chip, ink) = switch (tone) {
      _MetricTone.brand => (p.brandSoft, p.brandInk),
      _MetricTone.success => (p.successBg, p.successFg),
      _MetricTone.warning => (p.warningBg, p.warningFg),
      _MetricTone.info => (p.infoBg, p.infoFg),
    };
    return (
      bg: chip,
      fg: ink,
      valueFg: p.textPrimary,
      gradient: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final pal = _palette(p);
    return Container(
      decoration: BoxDecoration(
        color: primary ? null : p.card,
        gradient: pal.gradient,
        borderRadius: BorderRadius.circular(AppTokens.r14),
        border: primary ? null : Border.all(color: p.border),
        boxShadow: primary
            ? [
                BoxShadow(
                  color: p.brand.withValues(alpha: 0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : p.shCard,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 180;
          final iconBox = Container(
            width: compact ? 36 : 44,
            height: compact ? 36 : 44,
            decoration: BoxDecoration(
              color: primary ? Colors.white.withValues(alpha: 0.18) : pal.bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: primary ? Colors.white : pal.fg,
              size: compact ? 20 : 22,
            ),
          );
          final textBlock = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                maxLines: compact ? 2 : 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelSmall.copyWith(
                  color: primary
                      ? Colors.white.withValues(alpha: 0.86)
                      : p.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.kpi.copyWith(
                  color: pal.valueFg,
                  fontSize: 22,
                ),
              ),
              if (sub != null)
                Text(
                  sub!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: primary
                        ? Colors.white.withValues(alpha: 0.78)
                        : p.textMuted,
                  ),
                ),
            ],
          );
          return Padding(
            padding: const EdgeInsets.all(AppTokens.s12),
            child: compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [iconBox, const Spacer(), textBlock],
                  )
                : Row(
                    children: [
                      iconBox,
                      const SizedBox(width: AppTokens.s12),
                      Expanded(child: textBlock),
                    ],
                  ),
          );
        },
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: _Bar(label: 'المعالج', pct: metrics.cpuPct)),
              const SizedBox(width: AppTokens.s16),
              Expanded(child: _Bar(label: 'الذاكرة', pct: metrics.ramPct)),
              const SizedBox(width: AppTokens.s16),
              Expanded(child: _Bar(label: 'القرص', pct: metrics.diskPct)),
            ],
          ),
          const SizedBox(height: AppTokens.s12),
          Wrap(
            spacing: AppTokens.s8,
            runSpacing: AppTokens.s8,
            children: [
              if (metrics.hostname.isNotEmpty)
                _HealthChip(icon: Icons.dns_outlined, text: metrics.hostname),
              if (metrics.systemUptime.isNotEmpty)
                _HealthChip(
                  icon: Icons.power_settings_new,
                  text: 'النظام ${metrics.systemUptime}',
                ),
              if (metrics.processUptime.isNotEmpty)
                _HealthChip(
                  icon: Icons.timer_outlined,
                  text: 'التطبيق ${metrics.processUptime}',
                ),
              if (metrics.pingOk != null)
                _HealthChip(
                  icon: metrics.pingOk! ? Icons.public : Icons.public_off,
                  text: metrics.pingMs == null
                      ? 'Google ${metrics.pingOk! ? 'متاح' : 'غير متاح'}'
                      : 'Google ${metrics.pingMs!.toStringAsFixed(1)}ms',
                ),
              if (metrics.dnsOk != null)
                _HealthChip(
                  icon: metrics.dnsOk!
                      ? Icons.travel_explore
                      : Icons.error_outline,
                  text: 'DNS ${metrics.dnsOk! ? 'سليم' : 'فشل'}',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HealthChip extends StatelessWidget {
  const _HealthChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s12,
        vertical: AppTokens.s8,
      ),
      decoration: BoxDecoration(
        color: p.brandSoft,
        border: Border.all(color: p.brandLine),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: p.brand, size: 16),
          const SizedBox(width: AppTokens.s8),
          Text(
            text,
            style: AppTypography.labelSmall.copyWith(
              color: p.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
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
    final p = AppPalette.of(context);
    final val = pct ?? 0;
    final color = val >= 80
        ? p.dangerStrong
        : val >= 60
            ? p.warningStrong
            : p.brand;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: p.textSecondary,
              ),
            ),
            const Spacer(),
            Text(
              pct == null ? '—' : '${pct!.toStringAsFixed(0)}٪',
              style: AppTypography.labelLarge.copyWith(color: color),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: pct == null ? null : (val / 100).clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: p.surfaceTinted,
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
    final p = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.s8),
      child: Row(
        children: [
          Icon(Icons.circle, size: 8, color: p.brand),
          const SizedBox(width: AppTokens.s8),
          Expanded(
            child: Text(
              '${_dashboardActionLabel(event.action)} — ${_dashboardTargetLabel(event.targetType)}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyMedium.copyWith(color: p.textPrimary),
            ),
          ),
          Text(
            _dashboardActorLabel(event.actor),
            style: AppTypography.caption.copyWith(color: p.textMuted),
          ),
        ],
      ),
    );
  }
}

String _dashboardActionLabel(String value) {
  final a = value.toLowerCase();
  if (a.contains('payment')) return 'دفعة مالية';
  if (a.contains('loan')) return 'سلفة';
  if (a.contains('archive')) return 'أرشفة';
  if (a.contains('restore')) return 'استعادة';
  if (a.contains('disable')) return 'تعطيل';
  if (a.contains('enable')) return 'تفعيل';
  if (a.contains('delete')) return 'حذف';
  if (a.contains('create')) return 'إنشاء';
  if (a.contains('update')) return 'تعديل';
  if (a.contains('disconnect')) return 'قطع جلسة';
  return value.replaceAll('_', ' ');
}

String _dashboardTargetLabel(String value) {
  final t = value.toLowerCase();
  if (t.contains('subscriber') || t.contains('user')) return 'مستفيد';
  if (t.contains('card_batch')) return 'حزمة بطاقات';
  if (t.contains('card')) return 'بطاقة';
  if (t.contains('plan') || t.contains('profile')) return 'باقة';
  if (t.contains('nas')) return 'جهاز شبكة';
  if (t.contains('admin')) return 'مدير';
  if (t.contains('distributor')) return 'موزع';
  return value.replaceAll('_', ' ');
}

String _dashboardActorLabel(String value) {
  if (value.isEmpty) return '';
  if (value.startsWith('api-token')) return 'رمز تكامل';
  if (value.startsWith('actor:')) {
    return value.replaceFirst('actor:', '').trim();
  }
  return value;
}
