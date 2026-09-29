// appperm — the app honours manager / distributor permissions (p01 D18,
// 4(a), 4(c); permmodel contract of /api/admin/me).
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/core/api/api_client.dart';
import 'package:hoberadius_app/core/api/api_endpoint_storage.dart';
import 'package:hoberadius_app/core/api/api_exception.dart';
import 'package:hoberadius_app/core/api/visible_error_message.dart';
import 'package:hoberadius_app/core/auth/auth_controller.dart';
import 'package:hoberadius_app/core/auth/permission_route_gate.dart';
import 'package:hoberadius_app/core/auth/permissions.dart';
import 'package:hoberadius_app/core/auth/route_permissions.dart';
import 'package:hoberadius_app/core/auth/security_key_storage.dart';
import 'package:hoberadius_app/core/auth/session_reset.dart';
import 'package:hoberadius_app/core/auth/token_storage.dart';
import 'package:hoberadius_app/features/admins/domain/admin_model.dart';
import 'package:hoberadius_app/features/cards/domain/card_item.dart';
import 'package:hoberadius_app/features/admins/presentation/admin_form_screen.dart';
import 'package:hoberadius_app/features/admins/presentation/admins_list_screen.dart';
import 'package:hoberadius_app/features/dashboard/presentation/dashboard_screen.dart';
import 'package:hoberadius_app/features/notifications/application/notifications_providers.dart';
import 'package:hoberadius_app/features/provider_grants/application/nav_visibility.dart';
import 'package:hoberadius_app/features/provider_grants/domain/provider_grants_model.dart';
import 'package:hoberadius_app/features/sessions/presentation/sessions_list_screen.dart';
import 'package:hoberadius_app/features/shell/navigation_schema.dart';
import 'package:hoberadius_app/features/shell/visible_nav_sections.dart';
import 'package:hoberadius_app/features/subscribers/presentation/subscribers_list_screen.dart';
import 'package:hoberadius_app/features/subscribers/presentation/widgets/subscriber_form_sections.dart';

import 'support/fake_api.dart';

/// A `/api/admin/me` payload of the permmodel contract.
Map<String, dynamic> me({
  int id = 7,
  bool owner = false,
  bool coOwner = false,
  bool originalOwner = false,
  bool superAdmin = false,
  List<String> perms = const [],
  Map<String, bool> actions = const {},
  Map<String, String> sections = const {},
  bool viewAll = false,
  Map<String, dynamic> extraAdmin = const {},
}) =>
    {
      'admin': {
        'id': id,
        'username': 'm$id',
        'is_owner': owner || coOwner,
        'is_co_owner': coOwner,
        'is_original_owner': originalOwner,
        'is_super_admin': superAdmin,
        ...extraAdmin,
      },
      'permissions': perms,
      'grants': {
        'actions': actions,
        'sections': sections,
        'view_all_subscribers': viewAll,
      },
    };

AppPermissions perm(Map<String, dynamic> data) => AppPermissions.fromMe(data);

/// Viewer: «لوحة التحكم» only (the p01 probe manager).
final viewer = perm(me(perms: ['dashboard.view']));

/// A manager who may view and create subscribers.
final creator = perm(
  me(
    perms: ['users.view', 'users.create', 'users.edit'],
    actions: {'subscriber.create': true},
  ),
);

final owner = perm(me(id: 1, owner: true, originalOwner: true));
final coOwner = perm(me(id: 2, coOwner: true));

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

