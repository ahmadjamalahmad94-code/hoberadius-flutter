import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:hoberadius_app/core/api/visible_error_message.dart';

import '../../../core/auth/permissions.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/status_pill.dart';
import '../data/recycle_bin_repository.dart';
import '../domain/recycle_bin_model.dart';

const _entityLabels = <String, String>{
  '': 'الكل',
  'subscribers': 'المستفيدون',
  'plans': 'الباقات',
  'nas': 'أجهزة الشبكة',
  'admins': 'المدراء',
  'roles': 'الأدوار',
  'card_batches': 'حزم البطاقات',
};

final _recycleProvider = FutureProvider.autoDispose
    .family<List<RecycleBinItem>, String>((ref, entityType) {
  return ref.watch(recycleBinRepositoryProvider).list(entityType: entityType);
});

class RecycleBinScreen extends ConsumerStatefulWidget {
  const RecycleBinScreen({super.key});

  @override
  ConsumerState<RecycleBinScreen> createState() => _RecycleBinScreenState();
}

class _RecycleBinScreenState extends ConsumerState<RecycleBinScreen> {
  String _entityType = '';
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_recycleProvider(_entityType));
    final ownerLike = ref.watch(permissionsProvider).isOwnerLike;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'سلة المحذوفات',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTokens.sidebarBg,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            IconButton(
              tooltip: 'تحديث',
              onPressed: () => ref.invalidate(_recycleProvider(_entityType)),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s12),
        const AppCard(
          child: Row(
            children: [
              Icon(Icons.info_outline, color: AppTokens.brand),
              SizedBox(width: AppTokens.s8),
              Expanded(
                child: Text(
                  'العناصر هنا مؤرشفة وليست محذوفة نهائيًا. السجلات المالية تبقى محفوظة ولا تُحذف من هذه الشاشة.',
                  style: TextStyle(color: AppTokens.textMuted),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.s12),
        AppCard(
          padding: const EdgeInsets.all(AppTokens.s12),
          child: Wrap(
            spacing: AppTokens.s8,
            runSpacing: AppTokens.s8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'النوع:',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              DropdownButton<String>(
                value: _entityType,
                items: _entityLabels.entries
                    .map(
                      (entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _entityType = v ?? ''),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.s12),
        async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => EmptyState(
            icon: Icons.error_outline,
            title: 'تعذر جلب سلة المحذوفات',
            subtitle: visibleErrorMessage(e),
          ),
          data: (items) {
            if (items.isEmpty) {
              return const EmptyState(
                icon: Icons.inventory_2_outlined,
                title: 'لا توجد عناصر مؤرشفة',
                subtitle: 'عند أرشفة مستفيد أو باقة أو جهاز شبكة سيظهر هنا.',
              );
            }
            return LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth > 760;
                if (!wide) {
                  return Column(
                    children: [
                      for (final item in items) ...[
                        _RecycleCard(
                          item: item,
                          busy: _busy,
                          onRestore: () => _restore(item),
                          onPurge:
                              canPurgeRecycleItem(item, ownerLike: ownerLike)
                                  ? () => _purge(item)
                                  : null,
                        ),
                        const SizedBox(height: AppTokens.s12),
                      ],
                    ],
                  );
                }
                return AppCard(
                  padding: EdgeInsets.zero,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('النوع')),
                        DataColumn(label: Text('العنصر')),
                        DataColumn(label: Text('الحالة')),
                        DataColumn(label: Text('وقت الأرشفة')),
                        DataColumn(label: Text('بواسطة')),
                        DataColumn(label: Text('السبب')),
                        DataColumn(label: Text('مصدر الأرشفة')),
                        DataColumn(label: Text('الاحتفاظ')),
                        DataColumn(label: Text('')),
                      ],
                      rows: items
                          .map(
                            (item) => DataRow(
                              cells: [
                                DataCell(Text(_label(item.entityType))),
                                DataCell(Text(item.label)),
                                DataCell(
                                  StatusPill(
                                    text: item.statusLabel,
                                    tone: PillTone.orange,
                                  ),
                                ),
                                DataCell(Text(_fmt(item.deletedAt))),
                                DataCell(
                                  Text(item.deletedByText),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 240,
                                    child: Text(
                                      item.deleteReason.isEmpty
                                          ? 'لم يتم تسجيل سبب'
                                          : item.deleteReason,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                DataCell(Text(_archiveSource(item))),
                                DataCell(
                                  SizedBox(
                                    width: 180,
                                    child: Text(_retentionLabel(item)),
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextButton.icon(
                                        onPressed: _busy || !item.restoreAllowed
                                            ? null
                                            : () => _restore(item),
                                        icon: const Icon(Icons.restore),
                                        label: const Text('استعادة'),
                                      ),
                                      if (canPurgeRecycleItem(
                                        item,
                                        ownerLike: ownerLike,
                                      ))
                                        TextButton.icon(
                                          onPressed:
                                              _busy ? null : () => _purge(item),
                                          style: TextButton.styleFrom(
                                            foregroundColor: AppTokens.dangerFg,
                                          ),
                                          icon: const Icon(
                                            Icons.delete_forever_outlined,
                                          ),
                                          label: const Text('حذف نهائي'),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Future<void> _restore(RecycleBinItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('استعادة عنصر'),
        content:
            Text('هل تريد استعادة "${item.label}"؟ راجعه قبل تشغيله مرة أخرى.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('استعادة'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await ref.read(recycleBinRepositoryProvider).restore(item);
      ref.invalidate(_recycleProvider(_entityType));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تمت الاستعادة')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(visibleErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// The web «حذف نهائيّ»: erases the batch and every card in it — no undo.
  /// Typed confirmation (like the web backups delete / restore).
  Future<void> _purge(RecycleBinItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => _PurgeConfirmDialog(label: item.label),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      final cards = await ref.read(recycleBinRepositoryProvider).purge(item);
      ref.invalidate(_recycleProvider(_entityType));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم الحذف النهائي بلا رجعة — بطاقات: $cards'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(visibleErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _PurgeConfirmDialog extends StatefulWidget {
  const _PurgeConfirmDialog({required this.label});

  final String label;

  @override
  State<_PurgeConfirmDialog> createState() => _PurgeConfirmDialogState();
}

class _PurgeConfirmDialogState extends State<_PurgeConfirmDialog> {
  final _typed = TextEditingController();

  @override
  void dispose() {
    _typed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matches = recyclePurgeConfirmMatches(_typed.text);
    return AlertDialog(
      title: const Text('حذف نهائي'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'تُمحى الحزمة "${widget.label}" وكل بطاقاتها من القاعدة تمامًا، '
            'ولا يمكن التراجع.',
          ),
          const SizedBox(height: AppTokens.s12),
          const Text(
            'للتأكيد اكتب: $recyclePurgeConfirmPhrase',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppTokens.s8),
          TextField(
            key: const Key('recycle-purge-confirm'),
            controller: _typed,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: recyclePurgeConfirmPhrase,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          key: const Key('recycle-purge-submit'),
          style: FilledButton.styleFrom(backgroundColor: AppTokens.dangerFg),
          onPressed: matches ? () => Navigator.pop(context, true) : null,
          child: const Text('حذف نهائي'),
        ),
      ],
    );
  }
}

class _RecycleCard extends StatelessWidget {
  const _RecycleCard({
    required this.item,
    required this.busy,
    required this.onRestore,
    required this.onPurge,
  });

  final RecycleBinItem item;
  final bool busy;
  final VoidCallback onRestore;

  /// Null = no permanent delete for this item (not a card batch / not owner).
  final VoidCallback? onPurge;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.inventory_2_outlined, color: AppTokens.brand),
              const SizedBox(width: AppTokens.s8),
              Expanded(
                child: Text(
                  item.label,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              StatusPill(text: _label(item.entityType), tone: PillTone.cyan),
            ],
          ),
          const SizedBox(height: AppTokens.s8),
          Text(
            'وقت الأرشفة: ${_fmt(item.deletedAt)}',
            style: const TextStyle(color: AppTokens.textMuted),
          ),
          const SizedBox(height: AppTokens.s8),
          Text(
            item.deleteReason.isEmpty ? 'لم يتم تسجيل سبب' : item.deleteReason,
            style: const TextStyle(color: AppTokens.textSecondary),
          ),
          const SizedBox(height: AppTokens.s8),
          Wrap(
            spacing: AppTokens.s8,
            runSpacing: AppTokens.s8,
            children: [
              StatusPill(text: _archiveSource(item), tone: PillTone.blue),
              StatusPill(
                text: _retentionLabel(item),
                tone: item.restoreAllowed ? PillTone.green : PillTone.neutral,
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s12),
          Wrap(
            spacing: AppTokens.s8,
            children: [
              OutlinedButton.icon(
                onPressed: busy || !item.restoreAllowed ? null : onRestore,
                icon: const Icon(Icons.restore),
                label: const Text('استعادة'),
              ),
              if (onPurge != null)
                OutlinedButton.icon(
                  onPressed: busy ? null : onPurge,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTokens.dangerFg,
                  ),
                  icon: const Icon(Icons.delete_forever_outlined),
                  label: const Text('حذف نهائي'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The list returns TABLE names (`access_plans`, `nas_devices`, …): label
/// them too — the raw table name was shown (parity-b).
const _tableLabels = <String, String>{
  'access_plans': 'الباقات',
  'nas_devices': 'أجهزة الشبكة',
};

String _label(String entityType) =>
    _entityLabels[entityType] ?? _tableLabels[entityType] ?? entityType;

String _archiveSource(RecycleBinItem item) {
  if (item.archiveSource == 'auto') {
    final policy =
        item.archivePolicyId == null ? '' : ' #${item.archivePolicyId}';
    return 'أرشفة تلقائية$policy';
  }
  if (item.archiveSource == 'manual') return 'أرشفة يدوية';
  return 'غير محدد';
}

String _retentionLabel(RecycleBinItem item) {
  if (item.retentionExpired) return 'انتهت مدة الاستعادة';
  if (item.retentionExpiresAt == null) return 'استعادة مفتوحة';
  return 'حتى ${_fmt(item.retentionExpiresAt)}';
}

String _fmt(DateTime? value) {
  if (value == null) return '—';
  return DateFormat('yyyy-MM-dd HH:mm').format(value);
}
