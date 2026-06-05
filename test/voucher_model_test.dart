import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/vouchers/domain/voucher_model.dart';

void main() {
  test('voucher page parses list, stats, and Arabic labels', () {
    final page = VoucherPage.fromJson({
      'data': {
        'items': [
          {
            'id': 11,
            'code': 'ABCD-1234-WXYZ',
            'amount': 5,
            'plan_id': 3,
            'status': 'active',
            'used_by_subscriber_id': null,
            'used_at': null,
            'expire_at': '2026-06-30T23:59:59Z',
            'generated_by': 2,
            'created_at': '2026-06-05T12:00:00Z',
          },
        ],
        'count': 1,
        'stats': {
          'active': 1,
          'used': 2,
          'revoked': 3,
          'expired': 4,
          'total_amount': 55.5,
          'total_count': 10,
        },
      },
    });

    expect(page.count, 1);
    expect(page.stats.totalAmount, 55.5);
    expect(page.stats.totalCount, 10);
    expect(page.items.single.code, 'ABCD-1234-WXYZ');
    expect(page.items.single.planLabel, 'باقة رقم 3');
    expect(page.items.single.statusLabel, 'نشطة');
    expect(page.items.single.canRevoke, isTrue);
  });

  test('voucher generation draft serializes API contract safely', () {
    final draft = VoucherGenerateDraft(
      amount: 7.5,
      count: 20,
      planId: 4,
      expireAt: DateTime.utc(2026, 6, 30, 23, 59, 59),
    );

    expect(draft.toApiJson(), {
      'amount': 7.5,
      'count': 20,
      'plan_id': 4,
      'expire_at': '2026-06-30T23:59:59.000Z',
    });

    const withoutPlan = VoucherGenerateDraft(
      amount: 5,
      count: 1,
      planId: null,
      expireAt: null,
    );
    expect(withoutPlan.toApiJson(), {'amount': 5.0, 'count': 1});
  });

  test('voucher generate and revoke responses parse correctly', () {
    final generated = VoucherGenerateResult.fromJson({
      'data': {
        'items': [
          {
            'id': 1,
            'code': 'AAAA-BBBB-CCCC',
            'amount': '5',
            'status': 'active',
          },
          {
            'id': 2,
            'code': 'DDDD-EEEE-FFFF',
            'amount': '5',
            'status': 'active',
          },
        ],
        'count': 2,
      },
    });
    final revoked = VoucherRevokeResult.fromJson({
      'data': {'id': 1, 'status': 'revoked'},
    });

    expect(generated.count, 2);
    expect(generated.items.last.code, 'DDDD-EEEE-FFFF');
    expect(revoked.id, 1);
    expect(voucherStatusLabel(revoked.status), 'ملغاة');
  });
}
