import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/invoices/domain/invoice_model.dart';

void main() {
  test('invoice page parses list, stats, and Arabic labels', () {
    final page = InvoicePage.fromJson({
      'data': {
        'items': [
          {
            'id': 9,
            'invoice_number': 'INV-202606-00009',
            'subscriber_id': 4,
            'username': 'client-1',
            'amount': 75.5,
            'admin_id': 1,
            'plan_id': 2,
            'plan_name': '50 ميجا',
            'service_type': 'Hotspot',
            'router_id': null,
            'direction': 'charge',
            'balance_before': 0,
            'balance_after': 75.5,
            'recharged_on': null,
            'expiration_at': '2026-06-30T00:00:00Z',
            'payment_method': 'transfer',
            'payment_gateway_id': null,
            'status': 'pending',
            'note': 'بانتظار التحويل',
            'created_at': '2026-06-05T11:00:00Z',
            'updated_at': '2026-06-05T11:00:00Z',
          },
        ],
        'count': 1,
        'stats': {
          'total': 75.5,
          'paid': 0,
          'pending': 75.5,
          'count': 1,
        },
      },
    });

    expect(page.count, 1);
    expect(page.stats.total, 75.5);
    expect(page.stats.pending, 75.5);
    expect(page.items.single.displayNumber, 'INV-202606-00009');
    expect(page.items.single.statusLabel, 'معلقة');
    expect(page.items.single.directionLabel, 'تحصيل');
    expect(page.items.single.paymentMethodLabel, 'حوالة');
    expect(page.items.single.serviceTypeLabel, 'بوابة الدخول');
  });

  test('invoice draft serializes create invoice contract', () {
    final draft = InvoiceDraft(
      subscriberId: 4,
      username: 'client-1',
      amount: 75.5,
      planId: 2,
      planName: '50 ميجا',
      serviceType: 'Hotspot',
      direction: 'charge',
      paymentMethod: 'cash',
      status: 'paid',
      expirationAt: DateTime.utc(2026, 6, 30),
      note: 'فاتورة اشتراك شهرية',
    );

    expect(draft.toApiJson(), {
      'subscriber_id': 4,
      'username': 'client-1',
      'amount': 75.5,
      'plan_id': 2,
      'plan_name': '50 ميجا',
      'service_type': 'Hotspot',
      'direction': 'charge',
      'payment_method': 'cash',
      'status': 'paid',
      'expiration_at': '2026-06-30T00:00:00.000Z',
      'note': 'فاتورة اشتراك شهرية',
    });
  });

  test('invoice status update hides empty note from payload', () {
    const update = InvoiceStatusUpdate(status: 'refunded', note: '  ');

    expect(update.toApiJson(), {'status': 'refunded'});
    expect(invoiceStatusLabel('refunded'), 'مسترجعة');
    expect(invoiceStatusLabel('canceled'), 'ملغاة');
  });
}
