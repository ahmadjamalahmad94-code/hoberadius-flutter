import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hoberadius_app/core/api/api_exception.dart';
import 'package:hoberadius_app/features/subscribers/data/subscriber_actions_repository.dart';
import 'package:hoberadius_app/features/subscribers/domain/subscriber_actions_model.dart';
import 'package:hoberadius_app/features/subscribers/domain/subscriber_model.dart';
import 'package:hoberadius_app/features/subscribers/presentation/widgets/subscriber_action_dialogs.dart';
import 'package:hoberadius_app/features/subscribers/presentation/widgets/subscriber_actions_sheet.dart';

Map<String, dynamic> _contextJson({Map<String, bool>? permissions}) => {
      'username': 'ahmad',
      'full_name': 'أحمد',
      'status': 'enabled',
      'expire_at': '2026-10-10T21:00:00Z',
      'currency': 'ILS',
      'plan': {'id': 3, 'name': 'شهري 30', 'price': 30, 'minutes': 43200},
      'effective_price': 30,
      'balance': -12.5,
      'debt': 12.5,
      'open_loans': [
        {'id': 7, 'amount': 3, 'days': 3, 'minutes': 4320, 'reason': 'x'},
        {'id': 8, 'amount': 2, 'days': 2, 'minutes': 2880},
      ],
      'quota': {'has_quota': true, 'daily_quota_mb': 2048, 'used_today_mb': 10},
      'online_sessions': 0,
      'channels': {'sms': true, 'whatsapp': false},
      'message_templates': [],
      'max_free_loan_hours': 72,
      'max_debt_loan_days': 366,
      if (permissions != null) 'permissions': permissions,
    };

class _FakeRepo implements SubscriberActionsRepository {
  final calls = <String, Object?>{};

  @override
  Future<Map<String, dynamic>> extend(
    String username,
    Map<String, dynamic> payload, {
    String? idempotencyKey,
  }) async {
    calls['extend'] = payload;
    calls['extend_key'] = idempotencyKey;
    return {'new_expire_at': '2026-10-11T21:00:00Z'};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _host(Widget child, {List<Override> overrides = const []}) =>
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(body: child),
        ),
      ),
    );

