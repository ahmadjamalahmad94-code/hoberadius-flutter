// parity-a (2026-10-02) — subscriber quick-action dialogs ⇄ web, field by field.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/core/api/api_client.dart';
import 'package:hoberadius_app/features/subscribers/data/subscriber_actions_repository.dart';
import 'package:hoberadius_app/features/subscribers/domain/subscriber_actions_model.dart';
import 'package:hoberadius_app/features/subscribers/presentation/widgets/subscriber_action_dialogs.dart';
import 'package:hoberadius_app/features/subscribers/presentation/widgets/subscriber_actions_sheet.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'support/fake_api.dart';

Map<String, dynamic> _json({
  Map<String, bool>? permissions,
  Object? tempSpeed,
  bool custom = false,
}) =>
    {
      'username': 'pa_u1',
      'status': 'enabled',
      'expire_at': '2026-10-10T21:00:00Z',
      'currency': 'ILS',
      'plan': {'id': 3, 'name': 'شهري', 'price': 30, 'minutes': 43200},
      'effective_price': 30,
      'price_is_custom': custom,
      'balance': 0,
      'debt': 0,
      'open_loans': <dynamic>[],
      'quota': {'has_quota': true, 'quota_mb': 10240},
      'online_sessions': 1,
      'channels': {'sms': true, 'whatsapp': false},
      'max_free_loan_hours': 72,
      if (tempSpeed != null) 'temp_speed': tempSpeed,
      if (permissions != null) 'permissions': permissions,
    };

SubscriberActionSpec _spec(SubscriberAction a) =>
    [...kActivationActions, ...kAdminActions].firstWhere((s) => s.action == a);

Future<void> _open(
  WidgetTester tester,
  RecordingAdapter adapter,
  Widget dialog,
) async {
  tester.view.physicalSize = const Size(390, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [apiClientProvider.overrideWithValue(fakeApiClient(adapter))],
      child: MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showActionDialog(context, dialog),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async => initializeDateFormatting('en'));

  group('permissions follow the web endpoint of each action', () {
    test('«إرسال بيانات المشترك» reads send_credentials, not send_message', () {
      final c = SubscriberActionsContext.fromJson(
        _json(permissions: {'send_message': true, 'send_credentials': false}),
      );
      expect(
        actionAvailability(_spec(SubscriberAction.credentials), c).visible,
        isFalse,
      );
      expect(
        actionAvailability(_spec(SubscriberAction.message), c).visible,
        isTrue,
      );
      final reverse = SubscriberActionsContext.fromJson(
        _json(permissions: {'send_message': false, 'send_credentials': true}),
      );
      expect(
        actionAvailability(_spec(SubscriberAction.credentials), reverse)
            .visible,
        isTrue,
      );
    });

    test('«استعادة الكوتة اليومية» reads quota_reset (else quota)', () {
      final own = SubscriberActionsContext.fromJson(
        _json(permissions: {'quota': true, 'quota_reset': false}),
      );
      expect(
        actionAvailability(_spec(SubscriberAction.quotaReset), own).visible,
        isFalse,
      );
      final older = SubscriberActionsContext.fromJson(
        _json(permissions: {'quota': false}),
      );
      expect(
        actionAvailability(_spec(SubscriberAction.quotaReset), older).visible,
        isFalse,
      );
      final allowed = SubscriberActionsContext.fromJson(
        _json(permissions: {'quota': false, 'quota_reset': true}),
      );
      expect(
        actionAvailability(_spec(SubscriberAction.quotaReset), allowed)
            .enabled,
        isTrue,
      );
    });
  });

  group('«إلغاء السرعة المؤقتة» (web profile X)', () {
    test('hidden without a temp speed, shown beside one', () {
      final none = SubscriberActionsContext.fromJson(_json());
      expect(
        actionAvailability(_spec(SubscriberAction.tempSpeedCancel), none)
            .visible,
        isFalse,
      );
      final on = SubscriberActionsContext.fromJson(
        _json(
          tempSpeed: {
            'active': true,
            'ends_at': '2026-10-02T10:00:00Z',
            'down_kbps': 2500,
            'up_kbps': 1024,
          },
        ),
      );
      expect(on.tempSpeed!.rateLabel, '2500k / 1024k');
      expect(
        actionAvailability(_spec(SubscriberAction.tempSpeedCancel), on)
            .enabled,
        isTrue,
      );
      final denied = SubscriberActionsContext.fromJson(
        _json(
          tempSpeed: {'active': true},
          permissions: {'temp_speed_cancel': false},
        ),
      );
      expect(
        actionAvailability(_spec(SubscriberAction.tempSpeedCancel), denied)
            .visible,
        isFalse,
      );
    });

    test('posts /accounts/<u>/temp-speed/cancel', () async {
      final adapter = RecordingAdapter(
        (r) => FakeResponse.ok({'reverted': true, 'message': 'تم'}),
      );
      final repo = SubscriberActionsRepository(fakeApiClient(adapter));
      final res = await repo.cancelTempSpeed('pa_u1');
      expect(
        adapter.requests.single.path,
        '/api/v1/accounts/pa_u1/temp-speed/cancel',
      );
      expect(res['reverted'], isTrue);
    });
  });

  group('«إضافة كوتة» — units and whole MB like the web picker', () {
    test('MB / GB / TB, MB first (the web default)', () {
      expect(kQuotaUnits.map((u) => u.$2).toList(), ['MB', 'GB', 'TB']);
      expect(quotaMbOf(1.3, 1024), 1331);
      expect(quotaMbOf(2, 1048576), 2097152);
      expect(quotaMbOf(0.2, 1), 0);
      expect(quotaMbOf(-1, 1024), 0);
    });

    testWidgets('«1.3 GB» posts quota_mb 1331 (an integer)', (tester) async {
      final adapter = RecordingAdapter((r) => FakeResponse.ok({}));
      await _open(
        tester,
        adapter,
        QuotaTopupDialog(c: SubscriberActionsContext.fromJson(_json())),
      );
      await tester.enterText(find.byType(TextField).first, '1.3');
      await tester.tap(find.text('MB').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('GB').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('إضافة').last);
      await tester.pumpAndSettle();
      final body = adapter.requests.single.jsonBody;
      expect(body['quota_mb'], 1331);
      expect(body['quota_mb'], isA<int>());
    });
  });

  group('reset password', () {
    test('trimmed length like the server (validate_new_password)', () {
      expect(resetPasswordProblem('  ab  '), isNotNull);
      expect(resetPasswordProblem('abcd'), isNull);
      expect(resetPasswordProblem('ab'), isNotNull);
    });

    testWidgets('«نسخ» beside «إظهار»', (tester) async {
      final adapter = RecordingAdapter((r) => FakeResponse.ok({}));
      await _open(
        tester,
        adapter,
        ResetPasswordDialog(c: SubscriberActionsContext.fromJson(_json())),
      );
      expect(find.byTooltip('نسخ'), findsOneWidget);
      expect(find.byTooltip('إظهار'), findsOneWidget);
    });
  });

  group('price label follows price_is_custom (web hints)', () {
    test('«السعر المخصّص» vs «سعر العرض»', () {
      expect(
        priceLabelOf(SubscriberActionsContext.fromJson(_json(custom: true))),
        'السعر المخصّص',
      );
      expect(
        priceLabelOf(SubscriberActionsContext.fromJson(_json())),
        'سعر العرض',
      );
    });
  });
}
