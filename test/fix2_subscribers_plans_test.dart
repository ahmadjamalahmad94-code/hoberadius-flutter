// FIX2 — subscriber screens, plans, sessions.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hoberadius_app/core/api/api_client.dart';
import 'package:hoberadius_app/core/format/bidi.dart';
import 'package:hoberadius_app/core/api/api_exception.dart';
import 'package:hoberadius_app/core/format/input_rules.dart';
import 'package:hoberadius_app/features/nas/presentation/nas_form_screen.dart'
    show isNasNameConflict;
import 'package:hoberadius_app/features/card_users/presentation/card_users_screen.dart'
    show marketplacePackageNumberError;
import 'package:hoberadius_app/features/plans/application/plan_form_mapper.dart';
import 'package:hoberadius_app/features/plans/domain/plan_model.dart';
import 'package:hoberadius_app/features/plans/presentation/widgets/plan_form_dialogs.dart';
import 'package:hoberadius_app/features/sessions/presentation/sessions_list_screen.dart';
import 'package:hoberadius_app/features/subscribers/application/subscriber_form_controller.dart';
import 'package:hoberadius_app/features/subscribers/application/subscriber_form_mapper.dart';
import 'package:hoberadius_app/features/subscribers/data/subscriber_actions_repository.dart';
import 'package:hoberadius_app/features/subscribers/data/subscribers_repository.dart';
import 'package:hoberadius_app/features/subscribers/domain/subscriber_actions_model.dart';
import 'package:hoberadius_app/features/subscribers/domain/subscriber_model.dart';
import 'package:hoberadius_app/features/subscribers/presentation/subscriber_form_screen.dart';
import 'package:hoberadius_app/features/subscribers/presentation/widgets/subscriber_action_dialogs.dart';
import 'package:hoberadius_app/features/subscribers/presentation/widgets/subscriber_form_sections.dart';
import 'package:hoberadius_app/shared/widgets/form_field_row.dart';

