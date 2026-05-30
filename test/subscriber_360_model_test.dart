import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/subscribers/domain/subscriber_360_model.dart';

void main() {
  test('Subscriber360 parses account overview without secrets', () {
    final state = Subscriber360.fromJson({
      'subscriber': {
        'id': 7,
        'username': 's360-user',
        'full_name': 'مشترك تجريبي',
        'mobile': '0599000000',
        'status': 'enabled',
        'service_type': 'Hotspot',
      },
      'plan': {'name': 'باقة شهرية'},
      'overview': {
        'service_type': 'Hotspot',
        'wallet_balance': 12.5,
        'open_debt': '3.5',
        'session_count': '2',
      },
      'financial': {
        'total_paid': '100',
        'total_discount': 10,
        'open_loan_amount': 3.5,
        'wallet_balance': 12.5,
        'payments': [
          {'amount': 100},
        ],
        'loans': [
          {'amount': 3.5},
        ],
        'ledger': [],
      },
      'usage': {
        'sessions': [
          {'acctstarttime': '2026-05-30'},
        ],
        'total_seconds': '3600',
        'download_bytes': 1048576,
        'upload_bytes': '2048',
      },
      'services': {'service_type': 'Hotspot'},
      'devices': [
        {'mac': 'AA:BB:CC:DD:EE:01', 'source': 'subscriber'},
      ],
      'timeline': [
        {
          'created_at': '2026-05-30T10:00:00Z',
          'item': {'entry_type': 'payment', 'amount': 100},
        },
      ],
      'login_events': [
        {'reply': 'Access-Accept'},
      ],
      'notes': 'ملاحظة مهمة',
    });

    expect(state.subscriber.username, 's360-user');
    expect(state.planName, 'باقة شهرية');
    expect(state.walletBalance, 12.5);
    expect(state.openDebt, 3.5);
    expect(state.sessionCount, 2);
    expect(state.financial.totalPaid, 100);
    expect(state.usage.totalSeconds, 3600);
    expect(state.usage.totalBytes, 1050624);
    expect(state.devices.single.mac, 'AA:BB:CC:DD:EE:01');
    expect(state.timeline.single.label, 'دفعة مالية');
  });
}
