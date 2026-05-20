import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/dashboard/domain/dashboard_model.dart';

void main() {
  test('DashboardMetrics parses nested backend counters', () {
    final metrics = DashboardMetrics.fromJson({
      'subscribers': {'total': 120, 'active': 99, 'online': 14},
      'cards': {'total': 5000, 'used': 331, 'batches': 9},
      'plans': {'total': 7, 'enabled': 6},
      'nas': {'total': 4, 'enabled': 3},
      'system': {'cpu_pct': 11.5, 'ram_pct': 44, 'disk_pct': 62},
      'recent': [
        {
          'action': 'payment.create',
          'target_type': 'subscriber',
          'actor': 'admin',
        },
      ],
    });

    expect(metrics.subscribers, 120);
    expect(metrics.activeSubscribers, 99);
    expect(metrics.onlineNow, 14);
    expect(metrics.totalCards, 5000);
    expect(metrics.usedCards, 331);
    expect(metrics.totalBatches, 9);
    expect(metrics.plans, 7);
    expect(metrics.nasDevices, 4);
    expect(metrics.cpuPct, 11.5);
    expect(metrics.recentEvents, hasLength(1));
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
      'total_batches': 11,
      'nas_devices': 3,
    });

    expect(metrics.subscribers, 44);
    expect(metrics.activeSubscribers, 40);
    expect(metrics.onlineNow, 6);
    expect(metrics.plans, 5);
    expect(metrics.totalCards, 900);
    expect(metrics.usedCards, 88);
    expect(metrics.totalBatches, 11);
    expect(metrics.nasDevices, 3);
  });
}
