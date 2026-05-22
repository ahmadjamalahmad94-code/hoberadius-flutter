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
      'vps': {
        'hostname': 'vps-1',
        'platform': 'Linux',
        'process_uptime': '3س 4د',
        'system_uptime': '9ي 1س',
        'cpu_pct': 12.5,
        'cpu_count': 4,
        'load': {'one': 0.2, 'five': 0.3, 'fifteen': 0.4},
        'memory': {
          'percent': 44,
          'used_human': '1.2 GB',
          'available_human': '2.8 GB',
        },
        'disk': {'percent': 55, 'free_human': '20 GB', 'path': '/'},
        'network': {
          'ping_host': '8.8.8.8',
          'ping_ok': true,
          'ping_ms': 22.4,
          'dns_host': 'google.com',
          'dns_ok': true,
          'dns_ip': '142.250.0.0',
        },
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
    expect(status.vps.hostname, 'vps-1');
    expect(status.vps.cpuPct, 12.5);
    expect(status.vps.memory.percent, 44);
    expect(status.vps.disk.freeHuman, '20 GB');
    expect(status.vps.network.pingMs, 22.4);
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
