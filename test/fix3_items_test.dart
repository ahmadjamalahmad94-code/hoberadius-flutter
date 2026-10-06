// fix3 (app3) — the FINAL-campaign app «lows» (F01/F03/F04/F06/F07), the
// configurable caps (`system.limits`) and the ambiguous 24-Oct hour.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/core/api/api_client.dart';
import 'package:hoberadius_app/core/auth/permissions.dart';
import 'package:hoberadius_app/core/auth/route_permissions.dart';
import 'package:hoberadius_app/core/format/arabic_plural.dart';
import 'package:hoberadius_app/core/format/bidi.dart';
import 'package:hoberadius_app/core/format/currency.dart';
import 'package:hoberadius_app/core/format/money_limits.dart';
import 'package:hoberadius_app/core/format/panel_time.dart';
import 'package:hoberadius_app/core/l10n/arabic_labels.dart';
import 'package:hoberadius_app/features/accounting/domain/accounting_model.dart';
import 'package:hoberadius_app/features/accounting/presentation/financial_reports_screen.dart';
import 'package:hoberadius_app/features/accounting/presentation/widgets/finance_summary_card.dart';
import 'package:hoberadius_app/features/admins/domain/permission_labels.dart';
import 'package:hoberadius_app/features/cards/domain/card_batch_requests.dart';
import 'package:hoberadius_app/features/dashboard/domain/dashboard_model.dart';
import 'package:hoberadius_app/features/invoices/domain/invoice_model.dart';
import 'package:hoberadius_app/features/invoices/presentation/invoices_screen.dart';
import 'package:hoberadius_app/features/mikrotik/presentation/router_operations_screen.dart';
import 'package:hoberadius_app/features/notifications/domain/notification_model.dart';
import 'package:hoberadius_app/features/notifications/presentation/notification_center_screen.dart';
import 'package:hoberadius_app/features/sessions/data/sessions_repository.dart';
import 'package:hoberadius_app/features/sessions/domain/session_model.dart';
import 'package:hoberadius_app/features/sessions/presentation/sessions_list_screen.dart';
import 'package:hoberadius_app/features/subscribers/application/subscriber_form_mapper.dart';
import 'package:hoberadius_app/features/subscribers/domain/subscriber_actions_model.dart';
import 'package:hoberadius_app/features/subscribers/presentation/widgets/plan_picker.dart';
import 'package:hoberadius_app/features/tools/presentation/widgets/tools_set_speeds_panel.dart';

import 'support/fake_api.dart';

AppPermissions perm(List<String> keys) => AppPermissions.fromMe({
      'admin': {'id': 5, 'is_owner': false},
      'permissions': keys,
      'grants': {
        'actions': <String, bool>{},
        'sections': <String, String>{},
      },
    });

