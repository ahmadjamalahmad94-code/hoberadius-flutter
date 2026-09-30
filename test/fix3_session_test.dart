// fix3 (app3) — session restore, saved grants and the /me failure path.
//
// F07 M1 / N-B1: during a cold start / reload / slow /api/admin/me the app
//   was PERMISSIVE (legacy) — a limited manager saw the full «المزيد» and
//   opened forbidden forms, which stayed open after /me arrived.
// F03 N3 / F07 N-C9: a network error or 5xx on /me at start-up deleted the
//   saved login. Only a real 401 may sign out.
// F07 N-C6: the router was rebuilt when the session restored, so a reload /
//   deep link landed on the dashboard.

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/app.dart';
import 'package:hoberadius_app/core/api/api_client.dart';
import 'package:hoberadius_app/core/api/api_endpoint_storage.dart';
import 'package:hoberadius_app/core/api/api_exception.dart';
import 'package:hoberadius_app/core/auth/auth_controller.dart';
import 'package:hoberadius_app/core/auth/permission_route_gate.dart';
import 'package:hoberadius_app/core/auth/permissions.dart';
import 'package:hoberadius_app/core/auth/permissions_cache.dart';
import 'package:hoberadius_app/core/auth/route_permissions.dart';
import 'package:hoberadius_app/core/auth/security_key_storage.dart';
import 'package:hoberadius_app/core/auth/token_storage.dart';
import 'package:hoberadius_app/core/router/app_router.dart';
import 'package:hoberadius_app/features/admin_control/application/admin_control_providers.dart';
import 'package:hoberadius_app/features/admins/presentation/admin_form_screen.dart';
import 'package:hoberadius_app/features/notifications/application/notifications_providers.dart';
import 'package:hoberadius_app/features/notifications/push/desktop_toast_bridge.dart';
import 'package:hoberadius_app/features/notifications/push/push_service.dart';
import 'package:hoberadius_app/features/provider_grants/application/provider_grants_provider.dart';
import 'package:hoberadius_app/features/provider_grants/domain/provider_grants_model.dart';
import 'package:hoberadius_app/features/shell/navigation_schema.dart';
import 'package:hoberadius_app/features/shell/session_gate.dart';
import 'package:hoberadius_app/features/shell/visible_nav_sections.dart';

import 'support/fake_api.dart';

