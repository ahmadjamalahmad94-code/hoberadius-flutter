import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/status_pill.dart';
import '../../domain/system_operations_model.dart';

class SystemStatusPanel extends StatelessWidget {
  const SystemStatusPanel({super.key, required this.status});

  final SystemStatus status;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _Metric(
        'المشتركين',
        status.counts['subscribers'] ?? 0,
        Icons.person_outline,
      ),
      _Metric(
        'الباقات',
        status.counts['access_plans'] ?? 0,
        Icons.workspace_premium_outlined,
      ),
      _Metric(
        'الكروت',
        status.counts['cards'] ?? 0,
        Icons.credit_card_outlined,
      ),
      _Metric(
        'الحزم',
        status.counts['card_batches'] ?? 0,
        Icons.inventory_2_outlined,
      ),
      _Metric(
        'جلسات الريدياس',
        status.counts['radacct'] ?? 0,
        Icons.online_prediction,
      ),
      _Metric('مزامنة معلقة', status.syncQueue['queued'] ?? 0, Icons.sync),
    ];
    return AppCard(
      title: 'حالة النظام',
      icon: Icons.monitor_heart_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth >= 900
                  ? 3
                  : constraints.maxWidth >= 560
                      ? 2
                      : 1;
              return GridView.count(
                crossAxisCount: cols,
                crossAxisSpacing: AppTokens.s8,
                mainAxisSpacing: AppTokens.s8,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: cols == 1 ? 3.2 : 2.4,
                children: tiles.map(_MetricTile.new).toList(),
              );
            },
          ),
          if (status.routers.isNotEmpty) ...[
            const SizedBox(height: AppTokens.s12),
            Wrap(
              spacing: AppTokens.s8,
              runSpacing: AppTokens.s8,
              children: status.routers
                  .map(
                    (router) => StatusPill(
                      text:
                          '${router.name.isEmpty ? router.host : router.name}: ${router.enabled ? 'مفعل' : 'معطل'}',
                      tone: router.enabled ? PillTone.green : PillTone.neutral,
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: AppTokens.s16),
          _VpsHealth(status.vps),
        ],
      ),
    );
  }
}

class _Metric {
  const _Metric(this.label, this.value, this.icon);
  final String label;
  final int value;
  final IconData icon;
}

class _MetricTile extends StatelessWidget {
  const _MetricTile(this.metric);
  final _Metric metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s12),
      decoration: BoxDecoration(
        color: AppTokens.surfaceMuted,
        border: Border.all(color: AppTokens.border),
        borderRadius: BorderRadius.circular(AppTokens.r10),
      ),
      child: Row(
        children: [
          Icon(metric.icon, color: AppTokens.brand),
          const SizedBox(width: AppTokens.s8),
          Expanded(
            child: Text(
              metric.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppTokens.textMuted),
            ),
          ),
          Text(
            '${metric.value}',
            style: const TextStyle(
              color: AppTokens.sidebarBg,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _VpsHealth extends StatelessWidget {
  const _VpsHealth(this.vps);

  final VpsStatus vps;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s12),
      decoration: BoxDecoration(
        color: AppTokens.card,
        border: Border.all(color: AppTokens.border),
        borderRadius: BorderRadius.circular(AppTokens.r14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppTokens.s8,
            runSpacing: AppTokens.s8,
            children: [
              _InfoChip(
                Icons.dns_outlined,
                vps.hostname.isEmpty ? 'VPS' : vps.hostname,
              ),
              if (vps.systemUptime.isNotEmpty)
                _InfoChip(
                  Icons.power_settings_new,
                  'تشغيل النظام: ${vps.systemUptime}',
                ),
              if (vps.processUptime.isNotEmpty)
                _InfoChip(
                  Icons.timer_outlined,
                  'تشغيل التطبيق: ${vps.processUptime}',
                ),
              if ((vps.load['one']) != null)
                _InfoChip(Icons.speed_outlined, 'Load: ${vps.load['one']}'),
              _InfoChip(
                vps.network.pingOk ? Icons.public : Icons.public_off,
                vps.network.pingMs == null
                    ? 'Ping ${vps.network.pingOk ? 'سليم' : 'فشل'}'
                    : 'Ping ${vps.network.pingMs!.toStringAsFixed(1)}ms',
              ),
              _InfoChip(
                vps.network.dnsOk ? Icons.travel_explore : Icons.error_outline,
                'DNS ${vps.network.dnsOk ? 'سليم' : 'فشل'}',
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s12),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 720;
              final bars = [
                _UsageBar(label: 'المعالج', pct: vps.cpuPct),
                _UsageBar(
                  label: 'الذاكرة',
                  pct: vps.memory.percent,
                  caption:
                      _caption(vps.memory.usedHuman, vps.memory.availableHuman),
                ),
                _UsageBar(
                  label: 'القرص',
                  pct: vps.disk.percent,
                  caption: _caption(vps.disk.usedHuman, vps.disk.freeHuman),
                ),
              ];
              if (!wide) {
                return Column(
                  children: [
                    for (final bar in bars) ...[
                      bar,
                      const SizedBox(height: AppTokens.s12),
                    ],
                  ],
                );
              }
              return Row(
                children: [
                  for (var i = 0; i < bars.length; i++) ...[
                    Expanded(child: bars[i]),
                    if (i != bars.length - 1)
                      const SizedBox(width: AppTokens.s12),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _caption(String used, String freeOrAvailable) {
    if (used.isEmpty && freeOrAvailable.isEmpty) return '';
    if (freeOrAvailable.isEmpty) return 'المستخدم: $used';
    return 'المستخدم: $used · المتاح: $freeOrAvailable';
  }
}

class _UsageBar extends StatelessWidget {
  const _UsageBar({required this.label, required this.pct, this.caption = ''});

  final String label;
  final double? pct;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final value = pct ?? 0;
    final color = value >= 85
        ? AppTokens.red
        : value >= 70
            ? AppTokens.amber
            : AppTokens.brand;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
            const Spacer(),
            Text(
              pct == null ? '—' : '${pct!.toStringAsFixed(1)}٪',
              style: TextStyle(color: color, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: pct == null ? null : (value / 100).clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: AppTokens.borderSoft,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        if (caption.isNotEmpty) ...[
          const SizedBox(height: AppTokens.s4),
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppTokens.textMuted, fontSize: 12),
          ),
        ],
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s12,
        vertical: AppTokens.s8,
      ),
      decoration: BoxDecoration(
        color: AppTokens.brandSoft,
        border: Border.all(color: AppTokens.brandLine),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTokens.brand, size: 16),
          const SizedBox(width: AppTokens.s8),
          Text(
            label,
            style: const TextStyle(
              color: AppTokens.sidebarBg,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
