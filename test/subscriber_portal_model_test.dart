import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/subscriber_portal/domain/subscriber_portal_model.dart';

void main() {
  test('parses subscriber portal login capabilities', () {
    final result = SubscriberPortalLoginResult.fromJson({
      'ok': true,
      'token': 'subscriber-token',
      'expires_in': 900,
      'subscriber': {
        'id': 17,
        'username': 'sub-17',
        'full_name': 'Ahmad Subscriber',
        'mobile': '0599000000',
        'email': 'subscriber@example.com',
        'status': 'active',
        'service_type': 'pppoe',
      },
      'capabilities': {
        'dashboard': true,
        'requests': true,
        'loan_request': true,
        'renewal_request': true,
        'support_request': true,
      },
    });

    expect(result.token, 'subscriber-token');
    expect(result.subscriber.id, 17);
    expect(result.subscriber.title, 'Ahmad Subscriber');
    expect(result.capabilities.dashboard, isTrue);
    expect(result.capabilities.loanRequest, isTrue);
  });

  test('parses dashboard, sessions, and request labels', () {
    final dashboard = SubscriberPortalDashboard.fromJson({
      'subscriber': {
        'id': 17,
        'username': 'sub-17',
        'full_name': 'Ahmad Subscriber',
        'status': 'active',
      },
      'plan': {
        'id': 4,
        'name': '50 Mbps',
        'price': 35,
        'currency': 'ILS',
        'duration_minutes': 43200,
      },
      'subscription': {
        'status': 'expired',
        'expire_at': '2026-06-01T00:00:00Z',
        'remaining_days': -4,
        'expired_view_allowed': true,
      },
      'usage': {
        'upload_bytes': 1048576,
        'download_bytes': 2097152,
        'session_seconds': 7200,
      },
      'wallet': {
        'balance': '12.50',
        'balance_minor': 1250,
        'currency': 'ILS',
      },
      'debt': 7.5,
      'loan_policy': {
        'enabled': true,
        'auto_approve': false,
        'allowed_minutes': 120,
        'reason': 'manual review',
      },
      'sessions': [
        {
          'acctsessionid': 's-1',
          'nasipaddress': '10.0.0.1',
          'framedipaddress': '172.16.0.10',
          'acctstarttime': '2026-06-05T09:00:00Z',
          'acctstoptime': null,
          'acctsessiontime': 7200,
          'acctinputoctets': 1048576,
          'acctoutputoctets': 2097152,
        },
      ],
      'loans': [],
      'payments': [],
      'notifications': [],
      'cards': [],
      'walled_garden_note': 'note',
    });

    expect(dashboard.hasDebt, isTrue);
    expect(dashboard.plan.title, '50 Mbps');
    expect(dashboard.plan.priceLabel, '35 ILS');
    expect(dashboard.subscription.expiredViewAllowed, isTrue);
    expect(dashboard.usage.totalLabel, isNot('0 ب'));
    expect(dashboard.sessions.single.online, isTrue);
    expect(dashboard.loanPolicy.enabled, isTrue);

    final request = SubscriberPortalRequest.fromJson({
      'id': 21,
      'request_type': 'loan',
      'status': 'requires_approval',
      'reason': 'need more time',
      'created_at': '2026-06-05T10:00:00Z',
      'result': {'ticket_id': 3},
    });

    expect(request.id, 21);
    expect(request.typeLabel, isNot('loan'));
    expect(request.statusLabel, isNot('requires_approval'));
    expect(request.result['ticket_id'], 3);
  });
}
