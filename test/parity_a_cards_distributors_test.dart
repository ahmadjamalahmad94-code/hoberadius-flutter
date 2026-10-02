import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/core/api/api_client.dart';
import 'package:hoberadius_app/features/cards/application/card_checker_format.dart';
import 'package:hoberadius_app/features/cards/data/cards_repository.dart';
import 'package:hoberadius_app/features/cards/domain/card_model.dart';
import 'package:hoberadius_app/features/cards/domain/username_preview.dart';
import 'package:hoberadius_app/features/cards/presentation/card_batch_edit_screen.dart';
import 'package:hoberadius_app/features/distributors/data/distributors_repository.dart';
import 'package:hoberadius_app/features/distributors/domain/distributor_model.dart';
import 'package:hoberadius_app/features/distributors/presentation/distributor_detail_screen.dart';
import 'package:hoberadius_app/features/distributors/presentation/distributor_form_screen.dart';
import 'package:hoberadius_app/features/distributors/presentation/distributors_list_screen.dart';
import 'package:hoberadius_app/shared/widgets/status_pill.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_api.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('cards — generate request', () {
    test('#1 login_without_password is ALWAYS explicit', () {
      final withPw = GenerateBatchRequest(planId: 3, count: 5).toBody();
      expect(withPw['login_without_password'], isFalse);
      expect(withPw['password_length'], 6);
      final noPw = GenerateBatchRequest(
        planId: 3,
        count: 5,
        loginWithoutPassword: true,
      ).toBody();
      expect(noPw['login_without_password'], isTrue);
      expect(noPw['password_length'], 0);
    });

    test('#2/#4 device count defaults to 0 and device_limit_mode travels', () {
      final body = GenerateBatchRequest(planId: 3, count: 5).toBody();
      expect(body['device_count'], 0);
      expect(body['device_limit_mode'], '');
      final replace = GenerateBatchRequest(
        planId: 3,
        count: 5,
        deviceCount: 20,
        deviceLimitMode: 'replace',
      ).toBody();
      expect(replace['device_count'], 20);
      expect(replace['device_limit_mode'], 'replace');
      expect(
        GenerateBatchRequest(planId: 1, count: 1, deviceLimitMode: 'junk')
            .toBody()['device_limit_mode'],
        '',
      );
    });
  });

  group('cards — device count / limit mode', () {
    test('#2 the same 0–50 choices in create and edit', () {
      expect(kCardDeviceCountOptions.first, 0);
      expect(kCardDeviceCountOptions.last, 50);
      expect(
        kCardDeviceCountOptions,
        [0, 1, 2, 3, 4, 5, 6, 8, 10, 15, 20, 30, 50],
      );
      // A stored 7 is shown, not dropped.
      expect(cardDeviceCountOptionsFor(7), contains(7));
      expect(cardDeviceCountOptionsFor(5), kCardDeviceCountOptions);
      expect(cardDeviceCountLabel(0), contains('الافتراض العام'));
      expect(normalizeCardDeviceCount(null), 0);
      expect(normalizeCardDeviceCount(-1), 0);
      expect(normalizeCardDeviceCount(99), 50);
    });

    test('#4 device_limit_mode labels follow the web', () {
      expect(kCardDeviceLimitModeLabels.keys, ['', 'reject', 'replace']);
      expect(kCardDeviceLimitModeLabels['reject'], 'رفض الجلسة الجديدة');
      expect(
        kCardDeviceLimitModeLabels['replace'],
        'استبدال — فصل أقدم جلسة والسماح',
      );
      expect(normalizeDeviceLimitMode('REJECT'), 'reject');
      expect(normalizeDeviceLimitMode(null), '');
    });

    test('#2 a batch without device_count reads 0, not 1', () {
      final b = CardBatch.fromJson({'id': 1});
      expect(b.deviceCount, 0);
      expect(b.deviceLimitMode, '');
      expect(b.loginWithoutPassword, isFalse);
      final c = CardBatch.fromJson({
        'id': 2,
        'device_count': 3,
        'device_limit_mode': 'replace',
        'login_without_password': true,
      });
      expect(c.deviceCount, 3);
      expect(c.deviceLimitMode, 'replace');
      expect(c.loginWithoutPassword, isTrue);
    });

    test('#6 username length 4..32, password length ≤ 32', () {
      expect(kCardUsernameLengthMin, 4);
      expect(kCardUsernameLengthMax, 32);
      expect(kCardPasswordLengthMax, 32);
    });
  });

  group('cards — batch PATCH body', () {
    test('#3/#5 locked structure, phone_only and duration_mode never sent', () {
      final body = UpdateBatchRequest(
        planId: 2,
        deviceCount: 0,
        deviceLimitMode: 'reject',
        loginWithoutPassword: true,
      ).toBody();
      for (final k in [
        'count',
        'username_prefix',
        'username_suffix',
        'username_length',
        'password_length',
        'password_generation_type',
        'include_batch_number',
        'starts_with_or_ends_with',
        'prefix_or_suffix_value',
        'phone_only_login',
        'duration_mode',
      ]) {
        expect(body.containsKey(k), isFalse, reason: k);
      }
      expect(body['device_count'], 0);
      expect(body['device_limit_mode'], 'reject');
      expect(body['login_without_password'], isTrue);
    });
  });

  group('cards — batch edit screen', () {
    Future<RecordingAdapter> pumpEdit(WidgetTester tester) async {
      tester.view.physicalSize = const Size(900, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final adapter = RecordingAdapter((r) {
        if (r.path.endsWith('/plans/options') || r.path.endsWith('/profiles')) {
          return FakeResponse.ok({
            'items': [
              {'id': 3, 'name': 'P3', 'enabled': true, 'price': 0},
            ],
          });
        }
        final batch = {
          'id': 9,
          'batch_code': 'B-9',
          'package_name': 'Night',
          'plan_id': 3,
          'plan_name': 'P3',
          'count': 40,
          'generated': 40,
          'username_prefix': '25',
          'username_length': 8,
          'password_length': 6,
          'password_generation_type': 'digits',
          'validity_after_first_login_days': 5,
          'phone_only_login': true,
          'duration_mode': 'seconds',
          // no device_count → 0
        };
        return FakeResponse.ok({'batch': batch, ...batch});
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWithValue(fakeApiClient(adapter)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: CardBatchEditScreen(batchId: 9),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return adapter;
    }

    testWidgets('#3 #4 #5 #7 read-only structure, new fields, plan picker',
        (tester) async {
      final adapter = await pumpEdit(tester);
      expect(find.text('إعدادات التوليد (للعرض فقط)'), findsOneWidget);
      expect(find.text('إعدادات التوليد المستقبلية'), findsNothing);
      expect(find.text('دخول برقم الجوال فقط'), findsNothing);
      expect(find.text('وضع المدة'), findsNothing);
      expect(find.text('معرّف العرض'), findsNothing);
      expect(find.text('عند بلوغ حدّ الأجهزة'), findsOneWidget);
      expect(
        find.text('الدخول برقم البطاقة فقط (بلا كلمة مرور)'),
        findsOneWidget,
      );
      // #2: 0 = the global setting is shown for a batch with none.
      expect(find.text('0 = الافتراض العام (من الإعدادات)'), findsOneWidget);
      // The plan is a picker showing the current plan.
      expect(find.textContaining('P3'), findsWidgets);

      await tester.tap(find.text('حفظ').first);
      await tester.pumpAndSettle();
      final body = adapter.where('PATCH', '/cards/batches/9').single.jsonBody;
      expect(body['plan_id'], 3);
      expect(body['device_count'], 0);
      expect(body['device_limit_mode'], '');
      expect(body['login_without_password'], isFalse);
      expect(body['validity_after_first_login_days'], 5);
      expect(body.containsKey('count'), isFalse);
      expect(body.containsKey('username_prefix'), isFalse);
      expect(body.containsKey('phone_only_login'), isFalse);
      expect(body.containsKey('duration_mode'), isFalse);
    });
  });

  group('cards — checker disconnect', () {
    test('#8 every online session id, deduplicated', () {
      final card = CardCheckResult.fromJson({
        'id': 5,
        'accounting_summary': {
          'latest_sessions': [
            {'session_id': 'a', 'online': true},
            {'session_id': 'b', 'online': true},
            {'session_id': 'a', 'online': true},
            {'session_id': 'c', 'online': false},
            {'session_id': '', 'online': true},
          ],
        },
      });
      expect(cardOnlineSessionIds(card), ['a', 'b']);
    });

    test('#8 disconnect sends session_ids, or no key = all sessions',
        () async {
      final adapter = RecordingAdapter(
        (_) => FakeResponse.ok({
          'card': {'id': 5},
        }),
      );
      final repo = CardsRepository(fakeApiClient(adapter));
      await repo.disconnectCard(5, sessionIds: ['a', 'b']);
      await repo.disconnectCard(5);
      final posts = adapter.where('POST', '/cards/5/disconnect').toList();
      expect(posts.first.jsonBody['session_ids'], ['a', 'b']);
      expect(posts.first.jsonBody.containsKey('session_id'), isFalse);
      expect(posts.last.jsonBody.containsKey('session_ids'), isFalse);
      expect(posts.last.jsonBody.containsKey('session_id'), isFalse);
    });
  });

  group('distributors — pure', () {
    test('#10 «1,5» is refused by the validator the save also uses', () {
      expect(validateDistributorCreditLimit('1,5'), isNotNull);
      expect(validateDistributorCreditLimit(''), isNull);
      expect(validateDistributorCreditLimit('-3'), isNotNull);
      expect(validateDistributorCreditLimit('2000000000'), isNotNull);
      expect(validateDistributorCreditLimit('1.5'), isNull);
      expect(parseDistributorCreditLimit('1.5'), 1.5);
      expect(parseDistributorCreditLimit('١٥٠'), 150);
      expect(parseDistributorCreditLimit(''), 0);
    });

    test('#11 status and permission labels', () {
      expect(distributorStatusLabel('blocked'), 'محظور');
      expect(distributorStatusLabel('disabled'), 'معطّل');
      expect(distributorStatusLabel('suspended'), 'موقوف');
      expect(
        distributorStatusTone(const Distributor(status: 'blocked')),
        PillTone.red,
      );
      expect(distributorPermissionLabel('cards.check'), 'فحص كروت');
    });

    test('#12 credit-limit hint says it is a hard debt cap', () {
      expect(kDistributorCreditLimitHint, contains('يُمنع تسجيل دين'));
      expect(kDistributorCreditLimitHint, contains('0 = بلا حدّ'));
    });

    test('#13 assignment note shown (or a dash)', () {
      expect(
        distributorAssignmentNote(
          DistributorBatch.fromJson({'assignment_notes': ' للشمال '}),
        ),
        'للشمال',
      );
      expect(distributorAssignmentNote(const DistributorBatch()), '—');
    });

    test('#14 PATCH body: never name/balance/debt; password empty = keep',
        () {
      final body = distributorPatchBody(
        displayName: 'D',
        phone: '059',
        email: '',
        status: 'blocked',
        creditLimit: 1.5,
        notes: 'n',
        permissions: ['cards.check'],
        scope: distributorScopePayload(all: true),
      );
      expect(body['scope'], {'card_batches': 'all'});
      expect(body['credit_limit'], 1.5);
      for (final k in [
        'name',
        'balance',
        'debt_balance',
        'admin_id',
        'portal_password',
      ]) {
        expect(body.containsKey(k), isFalse, reason: k);
      }
      final withAdmin = distributorPatchBody(
        displayName: '',
        phone: '',
        email: '',
        status: 'active',
        creditLimit: 0,
        notes: '',
        permissions: const [],
        scope: distributorScopePayload(
          all: false,
          existing: {'card_batches': 'all', 'x': 1},
        ),
        includeAdmin: true,
        adminId: 4,
        portalPassword: 'secret',
      );
      expect(withAdmin['admin_id'], 4);
      expect(withAdmin['portal_password'], 'secret');
      expect(withAdmin['scope'], {'card_batches': 'assigned', 'x': 1});
    });

    test('#14 Distributor parses admin_id and the check scope', () {
      final d = Distributor.fromJson({
        'id': 1,
        'admin_id': '7',
        'scope_json': {'card_batches': 'all'},
      });
      expect(d.adminId, 7);
      expect(d.checksAllBatches, isTrue);
      expect(const Distributor().checksAllBatches, isFalse);
    });

    test('#14 repository update is a PATCH', () async {
      final adapter = RecordingAdapter(
        (_) => FakeResponse.ok({
          'distributor': {'id': 41, 'name': 'd'},
        }),
      );
      final repo = DistributorsRepository(fakeApiClient(adapter));
      final d = await repo.update(41, {'status': 'active'});
      expect(d.id, 41);
      expect(
        adapter.where('PATCH', '/distributors/41').single.jsonBody['status'],
        'active',
      );
    });
  });

  group('distributors — screens', () {
    FakeHandler server() => (r) {
          if (r.path.endsWith('/summary')) {
            return FakeResponse.ok({
              'summary': {
                'distributor': {
                  'id': 41,
                  'name': 'north',
                  'display_name': 'الشمال',
                  'status': 'active',
                  'permissions': ['cards.read'],
                  'scope_json': {'card_batches': 'assigned'},
                  'credit_limit': 100,
                  'notes': 'old',
                },
                'balance': 3,
                'debt_balance': 15,
              },
            });
          }
          if (r.path.endsWith('/batches')) {
            return FakeResponse.ok({
              'items': [
                {
                  'id': 63,
                  'batch_code': 'B-63',
                  'count': 10,
                  'used': 2,
                  'status': 'active',
                  'assignment_notes': 'دفعة الشمال',
                },
              ],
            });
          }
          if (r.method == 'PATCH') {
            return FakeResponse.ok({
              'distributor': {'id': 41, 'name': 'north'},
            });
          }
          return FakeResponse.ok({'items': <dynamic>[]});
        };

    Future<RecordingAdapter> pump(WidgetTester tester, Widget child) async {
      tester.view.physicalSize = const Size(1000, 3200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final adapter = RecordingAdapter(server());
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWithValue(fakeApiClient(adapter)),
          ],
          child: MaterialApp(
            home: Scaffold(body: SingleChildScrollView(child: child)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return adapter;
    }

    testWidgets('#12 #13 #14 detail: web wording, notes column, «تعديل»',
        (tester) async {
      await pump(tester, const DistributorDetailScreen(distributorId: 41));
      expect(find.text('دفعة من الموزّع'), findsOneWidget);
      expect(find.text('تسديد / إنقاص الدين'), findsNothing);
      expect(find.text('ملاحظة الربط'), findsOneWidget);
      expect(find.text('دفعة الشمال'), findsOneWidget);
      expect(find.text('تعديل'), findsOneWidget);
    });

    testWidgets('#14 edit form: prefilled, cards.check shows portal + scope',
        (tester) async {
      final adapter =
          await pump(tester, const DistributorFormScreen(distributorId: 41));
      expect(find.text('تعديل الموزع'), findsOneWidget);
      expect(find.text('الشمال'), findsOneWidget);
      expect(find.text(kDistributorCreditLimitHint), findsOneWidget);
      // Portal password / check scope appear only with «فحص كروت».
      expect(find.byKey(const ValueKey('portal-password')), findsNothing);
      await tester.tap(find.text('فحص كروت (بوابة الموزّع)'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('portal-password')), findsOneWidget);
      expect(find.text('نطاق الفحص'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('scope-all')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('portal-password')),
        'p4ss',
      );
      await tester.tap(find.text('حفظ التعديلات'));
      await tester.pumpAndSettle();
      final body = adapter.where('PATCH', '/distributors/41').single.jsonBody;
      expect(body['permissions'], ['cards.check', 'cards.read']);
      expect(body['scope'], {'card_batches': 'all'});
      expect(body['portal_password'], 'p4ss');
      expect(body['credit_limit'], 100);
      expect(body['notes'], 'old');
      expect(body.containsKey('name'), isFalse);
      expect(body.containsKey('balance'), isFalse);
      expect(body.containsKey('debt_balance'), isFalse);
    });
  });
}
