// Owner's dead-field decisions 2026-10-06 (team settings): removed fields are
// gone from the app forms and bodies, wired fields are effective, and message
// templates / campaigns say «معاينة فقط».
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/core/auth/route_permissions.dart';
import 'package:hoberadius_app/features/admin_control/domain/admin_control_model.dart';
import 'package:hoberadius_app/features/admins/domain/admin_model.dart';
import 'package:hoberadius_app/features/cards/domain/card_batch_operations.dart';
import 'package:hoberadius_app/features/cards/presentation/card_batch_form_screen.dart';
import 'package:hoberadius_app/features/communications/domain/communications_model.dart';
import 'package:hoberadius_app/features/communications/presentation/communications_screen.dart';
import 'package:hoberadius_app/features/nas/domain/nas_model.dart';
import 'package:hoberadius_app/features/payment_collection/domain/payment_collection_model.dart';
import 'package:hoberadius_app/features/radius_resources/application/radius_resources_providers.dart';
import 'package:hoberadius_app/features/radius_resources/domain/radius_resources_model.dart';
import 'package:hoberadius_app/features/router_alerts/domain/router_alerts_model.dart';
import 'package:hoberadius_app/features/saas_modules/application/saas_modules_catalog.dart';
import 'package:hoberadius_app/features/tools/presentation/widgets/tools_maintenance_panel.dart';

