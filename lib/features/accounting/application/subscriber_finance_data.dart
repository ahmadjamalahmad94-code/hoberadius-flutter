import '../../subscribers/domain/subscriber_actions_model.dart';
import '../../subscribers/domain/subscriber_model.dart';
import '../../subscribers/domain/subscriber_360_model.dart';
import '../domain/accounting_model.dart';
import '../presentation/widgets/finance_summary_card.dart';

class SubscriberFinanceData {
  const SubscriberFinanceData(
    this.subscriber,
    this.payments,
    this.loans,
    this.ledger, {
    this.context,
    this.totals,
  });

  /// The 360's `financial` block: totals over every row (null on failure).
  final Subscriber360Financial? totals;

  /// The summary card's figures — server totals when present.
  FinanceSummaryFigures get summary => FinanceSummaryFigures.compute(
        payments: payments,
        loans: loans,
        balance: subscriber.balance,
        serverTotalPaid: totals?.hasTotals == true ? totals!.totalPaid : null,
        serverOpenOutstanding:
            totals?.hasTotals == true ? totals!.openLoanAmount : null,
        currency: currency,
      );

  final Subscriber subscriber;
  final List<PaymentTransaction> payments;
  final List<LoanEntry> loans;
  final List<LedgerEntry> ledger;

  /// actions-context (price, plan period, the SERVER's system currency);
  /// null on servers without it.
  final SubscriberActionsContext? context;

  /// The currency to show and to reason with: the server's system currency
  /// (`default_currency()` via actions-context), else the currency stored on
  /// the subscriber's own rows — never a hardcoded «JOD».
  String get currency {
    final fromServer = context?.currency.trim() ?? '';
    if (fromServer.isNotEmpty && context?.legacy != true) return fromServer;
    for (final p in payments) {
      if (p.currency.isNotEmpty) return p.currency;
    }
    for (final l in loans) {
      if (l.currency.isNotEmpty) return l.currency;
    }
    for (final e in ledger) {
      if (e.currency.isNotEmpty) return e.currency;
    }
    return fromServer;
  }
}
