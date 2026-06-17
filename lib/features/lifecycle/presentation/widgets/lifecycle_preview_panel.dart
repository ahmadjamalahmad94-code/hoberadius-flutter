import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/status_pill.dart';
import '../../application/lifecycle_providers.dart';
import '../../domain/lifecycle_model.dart';

class LifecyclePreviewPanel extends StatelessWidget {
  const LifecyclePreviewPanel({
    super.key,
    required this.preview,
    required this.running,
    required this.onRun,
  });

  final LifecyclePreview preview;
  final bool running;
  final VoidCallback onRun;

  @override
  Widget build(BuildContext context) {
    final totals = preview.totals;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 700 ? 4 : 2;
              const gap = AppTokens.s8;
              final tileW =
                  ((constraints.maxWidth - gap * (columns - 1)) / columns)
                      .floorToDouble();
              final metrics = <Widget>[
                _Metric('كروت ستؤرشف', totals.cards, Icons.credit_card),
                _Metric('مشتركون سيؤرشفون', totals.subscribers, Icons.person),
                _Metric('حزم متأثرة', totals.batchesImpacted, Icons.inventory),
                _Metric('بانتظار الأرشفة', totals.pendingArchive, Icons.timer),
              ];
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final m in metrics) SizedBox(width: tileW, child: m),
                ],
              );
            },
          ),
          const SizedBox(height: AppTokens.s12),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppTokens.s8,
            runSpacing: AppTokens.s8,
            children: [
              StatusPill(
                text: preview.dryRun ? 'معاينة فقط' : 'تنفيذ',
                tone: preview.dryRun ? PillTone.blue : PillTone.green,
              ),
              ElevatedButton.icon(
                onPressed: running ? null : onRun,
                icon: running
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.archive_outlined),
                label: Text(running ? 'جار التنفيذ...' : 'تشغيل يدوي'),
              ),
            ],
          ),
          if (preview.policies.isNotEmpty) ...[
            const Divider(height: 24),
            for (final item in preview.policies.take(3)) ...[
              _PreviewPolicyRow(item: item),
              const SizedBox(height: AppTokens.s8),
            ],
          ],
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value, this.icon);
  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s12),
      decoration: BoxDecoration(
        color: AppTokens.surfaceMuted,
        borderRadius: BorderRadius.circular(AppTokens.r14),
        border: Border.all(color: AppTokens.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTokens.brandSoft,
            child: Icon(icon, color: AppTokens.brand, size: 18),
          ),
          const SizedBox(width: AppTokens.s8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTokens.textMuted,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '$value',
                  style: const TextStyle(
                    color: AppTokens.sidebarBg,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewPolicyRow extends StatelessWidget {
  const _PreviewPolicyRow({required this.item});
  final LifecyclePolicyPreview item;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppTokens.s8,
      runSpacing: AppTokens.s8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        StatusPill(
          text: lifecycleEntityLabel(item.policy.entityType),
          tone: item.supported ? PillTone.cyan : PillTone.neutral,
        ),
        Text(
          'كروت: ${item.cardsCount} · مشتركون: ${item.subscribersCount}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        if (!item.supported)
          const Text(
            'محفوظة كسياسة فقط ولا ينفذها العامل الحالي',
            style: TextStyle(color: AppTokens.textMuted),
          ),
      ],
    );
  }
}
