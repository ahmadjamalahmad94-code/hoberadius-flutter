@Tags(['render'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/admin_control/application/admin_control_providers.dart';
import 'package:hoberadius_app/features/admin_control/domain/admin_control_model.dart';
import 'package:hoberadius_app/features/dashboard/domain/dashboard_model.dart';
import 'package:hoberadius_app/features/dashboard/presentation/dashboard_screen.dart';
import 'package:hoberadius_app/shared/widgets/currency_field.dart';

/// Produces PNG render artifacts for the P0 foundation work. Run with:
///   flutter test --update-goldens test/render_p0_artifacts_test.dart
/// Artifacts land under docs/redesign/p0/.
ThemeData _theme() => ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF4F5FB),
      fontFamily: 'Roboto',
    );

Future<void> _frame(
  WidgetTester tester, {
  required Widget child,
  required Size size,
  List<Override> overrides = const [],
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: _theme(),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: const Color(0xFFF4F5FB),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  final populated = DashboardMetrics.fromJson({
    'subscribers': {
      'total': 1280,
      'active': 1110,
      'online': 214,
      'expired': 18,
      'expiring_soon': 7,
      'suspended': 3,
    },
    'cards': {'total': 8000, 'used': 5120, 'available': 2880, 'batches': 26},
    'plans': {
      'total': 9,
      'enabled': 8,
      'disabled': 1,
      'top': {'name': 'باقة 50 جيجا', 'subs': 318},
    },
    'nas': {'total': 6, 'enabled': 6},
    'system': {
      'cpu_pct': 23.0,
      'ram_pct': 61.0,
      'disk_pct': 47.0,
      'hostname': 'vps-hobe-01',
      'system_uptime': '12ي 4س',
      'process_uptime': '6س 12د',
      'db_ok': true,
      'radius_ok': true,
      'network': {'ping_ok': true, 'ping_ms': 14.0, 'dns_ok': true},
    },
    'recent_batches': [
      {'id': 312, 'batch_code': 'B-0312', 'package_name': 'باقة 10 جيجا', 'count': 200, 'used': 173},
      {'id': 311, 'batch_code': 'B-0311', 'package_name': 'باقة 5 جيجا', 'count': 150, 'used': 96},
      {'id': 310, 'batch_code': 'B-0310', 'package_name': 'باقة يومية', 'count': 100, 'used': 100},
    ],
    'alerts': [
      {
        'level': 'warn',
        'link_endpoint': 'radius.users_list',
        'message': '7 مشتركين ينتهي اشتراكهم خلال 3 أيام.',
      },
      {
        'level': 'info',
        'link_endpoint': 'radius.users_list',
        'message': '18 مشترك انتهى اشتراكه — جدّد أو احذف.',
      },
      {
        'level': 'danger',
        'link_endpoint': 'radius.cards_generate',
        'message': 'الكروت المتاحة منخفضة (2880) — جدّد المخزون.',
      },
    ],
  });

  testWidgets('render: dashboard populated (alerts + batches)', (tester) async {
    await _frame(
      tester,
      size: const Size(1100, 1700),
      overrides: [
        dashboardFutureProvider.overrideWith((ref) async => populated),
      ],
      child: const DashboardScreen(),
    );
    await expectLater(
      find.byType(DashboardScreen),
      matchesGoldenFile('../docs/redesign/p0/dashboard_after_populated.png'),
    );
  });

  testWidgets('render: dashboard empty states', (tester) async {
    await _frame(
      tester,
      size: const Size(1100, 1100),
      overrides: [
        dashboardFutureProvider
            .overrideWith((ref) async => DashboardMetrics.fromJson({})),
      ],
      child: const DashboardScreen(),
    );
    await expectLater(
      find.byType(DashboardScreen),
      matchesGoldenFile('../docs/redesign/p0/dashboard_after_empty.png'),
    );
  });

  SettingsSnapshot snap(String c) =>
      SettingsSnapshot(items: const [], settings: {'billing.currency': c});

  testWidgets('render: money field JOD', (tester) async {
    await _frame(
      tester,
      size: const Size(520, 160),
      overrides: [settingsProvider.overrideWith((ref) async => snap('JOD'))],
      child: const _MoneyDemo(),
    );
    await expectLater(
      find.byType(CurrencyField),
      matchesGoldenFile('../docs/redesign/p0/money_currency_jod.png'),
    );
  });

  testWidgets('render: money field ILS', (tester) async {
    await _frame(
      tester,
      size: const Size(520, 160),
      overrides: [settingsProvider.overrideWith((ref) async => snap('ILS'))],
      child: const _MoneyDemo(),
    );
    await expectLater(
      find.byType(CurrencyField),
      matchesGoldenFile('../docs/redesign/p0/money_currency_ils.png'),
    );
  });
}

class _MoneyDemo extends ConsumerWidget {
  const _MoneyDemo();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CurrencyField(currency: ref.watch(tenantCurrencyProvider));
  }
}
