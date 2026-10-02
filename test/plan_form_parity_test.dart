// Plan form ↔ web form parity (plans_form.html): service type Hotspot /
// PPPoE / Both, the web-only enforced fields (speed_unlimited, offer hours,
// connection_schedule, max_daily_minutes, shared_single_session), units,
// and the legacy fields kept untouched on save.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hoberadius_app/features/plans/application/plan_form_mapper.dart';
import 'package:hoberadius_app/features/plans/domain/plan_model.dart';
import 'package:hoberadius_app/features/plans/presentation/widgets/plan_form_sections.dart';

const _schedule =
    '{"windows":[{"days":["sat","sun"],"from":"08:00","to":"16:00"}]}';

Map<String, TextEditingController> _controllers() => {
      for (final k in [
        ...kPlanNumberFields.keys,
        'name',
        'code',
        'description',
        'color',
        'address_pool',
        'framed_pool',
        'currency',
      ])
        k: TextEditingController(),
    };

Future<void> _pump(WidgetTester tester, Widget child) async {
  SharedPreferences.setMockInitialValues({
    'section.plan.core': true,
    'section.plan.speed': true,
    'section.plan.window': true,
    'section.plan.time': true,
  });
  tester.view.physicalSize = const Size(390, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('model', () {
    test('parses and sends the web-only enforced fields', () {
      final p = Plan.fromJson({
        'id': 1,
        'name': 'x',
        'speed_unlimited': 1,
        'shared_single_session': true,
        'offer_hours_from': '08:00',
        'offer_hours_to': '',
        'connection_schedule': _schedule,
        'max_daily_minutes': 120,
      });
      expect(p.speedUnlimited, isTrue);
      expect(p.sharedSingleSession, isTrue);
      expect(p.offerHoursFrom, '08:00');
      expect(p.offerHoursTo, '');
      expect(p.connectionSchedule, _schedule);
      expect(p.maxDailyMinutes, 120);
      final body = p.toBody();
      expect(body['speed_unlimited'], isTrue);
      expect(body['shared_single_session'], isTrue);
      expect(body['connection_schedule'], _schedule);
      expect(body['offer_hours_from'], '08:00');
      expect(body['offer_hours_to'], '');
      expect(body['max_daily_minutes'], 120);
    });

    test('a missing / decoded schedule is read safely', () {
      expect(Plan.fromJson({'name': 'x'}).connectionSchedule, '');
      expect(Plan.fromJson({'name': 'x'}).speedUnlimited, isFalse);
      final decoded = Plan.fromJson({
        'name': 'x',
        'connection_schedule': {'windows': []},
      });
      expect(decoded.connectionSchedule, '{"windows":[]}');
    });
  });

  group('service type', () {
    test('exactly Hotspot / PPPoE / Both like the web', () {
      expect(
        planServiceTypeOptions('Hotspot').map((e) => e.$1),
        ['Hotspot', 'PPPoE', 'Both'],
      );
      expect(planServiceTypeOptions('Both').length, 3);
      expect(planServiceTypeOptions('PPPoE').map((e) => e.$2).toList(), [
        'هوت سبوت',
        'برودباند',
        'كلاهما (هوت سبوت + برودباند)',
      ]);
    });

    test('a legacy stored value stays selectable, marked «(قديم)»', () {
      final balance = planServiceTypeOptions('Balance');
      expect(balance.length, 4);
      expect(balance.last, ('Balance', 'رصيد (قديم)'));
      expect(planServiceTypeOptions('both').last.$1, 'both');
      expect(planServiceTypeOptions('').last.$2, 'غير محدّد (قديم)');
    });

    testWidgets('a web plan stored as Both opens without changing it',
        (tester) async {
      String? changed;
      await _pump(
        tester,
        PlanCoreSection(
          controllers: _controllers(),
          planType: 'time',
          serviceType: 'Both',
          enabled: true,
          onPlanTypeChanged: (_) {},
          onServiceTypeChanged: (v) => changed = v,
          onEnabledChanged: (_) {},
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('كلاهما (هوت سبوت + برودباند)'), findsOneWidget);
      expect(changed, isNull);
    });

    testWidgets('a legacy «Voucher» plan shows «قسيمة (قديم)»',
        (tester) async {
      await _pump(
        tester,
        PlanCoreSection(
          controllers: _controllers(),
          planType: 'time',
          serviceType: 'Voucher',
          enabled: true,
          onPlanTypeChanged: (_) {},
          onServiceTypeChanged: (_) {},
          onEnabledChanged: (_) {},
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('قسيمة (قديم)'), findsOneWidget);
    });
  });

  group('mapper', () {
    test('legacy fallbacks and derived service flags are kept untouched', () {
      final loaded = Plan(
        id: 3,
        name: 'x',
        serviceType: 'Both',
        hotspotEnabled: true,
        pppEnabled: false,
        allowedDays: const ['sat', 'sun'],
        allowedHoursFrom: '07:00',
        allowedHoursTo: '19:00',
        speedDownKbps: 2048,
        speedUpKbps: 1024,
        connectionSchedule: _schedule,
        offerHoursFrom: '09:00',
        maxDailyMinutes: 90,
        sharedSingleSession: true,
      );
      final c = _controllers();
      applyPlanToForm(loaded, c);
      expect(c['max_daily_minutes']!.text, '90');
      final sel = selectionsFromPlan(loaded);
      expect(sel.connectionSchedule, _schedule);
      expect(sel.offerHoursFrom, '09:00');
      expect(sel.offerHoursTo, '');
      final out = buildPlanFromForm(c, sel, base: loaded);
      expect(out.serviceType, 'Both');
      expect(out.hotspotEnabled, isTrue);
      expect(out.pppEnabled, isFalse);
      expect(out.allowedDays, ['sat', 'sun']);
      expect(out.allowedHoursFrom, '07:00');
      expect(out.allowedHoursTo, '19:00');
      expect(out.connectionSchedule, _schedule);
      expect(out.offerHoursFrom, '09:00');
      expect(out.offerHoursTo, '');
      expect(out.maxDailyMinutes, 90);
      expect(out.sharedSingleSession, isTrue);
      expect(out.speedDownKbps, 2048);
    });

    test('a 0 speed needs «بلا حدّ للسرعة» (the server rule)', () {
      final c = _controllers();
      c['speed_down_kbps']!.text = '0';
      c['speed_up_kbps']!.text = '512';
      expect(
        planFormSpeedError(c, speedUnlimited: false),
        contains('بلا حدّ للسرعة'),
      );
      expect(planFormSpeedError(c, speedUnlimited: true), isNull);
      c['speed_down_kbps']!.text = '1024';
      expect(planFormSpeedError(c, speedUnlimited: false), isNull);
    });

    test('«حد يومي» is validated like the other numbers', () {
      final c = _controllers();
      c['max_daily_minutes']!.text = 'abc';
      expect(planFormNumberError(c), contains('حد يومي'));
    });
  });

  group('inputs', () {
    testWidgets('offer hours stay EMPTY when unset — no fake 08:00/22:00',
        (tester) async {
      await _pump(
        tester,
        PlanWindowSection(
          offerHoursFrom: '',
          offerHoursTo: '',
          connectionSchedule: '',
          onOfferHoursFromChanged: (_) {},
          onOfferHoursToChanged: (_) {},
          onConnectionScheduleChanged: (_) {},
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('غير محدّد'), findsNWidgets(2));
      expect(find.text('08:00'), findsNothing);
      expect(find.text('22:00'), findsNothing);
      expect(
        find.textContaining('ساعات الباقة — من', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('a set offer hour can be cleared back to empty',
        (tester) async {
      String? from;
      await _pump(
        tester,
        PlanWindowSection(
          offerHoursFrom: '09:30',
          offerHoursTo: '',
          connectionSchedule: _schedule,
          onOfferHoursFromChanged: (v) => from = v,
          onOfferHoursToChanged: (_) {},
          onConnectionScheduleChanged: (_) {},
        ),
      );
      expect(find.text('09:30'), findsOneWidget);
      await tester.tap(find.byTooltip('مسح'));
      expect(from, '');
    });

    testWidgets('speed: Mbps typed → kbps stored in the controller; '
        '«بلا حدّ للسرعة» disables the inputs', (tester) async {
      final c = _controllers();
      c['speed_down_kbps']!.text = '2048';
      c['speed_up_kbps']!.text = '512';
      Widget section(bool unlimited) => PlanSpeedSection(
            controllers: c,
            speedUnlimited: unlimited,
            onSpeedUnlimitedChanged: (_) {},
            speedControl: false,
            onSpeedControlChanged: (_) {},
            burstEnabled: false,
            onBurstEnabledChanged: (_) {},
            nightlyUnlimited: false,
            onNightlyUnlimitedChanged: (_) {},
          );
      await _pump(tester, section(false));
      expect(find.text('بلا حدّ للسرعة'), findsOneWidget);
      // 2048 kbps shows as «2» Mbps.
      final down = find.widgetWithText(TextField, '2');
      expect(down, findsOneWidget);
      await tester.enterText(down, '3');
      expect(c['speed_down_kbps']!.text, '3072');
      expect(planFormNumberError(c), isNull);
      expect(find.text(kPlanNotAppliedHint, findRichText: true), findsWidgets);

      await _pump(tester, section(true));
      final fields = tester
          .widgetList<TextField>(find.byType(TextField))
          .where((f) => f.enabled == false);
      expect(fields.length, 2);
    });
  });
}
