import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/cards/domain/card_model.dart';

void main() {
  test('CardCheckResult parses operations payload without password', () {
    final card = CardCheckResult.fromJson({
      'exists': true,
      'status': 'active',
      'id': 44,
      'username': 'card-001',
      'has_password': true,
      'used': true,
      'revoked': false,
      'locked_mac': 'AA:BB:CC:DD:EE:FF',
      'created_at': '2026-05-20T10:00:00Z',
      'started_at': '2026-05-20T10:05:00Z',
      'expires_at': '2026-05-21T10:05:00Z',
      'remaining_seconds': 3600,
      'batch': {
        'id': 7,
        'batch_code': 'B-7',
        'package_name': 'Hotspot 4h',
        'generated': 100,
      },
      'profile': {
        'id': 3,
        'name': 'Pro',
        'speed_down_kbps': 5000,
        'speed_up_kbps': 1000,
      },
      'operations': {
        'can_disconnect': true,
        'can_lock_mac': true,
        'can_reset_usage': true,
        'can_disable': true,
        'can_enable': false,
        'can_delete_permanently': true,
      },
      'accounting_summary': {
        'sessions_count': 2,
        'online_sessions': 1,
        'unique_macs': 2,
        'total_upload_bytes': 1024,
        'total_download_bytes': 2048,
        'macs': [
          {'mac': 'AA:BB:CC:DD:EE:FF', 'sessions_count': 1},
        ],
        'latest_sessions': [
          {
            'id': 99,
            'session_id': 'sess-1',
            'online': true,
            'duration_seconds': 300,
            'upload_bytes': 1024,
            'download_bytes': 2048,
            'callingstationid': 'ignored',
            'mac_address': 'AA:BB:CC:DD:EE:FF',
          },
        ],
      },
      'data_sources': ['cards', 'radacct'],
      'missing_fields': ['sold_by'],
    });

    expect(card.id, 44);
    expect(card.username, 'card-001');
    expect(card.hasPassword, isTrue);
    expect(card.batch?.batchCode, 'B-7');
    expect(card.profile?.speedDownKbps, 5000);
    expect(card.operations.canDisconnect, isTrue);
    expect(card.accountingSummary.sessionsCount, 2);
    expect(card.accountingSummary.latestSessions.single.sessionId, 'sess-1');
    expect(card.accountingSummary.macs.single.mac, 'AA:BB:CC:DD:EE:FF');
    expect(card.dataSources, contains('radacct'));
    expect(card.missingFields, contains('sold_by'));
  });

  test('CardCheckResult parses not found card', () {
    final card = CardCheckResult.fromJson({
      'exists': false,
      'status': 'not_found',
      'query': 'missing',
    });

    expect(card.exists, isFalse);
    expect(card.status, 'not_found');
    expect(card.operations.canDisable, isFalse);
    expect(card.accountingSummary.latestSessions, isEmpty);
  });
}
