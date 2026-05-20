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

class FinancialReportsScreen extends ConsumerStatefulWidget {
  const FinancialReportsScreen({super.key});

  @override
  ConsumerState<FinancialReportsScreen> createState() =>
      _FinancialReportsScreenState();
}

class _FinancialReportsScreenState
    extends ConsumerState<FinancialReportsScreen> {
  String _slug = 'sales/daily';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_reportProvider(_slug));
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
              onPressed: () => ref.invalidate(_reportProvider(_slug)),
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
            ],
          ),
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
