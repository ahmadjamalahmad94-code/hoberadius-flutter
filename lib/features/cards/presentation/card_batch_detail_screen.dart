// ignore_for_file: require_trailing_commas

import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:hoberadius_app/core/api/visible_error_message.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/status_pill.dart';
import '../data/cards_repository.dart';
import '../domain/card_model.dart';
import '../application/cards_list_providers.dart';

/// Filters the cards-of-batch list can be paged through.
enum _CardFilter { all, available, used, revoked }

final _cardFilterProvider = StateProvider.autoDispose<_CardFilter>(
  (_) => _CardFilter.all,
);

final _batchDetailProvider =
    FutureProvider.autoDispose.family<CardBatch, int>((ref, id) {
  return ref.watch(cardsRepositoryProvider).getBatch(id);
});

final _cardsOfBatchProvider =
    FutureProvider.autoDispose.family<List<CardItem>, int>((ref, id) {
  final filter = ref.watch(_cardFilterProvider);
  final repo = ref.watch(cardsRepositoryProvider);
  switch (filter) {
    case _CardFilter.all:
      return repo.cardsOfBatch(id);
    case _CardFilter.available:
      return repo.cardsOfBatch(id, used: false, revoked: false);
    case _CardFilter.used:
      return repo.cardsOfBatch(id, used: true);
    case _CardFilter.revoked:
      return repo.cardsOfBatch(id, revoked: true);
  }
});

class CardBatchDetailScreen extends ConsumerWidget {
  const CardBatchDetailScreen({super.key, required this.batchId});
  final int batchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batchAsync = ref.watch(_batchDetailProvider(batchId));
    final cardsAsync = ref.watch(_cardsOfBatchProvider(batchId));
    final filter = ref.watch(_cardFilterProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => context.goNamed('cards'),
              icon: const Icon(Icons.arrow_back),
            ),
            Expanded(
              child: batchAsync.maybeWhen(
                data: (b) => Text(
                  b.batchCode,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppTokens.sidebarBg,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
                orElse: () => Text(
                  'دفعة #$batchId',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppTokens.sidebarBg,
                      ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'تحديث',
              icon: const Icon(Icons.refresh, color: AppTokens.textSecondary),
              onPressed: () {
                ref.invalidate(_batchDetailProvider(batchId));
                ref.invalidate(_cardsOfBatchProvider(batchId));
                ref.invalidate(batchesListProvider);
              },
            ),
            const SizedBox(width: AppTokens.s4),
            IconButton(
              tooltip: 'تعديل الباقة',
              onPressed: () => context.goNamed(
                'card-batch-edit',
                pathParameters: {'id': '$batchId'},
              ),
              icon: const Icon(Icons.edit_outlined,
                  color: AppTokens.textSecondary),
            ),
            const SizedBox(width: AppTokens.s4),
            IconButton(
              tooltip: 'سرعات متعددة',
              onPressed: () => context.goNamed('bandwidth-schedules'),
              icon: const Icon(Icons.speed_outlined,
                  color: AppTokens.textSecondary),
            ),
            const SizedBox(width: AppTokens.s4),
            cardsAsync.maybeWhen(
              data: (cards) => OutlinedButton.icon(
                onPressed: cards.isEmpty
                    ? null
                    : () => _exportCsv(batchAsync.valueOrNull, cards),
                icon: const Icon(Icons.file_download_outlined),
                label: const Text('تصدير ملف'),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s16),
        batchAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (e, _) => EmptyState(
            icon: Icons.error_outline,
            title: 'تعذّر جلب الدفعة',
            subtitle: visibleErrorMessage(e),
          ),
          data: (b) => _BatchSummary(batch: b),
        ),
        const SizedBox(height: AppTokens.s16),
        _FilterBar(
          current: filter,
          onChanged: (f) => ref.read(_cardFilterProvider.notifier).state = f,
        ),
        const SizedBox(height: AppTokens.s12),
        cardsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppTokens.s40),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => EmptyState(
            icon: Icons.error_outline,
            title: 'تعذّر جلب الكروت',
            subtitle: visibleErrorMessage(e),
          ),
          data: (cards) {
            if (cards.isEmpty) {
              return const EmptyState(
                icon: Icons.credit_card_off_outlined,
                title: 'لا توجد كروت تطابق الفلتر',
              );
            }
            return AppCard(
              padding: EdgeInsets.zero,
              child: _CardsTable(cards: cards),
            );
          },
        ),
        const SizedBox(height: AppTokens.s40),
      ],
    );
  }

  Future<void> _exportCsv(CardBatch? batch, List<CardItem> cards) async {
    final rows = <List<dynamic>>[
      ['username', 'password', 'used', 'revoked', 'expire_at', 'first_used_at'],
      for (final c in cards)
        [
          c.username,
          c.password,
          c.used ? '1' : '0',
          c.revoked ? '1' : '0',
          c.expireAt?.toIso8601String() ?? '',
          c.firstUsedAt?.toIso8601String() ?? '',
        ],
    ];
    final csv = const ListToCsvConverter().convert(rows);
    // BOM so Excel reads Arabic + UTF-8 cleanly.
    final bytes = Uint8List.fromList([0xEF, 0xBB, 0xBF, ...csv.codeUnits]);
    final name = batch?.batchCode.isNotEmpty == true
        ? 'cards_${batch!.batchCode}'
        : 'cards_batch_$batchId';
    await FileSaver.instance.saveFile(
      name: name,
      bytes: bytes,
      ext: 'csv',
      mimeType: MimeType.csv,
    );
  }
}

