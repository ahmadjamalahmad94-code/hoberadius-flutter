import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/accounting/domain/accounting_model.dart';

void main() {
  test('PaymentTransaction parses backend result fields', () {
    final payment = PaymentTransaction.fromJson({
      'id': 7,
      'subscriber_id': 3,
      'username': 'user1',
      'amount': 50,
      'currency': 'JOD',
      'method': 'cash',
      'status': 'posted',
      'earned_minutes': 14400,
      'ledger_entry_id': 11,
      'discount_amount': 5,
      'activation_result': {'dry_run': true, 'applied_to_radius': false},
      'notes': 'partial',
      'created_at': '2026-05-20T00:00:00Z',
    });

    expect(payment.id, 7);
    expect(payment.earnedMinutes, 14400);
    expect(payment.activationResult['dry_run'], isTrue);
    expect(payment.notes, 'partial');
  });

  test('LoanEntry and LedgerEntry parse append-only accounting fields', () {
    final loan = LoanEntry.fromJson({
      'id': 9,
      'subscriber_id': 3,
      'username': 'user1',
      'duration_minutes': 120,
      'amount': 10,
      'currency': 'JOD',
      'reason': 'support',
      'status': 'open',
      'approval_status': 'not_required',
      'starts_at': '2026-06-05T08:00:00Z',
      'ends_at': '2026-06-05T10:00:00Z',
    });
    final ledger = LedgerEntry.fromJson({
      'id': 12,
      'entry_type': 'void',
      'direction': 'debit',
      'amount': -50,
      'currency': 'JOD',
      'username': 'user1',
      'status': 'void',
      'reversal_of_entry_id': 11,
      'source_type': 'ledger_void',
    });

    expect(loan.durationMinutes, 120);
    expect(loan.status, 'open');
    expect(loan.statusLabel, 'مفتوحة');
    expect(loan.approvalStatusLabel, 'لا يلزم اعتماد');
    expect(loan.startsAt, isNotNull);
    expect(loan.endsAt, isNotNull);
    expect(ledger.entryType, 'void');
    expect(ledger.reversalOfEntryId, 11);
  });
}
