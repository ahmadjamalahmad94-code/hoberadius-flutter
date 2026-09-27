import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/shell/navigation_schema.dart';

void main() {
  test('operator navigation exposes critical production routes', () {
    final router = File('lib/core/router/app_router.dart').readAsStringSync();
    final shell =
        File('lib/features/shell/shell_scaffold.dart').readAsStringSync();
    final schema =
        File('lib/features/shell/navigation_schema.dart').readAsStringSync();
    final more = File('lib/features/more/presentation/more_screen.dart')
        .readAsStringSync();
    // The persistent sidebar is the web-style _WebSidebar inside
    // shell_scaffold, driven by navigation_schema (the legacy standalone
    // sidebar.dart was removed). Route coverage is asserted against the
    // unified schema + shell + more sources.
    final navigation = '$schema\n$shell\n$more';
    final schemaByRoute = {
      for (final item in appNavigationItems) item.routeName: item,
    };

    final criticalRoutes = {
      'account': '/account',
      'payment-collection': '/payment-collection',
      'loans-center': '/loans',
      'revenue': '/revenue',
      'tickets': '/tickets',
      'events-center': '/events',
      // network-devices is intentionally NOT a sidebar item — mirrors the web,
      // where the entry is hidden "until next release" (route stays alive).
      'router-operations': '/router-operations',
      'card-users': '/card-users',
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

    // Web-only pages: hidden from the menu but the routes stay alive
    // (deep links from notifications keep working).
    for (final path in kWebOnlyPaths) {
      expect(
        router,
        anyOf(
          contains("path: '$path'"),
          contains("path: '${path.split('/').last}'"),
        ),
      );
      expect(
        appNavigationItems.map((i) => i.path),
        isNot(contains(path)),
        reason: '$path is web-only and must not be in the app menu',
      );
    }

    expect(router, contains("name: 'payment-request-detail'"));
    expect(router, contains("path: ':id'"));
  });

  test('network-policy is merged into the router dashboard, not a nav item',
      () {
    // مطابقةً للويب (commit 80e9483 «Move NPC into MikroTik router dashboard»):
    // «سياسات الشبكة» لم تعد بندًا مستقلًا في التنقل — تُفتح من «عمليات الراوتر».
    final router = File('lib/core/router/app_router.dart').readAsStringSync();
    final schema =
        File('lib/features/shell/navigation_schema.dart').readAsStringSync();
    final routerOps = File(
      'lib/features/mikrotik/presentation/router_operations_screen.dart',
    ).readAsStringSync();

    // The route stays registered so it remains reachable for deep links.
    expect(router, contains("name: 'network-policy'"));
    expect(router, contains("path: '/network-policy'"));
    // …but it is no longer a standalone navigation entry.
    expect(
      appNavigationItems.map((item) => item.routeName),
      isNot(contains('network-policy')),
    );
    expect(schema, isNot(contains("routeName: 'network-policy'")));
    // It is surfaced from the router operations (dashboard) screen instead.
    expect(routerOps, contains("context.go('/network-policy')"));
    expect(routerOps, contains('سياسات الشبكة'));
  });

  test('customer portals are not offered on the operator login screen', () {
    // Owner decision 2026-09-27: the card-store and subscriber portals are for
    // customers (they have their own web pages); the admin app's login screen
    // no longer links to them. The routes themselves stay registered.
    final router = File('lib/core/router/app_router.dart').readAsStringSync();
    final login = File('lib/features/auth/presentation/login_screen.dart')
        .readAsStringSync();

    expect(router, contains("path: '/hotspot-cards'"));
    expect(router, contains("path: '/subscriber-portal'"));
    expect(login, isNot(contains("'hotspot-cards-portal'")));
    expect(login, isNot(contains("'subscriber-portal'")));
    expect(login, isNot(contains('بوابة شراء الكروت')));
    expect(login, isNot(contains('بوابة المشترك')));
  });

  test('shell scaffold uses the shared navigation schema', () {
    final shell =
        File('lib/features/shell/shell_scaffold.dart').readAsStringSync();

    expect(shell, contains("import 'navigation_schema.dart';"));
    expect(shell, isNot(contains('class _NavDest')));
    expect(shell, isNot(contains('class _SidebarItem')));
    expect(shell, isNot(contains('class _SidebarSection {')));
    expect(shell, isNot(contains('const _destinations')));
    expect(shell, isNot(contains('const _dashboardSidebarItem')));
    expect(shell, isNot(contains('const _sidebarSections')));
    expect(shell, isNot(contains("location == '/nas'")));
    expect(shell, isNot(contains("location == '/license-file'")));
    expect(shell, contains('mobileNavDestinations'));
    // The sidebar renders the shared schema filtered by provider grants and
    // by usage (visibleNavSectionsProvider builds on gatedNavSectionsProvider,
    // which derives from appNavSections); no direct const-list reference.
    expect(shell, contains('visibleNavSectionsProvider'));
    final visible = File('lib/features/shell/visible_nav_sections.dart')
        .readAsStringSync();
    expect(visible, contains('gatedNavSectionsProvider'));
    // The phone «المزيد» screen must use the same gated source, not the raw
    // schema (it used to list every section, ignoring the licence).
    final more =
        File('lib/features/more/presentation/more_screen.dart').readAsStringSync();
    expect(more, contains('visibleNavSectionsProvider'));
    expect(more, isNot(contains('in appNavSections')));
    expect(shell, contains('dashboardNavItem'));
    expect(shell, contains('mobileNavIndexForLocation'));
  });

  test('navigation schema uses canonical Arabic labels', () {
    expect(dashboardNavItem.label, 'لوحة التحكم');
    expect(
      mobileNavDestinations.map((item) => item.label),
      contains('البطاقات'),
    );
    // The integration/bridge section was removed from the operator app.
    expect(
      appNavSections.map((section) => section.label),
      isNot(contains('التكامل والجسر')),
    );
    expect(
      appNavigationItems.map((item) => item.path),
      isNot(anyOf(contains('/license-file'), contains('/system-operations'))),
    );
    expect(
      appNavSections.map((section) => section.label),
      contains('المال والتحصيل'),
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
