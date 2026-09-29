import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/status_pill.dart';
import '../../../../core/l10n/arabic_labels.dart';
import '../../../subscribers/domain/subscriber_actions_model.dart'
    show arDuration, formatMoney;
import '../../domain/accounting_model.dart';

/// Width under which the finance tables turn into stacked rows: on phones
/// the old DataTable pushed «عكس» and the date ~280 px off-screen with no
/// hint that the table scrolls sideways.
const double kFinanceTableBreakpoint = 700;

String _money(num amount, String currency) =>
    formatMoney(amount.toDouble(), currency);

class PaymentsTable extends StatelessWidget {
  const PaymentsTable({super.key, required this.items, required this.onVoid});

  final List<PaymentTransaction> items;
  final Future<void> Function(PaymentTransaction payment)? onVoid;

  // A voided row already carries the «معكوسة» pill — no second label.
  Widget _voidCell(PaymentTransaction p) => p.status == 'voided'
      ? const SizedBox.shrink()
      : TextButton.icon(
          onPressed: onVoid == null ? null : () => onVoid!(p),
          icon: const Icon(Icons.undo, size: 18),
          label: const Text('عكس'),
        );

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
      child: LayoutBuilder(
        builder: (context, c) {
          final narrow = c.maxWidth < kFinanceTableBreakpoint;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _TableTitle('آخر الدفعات'),
              if (narrow)
                for (final p in items) ...[
                  const Divider(height: 1),
                  _StackedRow(
                    title: '#${p.id} · ${_money(p.amount, p.currency)}',
                    subtitle:
                        '${arDuration(p.earnedMinutes)} · ${formatFinanceDate(p.createdAt)}',
                    pill: StatusPill(
                      text: _accountingStatusLabel(p.status),
                      tone: _accountingStatusTone(p.status),
                    ),
                    trailing: _voidCell(p),
                  ),
                ]
              else
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
                              DataCell(Text(_money(p.amount, p.currency))),
                              DataCell(Text(arDuration(p.earnedMinutes))),
                              DataCell(
                                StatusPill(
                                  text: _accountingStatusLabel(p.status),
                                  tone: _accountingStatusTone(p.status),
                                ),
                              ),
                              DataCell(Text(formatFinanceDate(p.createdAt))),
                              DataCell(_voidCell(p)),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// One row of a stacked (phone) finance table: text on the start side, the
/// status pill and the action always on screen at the end.
class _StackedRow extends StatelessWidget {
  const _StackedRow({
    required this.title,
    required this.subtitle,
    this.pill,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? pill;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
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
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppTokens.sidebarBg,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(color: AppTokens.textMuted),
                ),
                if (pill != null) ...[
                  const SizedBox(height: 4),
                  pill!,
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppTokens.s8),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class LoansTable extends StatelessWidget {
  const LoansTable({
    super.key,
    required this.items,
    required this.onSettle,
    this.currency = '',
  });

  final List<LoanEntry> items;
  final String currency;
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
          ...items.map((loan) {
            final cur = loan.currency.isEmpty ? currency : loan.currency;
            final partial = loan.isOpen &&
                loan.outstanding > 0 &&
                loan.outstanding < loan.amount;
            return ListTile(
              title: Text(
                '#${loan.id} · ${arDuration(loan.durationMinutes)} • ${_money(loan.amount, cur)}',
              ),
              subtitle: Text(
                [
                  if (partial) 'المتبقّي ${_money(loan.outstanding, cur)}',
                  loan.reason.isEmpty ? 'بدون سبب مسجل' : loan.reason,
                ].join(' · '),
              ),
              trailing: loan.status == 'open'
                  ? TextButton(
                      onPressed:
                          onSettle == null ? null : () => onSettle!(loan),
                      child: const Text('تسوية'),
                    )
                  : StatusPill(
                      text: loanClosedLabel(loan.status),
                      tone: loan.status == 'settled'
                          ? PillTone.green
                          : PillTone.neutral,
                    ),
            );
          }),
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
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < kFinanceTableBreakpoint) {
          return AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _TableTitle('سجل القيود'),
                for (final e in items) ...[
                  const Divider(height: 1),
                  _StackedRow(
                    title:
                        '#${e.id} · ${_ledgerTypeLabel(e.entryType)} · ${_money(e.amount, e.currency)}',
                    subtitle:
                        '${_ledgerSourceLabel(e.sourceType)} · ${formatFinanceDate(e.createdAt)}',
                  ),
                ],
              ],
            ),
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
                  _money(e.amount, e.currency),
                  _ledgerSourceLabel(e.sourceType),
                  formatFinanceDate(e.createdAt),
                ],
              )
              .toList(),
        );
      },
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

/// Closed-loan pill: a forgiven/written-off loan is `voided` on the server —
/// it was NOT paid, so it must never read «تمت التسوية».
String loanClosedLabel(String status) => switch (status.trim().toLowerCase()) {
      'settled' => 'تمت التسوية',
      'voided' || 'forgiven' || 'writeoff' => 'مسامحة / ملغاة',
      'pending' => 'بانتظار الموافقة',
      _ => 'مغلقة',
    };

String _ledgerTypeLabel(String value) => ledgerTypeLabel(value);

String _ledgerSourceLabel(String value) => ledgerSourceLabel(value);
