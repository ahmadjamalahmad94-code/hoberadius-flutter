// PARITY r6 (team a) — subscriber form fields vs the web form.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/subscribers/application/subscriber_form_mapper.dart';
import 'package:hoberadius_app/features/subscribers/domain/subscriber_model.dart';
import 'package:hoberadius_app/features/subscribers/presentation/widgets/subscriber_form_sections.dart';

Map<String, dynamic> _row({Map<String, dynamic> extra = const {}}) => {
      'id': 1,
      'username': 'ali',
      'status': 'enabled',
      'service_type': 'Hotspot',
      ...extra,
    };

void main() {
  test('web-only wired fields are read back from the server', () {
    final s = Subscriber.fromJson(
      _row(
        extra: {
          'login_without_password': true,
          'device_limit_mode': 'replace',
          'connection_schedule':
              '{"windows":[{"days":["sat"],"from":"08:00","to":"16:00"}]}',
          'metadata': {
            'mikrotik': {
              'mikrotik_address_list': 'vip',
              'mikrotik_queue_priority': '2',
            },
            'radius': {'framed_pool': 'pool-a', 'acct_interim_interval_sec': 60},
          },
        },
      ),
    );
    expect(s.loginWithoutPassword, isTrue);
    expect(s.deviceLimitMode, 'replace');
    expect(s.connectionSchedule, contains('"sat"'));
    expect(s.netAddressList, 'vip');
    expect(s.netQueuePriority, '2');
    expect(s.netFramedPool, 'pool-a');
    expect(s.netAcctInterimSec, '60');
  });

  test('form round-trip of the new fields: untouched → no PATCH', () {
    final row = Subscriber.fromJson(
      _row(
        extra: {
          'login_without_password': true,
          'device_limit_mode': 'reject',
          'connection_schedule': '{"windows":[{"days":["sun"],"from":"","to":""}]}',
          'metadata': {
            'mikrotik': {'mikrotik_address_list': 'vip'},
          },
        },
      ),
    );
    final c = {
      for (final k in kSubscriberFormControllerKeys) k: TextEditingController(),
    };
    applySubscriberToForm(row, c);
    final sel = selectionsFromSubscriber(row);
    final again = buildSubscriberFromForm(c, sel);
    expect(again.copyWith(username: 'ali').toPatchDiff(row), isEmpty);

    // Clearing an advanced network field sends '' (the server merges it).
    c['net_address_list']!.text = '';
    final diff = buildSubscriberFromForm(c, sel).toPatchDiff(row);
    expect(diff.keys, ['metadata']);
    expect(
      (diff['metadata'] as Map)['mikrotik']['mikrotik_address_list'],
      '',
    );
  });

  test('changed toggles / schedule travel under the server keys', () {
    final row = Subscriber.fromJson(_row());
    final next = row.copyWith(
      loginWithoutPassword: true,
      deviceLimitMode: 'replace',
      connectionSchedule: '{"windows":[{"days":["mon"],"from":"","to":""}]}',
    );
    final diff = next.toPatchDiff(row);
    expect(diff['login_without_password'], isTrue);
    expect(diff['device_limit_mode'], 'replace');
    expect(diff['connection_schedule'], contains('mon'));
    expect(diff.containsKey('working_days'), isFalse);
  });

  test('create body: schedule sent, working_days left to the server', () {
    final body = Subscriber(username: 'x', password: 'p1234').toCreateBody();
    expect(body.containsKey('working_days'), isFalse);
    expect(body['connection_schedule'], '');
    expect(body['login_without_password'], isFalse);
    expect(body['device_limit_mode'], '');
  });

  test('choices match the web / server', () {
    expect(
      kSubscriberStatusOptions.map((e) => e.$1),
      ['enabled', 'disabled', 'expired', 'suspended', 'pending'],
    );
    // card / employee were offered but the API answers 422.
    expect(userTypeOptions('subscriber').map((e) => e.$1), [
      'subscriber',
      'trial',
    ]);
    expect(userTypeOptions('card').last.$1, 'card');
    expect(
      kDeviceLimitModeOptions.map((e) => e.$1),
      ['', 'reject', 'replace'],
    );
    expect(
      serviceTypeOptions('Hotspot').map((e) => e.$2),
      ['هوت سبوت', 'برودباند', 'كلاهما'],
    );
  });
}