void main() {
  setUpAll(() async => initializeDateFormatting('en'));

  group('price math', () {
    test('effective price × minutes ÷ plan minutes, 2 decimals', () {
      expect(
        priceForMinutes(effectivePrice: 30, planMinutes: 43200, minutes: 1440),
        1.0,
      );
      expect(
        priceForMinutes(effectivePrice: 25, planMinutes: 43200, minutes: 60),
        0.03,
      );
      expect(
        priceForMinutes(
          effectivePrice: 30,
          planMinutes: 43200,
          minutes: 7 * 1440,
        ),
        7.0,
      );
    });

    test('free, no plan period or no price → 0', () {
      expect(
        priceForMinutes(
          effectivePrice: 30,
          planMinutes: 43200,
          minutes: 1440,
          mode: ChargeMode.free,
        ),
        0,
      );
      expect(
        priceForMinutes(effectivePrice: 30, planMinutes: 0, minutes: 1440),
        0,
      );
      expect(
        priceForMinutes(effectivePrice: 0, planMinutes: 43200, minutes: 1440),
        0,
      );
    });
  });

  group('extend payload', () {
    test('duration mode sends minutes, no expire_at', () {
      final p = extendPayload(
        mode: ExtendMode.duration,
        minutes: 2880,
        charge: ChargeMode.paid,
        amount: 2,
        notes: ' ok ',
      );
      expect(p, {
        'mode': 'duration',
        'minutes': 2880,
        'charge_mode': 'paid',
        'amount': 2,
        'notes': 'ok',
      });
    });

    test('exact mode sends the local pick as UTC ISO with Z', () {
      final local = DateTime(2026, 10, 1, 23, 59);
      final p = extendPayload(mode: ExtendMode.exact, expireAt: local);
      expect(p['mode'], 'expire_at');
      expect(p.containsKey('minutes'), isFalse);
      final sent = p['expire_at'] as String;
      expect(sent.endsWith('Z'), isTrue);
      expect(DateTime.parse(sent).isAtSameMomentAs(local), isTrue);
      expect(sent, toUtcIso(local));
      expect(p['charge_mode'], 'free');
      expect(p.containsKey('amount'), isFalse);
    });

    test('toUtcIso formats a UTC instant', () {
      expect(
        toUtcIso(DateTime.utc(2026, 9, 8, 7, 5, 3, 999)),
        '2026-09-08T07:05:03Z',
      );
    });

    test('exact-mode minutes count from the later of expiry and now', () {
      final now = DateTime(2026, 9, 28, 12);
      final exp = DateTime(2026, 10, 1, 12);
      expect(exactExtendMinutes(DateTime(2026, 10, 2, 12), exp, now), 1440);
      // expired → from now
      expect(
        exactExtendMinutes(
          DateTime(2026, 9, 29, 12),
          DateTime(2026, 9, 1),
          now,
        ),
        1440,
      );
      expect(exactExtendMinutes(DateTime(2026, 9, 30), exp, now), 0);
    });
  });

  group('loan limits', () {
    test('free loan ≤ 72 h', () {
      expect(validateLoan(type: LoanType.free, days: 3, hours: 0), isNull);
      expect(validateLoan(type: LoanType.free, days: 3, hours: 1), isNotNull);
      expect(validateLoan(type: LoanType.free, days: 0, hours: 72), isNull);
    });

    test('debt loan ≤ 365 days (one-year rule), zero duration rejected', () {
      expect(validateLoan(type: LoanType.debt, days: 365, hours: 0), isNull);
      // Owner decision 2026-09-29: one operation adds at most a year.
      expect(
        validateLoan(type: LoanType.debt, days: 366, hours: 0),
        contains('أقصى تمديد في المرة الواحدة سنة'),
      );
      expect(validateLoan(type: LoanType.debt, days: 367, hours: 0), isNotNull);
      expect(validateLoan(type: LoanType.debt, days: 0, hours: 0), isNotNull);
    });

    test('server-sent limits are honoured', () {
      expect(
        validateLoan(
          type: LoanType.free,
          days: 1,
          hours: 1,
          maxFreeHours: 24,
        ),
        isNotNull,
      );
    });

    test('payload', () {
      expect(
        loanPayload(type: LoanType.debt, days: 2, hours: 5, reason: ' r '),
        {'loan_type': 'debt', 'days': 2, 'hours': 5, 'reason': 'r'},
      );
    });
  });

  group('payment', () {
    test('loan_actions carries only settle/forgive, not defer', () {
      final p = paymentPayload(
        amount: 50,
        method: 'bank',
        choices: {
          7: LoanChoice.settle,
          8: LoanChoice.defer,
          9: LoanChoice.forgive,
        },
        settleBalance: true,
      );
      expect(p['loan_actions'], [
        {'loan_id': 7, 'action': 'settle'},
        {'loan_id': 9, 'action': 'forgive'},
      ]);
      expect(p['method'], 'bank');
      expect(p['settle_balance'], isTrue);
      expect(p['amount'], 50);
    });

    test('settled total sums only «خصم» rows', () {
      final c = SubscriberActionsContext.fromJson(_contextJson());
      expect(
        settledTotal(
          c.openLoans,
          {7: LoanChoice.settle, 8: LoanChoice.forgive},
        ),
        3,
      );
    });
  });

  group('change plan policy', () {
    PlanDirection dir(double cur, double next, {int? nextId = 5}) =>
        planDirection(
          currentPlanId: 3,
          currentPrice: cur,
          nextPlanId: nextId,
          nextPrice: next,
        );

    test('by price comparison', () {
      expect(dir(30, 20), PlanDirection.lower);
      expect(dir(30, 40), PlanDirection.higher);
      expect(dir(30, 30), PlanDirection.neutral);
      expect(dir(0, 40), PlanDirection.neutral);
      expect(dir(30, 40, nextId: 3), PlanDirection.neutral);
      expect(dir(30, 40, nextId: null), PlanDirection.neutral);
    });

    test('first option is the default and labels match the web', () {
      expect(planPolicies(PlanDirection.lower).first.value, 'lower_compensate');
      expect(
        planPolicies(PlanDirection.higher).map((o) => o.value),
        ['higher_debt', 'higher_reduce_days', 'higher_keep_expiry'],
      );
      expect(
        planPolicies(PlanDirection.neutral).single.title,
        'تغيير العرض فقط',
      );
    });
  });

  test('template substitution', () {
    final t = kDefaultMessageTemplates.firstWhere((t) => t.key == 'expiry');
    final out = fillMessageTemplate(
      t.text,
      username: 'ahmad',
      plan: 'شهري',
      expire: '2026-10-10',
    );
    expect(out, contains('ahmad'));
    expect(out, contains('(شهري)'));
    expect(out, contains('2026-10-10'));
    expect(out.contains('{'), isFalse);
    expect(kDefaultMessageTemplates, hasLength(5));
  });

  test('rename validation', () {
    expect(validateNewUsername('ahmad', current: 'ahmad'), isNotNull);
    expect(validateNewUsername('a b', current: 'x'), isNotNull);
    expect(validateNewUsername('ab', current: 'x'), isNotNull);
    expect(validateNewUsername('ahmad.2', current: 'x'), isNull);
  });

  test('Arabic-Indic digits parse', () {
    expect(parseLocalizedNumber('١٢٫٥'), 12.5);
    expect(parseLocalizedNumber('7'), 7);
    expect(parseLocalizedNumber(''), isNull);
  });

  group('context + errors', () {
    test('fromJson reads the contract', () {
      final c = SubscriberActionsContext.fromJson(_contextJson());
      expect(c.plan!.minutes, 43200);
      expect(c.debt, 12.5);
      expect(c.openLoans.map((l) => l.id), [7, 8]);
      expect(c.hasQuota, isTrue);
      expect(c.whatsappEnabled, isFalse);
      expect(c.templates, hasLength(5)); // empty list → web defaults
      expect(
        c.expireAt!.isAtSameMomentAs(DateTime.utc(2026, 10, 10, 21)),
        isTrue,
      );
      expect(c.legacy, isFalse);
    });

    test('404 without envelope = server not updated; 403 = no permission', () {
      final e404 = mapActionError(
        ApiException(
          code: 'not_found',
          message: 'العنصر المطلوب غير موجود.',
          status: 404,
        ),
      );
      expect(e404.notUpdated, isTrue);
      expect(e404.message, kServerNotUpdatedMessage);

      final real404 = mapActionError(
        ApiException(
          code: 'not_found',
          message: 'المشترك غير موجود',
          status: 404,
          details: const {},
        ),
      );
      expect(real404.notUpdated, isFalse);
      expect(real404.message, 'المشترك غير موجود');

      final e403 = mapActionError(
        ApiException(
          code: 'forbidden',
          message: 'لا تملك صلاحية تنفيذ هذا الإجراء.',
          status: 403,
        ),
        what: 'منح السلف',
      );
      expect(e403.forbidden, isTrue);
      expect(e403.message, 'لا تملك صلاحية منح السلف.');

      final server = mapActionError(
        ApiException(code: 'limit', message: 'تجاوزت سقف السلف', status: 400),
      );
      expect(server.message, 'تجاوزت سقف السلف');
    });
  });

  group('availability', () {
    SubscriberActionSpec spec(SubscriberAction a) => [
          ...kActivationActions,
          ...kAdminActions,
        ].firstWhere((s) => s.action == a);

    test('permission=false hides, offline disables disconnect', () {
      final c = SubscriberActionsContext.fromJson(
        _contextJson(permissions: {'extend': false, 'loan': true}),
      );
      expect(
        actionAvailability(spec(SubscriberAction.extend), c).visible,
        isFalse,
      );
      expect(
        actionAvailability(spec(SubscriberAction.loan), c).enabled,
        isTrue,
      );
      final d = actionAvailability(spec(SubscriberAction.disconnect), c);
      expect(d.visible, isTrue);
      expect(d.disabledReason, 'غير متصل الآن');
    });

    test('no quota disables quota actions; legacy disables new ones', () {
      final s = Subscriber.fromJson({'username': 'u1', 'status': 'enabled'});
      final c = SubscriberActionsContext.legacy(s);
      expect(
        actionAvailability(spec(SubscriberAction.payment), c).disabledReason,
        isNotNull,
      );
      expect(
        actionAvailability(spec(SubscriberAction.extend), c).enabled,
        isTrue,
      );
      expect(
        actionAvailability(spec(SubscriberAction.archive), c).enabled,
        isTrue,
      );
      final full = SubscriberActionsContext.fromJson(
        {
          ..._contextJson(),
          'quota': {'has_quota': false},
        },
      );
      expect(
        actionAvailability(spec(SubscriberAction.quotaReset), full)
            .disabledReason,
        'لا توجد كوتة لهذا المشترك',
      );
    });
  });

  testWidgets('sheet hides an action whose permission is false (360×640)',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final c = SubscriberActionsContext.fromJson(
      _contextJson(permissions: {'extend': false, 'delete': false}),
    );
    await tester.pumpWidget(
      _host(
        SubscriberActionsSheet(
          subscriber: Subscriber.fromJson({'username': 'ahmad'}),
          preloaded: ActionsContextResult(c),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('action:extend')), findsNothing);
    expect(find.byKey(const ValueKey('action:archive')), findsNothing);
    expect(find.byKey(const ValueKey('action:payment')), findsOneWidget);
    expect(find.text('تفعيل'), findsOneWidget);
    expect(find.text('غير متصل الآن'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('extend dialog prices paid time live and posts the payload',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = _FakeRepo();
    final c = SubscriberActionsContext.fromJson(_contextJson());
    ActionOutcome? outcome;
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async =>
                outcome = await showActionDialog(context, ExtendDialog(c: c)),
            child: const Text('open'),
          ),
        ),
        overrides: [
          subscriberActionsRepositoryProvider.overrideWithValue(repo),
        ],
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('مدفوع — دين'));
    await tester.pumpAndSettle();
    // 1 day of a 30 ILS / 30-day plan = 1.00
    expect(find.text('1.00'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '3');
    await tester.pumpAndSettle();
    expect(find.text('3.00'), findsOneWidget);
    await tester.tap(find.text('إضافة').last);
    await tester.pumpAndSettle();
    final sent = repo.calls['extend']! as Map<String, dynamic>;
    expect(sent['mode'], 'duration');
    expect(sent['minutes'], 3 * 1440);
    expect(sent['charge_mode'], 'debt');
    expect(sent['amount'], 3.0);
    // money actions carry an Idempotency-Key
    expect(repo.calls['extend_key'], isA<String>());
    expect(outcome?.message, contains('ينتهي'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('appfinal: extend dialog shows the one-year cap and refuses 366 d',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = _FakeRepo();
    final c = SubscriberActionsContext.fromJson(_contextJson());
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showActionDialog(context, ExtendDialog(c: c)),
            child: const Text('open'),
          ),
        ),
        overrides: [
          subscriberActionsRepositoryProvider.overrideWithValue(repo),
        ],
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.textContaining(kExtendCapHint, findRichText: true),
        findsOneWidget,);
    await tester.enterText(find.byType(TextField).first, '366');
    await tester.pumpAndSettle();
    expect(find.textContaining('أقصى تمديد في المرة الواحدة سنة'), findsWidgets);
    await tester.tap(find.text('إضافة').last);
    await tester.pumpAndSettle();
    expect(repo.calls['extend'], isNull, reason: 'never sent');
    expect(tester.takeException(), isNull);
  });
}
