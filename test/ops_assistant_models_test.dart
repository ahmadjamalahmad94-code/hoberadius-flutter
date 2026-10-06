import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/ops_assistant/domain/ops_labels.dart';
import 'package:hoberadius_app/features/ops_assistant/domain/ops_models.dart';

void main() {
  group('OpsStatus', () {
    test('available', () {
      final s = OpsStatus.fromJson({
        'ok': true,
        'data': {
          'available': true,
          'flag_enabled': true,
          'reason': '',
          'password_gate': {'ready': true, 'admins_checked': 3},
          'catalog_version': 'ops-v2',
        },
      });
      expect(s.available, isTrue);
      expect(s.unavailableReason, isNull);
      expect(s.passwordGate!.adminsChecked, 3);
      expect(s.catalogVersion, 'ops-v2');
    });

    test('flag off → disabled', () {
      final s = OpsStatus.fromJson({
        'data': {
          'available': false,
          'flag_enabled': false,
          'reason': 'disabled',
        },
      });
      expect(s.unavailableReason, OpsUnavailableReason.disabled);
    });

    test('password gate → counts only', () {
      final s = OpsStatus.fromJson({
        'data': {
          'available': false,
          'flag_enabled': true,
          'reason': 'weak_admin_passwords',
          'password_gate': {
            'ready': false,
            'admins_checked': 4,
            'default_password_count': 2,
            'must_change_count': 1,
          },
        },
      });
      expect(s.unavailableReason, OpsUnavailableReason.weakAdminPasswords);
      expect(s.passwordGate!.defaultPasswordCount, 2);
      expect(s.passwordGate!.mustChangeCount, 1);
    });

    test('not supported', () {
      expect(
        const OpsStatus.notSupported().unavailableReason,
        OpsUnavailableReason.notSupported,
      );
    });
  });

  test('detector events → one suggestion per record (web event_records)', () {
    final list = opsSuggestionsFromEvents({
      'data': {
        'items': [
          {
            'type': 'expiring_tomorrow',
            'data': {'date_local': '2026-10-08', 'count': 4, 'subscribers': []},
          },
          {
            'type': 'repeated_rejects',
            'data': {
              'window_minutes': 15,
              'nas': [
                {'nas': 'R1', 'rejects': 30},
                {'nas': 'R2', 'rejects': 21},
              ],
            },
          },
          {
            'type': 'low_card_stock',
            'data': {
              'threshold': 20,
              'plans': [
                {'plan_id': 1, 'plan_name': 'ساعة', 'unused_cards': 5},
              ],
            },
          },
          {
            'type': 'plan_without_offers',
            'data': {
              'plans': [
                {'plan_id': 2, 'plan_name': 'شهري'},
              ],
            },
          },
          {'type': 'unknown_type', 'data': {}},
        ],
      },
    });
    expect(list.length, 5);
    expect(list[0].title, 'اشتراكات تنتهي غدًا');
    expect(list[0].text, '4 مشترك ينتهي اشتراكه يوم 2026-10-08.');
    expect(list[2].eventType, 'repeated_rejects');
    expect(list[2].index, 1);
    expect(list[2].text, contains('«R2»'));
    expect(list[3].text, 'الباقة «ساعة»: 5 كرت غير مستخدم (الحدّ 20).');
    expect(list[4].text, 'الباقة «شهري» لا يبيعها أيّ عرض فعّال.');
  });

  group('OpsReply', () {
    test('choices carry the empty-state LINE', () {
      final r = OpsReply.fromJson({
        'type': 'choices',
        'source': 'list_offers',
        'items': [],
        'text': 'ما وجدت عروضًا',
        'empty': 'لا توجد عروض مسجّلة في النظام بعد…',
      });
      expect(r.type, OpsReplyType.choices);
      expect(r.emptyFlag, isTrue);
      expect(r.emptyText, 'لا توجد عروض مسجّلة في النظام بعد…');
    });

    test('assistant empty: true (repeated empty lookup)', () {
      final r = OpsReply.fromJson({
        'type': 'assistant',
        'action': 'reply',
        'empty': true,
        'text': 'لا يوجد',
      });
      expect(r.emptyFlag, isTrue);
      expect(r.emptyText, '');
    });

    test('proposal with steps, names and refs', () {
      final r = OpsReply.fromJson({
        'type': 'proposal',
        'action': 'plan',
        'text': 'خطّة',
        'proposal': {
          'proposal_id': 'p1',
          'proposal_hash': 'h1',
          'level': 3,
          'steps': [
            {
              'n': 1,
              'action': 'create_subscriber',
              'title_ar': 'إنشاء مشترك',
              'danger': 'L2',
              'values': {'username': 'ahmad', 'plan_id': 3},
              'display': {'expire_local': '2026-11-07 10:00'},
              'names': {'plan_id': 'شهري'},
              'password': 'generated_and_shown_once',
              'pending_refs': {},
              'executable': true,
            },
            {
              'n': 2,
              'action': 'extend_subscriber',
              'title_ar': 'تمديد',
              'danger': 'L3',
              'values': {'charge_mode': 'paid'},
              'pending_refs': {'username': r'$step1.username'},
              'executable': false,
            },
          ],
          'not_executable_steps': [2],
        },
      });
      final p = r.proposal!;
      expect(p.isPlan, isTrue);
      expect(p.level, 3);
      expect(p.notExecutableSteps, [2]);
      expect(p.steps[0].password, 'generated_and_shown_once');
      expect(p.steps[1].executable, isFalse);
      expect(p.steps[1].danger, 'L3');

      final rows0 = opsStepRows(
        values: p.steps[0].values,
        display: p.steps[0].display,
        names: p.steps[0].names,
        pendingRefs: p.steps[0].pendingRefs,
      );
      expect(rows0, contains(('الباقة', 'شهري (#3)')));
      expect(rows0, contains(('ينتهي', '2026-11-07 10:00')));
      final rows1 = opsStepRows(
        values: p.steps[1].values,
        display: p.steps[1].display,
        names: p.steps[1].names,
        pendingRefs: p.steps[1].pendingRefs,
      );
      expect(rows1, contains(('طريقة الحساب', 'مدفوع من الرصيد')));
      expect(rows1, contains(('اسم المستخدم', 'من نتيجة الخطوة 1')));
    });

    test('expire_at is hidden when the local time is displayed', () {
      final rows = opsStepRows(
        values: {'expire_at': '2026-11-07T07:00:00Z'},
        display: {'expire_local': 'no_expiry'},
        names: const {},
        pendingRefs: const {},
      );
      expect(rows, [('ينتهي', 'بلا انتهاء')]);
    });
  });

  test('confirm outcome: report + one-time secrets', () {
    final o = OpsConfirmOutcome.fromJson({
      'ok': true,
      'data': {
        'report': {
          'status': 'partial',
          'steps': [
            {'n': 1, 'action': 'create_subscriber', 'status': 'done'},
            {
              'n': 2,
              'action': 'temporary_speed',
              'status': 'failed',
              'error': {
                'code': 'not_online',
                'message': 'المشترك غير متّصل الآن',
              },
            },
            {'n': 3, 'action': 'extend_subscriber', 'status': 'not_run'},
          ],
        },
        'show_once': {
          'subscriber_passwords': [
            {'username': 'ahmad', 'password': 'Xy7pQ2mn4k'},
          ],
        },
      },
    });
    expect(o.report.status, 'partial');
    expect(o.report.steps[1].errorMessage, 'المشترك غير متّصل الآن');
    expect(o.secrets.single.password, 'Xy7pQ2mn4k');
    expect(OpsTexts.reportStatus('partial'), 'نُفّذ جزئيًّا — راجع الخطوات');
    expect(OpsTexts.stepStatus('not_run'), 'لم يُنفَّذ');
  });

  test('labels and values (web fmtValue)', () {
    expect(opsFormatValue('online', true), 'نعم');
    expect(opsFormatValue('status', 'exhausted'), 'نفدت كروتها');
    expect(opsFormatValue('name', 'active'), 'active');
    expect(opsFormatValue('x', null), '-');
    expect(
      opsFormatValue('expire_local', 'server_default:30d'),
      'حسب إعداد الخادم',
    );
    expect(
      opsInfoRows({'batch_id': 4, 'total_cards': 100, 'items': []}),
      [('كل الكروت', '100')],
    );
    expect(
      opsChoiceLine({'n': 1, 'id': 9, 'name': 'شهري', 'price': 50}),
      'شهري · 50',
    );
    expect(
      opsOnlineLine({
        'username': 'u1',
        'user_type': 'card',
        'started_local': '10:00',
      }),
      'u1 · كرت · 10:00',
    );
  });
}
