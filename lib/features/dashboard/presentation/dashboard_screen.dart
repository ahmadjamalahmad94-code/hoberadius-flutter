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
          inlineActions: true,
          actions: [
            IconButton(
              tooltip: 'تحديث',
              onPressed: () => ref.invalidate(dashboardFutureProvider),
              icon: Icon(Icons.refresh, color: p.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s12),
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
          : _BatchGrid(batches: batches.take(4).toList()),
    );
  }
}

/// Recent batches as a tight 2-column grid of equal cards (same visual
/// language as the stat cells above); a leftover odd card spans the row.
class _BatchGrid extends StatelessWidget {
  const _BatchGrid({required this.batches});
  final List<RecentBatch> batches;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < batches.length; i += 2) {
      final a = batches[i];
      final b = i + 1 < batches.length ? batches[i + 1] : null;
      rows.add(
        b == null
            ? _BatchCard(batch: a)
            : Row(
                children: [
                  Expanded(child: _BatchCard(batch: a)),
                  const SizedBox(width: AppTokens.s8),
                  Expanded(child: _BatchCard(batch: b)),
                ],
              ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: AppTokens.s8),
          rows[i],
        ],
      ],
    );
  }
}

class _BatchCard extends StatelessWidget {
  const _BatchCard({required this.batch});
  final RecentBatch batch;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final title = batch.packageName.isNotEmpty
        ? batch.packageName
        : (batch.batchCode.isNotEmpty ? batch.batchCode : 'حزمة بدون اسم');
    // When the title already fell back to the code, don't repeat it below.
    final code = batch.packageName.isNotEmpty && batch.batchCode.isNotEmpty
        ? batch.batchCode
        : '#${batch.id}';
    final total = batch.total;
    final ratio = total > 0 ? (batch.used / total).clamp(0.0, 1.0) : 0.0;
    return _TapCard(
      onTap: batch.id > 0
          ? () => context.goNamed(
                'card-batch-detail',
                pathParameters: {'id': '${batch.id}'},
              )
          : null,
      radius: AppTokens.s12,
      decoration: BoxDecoration(
        color: p.surfaceTinted,
        borderRadius: BorderRadius.circular(AppTokens.s12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.s12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.style_outlined, color: p.brand, size: 18),
                const SizedBox(width: AppTokens.s8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelLarge.copyWith(
                      color: p.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              code,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textDirection: TextDirection.ltr,
              style: AppTypography.caption.copyWith(color: p.textMuted),
            ),
            const SizedBox(height: AppTokens.s8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 6,
                backgroundColor: p.card,
                valueColor: AlwaysStoppedAnimation(p.brand),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'مستخدم',
                  style: AppTypography.caption.copyWith(color: p.textMuted),
                ),
                const Spacer(),
                // LTR so «used / total» never flips to «total / used» in RTL.
                Text(
                  '${batch.used} / $total',
                  textDirection: TextDirection.ltr,
                  style: AppTypography.labelMedium.copyWith(
                    color: p.brand,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
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
    final items = <_StatItem>[
      if (metrics.expiredSubscribers > 0)
        _StatItem(
          icon: Icons.event_busy_outlined,
          label: 'منتهٍ اشتراكهم',
          value: '${metrics.expiredSubscribers}',
          bg: p.infoBg,
          fg: p.infoStrong,
          onTap: () => context.goNamed(
            'subscribers',
            queryParameters: const {'status': 'expired'},
          ),
        ),
      if (metrics.expiringSoon > 0)
        _StatItem(
          icon: Icons.hourglass_bottom,
          label: 'ينتهي خلال ٣ أيام',
          value: '${metrics.expiringSoon}',
          bg: p.warningBg,
          fg: p.warningStrong,
          onTap: () => context.goNamed(
            'subscribers',
            queryParameters: const {'status': 'expiring_3d'},
          ),
        ),
      if (metrics.suspendedSubscribers > 0)
        _StatItem(
          icon: Icons.pause_circle_outline,
          label: 'موقوفون',
          value: '${metrics.suspendedSubscribers}',
          bg: p.warningBg,
          fg: p.warningStrong,
          onTap: () => context.goNamed(
            'subscribers',
            queryParameters: const {'status': 'suspended'},
          ),
        ),
      if (metrics.disabledSubscribers > 0)
        _StatItem(
          icon: Icons.block,
          label: 'معطّلون',
          value: '${metrics.disabledSubscribers}',
          bg: p.surfaceTinted,
          fg: p.textSecondary,
          onTap: () => context.goNamed(
            'subscribers',
            queryParameters: const {'status': 'disabled'},
          ),
        ),
      if (metrics.bannedSubscribers > 0)
        _StatItem(
          icon: Icons.gpp_bad_outlined,
          label: 'محظورون',
          value: '${metrics.bannedSubscribers}',
          bg: p.dangerBg,
          fg: p.dangerStrong,
          onTap: () => context.goNamed(
            'subscribers',
            queryParameters: const {'status': 'banned'},
          ),
        ),
      if (metrics.hasTopPlan)
        _StatItem(
          icon: Icons.star_outline,
          label: 'الأكثر استخدامًا',
          value: '${metrics.topPlanName} · ${metrics.topPlanSubs} مشترك',
          bg: p.brandSoft,
          fg: p.brandInk,
          full: true,
          onTap: () => context.goNamed('plans'),
        ),
    ];
    return AppCard(
      title: 'متابعة المشتركين',
      icon: Icons.people_alt_outlined,
      child: _StatGrid(items: items),
    );
  }
}

/// One cell of a [_StatGrid]: an icon, a small muted label and a bold value.
class _StatItem {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.bg,
    required this.fg,
    this.full = false,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color bg;
  final Color fg;

  /// Where tapping the cell leads (its underlying screen/filter).
  final VoidCallback? onTap;

  /// Spans the whole row (long values such as a plan name or a hostname).
  final bool full;
}

/// Tight, uniform grid: two equal columns, every cell the same height, no
/// ragged pill widths. A leftover odd cell and any [_StatItem.full] cell take
/// the whole row, so the grid never leaves a white hole on one side.
class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.items});
  final List<_StatItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final halves = items.where((i) => !i.full).toList();
    final fulls = items.where((i) => i.full).toList();
    final rows = <Widget>[];
    for (var i = 0; i < halves.length; i += 2) {
      final a = halves[i];
      final b = i + 1 < halves.length ? halves[i + 1] : null;
      rows.add(
        b == null
            ? _StatCell(item: a)
            : Row(
                children: [
                  Expanded(child: _StatCell(item: a)),
                  const SizedBox(width: AppTokens.s8),
                  Expanded(child: _StatCell(item: b)),
                ],
              ),
      );
    }
    for (final f in fulls) {
      rows.add(_StatCell(item: f));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: AppTokens.s8),
          rows[i],
        ],
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.item});
  final _StatItem item;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return _TapCard(
      onTap: item.onTap,
      radius: AppTokens.s12,
      decoration: BoxDecoration(
        color: item.bg,
        borderRadius: BorderRadius.circular(AppTokens.s12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.s12,
          vertical: AppTokens.s8,
        ),
        child: Row(
          children: [
            Icon(item.icon, color: item.fg, size: 18),
            const SizedBox(width: AppTokens.s8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: p.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelLarge.copyWith(
                      color: item.fg,
                      fontWeight: FontWeight.w900,
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
        onTap: () => context.goNamed('subscribers'),
      ),
      _MetricTile(
        icon: Icons.online_prediction,
        label: 'متّصلون الآن',
        value: '${metrics.onlineNow}',
        tone: _MetricTone.success,
        onTap: () => context.goNamed('sessions'),
      ),
      _MetricTile(
        icon: Icons.workspace_premium_outlined,
        label: 'الباقات',
        value: '${metrics.plans}',
        sub: metrics.plans > 0
            ? '${metrics.enabledPlans} مفعّلة · ${metrics.disabledPlans} معطّلة'
            : null,
        tone: _MetricTone.brand,
        onTap: () => context.goNamed('plans'),
      ),
      _MetricTile(
        icon: Icons.credit_card_outlined,
        label: 'الكروت المُولَّدة',
        value: '${metrics.totalCards}',
        sub: '${metrics.usedCards} مُستخدَمة · ${metrics.availableCards} متاح',
        tone: _MetricTone.warning,
        onTap: () => context.goNamed('cards'),
      ),
      _MetricTile(
        icon: Icons.router_outlined,
        label: 'أجهزة الشبكة',
        value: '${metrics.nasDevices}',
        sub: metrics.nasDevices > 0 ? '${metrics.nasEnabled} مفعّلة' : null,
        tone: _MetricTone.info,
        onTap: () => context.goNamed('nas'),
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
          // Denser tiles: the compact layout (icon+label row, then value/sub)
          // needs far less height than the old stacked one, so widen the ratio
          // to cut the empty white space the square cells used to leave.
          childAspectRatio: c.maxWidth < 520
              ? 1.3
              : c.maxWidth < 760
                  ? 1.6
                  : 2.2,
          children: tiles,
        );
      },
    );
  }
}

/// A decorated card that is tappable with a visible ripple: the decoration is
/// painted as [Ink] on a transparent [Material] so the InkWell splash shows on
/// top of the card's own background (a plain Container would hide it).
class _TapCard extends StatelessWidget {
  const _TapCard({
    required this.decoration,
    required this.radius,
    required this.child,
    this.onTap,
  });
  final BoxDecoration decoration;
  final double radius;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (onTap == null) {
      return DecoratedBox(decoration: decoration, child: child);
    }
    return Material(
      type: MaterialType.transparency,
      child: Ink(
        decoration: decoration,
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onTap,
          child: child,
        ),
      ),
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
    this.onTap,
  });
  final IconData icon;
  final String label;
  final String value;
  final _MetricTone tone;
  final String? sub;
  final bool primary;
  final VoidCallback? onTap;

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
    return _TapCard(
      onTap: onTap,
      radius: AppTokens.r14,
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
          final labelWidget = Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelSmall.copyWith(
              color:
                  primary ? Colors.white.withValues(alpha: 0.86) : p.textMuted,
            ),
          );
          final valueWidget = Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.kpi.copyWith(
              color: pal.valueFg,
              fontSize: 22,
            ),
          );
          final subWidget = sub != null
              ? Text(
                  sub!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: primary
                        ? Colors.white.withValues(alpha: 0.78)
                        : p.textMuted,
                  ),
                )
              : null;

          // Compact (phone): icon + label share the top row, the number and
          // details sit just below with tight spacing — no filler gap.
          if (compact) {
            return Padding(
              padding: const EdgeInsets.all(AppTokens.s12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      iconBox,
                      const SizedBox(width: AppTokens.s8),
                      Expanded(child: labelWidget),
                    ],
                  ),
                  const SizedBox(height: AppTokens.s8),
                  valueWidget,
                  if (subWidget != null) ...[
                    const SizedBox(height: 2),
                    subWidget,
                  ],
                ],
              ),
            );
          }

          final textBlock = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              labelWidget,
              const SizedBox(height: 2),
              valueWidget,
              if (subWidget != null) subWidget,
            ],
          );
          return Padding(
            padding: const EdgeInsets.all(AppTokens.s12),
            child: Row(
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

  List<_StatItem> _healthItems(AppPalette p) {
    _StatItem status(String label, bool ok, String yes, String no) => _StatItem(
          icon: ok ? Icons.check_circle : Icons.cancel,
          label: label,
          value: ok ? yes : no,
          bg: ok ? p.successBg : p.dangerBg,
          fg: ok ? p.successStrong : p.dangerStrong,
        );
    _StatItem info(IconData icon, String label, String value) => _StatItem(
          icon: icon,
          label: label,
          value: value,
          bg: p.surfaceTinted,
          fg: p.brand,
        );
    return [
      if (metrics.dbOk != null)
        status('قاعدة البيانات', metrics.dbOk!, 'متصلة', 'غير متصلة'),
      if (metrics.radiusOk != null)
        status('RADIUS', metrics.radiusOk!, 'جاهز', 'غير جاهز'),
      if (metrics.pingOk != null)
        status(
          'الإنترنت',
          metrics.pingOk!,
          metrics.pingMs == null
              ? 'متاح'
              : '${metrics.pingMs!.toStringAsFixed(1)} مللي ثانية',
          'غير متاح',
        ),
      if (metrics.dnsOk != null) status('DNS', metrics.dnsOk!, 'سليم', 'فشل'),
      if (metrics.systemUptime.isNotEmpty)
        info(Icons.power_settings_new, 'تشغيل النظام', metrics.systemUptime),
      if (metrics.processUptime.isNotEmpty)
        info(Icons.timer_outlined, 'تشغيل التطبيق', metrics.processUptime),
    ];
  }

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
          _StatGrid(items: _healthItems(AppPalette.of(context))),
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
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelMedium.copyWith(
                  color: p.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: AppTokens.s8),
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
