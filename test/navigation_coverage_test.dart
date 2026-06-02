import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('operator navigation exposes critical production routes', () {
    final router = File('lib/core/router/app_router.dart').readAsStringSync();
    final shell =
        File('lib/features/shell/shell_scaffold.dart').readAsStringSync();
    final more =
        File('lib/features/more/presentation/more_screen.dart').readAsStringSync();
    final sidebar = File('lib/features/shell/sidebar.dart').readAsStringSync();
    final navigation = '$shell\n$more\n$sidebar';

    final criticalRoutes = {
      'license-file': '/license-file',
      'audit': '/audit',
      'payment-collection': '/payment-collection',
      'tickets': '/tickets',
      'customer-portals': '/customer-portals',
      'communications': '/communications',
      'events-center': '/events',
      'network-policy': '/network-policy',
      'network-devices': '/network-devices',
      'router-operations': '/router-operations',
      'setup-wizard': '/setup-wizard',
      'radius-resources': '/radius-resources',
      'card-users': '/card-users',
    };

    for (final entry in criticalRoutes.entries) {
      expect(router, contains("name: '${entry.key}'"));
      expect(router, contains("path: '${entry.value}'"));
      expect(
        navigation,
        contains("routeName: '${entry.key}'"),
        reason: 'المسار ${entry.key} موجود في الراوتر وغير ظاهر في التنقل',
      );
    }
  });
}
