import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/dashboard/domain/dashboard_model.dart';

void main() {
  test('DashboardMetrics parses nested backend counters', () {
    final metrics = DashboardMetrics.fromJson({
      'subscribers': {'total': 120, 'active': 99, 'online': 14},
      'cards': {'total': 5000, 'used': 331, 'available': 4669, 'batches': 9},
      'plans': {'total': 7, 'enabled': 6},
      'nas': {'total': 4, 'enabled': 3},
      'system': {
        'cpu_pct': 11.5,
        'ram_pct': 44,
        'disk_pct': 62,
        'hostname': 'vps-1',
        'system_uptime': '9ي 1س',
        'process_uptime': '3س',
        'network': {'ping_ok': true, 'ping_ms': 18.2, 'dns_ok': true},
      },
    });

    expect(metrics.subscribers, 120);
    expect(metrics.activeSubscribers, 99);
    expect(metrics.onlineNow, 14);
    expect(metrics.totalCards, 5000);
    expect(metrics.usedCards, 331);
    expect(metrics.availableCards, 4669);
    expect(metrics.totalBatches, 9);
    expect(metrics.plans, 7);
    expect(metrics.nasDevices, 4);
    expect(metrics.cpuPct, 11.5);
    expect(metrics.hostname, 'vps-1');
    expect(metrics.systemUptime, '9ي 1س');
    expect(metrics.pingOk, isTrue);
    expect(metrics.pingMs, 18.2);
  });

  test('DashboardMetrics keeps flat response compatibility', () {
    final metrics = DashboardMetrics.fromJson({
      'subscribers': 3,
      'active_subscribers': 2,
      'online_now': 1,
      'plans': 4,
      'total_cards': 50,
      'used_cards': 8,
      'total_batches': 2,
      'nas_devices': 1,
    });

    expect(metrics.subscribers, 3);
    expect(metrics.activeSubscribers, 2);
    expect(metrics.onlineNow, 1);
    expect(metrics.plans, 4);
    expect(metrics.totalCards, 50);
    expect(metrics.usedCards, 8);
    expect(metrics.totalBatches, 2);
    expect(metrics.nasDevices, 1);
  });

  test('DashboardMetrics reads stable API counter aliases', () {
    final metrics = DashboardMetrics.fromJson({
      'total_subscribers': 44,
      'active_subscribers': 40,
      'online_now': 6,
      'plans_total': 5,
      'total_cards': 900,
      'used_cards': 88,
      'available_cards': 812,
      'total_batches': 11,
      'nas_devices': 3,
    });

    expect(metrics.subscribers, 44);
    expect(metrics.activeSubscribers, 40);
    expect(metrics.onlineNow, 6);
    expect(metrics.plans, 5);
    expect(metrics.totalCards, 900);
    expect(metrics.usedCards, 88);
    expect(metrics.availableCards, 812);
    expect(metrics.totalBatches, 11);
    expect(metrics.nasDevices, 3);
  });

  // --- P0 truth-up: alerts[] + recent_batches were previously dropped. ---

  test('DashboardMetrics parses recent_batches (was read under wrong key)', () {
    final metrics = DashboardMetrics.fromJson({
      'recent_batches': [
        {
          'id': 42,
          'batch_code': 'B-0042',
          'package_name': 'باقة 10 جيجا',
          'count': 100,
          'generated': 100,
          'used': 37,
        },
        {
          'id': 41,
          'batch_code': 'B-0041',
          'package_name': '',
          'count': 0,
          'generated': 50,
          'used': 0,
        },
      ],
    });

    expect(metrics.recentBatches, hasLength(2));
    final first = metrics.recentBatches.first;
    expect(first.id, 42);
    expect(first.batchCode, 'B-0042');
    expect(first.packageName, 'باقة 10 جيجا');
    expect(first.used, 37);
    expect(first.total, 100); // count
    // count==0 → falls back to generated, mirroring the web template.
    expect(metrics.recentBatches[1].total, 50);
  });

  test('DashboardMetrics parses alerts with level/message/link', () {
    final metrics = DashboardMetrics.fromJson({
      'alerts': [
        {
          'level': 'warn',
          'link_endpoint': 'radius.users_list',
          'link_args': {'attention': 'expiring_3d'},
          'message': '5 مشترك ينتهي اشتراكهم خلال 3 أيام.',
        },
        {
          'level': 'danger',
          'link_endpoint': 'radius.cards_generate',
          'message': 'لا توجد كروت متاحة — وَلِّد دفعة جديدة.',
        },
        {
          'level': 'info',
          'message': 'لا توجد باقات بعد — أنشئ أول باقة.',
        },
      ],
    });

    expect(metrics.alerts, hasLength(3));
    expect(metrics.alerts[0].level, DashboardAlertLevel.warn);
    expect(metrics.alerts[0].linkEndpoint, 'radius.users_list');
    expect(metrics.alerts[0].linkArgs['attention'], 'expiring_3d');
    expect(metrics.alerts[1].level, DashboardAlertLevel.danger);
    expect(metrics.alerts[2].level, DashboardAlertLevel.info);
    expect(metrics.alerts[2].linkEndpoint, '');
  });

  test('DashboardMetrics parses subscriber attention counters + top plan', () {
    final metrics = DashboardMetrics.fromJson({
      'subscribers': {
        'total': 200,
        'active': 150,
        'online': 20,
        'expired': 12,
        'expiring_soon': 5,
        'suspended': 3,
        'disabled': 8,
        'banned': 1,
      },
      'plans': {
        'total': 9,
        'enabled': 7,
        'disabled': 2,
        'top': {'id': 3, 'name': 'باقة الذهبية', 'subs': 64},
      },
      'system': {'db_ok': true, 'radius_ok': false},
    });

    expect(metrics.expiredSubscribers, 12);
    expect(metrics.expiringSoon, 5);
    expect(metrics.suspendedSubscribers, 3);
    expect(metrics.disabledSubscribers, 8);
    expect(metrics.bannedSubscribers, 1);
    expect(metrics.enabledPlans, 7);
    expect(metrics.disabledPlans, 2);
    expect(metrics.hasTopPlan, isTrue);
    expect(metrics.topPlanName, 'باقة الذهبية');
    expect(metrics.topPlanSubs, 64);
    expect(metrics.dbOk, isTrue);
    expect(metrics.radiusOk, isFalse);
  });

  test('DashboardMetrics defaults are empty/safe when keys absent', () {
    final metrics = DashboardMetrics.fromJson({});
    expect(metrics.recentBatches, isEmpty);
    expect(metrics.alerts, isEmpty);
    expect(metrics.hasTopPlan, isFalse);
    expect(metrics.dbOk, isNull);
    expect(metrics.radiusOk, isNull);
  });
}