import 'support/fake_api.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  required RecordingAdapter adapter,
  ProviderContainer? container,
  double width = 390,
}) async {
  tester.view.physicalSize = Size(width, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final app = MaterialApp(
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
  await tester.pumpWidget(
    container != null
        ? UncontrolledProviderScope(container: container, child: app)
        : ProviderScope(
            overrides: [
              apiClientProvider.overrideWithValue(fakeApiClient(adapter)),
            ],
            child: app,
          ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async => initializeDateFormatting('en'));
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('4 — subscriber screens', () {
    testWidgets('a stale «مستخدم مسبقًا» never greets a fresh new form',
        (tester) async {
      final adapter = RecordingAdapter((r) {
        if (r.path == '/api/v1/accounts/taken') {
          return FakeResponse.error(404, 'not_found', 'اسم المستخدم مستخدم مسبقًا.');
        }
        return FakeResponse.ok({'items': <dynamic>[]});
      });
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(fakeApiClient(adapter)),
        ],
      );
      addTearDown(container.dispose);
      // An earlier form left an error in the app-wide provider.
      await tester.runAsync(
        () => container.read(subscriberFormActionProvider.notifier).load('taken'),
      );
      expect(container.read(subscriberFormActionProvider).error, isNotNull);
      await _pump(
        tester,
        const SubscriberFormScreen(),
        adapter: adapter,
        container: container,
      );
      expect(find.text('اسم المستخدم مستخدم مسبقًا.'), findsNothing);
      expect(container.read(subscriberFormActionProvider).error, isNull);
    });

    testWidgets('edit: the username is read-only with «إعادة تسمية»',
        (tester) async {
      final adapter = RecordingAdapter((r) {
        if (r.path == '/api/v1/accounts/ali') {
          return FakeResponse.ok({
            'id': 1,
            'username': 'ali',
            'status': 'enabled',
          });
        }
        return FakeResponse.ok({'items': <dynamic>[]});
      });
      await _pump(
        tester,
        const SubscriberFormScreen(username: 'ali'),
        adapter: adapter,
      );
      final field = tester.widget<TextField>(
        find.descendant(
          of: find.byWidgetPredicate(
            (w) => w is TextFormField && w.controller?.text == 'ali',
          ),
          matching: find.byType(TextField),
        ),
      );
      expect(field.readOnly, isTrue);
      expect(find.byTooltip('إعادة تسمية'), findsOneWidget);
    });

    testWidgets('create: a 70-character name is not cut, it is refused',
        (tester) async {
      final adapter = RecordingAdapter(
        (r) => FakeResponse.ok({'items': <dynamic>[]}),
      );
      await _pump(tester, const SubscriberFormScreen(), adapter: adapter);
      final name = 'a' * 70;
      final field = find.descendant(
        of: find.byWidgetPredicate(
          (w) => w is FormFieldRow && w.label == 'اسم المستخدم',
        ),
        matching: find.byType(TextField),
      );
      await tester.enterText(field.first, name);
      await tester.pump();
      final typed = tester.widget<TextField>(field.first).controller!.text;
      expect(typed.length, 70);
      expect(find.textContaining('64 حرفًا على الأكثر'), findsOneWidget);
      expect(validateNewSubscriberUsername(name), contains('64'));
      expect(validateNewSubscriberUsername('ab'), contains('3'));
    });

    test('an invalid e-mail is refused', () {
      expect(validateOptionalEmail('not-an-email'), isNotNull);
      expect(validateOptionalEmail('a@b.co'), isNull);
      expect(validateOptionalEmail(''), isNull);
    });

    test('search sends Latin digits for «٠٥٩٩٠٠٠١٢٣»', () async {
      final adapter = RecordingAdapter(
        (r) => FakeResponse.ok({'items': <dynamic>[], 'total': 0}),
      );
      final repo = SubscribersRepository(fakeApiClient(adapter));
      await repo.listPage(search: '٠٥٩٩٠٠٠١٢٣');
      expect(adapter.requests.single.query['q'], '0599000123');
    });

    testWidgets('the edit-form «سرعة مؤقتة» switch is gone (it did nothing)',
        (tester) async {
      await _pump(
        tester,
        SubscriberSpeedSection(
          controllers: {
            'download_speed_kbps': TextEditingController(),
            'upload_speed_kbps': TextEditingController(),
          },
          bandwidthControlEnabled: false,
          onBandwidthControlChanged: (_) {},
          customSpeed: false,
          onCustomSpeedChanged: (_) {},
          temporarySpeed: false,
          onTemporarySpeedChanged: (_) {},
        ),
        adapter: RecordingAdapter((r) => FakeResponse.ok({})),
      );
      // Expand the collapsed section.
      await tester.tap(find.text('السرعة'));
      await tester.pumpAndSettle();
      expect(find.text('رفع مؤقت بدون تغيير الباقة'), findsNothing);
      expect(find.textContaining('«المتصلون»'), findsOneWidget);
    });

    test('«بدون انتهاء»: an old server that keeps the expiry is reported',
        () async {
      for (final (serverExpiry, expectError) in [
        ('2026-10-18T23:36:00Z', true),
        (null, false),
      ]) {
        final adapter = RecordingAdapter(
          (r) => FakeResponse.ok({
            'id': 1,
            'username': 'u',
            'expire_at': serverExpiry,
          }),
        );
        final c = ProviderContainer(
          overrides: [
            apiClientProvider.overrideWithValue(fakeApiClient(adapter)),
          ],
        );
        addTearDown(c.dispose);
        final err = await c
            .read(subscriberFormActionProvider.notifier)
            .submitChanges('u', {'expire_at': null});
        expect(err != null, expectError, reason: '$serverExpiry');
        expect(adapter.requests.single.jsonBody, {'expire_at': null});
      }
    });

    test('numbers in collapsed sections and the one-year expiry rule', () {
      final c = {
        for (final k in kSubscriberNumberFields.keys) k: TextEditingController(),
      };
      c['vlan_id']!.text = '7.5';
      expect(subscriberFormNumberError(c), contains('VLAN'));
      c['vlan_id']!.text = '٧';
      c['custom_price']!.text = '1e9';
      expect(subscriberFormNumberError(c), contains('السعر المخصص'));
      c['custom_price']!.text = '١٢٫٥';
      expect(subscriberFormNumberError(c), isNull);

      final now = DateTime(2026, 10, 1);
      expect(
        validateExpiryJump(
          original: DateTime(2026, 10, 20),
          next: DateTime(2027, 10, 30),
          now: now,
        ),
        contains('سنة'),
      );
      expect(
        validateExpiryJump(
          original: DateTime(2026, 10, 20),
          next: DateTime(2027, 10, 10),
          now: now,
        ),
        isNull,
      );
      // Shortening is free; clearing too.
      expect(
        validateExpiryJump(
          original: DateTime(2030),
          next: DateTime(2027),
          now: now,
        ),
        isNull,
      );
      expect(
        validateExpiryJump(original: DateTime(2030), next: null, now: now),
        isNull,
      );
    });

    test('service type: server values, a stored spelling is kept', () {
      expect(
        serviceTypeOptions('Hotspot').map((e) => e.$1),
        ['Hotspot', 'PPPoE', 'both'],
      );
      expect(serviceTypeOptions('hotspot').first.$1, 'hotspot');
      expect(serviceTypeOptions('Balance').last.$1, 'Balance');
    });

    testWidgets('the rename dialog error is a screen-reader live region',
        (tester) async {
      final semantics = tester.ensureSemantics();
      final adapter = RecordingAdapter(
        (r) => FakeResponse.error(
          422,
          'validation_error',
          'اسم الدخول «r10_001» مستخدَم بالفعل.',
        ),
      );
      await _pump(
        tester,
        const RenameDialog(c: SubscriberActionsContext(username: 'r10_016')),
        adapter: adapter,
      );
      await tester.enterText(find.byType(TextField), 'r10_001');
      await tester.pump();
      await tester.tap(find.text('حفظ الاسم'));
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel(RegExp('خطأ: .*مستخدَم بالفعل')),
        findsOneWidget,
      );
      final node = tester.getSemantics(
        find.bySemanticsLabel(RegExp('خطأ: .*مستخدَم بالفعل')),
      );
      expect(node.getSemanticsData().flagsCollection.isLiveRegion, isTrue);
      semantics.dispose();
    });
  });

  group('6 — plans', () {
    Map<String, TextEditingController> planControllers() => {
          for (final k in [
            ...kPlanNumberFields.keys,
            'name',
            'code',
            'description',
            'color',
            'address_pool',
            'framed_pool',
            'allowed_hours_from',
            'allowed_hours_to',
            'currency',
          ])
            k: TextEditingController(),
        };

    test('Arabic digits and «٫» are read, «7.5» / text refused', () {
      final c = planControllers();
      c['name']!.text = 'x';
      c['validity_days']!.text = '٩';
      c['duration_minutes']!.text = '١٤٤٠';
      c['price']!.text = '١٢٫٥';
      c['concurrent_sessions']!.text = '1';
      expect(planFormNumberError(c), isNull);
      final plan = buildPlanFromForm(c, selectionsFromPlan(Plan(name: 'x')));
      expect(plan.validityDays, 9);
      expect(plan.durationMinutes, 1440);
      expect(plan.price, 12.5);

      c['validity_days']!.text = '7.5';
      expect(planFormNumberError(c), contains('الصلاحية'));
      c['validity_days']!.text = 'abc';
      expect(planFormNumberError(c), isNotNull);
      c['validity_days']!.text = '7';
      c['priority']!.text = '-1';
      expect(planFormNumberError(c), contains('الأولوية'));
    });

    testWidgets('the delete dialog says «أرشفة», not «نهائيًا»',
        (tester) async {
      await _pump(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => confirmDeletePlan(context, 'r04_plan'),
            child: const Text('open'),
          ),
        ),
        adapter: RecordingAdapter((r) => FakeResponse.ok({})),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.textContaining('نهائي'), findsNothing);
      expect(find.textContaining('استعادتها'), findsOneWidget);
      expect(find.text('أرشفة'), findsOneWidget);
    });

    test('change-plan choices hide disabled and the current plan', () {
      final plans = [
        Plan(id: 1, name: 'current', price: 30, validityDays: 30),
        Plan(id: 2, name: 'off', enabled: false, price: 10, validityDays: 30),
        Plan(id: 3, name: 'r04_meta', price: 302.35, validityDays: 30),
      ];
      final list = changePlanChoices(plans, currentPlanId: 1);
      expect(list.map((p) => p.id), [3]);
      final label = planOptionLabel(list.single);
      expect(label, startsWith(kFirstStrongIsolate));
      expect(stripBidiMarks(label), startsWith('r04_meta — 302.35'));
    });

    test('higher/lower is per minute (5/day is dearer than 120/30 days)', () {
      const c = SubscriberActionsContext(
        username: 'u',
        plan: ActionPlan(id: 1, name: 'يوم', price: 5, minutes: 1440),
        effectivePrice: 5,
      );
      final vip = Plan(id: 2, name: 'VIP', price: 120, validityDays: 30);
      expect(changePlanDirection(c, vip), PlanDirection.lower);
      // The server's own rate wins when sent.
      const withRate = SubscriberActionsContext(
        username: 'u',
        plan: ActionPlan(
          id: 1,
          name: 'x',
          price: 5,
          minutes: 1440,
          ratePerMinute: 0.00001,
        ),
        effectivePrice: 5,
      );
      expect(changePlanDirection(withRate, vip), PlanDirection.higher);
    });

    test('quota windows follow the server (daily-only plan → daily)', () {
      expect(
        quotaWindowsOf({
          'has_quota': true,
          'quota_mb': null,
          'daily': {'combined': 200, 'used_mb': 3},
          'monthly': null,
        }),
        ['daily'],
      );
      expect(
        quotaWindowsOf({
          'quota_mb': 1024,
          'monthly': {'download': 5000},
          'daily': {'combined': 0},
        }),
        ['total', 'monthly'],
      );
      expect(quotaWindowsOf({}), isEmpty);
    });

    test('a chosen window is sent as quota_window (auto is not sent)',
        () async {
      final adapter = RecordingAdapter((r) => FakeResponse.ok({}));
      final repo = SubscriberActionsRepository(fakeApiClient(adapter));
      await repo.quotaTopup(
        'u',
        quotaMb: 100,
        target: 'combined',
        charge: ChargeMode.free,
        window: 'daily',
      );
      await repo.quotaTopup(
        'u',
        quotaMb: 100,
        target: 'combined',
        charge: ChargeMode.free,
      );
      expect(adapter.requests[0].jsonBody['quota_window'], 'daily');
      expect(adapter.requests[1].jsonBody.containsKey('quota_window'), isFalse);
    });
  });

  group('7 — sessions', () {
    testWidgets('«المتصلون»: input octets = upload, output = download',
        (tester) async {
      final adapter = RecordingAdapter((r) {
        if (r.path == '/api/v1/sessions/online') {
          return FakeResponse.ok({
            'items': [
              {
                'username': 'r07_u5',
                'session_id': 's1',
                'user_type': 'subscriber',
                'state': 'online',
                'started_at': '2026-09-28T10:00:00Z',
                'bytes_in': 5000000,
                'bytes_out': 50000000,
              },
            ],
            'total': 1,
            'has_more': false,
          });
        }
        return FakeResponse.ok({'items': <dynamic>[]});
      });
      tester.view.physicalSize = const Size(390, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWithValue(fakeApiClient(adapter)),
          ],
          child: const MaterialApp(
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                body: SingleChildScrollView(child: SessionsListScreen()),
              ),
            ),
          ),
        ),
      );
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      // «تنزيل» shows the 50 MB (output), «رفع» the 5 MB (input).
      final down = find.ancestor(
        of: find.text('تنزيل'),
        matching: find.byWidgetPredicate((w) => w is Column),
      );
      expect(
        find.descendant(of: down.first, matching: find.text('48 م.ب')),
        findsOneWidget,
      );
      final up = find.ancestor(
        of: find.text('رفع'),
        matching: find.byWidgetPredicate((w) => w is Column),
      );
      expect(
        find.descendant(of: up.first, matching: find.text('4.8 م.ب')),
        findsOneWidget,
      );
    });

    test('temp speed: days allowed, strict numbers, ≤ a year', () {
      String? v(String d, String u, String dur, String unit) =>
          validateTemporarySpeedInput(
            downloadText: d,
            uploadText: u,
            durationText: dur,
            unit: unit,
          );
      expect(v('2048', '1024', '3', 'days'), isNull);
      expect(v('٢٠٤٨', '1024', '2', 'hours'), isNull);
      expect(v('2048', '1024', '400', 'days'), contains('سنة'));
      expect(v('2048', '1e3', '2', 'hours'), contains('سرعة الرفع'));
      expect(v('2048', '1024', '0', 'minutes'), isNotNull);
    });
  });

  test('card users: marketplace package numbers are strict', () {
    String? err(String price, {String dur = '60'}) =>
        marketplacePackageNumberError(
          planId: '',
          price: price,
          duration: dur,
          down: '2048',
          up: '١٠٢٤',
        );
    expect(err('١٢٫٥'), isNull);
    expect(err('-5'), contains('السعر'));
    expect(err('5', dur: '1e3'), contains('المدة'));
    expect(err('200000'), contains('100,000'));
  });

  test('NAS: 409 nas_name_conflict goes under the name field', () {
    expect(
      isNasNameConflict(
        ApiException(
          code: 'nas_name_conflict',
          message: 'اسم الراوتر «X» مستخدم لراوتر آخر — اختر اسمًا مختلفًا.',
          status: 409,
        ),
      ),
      isTrue,
    );
    expect(
      isNasNameConflict(
        ApiException(code: 'internal_error', message: 'x', status: 500),
      ),
      isFalse,
    );
  });
}
