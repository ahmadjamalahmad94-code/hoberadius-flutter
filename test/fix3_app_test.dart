// fix3 (app3) — the FINAL-campaign app items (F01, F03, F04, F06, F07).
// One group per item; every expectation is the owner's rule or the
// server's contract, not the old app behaviour.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/core/api/api_exception.dart';
import 'package:hoberadius_app/core/api/visible_error_message.dart';
import 'package:hoberadius_app/core/auth/permissions.dart';
import 'package:hoberadius_app/features/distributors/presentation/distributor_detail_screen.dart';
import 'package:hoberadius_app/features/plans/domain/plan_model.dart';
import 'package:hoberadius_app/features/subscribers/domain/subscriber_actions_model.dart';
import 'package:hoberadius_app/features/subscribers/presentation/subscriber_360_screen.dart';
import 'package:hoberadius_app/features/subscribers/presentation/widgets/subscriber_action_dialogs.dart';

SubscriberActionsContext ctx({
  int? planId = 1,
  double price = 0,
  int minutes = 0,
  double? rate,
  double effectivePrice = 0,
}) =>
    SubscriberActionsContext(
      username: 'u',
      plan: planId == null
          ? null
          : ActionPlan(
              id: planId,
              name: 'p',
              price: price,
              minutes: minutes,
              ratePerMinute: rate,
            ),
      effectivePrice: effectivePrice,
    );

