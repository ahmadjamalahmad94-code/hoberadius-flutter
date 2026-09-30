// fix3 (app3) — the final `moneyquota` contract (agent/fix3-moneyquota
// @55908a92): system.limits with «بلا حدّ», daily_reset_available, the
// local-time rule, plan priority 1–10 and the change-plan 422s.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/core/api/api_client.dart';
import 'package:hoberadius_app/core/auth/auth_controller.dart';
import 'package:hoberadius_app/core/format/money_limits.dart';
import 'package:hoberadius_app/core/format/panel_time.dart';
import 'package:hoberadius_app/features/cards/domain/card_batch_requests.dart';
import 'package:hoberadius_app/features/cards/domain/username_preview.dart';
import 'package:hoberadius_app/features/sessions/presentation/sessions_list_screen.dart';
import 'package:hoberadius_app/features/plans/application/plan_form_mapper.dart';
import 'package:hoberadius_app/features/plans/domain/plan_model.dart';
import 'package:hoberadius_app/features/subscribers/application/subscriber_form_mapper.dart';
import 'package:hoberadius_app/features/subscribers/domain/subscriber_actions_model.dart';
import 'package:hoberadius_app/features/subscribers/presentation/widgets/subscriber_action_dialogs.dart';
import 'package:hoberadius_app/features/subscribers/presentation/widgets/subscriber_actions_sheet.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'support/fake_api.dart';

/// `system.limits` exactly as `core/limits.snapshot()` sends it.
Map<String, dynamic> snapshot({
  int days = 365,
  num payment = 100000,
  num generic = 100000,
  int year = 2100,
  int cards = 10000,
  Map<String, bool> unlimited = const {},
}) {
  bool u(String k) => unlimited[k] ?? false;
  return {
    'max_extend_days': days,
    'max_extend_days_unlimited': u('max_extend_days'),
    'max_subscriber_payment': payment,
    'max_subscriber_payment_unlimited': u('max_subscriber_payment'),
    'max_subscriber_balance_add': 100000,
    'max_subscriber_balance_add_unlimited': false,
    'max_distributor_balance_add': 100000,
    'max_distributor_balance_add_unlimited': false,
    'max_loan_amount': 100000,
    'max_loan_amount_unlimited': u('max_loan_amount'),
    'max_amount_generic': generic,
    'max_amount_generic_unlimited': u('max_amount_generic'),
    'max_expiry_year': year,
    'max_expiry_year_unlimited': false,
    'max_cards_per_batch': cards,
    'max_cards_per_batch_unlimited': u('max_cards_per_batch'),
    'max_extend_minutes': days * 1440,
    'max_expiry_at': '${year + 1}-01-01T00:00:00Z',
  };
}

