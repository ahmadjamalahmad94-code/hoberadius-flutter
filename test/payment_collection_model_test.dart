import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/payment_collection/domain/payment_collection_model.dart';

void main() {
  test('payment request page parses review queue payload', () {
    final page = PaymentRequestPage.fromJson({
      'ok': true,
      'data': {
        'count': 1,
        'items': [
          {
            'id': 9,
            'payer_type': 'subscriber',
            'payer_id': 44,
            'purpose': 'subscriber_renewal',
            'amount': 50,
            'currency': 'ILS',
            'provider': 'manual_wallet',
            'receiver_wallet': '0590000000',
            'reference_code': 'PAY-9',
            'status': 'proof_submitted',
            'service_apply_status': 'not_applied',
            'created_at': '2026-05-30T10:00:00Z',
            'updated_at': '2026-05-30T11:00:00Z',
          },
        ],
      },
    });

    final item = page.items.single;
    expect(page.count, 1);
    expect(item.isReviewable, isTrue);
    expect(item.amountLabel, '50 ILS');
    expect(item.statusLabel, 'بانتظار مراجعة الإثبات');
    expect(item.purposeLabel, 'تجديد مشترك');
    expect(item.payerLabel, 'مشترك #44');
    expect(item.serviceApplyLabel, 'لم تطبق الخدمة');
  });

  test('paid request exposes service apply action state', () {
    final result = PaymentReviewResult.fromJson({
      'data': {
        'request': {
          'id': 10,
          'status': 'paid',
          'purpose': 'card_purchase',
          'amount': '75.5',
          'currency': 'ILS',
          'payer_type': 'card_user',
          'payer_id': 3,
          'service_apply_status': 'pending',
        },
      },
    });

    expect(result.request.isPaid, isTrue);
    expect(result.request.canApplyService, isTrue);
    expect(result.request.amountLabel, '75.50 ILS');
    expect(result.request.purposeLabel, 'شراء كروت');
  });
}
