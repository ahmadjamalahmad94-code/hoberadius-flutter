import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/core/api/api_client.dart';
import 'package:hoberadius_app/features/subscribers/domain/subscriber_model.dart';
import 'package:hoberadius_app/features/subscribers/presentation/subscribers_list_screen.dart';

import 'support/fake_api.dart';

Map<String, dynamic> _row(String u, {Object? live, bool? online}) => {
      'username': u,
      'status': 'enabled',
      'expire_at': '2099-01-01T00:00:00Z',
      if (live != null) 'live': live,
      if (online != null) 'online': online,
    };

final _rows = [
  _row(
    'on1',
    online: true,
    live: {
      'online': true,
      'bytes_in': 2 * 1024 * 1024,
      'bytes_out': 300 * 1024 * 1024,
      'framed_ip': '10.9.0.5',
      'started_at': '2026-10-01T08:00:00Z',
      'session_time': 120,
      'access_type': 'broadband',
    },
  ),
  _row(
    'off1',
    online: false,
    live: {
      'online': false,
      'bytes_in': 1024,
      'bytes_out': 4096,
      'framed_ip': '10.9.0.6',
      'started_at': '2026-09-30T08:00:00Z',
      'stopped_at': '2026-09-30T09:00:00Z',
      'session_time': 3600,
    },
  ),
  _row('none1'), // older server / never connected
];

Future<RecordingAdapter> _pump(
  WidgetTester tester, {
  double width = 360,
}) async {
  tester.view.physicalSize = Size(width, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final adapter = RecordingAdapter(
    (_) => FakeResponse.ok({'items': _rows, 'total': _rows.length}),
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [apiClientProvider.overrideWithValue(fakeApiClient(adapter))],
      child: const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: SingleChildScrollView(
              padding: EdgeInsets.all(12),
              child: SubscribersListScreen(),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return adapter;
}

void main() {
  testWidgets('every row has the same strip (online, offline, no live)',
      (tester) async {
    await _pump(tester);
    expect(tester.takeException(), isNull);
    for (final u in ['on1', 'off1', 'none1']) {
      expect(find.byKey(ValueKey('live-strip:$u')), findsOneWidget, reason: u);
    }
    expect(find.text('تحميل'), findsNWidgets(3));
    expect(find.text('رفع'), findsNWidgets(3));
    expect(find.text('IP'), findsNWidgets(3));
    expect(find.text('المدة'), findsNWidgets(3));
    // bytes_out = download, bytes_in = upload (same as «المتصلون»)
    expect(find.text('300 م.ب'), findsOneWidget);
    expect(find.text('2.0 م.ب'), findsOneWidget);
    // offline row: its last session
    expect(find.text('1 س 0 د'), findsOneWidget);
    // no live → dashes, never «null»
    final none = find.byKey(const ValueKey('live-strip:none1'));
    expect(
      find.descendant(of: none, matching: find.text('—')),
      findsNWidgets(4),
    );
    expect(find.textContaining('null'), findsNothing);
  });

  testWidgets('strip goes 2×2 on a very narrow row, no overflow',
      (tester) async {
    await _pump(tester, width: 280);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping the IP copies http://<ip>', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );
    await _pump(tester);
    await tester.tap(find.textContaining('10.9.0.5'));
    await tester.pump();
    expect(copied, 'http://10.9.0.5');
    expect(find.textContaining('http://10.9.0.5'), findsOneWidget);
  });

  testWidgets('access filter sends access=broadband; status chips one bar',
      (tester) async {
    final adapter = await _pump(tester);
    expect(adapter.requests.first.query['access'], isNull);
    await tester.tap(find.text('برود باند'));
    await tester.pumpAndSettle();
    expect(
      adapter.requests.any((r) => r.query['access'] == 'broadband'),
      isTrue,
    );
    await tester.tap(find.text('هوت سبوت'));
    await tester.pumpAndSettle();
    expect(adapter.requests.last.query['access'], 'hotspot');
    await tester.tap(find.text('الكل'));
    await tester.pumpAndSettle();
    expect(adapter.requests.last.query['access'], isNull);
    expect(tester.takeException(), isNull);
  });

  test('Subscriber.fromJson: live / online / access_type are optional', () {
    final s = Subscriber.fromJson(_rows.first);
    expect(s.online, isTrue);
    expect(s.live?.framedIp, '10.9.0.5');
    expect(s.live?.bytesOut, 300 * 1024 * 1024);
    final old = Subscriber.fromJson(_row('x'));
    expect(old.live, isNull);
    expect(old.online, isFalse);
    expect(old.accessType, '');
    final both = Subscriber.fromJson({..._row('y'), 'access_type': 'both'});
    expect(both.accessType, 'both');
    // an open session counts up from its start
    final live = SubscriberLive.tryParse({
      'online': true,
      'started_at': '2026-10-01T08:00:00Z',
      'session_time': 60,
    })!;
    expect(
      live.durationSeconds(DateTime.utc(2026, 10, 1, 9)),
      3600,
    );
  });
}
