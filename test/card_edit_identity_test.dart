// «تعديل بيانات الكرت» (owner 2026-10-05): the card number and/or password,
// free text, never generated. Required entry points: the card checker
// (فحص الكرت) and the «المزيد» sheet of an online CARD tile.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/core/api/api_client.dart';
import 'package:hoberadius_app/core/auth/permissions.dart';
import 'package:hoberadius_app/features/cards/data/cards_repository.dart';
import 'package:hoberadius_app/features/cards/domain/card_model.dart';
import 'package:hoberadius_app/features/cards/presentation/card_checker_screen.dart';
import 'package:hoberadius_app/features/cards/presentation/widgets/card_identity_dialog.dart';
import 'package:hoberadius_app/features/sessions/domain/session_model.dart';
import 'package:hoberadius_app/features/sessions/presentation/sessions_list_screen.dart';

import 'support/fake_api.dart';

({CardIdentityDraft? draft, String? error}) _read(
  String u,
  String p, {
  bool passwordless = false,
}) =>
    readCardIdentityInput(
      currentUsername: '316240',
      currentPassword: '111111',
      typedUsername: u,
      typedPassword: p,
      passwordless: passwordless,
    );

Map<String, dynamic> _checkCard({String username = '316240'}) => {
      'exists': true,
      'status': 'active',
      'id': 7,
      'username': username,
      'has_password': true,
      'login_without_password': false,
      'operations': {
        'can_reset_usage': true,
        'can_disable': true,
        'can_edit_identity': true,
      },
    };

Map<String, dynamic> _patchResult(Map<String, dynamic> body) {
  final newName = (body['username'] ?? '316240').toString().toLowerCase();
  return {
    'action': 'update_identity',
    'card': _checkCard(username: newName),
    'changed': true,
    'renamed': body.containsKey('username'),
    'password_changed': body.containsKey('password'),
    'old_username': '316240',
    'username': newName,
    'kicked': true,
  };
}

RecordingAdapter _api() => RecordingAdapter((r) {
      if (r.path == '/api/v1/sessions/online') {
        return FakeResponse.ok({
          'items': [
            {
              'username': '316240',
              'session_id': 's-card',
              'user_type': 'card',
              'card_id': 7,
              'state': 'online',
              'nas_ip_address': '10.0.0.1',
              'framed_ip_address': '10.5.0.10',
              'calling_station_id': '11:22:33:44:55:66',
              'started_at': '2026-09-28T10:00:00Z',
              'session_time': 600,
            },
          ],
          'total': 1,
          'has_more': false,
        });
      }
      if (r.method == 'GET' && r.path == '/api/v1/cards/7') {
        return FakeResponse.ok(
            {'id': 7, 'username': '316240', 'password': '111111'},);
      }
      if (r.method == 'GET' && r.path == '/api/v1/cards/check') {
        return FakeResponse.ok({'card': _checkCard()});
      }
      if (r.method == 'PATCH' && r.path == '/api/v1/cards/7') {
        return FakeResponse.ok(_patchResult(r.jsonBody));
      }
      return FakeResponse.ok({'items': <dynamic>[]});
    });

