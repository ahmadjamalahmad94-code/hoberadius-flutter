// appfinal — the app adopts the final backend contract (agent/fix2-final):
// distributor login fields, the per-tool permission map, the server's
// `create_without_expiry` rule with an explicit «بدون انتهاء», and the
// owner's rules (≤ 1 year per extension, panel zone Gaza, money ≤ 100,000)
// re-verified at every entry point touched here.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hoberadius_app/core/api/api_client.dart';
import 'package:hoberadius_app/core/api/api_endpoint_storage.dart';
import 'package:hoberadius_app/core/api/api_exception.dart';
import 'package:hoberadius_app/core/auth/auth_controller.dart';
import 'package:hoberadius_app/core/auth/permission_route_gate.dart';
import 'package:hoberadius_app/core/auth/permissions.dart';
import 'package:hoberadius_app/core/auth/route_permissions.dart';
import 'package:hoberadius_app/core/auth/security_key_storage.dart';
import 'package:hoberadius_app/core/auth/system_settings.dart';
import 'package:hoberadius_app/core/auth/token_storage.dart';
import 'package:hoberadius_app/core/format/currency.dart';
import 'package:hoberadius_app/core/format/money_limits.dart';
import 'package:hoberadius_app/core/format/panel_time.dart';
import 'package:hoberadius_app/features/provider_grants/application/nav_visibility.dart';
import 'package:hoberadius_app/features/provider_grants/domain/provider_grants_model.dart';
import 'package:hoberadius_app/features/shell/visible_nav_sections.dart';
import 'package:hoberadius_app/features/store_admin/presentation/store_admin_screen.dart';
import 'package:hoberadius_app/features/subscribers/application/new_subscriber_expiry.dart';
import 'package:hoberadius_app/features/subscribers/data/subscriber_actions_repository.dart';
import 'package:hoberadius_app/features/subscribers/data/subscribers_repository.dart';
import 'package:hoberadius_app/features/subscribers/domain/subscriber_model.dart';
import 'package:hoberadius_app/features/subscribers/presentation/subscriber_form_screen.dart';
import 'package:hoberadius_app/features/subscribers/presentation/widgets/expire_picker.dart';
import 'package:hoberadius_app/features/tools/application/tools_providers.dart';
import 'package:hoberadius_app/features/tools/presentation/tools_screen.dart';
import 'package:hoberadius_app/features/tools/presentation/widgets/tools_adjustments_panel.dart';
import 'package:hoberadius_app/shared/widgets/form_field_row.dart';

import 'support/fake_api.dart';

/// An /api/admin/me payload of the final contract.
Map<String, dynamic> me({
  int id = 7,
  bool owner = false,
  List<String> perms = const [],
  Map<String, bool> actions = const {},
  Map<String, bool>? tools,
  Map<String, dynamic> extraAdmin = const {},
  Map<String, dynamic> extraGrants = const {},
  Map<String, dynamic>? system,
}) =>
    {
      'admin': {
        'id': id,
        'username': 'm$id',
        'is_owner': owner,
        'is_co_owner': false,
        'is_original_owner': owner,
        'is_super_admin': false,
        'is_distributor': false,
        'distributor_id': null,
        'distributor_name': null,
        ...extraAdmin,
      },
      'permissions': perms,
      'grants': {
        'actions': actions,
        'sections': <String, String>{},
        'view_all_subscribers': owner,
        if (tools != null) 'tools': tools,
        ...extraGrants,
      },
      if (system != null) 'system': system,
    };

AppPermissions perm(Map<String, dynamic> d) => AppPermissions.fromMe(d);

/// A distributor login (D11 `login_admin_id`) — role keys of a plain seller.
final distributor = perm(
  me(
    id: 40,
    perms: ['users.view', 'cards.view'],
    extraAdmin: {
      'is_distributor': true,
      'distributor_id': 5,
      'distributor_name': 'بقالة النور',
    },
  ),
);

