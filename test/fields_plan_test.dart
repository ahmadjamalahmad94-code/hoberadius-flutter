// FIELDS (team plan, owner 2026-10-06) — plan form ↔ web parity after the
// dead-field decisions: removed fields gone from the form and the request
// body; Burst / CIR / «غير محدود ليلًا» (+ من/إلى) wired; «تجديد تلقائي» is
// a mode (off / debt / balance / free); «مدفوع مسبقًا» a report label;
// «استخدام مرة واحدة» a temporary account.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hoberadius_app/features/plans/application/plan_form_mapper.dart';
import 'package:hoberadius_app/features/plans/domain/plan_model.dart';
import 'package:hoberadius_app/features/plans/presentation/widgets/plan_form_sections.dart';
import 'package:hoberadius_app/features/subscribers/domain/subscriber_model.dart';

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
    'section.plan.speed': true,
    'section.plan.session': true,
    'section.plan.commerce': true,
    'section.plan.loan_device': true,
    'section.plan.services': true,
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

const _removedKeys = [
  'speed_control_enabled',
  'vlan_id',
  'bind_mac',
  'bind_ip',
  'force_mac_address',
  'speed_override_allowed',
  'allowed_devices_count',
  'plan_tier',
  'auto_renew',
];

void main() {
  group('model', () {
    test('removed fields are read but never sent; new fields round-trip', () {
      final p = Plan.fromJson({
        'id': 3,
        'name': 'Night',
        'vlan_id': 7,
        'bind_mac': true,
        'plan_tier': 'Business',
        'auto_renew': true,
        'auto_renew_mode': 'balance',
        'nightly_unlimited_enabled': true,
        'nightly_from': '23:00',
        'nightly_to': '07:00',
      });
      expect(p.vlanId, 7);
      expect(p.autoRenewMode, 'balance');
      expect((p.nightlyFrom, p.nightlyTo), ('23:00', '07:00'));
      final body = p.toBody();
      for (final k in _removedKeys) {
        expect(body.containsKey(k), isFalse, reason: k);
      }
      expect(body['auto_renew_mode'], 'balance');
      expect(body['nightly_from'], '23:00');
      expect(body['nightly_to'], '07:00');
    });

    test('unknown auto-renew mode reads as «بدون»', () {
      final odd = Plan.fromJson({'name': 'x', 'auto_renew_mode': 'weekly'});
      expect(odd.autoRenewMode, 'off');
      expect(Plan.fromJson({'name': 'x'}).autoRenewMode, 'off');
    });

    test('buildPlanFromForm carries mode + night window + prepaid', () {
      final c = _controllers();
      c['name']!.text = 'P';
      final plan = buildPlanFromForm(
        c,
        const PlanFormSelections(
          planType: 'time',
          serviceType: 'Hotspot',
          enabled: true,
          burstEnabled: false,
          nightlyUnlimited: true,
          nightlyFrom: '22:00',
          nightlyTo: '06:00',
          singleUseOnce: true,
          prepaid: false,
          loanEnabled: false,
          autoRenewMode: 'debt',
        ),
      );
      expect(plan.autoRenewMode, 'debt');
      expect(plan.autoRenew, isTrue);
      expect((plan.nightlyFrom, plan.nightlyTo), ('22:00', '06:00'));
      expect(plan.prepaid, isFalse);
      expect(plan.singleUseOnce, isTrue);
      expect(plan.toBody().containsKey('auto_renew'), isFalse);
    });

    test('subscriber list item reads «مؤقت» (temporary_account)', () {
      final tmp = Subscriber.fromJson({
        'username': 'a',
        'temporary_account': true,
      });
      expect(tmp.temporaryAccount, isTrue);
      expect(Subscriber.fromJson({'username': 'b'}).temporaryAccount, isFalse);
    });

    test('removed number fields are no longer validated', () {
      expect(kPlanNumberFields.containsKey('vlan_id'), isFalse);
      expect(kPlanNumberFields.containsKey('allowed_devices_count'), isFalse);
    });
  });

  group('widgets', () {
    testWidgets('speed: night window pickers, no dead hint', (tester) async {
      String from = '';
      await _pump(
        tester,
        PlanSpeedSection(
          controllers: _controllers(),
          speedUnlimited: false,
          onSpeedUnlimitedChanged: (_) {},
          burstEnabled: true,
          onBurstEnabledChanged: (_) {},
          nightlyUnlimited: true,
          onNightlyUnlimitedChanged: (_) {},
          nightlyFrom: '23:30',
          onNightlyFromChanged: (v) => from = v,
        ),
      );
      expect(find.text('تفعيل التحكم بالسرعة'), findsNothing);
      expect(find.text('لا يُطبَّق حاليًا', findRichText: true), findsNothing);
      expect(find.text('23:30'), findsOneWidget);
      await tester.tap(find.byTooltip('مسح'));
      expect(from, '');
    });

    testWidgets('session: no VLAN / bind MAC / bind IP', (tester) async {
      await _pump(
        tester,
        PlanSessionSection(
          controllers: _controllers(),
          sharedSingleSession: false,
          onSharedSingleSessionChanged: (_) {},
        ),
      );
      expect(find.text('معرّف VLAN'), findsNothing);
      expect(find.text('ربط MAC'), findsNothing);
      expect(find.text('ربط IP'), findsNothing);
      expect(find.text('الجلسات المتزامنة'), findsOneWidget);
    });

    testWidgets('commerce: auto-renew mode selector, no «الفئة»',
        (tester) async {
      String mode = 'off';
      await _pump(
        tester,
        StatefulBuilder(
          builder: (context, setState) => PlanCommerceSection(
            controllers: _controllers(),
            prepaid: true,
            autoRenewMode: mode,
            onPrepaidChanged: (_) {},
            onAutoRenewModeChanged: (v) => setState(() => mode = v),
          ),
        ),
      );
      expect(find.text('الفئة'), findsNothing);
      expect(find.text('مدفوع مسبقًا'), findsOneWidget);
      await tester.tap(find.text('بدون'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('خصم من الرصيد المتاح').last);
      await tester.pumpAndSettle();
      expect(mode, 'balance');
    });

    testWidgets('loans: no speed override / force MAC / device count',
        (tester) async {
      await _pump(
        tester,
        PlanLoanDeviceSection(
          controllers: _controllers(),
          loanEnabled: true,
          onLoanEnabledChanged: (_) {},
        ),
      );
      expect(find.text('تجاوز سرعة المستفيد'), findsNothing);
      expect(find.text('إلزام ربط الـ MAC'), findsNothing);
      expect(find.text('عدد الأجهزة المسموحة'), findsNothing);
      expect(find.text('أقصى دقائق السلفة'), findsOneWidget);
    });

    testWidgets('single use explains the temporary account', (tester) async {
      await _pump(
        tester,
        PlanServicesSection(singleUseOnce: true, onSingleUseChanged: (_) {}),
      );
      expect(find.text(kPlanSingleUseHint, findRichText: true), findsOneWidget);
    });
  });
}
