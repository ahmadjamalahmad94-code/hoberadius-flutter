import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../data/accounting_repository.dart';
import '../domain/accounting_model.dart';

final _ledgerProvider =
    FutureProvider.autoDispose.family<List<LedgerEntry>, String>((ref, type) {
  return ref.watch(accountingRepositoryProvider).listLedger(entryType: type);
});

class LedgerScreen extends ConsumerStatefulWidget {
  const LedgerScreen({super.key});

  @override
  ConsumerState<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends ConsumerState<LedgerScreen> {
  String _entryType = '';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_ledgerProvider(_entryType));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'السجل المالي',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTokens.navy900,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            IconButton(
              tooltip: 'تحديث',
              onPressed: () => ref.invalidate(_ledgerProvider(_entryType)),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s12),
        const AppCard(
          child: Row(
            children: [
              Icon(Icons.verified_outlined, color: AppTokens.cyan500),
              SizedBox(width: AppTokens.s8),
              Expanded(
                child: Text(
                  'القيود المالية لا تحذف. التصحيح يتم بقيد عكسي يحافظ على الأصل.',
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
                'نوع القيد:',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              DropdownButton<String>(
                value: _entryType,
                items: const [
                  DropdownMenuItem(value: '', child: Text('الكل')),
                  DropdownMenuItem(value: 'payment', child: Text('دفعات')),
                  DropdownMenuItem(value: 'loan', child: Text('سلف')),
                  DropdownMenuItem(value: 'settlement', child: Text('تسويات')),
                  DropdownMenuItem(value: 'void', child: Text('قيود عكسية')),
                ],
                onChanged: (v) => setState(() => _entryType = v ?? ''),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.s12),
        async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => EmptyState(
            icon: Icons.error_outline,
            title: 'تعذر جلب السجل المالي',
            subtitle: '$e',
          ),
          data: (items) {
            if (items.isEmpty) {
              return const EmptyState(
                icon: Icons.scale_outlined,
                title: 'لا توجد قيود بهذه الفلترة',
              );
            }
            return AppCard(
              padding: EdgeInsets.zero,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('#')),
                    DataColumn(label: Text('النوع')),
                    DataColumn(label: Text('المستفيد')),
                    DataColumn(label: Text('المبلغ')),
                    DataColumn(label: Text('الحالة')),
                    DataColumn(label: Text('التاريخ')),
                    DataColumn(label: Text('تصحيح')),
                  ],
                  rows: items.map((entry) {
                    return DataRow(
                      cells: [
                        DataCell(Text('${entry.id}')),
                        DataCell(Text(entry.entryType)),
                        DataCell(
                          Text(
                            entry.username.isEmpty ? '—' : entry.username,
                          ),
                        ),
                        DataCell(Text('${entry.amount} ${entry.currency}')),
                        DataCell(Text(entry.status)),
                        DataCell(Text(_fmt(entry.createdAt))),
                        DataCell(
                          entry.entryType == 'void'
                              ? const Text('قيد عكسي')
                              : TextButton(
                                  onPressed: () => _voidEntry(entry),
                                  child: const Text('عكس'),
                                ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _voidEntry(LedgerEntry entry) async {
    final ctrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('عكس القيد #${entry.id}'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'سبب التصحيح'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('إنشاء قيد عكسي'),
          ),
        ],
      ),
    );
    if (reason == null || reason.isEmpty) return;
    try {
      await ref.read(accountingRepositoryProvider).voidLedger(
            entryId: entry.id,
            reason: reason,
          );
      ref.invalidate(_ledgerProvider(_entryType));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إنشاء قيد عكسي')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }
}

String _fmt(DateTime? value) {
  if (value == null) return '—';
  return DateFormat('yyyy-MM-dd').format(value);
}