void main() {
  tearDown(() {
    AppLimits.reset();
    PanelTimeZone.reset();
  });

  // ───────────────────────── F06 L5 temp speed ───────────────────────────
  group('temp speed: the router answer decides the message', () {
    test('router did not confirm → a warning with the Arabic reason', () {
      final o = tempSpeedOutcome('f06_u3', {
        'temporary_speed': {
          'mode': 'live_coa',
          'coa': {'ok': false, 'code': 'router_not_configured'},
        },
      });
      expect(o.warning, isTrue);
      expect(o.message, contains('لم يؤكّد تطبيقها'));
      expect(o.message, contains('راوتر الجلسة معطّل أو بلا كلمة سرّ RADIUS'));
      expect(o.message, isNot(contains('router_not_configured')));
    });

    test('applied → success; applied by reauth → says so', () {
      expect(
        tempSpeedOutcome('u', {
          'temporary_speed': {
            'coa': {'ok': true},
          },
        }).warning,
        isFalse,
      );
      expect(
        tempSpeedOutcome('u', {
          'temporary_speed': {
            'mode': 'disconnect_reauth',
            'coa': {'ok': true},
          },
        }).message,
        contains('بالفصل وإعادة الاتصال'),
      );
    });

    test('an older server without coa: the neutral line (no false alarm)', () {
      final o = tempSpeedOutcome('u', const {});
      expect(o.warning, isFalse);
      expect(o.message, contains('تم طلب تطبيق السرعة المؤقتة'));
    });
  });

  // ───────────────────────── F06 L6 speeds tool ──────────────────────────
  group('«السرعات» tool: strict numbers, never a silent 0', () {
    Map<String, dynamic>? body(String plans, String down, String up) =>
        buildSetSpeedsRequest(
          plans: plans,
          down: down,
          up: up,
          dryRun: true,
        ).body;

    test('Arabic digits are read', () {
      final b = body('١، ٢', '٢٠٤٨', '512')!;
      expect(b['plan_ids'], [1, 2]);
      expect(b['set_down'], 2048);
      expect(b['set_up'], 512);
    });

    test('0.5 / abc / -1 are refused, nothing is sent', () {
      for (final bad in ['0.5', 'abc', '-1', '1e3']) {
        final r = buildSetSpeedsRequest(
          plans: '1',
          down: bad,
          up: '512',
          dryRun: true,
        );
        expect(r.body, isNull, reason: bad);
        expect(r.downError, isNotNull, reason: bad);
      }
    });

    test('empty = unchanged; both empty or bad plan ids are errors', () {
      expect(body('1', '', '512')!['set_down'], 0);
      expect(
        buildSetSpeedsRequest(plans: '1', down: '', up: '', dryRun: true)
            .downError,
        isNotNull,
      );
      expect(
        buildSetSpeedsRequest(plans: 'x', down: '1', up: '', dryRun: true)
            .plansError,
        isNotNull,
      );
      expect(
        buildSetSpeedsRequest(
          plans: '1',
          down: '1000001',
          up: '',
          dryRun: true,
        ).downError,
        contains('1,000,000'),
      );
    });
  });

  // ───────────────────────── F06 L7 online counters ──────────────────────
  group('«كل المتصلين» is the whole network', () {
    final subs = [OnlineSession(username: 'a'), OnlineSession(username: 'b')];

    test('under the «المشتركون» tab the tiles use the overall totals', () {
      final c = onlineSummaryCounts(
        filtered:
            const OnlineSessionsQuery(kind: OnlineSessionKind.subscribers),
        items: subs,
        total: 6,
        typeCounts: const {'subscriber': 6, 'card': 0},
        overall: const OnlineTotals(total: 608, subscribers: 6, cards: 602),
      );
      expect(c.allLabel, 'كل المتصلين');
      expect(c.all, 608);
      expect(c.cards, 602);
    });

    test('totals not known yet → «المعروض», never a wrong «كل المتصلين»', () {
      final c = onlineSummaryCounts(
        filtered: const OnlineSessionsQuery(search: 'x'),
        items: subs,
        total: 2,
      );
      expect(c.allLabel, 'المعروض');
      expect(c.all, 2);
    });

    test('no filter: the list counters themselves', () {
      final c = onlineSummaryCounts(
        filtered: const OnlineSessionsQuery(),
        items: subs,
        total: 610,
        typeCounts: const {'subscriber': 8, 'card': 602},
      );
      expect((c.allLabel, c.all, c.cards), ('كل المتصلين', 610, 602));
    });
  });

  // ───────────────────────── F04 L9 money format ─────────────────────────
  group('one money format', () {
    test('grouped, 0 or 2 decimals, currency after', () {
      expect(formatMoneyAmount(7.5), '7.50');
      expect(formatMoneyAmount(1046), '1,046');
      expect(formatMoneyAmount(117.58999999999999), '117.59');
      expect(formatMoneyAmount(-0.001), '0');
      expect(stripBidiMarks(formatWithCurrency(3, 'usd')), '3 USD');
      expect(stripBidiMarks(formatWithCurrency(37.5, 'ILS')), '37.50 ₪');
      expect(stripBidiMarks(formatMoney(7.5, 'ILS')), '7.50 ₪');
    });

    test('a report money cell carries its ROW currency', () {
      expect(
        stripBidiMarks(reportCell({'amount': 3, 'currency': 'USD'}, 'amount')),
        '3 USD',
      );
      expect(reportCell({'amount': 7.5}, 'amount'), '7.50');
    });

    test('7 USD paid is never shown as «7 ILS»', () {
      final f = FinanceSummaryFigures.compute(
        payments: [
          PaymentTransaction(
            id: 44,
            subscriberId: 1,
            username: 'b',
            amount: 7,
            currency: 'USD',
            method: 'cash',
            status: 'posted',
            earnedMinutes: 0,
            ledgerEntryId: null,
            createdAt: null,
          ),
        ],
        loans: const [],
        balance: 0,
        serverTotalPaid: 7,
        currency: 'ILS',
      );
      expect(f.paidByCurrency.single.currency, 'USD');
      expect(f.paidByCurrency.single.amount, 7);
    });

    test('mixed ILS + USD: split per currency', () {
      PaymentTransaction p(num a, String c) => PaymentTransaction(
            id: 1,
            subscriberId: 1,
            username: 'b',
            amount: a,
            currency: c,
            method: 'cash',
            status: 'posted',
            earnedMinutes: 0,
            ledgerEntryId: null,
            createdAt: null,
          );
      final f = FinanceSummaryFigures.compute(
        payments: [p(10, 'ILS'), p(7, 'USD')],
        loans: const [],
        balance: 0,
        serverTotalPaid: 17,
        currency: 'ILS',
      );
      expect(
        f.paidByCurrency.map((c) => '${c.amount} ${c.currency}'),
        ['10.0 ILS', '7.0 USD'],
      );
    });
  });

  // ───────────────────────── F07 N-C7 Arabic plurals ─────────────────────
  group('one Arabic count helper', () {
    test('agreement by the last two digits', () {
      expect(arCount(1, arCard), 'بطاقة');
      expect(arCount(1, arCard, showOne: true), '1 بطاقة');
      expect(arCount(2, arCard), 'بطاقتان');
      expect(arCount(5, arCard), '5 بطاقات');
      expect(arCount(10, arCard), '10 بطاقات');
      expect(arCount(11, arSubscriber), '11 مشتركًا');
      expect(arCount(90, arSubscriber), '90 مشتركًا');
      expect(arCount(3, arSubscriber), '3 مشتركين');
      expect(arCount(100, arCard), '100 بطاقة');
      expect(arCount(103, arCard), '103 بطاقات');
      expect(arCount(0, arCard), '0 بطاقة');
    });

    test('«منذ دقيقتين», not «منذ دقيقتان»', () {
      expect(arSince(2, arMinute), 'منذ دقيقتين');
      expect(arSince(1, arHour), 'منذ ساعة');
      expect(arSince(5, arDay), 'منذ 5 أيام');
      final twoMinAgo = DateTime.now()
          .toUtc()
          .subtract(const Duration(minutes: 2, seconds: 5));
      expect(
        notificationTimeAgo(twoMinAgo.toIso8601String()),
        'منذ دقيقتين',
      );
    });

    test('uptime «23m» / «2d 3h 5m» in Arabic', () {
      expect(formatUptime('23m'), '23 دقيقة');
      expect(formatUptime('3h 5m'), '3 ساعات و5 دقائق');
      expect(formatUptime('2d 3h 5m'), 'يومان و3 ساعات');
      expect(formatUptime(''), '');
      expect(formatUptime('غير معروف'), 'غير معروف');
    });
  });

  // ───────────────────────── F03 N5 owner text ───────────────────────────
  group('the owner text, exactly', () {
    test('debt loan over a year: the owner sentence, no own wording', () {
      final e = validateLoan(type: LoanType.debt, days: 366, hours: 0);
      expect(e, kOneYearExtendMessage);
      expect(e, isNot(contains('سلفة الدين لا تتجاوز')));
    });

    test('extend: no trailing «.»', () {
      expect(validateExtendSpan(366 * 1440), kOneYearExtendMessage);
      expect(validateExtendSpan(366 * 1440)!.endsWith('.'), isFalse);
    });
  });

  // ───────────────────────── configurable caps ───────────────────────────
  group('system.limits', () {
    test('old server (no limits): the fixed defaults', () {
      expect(
          AppLimits.configureFrom({
            'system': {'currency': 'ILS'},
          }),
          isFalse,);
      expect(kMaxMoneyAmount, 100000);
      expect(kMaxExtendDays, 365);
      expect(kMaxExpiryYear, 2100);
      expect(kMaxCardsPerBatch, 10000);
    });

    test('values come from /me system.limits and messages quote them', () {
      AppLimits.configureFrom({
        'system': {
          'limits': {
            'max_extend_days': 90,
            'max_subscriber_payment': 5000,
            'max_subscriber_balance_add': 3000,
            'max_distributor_balance_add': 7000,
            'max_loan_amount': 400,
            'max_amount_generic': 20000,
            'max_expiry_year': 2050,
            'max_cards_per_batch': 500,
          },
        },
      });
      expect(validateExtendSpan(91 * 1440),
          'أقصى تمديد في المرة الواحدة 90 يومًا — كرّر التمديد إن احتجت أكثر',);
      expect(validateExtendSpan(90 * 1440), isNull);
      expect(validateMoneyAmount(5001, cap: MoneyCap.subscriberPayment),
          contains('5,000'),);
      expect(validateMoneyAmount(5001, cap: MoneyCap.generic), isNull);
      expect(
          validateMoneyAmount(401, cap: MoneyCap.loanAmount), contains('400'),);
      expect(validateMoneyAmount(7001, cap: MoneyCap.distributorBalanceAdd),
          contains('7,000'),);
      expect(validateMoneyAmount(20001), contains('20,000'));
      expect(readMoneyInput('٢٠٠٠١').error, contains('20,000'));
      expect(kMaxMoneyHelper, 'الحدّ الأعلى 20,000');
      expect(validateCardCount(501), contains('500'));
      expect(validateCardCount(500), isNull);
      expect(kLastPickableDate.year, 2050);
      expect(
        validateExpiryJump(
          original: null,
          next: DateTime(2051),
          now: DateTime(2050, 12, 1),
        ),
        contains(kExpiryTooFarMessage),
      );
    });

    test('365 days keeps the owner sentence word for word', () {
      AppLimits.configureFrom({
        'limits': {'max_extend_days': 365},
      });
      expect(kMaxExtendMessage, kOneYearExtendMessage);
    });

    test('a missing / invalid field falls back to its default', () {
      AppLimits.configureFrom({
        'system': {
          'limits': {'max_extend_days': 'abc', 'max_amount_generic': -5},
        },
      });
      expect(kMaxExtendDays, 365);
      expect(kMaxMoneyAmount, 100000);
    });

    test('«مشترك جديد»: expiry within the extend cap from now', () {
      final now = DateTime(2026, 10, 1, 10);
      expect(validateNewSubscriberExpiry(null, now), isNull);
      expect(
        validateNewSubscriberExpiry(now.add(const Duration(days: 365)), now),
        isNull,
      );
      expect(
        validateNewSubscriberExpiry(now.add(const Duration(days: 366)), now),
        // the server's create wording (limits.create_too_long_msg)
        startsWith('أقصى مدّة عند إنشاء المشترك سنة من الآن'),
      );
      AppLimits.configureFrom({
        'limits': {'max_extend_days': 30},
      });
      expect(
        validateNewSubscriberExpiry(now.add(const Duration(days: 31)), now),
        contains('30 يومًا'),
      );
      // the form's own check on create says the same
      expect(
        validateExpiryJump(
          original: null,
          next: now.add(const Duration(days: 31)),
          now: now,
          creating: true,
        ),
        contains('30 يومًا'),
      );
    });
  });

  // ───────────────────────── gates (F01 / F07) ───────────────────────────
  group('screens the server would refuse are gated', () {
    test('/loans needs users.loans or reports.finance (not users.view only)',
        () {
      expect(routeDenial(perm(['users.view']), '/loans'), isNotNull);
      expect(
          routeDenial(perm(['users.view', 'users.loans']), '/loans'), isNull,);
      expect(
        routeDenial(perm(['users.view', 'reports.finance']), '/loans'),
        isNull,
      );
    });

    test('/network-devices is the owner\'s (server legacy section)', () {
      expect(routeDenial(perm(['nas.view']), '/network-devices'), isNotNull);
      expect(routeDenial(AppPermissions.unknown, '/network-devices'), isNull);
    });

    test('no-access reason names store.view in Arabic', () {
      final reason = routeDenial(perm(['users.view']), '/card-users')!;
      expect(reason, isNot(contains('store.view')));
      expect(reason, contains(permissionLabel('store.view')));
      expect(permissionLabel('store.view'), isNot('store.view'));
    });

    // fix3: `GET /api/v1/plans/options` is readable with `users.create`
    // alone (no `plans.view` needed) — a manager who can create
    // subscribers now gets a real picker, not the old client-side gate.
    testWidgets(
        'new subscriber with «إنشاء مشترك» (no «عرض الباقات»): the lite '
        'plans/options list is used', (tester) async {
      final ctrl = TextEditingController();
      final adapter = RecordingAdapter((req) {
        if (req.path.contains('/plans/options')) {
          return FakeResponse.ok({
            'items': [
              {'id': 9, 'name': 'باقة خفيفة', 'price': 5, 'currency': 'ILS'},
            ],
          });
        }
        return FakeResponse.error(404, 'not_found', 'غير موجود');
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWithValue(fakeApiClient(adapter)),
            permissionsProvider.overrideWith(
              (ref) => PermissionsController(ref)
                ..apply({
                  'admin': {'id': 5, 'is_owner': false},
                  'permissions': ['users.view', 'users.create'],
                  'grants': {'actions': <String, bool>{}},
                }),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(body: PlanPicker(controller: ctrl)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<int?>));
      await tester.pumpAndSettle();
      expect(find.textContaining('باقة خفيفة'), findsOneWidget);
      expect(adapter.where('GET', '/plans/options'), isNotEmpty);
    });

    testWidgets(
        'new subscriber with no plan-reading permission at all: a clear '
        'message', (tester) async {
      final ctrl = TextEditingController();
      final adapter = RecordingAdapter(
        (req) => FakeResponse.error(403, 'forbidden', 'لا تملك صلاحية.'),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWithValue(fakeApiClient(adapter)),
            permissionsProvider.overrideWith(
              (ref) => PermissionsController(ref)
                ..apply({
                  'admin': {'id': 5, 'is_owner': false},
                  'permissions': ['users.view'],
                  'grants': {'actions': <String, bool>{}},
                }),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(body: PlanPicker(controller: ctrl)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(kNoPlanListMessage), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });
  });

  // ───────────────────────── raw English / tokens ────────────────────────
  group('no raw codes on screen', () {
    test('api-token actors', () {
      expect(actorLabel('api-token:20'), 'التطبيق / مفتاح ربط #20');
      expect(actorLabel('system:backup-scheduler'),
          'النظام: مجدول النسخ الاحتياطي',);
      expect(actorLabel('المدير العام'), 'المدير العام');
      expect(
        actorDisplay({'actor': 'api-token:3', 'actor_label': 'سمير'}),
        'سمير',
      );
      expect(
        humanizeActorsInText('أضافه: api-token:119'),
        'أضافه: التطبيق / مفتاح ربط #119',
      );
      final n = AppNotification.fromJson({
        'id': 1,
        'title': 'إضافة مشترك جديد',
        'body': 'أضافه: api-token:119',
      });
      expect(n.body, isNot(contains('api-token')));
      expect(rawTokenLabel('api-token:12'), 'التطبيق / مفتاح ربط #12');
    });

    test('report action / target codes', () {
      for (final code in [
        'create',
        'extend_time',
        'update',
        'user',
        'auth_login_failed',
        'page_visit',
        'manager_activity',
        'demo-seed',
      ]) {
        expect(rawTokenLabel(code), isNot(code), reason: code);
      }
      expect(rawTokenLabel('hotspot'), 'هوتسبوت');
    });

    test('router operations: lists, ids and statuses in Arabic', () {
      expect(routerDisplayValue(const <Object>[]), 'لا شيء');
      expect(routerDisplayValue([1, 2, 3]), '3 عناصر');
      expect(routerDisplayValue('attention', key: 'status'), 'يحتاج انتباهًا');
    });

    test('dashboard alert «استخدام Disk مرتفع»', () {
      expect(humanizeAlertMessage('استخدام Disk مرتفع'), 'استخدام القرص مرتفع');
      expect(humanizeAlertMessage('Disk high'), 'Disk high');
    });
  });

  // ───────────────────────── F07 N-B6 invoices at 360 ────────────────────
  testWidgets('invoice KPIs fit 360 px and carry the currency', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Padding(
              padding: EdgeInsets.all(12),
              child: InvoiceStatsGrid(
                stats: InvoiceStats(
                  total: 123456.75,
                  paid: 650,
                  pending: 30,
                  failed: 0,
                  refunded: 0,
                  canceled: 0,
                  count: 44,
                ),
                visibleCount: 44,
                currency: 'ILS',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('650 ₪'), findsOneWidget);
    expect(find.textContaining('123,456.75 ₪'), findsOneWidget);
    expect(find.textContaining('ILS'), findsNothing);
  });

  // ───────────────────────── ambiguous hour (F03 N7) ─────────────────────
  group('24 Oct: a repeated local hour is its FIRST occurrence (fold=0)', () {
    test('Asia/Gaza 2026-10-24 01:30 → 22:30Z (+03), as the web', () {
      PanelTimeZone.configure(name: 'Asia/Gaza');
      expect(
        panelWallToInstant(DateTime(2026, 10, 24, 1, 30)),
        DateTime.utc(2026, 10, 23, 22, 30),
      );
      // outside the switch nothing changes
      expect(
        panelWallToInstant(DateTime(2026, 10, 24, 3, 0)),
        DateTime.utc(2026, 10, 24, 1, 0),
      );
      expect(
        panelWallToInstant(DateTime(2026, 7, 1, 12, 0)),
        DateTime.utc(2026, 7, 1, 9, 0),
      );
    });

    test('the label of that wall time says +03:00', () {
      PanelTimeZone.configure(name: 'Asia/Gaza');
      expect(
        PanelTimeZone.offsetLabel(DateTime(2026, 10, 24, 1, 30)),
        'UTC+03:00',
      );
    });

    test('the server table (tz_transitions) when the zone is unknown', () {
      PanelTimeZone.configure(
        name: 'Unknown/Zone',
        offsetHours: 3,
        transitions: PanelTzTransition.listFrom([
          {
            'at': '2026-10-23T23:00:00Z',
            'offset_before_minutes': 180,
            'offset_after_minutes': 120,
          },
        ]),
      );
      expect(
        PanelTimeZone.offsetAt(DateTime.utc(2026, 10, 23, 22)).inMinutes,
        180,
      );
      expect(
        PanelTimeZone.offsetAt(DateTime.utc(2026, 10, 24, 1)).inMinutes,
        120,
      );
      expect(
        panelWallToInstant(DateTime(2026, 10, 24, 1, 30)),
        DateTime.utc(2026, 10, 23, 22, 30),
      );
    });
  });

  // ───────────────────────── plural sites ────────────────────────────────
  test('batch generate texts use the helper', () {
    expect('جاري توليد ${arCount(5, arCard, showOne: true)}…',
        'جاري توليد 5 بطاقات…',);
    expect(formatCurrencyList(const [CurrencyAmount('ILS', 7.5)]),
        contains('7.50 ₪'),);
  });
}
