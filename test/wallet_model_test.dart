import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/wallets/domain/wallet_model.dart';

void main() {
  test('wallet page parses wallet list with Arabic labels', () {
    final page = WalletPage.fromJson({
      'data': {
        'items': [
          {
            'id': 5,
            'owner_type': 'subscriber',
            'owner_id': 22,
            'currency': 'ILS',
            'balance': '15.50',
            'status': 'active',
            'created_at': '2026-06-05T10:00:00Z',
            'updated_at': '2026-06-05T11:00:00Z',
          },
        ],
        'count': 1,
      },
    });

    expect(page.count, 1);
    expect(page.items.single.ownerLabel, 'مشترك #22');
    expect(page.items.single.balance, '15.50');
    expect(page.items.single.statusLabel, 'نشطة');
  });

  test('wallet create and change drafts serialize API contract', () {
    const create = WalletCreateDraft(
      ownerType: 'distributor',
      ownerId: 7,
      currency: 'JOD',
    );
    const change = WalletChangeDraft(
      amount: 20,
      referenceType: 'manual',
      referenceId: 3,
      notes: 'تحصيل نقدي',
    );

    expect(create.toApiJson(), {
      'owner_type': 'distributor',
      'owner_id': 7,
      'currency': 'JOD',
    });
    expect(change.toApiJson(), {
      'amount': 20,
      'reference_type': 'manual',
      'reference_id': 3,
      'notes': 'تحصيل نقدي',
    });
  });

  test('wallet change result and transactions parse balance history', () {
    final result = WalletChangeResult.fromJson({
      'data': {
        'wallet': {
          'id': 5,
          'owner_type': 'subscriber',
          'owner_id': 22,
          'currency': 'ILS',
          'balance': '20.00',
          'status': 'active',
        },
        'transaction': {
          'id': 9,
          'wallet_id': 5,
          'transaction_type': 'credit',
          'amount': '20.00',
          'before_balance': '0.00',
          'after_balance': '20.00',
          'currency': 'ILS',
          'reference_type': 'manual',
          'reference_id': 1,
          'actor_type': 'admin',
          'actor_id': 2,
          'notes': 'شحن أولي',
          'created_at': '2026-06-05T12:00:00Z',
        },
      },
    });

    expect(result.wallet.balance, '20.00');
    expect(result.transaction.typeLabel, 'شحن');
    expect(result.transaction.referenceLabel, 'تسجيل يدوي');

    final page = WalletTransactionsPage.fromJson({
      'data': {
        'items': [
          {
            'id': 10,
            'wallet_id': 5,
            'transaction_type': 'debit',
            'amount': '4.50',
            'before_balance': '20.00',
            'after_balance': '15.50',
            'currency': 'ILS',
            'reference_type': 'invoice',
            'reference_id': 8,
            'created_at': '2026-06-05T13:00:00Z',
          },
        ],
        'count': 1,
      },
    });

    expect(page.items.single.typeLabel, 'خصم');
    expect(page.items.single.referenceLabel, 'فاتورة');
    expect(page.items.single.afterBalance, '15.50');
  });
}
