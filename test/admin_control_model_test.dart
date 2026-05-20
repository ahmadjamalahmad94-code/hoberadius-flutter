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

  test('ApiTokenRecord keeps one-time secret only when backend returns it', () {
    final created = ApiTokenRecord.fromJson({
      'id': 1,
      'name': 'mobile',
      'scopes': ['admin:full'],
      'revoked': false,
      'token': 'hr_secret',
      'token_shown_once': true,
    });
    final listed = ApiTokenRecord.fromJson({
      'id': 1,
      'name': 'mobile',
      'scopes': ['admin:full'],
      'revoked': false,
    });

    expect(created.token, 'hr_secret');
    expect(created.tokenShownOnce, isTrue);
    expect(listed.token, isNull);
  });

  test('TenantRecord and WebhookDelivery parse API payloads', () {
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
    final delivery = WebhookDelivery.fromJson({
      'id': 9,
      'event': 'webhook.test',
      'event_id': 'evt-1',
      'status': 'queued',
      'attempts': '2',
      'last_status_code': 0,
    });

    expect(tenant.slug, 'client');
    expect(tenant.maxSubscribers, 2000);
    expect(tenant.toBody()['plan_tier'], 'pro');
    expect(delivery.attempts, 2);
    expect(delivery.status, 'queued');
  });

  test('WebhookConfig parses enabled events and secret status', () {
    final config = WebhookConfig.fromJson({
      'target_url': 'https://example.test/hook',
      'enabled_events': ['subscriber.created'],
      'secret_set': true,
    });

    expect(config.targetUrl, startsWith('https://'));
    expect(config.enabledEvents.single, 'subscriber.created');
    expect(config.secretSet, isTrue);
  });
}
