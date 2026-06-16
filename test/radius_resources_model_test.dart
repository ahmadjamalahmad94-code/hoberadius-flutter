import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/radius_resources/domain/radius_resources_model.dart';

void main() {
  test('IP pools parse backend payload and keep router binding optional', () {
    final pool = IpPoolResource.fromJson({
      'id': 7,
      'pool_name': 'Hotspot Pool',
      'range_ip': '10.10.0.10-10.10.0.250',
      'local_ip': '10.10.0.1',
      'router_id': null,
      'created_at': '2026-05-31T10:00:00',
    });

    expect(pool.id, 7);
    expect(pool.poolName, 'Hotspot Pool');
    expect(pool.routerId, isNull);
    expect(pool.toBody()['range_ip'], '10.10.0.10-10.10.0.250');
  });

  test('share groups parse limits and Arabic member status labels', () {
    final details = ShareGroupDetails.fromJson({
      'ok': true,
      'data': {
        'group': {
          'id': 3,
          'name': 'عائلة أحمد',
          'description': 'حصة مشتركة',
          'shared_quota_mb': 50000,
          'shared_speed_down_kbps': 10000,
          'shared_speed_up_kbps': 3000,
          'max_members': 5,
          'enabled': 1,
          'members': 2,
        },
        'members': [
          {
            'id': 11,
            'username': 'sub-11',
            'full_name': 'العميل الأول',
            'status': 'suspended',
          }
        ],
      },
    });

    expect(details.group.enabled, isTrue);
    expect(details.group.sharedQuotaMb, 50000);
    expect(details.members.single.displayName, 'العميل الأول');
    expect(details.members.single.statusLabel, 'موقوف');
  });

  test('unknown share group member status does not expose backend code', () {
    final member = ShareGroupMember.fromJson({
      'id': 5,
      'username': 'sub-5',
      'status': 'backend_future_status',
    });

    expect(member.statusLabel, 'حالة عضو غير معروفة');
  });

  test('snapshot exposes dashboard counters for side explanations', () {
    const snapshot = RadiusResourcesSnapshot(
      pools: [
        IpPoolResource(
          id: 1,
          poolName: 'Pool A',
          rangeIp: '10.0.0.1-10.0.0.20',
          localIp: '',
          routerId: 2,
          createdAt: null,
        ),
      ],
      shareGroups: [
        ShareGroupResource(
          id: 1,
          name: 'Group A',
          description: '',
          sharedQuotaMb: 0,
          sharedSpeedDownKbps: 0,
          sharedSpeedUpKbps: 0,
          maxMembers: 0,
          enabled: true,
          members: 0,
          createdAt: null,
        ),
      ],
    );

    expect(snapshot.assignedPoolRouters, 1);
    expect(snapshot.activeGroups, 1);
  });

  test('BandwidthProfileResource parses and serialises', () {
    final p = BandwidthProfileResource.fromJson({
      'id': 3,
      'name': 'Fiber-50',
      'rate_down': 50,
      'rate_down_unit': 'Mbps',
      'rate_up': 25,
      'rate_up_unit': 'Mbps',
      'burst': '60M/30M',
      'priority': 5,
    });
    expect(p.name, 'Fiber-50');
    expect(p.rateDown, 50);
    expect(p.rateDownUnit, 'Mbps');
    expect(p.rateUp, 25);
    expect(p.burst, '60M/30M');
    expect(p.priority, 5);
    expect(p.rateLabel, contains('50 Mbps'));

    final body = p.toBody();
    expect(body['name'], 'Fiber-50');
    expect(body['rate_down'], 50);
    expect(body['rate_down_unit'], 'Mbps');
    expect(body['rate_up'], 25);
    expect(body['burst'], '60M/30M');
    expect(body['priority'], 5);
  });
}
