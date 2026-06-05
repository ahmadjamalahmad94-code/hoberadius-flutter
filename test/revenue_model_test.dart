import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/revenue/domain/revenue_model.dart';

void main() {
  test('revenue page parses business revenue payload and summary', () {
    final page = RevenuePage.fromJson({
      'data': {
        'items': [
          {
            'id': 7,
            'source_type': 'card_user_purchase',
            'source_id': 44,
            'price_snapshot_id': 3,
            'original_price': 10,
            'retail_price': 10,
            'wholesale_cost': 6,
            'collected_amount': 10,
            'debt_amount': 0,
            'discount_amount': 0,
            'net_profit': 4,
            'company_share': 3,
            'distributor_share': 1,
            'manager_share': 0,
            'currency': 'ILS',
            'status': 'posted',
            'metadata': {'batch': 'A'},
            'created_at': '2026-06-05T12:00:00Z',
          },
          {
            'id': 8,
            'source_type': 'invoice',
            'source_id': 11,
            'original_price_minor': 2500,
            'collected_amount_minor': 2000,
            'wholesale_cost_minor': 1200,
            'net_profit_minor': 800,
            'company_share_minor': 600,
            'distributor_share_minor': 200,
            'currency': 'JOD',
            'status': 'pending',
            'created_at': '2026-06-05T13:00:00Z',
          },
        ],
        'count': 2,
      },
    });

    expect(page.count, 2);
    expect(page.items.first.sourceLabel, 'شراء مستخدم كروت #44');
    expect(page.items.first.statusLabel, 'مرحلة');
    expect(page.items.last.collectedAmount, 20);
    expect(page.items.last.netProfit, 8);
    expect(page.summary.totalCollected, 30);
    expect(page.summary.totalNetProfit, 12);
    expect(page.summary.postedCount, 1);
  });

  test('revenue labels hide unknown empty values behind Arabic text', () {
    final record = RevenueRecord.fromJson({
      'id': 1,
      'source_type': '',
      'status': '',
    });

    expect(record.sourceLabel, 'غير محدد');
    expect(record.statusLabel, 'بانتظار الترحيل');
    expect(revenueStatusLabel('refunded'), 'مسترجعة');
    expect(revenueSourceLabel('subscriber_payment'), 'دفعة مشترك');
  });
}
