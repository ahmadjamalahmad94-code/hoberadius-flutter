import '../../subscribers/domain/subscriber_actions_model.dart';
import '../../subscribers/domain/subscriber_model.dart';
import '../domain/accounting_model.dart';

class SubscriberFinanceData {
  const SubscriberFinanceData(
    this.subscriber,
    this.payments,
    this.loans,
    this.ledger, {
    this.context,
  });

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