void main() {
  setUpAll(() async => initializeDateFormatting('en'));
  tearDown(() {
    AppLimits.reset();
    PanelTimeZone.reset();
  });

  group('system.limits — final field names', () {
    test('every field is read', () {
      AppLimits.configureFrom({
        'system': {'limits': snapshot(days: 30, payment: 50, year: 2040)},
      });
      expect(kMaxExtendDays, 30);
      expect(AppLimits.maxSubscriberPayment, 50);
      expect(kMaxExpiryYear, 2040);
      expect(
        validateExtendSpan(31 * 1440),
        'أقصى تمديد في المرة الواحدة 30 يومًا — كرّر التمديد إن احتجت أكثر',
      );
      // «… تتجاوز الحدّ …» quotes the configured value
      expect(
        validateMoneyAmount(51, cap: MoneyCap.subscriberPayment),
        contains('50'),
      );
    });

    test('Arabic day agreement like the server (days_ar)', () {
      expect(extendCapMessage(1), contains('يومًا واحدًا'));
      expect(extendCapMessage(2), contains('يومين'));
      expect(extendCapMessage(7), contains('7 أيام'));
      expect(extendCapMessage(30), contains('30 يومًا'));
      expect(extendCapMessage(365), kOneYearExtendMessage);
    });

    test('«بلا حدّ» skips the cap but keeps the technical ceilings', () {
      AppLimits.configureFrom({
        'system': {
          'limits': snapshot(
            unlimited: {
              'max_extend_days': true,
              'max_subscriber_payment': true,
              'max_amount_generic': true,
              'max_cards_per_batch': true,
            },
          ),
        },
      });
      expect(validateMoneyAmount(5e8, cap: MoneyCap.subscriberPayment), isNull);
      expect(
        validateMoneyAmount(2e9, cap: MoneyCap.subscriberPayment),
        isNotNull,
        reason: 'money 1e9 stays',
      );
      expect(validateExtendSpan(1000 * 1440), isNull);
      expect(validateExtendSpan(36501 * 1440), contains('الحدّ التقنيّ'));
      expect(validateCardCount(50000), isNull);
      expect(validateCardCount(100001), isNotNull, reason: 'cards 100,000');
      // loan cap untouched (not unlimited)
      expect(validateMoneyAmount(100001, cap: MoneyCap.loanAmount), isNotNull);
    });

    test('the year never passes 2100; max_expiry_at as a fallback', () {
      AppLimits.configureFrom({
        'limits': {'max_expiry_year': 2300},
      });
      expect(kMaxExpiryYear, 2100);
      AppLimits.configureFrom({
        'limits': {'max_expiry_at': '2051-01-01T00:00:00Z'},
      });
      expect(kMaxExpiryYear, 2050);
      expect(
        expiryTooFarMessage,
        'المدة الناتجة تتجاوز الحدّ المسموح. (آخر تاريخ انتهاء مسموح: نهاية سنة 2050)',
      );
    });

    test('create uses the server create wording', () {
      final now = DateTime(2026, 10, 1);
      expect(
        validateExpiryJump(
          original: null,
          next: now.add(const Duration(days: 400)),
          now: now,
          creating: true,
        ),
        startsWith('أقصى مدّة عند إنشاء المشترك سنة من الآن'),
      );
      AppLimits.configureFrom({
        'limits': {'max_extend_days': 90},
      });
      expect(kCreateExpiryTooLongMessage, contains('90 يومًا'));
      // an EDIT keeps the extend wording
      expect(
        validateExpiryJump(
          original: null,
          next: now.add(const Duration(days: 91)),
          now: now,
        ),
        contains('أقصى تمديد في المرة الواحدة 90 يومًا'),
      );
    });

    test('read at session restore from /me', () {
      expect(
        applyPanelTimeZoneFrom({
          'system': {
            'timezone': 'Asia/Gaza',
            'limits': snapshot(days: 60),
          },
        }),
        isTrue,
      );
      AppLimits.configureFrom({
        'system': {'limits': snapshot(days: 60)},
      });
      expect(kMaxExtendDays, 60);
    });
  });

  group('actions-context quota.daily_reset_available', () {
    SubscriberActionsContext ctx(Object? available) =>
        SubscriberActionsContext.fromJson({
          'username': 'u',
          'status': 'enabled',
          'quota': {
            'has_quota': true,
            if (available != null) 'daily_reset_available': available,
          },
        });
    final spec = [...kActivationActions, ...kAdminActions]
        .firstWhere((s) => s.action == SubscriberAction.quotaReset);

    test('false → «استعادة الكوتة اليومية» hidden', () {
      expect(actionAvailability(spec, ctx(false)).visible, isFalse);
    });

    test('true / older server → shown', () {
      expect(actionAvailability(spec, ctx(true)).enabled, isTrue);
      expect(actionAvailability(spec, ctx(null)).enabled, isTrue);
    });
  });

  group('plan priority 1–10, default 5', () {
    test('model default and legacy normalisation', () {
      expect(Plan(name: 'x').priority, 5);
      expect(Plan.fromJson({'name': 'x', 'priority': 100}).priority, 5);
      expect(Plan.fromJson({'name': 'x', 'priority': 0}).priority, 5);
      expect(Plan.fromJson({'name': 'x', 'priority': 12}).priority, 10);
      expect(Plan.fromJson({'name': 'x', 'priority': 3}).priority, 3);
    });

    test('form: 1–10 only, empty = 5', () {
      final c = {
        for (final k in kPlanNumberFields.keys) k: TextEditingController(),
      };
      for (final bad in ['0', '11', '100', '-1']) {
        c['priority']!.text = bad;
        expect(planFormNumberError(c), contains('الأولوية'), reason: bad);
      }
      c['priority']!.text = '١٠';
      expect(planFormNumberError(c), isNull);
    });
  });

  group('ambiguous hour follows system.local_time_rule', () {
    test('«earlier» (server) → first occurrence', () {
      PanelTimeZone.configure(name: 'Asia/Gaza', ambiguousRule: 'earlier');
      expect(
        panelWallToInstant(DateTime(2026, 10, 24, 1, 30)),
        DateTime.utc(2026, 10, 23, 22, 30),
      );
    });

    test('read from /me with tz_transitions', () {
      applyPanelTimeZoneFrom({
        'system': {
          'timezone': 'Asia/Gaza',
          'local_time_rule': {'ambiguous': 'earlier'},
          'tz_transitions': [
            {
              'at': '2026-10-23T23:00:00Z',
              'offset_before_minutes': 180,
              'offset_after_minutes': 120,
            },
          ],
        },
      });
      expect(PanelTimeZone.ambiguousLater, isFalse);
      expect(
        panelWallToInstant(DateTime(2026, 10, 24, 1, 30)),
        DateTime.utc(2026, 10, 23, 22, 30),
      );
    });
  });

  testWidgets('change-plan 422 (cap) is shown IN the dialog, which stays open',
      (tester) async {
    const refusal = 'أقصى تمديد في المرة الواحدة سنة — التعويض المحسوب لهذا '
        'التغيير 600 يومًا. اختر «تغيير العرض بدون تعويض» ثم مدّد يدويًّا.';
    final adapter = RecordingAdapter((r) {
      if (r.method == 'GET' && r.path.contains('/profiles')) {
        return FakeResponse.ok({
          'items': [
            {
              'id': 2,
              'name': 'رخيص',
              'price': 1,
              'validity_days': 30,
              'enabled': true,
            },
          ],
        });
      }
      return FakeResponse.error(422, 'validation_error', refusal);
    });
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final c = SubscriberActionsContext.fromJson({
      'username': 'f04_u',
      'status': 'enabled',
      'currency': 'ILS',
      'plan': {'id': 1, 'name': 'غالي', 'price': 120, 'minutes': 43200},
      'effective_price': 120,
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(fakeApiClient(adapter)),
        ],
        child: MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () =>
                      showActionDialog(context, ChangePlanDialog(c: c)),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('رخيص').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('تغيير العرض'));
    await tester.pumpAndSettle();
    expect(find.text(refusal), findsOneWidget);
    expect(find.byType(ChangePlanDialog), findsOneWidget);
    expect(adapter.where('POST', 'change-plan'), hasLength(1));
  });

  // ─────────────── cardsnet (agent/fix3-cardsnet @4e8bbed6) ───────────────
  group('card generator preview = the server rule', () {
    test('the maximum is 32 (was 16) and 1..32 only', () {
      expect(kCardUsernameLengthMax, 32);
      for (final bad in [0, 33, null]) {
        expect(
          cardUsernameLengthRefusal(prefix: '', suffix: '', totalLength: bad),
          'طول اسم المستخدم يجب أن يكون بين 1 و32.',
          reason: '$bad',
        );
      }
      expect(
        cardUsernameLengthRefusal(prefix: '', suffix: '', totalLength: 32),
        isNull,
      );
    });

    test('the server 422 text word for word (with the batch number)', () {
      expect(
        cardUsernameLengthRefusal(
          prefix: 'ab',
          suffix: 'z',
          totalLength: 5,
          batchNumber: '14',
        ),
        'طول اسم المستخدم المختار 5 محارف لا يتّسع: الأجزاء الثابتة '
        '(البادئة 2 + رقم الحزمة 2 + اللاحقة 1 = 5) لا تترك خانةً للأرقام '
        'العشوائيّة. اجعل الطول 6 على الأقلّ (والحدّ 32)، أو قصّر '
        'البادئة/اللاحقة.',
      );
      // one free position is enough for the server
      expect(
        cardUsernameLengthRefusal(
          prefix: 'ab',
          suffix: 'z',
          totalLength: 6,
          batchNumber: '14',
        ),
        isNull,
      );
    });

    test('the preview never shows a refused name; 32 fits', () {
      final refused = UsernamePreview.of(
        prefix: 'x' * 16,
        suffix: '',
        totalLength: 16,
      );
      expect(refused.refusal, isNotNull);
      expect(refused.generated, isEmpty);
      final ok =
          UsernamePreview.of(prefix: 'x' * 16, suffix: '', totalLength: 32);
      expect(ok.refusal, isNull);
      expect(ok.full.length, 32);
    });
  });

  group('temp speed: a failed CoA is said clearly (web parity)', () {
    Map<String, dynamic> res(Map<String, dynamic> coa,
            {String mode = 'live_coa',}) =>
        {
          'temporary_speed': {
            'rate': '512k/2M',
            'mode': mode,
            'ends_at': '2026-10-01T10:00:00Z',
            'coa': coa,
          },
        };

    test('the server labels, never the raw code', () {
      for (final code in [
        'timeout',
        'socket_error',
        'CoA-NAK',
        'router_not_configured',
        'unknown-code-44',
        'weird',
      ]) {
        final o = tempSpeedOutcome('u', res({'ok': false, 'code': code}));
        expect(o.warning, isTrue, reason: code);
        expect(o.message, contains('لم يؤكّد تطبيقها'), reason: code);
        expect(o.message, isNot(contains(code == 'CoA-NAK' ? 'xx' : code)),
            reason: code,);
      }
      expect(coaFailureReason('timeout'), 'لم يردّ الراوتر (انتهت المهلة)');
      expect(coaFailureReason('unknown-code-3'), 'ردّ غير معروف من الراوتر');
    });

    test('no live session: info, applied on reconnect', () {
      final o = tempSpeedOutcome(
        'u',
        res({'ok': false, 'code': 'no_active_session'}),
      );
      expect(o.warning, isFalse);
      expect(o.message, contains('ستُطبَّق تلقائيًا فور إعادة اتصاله'));
    });

    test('reauth that failed: «تعذّر الفصل»', () {
      final o = tempSpeedOutcome(
        'u',
        res({'ok': false, 'code': 'timeout'}, mode: 'disconnect_reauth'),
      );
      expect(o.warning, isTrue);
      expect(o.message, contains('تعذّر الفصل'));
    });

    test('success names the rate', () {
      final o = tempSpeedOutcome('u', res({'ok': true, 'code': 'CoA-ACK'}));
      expect(o.warning, isFalse);
      expect(o.message, contains('512k/2M'));
      expect(o.message, contains('مباشرةً'));
    });
  });
}
