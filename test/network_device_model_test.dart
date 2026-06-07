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

  test('NetworkScanResult parses discovered network devices', () {
    final result = NetworkScanResult.fromJson({
      'router': {'id': 3, 'name': 'راوتر رئيسي', 'address': '10.0.0.1'},
      'known_ips': ['10.0.0.20'],
      'items': [
        {
          'ip': '10.0.0.50',
          'mac': 'aa:bb:cc:dd:ee:ff',
          'hostname': 'camera-entry',
          'interface': 'bridge-lan',
          'vendor': 'Camera Vendor',
          'sources': ['arp', 'dhcp'],
          'known': false,
        },
      ],
    });

    expect(result.router.name, 'راوتر رئيسي');
    expect(result.knownIps, ['10.0.0.20']);
    expect(result.items.single.displayName, 'camera-entry');
    expect(result.items.single.sources, ['arp', 'dhcp']);
    expect(result.items.single.known, isFalse);
  });

  test('NetworkDeviceBypassState parses DHCP and bypass contracts', () {
    final state = NetworkDeviceBypassState.fromJson({
      'device': {
        'id': 7,
        'router_id': 3,
        'router_name': 'راوتر رئيسي',
        'router_address': '10.0.0.1',
        'name': 'كاميرا المدخل',
        'device_type': 'camera',
        'device_type_label': 'كاميرا',
        'ip_address': '10.0.0.50',
        'mac_address': 'aa:bb:cc:dd:ee:ff',
        'management_port': 80,
      },
      'router': {'id': 3, 'name': 'راوتر رئيسي', 'address': '10.0.0.1'},
      'dhcp_servers': [
        {'name': 'dhcp-lan', 'interface': 'bridge-lan', 'disabled': false},
      ],
      'ready': true,
      'dhcp_error': '',
      'address_list_name': 'trusted-network-devices',
    });

    expect(state.ready, isTrue);
    expect(state.device.address, '10.0.0.50');
    expect(state.dhcpServers.single.name, 'dhcp-lan');
    expect(state.addressListName, 'trusted-network-devices');

    final applied = NetworkDeviceBypassResult.fromJson({
      'message': 'تم تجهيز الجهاز على الراوتر.',
      'steps': {'dhcp_lease': 'created', 'ip_binding': 'created'},
    });
    expect(applied.steps['ip_binding'], 'created');

    final removed = NetworkDeviceBypassRemoveResult.fromJson({
      'message': 'تمت إزالة 2 قاعدة من الراوتر.',
      'removed': {'dhcp_lease': 1, 'ip_binding': 1},
      'total_removed': 2,
    });
    expect(removed.totalRemoved, 2);
    expect(removed.removed['dhcp_lease'], 1);
  });

  test('NetworkRemoteAccessState parses temporary access sessions', () {
    final state = NetworkRemoteAccessState.fromJson({
      'device': {
        'id': 7,
        'router_id': 3,
        'router_name': 'راوتر رئيسي',
        'router_address': '10.0.0.1',
        'name': 'كاميرا المدخل',
        'device_type': 'camera',
        'device_type_label': 'كاميرا',
        'ip_address': '10.0.0.50',
        'management_port': 80,
      },
      'router': {'id': 3, 'name': 'راوتر رئيسي', 'address': '10.0.0.1'},
      'public_host': '203.0.113.10',
      'config_ready': true,
      'allowed_protocols': [
        {'key': 'http', 'label': 'واجهة الويب العادية'},
      ],
      'ttl_options': [
        {'minutes': 30, 'label': '30 دقيقة'},
      ],
      'sessions': [
        {
          'id': 44,
          'device_id': 7,
          'router_id': 3,
          'requested_by': 'admin:1',
          'protocol': 'http',
          'protocol_label': 'واجهة الويب العادية',
          'internal_ip': '10.0.0.50',
          'internal_port': 80,
          'external_port': 40044,
          'public_endpoint': '203.0.113.10:40044',
          'public_url': 'http://203.0.113.10:40044/',
          'status': 'active',
          'status_label': 'نشطة',
          'created_at': '2026-06-07T12:00:00Z',
          'expires_at': '2026-06-07T12:30:00Z',
          'notes': 'صيانة',
        },
      ],
      'active_sessions': [
        {
          'id': 44,
          'device_id': 7,
          'router_id': 3,
          'protocol': 'http',
          'external_port': 40044,
          'public_url': 'http://203.0.113.10:40044/',
          'status': 'active',
          'status_label': 'نشطة',
        },
      ],
    });

    expect(state.configReady, isTrue);
    expect(state.allowedProtocols.single.key, 'http');
    expect(state.ttlOptions.single.minutes, 30);
    expect(state.sessions.single.active, isTrue);
    expect(state.sessions.single.bestAccessText, 'http://203.0.113.10:40044/');
    expect(state.activeSessions.single.id, 44);
  });
}
