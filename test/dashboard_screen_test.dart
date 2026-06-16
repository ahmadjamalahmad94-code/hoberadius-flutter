import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/dashboard/domain/dashboard_model.dart';
import 'package:hoberadius_app/features/dashboard/presentation/dashboard_screen.dart';

Future<void> _pumpDashboard(
  WidgetTester tester,
  DashboardMetrics metrics,
) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dashboardFutureProvider.overrideWith((ref) async => metrics),
      ],
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: DashboardScreen(),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump(); // resolve the overridden future
  await tester.pump();
}

void main() {
  testWidgets('renders recent batches + alerts from the API payload',
      (tester) async {
    final metrics = DashboardMetrics.fromJson({
      'subscribers': {
        'total': 200,
        'active': 150,
        'online': 20,
        'expired': 12,
        'expiring_soon': 5,
      },
      'cards': {'total': 5000, 'used': 331, 'available': 4669, 'batches': 9},
      'plans': {
        'total': 7,
        'enabled': 6,
        'disabled': 1,
        'top': {'name': 'باقة الذهبية', 'subs': 64},
      },
      'nas': {'total': 4, 'enabled': 3},
      'system': {'db_ok': true, 'radius_ok': false},
      'recent_batches': [
        {
          'id': 42,
          'batch_code': 'B-0042',
          'package_name': 'باقة 10 جيجا',
          'count': 100,
          'used': 37,
        },
      ],
      'alerts': [
        {
          'level': 'warn',
          'link_endpoint': 'radius.users_list',
          'message': '5 مشترك ينتهي اشتراكهم خلال 3 أيام.',
        },
        {
          'level': 'danger',
          'message': 'لا توجد كروت متاحة — وَلِّد دفعة جديدة.',
        },
      ],
    });

    await _pumpDashboard(tester, metrics);

    // Recent batches card + a row.
    expect(find.text('آخر الحزم'), findsOneWidget);
    expect(find.text('باقة 10 جيجا'), findsOneWidget);
    expect(find.text('37 / 100'), findsOneWidget);

    // Alerts card + messages.
    expect(find.text('ما يحتاج انتباه'), findsOneWidget);
    expect(find.text('5 مشترك ينتهي اشتراكهم خلال 3 أيام.'), findsOneWidget);
    expect(find.text('لا توجد كروت متاحة — وَلِّد دفعة جديدة.'), findsOneWidget);

    // Subscriber attention + top plan surfaced.
    expect(find.text('متابعة المشتركين'), findsOneWidget);
    expect(find.textContaining('الأكثر استخدامًا'), findsOneWidget);

    // Service-health chips.
    expect(find.text('قاعدة البيانات متصلة'), findsOneWidget);
    expect(find.text('RADIUS غير جاهز'), findsOneWidget);
  });

  testWidgets('shows empty states when batches + alerts are empty',
      (tester) async {
    await _pumpDashboard(tester, DashboardMetrics.fromJson({}));

    expect(find.text('لا توجد حزم بعد'), findsOneWidget);
    expect(
      find.text('لا توجد ملاحظات تشغيلية مهمة الآن.'),
      findsOneWidget,
    );
  });
}
