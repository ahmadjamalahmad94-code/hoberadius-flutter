// Owner 2026-10-04: beside the name, the speed the session runs at now
// (instead of «متصل» — we are already in «المتصلون»); a raised speed is
// highlighted and a temporary one counts down. And the duration is never
// «غير معروف» just because the router has not sent its first update yet.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/sessions/domain/session_model.dart';
import 'package:hoberadius_app/features/sessions/presentation/sessions_list_screen.dart';

Widget _wrap(Widget w) => MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(body: Center(child: w)),
      ),
    );

void main() {
  test('parses the server speed fields and the temporary end', () {
    final ends = DateTime.now().toUtc().add(const Duration(minutes: 10));
    final s = OnlineSession.fromJson({
      'username': '725563',
      'user_type': 'card',
      'rate_down_kbps': 4000,
      'rate_up_kbps': 2000,
      'plan_down_kbps': 1600,
      'plan_up_kbps': 1600,
      'speed_state': 'temporary',
      'temporary_speed_window': {
        'active': true,
        'ends_at_epoch': ends.millisecondsSinceEpoch ~/ 1000,
      },
    });
    expect(s.speedKnown, isTrue);
    expect(s.isRaisedSpeed, isTrue);
    expect(s.tempEndsAt, isNotNull);
  });

  test('duration falls back to the time since start before the first update',
      () {
    final start = DateTime.utc(2026, 10, 4, 10, 0, 0);
    final s = OnlineSession.fromJson({
      'username': 'x',
      'session_time': 0,
      'started_at': '2026-10-04T10:00:00Z',
    });
    expect(s.effectiveSessionTime(start.add(const Duration(minutes: 7))), 420);
    expect(compactSessionDuration(s.effectiveSessionTime(start)), 'غير معروف');
  });

  testWidgets('plan speed shows plainly, a temporary one counts down',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        SessionSpeedBadge(
          session: OnlineSession.fromJson({
            'username': 'a',
            'rate_down_kbps': 1600,
            'rate_up_kbps': 1600,
            'plan_down_kbps': 1600,
            'plan_up_kbps': 1600,
          }),
        ),
      ),
    );
    expect(find.textContaining('1.6M'), findsOneWidget);
    expect(find.textContaining('مؤقتة'), findsNothing);

    final ends = DateTime.now().toUtc().add(const Duration(minutes: 5));
    await tester.pumpWidget(
      _wrap(
        SessionSpeedBadge(
          session: OnlineSession.fromJson({
            'username': 'b',
            'rate_down_kbps': 4000,
            'rate_up_kbps': 2000,
            'plan_down_kbps': 1600,
            'plan_up_kbps': 1600,
            'speed_state': 'temporary',
            'temporary_speed_window': {
              'active': true,
              'ends_at_epoch': ends.millisecondsSinceEpoch ~/ 1000,
            },
          }),
        ),
      ),
    );
    expect(find.textContaining('4M'), findsOneWidget);
    expect(find.textContaining('مؤقتة · 0'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpWidget(const SizedBox());
  });

  test('speed text never shows a trailing .0', () {
    expect(compactKbps(2048), '2M');
    expect(compactKbps(2000), '2M');
    expect(compactKbps(1600), '1.6M');
    expect(compactKbps(1536), '1.5M');
    expect(compactKbps(512), '512K');
  });

  test('parses the card batch name', () {
    final s = OnlineSession.fromJson({
      'username': 'c',
      'user_type': 'card',
      'card_batch_name': 'حزمة علاء',
    });
    expect(s.cardBatchName, 'حزمة علاء');
  });

  testWidgets('countdown reaching zero asks for one refresh', (tester) async {
    var calls = 0;
    final ends = DateTime.now().toUtc().add(const Duration(seconds: 2));
    final session = OnlineSession.fromJson({
      'username': 'x',
      'rate_down_kbps': 2560,
      'rate_up_kbps': 2560,
      'plan_down_kbps': 2048,
      'plan_up_kbps': 2048,
      'speed_state': 'temporary',
      'temporary_speed_window': {
        'active': true,
        'ends_at_epoch': ends.millisecondsSinceEpoch ~/ 1000 + 1,
      },
    });
    await tester.runAsync(() async {
      await tester.pumpWidget(_wrap(SessionSpeedBadge(
        session: session,
        onExpired: () => calls++,
      ),),);
      await Future<void>.delayed(const Duration(seconds: 5));
      await tester.pump();
    });
    expect(calls, 1);
    expect(find.textContaining('انتهت'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  test('parses the subscriber real name', () {
    final s = OnlineSession.fromJson({
      'username': 'r6ops_unl033',
      'user_type': 'subscriber',
      'full_name': ' أحمد أحمد ',
    });
    expect(s.fullName, 'أحمد أحمد');
  });
}
