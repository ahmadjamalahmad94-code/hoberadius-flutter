import '../../subscribers/domain/subscriber_model.dart';
import '../domain/accounting_model.dart';

class SubscriberFinanceData {
  const SubscriberFinanceData(
    this.subscriber,
    this.payments,
    this.loans,
    this.ledger,
  );

  final Subscriber subscriber;
  final List<PaymentTransaction> payments;
  final List<LoanEntry> loans;
  final List<LedgerEntry> ledger;
}
