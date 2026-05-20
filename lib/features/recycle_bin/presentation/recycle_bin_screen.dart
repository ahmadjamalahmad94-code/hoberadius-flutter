import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'سلة المحذوفات',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTokens.navy900,
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
              Icon(Icons.info_outline, color: AppTokens.cyan500),
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
            subtitle: '$e',
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
                                    text: item.status.isEmpty
                                        ? 'غير محدد'
                                        : item.status,
                                    tone: PillTone.orange,
                                  ),
                                ),
                                DataCell(Text(_fmt(item.deletedAt))),
                                DataCell(
                                  Text(
                                    item.deletedBy.isEmpty
                                        ? 'غير معروف'
                                        : item.deletedBy,
                                  ),
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
                                DataCell(
                                  TextButton.icon(
                                    onPressed:
                                        _busy ? null : () => _restore(item),
                                    icon: const Icon(Icons.restore),
                                    label: const Text('استعادة'),
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _RecycleCard extends StatelessWidget {
  const _RecycleCard({
    required this.item,
    required this.busy,
    required this.onRestore,
  });

  final RecycleBinItem item;
  final bool busy;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.inventory_2_outlined, color: AppTokens.cyan500),
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
          const SizedBox(height: AppTokens.s12),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: busy ? null : onRestore,
              icon: const Icon(Icons.restore),
              label: const Text('استعادة'),
            ),
          ),
        ],
      ),
    );
  }
}

String _label(String entityType) => _entityLabels[entityType] ?? entityType;

String _fmt(DateTime? value) {
  if (value == null) return '—';
  return DateFormat('yyyy-MM-dd HH:mm').format(value);
}
