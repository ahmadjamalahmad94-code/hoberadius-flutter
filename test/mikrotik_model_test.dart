import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/mikrotik/domain/mikrotik_model.dart';

void main() {
  test('MikrotikConfig parses saved config without password leakage', () {
    final config = MikrotikConfig.fromJson({
      'id': 3,
      'name': 'core-router',
      'host': '10.0.0.1',
      'port': '8729',
      'username': 'api',
      'use_tls': true,
      'verify_tls': false,
      'timeout_sec': '15',
      'enabled': true,
      'password': 'secret',
    });

    expect(config.id, 3);
    expect(config.host, '10.0.0.1');
    expect(config.port, 8729);
    expect(config.useTls, isTrue);
    expect(config.verifyTls, isFalse);
    expect(config.timeoutSec, 15);
    expect(config.toBody().containsKey('password'), isFalse);
  });

  test('MikrotikConfig includes password only when explicitly supplied', () {
    const config = MikrotikConfig(
      name: 'router',
      host: '192.0.2.10',
      port: 8728,
      username: 'admin',
      useTls: false,
      verifyTls: true,
      timeoutSec: 10,
      enabled: true,
    );

    expect(config.toBody(password: '').containsKey('password'), isFalse);
    expect(config.toBody(password: 'new-pass')['password'], 'new-pass');
  });

  test('MikrotikTestResult parses identity and resource data', () {
    final result = MikrotikTestResult.fromJson({
      'connected': true,
      'identity': {'name': 'branch-router'},
      'resource': {
        'board-name': 'CCR',
        'version': '7.14',
        'uptime': '1d2h',
        'cpu-load': '4',
      },
    });

    expect(result.connected, isTrue);
    expect(result.displayName, 'branch-router');
    expect(result.boardName, 'CCR');
    expect(result.version, '7.14');
    expect(result.cpuLoad, '4');
  });

  test('MikrotikRouterOverview parses section envelopes', () {
    final overview = MikrotikRouterOverview.fromJson({
      'router_id': 5,
      'name': 'راوتر الفرع',
      'any_ok': true,
      'all_ok': false,
      'connection': {'mode': 'vpn', 'address': '10.77.0.2'},
      'sections': {
        'resource': {
          'ok': true,
          'data': [
            {'cpu-load': '7', 'uptime': '1d', 'version': '7.15'},
          ],
          'took_ms': 12,
          'cached': true,
          'dialed_address': '10.77.0.2',
          'mode': 'vpn',
        },
        'health': {
          'ok': false,
          'error': 'تعذر الاتصال',
          'took_ms': 30,
        },
      },
    });

    expect(overview.routerId, 5);
    expect(overview.modeLabel, 'عبر النفق');
    expect(overview.dialAddress, '10.77.0.2');
    expect(overview.section('resource')?.ok, isTrue);
    expect(overview.section('resource')?.firstRow['cpu-load'], '7');
    expect(overview.section('health')?.error, 'تعذر الاتصال');
  });
}
