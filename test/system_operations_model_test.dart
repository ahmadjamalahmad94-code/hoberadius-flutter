import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/system_operations/domain/system_operations_model.dart';

void main() {
  test('SystemStatus parses counts routers and sync stats', () {
    final status = SystemStatus.fromJson({
      'tenant_id': 1,
      'counts': {
        'subscribers': 12,
        'cards': '30',
      },
      'sync_queue': {
        'queued': 2,
        'failed': '1',
      },
      'webhook_deliveries': {
        'delivered': 5,
      },
      'workers': {
        'sync_worker': {'alive': true},
      },
      'mt_routers': {
        'items': [
          {
            'id': 7,
            'name': 'Main',
            'host': '10.0.0.1',
            'enabled': true,
            'last_status': 'ok',
          },
        ],
      },
      'now': '2026-05-20T12:00:00Z',
    });

    expect(status.tenantId, 1);
    expect(status.counts['subscribers'], 12);
    expect(status.counts['cards'], 30);
    expect(status.syncQueue['queued'], 2);
    expect(status.syncQueue['failed'], 1);
    expect(status.webhooks['delivered'], 5);
    expect(status.routers.single.host, '10.0.0.1');
    expect(status.routers.single.enabled, isTrue);
  });

  test('SystemDiagnostics and SyncQueueState parse API payloads', () {
    final diagnostics = SystemDiagnostics.fromJson({
      'summary': {'total': 1, 'ok': '1'},
      'routers': [
        {
          'name': 'RTR',
          'host': '192.0.2.1',
          'status': 'ok',
          'verdict': 'healthy',
          'hint': '',
        },
      ],
    });
    expect(diagnostics.summary['ok'], 1);
    expect(diagnostics.routers.single.status, 'ok');

    final queue = SyncQueueState.fromJson({
      'status': 'all',
      'stats': {'queued': 1},
      'items': [
        {
          'id': 99,
          'kind': 'subscriber.update',
          'entity_key': 'u1',
          'status': 'queued',
          'attempts': '2',
          'last_error': '',
          'created_at': 'now',
          'next_attempt_at': 'soon',
        },
      ],
    });
    expect(queue.stats['queued'], 1);
    expect(queue.items.single.id, 99);
    expect(queue.items.single.attempts, 2);
  });
}