void main() {
  test('settings list hides the retired / web-hidden keys', () {
    final snap = SettingsSnapshot.fromJson({
      'items': [
        for (final k in [
          'system.name',
          'billing.tax_pct',
          'auth.allow_password_reset',
          'quota.threshold_alerts',
          'portal.allow_plan_change',
        ])
          {'key': k, 'label': k, 'value': '1', 'default': '0'},
      ],
      'settings': {'system.name': 'X', 'billing.tax_pct': '16'},
    });
    expect(snap.items.map((i) => i.key), ['system.name']);
    expect(snap.settings.keys, ['system.name']);
    expect(settingChoices('auth.allow_password_reset'), isNull);
  });

  test('admin save no longer sends avatar_url', () {
    final body = Admin(username: 'm', avatarUrl: 'https://x/a.png').toBody();
    expect(body.containsKey('avatar_url'), isFalse);
  });

  test('collection settings save no longer sends auto_apply', () {
    final s = PaymentCollectionSettings.fromJson({
      'settings': {'enabled': true, 'auto_apply': true},
    });
    expect(s.toApiJson().containsKey('auto_apply'), isFalse);
  });

  test(
      'channels: SMS is TweetSMS status only; WhatsApp body has no mode/balance',
      () {
    final page = CommunicationChannelPage.fromJson({
      'items': [
        {
          'channel': 'sms',
          'provider': 'tweetsms',
          'connected': true,
          'sender': 'HobeNet',
          'config': {},
        },
        {'channel': 'whatsapp', 'enabled': true, 'config': {}},
      ],
    });
    expect(page.items.first.isTweetSms, isTrue);
    expect(page.items.first.sender, 'HobeNet');
    expect(page.items.last.isTweetSms, isFalse);
    const draft = CommunicationChannelDraft(
      channel: 'whatsapp',
      enabled: true,
      sendUrlTemplate: 'https://gw/?to={phone}',
      httpMethod: 'get',
    );
    expect(
      draft.toBody().keys.toSet(),
      {'enabled', 'send_url_template', 'http_method'},
    );
  });

  test('WhatsApp quota / portal gates are hidden', () {
    final state = WhatsappBridgeState.fromJson({
      'events': [
        for (final k in ['otp', 'quota', 'portal', 'expiry'])
          {'key': k, 'label': k, 'enabled': false},
      ],
    });
    expect(state.events.map((e) => e.key), ['otp', 'expiry']);
  });

  test(
      'SaaS catalog: no pools page, voucher plan, rent, priority, share limits',
      () {
    expect(kSaasModules.containsKey('pools'), isFalse);
    Iterable<String> keys(String m) =>
        kSaasModules[m]!.fields.map((f) => f.key);
    expect(keys('vouchers'), isNot(contains('plan_id')));
    expect(keys('services'), isNot(contains('rent_per_month')));
    expect(keys('bandwidth'), isNot(contains('priority')));
    expect(keys('share-groups'), ['name']);
  });

  test('RADIUS resources: no pools tab; bodies drop removed fields', () {
    expect(
      RadiusResourcesTab.values.map((t) => t.name),
      ['shareGroups', 'bandwidthProfiles'],
    );
    const group = ShareGroupResource(
      id: 1,
      name: 'G',
      description: '',
      sharedQuotaMb: 10,
      sharedSpeedDownKbps: 10,
      sharedSpeedUpKbps: 10,
      maxMembers: 3,
      enabled: true,
      members: 0,
      createdAt: null,
    );
    expect(group.toBody().keys.toSet(), {'name', 'description', 'enabled'});
    const profile = BandwidthProfileResource(id: 1, name: 'P', priority: 4);
    expect(profile.toBody().containsKey('priority'), isFalse);
  });

  test('router form body drops the dead NAS fields', () {
    final body = NasDevice(name: 'r', address: '10.0.0.1').toBody();
    for (final k in [
      'auth_port',
      'acct_port',
      'snmp_community',
      'ports',
      'monitoring_enabled',
    ]) {
      expect(body.containsKey(k), isFalse, reason: k);
    }
    expect(body['coa_port'], 3799);
  });

  test('maintenance days only for actions with an age window', () {
    expect(maintenanceUsesDays('vacuum'), isFalse);
    expect(maintenanceUsesDays('purge_failed_webhooks'), isFalse);
    expect(maintenanceUsesDays('purge_audit'), isTrue);
  });

  test('legacy «اتصالات ميكروتك» route is gone', () {
    expect(kRouteRequirements.containsKey('/mikrotik'), isFalse);
  });

  test('router alert blanks say «يرث العامّ (X)»', () {
    final r = RouterAlertTarget.fromJson({
      'id': 3,
      'name': 'R',
      'normal_speed_mbps': 50,
      'normal_usage_gb': 300,
      'offline_after_min': 6,
      'usage_window': 'day',
      'override': {'normal_speed_mbps': 50},
      'inherited': {
        'offline_after_min': 6,
        'normal_speed_mbps': 300,
        'normal_usage_gb': 300,
        'usage_window': 'month',
      },
    });
    expect(inheritsGlobalLabel(r.inheritedSpeedMbps), 'يرث العامّ (300)');
    expect(
      inheritsGlobalLabel(usageWindowLabel(r.inheritedUsageWindow)),
      'يرث العامّ (شهري)',
    );
    // an older server (no «inherited»): the effective value of a blank limit
    final old = RouterAlertTarget.fromJson({
      'id': 3,
      'normal_usage_gb': 200,
      'override': {'normal_usage_gb': null},
    });
    expect(old.inheritedUsageGb, 200);
  });

  test('card generator starts from the network default lengths', () {
    final page = CardBatchOperationsPage.fromJson({
      'items': [],
      'meta': {
        'next_batch_id': 9,
        'card_defaults': {'username_length': 11, 'password_length': 4},
      },
    });
    expect(page.defaultUsernameLength, 11);
    expect(page.defaultPasswordLength, 4);
    expect(
      applyCardDefaultLengths(
        currentUsername: '8',
        currentPassword: '6',
        defaultUsername: 11,
        defaultPassword: 4,
      ),
      ('11', '4'),
    );
    // a box the operator already changed is kept
    expect(
      applyCardDefaultLengths(
        currentUsername: '10',
        currentPassword: '6',
        defaultUsername: 11,
        defaultPassword: null,
      ),
      ('10', '6'),
    );
  });

  testWidgets('templates / campaigns banner says «معاينة فقط»', (t) async {
    await t.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: PreviewOnlyBanner(message: 'لا مُرسِل بعد.')),
      ),
    );
    expect(find.textContaining('معاينة فقط'), findsOneWidget);
  });

  testWidgets('SMS card shows the TweetSMS status, no URL form', (t) async {
    final item = CommunicationChannel.fromJson({
      'channel': 'sms',
      'provider': 'tweetsms',
      'connected': false,
      'config': {},
    });
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(body: TweetSmsStatusCard(item: item)),
      ),
    );
    expect(find.text('غير مربوطة'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });
}
