import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/core/api/api_client.dart';
import 'package:hoberadius_app/features/sessions/domain/session_model.dart';
import 'package:hoberadius_app/features/sessions/presentation/sessions_list_screen.dart';

import 'support/fake_api.dart';

Map<String, dynamic> _sub({Map<String, dynamic> extra = const {}}) => {
      'username': 'sub1',
      'session_id': 's-sub',
      'user_type': 'subscriber',
      'state': 'online',
      'nas_ip_address': '10.0.0.1',
      'framed_ip_address': '10.5.0.9',
      'calling_station_id': 'AA:BB:CC:DD:EE:FF',
      'started_at': '2026-09-28T10:00:00Z',
      'session_time': 3600,
      'bytes_in': 1024 * 1024,
      'bytes_out': 5 * 1024 * 1024,
      ...extra,
    };

Map<String, dynamic> _card({Map<String, dynamic> extra = const {}}) => {
      'username': 'card77',
      'session_id': 's-card',
      'user_type': 'card',
      'card_id': 7,
      'state': 'online',
      'nas_ip_address': '10.0.0.1',
      'framed_ip_address': '10.5.0.10',
      'calling_station_id': '11:22:33:44:55:66',
      'started_at': '2026-09-28T10:00:00Z',
      'session_time': 600,
      ...extra,
    };

RecordingAdapter _api(
  List<Map<String, dynamic>> items, {
  Map<String, dynamic>? accesses,
  FakeResponse Function(RecordedRequest r)? post,
}) =>
    RecordingAdapter((r) {
      if (r.path == '/api/v1/sessions/online') {
        return FakeResponse.ok({
          'items': items,
          'total': items.length,
          'has_more': false,
          if (accesses != null) 'accesses': accesses,
        });
      }
      if (r.method == 'POST' && post != null) return post(r);
      return FakeResponse.ok({'items': <dynamic>[]});
    });

Future<void> _pump(WidgetTester tester, RecordingAdapter adapter) async {
  tester.view.physicalSize = const Size(360, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [apiClientProvider.overrideWithValue(fakeApiClient(adapter))],
      child: const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: SingleChildScrollView(
              padding: EdgeInsets.all(12),
              child: SessionsListScreen(),
            ),
          ),
        ),
      ),
    ),
  );
  await _frames(tester);
}

/// «مباشر» pulses forever: pump frames instead of settling.
Future<void> _frames(WidgetTester tester, [int n = 12]) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// The tile's action buttons (outlined / filled), by label.
Finder _btn(String label) => find.ancestor(
      of: find.text(label),
      matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
    );

