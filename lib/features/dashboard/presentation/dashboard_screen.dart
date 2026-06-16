import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../shared/widgets/app_card.dart';
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
    final hasAttention = metrics.expiredSubscribers > 0 ||
        metrics.expiringSoon > 0 ||
        metrics.suspendedSubscribers > 0 ||
        metrics.disabledSubscribers > 0 ||
        metrics.bannedSubscribers > 0 ||
        metrics.hasTopPlan;
    return LayoutBuilder(
      builder: (context, c) {
        final twoCol = c.maxWidth >= 760;
        final batchesCard = _RecentBatchesCard(batches: metrics.recentBatches);
        final alertsCard = _AlertsCard(alerts: metrics.alerts);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _MetricGrid(metrics: metrics),
            if (hasAttention) ...[
              const SizedBox(height: AppTokens.s20),
              _SubscriberAttention(metrics: metrics),
            ],
            const SizedBox(height: AppTokens.s20),
            if (metrics.cpuPct != null ||
                metrics.ramPct != null ||
                metrics.diskPct != null ||
                metrics.dbOk != null ||
                metrics.radiusOk != null)
              _SystemHealth(metrics: metrics),
            const SizedBox(height: AppTokens.s20),
            if (twoCol)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: batchesCard),
                    const SizedBox(width: AppTokens.s16),
                    Expanded(child: alertsCard),
                  ],
                ),
              )
            else ...[
              batchesCard,
              const SizedBox(height: AppTokens.s20),
              alertsCard,
            ],
          ],
        );
      },
    );
  }
}

/// "آخر الحزم" — latest card batches, mirrors web `metrics.recent_batches`.
class _RecentBatchesCard extends StatelessWidget {
  const _RecentBatchesCard({required this.batches});
  final List<RecentBatch> batches;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'آخر الحزم',
      icon: Icons.history_toggle_off,
      child: batches.isEmpty
          ? const _EmptyRow(
              code: '--',
              title: 'لا توجد حزم بعد',
              subtitle: 'ستظهر أحدث الحزم هنا',
            )
          : Column(
              children: [
                for (final b in batches.take(4)) _BatchRow(batch: b),
              ],
            ),
    );
  }
}

class _BatchRow extends StatelessWidget {
  const _BatchRow({required this.batch});
  final RecentBatch batch;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final title = batch.packageName.isNotEmpty
        ? batch.packageName
        : (batch.batchCode.isNotEmpty ? batch.batchCode : 'حزمة بدون اسم');
    final sub = batch.batchCode.isNotEmpty ? batch.batchCode : 'بدون كود';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.s8),
      child: Row(
        children: [
          _CodeChip(text: '#${batch.id}'),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(
                    color: p.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(color: p.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTokens.s8),
          Text(
            '${batch.used} / ${batch.total}',
            style: AppTypography.labelLarge.copyWith(
              color: p.brand,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyRow extends StatelessWidget {
  const _EmptyRow({
    required this.code,
    required this.title,
    required this.subtitle,
  });
  final String code;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.s8),
      child: Row(
        children: [
          _CodeChip(text: code),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    color: p.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(color: p.textMuted),
                ),
              ],
            ),
          ),
          Text(
            '0',
            style: AppTypography.labelLarge.copyWith(color: p.textMuted),
          ),
        ],
      ),
    );
  }
}

