import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/status_pill.dart';
import '../../domain/bandwidth_schedule_model.dart';

class BandwidthSchedulesList extends StatelessWidget {
  const BandwidthSchedulesList({
    super.key,
    required this.items,
    required this.planNames,
    required this.batchNames,
    required this.applying,
    required this.onApplyDryRun,
    required this.onApplyLive,
  });

  final List<BandwidthSchedule> items;
  final Map<int, String> planNames;
  final Map<int, String> batchNames;
  final bool applying;
  final ValueChanged<BandwidthSchedule> onApplyDryRun;
  final ValueChanged<BandwidthSchedule> onApplyLive;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const AppCard(
        child: EmptyState(
          icon: Icons.schedule_outlined,
          title: 'لا توجد جداول سرعة بعد',
          subtitle: 'أضف أول جدول من النموذج لتجربة العقد.',
        ),
      );
    }
    return AppCard(
      title: 'الجداول الحالية',
      icon: Icons.schedule_outlined,
      child: Column(
        children: [
          for (final item in items) ...[
            _ScheduleTile(
              item: item,
              targetName: _targetName(item, planNames, batchNames),
              applying: applying,
              onApplyDryRun: () => onApplyDryRun(item),
              onApplyLive: () => onApplyLive(item),
            ),
            if (item != items.last) const Divider(height: AppTokens.s24),
          ],
        ],
      ),
    );
  }

  static String _targetName(
    BandwidthSchedule item,
    Map<int, String> planNames,
    Map<int, String> batchNames,
  ) {
    if (item.targetType == 'subscriber') {
      return 'مشترك: ${item.subscriberUsername}';
    }
    if (item.targetType == 'card_batch') {
      final id = item.cardBatchId;
      return 'باقة كروت: ${id == null ? 'غير محددة' : batchNames[id] ?? '#$id'}';
    }
    return 'عرض: ${planNames[item.planId] ?? '#${item.planId}'}';
  }
}

class _ScheduleTile extends StatelessWidget {
  const _ScheduleTile({
    required this.item,
    required this.targetName,
    required this.applying,
    required this.onApplyDryRun,
    required this.onApplyLive,
  });

  final BandwidthSchedule item;
  final String targetName;
  final bool applying;
  final VoidCallback onApplyDryRun;
  final VoidCallback onApplyLive;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppTokens.s8,
          runSpacing: AppTokens.s8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Icon(Icons.speed_outlined, color: p.brand, size: 18),
            Text(
              item.name,
              style: TextStyle(
                color: p.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            StatusPill(
              text: item.enabled ? 'مفعّل' : 'معطّل',
              tone: item.enabled ? PillTone.green : PillTone.neutral,
            ),
            const StatusPill(text: 'تجربة فقط', tone: PillTone.orange),
          ],
        ),
        const SizedBox(height: AppTokens.s8),
        Text(
          '$targetName • ${item.startsAtTime} → ${item.endsAtTime} • أولوية ${item.priority}',
          style: const TextStyle(color: AppTokens.textMuted),
        ),
        const SizedBox(height: AppTokens.s8),
        Wrap(
          spacing: AppTokens.s8,
          runSpacing: AppTokens.s8,
          children: [
            _Metric(label: 'تنزيل', value: '${item.speedDownKbps} Kbps'),
            _Metric(label: 'رفع', value: '${item.speedUpKbps} Kbps'),
            _Metric(label: 'حد تنزيل أدنى', value: '${item.cirDownKbps}'),
            _Metric(label: 'حد رفع أدنى', value: '${item.cirUpKbps}'),
          ],
        ),
        if (item.notes.isNotEmpty) ...[
          const SizedBox(height: AppTokens.s8),
          Text(item.notes, style: const TextStyle(color: AppTokens.textMuted)),
        ],
        const SizedBox(height: AppTokens.s12),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Wrap(
            spacing: AppTokens.s8,
            children: [
              OutlinedButton.icon(
                onPressed: applying ? null : onApplyDryRun,
                icon: const Icon(Icons.science_outlined),
                label: const Text('تجربة تطبيق'),
              ),
              ElevatedButton.icon(
                onPressed: applying ? null : onApplyLive,
                icon: const Icon(Icons.network_check_outlined),
                label: const Text('تطبيق فعلي'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s12,
        vertical: AppTokens.s8,
      ),
      decoration: BoxDecoration(
        color: AppTokens.bg,
        borderRadius: BorderRadius.circular(AppTokens.r10),
        border: Border.all(color: AppTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppTokens.textMuted, fontSize: 11),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppTokens.sidebarBg,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
