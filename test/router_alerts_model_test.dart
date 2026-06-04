import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/router_alerts/domain/router_alerts_model.dart';

void main() {
  test('router alerts state parses settings and router thresholds', () {
    final state = RouterAlertsState.fromJson({
      'settings': {
        'enabled': true,
        'telegram': false,
        'offline': true,
        'high_traffic': true,
        'high_usage': true,
        'loop': true,
        'offline_after_min': 11,
        'default_speed_mbps': 120,
        'default_usage_gb': 400,
        'usage_window': 'month',
      },
      'routers': [
        {
          'id': 17,
          'name': 'راوتر الفرع',
          'address': '10.0.0.17',
          'enabled': true,
          'offline_after_min': 5,
          'normal_speed_mbps': 80,
          'normal_usage_gb': 140,
          'usage_window': 'day',
          'last_push_at': '2026-06-02T10:00:00Z',
          'has_override': true,
        }
      ],
      'loop_probes': [
        {
          'router_id': 17,
          'router_name': 'راوتر الفرع',
          'interface': 'ether2',
          'enabled': true,
          'status': 'bound',
          'lease_ip': '10.0.0.7/24',
          'server_ip': '10.0.0.1',
          'last_reading_at': '2026-06-02T10:01:00Z',
          'loop_detected': true,
        }
      ],
      'counts': {
        'routers': 1,
        'pushing': 1,
        'overrides': 1,
        'loop_probes': 1,
        'loop_detected': 1,
        'loop_routers': 1,
      },
      'usage_windows': [
        {'key': 'day', 'label': 'يومي'},
        {'key': 'month', 'label': 'شهري'},
      ],
    });

    expect(state.settings.defaultSpeedMbps, 120);
    expect(state.settings.loop, isTrue);
    expect(state.settings.usageWindow, 'month');
    expect(state.routers.single.name, 'راوتر الفرع');
    expect(state.routers.single.normalUsageGb, 140);
    expect(state.routers.single.hasOverride, isTrue);
    expect(state.counts.pushing, 1);
    expect(state.counts.loopDetected, 1);
    expect(state.loopProbes.single.interfaceName, 'ether2');
    expect(state.loopProbes.single.loopDetected, isTrue);
    expect(state.usageWindows.last.label, 'شهري');
  });
}
