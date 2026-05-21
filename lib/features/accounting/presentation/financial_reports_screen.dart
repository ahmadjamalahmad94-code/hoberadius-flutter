import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../data/accounting_repository.dart';

const _reports = <String, String>{
  'sales/daily': 'مبيعات يومية',
  'sales/monthly': 'مبيعات شهرية',
  'sales/yearly': 'مبيعات سنوية',
  'payments': 'دفعات المستفيدين',
  'loans': 'السلف',
  'activations': 'التفعيلات',
  'card-sales': 'مبيعات الكروت',
  'profit-loss': 'ربح / خسارة',
  'distributor-debts': 'ديون الموزعين',
};

final _reportProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, slug) {
  return ref.watch(accountingRepositoryProvider).financialReport(slug);
});

final _snapshotProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, slug) {
  return ref.watch(accountingRepositoryProvider).reportSnapshots(reportType: slug);
});

class FinancialReportsScreen extends ConsumerStatefulWidget {
  const FinancialReportsScreen({super.key});

  @override
  ConsumerState<FinancialReportsScreen> createState() =>
      _FinancialReportsScreenState();
}

class _FinancialReportsScreenState
    extends ConsumerState<FinancialReportsScreen> {
  String _slug = 'sales/daily';
  bool _savingSnapshot = false;

  Future<void> _saveSnapshot() async {
    setState(() => _savingSnapshot = true);
    try {
      final snapshot = await ref
          .read(accountingRepositoryProvider)
          .createReportSnapshot(_slug);
      if (!mounted) return;
      ref.invalidate(_snapshotProvider(_slug));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم حفظ لقطة ثابتة للتقرير #${snapshot['id'] ?? ''}'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر حفظ اللقطة: $e')),
      );
    } finally {
      if (mounted) setState(() => _savingSnapshot = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_reportProvider(_slug));
    final snapshots = ref.watch(_snapshotProvider(_slug));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'التقارير المالية',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTokens.navy900,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            IconButton(
              tooltip: 'تحديث',
              onPressed: () {
                ref.invalidate(_reportProvider(_slug));
                ref.invalidate(_snapshotProvider(_slug));
              },
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s12),
        const AppCard(
          child: Row(
            children: [
              Icon(Icons.lock_clock_outlined, color: AppTokens.cyan500),
              SizedBox(width: AppTokens.s8),
              Expanded(
                child: Text(
                  'هذه التقارير مبنية من Ledger. التصحيح يظهر كقيد عكسي ولا يحذف الأصل.',
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
                'التقرير:',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              DropdownButton<String>(
                value: _slug,
                items: _reports.entries
                    .map(
                      (entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _slug = v ?? 'sales/daily'),
              ),
              FilledButton.icon(
                onPressed: _savingSnapshot ? null : _saveSnapshot,
                icon: _savingSnapshot
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.lock_clock_outlined),
                label: const Text('حفظ لقطة ثابتة'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.s12),
        snapshots.when(
          loading: () => const SizedBox.shrink(),
          error: (e, _) => _SnapshotStrip(error: '$e'),
          data: (items) => _SnapshotStrip(items: items),
        ),
        const SizedBox(height: AppTokens.s12),
        async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => EmptyState(
            icon: Icons.error_outline,
            title: 'تعذر جلب التقرير',
            subtitle: '$e',
          ),
          data: (rows) {
            if (rows.isEmpty) {
              return EmptyState(
                icon: Icons.insert_chart_outlined,
                title: 'لا توجد بيانات بعد',
                subtitle: _reports[_slug],
              );
            }
            final columns = rows.expand((row) => row.keys).toSet().toList()
              ..sort();
            return AppCard(
              padding: EdgeInsets.zero,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: columns
                      .map((column) => DataColumn(label: Text(_label(column))))
                      .toList(),
                  rows: rows
                      .map(
                        (row) => DataRow(
                          cells: columns
                              .map(
                                (column) => DataCell(
                                  Text(_cell(row[column])),
                                ),
                              )
                              .toList(),
                        ),
                      )
                      .toList(),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SnapshotStrip extends StatelessWidget {
  const _SnapshotStrip({this.items = const [], this.error});

  final List<Map<String, dynamic>> items;
  final String? error;

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return AppCard(
        child: Text(
          'تعذر تحميل اللقطات: $error',
          style: const TextStyle(color: Colors.redAccent),
        ),
      );
    }
    if (items.isEmpty) {
      return const AppCard(
        child: Row(
          children: [
            Icon(Icons.lock_clock_outlined, color: AppTokens.cyan500),
            SizedBox(width: AppTokens.s8),
            Expanded(
              child: Text(
                'لا توجد لقطات ثابتة لهذا التقرير بعد.',
                style: TextStyle(color: AppTokens.textMuted),
              ),
            ),
          ],
        ),
      );
    }
    return AppCard(
      padding: const EdgeInsets.all(AppTokens.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'آخر اللقطات الثابتة',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTokens.navy900,
                ),
          ),
          const SizedBox(height: AppTokens.s8),
          for (final item in items.take(5))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.archive_outlined, size: 18, color: AppTokens.cyan500),
                  const SizedBox(width: AppTokens.s8),
                  Expanded(
                    child: Text(
                      '#${item['id']} · ${item['created_at'] ?? ''}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text('${_snapshotCount(item)} صف'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static int _snapshotCount(Map<String, dynamic> item) {
    final result = item['result'];
    if (result is Map && result['count'] is num) {
      return (result['count'] as num).toInt();
    }
    return 0;
  }
}

String _cell(Object? value) {
  if (value == null || value.toString().isEmpty) return '—';
  return value.toString();
}

String _label(String key) {
  const labels = {
    'period': 'الفترة',
    'count': 'العدد',
    'total': 'الإجمالي',
    'username': 'اسم الدخول',
    'subscriber_id': 'رقم المستفيد',
    'earned_minutes': 'الدقائق المستحقة',
    'credits': 'دائن',
    'debits': 'مدين',
    'net': 'الصافي',
    'debt_balance': 'الدين',
    'balance': 'الرصيد',
    'credit_limit': 'حد الائتمان',
  };
  return labels[key] ?? key;
}
