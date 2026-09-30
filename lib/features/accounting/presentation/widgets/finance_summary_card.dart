import 'package:flutter/material.dart';

import '../../../../core/format/currency.dart';
import '../../../../shared/widgets/hub_layout.dart';
import '../../../../shared/widgets/status_pill.dart';
import '../../../subscribers/domain/subscriber_actions_model.dart'
    show formatMoney;
import '../../domain/accounting_model.dart';

/// The numbers of the finance summary, computed once (unit-tested).
///
/// Re-test findings fixed here (r03 N4, r10 N4):
/// - open loans count what is still OWED (`outstanding`), not the original
///   amount of a partly settled loan;
/// - a forgiven loan (server status `voided`) is «مسامحة», never counted as
///   settled — only real settlements are «مسدَّد»;
/// - «مدفوعات» is the server's all-time total (`total_paid` of the 360),
///   not the sum of the first page of payments;
/// - «الصافي» = balance − open loans, so a balance debt (plan-change debt,
///   paid-by-debt extensions) is no longer ignored.
class FinanceSummaryFigures {
  const FinanceSummaryFigures({
    required this.paidTotal,
    required this.paidIsServerTotal,
    required this.openCount,
    required this.openOutstanding,
    required this.settledTotal,
    required this.forgivenTotal,
    required this.balance,
    this.paidByCurrency = const [],
  });

  final double paidTotal;

  /// «مدفوعات» per currency when the subscriber has payments in more than
  /// one currency (a 7 USD payment was shown as «7 ILS» — f07 N-C3). Empty
  /// when every payment is in the system currency.
  final List<CurrencyAmount> paidByCurrency;

  /// `false`: the server gave no total — [paidTotal] covers only the loaded
  /// rows (older servers) and is labelled as such.
  final bool paidIsServerTotal;
  final int openCount;
  final double openOutstanding;
  final double settledTotal;
  final double forgivenTotal;

  /// The subscriber's balance (negative = debt outside loans).
  final double balance;

  /// What the subscriber owes (positive) or has in credit (negative net).
  double get net => _r2(balance - openOutstanding);

  factory FinanceSummaryFigures.compute({
    required List<PaymentTransaction> payments,
    required List<LoanEntry> loans,
    required double balance,
    double? serverTotalPaid,
    double? serverOpenOutstanding,
    int? serverOpenCount,
    String currency = '',
  }) {
    final live = payments.where((p) => p.status != 'voided').toList();
    final paid = serverTotalPaid ??
        live.fold<double>(0, (s, p) => s + p.amount.toDouble());
    // Rows in another currency than the system one: never labelled with
    // the system currency. The server's total adds every row whatever its
    // currency, so the system-currency share is that total minus the
    // foreign rows.
    final system = currency.trim().toUpperCase();
    final foreign = <String, double>{};
    for (final p in live) {
      final code = p.currency.trim().toUpperCase();
      if (code.isEmpty || code == system) continue;
      foreign[code] = (foreign[code] ?? 0) + p.amount.toDouble();
    }
    final byCurrency = <CurrencyAmount>[];
    if (foreign.isNotEmpty && system.isNotEmpty) {
      final foreignSum = foreign.values.fold<double>(0, (s, v) => s + v);
      final own = _r2(paid - foreignSum);
      if (own > 0) byCurrency.add(CurrencyAmount(system, own));
      for (final e in foreign.entries) {
        byCurrency.add(CurrencyAmount(e.key, _r2(e.value)));
      }
    }
    final open = loans.where((l) => l.status == 'open').toList();
    final openOutstanding = serverOpenOutstanding ??
        open.fold<double>(0, (s, l) => s + l.outstanding.toDouble());
    var settled = 0.0;
    var forgiven = 0.0;
    for (final l in loans) {
      final paidPart = l.settledAmount.toDouble();
      switch (l.status) {
        case 'settled':
          // Older servers send no settled_amount: a settled loan was paid.
          settled += paidPart > 0 ? paidPart : l.amount.toDouble();
        case 'voided':
          settled += paidPart;
          final rest = l.amount.toDouble() - paidPart;
          if (rest > 0) forgiven += rest;
        case 'open':
          settled += paidPart;
      }
    }
    return FinanceSummaryFigures(
      paidTotal: _r2(paid),
      paidByCurrency: byCurrency,
      paidIsServerTotal: serverTotalPaid != null,
      openCount: serverOpenCount ?? open.length,
      openOutstanding: _r2(openOutstanding),
      settledTotal: _r2(settled),
      forgivenTotal: _r2(forgiven),
      balance: _r2(balance),
    );
  }

  static double _r2(double v) {
    final r = (v * 100).round() / 100;
    return r == 0 ? 0 : r; // no «-0.00»
  }
}

/// Top-of-screen summary for the finance view as a colour-coded counter grid
/// (2 columns on phones, one row when wide). Pure presentation.
class FinanceSummaryCard extends StatelessWidget {
  const FinanceSummaryCard({
    super.key,
    required this.figures,
    required this.currency,
  });

  final FinanceSummaryFigures figures;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final f = figures;
    String money(double v) => formatMoney(v, currency);
    String money2(CurrencyAmount a) => formatMoney(a.amount, a.currency);
    final net = f.net;
    return LayoutBuilder(
      builder: (context, c) => CountGrid(
        columns: c.maxWidth >= 560 ? 3 : 2,
        items: [
          CountItem.text(
            f.paidIsServerTotal ? 'مدفوعات (الكل)' : 'مدفوعات (المعروضة)',
            f.paidByCurrency.length > 1
                ? formatByCurrency(f.paidByCurrency)
                : f.paidByCurrency.length == 1
                    ? money2(f.paidByCurrency.single)
                    : money(f.paidTotal),
            tone: f.paidTotal > 0 ? PillTone.green : PillTone.neutral,
          ),
          CountItem.text(
            'سلف مفتوحة (${f.openCount}) — المتبقّي',
            money(f.openOutstanding),
            tone: f.openOutstanding > 0 ? PillTone.amber : PillTone.neutral,
          ),
          CountItem.text(
            'سلف مسدَّدة',
            money(f.settledTotal),
            tone: f.settledTotal > 0 ? PillTone.blue : PillTone.neutral,
          ),
          if (f.forgivenTotal > 0)
            CountItem.text(
              'مسامحة',
              money(f.forgivenTotal),
              tone: PillTone.neutral,
            ),
          CountItem.text(
            f.balance < 0 ? 'دين على الرصيد' : 'الرصيد',
            money(f.balance.abs()),
            tone: f.balance < 0 ? PillTone.red : PillTone.brand,
          ),
          CountItem.text(
            net < 0 ? 'الصافي — مستحقّ عليه' : 'الصافي',
            money(net.abs()),
            tone: net < 0 ? PillTone.red : PillTone.brand,
          ),
        ],
      ),
    );
  }
}
