import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/distributors/domain/distributor_model.dart';

void main() {
  test('Distributor parses backend JSON fields', () {
    final distributor = Distributor.fromJson({
      'id': 7,
      'name': 'north',
      'display_name': 'موزع الشمال',
      'status': 'active',
      'permissions_json': ['cards.read', 'cards.sell'],
      'scope_json': {'card_batches': 'assigned'},
      'balance': 5,
      'credit_limit': '100',
      'debt_balance': '12.5',
    });

    expect(distributor.id, 7);
    expect(distributor.title, 'موزع الشمال');
    expect(distributor.permissions, ['cards.read', 'cards.sell']);
    expect(distributor.scope['card_batches'], 'assigned');
    expect(distributor.debtBalance, 12.5);
    expect(distributor.isActive, isTrue);
  });

  test('DistributorSummary keeps financial counters', () {
    final summary = DistributorSummary.fromJson({
      'distributor': {'id': 1, 'name': 'd1'},
      'assigned_batches': 3,
      'balance': 10,
      'debt_balance': 20,
      'credit_limit': 50,
      'ledger': {'debit': 30, 'credit': 12, 'entries': 4},
    });

    expect(summary.distributor.name, 'd1');
    expect(summary.assignedBatches, 3);
    expect(summary.ledgerDebit, 30);
    expect(summary.ledgerCredit, 12);
    expect(summary.ledgerEntries, 4);
  });
}