const _allTools = {
  'set_speeds': true,
  'general_adjustments': true,
  'test_auth': true,
  'radius_log': true,
  'maintenance': true,
};
const _logOnly = {
  'set_speeds': false,
  'general_adjustments': false,
  'test_auth': false,
  'radius_log': true,
  'maintenance': false,
};
const _none = {
  'set_speeds': false,
  'general_adjustments': false,
  'test_auth': false,
  'radius_log': false,
  'maintenance': false,
};

class _Tokens implements TokenStorage {
  _Tokens(this.token);
  String? token;
  @override
  Future<void> clear() async => token = null;
  @override
  Future<String?> read() async => token;
  @override
  Future<void> write(String t) async => token = t;
}

class _Keys implements SecurityKeyStorage {
  @override
  Future<void> clear() async {}
  @override
  Future<String?> read() async => null;
  @override
  Future<void> write(String key) async {}
}

class _Endpoint implements ApiEndpointStorage {
  @override
  Future<String> readBaseUrl() async => 'http://127.0.0.1:5000';
  @override
  Future<void> writeBaseUrl(String baseUrl) async {}
}

Future<void> _settle() async {
  for (var i = 0; i < 30; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

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

void main() {
  setUpAll(() async => initializeDateFormatting('en'));
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(PanelTimeZone.reset);

  // ─────────────────────────── 1. distributor ───────────────────────────
  group('1. distributor login (admin.is_distributor / distributor_id)', () {
    test('/me fields are parsed', () {
      expect(distributor.isDistributor, isTrue);
      expect(distributor.distributorId, 5);
      expect(distributor.distributorName, 'بقالة النور');
      final plain = perm(me(perms: ['users.view']));
      expect(plain.isDistributor, isFalse);
      expect(plain.distributorId, isNull);
      expect(plain.distributorName, '');
    });

    test('the list opens ITS page; another distributor never opens', () {
      expect(
        distributorOwnPageRedirect(distributor, '/distributors'),
        '/distributors/5',
      );
      expect(
        routeDenial(distributor, '/distributors/5'),
        isNull,
        reason: 'own page, even without reports.finance',
      );
      expect(
        routeDenial(distributor, '/distributors/6'),
        kOtherDistributorPage,
      );
      expect(routeDenial(distributor, '/distributors/new'), isNotNull);
      // the rest of the distributor-scoped UI (built in appperm) still holds
      expect(routeDenial(distributor, '/subscribers'), isNull);
      expect(routeDenial(distributor, '/cards'), isNull);
      expect(routeDenial(distributor, '/plans'), isNotNull);
      expect(routeDenial(distributor, '/revenue'), isNotNull);
    });

    test('the router gate rewrites /distributors before any check', () {
      final gate = PermissionRouteGate();
      expect(gate.redirect(distributor, '/distributors'), '/distributors/5');
      expect(gate.redirect(distributor, '/distributors/5'), isNull);
      expect(
        gate.redirect(distributor, '/distributors/9'),
        startsWith('/no-access'),
      );
    });

    test('no rewrite for managers, owners, legacy or an unknown id', () {
      final manager = perm(me(perms: ['reports.finance']));
      final owner = perm(me(id: 1, owner: true));
      final legacy = perm({
        'admin': {'id': 1, 'distributor_id': 5},
      });
      final flagOnly = perm(me(extraAdmin: {'is_distributor': true}));
      for (final p in [manager, owner, legacy, flagOnly]) {
        expect(distributorOwnPageRedirect(p, '/distributors'), isNull);
      }
      // flag without an id: the appperm rule (list refused) is kept
      expect(flagOnly.isDistributor, isTrue);
      expect(routeDenial(flagOnly, '/distributors'), isNotNull);
    });

    test('the menu entry becomes «صفحتي كموزّع»', () {
      final all = gatedNavSections(ProviderGrants.permissive);
      final items = [
        for (final s in filterNavSectionsByPermissions(all, distributor))
          for (final i in s.items) i.item,
      ];
      final own = items.where((i) => i.path == '/distributors').toList();
      expect(own, hasLength(1));
      expect(own.single.label, kDistributorOwnPageLabel);
      expect(own.single.description, contains('بقالة النور'));
      expect(own.single.routeName, 'distributors');
      // a manager keeps «الموزعون»
      final mgr = perm(me(perms: ['reports.finance']));
      final mgrItems = [
        for (final s in filterNavSectionsByPermissions(all, mgr))
          for (final i in s.items) i.item,
      ];
      expect(
        mgrItems.singleWhere((i) => i.path == '/distributors').label,
        'الموزعون',
      );
    });
  });

  // ─────────────────────────── 2. tools map ───────────────────────────
  group('2. per-tool permission map (grants.tools, GET /api/v1/tools)', () {
    test('canTool follows grants.tools; unknown = allowed (older server)', () {
      final p = perm(me(perms: ['reports.view'], tools: _logOnly));
      expect(p.canTool(kToolRadiusLog), isTrue);
      expect(p.canTool(kToolSetSpeeds), isFalse);
      expect(p.canTool(kToolMaintenance), isFalse);
      final noMap = perm(me(perms: ['reports.view']));
      expect(noMap.tools, isNull);
      expect(kToolKeys.every(noMap.canTool), isTrue);
      // the server's «could not evaluate» ({}) is unknown, not «nothing»
      expect(perm(me(tools: const {})).tools, isNull);
      expect(kToolKeys.every(perm(me(id: 1, owner: true)).canTool), isTrue);
      expect(
        kToolKeys.every(
          perm({
            'admin': {'id': 1},
          }).canTool,
        ),
        isTrue,
      );
    });

    test('/tools is refused when the map allows no tool', () {
      expect(
        routeDenial(
          perm(me(perms: ['reports.view'], tools: _none)),
          '/tools',
        ),
        kNoToolAllowed,
      );
      expect(
        routeDenial(
          perm(me(perms: ['reports.view'], tools: _logOnly)),
          '/tools',
        ),
        isNull,
      );
      expect(routeDenial(perm(me(perms: ['reports.view'])), '/tools'), isNull);
    });

    test('GET /api/v1/tools payload → map (allowed or items)', () {
      expect(parseToolsAccess({'allowed': _logOnly}), _logOnly);
      expect(
        parseToolsAccess({
          'items': [
            {'key': 'set_speeds', 'allowed': false, 'owner_only': true},
            {'key': 'radius_log', 'allowed': true, 'owner_only': false},
          ],
        }),
        {'set_speeds': false, 'radius_log': true},
      );
      expect(parseToolsAccess(null), isNull);
      expect(parseToolsAccess({'allowed': {}}), isNull);
      expect(visibleToolKeys(null), kToolKeys);
      expect(visibleToolKeys(_logOnly), [kToolRadiusLog]);
    });

    test('toolsAccessProvider: /me map first, else /api/v1/tools, else all',
        () async {
      Future<(Map<String, bool>?, RecordingAdapter)> run(
        Map<String, dynamic> meData,
        FakeHandler handler,
      ) async {
        final adapter = RecordingAdapter(handler);
        final c = ProviderContainer(
          overrides: [
            apiClientProvider.overrideWithValue(fakeApiClient(adapter)),
            permissionsProvider.overrideWith(
              (ref) => PermissionsController(ref)..apply(meData),
            ),
          ],
        );
        addTearDown(c.dispose);
        final sub = c.listen(toolsAccessProvider, (_, __) {});
        addTearDown(sub.close);
        return (await c.read(toolsAccessProvider.future), adapter);
      }

      final (fromMe, a1) = await run(
        me(perms: ['reports.view'], tools: _logOnly),
        (_) => FakeResponse.ok({}),
      );
      expect(fromMe, _logOnly);
      expect(a1.requests, isEmpty, reason: 'no request when /me carries it');

      final (fromApi, a2) = await run(
        me(perms: ['reports.view']),
        (r) => r.path == '/api/v1/tools'
            ? FakeResponse.ok({'allowed': _logOnly, 'items': []})
            : FakeResponse.ok({}),
      );
      expect(fromApi, _logOnly);
      expect(a2.where('GET', '/api/v1/tools'), hasLength(1));

      final (old, _) = await run(
        me(perms: ['reports.view']),
        (_) => FakeResponse.error(404, 'not_found', 'غير موجود'),
      );
      expect(old, isNull, reason: 'older server: show every tool');

      final (legacy, a4) = await run(
        {
          'admin': {'id': 1},
        },
        (_) => FakeResponse.ok({}),
      );
      expect(legacy, isNull);
      expect(a4.requests, isEmpty);
    });

    RecordingAdapter toolsApi() => RecordingAdapter((r) {
          if (r.path == '/api/v1/tools/radius-log') {
            return FakeResponse.ok({'items': <dynamic>[]});
          }
          if (r.path == '/api/v1/tools') {
            return FakeResponse.error(404, 'not_found', 'غير موجود');
          }
          return FakeResponse.ok(<String, dynamic>{});
        });

    testWidgets('a radius-log-only manager sees only «السجل»', (tester) async {
      final adapter = toolsApi();
      await _pump(
        tester,
        const ToolsScreen(),
        adapter: adapter,
        me: me(perms: ['reports.view'], tools: _logOnly),
      );
      expect(find.text('ضبط سرعات جماعي'), findsNothing);
      expect(find.text('السرعات'), findsNothing);
      expect(find.text('الصيانة'), findsNothing);
      expect(find.text('اختبار'), findsNothing);
      expect(adapter.where('GET', '/api/v1/tools/radius-log'), isNotEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('no tool allowed → an Arabic empty state, no tool request',
        (tester) async {
      final adapter = toolsApi();
      await _pump(
        tester,
        const ToolsScreen(),
        adapter: adapter,
        me: me(perms: ['reports.view'], tools: _none),
      );
      expect(find.text('لا تملك صلاحية أيّ أداة'), findsOneWidget);
      expect(adapter.where('GET', '/api/v1/tools/radius-log'), isEmpty);
    });

    testWidgets('owner and an older server keep all five tabs', (tester) async {
      for (final meData in [
        me(id: 1, owner: true, tools: _allTools),
        me(perms: ['reports.view']), // no map, /api/v1/tools 404
      ]) {
        await _pump(
          tester,
          const ToolsScreen(),
          adapter: toolsApi(),
          me: meData,
        );
        for (final label in [
          'السرعات',
          'تعديلات',
          'اختبار',
          'السجل',
          'الصيانة',
        ]) {
          expect(find.text(label), findsOneWidget, reason: label);
        }
      }
    });
  });

  // ─────────────────── 3. create_without_expiry + «بدون انتهاء» ───────────
  group('3. create_without_expiry', () {
    test('parsed from /me system and from /settings', () {
      expect(
        createWithoutExpiryOf({
          'system': {'create_without_expiry': 'expired'},
        }),
        kCreateWithoutExpiryExpired,
      );
      expect(
        createWithoutExpiryOf({
          'system': {'create_without_expiry': 'UNLIMITED'},
        }),
        kCreateWithoutExpiryUnlimited,
      );
      expect(
        createWithoutExpiryOf({
          'settings': {'subscribers.create_without_expiry': 'unlimited'},
        }),
        kCreateWithoutExpiryUnlimited,
      );
      expect(
        createWithoutExpiryOf({
          'system': {'currency': 'ILS'},
        }),
        isNull,
      );
      expect(
        createWithoutExpiryOf({
          'system': {'create_without_expiry': 'x'},
        }),
        isNull,
      );
    });

    test('the hint follows the rule; none on an older server', () {
      expect(
        newSubscriberExpiryHint(mode: 'expired', explicitNoExpiry: false),
        'سيُنشأ المشترك منتهيًا حتى تجدّده',
      );
      expect(
        newSubscriberExpiryHint(mode: 'unlimited', explicitNoExpiry: false),
        'بلا تاريخ انتهاء',
      );
      expect(
        newSubscriberExpiryHint(mode: 'expired', explicitNoExpiry: true),
        kExplicitNoExpiryHint,
      );
      expect(
        newSubscriberExpiryHint(mode: null, explicitNoExpiry: false),
        isNull,
      );
    });

    test('canSetExpiry: owner / legacy / extend action / field grants', () {
      expect(perm(me(id: 1, owner: true)).canSetExpiry, isTrue);
      expect(
        perm({
          'admin': {'id': 1},
        }).canSetExpiry,
        isTrue,
      );
      expect(
        perm(me(perms: ['users.create'], actions: {'subscriber.extend': true}))
            .canSetExpiry,
        isTrue,
      );
      expect(
        perm(me(perms: ['users.create'], actions: {'subscriber.extend': false}))
            .canSetExpiry,
        isFalse,
      );
      // no action decision → the RBAC key (users.extend)
      expect(perm(me(perms: ['users.extend'])).canSetExpiry, isTrue);
      expect(perm(me(perms: ['users.create'])).canSetExpiry, isFalse);
      // field grants, when sent, must include «expiry»
      expect(
        perm(
          me(
            perms: ['users.extend'],
            extraGrants: {
              'fields': {
                'subscriber': ['name', 'plan'],
              },
            },
          ),
        ).canSetExpiry,
        isFalse,
      );
    });

    test('create body: explicit «بدون انتهاء» = expire_at: null; else absent',
        () {
      final s = Subscriber(username: 'ali', password: 'x1234');
      expect(s.toCreateBody().containsKey('expire_at'), isFalse);
      final explicit = s.toCreateBody(explicitNoExpiry: true);
      expect(explicit.containsKey('expire_at'), isTrue);
      expect(explicit['expire_at'], isNull);
      final dated = Subscriber(
        username: 'ali',
        password: 'x1234',
        expireAt: DateTime.utc(2027, 1, 1),
      ).toCreateBody(explicitNoExpiry: true);
      expect(dated['expire_at'], isNotNull, reason: 'a date always wins');
    });

    RecordingAdapter createApi(Map<String, dynamic> meData) =>
        RecordingAdapter((r) {
          if (r.method == 'POST' && r.path == '/api/v1/accounts') {
            // stop before navigation: we only look at the body
            return FakeResponse.error(422, 'validation_error', 'رفض تجريبيّ.');
          }
          if (r.method == 'GET' && r.path.startsWith('/api/v1/accounts/')) {
            return FakeResponse.error(404, 'not_found', 'غير موجود');
          }
          if (r.path == '/api/admin/me') return FakeResponse.ok(meData);
          return FakeResponse.ok({'items': <dynamic>[]});
        });

    Future<RecordedRequest> fillAndSave(
      WidgetTester tester,
      RecordingAdapter adapter,
    ) async {
      Finder field(String label) => find.descendant(
            of: find.byWidgetPredicate(
              (w) => w is FormFieldRow && w.label == label,
            ),
            matching: find.byType(TextField),
          );
      await tester.enterText(field('اسم المستخدم').first, 'ali_new');
      await tester.enterText(field('كلمة المرور').first, 'Secret#123');
      await tester.pump();
      await tester.tap(find.text('حفظ'));
      await tester.pumpAndSettle();
      return adapter.where('POST', '/api/v1/accounts').single;
    }

    Map<String, dynamic> creatorMe({String? mode, bool extend = true}) => me(
          perms: [
            'users.view',
            'users.create',
            if (extend) 'users.extend',
          ],
          actions: {
            'subscriber.create': true,
            'subscriber.extend': extend,
          },
          system: mode == null ? null : {'create_without_expiry': mode},
        );

    testWidgets('«expired» (default): hint shown, key omitted on save',
        (tester) async {
      final meData = creatorMe(mode: 'expired');
      final adapter = createApi(meData);
      await _pump(
        tester,
        const SubscriberFormScreen(),
        adapter: adapter,
        me: meData,
      );
      expect(find.text(kNoExpiryHintExpired), findsOneWidget);
      expect(find.text(kExpiryNotChosen), findsOneWidget);
      expect(
        find.byKey(const ValueKey('new-subscriber-no-expiry')),
        findsOneWidget,
      );
      final post = await fillAndSave(tester, adapter);
      expect(
        post.jsonBody.containsKey('expire_at'),
        isFalse,
        reason: 'the server rule applies',
      );
    });

    testWidgets('«unlimited»: its own hint', (tester) async {
      final meData = creatorMe(mode: 'unlimited');
      await _pump(
        tester,
        const SubscriberFormScreen(),
        adapter: createApi(meData),
        me: meData,
      );
      expect(find.text(kNoExpiryHintUnlimited), findsOneWidget);
      expect(find.text(kNoExpiryHintExpired), findsNothing);
    });

    testWidgets('explicit «بدون انتهاء» sends expire_at: null', (tester) async {
      final meData = creatorMe(mode: 'expired');
      final adapter = createApi(meData);
      await _pump(
        tester,
        const SubscriberFormScreen(),
        adapter: adapter,
        me: meData,
      );
      await tester.tap(find.byKey(const ValueKey('new-subscriber-no-expiry')));
      await tester.pumpAndSettle();
      expect(find.text(kExplicitNoExpiryHint), findsOneWidget);
      expect(
        find.byKey(const ValueKey('new-subscriber-expiry-undo')),
        findsOneWidget,
      );
      final post = await fillAndSave(tester, adapter);
      expect(post.jsonBody.containsKey('expire_at'), isTrue);
      expect(post.jsonBody['expire_at'], isNull);
    });

    testWidgets('undo returns to the server rule (key omitted again)',
        (tester) async {
      final meData = creatorMe(mode: 'expired');
      final adapter = createApi(meData);
      await _pump(
        tester,
        const SubscriberFormScreen(),
        adapter: adapter,
        me: meData,
      );
      await tester.tap(find.byKey(const ValueKey('new-subscriber-no-expiry')));
      await tester.pumpAndSettle();
      await tester
          .tap(find.byKey(const ValueKey('new-subscriber-expiry-undo')));
      await tester.pumpAndSettle();
      expect(find.text(kNoExpiryHintExpired), findsOneWidget);
      final post = await fillAndSave(tester, adapter);
      expect(post.jsonBody.containsKey('expire_at'), isFalse);
    });

    testWidgets('not allowed to set expiry: hint only, no «بدون انتهاء»',
        (tester) async {
      final meData = creatorMe(mode: 'expired', extend: false);
      final adapter = createApi(meData);
      await _pump(
        tester,
        const SubscriberFormScreen(),
        adapter: adapter,
        me: meData,
      );
      expect(find.text(kNoExpiryHintExpired), findsOneWidget);
      expect(
        find.byKey(const ValueKey('new-subscriber-no-expiry')),
        findsNothing,
      );
      final post = await fillAndSave(tester, adapter);
      expect(post.jsonBody.containsKey('expire_at'), isFalse);
    });

    testWidgets('mode from the session provider (no /me read)', (tester) async {
      final meData = creatorMe();
      final adapter = createApi(meData);
      await _pump(
        tester,
        const SubscriberFormScreen(),
        adapter: adapter,
        me: meData,
        extra: [
          createWithoutExpiryProvider.overrideWith((ref) => 'unlimited'),
        ],
      );
      expect(find.text(kNoExpiryHintUnlimited), findsOneWidget);
      expect(adapter.where('GET', '/api/admin/me'), isEmpty);
    });

    testWidgets('older server (legacy): the old field, nothing new',
        (tester) async {
      final meData = <String, dynamic>{
        'admin': {'id': 1, 'username': 'old'},
        'permissions': <String>[],
      };
      final adapter = createApi(meData);
      await _pump(
        tester,
        const SubscriberFormScreen(),
        adapter: adapter,
        me: meData,
      );
      expect(
        find.text(kExplicitNoExpiryLabel),
        findsOneWidget,
        reason: 'the old empty text',
      );
      expect(find.text(kNoExpiryHintExpired), findsNothing);
      expect(
        find.byKey(const ValueKey('new-subscriber-no-expiry')),
        findsNothing,
      );
      expect(adapter.where('GET', '/api/admin/me'), isEmpty);
      final post = await fillAndSave(tester, adapter);
      expect(post.jsonBody.containsKey('expire_at'), isFalse);
    });

    testWidgets('edit form: ✕ (clear expiry) only for who may set it',
        (tester) async {
      for (final allowed in [true, false]) {
        await tester.pumpWidget(
          ProviderScope(
            key: ValueKey(allowed),
            overrides: [
              permissionsProvider.overrideWith(
                (ref) => PermissionsController(ref)
                  ..apply(creatorMe(extend: allowed)),
              ),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: SubscriberExpiryField(
                  isEdit: true,
                  value: DateTime(2027, 1, 1, 23, 59),
                  onChange: (_) {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byIcon(Icons.clear),
          allowed ? findsOneWidget : findsNothing,
          reason: 'allowed=$allowed',
        );
      }
    });
  });

  // ───────────── session: login reads /me system (zone, currency, rule) ─────
  group('session system block', () {
    test('login answer without system → /me system: Gaza zone + rule',
        () async {
      var meReads = 0;
      final adapter = RecordingAdapter((r) {
        if (r.path == '/api/admin/login') {
          return FakeResponse.ok({
            'token': 'tok',
            ...me(id: 9, perms: ['users.view']),
          });
        }
        if (r.path == '/api/admin/me') {
          meReads++;
          return FakeResponse.ok(
            me(
              id: 9,
              perms: ['users.view'],
              system: {
                'currency': 'ILS',
                'timezone': 'Asia/Gaza',
                'timezone_label': 'غزة (فلسطين)',
                'utc_offset_minutes': 180,
                'create_without_expiry': 'expired',
              },
            ),
          );
        }
        return FakeResponse.ok(<String, dynamic>{});
      });
      final c = ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWithValue(_Tokens(null)),
          apiEndpointStorageProvider.overrideWithValue(_Endpoint()),
          securityKeyStorageProvider.overrideWithValue(_Keys()),
          apiClientProvider.overrideWithValue(fakeApiClient(adapter)),
        ],
      );
      addTearDown(c.dispose);
      c.read(authControllerProvider);
      await _settle();
      await c.read(authControllerProvider.notifier).login(
            baseUrl: 'http://127.0.0.1:5000',
            username: 'm9',
            password: 'x',
          );
      await _settle();
      expect(c.read(authControllerProvider).error, isNull);
      expect(meReads, 1);
      expect(PanelTimeZone.name, 'Asia/Gaza');
      expect(c.read(sessionCurrencyProvider), 'ILS');
      expect(c.read(createWithoutExpiryProvider), 'expired');
      expect(adapter.where('GET', '/api/v1/settings'), isEmpty);
      // Gaza, not the phone: winter +2, summer +3
      expect(PanelTimeZone.offsetAt(DateTime.utc(2027, 1, 15)).inHours, 2);
      expect(PanelTimeZone.offsetAt(DateTime.utc(2027, 7, 15)).inHours, 3);

      await c.read(authControllerProvider.notifier).logout();
      await _settle();
      expect(
        c.read(createWithoutExpiryProvider),
        isNull,
        reason: 'nothing of this session survives sign-out',
      );
    });

    test('a /me refresh updates the rule (owner changed the setting)',
        () async {
      var mode = 'expired';
      final adapter = RecordingAdapter((r) {
        if (r.path == '/api/admin/me') {
          return FakeResponse.ok(
            me(perms: ['users.view'], system: {'create_without_expiry': mode}),
          );
        }
        return FakeResponse.ok(<String, dynamic>{});
      });
      final c = ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWithValue(_Tokens('t')),
          apiEndpointStorageProvider.overrideWithValue(_Endpoint()),
          securityKeyStorageProvider.overrideWithValue(_Keys()),
          apiClientProvider.overrideWithValue(fakeApiClient(adapter)),
        ],
      );
      addTearDown(c.dispose);
      c.read(authControllerProvider);
      await _settle();
      expect(c.read(createWithoutExpiryProvider), 'expired');
      mode = 'unlimited';
      await c.read(permissionsProvider.notifier).refresh(force: true);
      await _settle();
      expect(c.read(createWithoutExpiryProvider), 'unlimited');
    });
  });

  // ─────────────────────────── 5. owner rules ───────────────────────────
  group('5. owner rules at every entry point', () {
    test('≤ 1 year per extension: bulk «تمديد وقت» (tools)', () {
      expect(validateAdjustmentMinutes('525600'), isNull);
      expect(validateAdjustmentMinutes('٥٢٥٦٠٠'), isNull);
      expect(
        validateAdjustmentMinutes('525601'),
        contains('أقصى تمديد في المرة الواحدة سنة'),
      );
      expect(validateAdjustmentMinutes('0'), isNotNull);
      expect(validateAdjustmentMinutes('abc'), isNotNull);
    });

    testWidgets('bulk «تمديد وقت» over a year is never sent', (tester) async {
      var sent = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ToolsAdjustmentsPanel(
                busy: false,
                run: (body) async {
                  sent++;
                  return null;
                },
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('تعطيل'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تمديد وقت').last);
      await tester.pumpAndSettle();
      expect(
        find.text('حتى سنة واحدة (525,600 دقيقة) في المرة'),
        findsOneWidget,
      );
      await tester.enterText(find.byType(TextField).last, '600000');
      await tester.tap(find.text('تنفيذ'));
      await tester.pumpAndSettle();
      expect(sent, 0);
      expect(
        find.textContaining('أقصى تمديد في المرة الواحدة سنة'),
        findsOneWidget,
      );
    });

    test('≤ 1 year: extend_time (form + legacy menu) refused before sending',
        () async {
      final adapter = RecordingAdapter((_) => FakeResponse.ok({}));
      final api = fakeApiClient(adapter);
      await expectLater(
        SubscribersRepository(api).extendTime('ali', kMaxActionMinutes + 1),
        throwsA(
          isA<ApiException>()
              .having((e) => e.message, 'message', contains('سنة')),
        ),
      );
      await expectLater(
        SubscriberActionsRepository(api)
            .extendTimeLegacy('ali', kMaxActionMinutes + 1),
        throwsA(isA<ApiException>()),
      );
      expect(adapter.requests, isEmpty);
      await SubscribersRepository(api).extendTime('ali', kMaxActionMinutes);
      expect(adapter.where('POST', 'extend_time'), hasLength(1));
    });

    test('money ≤ 100,000: typed amounts (tickets, collection, vouchers)', () {
      expect(readMoneyInput('100000').value, 100000);
      expect(readMoneyInput('100000.00').error, isNull);
      expect(readMoneyInput('١٠٠٠٠٠').value, 100000);
      expect(readMoneyInput('100000.01').error, contains('100,000'));
      expect(readMoneyInput('1000000').value, isNull);
      expect(readMoneyInput('0').error, isNotNull);
      expect(readMoneyInput('-5').error, isNotNull);
      expect(readMoneyInput('').error, isNotNull);
      expect(kMaxMoneyHelper, contains('100,000'));
    });

    test('money ≤ 100,000: store deposit «المبلغ المؤكَّد» (optional)', () {
      expect(confirmedAmountError(''), isNull);
      expect(confirmedAmountError('250'), isNull);
      expect(confirmedAmountError('100001'), contains('100,000'));
    });
  });
}
