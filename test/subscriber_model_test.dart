import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/subscribers/application/subscriber_form_mapper.dart';
import 'package:hoberadius_app/features/subscribers/domain/subscriber_model.dart';
import 'package:hoberadius_app/features/subscribers/presentation/widgets/subscriber_form_sections.dart';

// Full controller-key set mirrored from SubscriberFormScreen.
const _keys = [
  'username', 'password', 'full_name', 'mobile', 'email', 'beneficiary_ref',
  'remark', 'mac_lock', 'static_ip', 'plan_id', 'custom_price', 'balance',
  'group', 'pool', 'father_name', 'national_id', 'nationality', 'country',
  'address', 'city', 'district', 'state', 'zip', 'coordinates',
  'payment_method', 'payment_reference', 'download_speed_kbps',
  'upload_speed_kbps', 'combined_quota_mb', 'download_quota_mb',
  'upload_quota_mb', 'total_connection_time_min', 'daily_connection_time_min',
  'vlan_id', 'device_count', 'allowed_macs', 'device_connection_file',
  'pppoe_username', 'pppoe_password', 'pppoe_ip', 'mt_profile', 'mt_rate_limit',
  'mt_ip_pool', 'mt_comment', 'dns1', 'dns2', 'simultaneous_use',
  'session_timeout', 'idle_timeout', 'called_station_id', 'allowed_hours',
  'notify_email', 'notify_mobile', 'subscription_days', 'notes', 'tags',
];

Map<String, TextEditingController> _controllers() =>
    {for (final k in _keys) k: TextEditingController()};

SubscriberFormSelections _selections({
  String status = 'enabled',
  String serviceType = 'Hotspot',
  String accountType = 'Personal',
  int? managerId,
  bool bandwidthControlEnabled = false,
  bool customSpeed = false,
  bool temporarySpeed = false,
  bool quotaLimitEnabled = false,
  bool connectionTimeLimitEnabled = false,
  bool equalShareDownload = false,
  bool equalShareUpload = false,
}) =>
    SubscriberFormSelections(
      status: status,
      userType: 'subscriber',
      serviceType: serviceType,
      accountType: accountType,
      managerId: managerId,
      mtService: 'pppoe',
      expireAt: null,
      workingDays: const {},
      autoRenew: true,
      bandwidthControlEnabled: bandwidthControlEnabled,
      customSpeed: customSpeed,
      temporarySpeed: temporarySpeed,
      quotaLimitEnabled: quotaLimitEnabled,
      connectionTimeLimitEnabled: connectionTimeLimitEnabled,
      equalShareDownload: equalShareDownload,
      equalShareUpload: equalShareUpload,
    );

