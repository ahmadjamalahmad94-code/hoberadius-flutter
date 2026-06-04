import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/cards/domain/card_model.dart';

void main() {
  test('Recharge batches page parses wallet recharge contract', () {
    final page = RechargeBatchesPage.fromJson({
      'data': {
        'items': [
          {
            'id': 7,
            'batch_code': 'B-7',
            'package_name': 'حزمة شحن',
            'count': 3,
            'used_count': 1,
            'remaining_count': 2,
            'total_value': '20.00',
            'denominations': [
              {'value': 5, 'count': 2},
              {'value': 10, 'count': 1},
            ],
          }
        ],
        'total': 1,
        'page': 1,
        'per_page': 25,
        'pages': 1,
        'default_denominations': [5, 10, 20],
      },
    });

    expect(page.total, 1);
    expect(page.defaultDenominations, [5, 10, 20]);
    expect(page.items.single.displayName, 'حزمة شحن');
    expect(page.items.single.totalValue, 20);
    expect(page.items.single.denominations.last.value, 10);
  });

  test('Recharge batch detail parses cards without dropping password', () {
    final detail = RechargeBatchDetail.fromJson({
      'data': {
        'batch': {'id': 7, 'package_name': 'دفعة تجريبية'},
        'cards': [
          {
            'id': 11,
            'batch_id': 7,
            'username': '1234567890',
            'password': '12345',
            'wallet_value': 5,
            'used': false,
          }
        ],
        'total_cards': 1,
        'page': 1,
        'per_page': 25,
        'pages': 1,
      },
    });

    expect(detail.batch.displayName, 'دفعة تجريبية');
    expect(detail.cards.single.username, '1234567890');
    expect(detail.cards.single.password, '12345');
    expect(detail.cards.single.walletValue, 5);
  });
}
