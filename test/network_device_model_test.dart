import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/network_devices/domain/network_device_model.dart';

void main() {
  test('NetworkDevicesState parses registry contract', () {
    final state = NetworkDevicesState.fromJson({
      'items': [
        {
          'id': 7,
          'router_id': 3,
          'router_name': 'راوتر رئيسي',
          'router_address': '10.0.0.1',
          'name': 'كاميرا المدخل',
          'device_type': 'camera',
          'device_type_label': 'كاميرا',
          'ip_address': '10.0.0.50',
          'mac_address': 'aa:bb:cc:dd:ee:ff',
          'location': 'المدخل',
          'management_port': 80,
          'is_critical': true,
          'watch_enabled': true,
          'alert_enabled': false,
          'last_status': 'down',
          'last_status_label': 'لا يستجيب',
          'last_latency_ms': null,
        },
      ],
      'summary': {
        'total': 1,
        'up': 0,
        'down': 1,
        'unknown': 0,
        'watched': 1,
        'critical': 1,
        'alerts': 0,
      },
      'routers': [
        {'id': 3, 'name': 'راوتر رئيسي', 'address': '10.0.0.1'},
      ],
    });

    expect(state.items.single.name, 'كاميرا المدخل');
    expect(state.items.single.deviceTypeLabel, 'كاميرا');
    expect(state.items.single.isCritical, isTrue);
    expect(state.items.single.matches('المدخل'), isTrue);
    expect(state.summary.down, 1);
    expect(state.routers.single.name, 'راوتر رئيسي');
  });

  test('NetworkDeviceDraft serializes editable fields', () {
    const draft = NetworkDeviceDraft(
      routerId: 3,
      name: 'سويتش الطابق الأول',
      deviceType: 'switch',
      address: '10.0.0.20',
      physicalAddress: '',
      location: 'الطابق الأول',
      managementPort: 443,
      notes: 'إدارة داخلية',
      isCritical: false,
      watchEnabled: true,
      alertEnabled: true,
    );

    final body = draft.toBody();
    expect(body['router_id'], 3);
    expect(body['device_type'], 'switch');
    expect(body['management_port'], 443);
    expect(body['watch_enabled'], isTrue);
  });
}