class _CodeChip extends StatelessWidget {
  const _CodeChip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: p.surfaceTinted,
        borderRadius: BorderRadius.circular(AppTokens.r8),
      ),
      child: Text(
        text,
        textDirection: TextDirection.ltr,
        style: AppTypography.caption.copyWith(
          color: p.textSecondary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// "ما يحتاج انتباه" — actionable alerts, mirrors web `metrics.alerts`.
class _AlertsCard extends StatelessWidget {
  const _AlertsCard({required this.alerts});
  final List<DashboardAlert> alerts;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return AppCard(
      title: 'ما يحتاج انتباه',
      icon: Icons.warning_amber_rounded,
      child: alerts.isEmpty
          ? _AlertTile(
              tone: (
                bg: p.successBg,
                fg: p.successStrong,
              ),
              icon: Icons.check_circle_outline,
              message: 'لا توجد ملاحظات تشغيلية مهمة الآن.',
            )
          : Column(
              children: [
                for (final a in alerts.take(4))
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppTokens.s8),
                    child: _AlertTile.fromAlert(context, a),
                  ),
              ],
            ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({
    required this.tone,
    required this.icon,
    required this.message,
    this.onTap,
  });

  final ({Color bg, Color fg}) tone;
  final IconData icon;
  final String message;
  final VoidCallback? onTap;

  factory _AlertTile.fromAlert(BuildContext context, DashboardAlert alert) {
    final p = AppPalette.of(context);
    final tone = switch (alert.level) {
      DashboardAlertLevel.danger => (bg: p.dangerBg, fg: p.dangerStrong),
      DashboardAlertLevel.warn => (bg: p.warningBg, fg: p.warningStrong),
      DashboardAlertLevel.info => (bg: p.infoBg, fg: p.infoStrong),
    };
    final icon = switch (alert.level) {
      DashboardAlertLevel.danger => Icons.error_outline,
      DashboardAlertLevel.warn => Icons.warning_amber_rounded,
      DashboardAlertLevel.info => Icons.info_outline,
    };
    final target = _alertRoute(alert.linkEndpoint);
    return _AlertTile(
      tone: tone,
      icon: icon,
      message: alert.message,
      onTap: target == null
          ? null
          : () => _navigateAlert(context, target, alert.linkArgs),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final row = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s12,
        vertical: AppTokens.s12,
      ),
      decoration: BoxDecoration(
        color: tone.bg,
        borderRadius: BorderRadius.circular(AppTokens.r12),
      ),
      child: Row(
        children: [
          Icon(icon, color: tone.fg, size: 18),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodyMedium.copyWith(
                color: p.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: AppTokens.s8),
            Icon(Icons.chevron_left, color: tone.fg, size: 18),
          ],
        ],
      ),
    );
    if (onTap == null) return row;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTokens.r12),
        onTap: onTap,
        child: row,
      ),
    );
  }
}

/// Maps a web alert `link_endpoint` to the Flutter route name, mirroring the
/// destinations `build_alerts` deep-links to. Unknown endpoints are not
/// tappable (returns null), matching the web's safe `'#'` fallback.
String? _alertRoute(String endpoint) {
  switch (endpoint) {
    case 'radius.users_list':
      return 'subscribers';
    case 'radius.cards_generate':
      return 'card-batch-new';
    case 'radius.plans_new':
      return 'plan-new';
    case 'radius.devices_list':
      return 'nas';
    case 'radius.settings_page':
      return 'admin-control';
    case 'radius.mt_alerts_index':
      return 'router-alerts';
    default:
      return '';
  }
}

void _navigateAlert(
  BuildContext context,
  String routeName,
  Map<String, dynamic> args,
) {
  if (routeName.isEmpty) return;
  final query = <String, String>{};
  // Subscribers list filters on ?attention=… exactly like the web link.
  final attention = args['attention'];
  if (routeName == 'subscribers' && attention != null) {
    query['attention'] = attention.toString();
  }
  context.goNamed(routeName, queryParameters: query);
}