Future<void> _frames(WidgetTester tester, [int n = 12]) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _pump(
    WidgetTester tester, RecordingAdapter a, Widget child,) async {
  tester.view.physicalSize = const Size(400, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [apiClientProvider.overrideWithValue(fakeApiClient(a))],
      child: MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
  await _frames(tester);
}

Finder _btn(String label) => find.ancestor(
      of: find.text(label),
      matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
    );

Finder get _userField => find.byKey(const ValueKey('card-identity-username'));
Finder get _pwField => find.byKey(const ValueKey('card-identity-password'));
Finder get _save => find.byKey(const ValueKey('card-identity-save'));

bool _saveEnabled(WidgetTester tester) =>
    tester.widget<ElevatedButton>(_save).onPressed != null;

void main() {
  group('readCardIdentityInput', () {
    test('number only', () {
      final r = _read('ZX-1001', '111111');
      expect(r.error, isNull);
      expect(r.draft!.toJson(), {'username': 'ZX-1001'});
    });

    test('password only', () {
      final r = _read('316240', 'NewPw9');
      expect(r.draft!.toJson(), {'password': 'NewPw9'});
    });

    test('both', () {
      final r = _read('55667788', 'NewPw9');
      expect(r.draft!.toJson(), {'username': '55667788', 'password': 'NewPw9'});
    });

    test('empty password = unchanged, nothing generated', () {
      final r = _read('316240', '');
      expect(r.error, isNull);
      expect(r.draft!.isEmpty, isTrue);
      expect(r.draft!.toJson(), isEmpty);
      final n = _read('99887766', '   ');
      expect(n.draft!.toJson(), {'username': '99887766'});
    });

    test('same number in another case is not a change', () {
      expect(_read('316240'.toUpperCase(), '111111').draft!.isEmpty, isTrue);
    });

    test('Arabic-Indic digits are read as Latin', () {
      expect(_read('٥٥٥١٢٣', '').draft!.username, '555123');
      expect(_read('316240', '٩٩٨٨').draft!.password, '9988');
    });

    test('invalid input → Arabic error', () {
      expect(_read('a b', '').error, contains('رقم الكرت'));
      expect(_read('ab', '').error, contains('رقم الكرت'));
      expect(_read('بطاقة', '').error, contains('رقم الكرت'));
      expect(_read('rtr-x1', '').error, contains('rtr-'));
      expect(_read('316240', 'a b').error, contains('مسافات'));
      expect(_read('316240', 'x' * 65).error, contains('64'));
    });

    test('«رقم فقط» batch: the password is never sent', () {
      final r = _read('316240', 'NewPw9', passwordless: true);
      expect(r.draft!.isEmpty, isTrue);
    });
  });

  test('repository: PATCH /cards/<id> with only the changed fields', () async {
    final a = _api();
    final repo = CardsRepository(fakeApiClient(a));
    final res = await repo.updateCardIdentity(
      7,
      const CardIdentityDraft(username: 'ZX-1001'),
    );
    final req = a.where('PATCH', '/api/v1/cards/7').single;
    expect(req.jsonBody, {'username': 'ZX-1001'});
    expect(res.renamed, isTrue);
    expect(res.passwordChanged, isFalse);
    expect(res.card.username, 'zx-1001');
    expect(res.message, contains('من 316240 إلى zx-1001'));
    expect(res.message, contains('قُطعت الجلسة'));

    await repo.updateCardIdentity(7, const CardIdentityDraft(password: 'P9'));
    expect(
        a.where('PATCH', '/api/v1/cards/7').last.jsonBody, {'password': 'P9'},);
    expect(await repo.cardPassword(7), '111111');
  });

  test('repository: a masked password prefills nothing', () async {
    final a = RecordingAdapter(
      (r) => FakeResponse.ok({'id': 7, 'password': '••••••'}),
    );
    expect(await CardsRepository(fakeApiClient(a)).cardPassword(7), '');
  });

  test('model: can_edit_identity + login_without_password parsed', () {
    final c = CardCheckResult.fromJson({
      ..._checkCard(),
      'login_without_password': true,
    });
    expect(c.operations.canEditIdentity, isTrue);
    expect(c.loginWithoutPassword, isTrue);
    expect(
        CardCheckResult.fromJson(const {}).operations.canEditIdentity, isFalse,);
  });

  test('«المزيد»: offered on a card tile with cards.verify only', () {
    OnlineSession s(Map<String, dynamic> j) => OnlineSession.fromJson(j);
    final card = s({'username': 'c1', 'user_type': 'card', 'card_id': 7});
    final sub = s({'username': 'u1', 'user_type': 'user'});
    const all = SessionMorePermissions(
      acts: SessionActionPermissions(AppPermissions.unknown),
      cardCheck: true,
      cardOps: true,
    );
    expect(sessionMoreActions(card, all),
        contains(SessionMoreAction.editCardIdentity),);
    expect(sessionMoreActions(sub, all),
        isNot(contains(SessionMoreAction.editCardIdentity)),);
    const noOps = SessionMorePermissions(
      acts: SessionActionPermissions(AppPermissions.unknown),
      cardCheck: true,
    );
    expect(
      sessionMoreActions(card, noOps),
      isNot(contains(SessionMoreAction.editCardIdentity)),
    );
  });

  testWidgets('dialog: prefilled, Save disabled until a real change',
      (tester) async {
    CardIdentityDraft? got;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () async => got = await showCardIdentityDialog(
              ctx,
              username: '316240',
              password: '111111',
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(_userField).controller!.text, '316240');
    expect(tester.widget<TextField>(_pwField).controller!.text, '111111');
    expect(_saveEnabled(tester), isFalse);
    // clearing the password = «leave as is» — still nothing to save
    await tester.enterText(_pwField, '');
    await tester.pump();
    expect(_saveEnabled(tester), isFalse);
    await tester.enterText(_userField, '٧٧٧٨٨٨');
    await tester.pump();
    expect(_saveEnabled(tester), isTrue);
    await tester.tap(_save);
    await tester.pumpAndSettle();
    expect(got!.toJson(), {'username': '777888'});
  });

  testWidgets('dialog: «رقم فقط» locks the password field', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () => showCardIdentityDialog(
              ctx,
              username: '316240',
              passwordless: true,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(_pwField).enabled, isFalse);
    expect(find.text('حزمة «رقم فقط» — بلا كلمة مرور'), findsOneWidget);
  });

  testWidgets('online card tile «المزيد» → edit number only → PATCH',
      (tester) async {
    final a = _api();
    await _pump(tester, a, const SessionsListScreen());
    await tester.tap(_btn('المزيد'));
    await _frames(tester, 6);
    expect(find.text('تعديل بيانات الكرت'), findsOneWidget);
    await tester.tap(find.text('تعديل بيانات الكرت'));
    await _frames(tester, 6);
    expect(tester.widget<TextField>(_userField).controller!.text, '316240');
    expect(tester.widget<TextField>(_pwField).controller!.text, '111111');
    await tester.enterText(_userField, '44332211');
    await tester.pump();
    await tester.tap(_save);
    await _frames(tester, 6);
    final req = a.where('PATCH', '/api/v1/cards/7').single;
    expect(req.jsonBody, {'username': '44332211'});
    expect(find.textContaining('من 316240 إلى 44332211'), findsOneWidget);
  });

  testWidgets('card checker → edit password only → PATCH, result shown',
      (tester) async {
    final a = _api();
    await _pump(tester, a, const CardCheckerScreen(initialQuery: '316240'));
    expect(find.text('تعديل بيانات الكرت'), findsOneWidget);
    await tester.tap(find.text('تعديل بيانات الكرت'));
    await _frames(tester, 6);
    await tester.enterText(_pwField, 'Np4455');
    await tester.pump();
    await tester.tap(_save);
    await _frames(tester, 6);
    final req = a.where('PATCH', '/api/v1/cards/7').single;
    expect(req.jsonBody, {'password': 'Np4455'});
    expect(find.textContaining('تم تغيير كلمة المرور'), findsOneWidget);
  });

  testWidgets('card checker: server refusal (409) is shown in Arabic',
      (tester) async {
    final a = _api();
    final ok = a.handler;
    a.handler = (r) => r.method == 'PATCH'
        ? FakeResponse.error(409, 'conflict',
            'الاسم مستخدم: «123456» رقمُ بطاقةٍ أو اسمُ مشتركٍ آخر.',)
        : ok(r);
    await _pump(tester, a, const CardCheckerScreen(initialQuery: '316240'));
    await tester.tap(find.text('تعديل بيانات الكرت'));
    await _frames(tester, 6);
    await tester.enterText(_userField, '123456');
    await tester.pump();
    await tester.tap(_save);
    await _frames(tester, 6);
    expect(find.textContaining('الاسم مستخدم'), findsWidgets);
  });
}