Map<String, dynamic> me({
  int id = 7,
  bool owner = false,
  List<String> perms = const [],
}) =>
    {
      'admin': {'id': id, 'username': 'm$id', 'is_owner': owner},
      'permissions': perms,
      'grants': {
        'actions': <String, bool>{},
        'sections': <String, String>{},
        'view_all_subscribers': false,
      },
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
  for (var i = 0; i < 40; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

/// A saved copy of [payload] bound to [token] (what a previous run wrote).
Future<MemoryPermissionsCacheStorage> savedCopy(
  String token,
  Map<String, dynamic> payload,
) async {
  final storage = MemoryPermissionsCacheStorage();
  await PermissionsCache(storage).write(token, payload);
  return storage;
}

ProviderContainer _container({
  required _Tokens tokens,
  required RecordingAdapter adapter,
  required PermissionsCacheStorage cache,
}) {
  final c = ProviderContainer(
    overrides: [
      tokenStorageProvider.overrideWithValue(tokens),
      apiEndpointStorageProvider.overrideWithValue(_Endpoint()),
      securityKeyStorageProvider.overrideWithValue(_Keys()),
      apiClientProvider.overrideWithValue(fakeApiClient(adapter)),
      permissionsCacheStorageProvider.overrideWithValue(cache),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

final support = me(perms: ['users.view', 'dashboard.view']);

void main() {
  group('saved grants', () {
    test('bound to the token: another session never reuses them', () async {
      final storage = await savedCopy('tok-A', support);
      final cache = PermissionsCache(storage);
      expect(await cache.read('tok-A'), isNotNull);
      expect(await cache.read('tok-B'), isNull);
      expect(tokenFingerprint('tok-A'), isNot(tokenFingerprint('tok-B')));
      expect(tokenFingerprint('tok-A'), tokenFingerprint('tok-A'));
      // the token itself is never stored
      expect(storage.value, isNot(contains('tok-A')));
    });

    test('only the fields the app reads are kept', () {
      final kept = cacheableMe({
        ...support,
        'system': {'currency': 'ILS'},
        'token': 'secret',
        'tenant_id': 3,
      });
      expect(kept.keys, containsAll(['admin', 'grants', 'permissions']));
      expect(kept.containsKey('token'), isFalse);
      expect(kept['tenant_id'], 3);
    });

    test('a corrupt copy reads as none', () async {
      final storage = MemoryPermissionsCacheStorage('{not json');
      expect(await PermissionsCache(storage).read('t'), isNull);
    });
  });

  group('restore while /api/admin/me is pending', () {
    test('no saved copy → NOTHING allowed (not the old «allow all»)',
        () async {
      final hold = Completer<void>();
      final adapter = RecordingAdapter((_) => FakeResponse.ok(support))
        ..beforeRespond = (_) => hold.future;
      final c = _container(
        tokens: _Tokens('t1'),
        adapter: adapter,
        cache: MemoryPermissionsCacheStorage(),
      );
      c.read(authControllerProvider);
      await _settle();
      final p = c.read(permissionsProvider);
      final auth = c.read(authControllerProvider);
      expect(p.pending, isTrue);
      expect(p.legacy, isFalse);
      expect(auth.isAuthenticated, isTrue);
      expect(auth.restoring, isTrue);
      // the full «المزيد» of f07: none of it while unknown
      for (final path in ['/admins/new', '/subscribers/new', '/nas', '/tools']) {
        expect(routeAllowed(p, path), isFalse, reason: path);
      }
      expect(
        mobileDestinationsFor(p),
        [dashboardNavItem, moreNavItem],
      );
      // the router keeps the location; the shell shows «جارٍ التحقق»
      expect(PermissionRouteGate().redirect(p, '/admins/new'), isNull);
      expect(
        sessionContentPhase(auth, p),
        SessionContentPhase.checking,
      );
      hold.complete();
      await _settle();
      final after = c.read(permissionsProvider);
      expect(after.pending, isFalse);
      expect(after.can('users.view'), isTrue);
      expect(
        sessionContentPhase(c.read(authControllerProvider), after),
        SessionContentPhase.ready,
      );
    });

    test('saved copy of THIS admin → its own grants at once', () async {
      final hold = Completer<void>();
      final adapter = RecordingAdapter((_) => FakeResponse.ok(support))
        ..beforeRespond = (_) => hold.future;
      final c = _container(
        tokens: _Tokens('t2'),
        adapter: adapter,
        cache: await savedCopy('t2', support),
      );
      c.read(authControllerProvider);
      await _settle();
      final p = c.read(permissionsProvider);
      expect(p.provisional, isTrue);
      expect(p.can('users.view'), isTrue);
      expect(routeAllowed(p, '/subscribers'), isTrue);
      expect(routeAllowed(p, '/admins/new'), isFalse);
      expect(c.read(authControllerProvider).admin?.id, 7);
      hold.complete();
      await _settle();
      expect(c.read(permissionsProvider).provisional, isFalse);
    });

    test("another session's copy is ignored", () async {
      final hold = Completer<void>();
      final adapter = RecordingAdapter((_) => FakeResponse.ok(support))
        ..beforeRespond = (_) => hold.future;
      final c = _container(
        tokens: _Tokens('new-token'),
        adapter: adapter,
        cache: await savedCopy('old-token', me(id: 1, owner: true)),
      );
      c.read(authControllerProvider);
      await _settle();
      final p = c.read(permissionsProvider);
      expect(p.pending, isTrue);
      expect(p.isOwner, isFalse);
      hold.complete();
      await _settle();
    });

    test('a /me success saves the grants for the next start', () async {
      final storage = MemoryPermissionsCacheStorage();
      final c = _container(
        tokens: _Tokens('t3'),
        adapter: RecordingAdapter((_) => FakeResponse.ok(support)),
        cache: storage,
      );
      c.read(authControllerProvider);
      await _settle();
      final saved = await PermissionsCache(storage).read('t3');
      expect(saved?['permissions'], ['users.view', 'dashboard.view']);
    });
  });

  group('/api/admin/me fails at start-up', () {
    DioException offline(RecordedRequest r) => DioException.connectionError(
          requestOptions: RequestOptions(path: r.path),
          reason: 'offline',
        );

    test('network error: session KEPT on the saved grants + banner',
        () async {
      final tokens = _Tokens('t4');
      final adapter = RecordingAdapter((_) => FakeResponse.ok(support))
        ..beforeRespond = (r) async => throw offline(r);
      final c = _container(
        tokens: tokens,
        adapter: adapter,
        cache: await savedCopy('t4', support),
      );
      c.read(authControllerProvider);
      await _settle();
      final auth = c.read(authControllerProvider);
      expect(tokens.token, 't4', reason: 'the saved login is not deleted');
      expect(auth.isAuthenticated, isTrue);
      expect(auth.offline, isTrue);
      expect(auth.offlineMessage, isNotEmpty);
      final p = c.read(permissionsProvider);
      // cached grants — NOT every tab (f01 «all tabs when /me fails»)
      expect(p.provisional, isTrue);
      expect(routeAllowed(p, '/subscribers'), isTrue);
      expect(routeAllowed(p, '/nas'), isFalse);
      expect(
        mobileDestinationsFor(p).map((d) => d.path),
        isNot(contains('/sessions')),
      );
    });

    test('network error without a saved copy: retry screen, then recovers',
        () async {
      final tokens = _Tokens('t5');
      var down = true;
      final adapter = RecordingAdapter((_) => FakeResponse.ok(support))
        ..beforeRespond = (r) async {
          if (down) throw offline(r);
        };
      final c = _container(
        tokens: tokens,
        adapter: adapter,
        cache: MemoryPermissionsCacheStorage(),
      );
      c.read(authControllerProvider);
      await _settle();
      var auth = c.read(authControllerProvider);
      expect(tokens.token, 't5');
      expect(auth.offline, isTrue);
      expect(
        sessionContentPhase(auth, c.read(permissionsProvider)),
        SessionContentPhase.unverified,
      );
      down = false;
      await c.read(authControllerProvider.notifier).retrySession();
      await _settle();
      auth = c.read(authControllerProvider);
      expect(auth.offline, isFalse);
      expect(auth.isAuthenticated, isTrue);
      expect(c.read(permissionsProvider).can('users.view'), isTrue);
    });

    test('503 «الخادم مشغول» keeps the session too', () async {
      final tokens = _Tokens('t6');
      final c = _container(
        tokens: tokens,
        adapter: RecordingAdapter(
          (_) => FakeResponse.error(503, 'server_busy', 'الخادم مشغول.'),
        ),
        cache: await savedCopy('t6', support),
      );
      c.read(authControllerProvider);
      await _settle();
      expect(tokens.token, 't6');
      expect(c.read(authControllerProvider).offline, isTrue);
    });

    test('a real 401 signs out and forgets the saved grants', () async {
      final tokens = _Tokens('t7');
      final storage = await savedCopy('t7', support);
      final c = _container(
        tokens: tokens,
        adapter: RecordingAdapter(
          (_) => FakeResponse.error(401, 'token_revoked', 'انتهت الجلسة.'),
        ),
        cache: storage,
      );
      c.read(authControllerProvider);
      await _settle();
      final auth = c.read(authControllerProvider);
      expect(auth.isAuthenticated, isFalse);
      expect(tokens.token, isNull);
      expect(storage.value, isNull);
      expect(c.read(permissionsProvider).loaded, isFalse);
    });

    test('only 401 is a rejection', () {
      ApiException e(int? s) =>
          ApiException(code: 'x', message: 'm', status: s);
      expect(isSessionRejected(e(401)), isTrue);
      for (final s in [null, 403, 404, 429, 500, 502, 503, 504]) {
        expect(isSessionRejected(e(s)), isFalse, reason: '$s');
      }
    });
  });

  group('router across the restore (full app)', () {
    Future<(ProviderContainer, Completer<void>)> pumpApp(
      WidgetTester tester, {
      required Map<String, dynamic> grants,
      required String deepLink,
      PermissionsCacheStorage? cache,
    }) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final hold = Completer<void>();
      final tokenRead = Completer<String?>();
      final adapter = RecordingAdapter((r) {
        if (r.path == '/api/admin/me') return FakeResponse.ok(grants);
        return FakeResponse.ok({'items': <Object>[], 'total': 0});
      })
        ..beforeRespond = (r) async {
          if (r.path == '/api/admin/me') await hold.future;
        };
      final container = ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWithValue(_DelayedTokens(tokenRead)),
          apiEndpointStorageProvider.overrideWithValue(_Endpoint()),
          securityKeyStorageProvider.overrideWithValue(_Keys()),
          apiClientProvider.overrideWithValue(fakeApiClient(adapter)),
          permissionsCacheStorageProvider
              .overrideWithValue(cache ?? MemoryPermissionsCacheStorage()),
          unreadCountProvider.overrideWithValue(0),
          desktopToastBridgeProvider.overrideWith((ref) {}),
          pushBootstrapProvider.overrideWith((ref) {}),
          effectiveGrantsProvider.overrideWithValue(ProviderGrants.permissive),
          eCardsInUseProvider.overrideWith((ref) async => false),
          tenantCurrencyProvider.overrideWithValue('ILS'),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const HobeRadiusApp(),
        ),
      );
      // A reload / notification tap opens a deep link before the saved
      // token is even read.
      container.read(appRouterProvider).go(deepLink);
      await tester.pump();
      tokenRead.complete('tok');
      await tester.pump();
      await tester.pump();
      return (container, hold);
    }

    String location(ProviderContainer c) => c
        .read(appRouterProvider)
        .routerDelegate
        .currentConfiguration
        .uri
        .path;

    testWidgets('a forbidden deep link never builds its form; closed on /me',
        (tester) async {
      final (c, hold) = await pumpApp(
        tester,
        grants: support,
        deepLink: '/admins/new',
      );
      // /me pending, no saved copy: neutral state, the form is NOT built
      expect(find.byType(AdminFormScreen), findsNothing);
      expect(find.text('جارٍ التحقق من صلاحياتك…'), findsOneWidget);
      expect(location(c), '/admins/new');
      hold.complete();
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(location(c), '/no-access');
      expect(find.byType(AdminFormScreen), findsNothing);
    });

    testWidgets('a provisional screen the server refuses is closed',
        (tester) async {
      // the saved copy (stale) still allowed /admins/new; the server's
      // answer no longer does
      final (c, hold) = await pumpApp(
        tester,
        grants: support,
        deepLink: '/admins/new',
        cache: await savedCopy(
          'tok',
          me(perms: ['users.view', 'admins.create']),
        ),
      );
      expect(location(c), '/admins/new');
      hold.complete();
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(location(c), '/no-access');
    });

    testWidgets('reload keeps an allowed page (not the dashboard)',
        (tester) async {
      final (c, hold) = await pumpApp(
        tester,
        grants: support,
        deepLink: '/subscribers',
      );
      hold.complete();
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(location(c), '/subscribers');
      expect(c.read(appRouterProvider), same(c.read(appRouterProvider)));
    });
  });
}

class _DelayedTokens implements TokenStorage {
  _DelayedTokens(this._read);
  final Completer<String?> _read;
  @override
  Future<void> clear() async {}
  @override
  Future<String?> read() => _read.future;
  @override
  Future<void> write(String token) async {}
}
