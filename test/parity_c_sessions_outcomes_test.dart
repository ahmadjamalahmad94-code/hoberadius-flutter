// parity-c (2026-10-02): the online screen's action messages say what the
// web says — «إلغاء السرعة» with no active window is NOT a success, and
// «تغيير الوقت» reports exhaustion / remaining time / the router's answer.
import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/sessions/presentation/sessions_list_screen.dart';

void main() {
  group('cancelTempSpeedOutcome', () {
    test('reverted=false → «لا توجد سرعة مؤقتة فعّالة»', () {
      final o = cancelTempSpeedOutcome('u1', {
        'temporary_speed': {'reverted': false, 'reason': 'no_temp_window'},
      });
      expect(o.message, contains('لا توجد سرعة مؤقتة فعّالة'));
      expect(o.warning, isFalse);
    });
    test('reverted=true → cancelled and restored', () {
      final o = cancelTempSpeedOutcome('u1', {
        'temporary_speed': {'reverted': true},
      });
      expect(o.message, contains('تم إلغاء السرعة المؤقتة'));
    });
    test('older server (no flag) keeps the neutral line', () {
      expect(
        cancelTempSpeedOutcome('u1', const {}).message,
        contains('تم طلب إلغاء'),
      );
    });
  });

  group('cardTimeOutcome', () {
    const sub = CardTimeDraft(amount: 2, unit: 'hours', subtract: true);
    const add = CardTimeDraft(amount: 30, unit: 'minutes', subtract: false);
    test('exhausted subtraction is a warning', () {
      final o = cardTimeOutcome('c1', sub, {
        'adjustment': {'exhausted': true, 'remaining_seconds': 0},
      });
      expect(o.warning, isTrue);
      expect(o.message, contains('استُنفد'));
    });
    test('remaining time + CoA ack', () {
      final o = cardTimeOutcome('c1', add, {
        'adjustment': {
          'exhausted': false,
          'remaining_seconds': 5400,
          'coa': {'ok': true, 'code': 'ack'},
        },
      });
      expect(o.warning, isFalse);
      expect(o.message, contains('المتبقي الآن: 1 ساعة و 30 دقيقة'));
      expect(o.message, contains('وصل التحديث'));
    });
    test('no live session is info, a NAK is a warning', () {
      final info = cardTimeOutcome('c1', add, {
        'adjustment': {
          'remaining_seconds': 600,
          'coa': {'ok': false, 'code': 'no_active_session'},
        },
      });
      expect(info.warning, isFalse);
      expect(info.message, contains('الجلسة التالية'));
      final nak = cardTimeOutcome('c1', add, {
        'adjustment': {
          'remaining_seconds': 600,
          'coa': {'ok': false, 'code': 'nak'},
        },
      });
      expect(nak.warning, isTrue);
    });
    test('older server (no adjustment) → plain line', () {
      final o = cardTimeOutcome('c1', add, {'card': <String, dynamic>{}});
      expect(o.message, contains('تمت إضافة 30 دقيقة'));
    });
  });
}
