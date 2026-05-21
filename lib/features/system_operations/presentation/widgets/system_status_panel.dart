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
        'جلسات RADIUS',
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
                      tone:
                          router.enabled ? PillTone.green : PillTone.neutral,
                    ),
                  )
                  .toList(),
            ),
          ],
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