void main() {
  testWidgets(
      'subscriber tile: طرد · تثبيت MAC · المزيد / سرعة مؤقتة · '
      'إلغاء السرعة — fits at 360', (tester) async {
    await _pump(tester, _api([_sub()]));
    expect(tester.takeException(), isNull);
    for (final l in [
      'طرد',
      'تثبيت MAC',
      'المزيد',
      'سرعة مؤقتة',
      'إلغاء السرعة',
    ]) {
      expect(_btn(l), findsOneWidget, reason: l);
    }
    expect(_btn('تغيير الوقت'), findsNothing);
    expect(_btn('تثبيت IP'), findsNothing); // moved to «المزيد»
    // the subscriber keeps its router / start-time row
    expect(find.text('الراوتر'), findsOneWidget);
    expect(find.text('مُستخدَم'), findsNothing);
  });

  testWidgets('card tile: طرد · تثبيت MAC · المزيد / سرعة مؤقتة · تغيير الوقت',
      (tester) async {
    await _pump(tester, _api([_card()]));
    expect(tester.takeException(), isNull);
    for (final l in [
      'طرد',
      'تثبيت MAC',
      'المزيد',
      'سرعة مؤقتة',
      'تغيير الوقت',
    ]) {
      expect(_btn(l), findsOneWidget, reason: l);
    }
    expect(_btn('إلغاء السرعة'), findsNothing);
    expect(_btn('تثبيت IP'), findsNothing);
  });

  testWidgets('card used / remaining boxes replace router · start time',
      (tester) async {
    await _pump(
      tester,
      _api([
        _card(
          extra: {
            'card_used_seconds': 2 * 3600 + 600,
            'card_remaining_seconds': 1800,
            'card_budget_seconds': 3 * 3600,
          },
        ),
      ]),
    );
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('card-time-row')), findsOneWidget);
    expect(find.text('مُستخدَم'), findsOneWidget);
    expect(find.text('متبقّي'), findsOneWidget);
    expect(find.text('2 س 10 د'), findsOneWidget);
    expect(find.text('30 د 0 ث'), findsOneWidget);
    expect(find.text('الراوتر'), findsNothing);
    expect(find.text('بدأت'), findsNothing);
  });

  testWidgets('unlimited card: remaining null → «غير محدود»', (tester) async {
    await _pump(
      tester,
      _api([
        _card(
          extra: {'card_used_seconds': 0, 'card_remaining_seconds': null},
        ),
      ]),
    );
    expect(find.text('غير محدود'), findsOneWidget);
    expect(find.text('0 د'), findsOneWidget);
  });

  testWidgets('older server (no card time): the old third row stays',
      (tester) async {
    await _pump(tester, _api([_card()]));
    expect(find.byKey(const ValueKey('card-time-row')), findsNothing);
    expect(find.text('الراوتر'), findsOneWidget);
    expect(find.text('بدأت'), findsOneWidget);
    expect(find.textContaining('null'), findsNothing);
  });

  testWidgets('card «حذف نهائي» needs a confirmation, then posts',
      (tester) async {
    final adapter = _api(
      [_card()],
      post: (r) => FakeResponse.ok({'card': <String, dynamic>{}}),
    );
    await _pump(tester, adapter);
    await tester.tap(_btn('المزيد'));
    await _frames(tester, 6);
    // the sheet carries router / start time + the card rows
    expect(find.text('فحص الكرت'), findsOneWidget);
    expect(find.text('تصفير الاستخدام'), findsOneWidget);
    expect(find.text('إلغاء السرعة'), findsOneWidget);
    expect(find.text('تثبيت IP'), findsNothing);
    await tester.tap(find.text('حذف نهائي'));
    await _frames(tester, 6);
    expect(find.text('حذف الكرت نهائيًا'), findsOneWidget);
    expect(adapter.where('POST', '/cards/'), isEmpty);
    // cancel → nothing sent
    await tester.tap(find.text('إلغاء').last);
    await _frames(tester, 6);
    expect(adapter.where('POST', '/cards/'), isEmpty);
    // again, confirm
    await tester.tap(_btn('المزيد'));
    await _frames(tester, 6);
    await tester.tap(find.text('حذف نهائي'));
    await _frames(tester, 6);
    await tester.tap(_btn('حذف نهائي').last);
    await _frames(tester, 6);
    final sent = adapter.where('POST', '/cards/7/delete-permanent').toList();
    expect(sent, hasLength(1));
    expect(sent.single.jsonBody['confirm'], 'DELETE:card77');
  });

  testWidgets('card «تعطيل» needs a confirmation', (tester) async {
    final adapter = _api(
      [_card()],
      post: (r) => FakeResponse.ok({'card': <String, dynamic>{}}),
    );
    await _pump(tester, adapter);
    await tester.tap(_btn('المزيد'));
    await _frames(tester, 6);
    await tester.tap(find.text('تعطيل'));
    await _frames(tester, 6);
    expect(find.text('تعطيل الكرت'), findsOneWidget);
    expect(adapter.where('POST', '/cards/7/disable'), isEmpty);
    await tester.tap(_btn('تعطيل').last);
    await _frames(tester, 6);
    expect(adapter.where('POST', '/cards/7/disable'), hasLength(1));
  });

  testWidgets('subscriber «تعطيل» in «المزيد» needs a confirmation',
      (tester) async {
    final adapter = _api([_sub()], post: (r) => FakeResponse.ok({}));
    await _pump(tester, adapter);
    await tester.tap(_btn('المزيد'));
    await _frames(tester, 6);
    expect(find.text('تثبيت IP'), findsOneWidget);
    expect(find.text('ملف المشترك'), findsOneWidget);
    expect(find.text('حذف نهائي'), findsNothing);
    await tester.tap(find.text('تعطيل'));
    await _frames(tester, 6);
    expect(find.text('تعطيل المشترك'), findsOneWidget);
    expect(adapter.where('POST', '/disable'), isEmpty);
    await tester.tap(_btn('تعطيل').last);
    await _frames(tester, 6);
    expect(adapter.where('POST', '/accounts/sub1/disable'), hasLength(1));
  });

  testWidgets('«تغيير الوقت» posts adjust-time (subtract 2 hours)',
      (tester) async {
    final adapter = _api(
      [_card()],
      post: (r) => FakeResponse.ok({'card': <String, dynamic>{}}),
    );
    await _pump(tester, adapter);
    await tester.tap(_btn('تغيير الوقت'));
    await _frames(tester, 6);
    await tester.tap(find.text('خصم').first);
    await _frames(tester, 3);
    await tester.enterText(
      find.byKey(const ValueKey('card-time-amount')),
      '2',
    );
    await tester.tap(find.text('دقائق'));
    await _frames(tester, 6);
    await tester.tap(find.text('ساعات').last);
    await _frames(tester, 6);
    await tester.tap(_btn('خصم').last);
    await _frames(tester, 6);
    final sent = adapter.where('POST', '/cards/7/adjust-time').toList();
    expect(sent, hasLength(1));
    expect(
      sent.single.jsonBody,
      {'amount': 2, 'unit': 'hours', 'op': 'subtract'},
    );
  });

  testWidgets('card temp speed: an older server\'s refusal is shown as is',
      (tester) async {
    final adapter = _api(
      [_card()],
      post: (r) => FakeResponse.error(
        422,
        'validation_error',
        'السرعة المؤقتة متاحة للمشتركين فقط.',
      ),
    );
    await _pump(tester, adapter);
    await tester.tap(_btn('سرعة مؤقتة'));
    await _frames(tester, 6);
    await tester.tap(find.text('تطبيق'));
    await _frames(tester, 6);
    expect(adapter.where('POST', '/sessions/temp-speed'), hasLength(1));
    expect(find.text('السرعة المؤقتة متاحة للمشتركين فقط.'), findsOneWidget);
  });

  testWidgets('access filter sends access= and shows the counters',
      (tester) async {
    final adapter = _api(
      [_sub()],
      accesses: {'hotspot': 12, 'broadband': 30},
    );
    await _pump(tester, adapter);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('30'), findsOneWidget);
    expect(
      adapter.where('GET', '/sessions/online').first.query['access'],
      isNull,
    );
    await tester.tap(find.text('هوت سبوت'));
    await _frames(tester);
    expect(
      adapter
          .where('GET', '/sessions/online')
          .any((r) => r.query['access'] == 'hotspot'),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  test('OnlineSession reads access_type and card time (optional)', () {
    final full = OnlineSession.fromJson({
      ..._card(),
      'access_type': 'hotspot',
      'card_used_seconds': 60,
      'card_remaining_seconds': null,
      'card_budget_seconds': 3600,
    });
    expect(full.accessType, 'hotspot');
    expect(full.cardTimeKnown, isTrue);
    expect(full.cardUsedSeconds, 60);
    expect(full.cardRemainingSeconds, isNull);
    final old = OnlineSession.fromJson(_card());
    expect(old.accessType, '');
    expect(old.cardTimeKnown, isFalse);
    // a subscriber never shows card time even if a field leaks through
    expect(
      OnlineSession.fromJson({..._sub(), 'card_used_seconds': 5}).cardTimeKnown,
      isFalse,
    );
  });
}
