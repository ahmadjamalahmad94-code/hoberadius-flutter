import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/device_fingerprints/domain/device_fingerprint_model.dart';

void main() {
  test('DeviceFingerprint parses backend row and labels device safely', () {
    final item = DeviceFingerprint.fromJson({
      'id': 9,
      'mac': 'aa:bb:cc:dd:ee:ff',
      'hostname': 'Redmi-Note-12-Pro',
      'dhcp_class_id': 'android-dhcp-11',
      'os_family': 'android',
      'os_version': '11',
      'device_brand': 'xiaomi',
      'device_model': 'Redmi Note 12 Pro',
      'ip_address': '10.20.30.40',
      'nas_id': '2',
      'first_seen_at': '2026-05-20T10:00:00Z',
      'last_seen_at': '2026-05-20T12:00:00Z',
    });

    expect(item.id, 9);
    expect(item.title, 'Redmi-Note-12-Pro');
    expect(item.osLabel, 'Android 11');
    expect(item.deviceLabel, 'xiaomi Redmi Note 12 Pro');
    expect(item.nasId, 2);
    expect(item.matches('note'), isTrue);
    expect(item.matches('windows'), isFalse);
  });

  test('DeviceFingerprintsPage parses list and counters', () {
    final page = DeviceFingerprintsPage.fromJson({
      'items': [
        {'id': 1, 'mac': 'aa', 'os_family': 'ios'},
      ],
      'count': 1,
      'total': '7',
      'limit': 200,
      'offset': 0,
    });

    expect(page.items.single.osLabel, 'iOS');
    expect(page.count, 1);
    expect(page.total, 7);
  });

  test('DeviceSyncResult accepts count or list response', () {
    expect(DeviceSyncResult.fromJson({'macs_seen': 5}).macsSeen, 5);
    expect(
      DeviceSyncResult.fromJson({
        'macs_seen': ['aa', 'bb'],
      }).macsSeen,
      2,
    );
  });
}
