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
    this.groupNames = const {},
    this.canEdit = false,
    this.canDelete = false,
    this.onEdit,
    this.onDelete,
    this.onToggleEnabled,
  });

  final List<BandwidthSchedule> items;
  final Map<int, String> groupNames;
  final bool canEdit;
  final bool canDelete;
  final ValueChanged<BandwidthSchedule>? onEdit;
  final ValueChanged<BandwidthSchedule>? onDelete;
  final void Function(BandwidthSchedule item, bool enabled)? onToggleEnabled;
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
          subtitle: 'أضف أول جدول لتحديد السرعة حسب الخطة أو المشترك.',
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
              targetName: _targetName(item, planNames, batchNames, groupNames),
              applying: applying,
              onApplyDryRun: () => onApplyDryRun(item),
              onApplyLive: () => onApplyLive(item),
              onEdit: canEdit && onEdit != null ? () => onEdit!(item) : null,
              onDelete:
                  canDelete && onDelete != null ? () => onDelete!(item) : null,
              onToggleEnabled: canEdit && onToggleEnabled != null
                  ? (v) => onToggleEnabled!(item, v)
                  : null,
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
    Map<int, String> groupNames,
  ) {
    if (item.targetType == 'subscriber_group') {
      final id = item.subscriberGroupId;
      return 'مجموعة مشتركين: ${id == null ? 'غير محددة' : groupNames[id] ?? '#$id'}';
    }
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
    this.onEdit,
    this.onDelete,
    this.onToggleEnabled,
  });

  final BandwidthSchedule item;
  final String targetName;
  final bool applying;
  final VoidCallback onApplyDryRun;
  final VoidCallback onApplyLive;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final ValueChanged<bool>? onToggleEnabled;

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
            if (onToggleEnabled != null)
              Tooltip(
                message: item.enabled ? 'تعطيل الجدول' : 'تفعيل الجدول',
                child: Switch(
                  key: ValueKey('schedule-enabled-${item.id}'),
                  value: item.enabled,
                  onChanged: applying ? null : onToggleEnabled,
                ),
              ),
            const StatusPill(text: 'معاينة متاحة', tone: PillTone.orange),
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
            _Metric(label: 'CIR تنزيل', value: '${item.cirDownKbps} Kbps'),
            _Metric(label: 'CIR رفع', value: '${item.cirUpKbps} Kbps'),
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
            runSpacing: AppTokens.s8,
            children: [
              if (onEdit != null)
                OutlinedButton.icon(
                  key: ValueKey('schedule-edit-${item.id}'),
                  onPressed: applying ? null : onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('تعديل'),
                ),
              if (onDelete != null)
                OutlinedButton.icon(
                  key: ValueKey('schedule-delete-${item.id}'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTokens.red,
                  ),
                  onPressed: applying ? null : onDelete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('حذف'),
                ),
              OutlinedButton.icon(
                onPressed: applying ? null : onApplyDryRun,
                icon: const Icon(Icons.science_outlined),
                label: const Text('معاينة التطبيق'),
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