void main() {
  test('subscriber model parses and sends custom price', () {
    final subscriber = Subscriber.fromJson({
      'id': 7,
      'username': 'custom-price-user',
      'plan_id': 3,
      'custom_price': '120.50',
      'status': 'enabled',
    });
    expect(subscriber.customPrice, 120.5);
    expect(subscriber.toPatchBody()['custom_price'], 120.5);
  });

  test('subscriber form maps empty custom price to fallback', () {
    final c = _controllers();
    addTearDown(() {
      for (final v in c.values) {
        v.dispose();
      }
    });
    c['username']!.text = 'fallback-user';
    c['plan_id']!.text = '2';
    c['custom_price']!.text = '';
    final subscriber = buildSubscriberFromForm(c, _selections());
    expect(subscriber.customPrice, 0);
    expect(subscriber.toCreateBody()['custom_price'], 0);
  });

  test('fromJson reads the full _EDITABLE field surface', () {
    final s = Subscriber.fromJson({
      'username': 'parity',
      'service_type': 'PPPoE',
      'account_type': 'Business',
      'manager_id': 4,
      'group': 'vip',
      'pool': 'pool-a',
      'balance': '15.5',
      'father_name': 'أحمد',
      'national_id': '99887766',
      'nationality': 'JO',
      'country': 'الأردن',
      'city': 'عمّان',
      'district': 'تلاع العلي',
      'address': 'شارع المدينة',
      'state': 'العاصمة',
      'zip': '11183',
      'coordinates': '31.9,35.9',
      'payment_method': 'cash',
      'payment_reference': 'REF-1',
      'bandwidth_control_enabled': true,
      'download_speed_kbps': 5000,
      'upload_speed_kbps': 2000,
      'custom_speed': true,
      'temporary_speed': true,
      'combined_quota_mb': 10240,
      'download_quota_mb': 8000,
      'upload_quota_mb': 2000,
      'total_connection_time_min': 600,
      'daily_connection_time_min': 120,
      'quota_limit_enabled': true,
      'connection_time_limit_enabled': true,
      'equal_share_download': true,
      'equal_share_upload': true,
      'vlan_id': 30,
      'device_count': 3,
      'allowed_macs': 'AA:BB,CC:DD',
      'device_connection_file': 'cfg.ovpn',
      'pppoe_username': 'p-user',
      'pppoe_ip': '10.0.0.5',
    });

    expect(s.serviceType, 'PPPoE');
    expect(s.accountType, 'Business');
    expect(s.managerId, 4);
    expect(s.group, 'vip');
    expect(s.pool, 'pool-a');
    expect(s.balance, 15.5);
    expect(s.fatherName, 'أحمد');
    expect(s.nationalId, '99887766');
    expect(s.bandwidthControlEnabled, isTrue);
    expect(s.downloadSpeedKbps, 5000);
    expect(s.customSpeed, isTrue);
    expect(s.temporarySpeed, isTrue);
    expect(s.combinedQuotaMb, 10240);
    expect(s.totalConnectionTimeMin, 600);
    expect(s.quotaLimitEnabled, isTrue);
    expect(s.equalShareUpload, isTrue);
    expect(s.vlanId, 30);
    expect(s.deviceCount, 3);
    expect(s.allowedMacs, 'AA:BB,CC:DD');
    expect(s.pppoeUsername, 'p-user');
  });

  test('form build sends every new API-whitelisted field on the wire', () {
    final c = _controllers();
    addTearDown(() {
      for (final v in c.values) {
        v.dispose();
      }
    });
    c['username']!.text = 'wire';
    c['balance']!.text = '20';
    c['group']!.text = 'g1';
    c['pool']!.text = 'p1';
    c['father_name']!.text = 'father';
    c['national_id']!.text = '123';
    c['country']!.text = 'JO';
    c['city']!.text = 'Amman';
    c['download_speed_kbps']!.text = '4000';
    c['upload_speed_kbps']!.text = '1000';
    c['combined_quota_mb']!.text = '5120';
    c['total_connection_time_min']!.text = '300';
    c['daily_connection_time_min']!.text = '60';
    c['vlan_id']!.text = '10';
    c['device_count']!.text = '2';
    c['allowed_macs']!.text = 'AA:BB';
    c['pppoe_username']!.text = 'pu';
    c['pppoe_password']!.text = 'pp';
    c['pppoe_ip']!.text = '10.0.0.1';

    final body = buildSubscriberFromForm(
      c,
      _selections(
        serviceType: 'PPPoE',
        accountType: 'Business',
        managerId: 9,
        bandwidthControlEnabled: true,
        customSpeed: true,
        temporarySpeed: true,
        quotaLimitEnabled: true,
        connectionTimeLimitEnabled: true,
        equalShareDownload: true,
        equalShareUpload: true,
      ),
    ).toCreateBody();

    expect(body['service_type'], 'PPPoE');
    expect(body['account_type'], 'Business');
    expect(body['manager_id'], 9);
    // fix2: the create body never carries a balance (403 for a restricted
    // manager; money goes through «إضافة رصيد»).
    expect(body.containsKey('balance'), isFalse);
    expect(body['group'], 'g1');
    // retired (owner 2026-10-06): never sent, the server keeps stored values
    for (final k in [
      'pool',
      'vlan_id',
      'device_connection_file',
      'pppoe_username',
      'pppoe_password',
    ]) {
      expect(body.containsKey(k), isFalse, reason: k);
    }
    expect(body['father_name'], 'father');
    expect(body['national_id'], '123');
    expect(body['country'], 'JO');
    expect(body['city'], 'Amman');
    expect(body['bandwidth_control_enabled'], true);
    expect(body['download_speed_kbps'], 4000);
    expect(body['upload_speed_kbps'], 1000);
    expect(body['custom_speed'], true);
    expect(body['temporary_speed'], true);
    expect(body['combined_quota_mb'], 5120);
    expect(body['total_connection_time_min'], 300);
    expect(body['daily_connection_time_min'], 60);
    expect(body['quota_limit_enabled'], true);
    expect(body['connection_time_limit_enabled'], true);
    expect(body['equal_share_download'], true);
    expect(body['equal_share_upload'], true);
    expect(body['device_count'], 2);
    expect(body['allowed_macs'], 'AA:BB');
    expect(body['pppoe_ip'], '10.0.0.1');
  });

  test('retired metadata is never sent; stored values survive a PATCH', () {
    final row = Subscriber.fromJson({
      'username': 'meta',
      'metadata': {
        'mikrotik': {'profile': 'p1', 'rate_limit': '5M/5M', 'service': 'pppoe'},
        'radius': {'session_timeout': 3600, 'called_station_id': 'ap1'},
        'advanced': {'disable_on_first_use': true},
        'notifications': {'on_login': true, 'email': 'a@b.co'},
        'subscription': {'type': 'rolling', 'days': 30},
        'general': {
          'notes': 'n',
          'tags': ['a'],
        },
      },
    });
    final create = row.toCreateBody()['metadata'] as Map<String, dynamic>;
    expect(create.containsKey('notifications'), isFalse);
    expect(create.containsKey('subscription'), isFalse);
    expect((create['mikrotik'] as Map).containsKey('profile'), isFalse);
    expect((create['radius'] as Map).containsKey('session_timeout'), isFalse);
    expect(
      (create['advanced'] as Map).containsKey('disable_on_first_use'),
      isFalse,
    );
    // notes/tags are kept (owner: KEEP)
    expect(create['general'], {
      'notes': 'n',
      'tags': ['a'],
    });
    final diff = row.copyWith(notes: 'n2').toPatchDiff(row);
    final meta = diff['metadata'] as Map<String, dynamic>;
    expect(meta['general']['notes'], 'n2');
    // merged into the loaded metadata — the stored retired values ride along
    expect(meta['radius']['session_timeout'], 3600);
    expect(meta['notifications'], {'on_login': true, 'email': 'a@b.co'});
  });

  test('PPPoE IP: empty or IPv4 only (Framed-IP-Address)', () {
    expect(validatePppoeIp(''), isNull);
    expect(validatePppoeIp('10.0.0.5'), isNull);
    expect(validatePppoeIp('999.1.1.1'), isNotNull);
    expect(validatePppoeIp('2001:db8::1'), isNotNull);
    expect(validatePppoeIp('10.0.0'), isNotNull);
  });
}
