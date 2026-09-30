// appperm — widget-level: nothing the manager can't save opens, the
// «المدير المسؤول» list is never asked for without admins.view, a 403 keeps
// the typed input, owner toggles only for the owner / a co-owner.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hoberadius_app/core/api/api_client.dart';
import 'package:hoberadius_app/core/auth/permissions.dart';
import 'package:hoberadius_app/features/admins/presentation/admin_form_screen.dart';
import 'package:hoberadius_app/features/cards/presentation/widgets/cards_list_header.dart';
import 'package:hoberadius_app/features/dashboard/domain/dashboard_model.dart';
import 'package:hoberadius_app/features/dashboard/presentation/dashboard_screen.dart';
import 'package:hoberadius_app/features/shell/no_access_screen.dart';
import 'package:hoberadius_app/features/subscribers/presentation/subscriber_form_screen.dart';
import 'package:hoberadius_app/features/subscribers/presentation/subscribers_list_screen.dart';
import 'package:hoberadius_app/shared/widgets/form_field_row.dart';

import 'support/fake_api.dart';

Map<String, dynamic> _me({
  int id = 7,
  bool owner = false,
  bool coOwner = false,
  bool originalOwner = false,
  List<String> perms = const [],
  Map<String, bool> actions = const {},
  Map<String, String> sections = const {},
}) =>
    {
      'admin': {
        'id': id,
        'username': 'm$id',
        'is_owner': owner || coOwner,
        'is_co_owner': coOwner,
        'is_original_owner': originalOwner,
        'is_super_admin': false,
      },
      'permissions': perms,
      'grants': {
        'actions': actions,
        'sections': sections,
        'view_all_subscribers': false,
      },
    };

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  required RecordingAdapter adapter,
  required Map<String, dynamic> me,
  List<Override> extra = const [],
}) async {
  tester.view.physicalSize = const Size(900, 3200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(fakeApiClient(adapter)),
        permissionsProvider.overrideWith(
          (ref) => PermissionsController(ref)..apply(me),
        ),
        ...extra,
      ],
      child: MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _button(String label) => find.ancestor(
      of: find.text(label),
      matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
    );

void main() {
  setUpAll(() async => initializeDateFormatting('en'));
  setUp(() => SharedPreferences.setMockInitialValues({}));

  RecordingAdapter emptyApi() => RecordingAdapter(
        (r) => FakeResponse.ok({'items': <dynamic>[], 'total': 0}),
      );

  group('«مشترك جديد» (4(a))', () {
    testWidgets('disabled with the reason when users.create is missing',
        (tester) async {
      await _pump(
        tester,
        const SubscribersListScreen(),
        adapter: emptyApi(),
        me: _me(perms: ['users.view']),
      );
      final btn = tester.widget<ButtonStyleButton>(_button('مشترك جديد').first);
      expect(btn.onPressed, isNull);
      expect(
        find.byWidgetPredicate(
          (w) => w is Tooltip && (w.message ?? '').contains('إنشاء'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('disabled when the subscribers section is locked',
        (tester) async {
      await _pump(
        tester,
        const SubscribersListScreen(),
        adapter: emptyApi(),
        me: _me(
          perms: ['users.view', 'users.create'],
          actions: {'subscriber.create': true},
          sections: {'subscribers': 'locked'},
        ),
      );
      final btn = tester.widget<ButtonStyleButton>(_button('مشترك جديد').first);
      expect(btn.onPressed, isNull);
    });

    testWidgets('enabled with users.create + the action grant', (tester) async {
      await _pump(
        tester,
        const SubscribersListScreen(),
        adapter: emptyApi(),
        me: _me(
          perms: ['users.view', 'users.create'],
          actions: {'subscriber.create': true},
        ),
      );
      final btn = tester.widget<ButtonStyleButton>(_button('مشترك جديد').first);
      expect(btn.onPressed, isNotNull);
    });
  });

  group('«المدير المسؤول» (D18)', () {
    testWidgets('hidden and never fetched without admins.view', (tester) async {
      final adapter = emptyApi();
      await _pump(
        tester,
        const SubscriberFormScreen(),
        adapter: adapter,
        me: _me(
          perms: ['users.view', 'users.create'],
          actions: {'subscriber.create': true},
        ),
      );
      await tester.tap(find.text('الإدارة والربط'));
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (w) => w is FormFieldRow && w.label == 'المدير المسؤول',
        ),
        findsNothing,
      );
      expect(adapter.where('GET', '/api/v1/admins'), isEmpty);
    });

    testWidgets('shown to the owner (list fetched)', (tester) async {
      final adapter = RecordingAdapter((r) {
        if (r.path == '/api/v1/admins') {
          return FakeResponse.ok({
            'items': [
              {'id': 1, 'username': 'owner'},
              {'id': 7, 'username': 'mgr'},
            ],
          });
        }
        return FakeResponse.ok({'items': <dynamic>[]});
      });
      await _pump(
        tester,
        const SubscriberFormScreen(),
        adapter: adapter,
        me: _me(id: 1, owner: true, originalOwner: true),
      );
      await tester.tap(find.text('الإدارة والربط'));
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (w) => w is FormFieldRow && w.label == 'المدير المسؤول',
        ),
        findsOneWidget,
      );
      expect(adapter.where('GET', '/api/v1/admins'), isNotEmpty);
    });
  });

  testWidgets('a 403 on save keeps every typed field and shows the reason',
      (tester) async {
    final adapter = RecordingAdapter((r) {
      if (r.method == 'POST' && r.path == '/api/v1/accounts') {
        return FakeResponse.error(
          403,
          'forbidden',
          'لا تملك صلاحية إنشاء مشترك.',
          details: {'reason': 'permission', 'permission': 'users.create'},
        );
      }
      if (r.method == 'GET' && r.path.startsWith('/api/v1/accounts/')) {
        // the availability check: the username is free
        return FakeResponse.error(404, 'not_found', 'غير موجود');
      }
      if (r.path == '/api/admin/me') {
        return FakeResponse.ok(
          _me(
            perms: ['users.view', 'users.create'],
            actions: {'subscriber.create': true},
          ),
        );
      }
      return FakeResponse.ok({'items': <dynamic>[]});
    });
    await _pump(
      tester,
      const SubscriberFormScreen(),
      adapter: adapter,
      me: _me(
        perms: ['users.view', 'users.create'],
        actions: {'subscriber.create': true},
      ),
    );
    Finder field(String label) => find.descendant(
          of: find.byWidgetPredicate(
            (w) => w is FormFieldRow && w.label == label,
          ),
          matching: find.byType(TextField),
        );
    await tester.enterText(field('اسم المستخدم').first, 'ali_403');
    await tester.enterText(field('الاسم الكامل').first, 'علي حسن');
    await tester.enterText(field('كلمة المرور').first, 'Secret#123');
    await tester.pump();
    await tester.tap(find.text('حفظ'));
    await tester.pumpAndSettle();

    expect(adapter.where('POST', '/api/v1/accounts'), hasLength(1));
    expect(find.textContaining('لا تملك صلاحية إنشاء مشترك.'), findsOneWidget);
    expect(find.textContaining('بياناتك باقية'), findsOneWidget);
    // Nothing lost.
    expect(
      tester.widget<TextField>(field('اسم المستخدم').first).controller!.text,
      'ali_403',
    );
    expect(
      tester.widget<TextField>(field('الاسم الكامل').first).controller!.text,
      'علي حسن',
    );
    expect(
      tester.widget<TextField>(field('كلمة المرور').first).controller!.text,
      'Secret#123',
    );
    expect(find.text('مشترك جديد'), findsOneWidget, reason: 'still the form');
  });

  group('owner toggles on the admin edit screen (4(c))', () {
    RecordingAdapter adminApi({bool original = false}) => RecordingAdapter((r) {
          if (r.path == '/api/v1/admins/9') {
            return FakeResponse.ok({
              'id': 9,
              'username': original ? 'owner' : 'mgr',
              'role_id': 3,
              'is_original_owner': original,
              'is_owner': original,
            });
          }
          if (r.path == '/api/v1/roles') {
            return FakeResponse.ok({
              'items': [
                {'id': 3, 'name': 'operator', 'display_name': 'مشغّل'},
              ],
            });
          }
          return FakeResponse.ok(<String, dynamic>{});
        });

    testWidgets('co-owner sees «سوبر يوزر» and «شريك» with a warning',
        (tester) async {
      await _pump(
        tester,
        const AdminFormScreen(adminId: 9),
        adapter: adminApi(),
        me: _me(id: 2, coOwner: true),
      );
      expect(find.text('سوبر يوزر (كل الصلاحيات)'), findsOneWidget);
      expect(find.text('منح صلاحيات المالك (شريك)'), findsOneWidget);
      expect(
        find.textContaining('تنبيه: الشريك يملك كل صلاحيات المالك'),
        findsOneWidget,
      );
    });

    testWidgets('a manager with admins.edit sees neither toggle',
        (tester) async {
      await _pump(
        tester,
        const AdminFormScreen(adminId: 9),
        adapter: adminApi(),
        me: _me(perms: ['admins.view', 'admins.edit']),
      );
      expect(find.text('سوبر يوزر (كل الصلاحيات)'), findsNothing);
      expect(find.text('منح صلاحيات المالك (شريك)'), findsNothing);
    });

    testWidgets("never on the original owner's row", (tester) async {
      await _pump(
        tester,
        const AdminFormScreen(adminId: 9),
        adapter: adminApi(original: true),
        me: _me(id: 2, coOwner: true),
      );
      expect(find.text('سوبر يوزر (كل الصلاحيات)'), findsNothing);
      expect(find.text('منح صلاحيات المالك (شريك)'), findsNothing);
      expect(find.textContaining('المالك الأصليّ — محميّ'), findsOneWidget);
    });

    testWidgets('saving as a manager never sends the owner flags',
        (tester) async {
      final adapter = adminApi();
      await _pump(
        tester,
        const AdminFormScreen(adminId: 9),
        adapter: adapter,
        me: _me(perms: ['admins.view', 'admins.edit']),
      );
      await tester.tap(find.text('حفظ'));
      await tester.pumpAndSettle();
      final patch = adapter.where('PATCH', '/api/v1/admins/9').single;
      expect(patch.jsonBody.containsKey('is_super_admin'), isFalse);
      expect(patch.jsonBody.containsKey('is_co_owner'), isFalse);
    });
  });

  group('dashboard (D18: a viewer saw every total)', () {
    final metrics = DashboardMetrics.fromJson({
      'subscribers': {'total': 200, 'online': 20, 'expired': 12},
      'cards': {'total': 5000, 'used': 331, 'available': 4669},
      'plans': {'total': 7, 'enabled': 6},
      'nas': {'total': 4, 'enabled': 3},
    });

    Future<void> pumpDash(WidgetTester tester, Map<String, dynamic> me) =>
        _pump(
          tester,
          const DashboardScreen(),
          adapter:
              RecordingAdapter((r) => FakeResponse.ok(<String, dynamic>{})),
          me: me,
          extra: [dashboardFutureProvider.overrideWith((ref) async => metrics)],
        );

    testWidgets('viewer: no totals, no shortcuts', (tester) async {
      await pumpDash(tester, _me(perms: ['dashboard.view']));
      expect(find.text('إجمالي المشتركين'), findsNothing);
      expect(find.text('متّصلون الآن'), findsNothing);
      expect(find.text('الكروت المُولَّدة'), findsNothing);
      expect(find.text('آخر الحزم'), findsNothing);
      expect(find.text('متابعة المشتركين'), findsNothing);
    });

    testWidgets('subscribers-only manager: just the subscriber tiles',
        (tester) async {
      await pumpDash(tester, _me(perms: ['users.view']));
      expect(find.text('إجمالي المشتركين'), findsOneWidget);
      expect(find.text('الكروت المُولَّدة'), findsNothing);
      expect(find.text('أجهزة الشبكة'), findsNothing);
    });

    testWidgets('owner: every tile', (tester) async {
      await pumpDash(tester, _me(id: 1, owner: true));
      expect(find.text('إجمالي المشتركين'), findsOneWidget);
      expect(find.text('الكروت المُولَّدة'), findsOneWidget);
      expect(find.text('أجهزة الشبكة'), findsOneWidget);
    });
  });

  group('cards header', () {
    testWidgets(
        '«حزمة جديدة» disabled without cards.generate; checker hidden '
        'without cards.view/verify', (tester) async {
      await _pump(
        tester,
        CardsListHeader(onRefresh: () {}),
        adapter: RecordingAdapter((r) => FakeResponse.ok(<String, dynamic>{})),
        me: _me(perms: ['users.view']),
      );
      final btn = tester.widget<ButtonStyleButton>(_button('حزمة جديدة').first);
      expect(btn.onPressed, isNull);
      expect(find.text('فحص بطاقة'), findsNothing);
    });

    testWidgets('enabled with cards.generate + the action grant',
        (tester) async {
      await _pump(
        tester,
        CardsListHeader(onRefresh: () {}),
        adapter: RecordingAdapter((r) => FakeResponse.ok(<String, dynamic>{})),
        me: _me(
          perms: ['cards.view', 'cards.generate'],
          actions: {'cards.generate': true},
        ),
      );
      final btn = tester.widget<ButtonStyleButton>(_button('حزمة جديدة').first);
      expect(btn.onPressed, isNotNull);
      expect(find.text('فحص بطاقة'), findsOneWidget);
    });
  });

  testWidgets('/no-access explains the refusal in Arabic', (tester) async {
    await _pump(
      tester,
      const NoAccessScreen(from: '/subscribers/new'),
      adapter: RecordingAdapter((r) => FakeResponse.ok(<String, dynamic>{})),
      me: _me(perms: ['users.view']),
    );
    expect(find.text('لا تملك صلاحية فتح هذه الصفحة'), findsOneWidget);
    expect(find.textContaining('إنشاء'), findsOneWidget);
  });
}
