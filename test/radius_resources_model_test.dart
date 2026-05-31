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
}
