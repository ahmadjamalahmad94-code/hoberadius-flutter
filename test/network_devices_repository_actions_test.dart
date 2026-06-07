import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/core/api/api_client.dart';
import 'package:hoberadius_app/core/api/api_endpoint_storage.dart';
import 'package:hoberadius_app/core/auth/token_storage.dart';
import 'package:hoberadius_app/features/network_devices/data/network_devices_repository.dart';

class _MemoryTokenStorage implements TokenStorage {
  String? token = 'token';

  @override
  Future<void> clear() async => token = null;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String token) async => this.token = token;
}

class _MemoryEndpointStorage implements ApiEndpointStorage {
  String baseUrl = 'http://127.0.0.1:5000';

  @override
  Future<String> readBaseUrl() async => baseUrl;

  @override
  Future<void> writeBaseUrl(String baseUrl) async => this.baseUrl = baseUrl;
}

class _CaptureAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final data = switch (options.path) {
      String path when path.endsWith('/scan') => {
          'router': {'id': 3, 'name': 'راوتر رئيسي', 'address': '10.0.0.1'},
          'known_ips': ['10.0.0.20'],
          'items': [
            {
              'ip': '10.0.0.50',
              'mac': 'aa:bb:cc:dd:ee:ff',
              'hostname': 'camera-entry',
              'interface': 'bridge-lan',
              'vendor': '',
              'sources': ['arp'],
              'known': false,
            },
          ],
        },
      String path when path.endsWith('/scan/add') => {
          'device': _device(),
        },
      String path when path.endsWith('/bypass') => {
          'device': _device(),
          'router': {'id': 3, 'name': 'راوتر رئيسي', 'address': '10.0.0.1'},
          'dhcp_servers': [
            {'name': 'dhcp-lan', 'interface': 'bridge-lan', 'disabled': false},
          ],
          'ready': true,
          'dhcp_error': '',
          'address_list_name': 'trusted-network-devices',
        },
      String path when path.endsWith('/bypass/apply') => {
          'message': 'تم تجهيز الجهاز على الراوتر.',
          'steps': {'dhcp_lease': 'created'},
        },
      String path when path.endsWith('/bypass/remove') => {
          'message': 'تمت إزالة 1 قاعدة من الراوتر.',
          'removed': {'dhcp_lease': 1},
          'total_removed': 1,
        },
      _ => {},
    };
    return ResponseBody.fromString(
      jsonEncode({'ok': true, 'data': data}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  Map<String, Object?> _device() => {
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
        'last_status': 'unknown',
        'last_status_label': 'غير مفحوص',
      };
}

void main() {
  test('NetworkDevicesRepository sends scan and bypass actions to API',
      () async {
    final client = ApiClient(_MemoryTokenStorage(), _MemoryEndpointStorage());
    final adapter = _CaptureAdapter();
    client.dio.httpClientAdapter = adapter;
    final repo = NetworkDevicesRepository(client);

    final scan = await repo.scanRouter(3);
    final added = await repo.addScannedDevice(
      routerId: 3,
      item: scan.items.single,
    );
    final state = await repo.bypassState(7);
    final applied = await repo.applyBypass(
      7,
      dhcpServerName: 'dhcp-lan',
      bypassHotspot: true,
      addToAddressList: true,
    );
    final removed = await repo.removeBypass(7);

    expect(scan.items.single.address, '10.0.0.50');
    expect(added.name, 'كاميرا المدخل');
    expect(state.dhcpServers.single.name, 'dhcp-lan');
    expect(applied.steps['dhcp_lease'], 'created');
    expect(removed.totalRemoved, 1);
    expect(
      adapter.requests.map((request) => '${request.method} ${request.path}'),
      [
        'POST /api/v1/network-devices/scan',
        'POST /api/v1/network-devices/scan/add',
        'GET /api/v1/network-devices/7/bypass',
        'POST /api/v1/network-devices/7/bypass/apply',
        'POST /api/v1/network-devices/7/bypass/remove',
      ],
    );
  });
}