/// "متابعة المشتركين" — surfaces the subscriber attention counters and top
/// plan the API already returns (web shows these inline in the module grid).
class _SubscriberAttention extends StatelessWidget {
  const _SubscriberAttention({required this.metrics});
  final DashboardMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final chips = <Widget>[
      if (metrics.expiredSubscribers > 0)
        _AttentionChip(
          icon: Icons.event_busy_outlined,
          label: 'منتهٍ اشتراكهم',
          value: metrics.expiredSubscribers,
          bg: p.infoBg,
          fg: p.infoStrong,
        ),
      if (metrics.expiringSoon > 0)
        _AttentionChip(
          icon: Icons.hourglass_bottom,
          label: 'ينتهي خلال ٣ أيام',
          value: metrics.expiringSoon,
          bg: p.warningBg,
          fg: p.warningStrong,
        ),
      if (metrics.suspendedSubscribers > 0)
        _AttentionChip(
          icon: Icons.pause_circle_outline,
          label: 'موقوفون',
          value: metrics.suspendedSubscribers,
          bg: p.warningBg,
          fg: p.warningStrong,
        ),
      if (metrics.disabledSubscribers > 0)
        _AttentionChip(
          icon: Icons.block,
          label: 'معطّلون',
          value: metrics.disabledSubscribers,
          bg: p.surfaceTinted,
          fg: p.textSecondary,
        ),
      if (metrics.bannedSubscribers > 0)
        _AttentionChip(
          icon: Icons.gpp_bad_outlined,
          label: 'محظورون',
          value: metrics.bannedSubscribers,
          bg: p.dangerBg,
          fg: p.dangerStrong,
        ),
      if (metrics.hasTopPlan)
        _AttentionChip(
          icon: Icons.star_outline,
          label: 'الأكثر استخدامًا: ${metrics.topPlanName}',
          value: metrics.topPlanSubs,
          bg: p.brandSoft,
          fg: p.brandInk,
        ),
    ];
    return AppCard(
      title: 'متابعة المشتركين',
      icon: Icons.people_alt_outlined,
      child: Wrap(
        spacing: AppTokens.s8,
        runSpacing: AppTokens.s8,
        children: chips,
      ),
    );
  }
}

class _AttentionChip extends StatelessWidget {
  const _AttentionChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.bg,
    required this.fg,
  });
  final IconData icon;
  final String label;
  final int value;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s12,
        vertical: AppTokens.s8,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: fg, size: 16),
          const SizedBox(width: AppTokens.s8),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: p.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: AppTokens.s8),
          Text(
            '$value',
            style: AppTypography.labelLarge.copyWith(
              color: fg,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
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
        sub: metrics.plans > 0
            ? '${metrics.enabledPlans} مفعّلة · ${metrics.disabledPlans} معطّلة'
            : null,
        tone: _MetricTone.brand,
      ),
      _MetricTile(
        icon: Icons.credit_card_outlined,
        label: 'الكروت المُولَّدة',
        value: '${metrics.totalCards}',
        sub: '${metrics.usedCards} مُستخدَمة · ${metrics.availableCards} متاح',
        tone: _MetricTone.warning,
      ),
      _MetricTile(
        icon: Icons.router_outlined,
        label: 'أجهزة الشبكة',
        value: '${metrics.nasDevices}',
        sub: metrics.nasDevices > 0 ? '${metrics.nasEnabled} مفعّلة' : null,
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
              if (metrics.dbOk != null)
                _StatusChip(
                  ok: metrics.dbOk!,
                  okText: 'قاعدة البيانات متصلة',
                  failText: 'قاعدة البيانات غير متصلة',
                ),
              if (metrics.radiusOk != null)
                _StatusChip(
                  ok: metrics.radiusOk!,
                  okText: 'RADIUS جاهز',
                  failText: 'RADIUS غير جاهز',
                ),
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
                      ? 'فحص الإنترنت ${metrics.pingOk! ? 'متاح' : 'غير متاح'}'
                      : 'فحص الإنترنت ${metrics.pingMs!.toStringAsFixed(1)} مللي ثانية',
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

/// Service-health pill for db_ok / radius_ok (web shows these as status chips).
class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.ok,
    required this.okText,
    required this.failText,
  });
  final bool ok;
  final String okText;
  final String failText;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final bg = ok ? p.successBg : p.dangerBg;
    final fg = ok ? p.successStrong : p.dangerStrong;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s12,
        vertical: AppTokens.s8,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.cancel,
            color: fg,
            size: 16,
          ),
          const SizedBox(width: AppTokens.s8),
          Text(
            ok ? okText : failText,
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
