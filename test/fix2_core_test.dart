// FIX2 (re-test campaign) — shared number input, money/extend caps and the
// panel time zone.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/core/auth/auth_controller.dart';
import 'package:hoberadius_app/core/format/bidi.dart';
import 'package:hoberadius_app/core/format/money_limits.dart';
import 'package:hoberadius_app/core/format/number_input.dart';
import 'package:hoberadius_app/core/format/panel_time.dart';
import 'package:hoberadius_app/core/format/server_time.dart';
import 'package:hoberadius_app/features/subscribers/domain/subscriber_actions_model.dart';
import 'package:hoberadius_app/shared/widgets/number_text_field.dart';

void main() {
  group('1 — one strict number reader', () {
    test('Arabic-Indic digits and «٫» / «.» are accepted', () {
      expect(readNumberInput('١٢٫٥').value, 12.5);
      expect(readNumberInput('7.5').value, 7.5);
      expect(readNumberInput('۱۵').value, 15);
      expect(readNumberInput(' 42 ').value, 42);
      expect(parseIntInput('٩'), 9);
    });

    test('«1e9», «-1», «1,5», text are refused — never rewritten', () {
      expect(readNumberInput('1e9').error, contains('e'));
      expect(readNumberInput('1e9').value, isNull);
      expect(readNumberInput('-1').error, contains('السالبة'));
      expect(readNumberInput('1,5').error, isNotNull);
      expect(readNumberInput('abc').error, isNotNull);
      expect(readNumberInput('1.2.3').error, isNotNull);
      expect(parseLocalizedNumber('1e9'), isNull);
      expect(parseLocalizedNumber('-5'), isNull);
      expect(parseLocalizedNumber('١٢٫٥'), 12.5);
    });

    test('whole-number fields refuse a fraction', () {
      expect(readNumberInput('7.5', decimal: false).error, contains('كسور'));
      expect(readNumberInput('7', decimal: false).value, 7);
    });

    test('negative allowed only when asked', () {
      expect(readNumberInput('-3', allowNegative: true).value, -3);
    });

    test('validator: empty/required, bounds', () {
      expect(validateNumberInput(''), 'مطلوب');
      expect(validateNumberInput('', required: false), isNull);
      expect(validateNumberInput('5', max: 3), isNotNull);
      expect(validateNumberInput('0', min: 0, minExclusive: true), isNotNull);
      expect(validateNumberInput('٣', min: 1, max: 5), isNull);
    });

    test('the shared formatters never strip characters', () {
      final f = numberFieldFormatters.single;
      const typed = TextEditingValue(text: '1e9-');
      expect(f.formatEditUpdate(TextEditingValue.empty, typed).text, '1e9-');
    });

    testWidgets('NumberTextField shows why «1e9» is refused', (tester) async {
      final c = TextEditingController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NumberTextField(
              controller: c,
              extraError: (v) => validateMoneyAmount(v),
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), '1e9');
      await tester.pump();
      expect(c.text, '1e9', reason: 'the text is kept as typed');
      expect(find.textContaining('«e»'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '200000');
      await tester.pump();
      expect(find.textContaining('100,000'), findsOneWidget);
    });
  });

  group('2 — caps', () {
    test('money ≤ 100,000; 1,000,000 refused', () {
      expect(validateMoneyAmount(100000), isNull);
      expect(validateMoneyAmount(1000000), contains('100,000'));
      expect(validateMoneyAmount(0.001), isNotNull);
    });

    test('one extension ≤ a year with the owner wording', () {
      expect(validateExtendSpan(365 * 1440), isNull);
      expect(
        validateExtendSpan(366 * 1440),
        contains('أقصى تمديد في المرة الواحدة سنة'),
      );
    });

    final now = DateTime(2026, 10, 1, 12);
    test('extend dialog: a year max, 2100 max, paid needs a price', () {
      String? reason({
        String text = '1',
        int minutes = 1440,
        ChargeMode charge = ChargeMode.free,
        double price = 0,
        bool unpriced = false,
        DateTime? anchor,
      }) =>
          extendInvalidReason(
            mode: ExtendMode.duration,
            amountText: text,
            minutes: minutes,
            charge: charge,
            price: price,
            unpriced: unpriced,
            anchor: anchor ?? now,
          );
      expect(reason(), isNull);
      expect(reason(text: '1e9', minutes: 0), contains('e'));
      expect(reason(text: '-5', minutes: 0), contains('السالبة'));
      expect(reason(minutes: 400 * 1440), contains('سنة'));
      expect(
        reason(minutes: 30 * 1440, anchor: DateTime(2100, 12, 20)),
        contains(kExpiryTooFarMessage),
      );
      // Free plan: «مدفوع» with a 0.00 price is refused (was recorded).
      expect(
        reason(charge: ChargeMode.paid, unpriced: true),
        contains('مجاني'),
      );
      expect(reason(charge: ChargeMode.debt, price: 3), isNull);
    });

    test('payment → time counts only what is left after debts', () {
      expect(
        paymentExtendMinutes(
          amount: 50,
          debt: 20,
          effectivePrice: 30,
          planMinutes: 30 * 1440,
        ),
        30 * 1440,
      );
      // 400 days bought in one payment → the one-year rule.
      expect(
        validateExtendSpan(
          paymentExtendMinutes(
            amount: 400,
            effectivePrice: 30,
            planMinutes: 30 * 1440,
          ),
        ),
        isNotNull,
      );
    });

    test('loans: 366 debt days → one-year rule', () {
      expect(
        validateLoan(type: LoanType.debt, days: 366, hours: 0),
        contains('سنة'),
      );
    });
  });

  group('3 — panel time zone', () {
    tearDown(PanelTimeZone.reset);

    test('Asia/Gaza: winter UTC+2, summer UTC+3 (DST from the tz database)',
        () {
      PanelTimeZone.configure(name: 'Asia/Gaza', offsetHours: 3);
      final winter = parseServerDateTime('2026-12-01T12:30:00Z')!;
      expect([winter.hour, winter.minute], [14, 30]);
      final summer = parseServerDateTime('2026-07-01T12:30:00Z')!;
      expect([summer.hour, summer.minute], [15, 30]);
      // A time picked on the panel clock is sent as the right UTC instant.
      expect(toServerUtcIso(DateTime(2027, 1, 15, 14, 30)),
          '2027-01-15T12:30:00Z');
      expect(toServerUtcIso(DateTime(2026, 7, 1, 15, 30)),
          '2026-07-01T12:30:00Z');
    });

    test('the late-October switch changes the offset', () {
      PanelTimeZone.configure(name: 'Asia/Gaza');
      final before = PanelTimeZone.offsetAt(DateTime.utc(2026, 10, 10));
      final after = PanelTimeZone.offsetAt(DateTime.utc(2026, 11, 10));
      expect(before, const Duration(hours: 3));
      expect(after, const Duration(hours: 2));
    });

    test('round trip is stable across the switch', () {
      PanelTimeZone.configure(name: 'Asia/Hebron');
      for (final iso in [
        '2026-10-23T21:59:00Z',
        '2026-10-24T00:30:00Z',
        '2026-11-01T08:00:00Z',
        '2027-03-28T10:00:00Z',
      ]) {
        final wall = parseServerDateTime(iso)!;
        expect(toServerUtcIso(wall), iso.replaceAll('.000', ''));
      }
    });

    test('unknown name → the server offset; nothing → the phone', () {
      PanelTimeZone.configure(name: 'Mars/Base', offsetHours: 3);
      expect(parseServerDateTime('2026-12-01T12:30:00Z')!.hour, 15);
      PanelTimeZone.reset();
      final local = DateTime.utc(2026, 12, 1, 12, 30).toLocal();
      expect(parseServerDateTime('2026-12-01T12:30:00Z'), local);
    });

    test('the label names the zone, isolated for RTL', () {
      PanelTimeZone.configure(name: 'Asia/Gaza');
      final label = PanelTimeZone.label(DateTime.utc(2026, 12, 1));
      expect(stripBidiMarks(label), 'بتوقيت اللوحة: Asia/Gaza (UTC+02:00)');
      expect(label, contains(kLtrIsolate));
    });

    test('read from /api/admin/me (new and old field names)', () {
      expect(
        applyPanelTimeZoneFrom({
          'system': {'timezone': 'Asia/Gaza', 'utc_offset_minutes': 120},
        }),
        isTrue,
      );
      expect(PanelTimeZone.name, 'Asia/Gaza');
      expect(
        applyPanelTimeZoneFrom({
          'system': {'tz_name': 'Asia/Damascus', 'tz_offset': 3.0},
        }),
        isTrue,
      );
      expect(PanelTimeZone.name, 'Asia/Damascus');
      expect(applyPanelTimeZoneFrom({'admin': {}}), isFalse);
      expect(
        applyPanelTimeZoneFromSettings({
          'settings': {
            'billing.timezone': 'Asia/Hebron',
            'billing.timezone_offset': '2',
          },
        }),
        isTrue,
      );
      expect(PanelTimeZone.name, 'Asia/Hebron');
    });

    test('panelNow is on the panel clock', () {
      PanelTimeZone.configure(name: 'Asia/Gaza');
      final clock = DateTime.utc(2026, 12, 1, 12);
      expect(panelNow(clock).hour, 14);
    });
  });

  group('bidi helpers', () {
    test('isolates wrap and strip', () {
      expect(stripBidiMarks(ltrIsolate('@r11_dist')), '@r11_dist');
      expect(ltrIsolate(''), '');
      expect(autoIsolate('r04_meta').length, 'r04_meta'.length + 2);
    });
  });
}
