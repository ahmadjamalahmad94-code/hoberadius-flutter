import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/core/api/api_client.dart';
import 'package:hoberadius_app/features/notifications/application/notifications_providers.dart';
import 'package:hoberadius_app/features/notifications/data/notifications_repository.dart';
import 'package:hoberadius_app/features/notifications/presentation/notification_center_screen.dart';

import 'support/fake_api.dart';

Map<String, dynamic> _n(int id) => {
      'id': id,
      'title': 'إشعار $id',
      'is_read': false,
      'created_at': '2026-09-28T10:00:00Z',
    };

void main() {
  test('offset paging with new rows arriving → no duplicates (A11 F-11)',
      () async {
    // Newest first. Between page 1 and 2, 15 new rows arrive, so the old
    // offset page overlaps the first one by 15 ids.
    var inserted = 0;
    final adapter = RecordingAdapter((r) {
      final offset = int.parse('${r.query['offset'] ?? 0}');
      final newest = 100 + inserted;
      final ids = [for (var i = 0; i < 30; i++) newest - offset - i];
      inserted = 15;
      return FakeResponse.ok({
        'items': ids.map(_n).toList(),
        'unread_count': 60,
        'limit': 30,
        'offset': offset,
        'has_more': true,
      });
    });
    final repo = NotificationsRepository(fakeApiClient(adapter));
    final c = ProviderContainer(
      overrides: [notificationsRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(c.dispose);
    await c.read(notificationCenterProvider.future);
    await c.read(notificationCenterProvider.notifier).loadMore();
    final ids =
        c.read(notificationCenterProvider).value!.items.map((n) => n.id);
    expect(ids.toSet().length, ids.length, reason: 'duplicates in load-more');
  });

  test('uses the server keyset cursor (before_id) when it is sent', () async {
    final adapter = RecordingAdapter((r) {
      final before = r.query['before_id'];
      final start = before == null ? 100 : int.parse('$before') - 1;
      return FakeResponse.ok({
        'items': [for (var i = 0; i < 30; i++) _n(start - i)],
        'unread_count': 0,
        'limit': 30,
        'has_more': before == null,
        'next_before_id': start - 29,
      });
    });
    final repo = NotificationsRepository(fakeApiClient(adapter));
    final c = ProviderContainer(
      overrides: [notificationsRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(c.dispose);
    await c.read(notificationCenterProvider.future);
    await c.read(notificationCenterProvider.notifier).loadMore();
    final second = adapter.requests.last;
    expect('${second.query['before_id']}', '71');
    expect(second.query.containsKey('offset'), isFalse);
    final page = c.read(notificationCenterProvider).value!;
    expect(page.items, hasLength(60));
    expect(page.hasMore, isFalse);
  });

  testWidgets('«تعليم الكل كمقروء» asks first and sits away from the chips',
      (tester) async {
    final adapter = RecordingAdapter(
      (r) => FakeResponse.ok({
        'items': [_n(1), _n(2)],
        'unread_count': 2,
        'limit': 30,
        'offset': 0,
        'has_more': false,
      }),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(fakeApiClient(adapter))
        ],
        child: const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: SingleChildScrollView(child: NotificationCenterScreen()),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('تعليم الكل كمقروء'), findsNothing); // no big button
    await tester.tap(find.byTooltip('تعليم الكل كمقروء'));
    await tester.pumpAndSettle();
    expect(find.text('تعليم الكل كمقروء؟'), findsOneWidget);
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();
    expect(adapter.where('POST', 'read-all'), isEmpty);
    await tester.tap(find.byTooltip('تعليم الكل كمقروء'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تعليم الكل'));
    await tester.pumpAndSettle();
    expect(adapter.where('POST', 'read-all'), hasLength(1));
  });
}
