import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/admin_control/domain/admin_control_model.dart';

void main() {
  test('SettingsSnapshot parses settings catalog', () {
    final snapshot = SettingsSnapshot.fromJson({
      'items': [
        {
          'key': 'billing.currency',
          'label': 'العملة',
          'value': 'JOD',
          'default': 'JOD',
        },
      ],
      'settings': {'billing.currency': 'JOD'},
    });

    expect(snapshot.items.single.key, 'billing.currency');
    expect(snapshot.items.single.value, 'JOD');
    expect(snapshot.settings['billing.currency'], 'JOD');
  });

  test('TenantRecord parses API payloads', () {
    final tenant = TenantRecord.fromJson({
      'id': 2,
      'slug': 'client',
      'name': 'Client',
      'display_name': 'Client ISP',
      'status': 'active',
      'plan_tier': 'pro',
      'max_subscribers': '2000',
      'max_nas': 3,
      'api_rpm': 0,
    });

    expect(tenant.slug, 'client');
    expect(tenant.maxSubscribers, 2000);
    expect(tenant.toBody()['plan_tier'], 'pro');
  });
}
