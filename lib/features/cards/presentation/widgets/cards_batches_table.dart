import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/status_pill.dart';
import '../../application/cards_list_providers.dart';
import '../../domain/card_model.dart';

/// Card-package list as a responsive **card/grid** (was a wide DataTable).
/// Mirrors the web's card-style batch view; reflows 1→2 columns and never
/// overflows. All actions (select, bulk via the shared provider, navigate)
/// stay wired.
class CardsBatchesTable extends ConsumerWidget {
  const CardsBatchesTable({super.key, required this.page});
  final CardBatchOperationsPage page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedBatchIdsProvider);
    final ids = page.items.map((item) => item.id).whereType<int>().toSet();
    final allSelected = ids.isNotEmpty && ids.difference(selected).isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Select-all bar (was the table header checkbox).
        if (ids.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppTokens.s8),
            child: Row(
              children: [
                Checkbox(
                  value: allSelected,
                  onChanged: (_) {
                    ref.read(selectedBatchIdsProvider.notifier).state =
                        allSelected ? <int>{} : ids;
                  },
                ),
                const Text(
                  'تحديد الكل',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppTokens.textSecondary,
                  ),
                ),
                const Spacer(),
                if (selected.isNotEmpty)
                  Text(
                    'محدد: ${selected.length}',
                    style: const TextStyle(
                      color: AppTokens.brandInk,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
          ),
        LayoutBuilder(
          builder: (context, c) {
            final cols = c.maxWidth >= 1100 ? 2 : 1;
            const gap = AppTokens.s12;
            final cardW = cols == 1
                ? c.maxWidth
                : (c.maxWidth - gap * (cols - 1)) / cols;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final batch in page.items)
                  SizedBox(
                    width: cardW,
                    child: _BatchCard(
                      batch: batch,
                      selected: batch.id != null && selected.contains(batch.id),
                      onToggle: batch.id == null
                          ? null
                          : () {
                              final next = {...selected};
                              if (next.contains(batch.id)) {
                                next.remove(batch.id);
                              } else {
                                next.add(batch.id!);
                              }
                              ref
                                  .read(selectedBatchIdsProvider.notifier)
                                  .state = next;
                            },
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _BatchCard extends StatelessWidget {
  const _BatchCard({
    required this.batch,
    required this.selected,
    required this.onToggle,
  });
  final CardBatch batch;
  final bool selected;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppTokens.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: Checkbox(
                  value: selected,
                  onChanged: onToggle == null ? null : (_) => onToggle!(),
                ),
              ),
              const SizedBox(width: AppTokens.s8),
              Expanded(child: _BatchName(batch: batch)),
              const SizedBox(width: AppTokens.s8),
              StatusPill(
                text: batchStatusLabel(batch.displayStatus),
                tone: batchStatusTone(batch.displayStatus),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s12),
          _PlanAndSpeed(batch: batch),
          const SizedBox(height: AppTokens.s8),
          _Counts(batch: batch),
          const SizedBox(height: AppTokens.s8),
          Wrap(
            spacing: AppTokens.s8,
            runSpacing: AppTokens.s4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _MetaChip(
                icon: Icons.store_outlined,
                text: distributorLabel(batch),
              ),
              _MetaChip(
                icon: Icons.payments_outlined,
                text: formatMoney(batch.estimatedValue),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s8),
          _Activity(batch: batch),
          const Divider(height: AppTokens.s24),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: _RowActions(batch: batch),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          batch.batchCode,
          maxLines: 1,
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppTokens.textMuted, fontSize: 12),
        ),
      ],
    );
  }
}

class _Counts extends StatelessWidget {
  const _Counts({required this.batch});
  final CardBatch batch;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _MiniCount(label: 'كلها', value: batch.generated),
        _MiniCount(label: 'الأصلي', value: batch.originalCount),
        _MiniCount(label: 'متاح', value: batch.availableCount),
        _MiniCount(label: 'نشط', value: batch.activeCount),
        _MiniCount(label: 'منتهي', value: batch.expiredCount),
        _MiniCount(label: 'مؤرشف', value: batch.archivedCount),
        _MiniCount(label: 'بانتظار الأرشفة', value: batch.pendingArchiveCount),
        _MiniCount(label: 'تشغيلي', value: batch.operationalRemainingCount),
        _MiniCount(label: 'ملغى', value: batch.revokedCount),
      ],
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

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTokens.textMuted),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: AppTokens.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          batch.planName.isNotEmpty ? batch.planName : 'بدون عرض',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        Text(
          [
            if (speed.isNotEmpty) speed,
            if (batch.activeSpeedRules > 0)
              '${batch.activeSpeedRules} قاعدة سرعة',
          ].join(' • '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppTokens.textMuted, fontSize: 12),
        ),
      ],
    );
  }
}

class _Activity extends StatelessWidget {
  const _Activity({required this.batch});
  final CardBatch batch;

  @override
  Widget build(BuildContext context) {
    return Text(
      [
        '${batch.sessionsCount} جلسة',
        '${batch.uniqueMacs} MAC',
        if (batch.onlineSessions > 0) '${batch.onlineSessions} متصل',
      ].join(' • '),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(color: AppTokens.textSecondary, fontSize: 12),
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