void main() {
  group('AppPermissions — /api/admin/me contract', () {
    test(
        'an older server (no grants, no is_owner) = legacy: everything allowed',
        () {
      final p = AppPermissions.fromMe({
        'admin': {'id': 3, 'username': 'x', 'is_super_admin': false},
        'permissions': ['dashboard.view'],
      });
      expect(p.legacy, isTrue);
      expect(p.can('users.create'), isTrue);
      expect(p.canAction('subscriber.create'), isTrue);
      expect(p.canSection('subscribers'), isTrue);
      expect(p.isOwnerLike, isTrue, reason: 'old behaviour: show everything');
      expect(p.supportsOwnerContract, isFalse);
      expect(routeDenial(p, '/admin-control'), isNull);
    });

    test('signed out / not loaded yet is permissive (never hides by accident)',
        () {
      expect(AppPermissions.unknown.can('anything'), isTrue);
      expect(AppPermissions.unknown.loaded, isFalse);
    });

    test('owner and co-owner bypass every check', () {
      for (final p in [owner, coOwner]) {
        expect(p.legacy, isFalse);
        expect(p.isOwnerLike, isTrue);
        expect(p.can('settings.edit'), isTrue);
        expect(p.canAction('session.disconnect'), isTrue);
        expect(p.sectionState('subscribers'), kSectionOpen);
      }
      expect(coOwner.isCoOwner, isTrue);
      expect(owner.isOriginalOwner, isTrue);
    });

    test('can / canAny read the effective RBAC keys', () {
      expect(creator.can('users.create'), isTrue);
      expect(creator.can('users.delete'), isFalse);
      expect(creator.canAny(['users.delete', 'users.view']), isTrue);
      expect(creator.canAny(const []), isTrue);
      expect(creator.isOwnerLike, isFalse);
    });

    test('canAction: the server decision wins, else the RBAC fallback', () {
      final p = perm(
        me(
          perms: ['online.disconnect', 'users.extend'],
          actions: {'subscriber.extend': false},
        ),
      );
      expect(
        p.canAction('subscriber.extend'),
        isFalse,
        reason: 'server says no',
      );
      expect(p.canAction('session.disconnect'), isTrue, reason: 'derived');
      expect(p.canAction('session.lock_mac'), isFalse);
      expect(p.canAction('unknown.future_action'), isTrue);
    });

    test('a locked section is read-only, a hidden one invisible', () {
      final p = perm(
        me(
          perms: ['users.view', 'users.create', 'cards.view'],
          actions: {'subscriber.create': true},
          sections: {'subscribers': 'locked', 'cards': 'hidden'},
        ),
      );
      expect(p.canSection('subscribers'), isTrue);
      expect(p.canWriteSection('subscribers'), isFalse);
      expect(
        p.canAction('subscriber.create'),
        isFalse,
        reason: 'granted but the section is locked (4(a))',
      );
      expect(p.canSection('cards'), isFalse);
      expect(p.deniedReason(section: 'subscribers'), contains('للعرض فقط'));
      expect(p.deniedReason(section: 'cards'), contains('مخفيّ'));
    });

    test('deniedReason names the missing permission in Arabic', () {
      expect(viewer.deniedReason(perm: 'users.create'), contains('إنشاء'));
      expect(viewer.deniedReason(ownerOnly: true), contains('مالك'));
    });

    test('a distributor login is recognised when the server flags it', () {
      final d = perm(me(extraAdmin: {'is_distributor': true}));
      expect(d.isDistributor, isTrue);
      expect(perm(me(extraAdmin: {'distributor_id': 4})).isDistributor, isTrue);
      expect(creator.isDistributor, isFalse);
    });
  });

  group('screen × permission matrix (routes)', () {
    test('literal segments beat :params (/subscribers/new is the form)', () {
      expect(
        routeRequirementFor('/subscribers/new')!.action,
        'subscriber.create',
      );
      expect(
        routeRequirementFor('/subscribers/ali')!.anyOf,
        ['users.edit'],
      );
      expect(
        routeRequirementFor('/subscribers/ali/360')!.anyOf,
        ['users.view'],
      );
      expect(routeRequirementFor('/'), isNull);
    });

    test('viewer: only the dashboard, account and notifications open', () {
      for (final path in ['/', '/account', '/notifications', '/more']) {
        expect(routeDenial(viewer, path), isNull, reason: path);
      }
      for (final path in [
        '/subscribers',
        '/subscribers/new',
        '/sessions',
        '/cards',
        '/cards/new',
        '/plans',
        '/nas',
        '/revenue',
        '/admins',
        '/backups',
        '/admin-control',
      ]) {
        expect(routeDenial(viewer, path), isNotNull, reason: path);
      }
    });

    test('the create form needs users.create + the action + an open section',
        () {
      expect(routeDenial(creator, '/subscribers/new'), isNull);
      final noCreate = perm(me(perms: ['users.view']));
      expect(routeDenial(noCreate, '/subscribers/new'), contains('إنشاء'));
      final actionOff = perm(
        me(
          perms: ['users.view', 'users.create'],
          actions: {'subscriber.create': false},
        ),
      );
      expect(routeDenial(actionOff, '/subscribers/new'), isNotNull);
    });

    test('owner-only screens: settings, backups, collection', () {
      final superUser = perm(
        me(
          superAdmin: true,
          perms: [
            'settings.view',
            'settings.edit',
            'admins.view',
            'reports.finance',
          ],
        ),
      );
      expect(routeDenial(superUser, '/admin-control'), contains('مالك'));
      expect(routeDenial(superUser, '/backups'), isNotNull);
      expect(routeDenial(superUser, '/payment-collection'), isNotNull);
      expect(routeDenial(coOwner, '/admin-control'), isNull);
      expect(routeDenial(owner, '/backups'), isNull);
    });

    test('managers / roles: owner-like or the delegated admins.* keys', () {
      expect(routeDenial(creator, '/admins'), isNotNull);
      final delegated = perm(me(perms: ['admins.view', 'admins.edit']));
      expect(routeDenial(delegated, '/admins'), isNull);
      expect(routeDenial(delegated, '/admins/3'), isNull);
      expect(routeDenial(delegated, '/admins/new'), isNotNull);
      expect(routeDenial(coOwner, '/admins/new'), isNull);
    });

    test('distributor: own subscribers, cards/batches, finance — nothing else',
        () {
      final d = perm(
        me(
          perms: [
            'users.view',
            'users.create',
            'cards.view',
            'reports.finance',
          ],
          actions: {'subscriber.create': true},
          extraAdmin: {'is_distributor': true},
        ),
      );
      for (final path in [
        '/subscribers',
        '/subscribers/new',
        '/cards',
        '/cards/batches/5',
        '/loans',
        '/distributors/9',
        '/account',
      ]) {
        expect(routeDenial(d, path), isNull, reason: path);
      }
      for (final path in [
        '/plans',
        '/nas',
        '/revenue',
        '/distributors',
        '/cards/new',
        '/tickets',
      ]) {
        expect(routeDenial(d, path), isNotNull, reason: path);
      }
    });
  });

  group('router gate', () {
    test('refuses a screen before it opens → /no-access?from=', () {
      final gate = PermissionRouteGate();
      expect(gate.redirect(viewer, '/'), isNull);
      final to = gate.redirect(viewer, '/subscribers/new');
      expect(to, startsWith('/no-access'));
      expect(Uri.parse(to!).queryParameters['from'], '/subscribers/new');
      expect(gate.redirect(viewer, '/no-access'), isNull);
    });

    test('never evicts the screen on display (a half-filled form)', () {
      final gate = PermissionRouteGate();
      expect(gate.redirect(creator, '/subscribers/new'), isNull);
      // A 403 re-read the grants: users.create was revoked meanwhile. The
      // router re-runs redirect for the SAME location — it must stay.
      expect(gate.redirect(viewer, '/subscribers/new'), isNull);
      // A NEW navigation is refused.
      expect(gate.redirect(viewer, '/cards'), isNotNull);
    });
  });

  group('navigation', () {
    final all = gatedNavSections(ProviderGrants.permissive);

    test('viewer: every section that needs a permission disappears', () {
      final visible = filterNavSectionsByPermissions(all, viewer);
      final paths = [
        for (final s in visible)
          for (final i in s.items) i.item.path,
      ];
      expect(paths, ['/account']);
    });

    test('legacy server: the whole menu, as before', () {
      final legacy = AppPermissions.fromMe({
        'admin': {'id': 1},
      });
      expect(filterNavSectionsByPermissions(all, legacy).length, all.length);
    });

    test('bottom tabs follow the permissions; dashboard + «المزيد» stay', () {
      expect(
        mobileDestinationsFor(viewer).map((d) => d.path),
        ['/', '/more'],
      );
      final sub = perm(me(perms: ['users.view', 'online.view']));
      expect(
        mobileDestinationsFor(sub).map((d) => d.path),
        ['/', '/subscribers', '/sessions', '/more'],
      );
      final dests = mobileDestinationsFor(viewer);
      expect(mobileNavIndexForLocation('/more', dests), 1);
      expect(mobileTitleForLocation('/', 0, dests), 'لوحة التحكم');
    });
  });

  group('buttons / forms', () {
    test('«مشترك جديد» only when the save would be accepted', () {
      expect(subscriberCreateDenial(creator), isNull);
      expect(subscriberCreateDenial(viewer), contains('إنشاء'));
      final locked = perm(
        me(
          perms: ['users.view', 'users.create'],
          actions: {'subscriber.create': true},
          sections: {'subscribers': 'locked'},
        ),
      );
      expect(subscriberCreateDenial(locked), contains('للعرض فقط'));
    });

    test('«المدير المسؤول»: owner-like or admins.view only', () {
      expect(canPickResponsibleManager(owner), isTrue);
      expect(canPickResponsibleManager(coOwner), isTrue);
      expect(canPickResponsibleManager(creator), isFalse);
      expect(
        canPickResponsibleManager(perm(me(perms: ['admins.view']))),
        isTrue,
      );
      expect(
        canPickResponsibleManager(
          AppPermissions.fromMe({
            'admin': {'id': 1},
          }),
        ),
        isTrue,
        reason: 'legacy server keeps the field',
      );
    });

    test('dashboard tiles follow the screens they open', () {
      final v = DashboardVisibility(viewer);
      expect(
        [v.subscribers, v.online, v.plans, v.cards, v.nas],
        everyElement(false),
      );
      final s =
          DashboardVisibility(perm(me(perms: ['users.view', 'cards.view'])));
      expect(s.subscribers, isTrue);
      expect(s.cards, isTrue);
      expect(s.plans, isFalse);
      expect(s.canOpen('admin-control'), isFalse);
      expect(DashboardVisibility(owner).canOpen('admin-control'), isTrue);
    });

    test('live-session actions follow online.* / users.temp_speed', () {
      final a = SessionActionPermissions(
        perm(me(perms: ['online.view', 'online.disconnect'])),
      );
      expect(a.disconnect, isTrue);
      expect(a.lockMac, isFalse);
      expect(a.lockIp, isFalse);
      expect(a.tempSpeed, isFalse);
    });
  });

  group('masked card passwords (permguard)', () {
    test('«••••••» is recognised and shown as «••••», never as a password', () {
      final c =
          CardItem.fromJson({'id': 1, 'username': 'c1', 'password': '••••••'});
      expect(c.passwordMasked, isTrue);
      expect(cardPasswordDisplay(c.password), '••••');
      expect(isMaskedCardPassword('******'), isTrue);
      expect(isMaskedCardPassword('123456'), isFalse);
      expect(isMaskedCardPassword(''), isFalse);
      expect(cardPasswordDisplay('4821'), '4821');
    });

    test('printing needs cards.print (the server unmasks only then)', () {
      final viewOnly = perm(me(perms: ['cards.view']));
      expect(routeDenial(viewOnly, '/cards/batches/3'), isNull);
      expect(routeDenial(viewOnly, '/cards/batches/3/print'), isNotNull);
      final printer = perm(me(perms: ['cards.view', 'cards.print']));
      expect(routeDenial(printer, '/cards/batches/3/print'), isNull);
    });
  });

  group('co-owner / super-user toggles', () {
    final plainRow = Admin(id: 9, username: 'mgr');
    final originalRow = Admin(id: 1, username: 'owner', isOriginalOwner: true);

    test('shown only to the owner or a co-owner', () {
      expect(
        adminOwnerFlagsFor(owner, plainRow),
        (superUser: true, coOwner: true),
      );
      expect(
        adminOwnerFlagsFor(coOwner, plainRow),
        (superUser: true, coOwner: true),
      );
      final delegated = perm(me(perms: ['admins.view', 'admins.edit']));
      expect(
        adminOwnerFlagsFor(delegated, plainRow),
        (superUser: false, coOwner: false),
      );
    });

    test("never on the original owner's row", () {
      expect(
        adminOwnerFlagsFor(coOwner, originalRow),
        (superUser: false, coOwner: false),
      );
      expect(
        adminOwnerFlagsFor(owner, originalRow),
        (superUser: false, coOwner: false),
      );
    });

    test('legacy server: the old «مدير عام» switch, no co-owner', () {
      final legacy = AppPermissions.fromMe({
        'admin': {'id': 1},
      });
      expect(
        adminOwnerFlagsFor(legacy, plainRow),
        (superUser: true, coOwner: false),
      );
    });

    test('the body carries owner flags only when owner-like AND changed', () {
      final loaded = Admin(id: 9, username: 'mgr', roleId: 3);
      final edited = loaded.copyWith(fullName: 'x');
      expect(
        edited.toBody(original: loaded).containsKey('is_super_admin'),
        isFalse,
      );
      final promoted = loaded.copyWith(isSuperAdmin: true, isCoOwner: true);
      final body = promoted.toBody(original: loaded, coOwnerFlag: true);
      expect(body['is_super_admin'], isTrue);
      expect(body['is_co_owner'], isTrue);
      // A manager holding admins.edit never sends them.
      final mgrBody = promoted.toBody(original: loaded, ownerFlags: false);
      expect(mgrBody.containsKey('is_super_admin'), isFalse);
      expect(mgrBody.containsKey('is_co_owner'), isFalse);
      // Create: sent only when switched on.
      expect(
        Admin(username: 'n').toBody().containsKey('is_super_admin'),
        isFalse,
      );
    });

    test('Admin.fromJson reads the owner flags', () {
      final a = Admin.fromJson({
        'id': 2,
        'username': 'p',
        'is_co_owner': true,
        'is_original_owner': false,
      });
      expect(a.isCoOwner, isTrue);
      expect(a.isOwner, isTrue);
    });

    test('a manager row opens only when its save can succeed', () {
      final delegated = perm(me(id: 5, perms: ['admins.view', 'admins.edit']));
      expect(canOpenAdminRow(delegated, plainRow), isTrue);
      expect(canOpenAdminRow(delegated, originalRow), isFalse);
      expect(
        canOpenAdminRow(
          delegated,
          Admin(id: 2, username: 'partner', isCoOwner: true, isOwner: true),
        ),
        isFalse,
      );
      expect(canOpenAdminRow(coOwner, originalRow), isFalse);
      expect(canOpenAdminRow(owner, originalRow), isTrue, reason: 'himself');
      expect(canOpenAdminRow(viewer, plainRow), isFalse);
    });
  });

  group('403 that still happens', () {
    test('keeps the server Arabic reason and says the input is kept', () {
      final e = ApiException(
        code: 'forbidden',
        message: 'قسم «المشتركون» مقفول — لا تملك صلاحية التعديل.',
        status: 403,
      );
      final text = formSaveErrorMessage(e);
      expect(text, startsWith('قسم «المشتركون» مقفول'));
      expect(text, contains('بياناتك باقية'));
      final v =
          ApiException(code: 'validation_error', message: 'مطلوب', status: 422);
      expect(formSaveErrorMessage(v), 'مطلوب');
    });

    test('permguard details.requires names the missing permission', () {
      final e = ApiException(
        code: 'forbidden',
        message: 'ليس لديك صلاحية لتنفيذ هذا الإجراء.',
        status: 403,
        details: {
          'endpoint': 'v1.payments_list',
          'requires': 'users.payments|reports.finance',
        },
      );
      final text = visibleErrorMessage(e);
      expect(text, startsWith('ليس لديك صلاحية'));
      expect(text, contains('الصلاحية المطلوبة'));
      expect(text, contains(' أو '));
      expect(
        forbiddenRequirementLabel({'requires': '__super__'}),
        contains('المالك'),
      );
      expect(
        forbiddenRequirementLabel({'requires': 'web:users_create'}),
        isNull,
      );
      expect(
        forbiddenRequirementLabel({'permission': 'users.create'}),
        isNotNull,
      );
      // No details → the server text alone (older servers).
      expect(
        visibleErrorMessage(
          ApiException(code: 'forbidden', message: 'ممنوع.', status: 403),
        ),
        'ممنوع.',
      );
    });

    test('a 403 re-reads /api/admin/me (throttled), never loops', () async {
      var meCalls = 0;
      final adapter = RecordingAdapter((r) {
        if (r.path == '/api/admin/me') {
          meCalls++;
          return FakeResponse.ok(me(perms: ['users.view']));
        }
        return FakeResponse.error(403, 'forbidden', 'ليس لديك صلاحية.');
      });
      final container = ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWithValue(_Tokens('t')),
          apiEndpointStorageProvider.overrideWithValue(_Endpoint()),
          securityKeyStorageProvider.overrideWithValue(_Keys()),
          apiClientProvider.overrideWithValue(fakeApiClient(adapter)),
        ],
      );
      addTearDown(container.dispose);
      container.read(authControllerProvider);
      await _settle();
      expect(meCalls, 1, reason: 'session restore');
      expect(container.read(permissionsProvider).can('users.view'), isTrue);
      expect(container.read(permissionsProvider).can('users.create'), isFalse);

      // Force past the throttle window, then a burst of 403s = ONE /me.
      container.read(permissionsProvider.notifier).debugExpireThrottle();
      final api = container.read(apiClientProvider);
      for (var i = 0; i < 3; i++) {
        await expectLater(
          api.post('/api/v1/accounts', body: {'username': 'x$i'}),
          throwsA(isA<ApiException>()),
        );
      }
      await _settle();
      expect(meCalls, 2);
    });
  });

  group('account switch', () {
    test('sign-out clears the grants and app-wide cached state', () async {
      var who = 7;
      final adapter = RecordingAdapter((r) {
        if (r.path == '/api/admin/me') {
          return FakeResponse.ok(me(id: who, perms: ['users.view']));
        }
        if (r.path == '/api/admin/login') {
          return FakeResponse.ok({
            'token': 'tok2',
            ...me(id: 8, perms: ['cards.view']),
          });
        }
        if (r.path.startsWith('/api/v1/notifications')) {
          return FakeResponse.ok({
            'items': [
              {'id': who, 'title': 'n$who', 'body': '', 'created_at': null},
            ],
            'unread_count': 1,
          });
        }
        return FakeResponse.ok(<String, dynamic>{});
      });
      final tokens = _Tokens('tok1');
      final container = ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWithValue(tokens),
          apiEndpointStorageProvider.overrideWithValue(_Endpoint()),
          securityKeyStorageProvider.overrideWithValue(_Keys()),
          apiClientProvider.overrideWithValue(fakeApiClient(adapter)),
        ],
      );
      addTearDown(container.dispose);
      container.read(authControllerProvider);
      await _settle();
      expect(container.read(permissionsProvider).adminId, 7);
      // An app-wide provider (not autoDispose) loaded under account 7.
      final sub = container.listen(notificationCenterProvider, (_, __) {});
      await _settle();
      expect(container.read(notificationCenterProvider).valueOrNull, isNotNull);
      var rebuilt = 0;
      container.listen(
        notificationCenterProvider,
        (_, __) => rebuilt++,
      );

      await container.read(authControllerProvider.notifier).logout();
      await _settle();
      expect(container.read(permissionsProvider).loaded, isFalse);
      expect(rebuilt, greaterThan(0), reason: 'invalidated at sign-out');

      who = 8;
      await container.read(authControllerProvider.notifier).login(
            baseUrl: 'http://127.0.0.1:5000',
            username: 'm8',
            password: 'x',
          );
      await _settle();
      final p = container.read(permissionsProvider);
      expect(p.adminId, 8);
      expect(p.can('users.view'), isFalse, reason: 'nothing of account 7');
      expect(p.can('cards.view'), isTrue);
      sub.close();
    });

    test('the reset list covers every app-wide data holder', () {
      expect(kSessionScopedProviders, contains(notificationCenterProvider));
      expect(kSessionScopedProviders, contains(notificationsPollerProvider));
      expect(kSessionScopedProviders.length, greaterThanOrEqualTo(8));
    });

    test('an older login answer (no grants) reads /me, still legacy', () async {
      final adapter = RecordingAdapter((r) {
        if (r.path == '/api/admin/login') {
          return FakeResponse.ok({
            'token': 't',
            'admin': {'id': 3, 'username': 'old'},
            'permissions': ['dashboard.view'],
          });
        }
        if (r.path == '/api/admin/me') {
          return FakeResponse.ok({
            'admin': {'id': 3, 'username': 'old'},
            'permissions': ['dashboard.view'],
          });
        }
        return FakeResponse.ok(<String, dynamic>{});
      });
      final container = ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWithValue(_Tokens(null)),
          apiEndpointStorageProvider.overrideWithValue(_Endpoint()),
          securityKeyStorageProvider.overrideWithValue(_Keys()),
          apiClientProvider.overrideWithValue(fakeApiClient(adapter)),
        ],
      );
      addTearDown(container.dispose);
      container.read(authControllerProvider);
      await _settle();
      await container.read(authControllerProvider.notifier).login(
            baseUrl: 'http://127.0.0.1:5000',
            username: 'old',
            password: 'x',
          );
      await _settle();
      final p = container.read(permissionsProvider);
      expect(container.read(authControllerProvider).error, isNull);
      expect(p.loaded, isTrue);
      expect(p.legacy, isTrue);
      expect(p.can('users.create'), isTrue);
    });
  });
}
