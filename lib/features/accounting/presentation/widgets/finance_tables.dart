import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../domain/accounting_model.dart';

class PaymentsTable extends StatelessWidget {
  const PaymentsTable({super.key, required this.items, required this.onVoid});

  final List<PaymentTransaction> items;
  final Future<void> Function(PaymentTransaction payment)? onVoid;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const EmptyState(
        icon: Icons.receipt_long,
        title: 'لا توجد دفعات بعد',
      );
    }
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.all(AppTokens.s16),
            child: Text(
              'آخر الدفعات',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('#')),
                DataColumn(label: Text('المبلغ')),
                DataColumn(label: Text('المدة')),
                DataColumn(label: Text('الحالة')),
                DataColumn(label: Text('التاريخ')),
                DataColumn(label: Text('إجراء')),
              ],
              rows: items
                  .map(
                    (p) => DataRow(
                      cells: [
                        DataCell(Text('${p.id}')),
                        DataCell(Text('${p.amount} ${p.currency}')),
                        DataCell(Text('${p.earnedMinutes} دقيقة')),
                        DataCell(Text(_accountingStatusLabel(p.status))),
                        DataCell(Text(formatFinanceDate(p.createdAt))),
                        DataCell(
                          p.status == 'voided'
                              ? const Text('معكوسة')
                              : TextButton.icon(
                                  onPressed: onVoid == null
                                      ? null
                                      : () => onVoid!(p),
                                  icon: const Icon(Icons.undo, size: 18),
                                  label: const Text('عكس'),
                                ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class LoansTable extends StatelessWidget {
  const LoansTable({super.key, required this.items, required this.onSettle});

  final List<LoanEntry> items;
  final Future<void> Function(LoanEntry loan)? onSettle;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const EmptyState(
        icon: Icons.handshake_outlined,
        title: 'لا توجد سلف بعد',
      );
    }
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.all(AppTokens.s16),
            child: Text(
              'السلف والتسويات',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
          const Divider(height: 1),
          ...items.map(
            (loan) => ListTile(
              title: Text(
                '${loan.durationMinutes} دقيقة • ${loan.amount} ${loan.currency}',
              ),
              subtitle: Text(
                loan.reason.isEmpty ? 'بدون سبب مسجل' : loan.reason,
              ),
              trailing: loan.status == 'open'
                  ? TextButton(
                      onPressed:
                          onSettle == null ? null : () => onSettle!(loan),
                      child: const Text('تسوية'),
                    )
                  : const Text('تمت التسوية'),
            ),
          ),
        ],
      ),
    );
  }
}

class LedgerTable extends StatelessWidget {
  const LedgerTable({super.key, required this.items});

  final List<LedgerEntry> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const EmptyState(
        icon: Icons.scale_outlined,
        title: 'لا توجد قيود مالية',
      );
    }
    return _SectionTable(
      title: 'سجل القيود',
      columns: const ['#', 'النوع', 'المبلغ', 'المصدر', 'التاريخ'],
      rows: items
          .map(
            (e) => [
              '${e.id}',
              _ledgerTypeLabel(e.entryType),
              '${e.amount} ${e.currency}',
              _ledgerSourceLabel(e.sourceType),
              formatFinanceDate(e.createdAt),
            ],
          )
          .toList(),
    );
  }
}

class _SectionTable extends StatelessWidget {
  const _SectionTable({
    required this.title,
    required this.columns,
    required this.rows,
  });

  final String title;
  final List<String> columns;
  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTokens.s16),
            child: Text(
              title,
              style:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: columns.map((c) => DataColumn(label: Text(c))).toList(),
              rows: rows
                  .map(
                    (r) => DataRow(
                      cells: r.map((cell) => DataCell(Text(cell))).toList(),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

String formatFinanceDate(DateTime? value) {
  if (value == null) return '—';
  return DateFormat('yyyy-MM-dd').format(value);
}

String _accountingStatusLabel(String value) {
  return switch (value.trim().toLowerCase()) {
    'posted' => 'مرحّلة',
    'voided' => 'معكوسة',
    'open' => 'مفتوحة',
    'settled' => 'مسددة',
    'pending' => 'قيد المراجعة',
    'failed' => 'فشلت',
    '' => 'غير محددة',
    _ => 'حالة غير معروفة',
  };
}

String _ledgerTypeLabel(String value) {
  return switch (value.trim().toLowerCase()) {
    'payment' => 'دفعة',
    'loan' => 'سلفة',
    'settlement' => 'تسوية',
    'void' => 'قيد عكسي',
    'adjustment' => 'تعديل مالي',
    '' => 'غير محدد',
    _ => 'نوع غير معروف',
  };
}

String _ledgerSourceLabel(String value) {
  return switch (value.trim().toLowerCase()) {
    'payment' => 'دفعة',
    'loan' => 'سلفة',
    'settlement' => 'تسوية',
    'void' => 'قيد عكسي',
    '' => '—',
    _ => 'مصدر آخر',
  };
}
