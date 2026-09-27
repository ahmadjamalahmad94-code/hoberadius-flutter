import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/status_pill.dart';
import '../../domain/accounting_model.dart';

class PaymentsTable extends StatelessWidget {
  const PaymentsTable({super.key, required this.items, required this.onVoid});

  final List<PaymentTransaction> items;
  final Future<void> Function(PaymentTransaction payment)? onVoid;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptyTable(
        icon: Icons.receipt_long,
        title: 'آخر الدفعات',
        message: 'لا توجد دفعات بعد',
      );
    }
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _TableTitle('آخر الدفعات'),
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
                        DataCell(
                          StatusPill(
                            text: _accountingStatusLabel(p.status),
                            tone: _accountingStatusTone(p.status),
                          ),
                        ),
                        DataCell(Text(formatFinanceDate(p.createdAt))),
                        DataCell(
                          p.status == 'voided'
                              ? const Text('معكوسة')
                              : TextButton.icon(
                                  onPressed:
                                      onVoid == null ? null : () => onVoid!(p),
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
      return const _EmptyTable(
        icon: Icons.handshake_outlined,
        title: 'السلف والتسويات',
        message: 'لا توجد سلف بعد',
      );
    }
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _TableTitle('السلف والتسويات'),
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
                  : const StatusPill(
                      text: 'تمت التسوية',
                      tone: PillTone.neutral,
                    ),
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
      return const _EmptyTable(
        icon: Icons.scale_outlined,
        title: 'سجل القيود',
        message: 'لا توجد قيود مالية',
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
          _TableTitle(title),
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

class _TableTitle extends StatelessWidget {
  const _TableTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.s12,
        AppTokens.s12,
        AppTokens.s12,
        AppTokens.s8,
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppTokens.sidebarBg,
            ),
      ),
    );
  }
}

/// Empty table → one compact line (title + muted message) instead of a big
/// centred illustration.
class _EmptyTable extends StatelessWidget {
  const _EmptyTable({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AppCard(
      padding: const EdgeInsets.all(AppTokens.s12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppTokens.slate100,
              borderRadius: BorderRadius.circular(AppTokens.r10),
            ),
            child: Icon(icon, size: 18, color: AppTokens.slate500),
          ),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: text.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppTokens.sidebarBg,
                  ),
                ),
                Text(
                  message,
                  style: text.bodySmall?.copyWith(color: AppTokens.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

PillTone _accountingStatusTone(String value) {
  return switch (value.trim().toLowerCase()) {
    'posted' => PillTone.green,
    'voided' || 'failed' => PillTone.red,
    'open' || 'pending' => PillTone.amber,
    _ => PillTone.neutral,
  };
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
