// ignore_for_file: require_trailing_commas

import 'package:hoberadius_app/core/l10n/arabic_labels.dart';
import 'package:hoberadius_app/core/format/arabic_plural.dart';
import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:hoberadius_app/core/api/visible_error_message.dart';

import '../../../core/auth/permissions.dart';
import '../../../core/auth/route_permissions.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/hub_layout.dart';
import '../../../shared/widgets/status_pill.dart';
import '../data/cards_repository.dart';
import '../domain/card_model.dart';
import '../application/cards_list_providers.dart';

/// Filters the cards-of-batch list can be paged through.
enum _CardFilter { all, available, used, revoked }

final _cardFilterProvider = StateProvider.autoDispose<_CardFilter>(
  (_) => _CardFilter.all,
);

final _batchDetailProvider = FutureProvider.autoDispose.family<CardBatch, int>((
  ref,
  id,
) {
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
    final perms = ref.watch(permissionsProvider);
    final editDenied = routeDenial(perms, '/cards/batches/$batchId/edit');
    final printDenied = routeDenial(perms, '/cards/batches/$batchId/print');
    final exportDenied = perms.canAction('data.export')
        ? null
        : perms.deniedReason(action: 'data.export', perm: 'users.export');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'رجوع',
              visualDensity: VisualDensity.compact,
              onPressed: () => context.goNamed('cards'),
              icon: const Icon(Icons.arrow_back),
            ),
            const SizedBox(width: AppTokens.s4),
            Expanded(
              child: Text(
                batchAsync.maybeWhen(
                  data: (b) => b.batchCode,
                  orElse: () => 'دفعة #$batchId',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTokens.sidebarBg,
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
          ],
        ),
        const SizedBox(height: AppTokens.s8),
        ActionBar(
          items: [
            ActionItem(
              icon: Icons.print_outlined,
              label: 'طباعة',
              primary: true,
              onPressed: printDenied != null
                  ? null
                  : () => context.goNamed(
                        'card-batch-print',
                        pathParameters: {'id': '$batchId'},
                      ),
              tooltip: printDenied,
            ),
            ActionItem(
              icon: Icons.edit_outlined,
              label: 'تعديل',
              onPressed: editDenied != null
                  ? null
                  : () => context.goNamed(
                        'card-batch-edit',
                        pathParameters: {'id': '$batchId'},
                      ),
              tooltip: editDenied,
            ),
            ActionItem(
              icon: Icons.file_download_outlined,
              label: 'تصدير ملف',
              tooltip: exportDenied,
              onPressed: exportDenied != null
                  ? null
                  : cardsAsync.maybeWhen(
                      data: (cards) => cards.isEmpty
                          ? null
                          : () => _exportCsv(
                                context,
                                ref,
                                batchAsync.valueOrNull,
                                ref.read(_cardFilterProvider),
                              ),
                      orElse: () => null,
                    ),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s12),
        batchAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (e, _) => EmptyState(
            icon: Icons.error_outline,
            title: 'تعذّر جلب الدفعة',
            subtitle: visibleErrorMessage(e),
          ),
          data: (b) => _BatchSummary(batch: b),
        ),
        const SizedBox(height: AppTokens.s12),
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

  /// Exports EVERY card of the batch for the current filter (paged through
  /// the API), not only the first page shown on screen.
  Future<void> _exportCsv(
    BuildContext context,
    WidgetRef ref,
    CardBatch? batch,
    _CardFilter filter,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('جارٍ تجهيز ملف كل بطاقات الدفعة…')),
    );
    final repo = ref.read(cardsRepositoryProvider);
    final List<CardItem> cards;
    try {
      cards = await switch (filter) {
        _CardFilter.all => repo.allCardsOfBatch(batchId),
        _CardFilter.available =>
          repo.allCardsOfBatch(batchId, used: false, revoked: false),
        _CardFilter.used => repo.allCardsOfBatch(batchId, used: true),
        _CardFilter.revoked => repo.allCardsOfBatch(batchId, revoked: true),
      };
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(visibleErrorWithRetryHint(e))),
      );
      return;
    }
    final rows = <List<dynamic>>[
      ['username', 'password', 'used', 'revoked', 'expire_at', 'first_used_at'],
      for (final c in cards)
        [
          c.username,
          // masked by the server → left empty, never exported as «••••••»
          c.passwordMasked ? '' : c.password,
          c.used ? '1' : '0',
          c.revoked ? '1' : '0',
          c.expireAt?.toIso8601String() ?? '',
          c.firstUsedAt?.toIso8601String() ?? '',
        ],
    ];
    final csv = const ListToCsvConverter().convert(rows);
    // BOM so Excel reads Arabic + UTF-8 cleanly.
    final bytes = Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(csv)]);
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

  static String _unitLabel(String unit) => switch (unit) {
        'minutes' => 'دقيقة',
        'hours' => 'ساعة',
        'days' => 'يوم',
        _ => unit,
      };

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('yyyy-MM-dd HH:mm');
    final usedPct =
        batch.count == 0 ? 0.0 : (batch.used / batch.count).clamp(0.0, 1.0);
    final heading = batch.packageName.isNotEmpty
        ? batch.packageName
        : (batch.planName.isNotEmpty ? batch.planName : batch.batchCode);
    final meta = <InfoItem>[
      if (batch.createdAt != null)
        InfoItem(
          icon: Icons.event,
          label: 'أُنشئت',
          value: df.format(batch.createdAt!),
        ),
      if (batch.expireAt != null)
        InfoItem(
          icon: Icons.timer_outlined,
          label: 'تنتهي',
          value: df.format(batch.expireAt!),
        ),
      if (batch.timeValue > 0)
        InfoItem(
          icon: Icons.access_time,
          label: 'المدة',
          value: '${batch.timeValue} ${_unitLabel(batch.timeUnit)}',
        ),
      if (batch.deviceCount > 0)
        InfoItem(
          icon: Icons.devices,
          label: 'الأجهزة',
          value: arCount(batch.deviceCount, arDevice, showOne: true),
        ),
      if (batch.createdBy.isNotEmpty)
        InfoItem(
          icon: Icons.person_outline,
          label: 'بواسطة',
          value: actorLabel(batch.createdBy),
        ),
    ];
    return AppCard(
      padding: const EdgeInsets.all(AppTokens.s12),
      child: LayoutBuilder(
        builder: (context, c) {
          final wide = c.maxWidth >= 620;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.workspace_premium_outlined,
                    size: 18,
                    color: AppTokens.brandInk,
                  ),
                  const SizedBox(width: AppTokens.s8),
                  Expanded(
                    child: Text(
                      heading,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppTokens.sidebarBg,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTokens.s8),
                  StatusPill(
                    text: batchStatusLabel(batch.status),
                    tone: batchStatusTone(batch.status),
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.s12),
              // The single-batch endpoint may omit expired/revoked counts, so
              // those cells only appear when they carry a real number.
              CountGrid(
                items: [
                  CountItem('الإجمالي', batch.count),
                  CountItem('متاح', batch.available, tone: PillTone.blue),
                  CountItem('مستخدم', batch.used, tone: PillTone.brand),
                  CountItem(
                    'منتهي',
                    batch.expiredCount,
                    tone: PillTone.amber,
                    hideWhenZero: true,
                  ),
                  CountItem(
                    'ملغى',
                    batch.revokedCount,
                    tone: PillTone.red,
                    hideWhenZero: true,
                  ),
                  if (batch.generated != batch.count)
                    CountItem('مُولَّد', batch.generated),
                ],
              ),
              const SizedBox(height: AppTokens.s12),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: usedPct,
                        minHeight: 6,
                        backgroundColor: AppTokens.surfaceTinted,
                        valueColor: AlwaysStoppedAnimation(
                          usedPct >= 0.9 ? AppTokens.red : AppTokens.brand,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTokens.s8),
                  Text(
                    'مستخدم \u200E${(usedPct * 100).round()}%',
                    style: const TextStyle(
                      color: AppTokens.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              if (meta.isNotEmpty) ...[
                const SizedBox(height: AppTokens.s12),
                InfoGrid(items: meta, columns: wide ? 3 : 2),
              ],
              if (batch.notes.isNotEmpty) ...[
                const SizedBox(height: AppTokens.s8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.sticky_note_2_outlined,
                      size: 14,
                      color: AppTokens.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        batch.notes,
                        style: const TextStyle(
                          color: AppTokens.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
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

  Future<void> _revoke(BuildContext ctx, WidgetRef ref, CardItem c) async {
    final confirm = await showDialog<bool>(
      context: ctx,
      useRootNavigator: true,
      builder: (d) => AlertDialog(
        title: const Text('إلغاء الكرت'),
        content: Text('سيُلغى الكرت "${c.username}" نهائيًا. متأكّد؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTokens.red),
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
      ScaffoldMessenger.of(
        ctx,
      ).showSnackBar(const SnackBar(content: Text('تم إلغاء الكرت')));
      // Refresh both lists
      final batchId = c.batchId;
      if (batchId != null) {
        ref.invalidate(_cardsOfBatchProvider(batchId));
        ref.invalidate(_batchDetailProvider(batchId));
      }
      ref.invalidate(batchesListProvider);
    } catch (e) {
      if (!ctx.mounted) return;
      ScaffoldMessenger.of(
        ctx,
      ).showSnackBar(SnackBar(content: Text(visibleErrorMessage(e))));
    }
  }

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
                ? PillTone.brand
                : PillTone.blue;
        final label = c.revoked
            ? 'مُلغى'
            : c.used
                ? 'مُستخدَم'
                : 'متاح';
        final canRevoke = !c.revoked &&
            c.id != null &&
            ref.watch(permissionsProvider).canAction('cards.revoke');
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.s12,
            vertical: AppTokens.s8,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppTokens.sidebarBg,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Text(
                      c.passwordMasked
                          ? 'كلمة المرور: •••• (مخفيّة — لا تملك صلاحية كشفها)'
                          : 'كلمة المرور: ${c.password}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTokens.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    if (c.lockedMac.isNotEmpty || c.usedByMac.isNotEmpty)
                      Text(
                        c.lockedMac.isNotEmpty
                            ? 'مقفلة على MAC: ${c.lockedMac}'
                            : 'استُخدمت من MAC: ${c.usedByMac}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTokens.textMuted,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppTokens.s8),
              StatusPill(text: label, tone: tone),
              const SizedBox(width: AppTokens.s8),
              // Fixed slot so the pills line up whether or not a row can
              // still be revoked.
              SizedBox(
                width: 34,
                height: 34,
                child: canRevoke
                    ? _RevokeButton(onPressed: () => _revoke(ctx, ref, c))
                    : null,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Small red-tinted square button — a clear, bordered target instead of a
/// bare red icon floating at the row's edge.
class _RevokeButton extends StatelessWidget {
  const _RevokeButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = pillToneColors(PillTone.red);
    return Tooltip(
      message: 'إلغاء الكرت',
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.r10),
          side: BorderSide(color: border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTokens.r10),
          onTap: onPressed,
          child: Icon(Icons.block, size: 18, color: fg),
        ),
      ),
    );
  }
}