class _BatchSummary extends StatelessWidget {
  const _BatchSummary({required this.batch});
  final CardBatch batch;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('yyyy-MM-dd HH:mm');
    final usedPct =
        batch.count == 0 ? 0.0 : (batch.used / batch.count).clamp(0.0, 1.0);
    return AppCard(
      padding: const EdgeInsets.all(AppTokens.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Chip(label: 'الإجمالي', value: '${batch.count}'),
                    _Chip(label: 'مُولَّد', value: '${batch.generated}'),
                    _Chip(label: 'مُستخدَم', value: '${batch.used}'),
                    _Chip(label: 'المتاح', value: '${batch.available}'),
                  ],
                ),
              ),
              StatusPill(
                text: switch (batch.status) {
                  'active' => 'نشِط',
                  'exhausted' => 'منتهٍ',
                  'revoked' => 'مُلغى',
                  _ => batch.status,
                },
                tone: batch.status == 'active'
                    ? PillTone.green
                    : batch.status == 'revoked'
                        ? PillTone.red
                        : PillTone.orange,
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: usedPct,
              minHeight: 8,
              backgroundColor: AppTokens.surfaceTinted,
              valueColor: AlwaysStoppedAnimation(
                usedPct >= 0.9 ? AppTokens.red : AppTokens.brand,
              ),
            ),
          ),
          const SizedBox(height: AppTokens.s12),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              if (batch.packageName.isNotEmpty)
                _MetaLine(
                    icon: Icons.workspace_premium_outlined,
                    text: batch.packageName),
              if (batch.createdAt != null)
                _MetaLine(
                    icon: Icons.event,
                    text: 'أُنشئت: ${df.format(batch.createdAt!)}'),
              if (batch.expireAt != null)
                _MetaLine(
                    icon: Icons.timer_outlined,
                    text: 'تنتهي: ${df.format(batch.expireAt!)}'),
              if (batch.createdBy.isNotEmpty)
                _MetaLine(icon: Icons.person_outline, text: batch.createdBy),
              if (batch.timeValue > 0)
                _MetaLine(
                    icon: Icons.access_time,
                    text: '${batch.timeValue} ${batch.timeUnit}'),
              if (batch.deviceCount > 0)
                _MetaLine(
                    icon: Icons.devices, text: '${batch.deviceCount} جهاز'),
            ],
          ),
          if (batch.notes.isNotEmpty) ...[
            const SizedBox(height: AppTokens.s8),
            Text(
              batch.notes,
              style: const TextStyle(color: AppTokens.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTokens.brandSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: AppTokens.sidebarBg, fontSize: 13),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(color: AppTokens.textSecondary),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.icon, required this.text});
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
          style: const TextStyle(color: AppTokens.textSecondary, fontSize: 13),
        ),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.current, required this.onChanged});
  final _CardFilter current;
  final ValueChanged<_CardFilter> onChanged;

  static const _labels = {
    _CardFilter.all: 'الكل',
    _CardFilter.available: 'متاحة',
    _CardFilter.used: 'مُستخدَمة',
    _CardFilter.revoked: 'مُلغاة',
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _CardFilter.values.map((f) {
        final selected = f == current;
        return ChoiceChip(
          label: Text(_labels[f]!),
          selected: selected,
          onSelected: (_) => onChanged(f),
        );
      }).toList(),
    );
  }
}

class _CardsTable extends ConsumerWidget {
  const _CardsTable({required this.cards});
  final List<CardItem> cards;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (ctx, i) {
        final c = cards[i];
        final tone = c.revoked
            ? PillTone.red
            : c.used
                ? PillTone.orange
                : PillTone.green;
        final label = c.revoked
            ? 'مُلغى'
            : c.used
                ? 'مُستخدَم'
                : 'متاح';
        return ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppTokens.s16,
            vertical: AppTokens.s4,
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  c.username,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              StatusPill(text: label, tone: tone),
            ],
          ),
          subtitle: Text(
            'كلمة المرور: ${c.password}',
            style: const TextStyle(color: AppTokens.textMuted, fontSize: 12),
          ),
          trailing: c.revoked || c.id == null
              ? null
              : IconButton(
                  tooltip: 'إلغاء',
                  icon: const Icon(Icons.block, color: AppTokens.red),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: ctx,
                      builder: (d) => AlertDialog(
                        title: const Text('إلغاء الكرت'),
                        content: Text(
                          'سيُلغى الكرت "${c.username}" نهائيًا. متأكّد؟',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(d, false),
                            child: const Text('إلغاء'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTokens.red,
                            ),
                            onPressed: () => Navigator.pop(d, true),
                            child: const Text('تأكيد'),
                          ),
                        ],
                      ),
                    );
                    if (confirm != true) return;
                    try {
                      await ref.read(cardsRepositoryProvider).revoke(c.id!);
                      if (!ctx.mounted) return;
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('تم إلغاء الكرت')),
                      );
                      // Refresh both lists
                      final batchId = c.batchId;
                      if (batchId != null) {
                        ref.invalidate(_cardsOfBatchProvider(batchId));
                        ref.invalidate(_batchDetailProvider(batchId));
                      }
                      ref.invalidate(batchesListProvider);
                    } catch (e) {
                      if (!ctx.mounted) return;
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text('تعذّر الإلغاء: $e')),
                      );
                    }
                  },
                ),
        );
      },
    );
  }
}
