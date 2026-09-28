import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/core/api/api_exception.dart';
import 'package:hoberadius_app/core/api/idempotency.dart';
import 'package:hoberadius_app/core/api/paging.dart';
import 'package:hoberadius_app/core/api/visible_error_message.dart';
import 'package:hoberadius_app/core/format/server_time.dart';
import 'package:hoberadius_app/features/accounting/domain/accounting_model.dart';
import 'package:hoberadius_app/features/admins/domain/admin_model.dart';
import 'package:hoberadius_app/features/cards/domain/card_parsing.dart';
import 'package:hoberadius_app/features/notifications/presentation/notification_center_screen.dart';
import 'package:hoberadius_app/features/sessions/domain/session_model.dart';

import 'support/fake_api.dart';

void main() {
  group('parseServerDateTime (item 9: one tolerant UTC parser)', () {
    final utc = DateTime.utc(2026, 9, 28, 12, 30, 5);

    test('«Z», naive, space-separated and offset all mean the same UTC', () {
      for (final raw in [
        '2026-09-28T12:30:05Z',
        '2026-09-28T12:30:05',
        '2026-09-28 12:30:05',
        '2026-09-28T15:30:05+03:00',
        '2026-09-28T15:30:05+03:00Z', // legacy double suffix
      ]) {
        final got = parseServerDateTime(raw);
        expect(got, isNotNull, reason: raw);
        expect(got!.isUtc, isFalse, reason: '$raw must come back LOCAL');
        expect(got.toUtc(), utc, reason: raw);
      }
    });

    test('a bare date stays on the same calendar day', () {
      final d = parseServerDateTime('2026-09-28')!;
      expect([d.year, d.month, d.day], [2026, 9, 28]);
    });

    test('null / empty / garbage → null', () {
      expect(parseServerDateTime(null), isNull);
      expect(parseServerDateTime(''), isNull);
      expect(parseServerDateTime('None'), isNull);
      expect(parseServerDateTime('not a date'), isNull);
    });

    test('toServerUtcIso writes UTC with Z', () {
      expect(toServerUtcIso(utc.toLocal()), '2026-09-28T12:30:05Z');
    });

    test('models no longer read a naive UTC value as local time', () {
      final expected = utc.toLocal();
      final session = OnlineSession.fromJson({
        'username': 'u',
        'started_at': '2026-09-28T12:30:05',
      });
      expect(session.startedAt, expected);
      final loan =
          LoanEntry.fromJson({'id': 1, 'created_at': '2026-09-28 12:30:05'});
      expect(loan.createdAt, expected);
      expect(cardParseDate('2026-09-28T12:30:05Z'), expected);
      final admin = Admin.fromJson(
        {'id': 1, 'username': 'a', 'last_login_at': '2026-09-28T12:30:05'},
      );
      expect(admin.lastLoginAt, expected);
    });

    test('notification «منذ …» is computed from UTC, not local', () {
      final created =
          DateTime.now().toUtc().subtract(const Duration(minutes: 5));
      final iso = created.toIso8601String().replaceAll('Z', '');
      expect(notificationTimeAgo(iso), 'منذ 5 دقائق');
    });
  });

  group('idempotency keys (item 6)', () {
    test('uuid v4 shape', () {
      final k = newIdempotencyKey();
      expect(
        RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')
            .hasMatch(k),
        isTrue,
        reason: k,
      );
      expect(newIdempotencyKey(), isNot(k));
    });

    test('same submission → same key; changed body or reset → new key', () {
      final keeper = IdempotencyKeeper();
      final a = keeper.keyFor('payment', {
        'amount': 10,
        'x': [1, 2],
      });
      expect(
        keeper.keyFor('payment', {
          'x': [1, 2],
          'amount': 10,
        }),
        a,
      );
      final b = keeper.keyFor('payment', {'amount': 11});
      expect(b, isNot(a));
      keeper.reset();
      expect(keeper.keyFor('payment', {'amount': 11}), isNot(b));
    });

    test('ApiClient.post sends the Idempotency-Key header', () async {
      final adapter = RecordingAdapter((_) => FakeResponse.ok({}));
      final api = fakeApiClient(adapter);
      await api.post('/x', body: {'a': 1}, headers: idempotencyHeaders('k-1'));
      expect(adapter.requests.single.headers[kIdempotencyHeader], 'k-1');
      await api.post('/y', body: {'a': 1});
      expect(
        adapter.requests.last.headers.containsKey(kIdempotencyHeader),
        isFalse,
      );
    });
  });

  group('paging contract', () {
    test('has_more wins, else total, else a full page', () {
      expect(
        readPageInfo(
          {'has_more': false, 'total': 999},
          requestedLimit: 50,
          offset: 0,
          itemCount: 50,
        ).hasMore,
        isFalse,
      );
      final t = readPageInfo(
        {'total': 120},
        requestedLimit: 50,
        offset: 50,
        itemCount: 50,
      );
      expect(t.hasMore, isTrue);
      expect(t.total, 120);
      expect(
        readPageInfo({}, requestedLimit: 50, offset: 0, itemCount: 50).hasMore,
        isTrue,
      );
      expect(
        readPageInfo({}, requestedLimit: 50, offset: 0, itemCount: 7).hasMore,
        isFalse,
      );
      expect(
        readPageInfo(
          {'next_before_id': 77},
          requestedLimit: 30,
          offset: 0,
          itemCount: 30,
        ).nextBeforeId,
        77,
      );
    });

    test('mergeUniqueBy drops overlapping rows and counts new ones', () {
      final (merged, added) = mergeUniqueBy([1, 2, 3], [3, 4, 2, 5], (i) => i);
      expect(merged, [1, 2, 3, 4, 5]);
      expect(added, 2);
    });
  });

  group('shared error helper (item 5)', () {
    test('keeps the server Arabic message; 503 busy is retryable', () {
      final busy = ApiException(
        code: 'server_busy',
        message: 'الخادم مشغول الآن، أعد المحاولة بعد لحظات.',
        status: 503,
      );
      expect(visibleErrorMessage(busy), contains('الخادم مشغول'));
      expect(isRetryableError(busy), isTrue);
      final conflict = ApiException(
        code: 'conflict',
        message: 'اسم المستخدم مستخدم مسبقًا.',
        status: 409,
      );
      expect(visibleErrorMessage(conflict), 'اسم المستخدم مستخدم مسبقًا.');
      expect(isRetryableError(conflict), isFalse);
      expect(
        isRetryableError(
          ApiException(
            code: 'idempotency_in_progress',
            message: '',
            status: 409,
          ),
        ),
        isTrue,
      );
      // Already says «أعد المحاولة» → unchanged; a bare 503 gets the hint.
      expect(visibleErrorWithRetryHint(busy), busy.message);
      final bare = ApiException(
        code: 'server_unavailable',
        message: 'الخادم غير متاح حاليًا.',
        status: 503,
      );
      expect(visibleErrorWithRetryHint(bare), contains('إعادة المحاولة'));
    });
  });
}
