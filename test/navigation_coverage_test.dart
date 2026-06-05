import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/shell/navigation_schema.dart';

void main() {
  test('operator navigation exposes critical production routes', () {
    final router = File('lib/core/router/app_router.dart').readAsStringSync();
    final shell =
        File('lib/features/shell/shell_scaffold.dart').readAsStringSync();
    final more = File('lib/features/more/presentation/more_screen.dart')
        .readAsStringSync();
    final sidebar = File('lib/features/shell/sidebar.dart').readAsStringSync();
    final navigation = '$shell\n$more\n$sidebar';
    final schemaByRoute = {
      for (final item in appNavigationItems) item.routeName: item,
    };

    final criticalRoutes = {
      'account': '/account',
      'license-file': '/license-file',
      'audit': '/audit',
      'payment-collection': '/payment-collection',
      'invoices': '/invoices',
      'vouchers': '/vouchers',
      'wallets': '/wallets',
      'loans-center': '/loans',
      'revenue': '/revenue',
      'tickets': '/tickets',
      'customer-portals': '/customer-portals',
      'communications': '/communications',
      'events-center': '/events',
      'network-policy': '/network-policy',
      'network-devices': '/network-devices',
      'router-alerts': '/router-alerts',
      'router-operations': '/router-operations',
      'setup-wizard': '/setup-wizard',
      'radius-resources': '/radius-resources',
      'card-users': '/card-users',
      'cards-recharge': '/cards/recharge',
    };

    for (final entry in criticalRoutes.entries) {
      expect(router, contains("name: '${entry.key}'"));
      expect(router, contains("path: '${entry.value}'"));
      expect(
        schemaByRoute[entry.key]?.path,
        entry.value,
        reason: 'المسار ${entry.key} يجب أن يظهر في مصدر التنقل الموحد',
      );
      expect(
        navigation,
        contains("routeName: '${entry.key}'"),
        reason: 'المسار ${entry.key} موجود في الراوتر وغير ظاهر في التنقل',
      );
    }

    expect(router, contains("name: 'payment-request-detail'"));
    expect(router, contains("path: ':id'"));
  });

  test('navigation schema uses canonical Arabic labels', () {
    expect(dashboardNavItem.label, 'لوحة التحكم');
    expect(
      mobileNavDestinations.map((item) => item.label),
      contains('البطاقات'),
    );
    expect(
      appNavSections.map((section) => section.label),
      contains('التكامل والجسر'),
    );
    expect(
      appNavSections.map((section) => section.label),
      contains('التحصيل والمحاسبة'),
    );
    expect(
      appNavigationItems.map((item) => item.label),
      isNot(contains('الكروت')),
    );
    expect(
      mobileNavDestinations.map((item) => item.label),
      isNot(contains('الرئيسية')),
    );
  });
}