void main() {
  // ───────────────────────── F04 M2 change-plan direction ────────────────
  group('change-plan direction = the server rule', () {
    test('plan_change_direction per minute', () {
      expect(planDirectionByRate(0, 0), PlanDirection.neutral);
      expect(planDirectionByRate(0, 0.001), PlanDirection.higher);
      expect(planDirectionByRate(0.001, 0), PlanDirection.lower);
      expect(planDirectionByRate(0.002, 0.001), PlanDirection.lower);
      expect(planDirectionByRate(0.001, 0.002), PlanDirection.higher);
      // equal within the server's 1e-9 relative tolerance
      expect(
        planDirectionByRate(120 / 43200, 4 / 1440),
        PlanDirection.neutral,
      );
    });

    test('a plan without a duration is priced as a 30-day month', () {
      final noDuration = Plan(id: 2, name: 'x', price: 60);
      expect(noDuration.pricingPeriodMinutes, 43200);
      expect(noDuration.ratePerMinute, closeTo(60 / 43200, 1e-12));
      expect(Plan(id: 3, name: 'd', price: 5, validityDays: 1).ratePerMinute,
          closeTo(5 / 1440, 1e-12),);
      expect(
        Plan.fromJson({
          'id': 4,
          'name': 'legacy',
          'price': 10,
          'duration_value': 2,
          'duration_unit': 'hours',
        }).pricingPeriodMinutes,
        120,
      );
      expect(Plan(id: 5, name: 'free', price: 0).ratePerMinute, 0);
    });

    test("the server's rate_per_minute / period_minutes win", () {
      final p = Plan.fromJson({
        'id': 6,
        'name': 's',
        'price': 999,
        'validity_days': 1,
        'rate_per_minute': 0.5,
        'period_minutes': 60,
      });
      expect(p.ratePerMinute, 0.5);
      expect(p.pricingPeriodMinutes, 60);
      // read-only: never sent back on save
      expect(p.toBody().containsKey('rate_per_minute'), isFalse);
      expect(p.toBody().containsKey('period_minutes'), isFalse);
    });

    test('free → paid offers the «higher» policies (was «تغيير العرض فقط»)',
        () {
      final c = ctx(price: 0, minutes: 43200);
      final paid = Plan(id: 2, name: 'paid', price: 30, validityDays: 30);
      final d = changePlanDirection(c, paid);
      expect(d, PlanDirection.higher);
      expect(
        planPolicies(d).map((o) => o.value),
        ['higher_debt', 'higher_reduce_days', 'higher_keep_expiry'],
      );
    });

    test('paid → free is «lower»', () {
      final c = ctx(price: 30, minutes: 43200);
      expect(
        changePlanDirection(c, Plan(id: 2, name: 'free', price: 0)),
        PlanDirection.lower,
      );
    });

    test('to a plan WITHOUT a duration: 30-day default (server: cheaper)', () {
      // 5 / day vs 100 with no duration → 100 / 30 days is cheaper per
      // minute; the old app compared totals (5 < 100) and said «higher».
      final c = ctx(price: 5, minutes: 1440);
      expect(
        changePlanDirection(c, Plan(id: 2, name: 'month?', price: 100)),
        PlanDirection.lower,
      );
    });

    test('the direction ignores a custom subscriber price (server rule)', () {
      // the plan is free; a custom price of 50 does not make it «paid»
      final c = ctx(price: 0, minutes: 43200, effectivePrice: 50);
      expect(
        changePlanDirection(
          c,
          Plan(id: 2, name: 'p', price: 10, validityDays: 30),
        ),
        PlanDirection.higher,
      );
    });

    test('no current plan = free (server: no plan → rate 0)', () {
      final c = ctx(planId: null);
      expect(
        changePlanDirection(
          c,
          Plan(id: 2, name: 'p', price: 10, validityDays: 30),
        ),
        PlanDirection.higher,
      );
    });

    test('rates from the server are used as given', () {
      final c = ctx(price: 5, minutes: 1440, rate: 0.00001);
      final next = Plan.fromJson({
        'id': 2,
        'name': 'n',
        'price': 1,
        'validity_days': 30,
        'rate_per_minute': 0.00002,
      });
      expect(changePlanDirection(c, next), PlanDirection.higher);
      expect(planDirectionFromServer('lower'), PlanDirection.lower);
      expect(planDirectionFromServer('?'), isNull);
    });

    test('the same plan / no choice is neutral', () {
      final c = ctx(price: 5, minutes: 1440);
      expect(changePlanDirection(c, null), PlanDirection.neutral);
      expect(
        changePlanDirection(c, Plan(id: 1, name: 'same', price: 9)),
        PlanDirection.neutral,
      );
    });
  });

  // ─────────────────── F07 M4 subscriber profile error ───────────────────
  group('360 page shows the server reason', () {
    ApiException e403() => ApiException(
          code: 'out_of_scope',
          message: 'هذه البيانات ليست ضمن نطاقك (تخصّ مديرًا أو موزّعًا آخر).',
          status: 403,
        );

    test('403 → the server text, no connection hint', () {
      final text = loadErrorMessage(e403(), networkHint: 'تحقق من الاتصال');
      expect(text, contains('ليست ضمن نطاقك'));
      expect(text, isNot(contains('تحقق من الاتصال')));
      expect(isAccessRefusal(e403()), isTrue);
    });

    test('no answer (network) → the connection hint is added', () {
      final net =
          ApiException(code: 'connectionError', message: 'تعذّر الوصول');
      expect(
        loadErrorMessage(net, networkHint: 'تحقق من الاتصال'),
        contains('تحقق من الاتصال'),
      );
      expect(isAccessRefusal(net), isFalse);
    });

    testWidgets('the page renders the reason (never «بالريدياس»)',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subscriber360Provider.overrideWith((ref, u) => throw e403()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Subscriber360Screen(username: 'x'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('ليست ضمن نطاقك'), findsOneWidget);
      expect(find.textContaining('بالريدياس'), findsNothing);
      expect(find.text('لا يمكن فتح ملف المشترك'), findsOneWidget);
    });
  });

  // ────────────────── F07 H2 distributor «صفحتي كموزّع» ──────────────────
  group('distributor own page', () {
    final dist = AppPermissions.fromMe({
      'admin': {'id': 9, 'is_owner': false, 'distributor_id': 4},
      'permissions': ['cards.view'],
      'grants': {'actions': <String, bool>{}, 'sections': <String, String>{}},
    });
    final refused = ApiException(
      code: 'forbidden',
      message: 'ليس لديك صلاحية لتنفيذ هذا الإجراء.',
      status: 403,
      details: {'requires': 'web:distributors_detail'},
    );

    test('refused own page: the server reason + what to expect', () {
      expect(distributorLoadErrorTitle(dist, 4, refused),
          'صفحتك كموزّع غير متاحة حاليًا',);
      final text = distributorLoadErrorText(dist, 4, refused);
      expect(text, contains('ليس لديك صلاحية'));
      expect(text, contains('بمجرد أن يسمح بها الخادم'));
    });

    test('another page / another error: the plain server reason', () {
      expect(distributorLoadErrorTitle(dist, 5, refused), 'تعذر جلب الموزع');
      expect(
          distributorLoadErrorText(dist, 5, refused), isNot(contains('بمجرد')),);
      final net = ApiException(code: 'x', message: 'انتهت المهلة');
      expect(distributorLoadErrorTitle(dist, 4, net), 'تعذر جلب الموزع');
    });
  });

  // ────────────────────── raw field names in messages ────────────────────
  group('server messages', () {
    test('«(amount)» is dropped from an Arabic message (r11 L-6)', () {
      final e = ApiException(
        code: 'validation_error',
        message: 'قيمة المبلغ (amount) يجب ألا تقل عن 0.01.',
        status: 422,
      );
      expect(visibleErrorMessage(e), 'قيمة المبلغ يجب ألا تقل عن 0.01.');
      expect(
        stripRawFieldNames('الراوتر لم يؤكّد CoA (router_not_configured).'),
        'الراوتر لم يؤكّد CoA.',
      );
      // not an API field name: kept
      expect(stripRawFieldNames('الرصيد (0.00) لا يكفي (SSTP).'),
          'الرصيد (0.00) لا يكفي (SSTP).',);
    });
  });
}
