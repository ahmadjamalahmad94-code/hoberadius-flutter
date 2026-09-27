import 'package:flutter/material.dart';

import '../../../../shared/widgets/hub_layout.dart';
import '../../../../shared/widgets/status_pill.dart';
import '../../domain/accounting_model.dart';

/// Top-of-screen summary for the finance view — sums payments, loans (open
/// vs settled), and a net "balance to the operator" figure as a tight,
/// colour-coded counter grid (2×2 on phones, one row of 4 when wide).
/// Pure presentation; data flows in pre-computed.
class FinanceSummaryCard extends StatelessWidget {
  const FinanceSummaryCard({
    super.key,
    required this.payments,
    required this.loans,
    required this.currency,
  });

  final List<PaymentTransaction> payments;
  final List<LoanEntry> loans;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final paidTotal = payments
        .where((p) => p.status != 'voided')
        .fold<num>(0, (sum, p) => sum + p.amount);
    final openLoans = loans.where((l) => l.status == 'open').toList();
    final openLoansTotal = openLoans.fold<num>(0, (s, l) => s + l.amount);
    final settledLoansTotal = loans
        .where((l) => l.status != 'open')
        .fold<num>(0, (s, l) => s + l.amount);
    final net = paidTotal - openLoansTotal;
    final cur = currency.isEmpty ? '' : ' $currency';

    return LayoutBuilder(
      builder: (context, c) => CountGrid(
        columns: c.maxWidth >= 560 ? 4 : 2,
        items: [
          CountItem.text(
            'مدفوعات',
            '${paidTotal.toStringAsFixed(2)}$cur',
            tone: paidTotal > 0 ? PillTone.green : PillTone.neutral,
          ),
          CountItem.text(
            'سلف مفتوحة (${openLoans.length})',
            '${openLoansTotal.toStringAsFixed(2)}$cur',
            tone: openLoans.isNotEmpty ? PillTone.amber : PillTone.neutral,
          ),
          CountItem.text(
            'سلف مسوّاة',
            '${settledLoansTotal.toStringAsFixed(2)}$cur',
            tone: settledLoansTotal > 0 ? PillTone.blue : PillTone.neutral,
          ),
          CountItem.text(
            'الصافي',
            '${net.toStringAsFixed(2)}$cur',
            tone: net < 0 ? PillTone.red : PillTone.brand,
          ),
        ],
      ),
    );
  }
}
