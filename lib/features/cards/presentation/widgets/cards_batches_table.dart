import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/status_pill.dart';
import '../../application/cards_list_providers.dart';
import '../../domain/card_model.dart';

class CardsBatchesTable extends ConsumerWidget {
  const CardsBatchesTable({super.key, required this.page});
  final CardBatchOperationsPage page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedBatchIdsProvider);
    final ids = page.items.map((item) => item.id).whereType<int>().toSet();
    final allSelected = ids.isNotEmpty && ids.difference(selected).isEmpty;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(AppTokens.surfaceMuted),
        columns: [
          DataColumn(
            label: Checkbox(
              value: allSelected,
              onChanged: (_) {
                ref.read(selectedBatchIdsProvider.notifier).state =
                    allSelected ? <int>{} : ids;
              },
            ),
          ),
          const DataColumn(label: Text('الحزمة')),
          const DataColumn(label: Text('الحالة')),
          const DataColumn(label: Text('الأعداد')),
          const DataColumn(label: Text('العرض/السرعة')),
          const DataColumn(label: Text('الموزع')),
          const DataColumn(label: Text('القيمة التقديرية')),
          const DataColumn(label: Text('آخر بيانات')),
          const DataColumn(label: Text('إجراءات')),
        ],
        rows: [
          for (final batch in page.items)
            DataRow(
              selected: batch.id != null && selected.contains(batch.id),
              cells: [
                DataCell(
                  Checkbox(
                    value: batch.id != null && selected.contains(batch.id),
                    onChanged: batch.id == null
                        ? null
                        : (_) {
                            final next = {...selected};
                            if (next.contains(batch.id)) {
                              next.remove(batch.id);
                            } else {
                              next.add(batch.id!);
                            }
                            ref.read(selectedBatchIdsProvider.notifier).state =
                                next;
                          },
                  ),
                ),
                DataCell(_BatchName(batch: batch)),
                DataCell(
                  StatusPill(
                    text: batchStatusLabel(batch.displayStatus),
                    tone: batchStatusTone(batch.displayStatus),
                  ),
                ),
                DataCell(_Counts(batch: batch)),
                DataCell(_PlanAndSpeed(batch: batch)),
                DataCell(Text(distributorLabel(batch))),
                DataCell(Text(formatMoney(batch.estimatedValue))),
                DataCell(_Activity(batch: batch)),
                DataCell(_RowActions(batch: batch)),
              ],
            ),
        ],
      ),
    );
  }
}

class _BatchName extends StatelessWidget {
  const _BatchName({required this.batch});
  final CardBatch batch;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('yyyy-MM-dd');
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            batch.batchCode,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTokens.sidebarBg,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            [
              if (batch.displayName.isNotEmpty) batch.displayName,
              if (batch.createdAt != null) df.format(batch.createdAt!),
            ].join(' • '),
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppTokens.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _Counts extends StatelessWidget {
  const _Counts({required this.batch});
  final CardBatch batch;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 270,
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          _MiniCount(label: 'كلها', value: batch.generated),
          _MiniCount(label: 'الأصلي', value: batch.originalCount),
          _MiniCount(label: 'متاح', value: batch.availableCount),
          _MiniCount(label: 'نشط', value: batch.activeCount),
          _MiniCount(label: 'منتهي', value: batch.expiredCount),
          _MiniCount(label: 'مؤرشف', value: batch.archivedCount),
          _MiniCount(label: 'قادم', value: batch.pendingArchiveCount),
          _MiniCount(label: 'تشغيلي', value: batch.operationalRemainingCount),
          _MiniCount(label: 'ملغى', value: batch.revokedCount),
        ],
      ),
    );
  }
}

class _MiniCount extends StatelessWidget {
  const _MiniCount({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTokens.slate100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label $value',
        style: const TextStyle(fontSize: 11, color: AppTokens.textSecondary),
      ),
    );
  }
}

class _PlanAndSpeed extends StatelessWidget {
  const _PlanAndSpeed({required this.batch});
  final CardBatch batch;

  @override
  Widget build(BuildContext context) {
    final speed = [
      if ((batch.planSpeedDownKbps ?? 0) > 0) '↓ ${batch.planSpeedDownKbps}',
      if ((batch.planSpeedUpKbps ?? 0) > 0) '↑ ${batch.planSpeedUpKbps}',
    ].join(' / ');
    return SizedBox(
      width: 190,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            batch.planName.isNotEmpty ? batch.planName : 'بدون عرض',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          Text(
            [
              if (speed.isNotEmpty) speed,
              if (batch.activeSpeedRules > 0)
                '${batch.activeSpeedRules} قاعدة سرعة',
            ].join(' • '),
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppTokens.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _Activity extends StatelessWidget {
  const _Activity({required this.batch});
  final CardBatch batch;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Text(
        [
          '${batch.sessionsCount} جلسة',
          '${batch.uniqueMacs} MAC',
          if (batch.onlineSessions > 0) '${batch.onlineSessions} متصل',
        ].join(' • '),
        style: const TextStyle(color: AppTokens.textSecondary, fontSize: 12),
      ),
    );
  }
}

class _RowActions extends ConsumerWidget {
  const _RowActions({required this.batch});
  final CardBatch batch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (batch.id == null) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'تفاصيل الحزمة',
          icon: const Icon(Icons.open_in_new, size: 18),
          onPressed: () => context.goNamed(
            'card-batch-detail',
            pathParameters: {'id': '${batch.id}'},
          ),
        ),
        IconButton(
          tooltip: 'تعديل الحزمة',
          icon: const Icon(Icons.edit_outlined, size: 18),
          onPressed: () => context.goNamed(
            'card-batch-edit',
            pathParameters: {'id': '${batch.id}'},
          ),
        ),
        IconButton(
          tooltip: 'قواعد السرعة',
          icon: const Icon(Icons.speed_outlined, size: 18),
          onPressed: () => context.goNamed('bandwidth-schedules'),
        ),
      ],
    );
  }
}
