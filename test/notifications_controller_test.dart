import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoberadius_app/features/notifications/application/notifications_providers.dart';
import 'package:hoberadius_app/features/notifications/data/notifications_repository.dart';
import 'package:hoberadius_app/features/notifications/domain/notification_model.dart';

/// In-memory fake of the repository so the controller/poller logic can be
/// tested without a server.
class _FakeRepo implements NotificationsRepository {
  _FakeRepo(this._items);
  List<AppNotification> _items;

  int get _unread => _items.where((n) => !n.isRead).length;

  @override
  Future<NotificationsPage> list({
    bool unreadOnly = false,
    int limit = 30,
    int offset = 0,
  }) async {
    final src = unreadOnly ? _items.where((n) => !n.isRead).toList() : _items;
    final slice = src.skip(offset).take(limit).toList();
    return NotificationsPage(
      items: slice,
      unreadCount: _unread,
      limit: limit,
      offset: offset,
      hasMore: offset + slice.length < src.length,
    );
  }

  @override
  Future<int> unreadCount() async => _unread;

  @override
  Future<int> markRead(int id) async {
    _items = _items
        .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
        .toList();
    return _unread;
  }

  @override
  Future<int> markAllRead() async {
    _items = _items.map((n) => n.copyWith(isRead: true)).toList();
    return _unread;
  }
}

AppNotification _n(int id, {bool read = false}) => AppNotification.fromJson({
      'id': id,
      'title': 'إشعار $id',
      'is_read': read,
      'created_at': '2026-06-18T10:00:00',
    });

ProviderContainer _containerWith(_FakeRepo repo) {
  final c = ProviderContainer(
    overrides: [
      notificationsRepositoryProvider.overrideWithValue(repo),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('center loads items + unread count', () async {
    final c = _containerWith(_FakeRepo([_n(3), _n(2), _n(1, read: true)]));
    final page = await c.read(notificationCenterProvider.future);
    expect(page.items.length, 3);
    expect(page.unreadCount, 2);
  });

  test('unreadCountProvider reflects the poller', () async {
    final c = _containerWith(_FakeRepo([_n(2), _n(1)]));
    await c.read(notificationsPollerProvider.future);
    expect(c.read(unreadCountProvider), 2);
  });

  test('markRead flips item + decrements unread', () async {
    final c = _containerWith(_FakeRepo([_n(2), _n(1)]));
    await c.read(notificationCenterProvider.future);
    await c.read(notificationCenterProvider.notifier).markRead(2);
    final page = c.read(notificationCenterProvider).valueOrNull!;
    final marked = page.items.firstWhere((n) => n.id == 2);
    expect(marked.isRead, isTrue);
    expect(page.unreadCount, 1);
  });

  test('markAllRead clears unread', () async {
    final c = _containerWith(_FakeRepo([_n(3), _n(2), _n(1)]));
    await c.read(notificationCenterProvider.future);
    await c.read(notificationCenterProvider.notifier).markAllRead();
    final page = c.read(notificationCenterProvider).valueOrNull!;
    expect(page.unreadCount, 0);
    expect(page.items.every((n) => n.isRead), isTrue);
  });

  test('loadMore appends the next page', () async {
    final many = List.generate(45, (i) => _n(45 - i));
    final c = _containerWith(_FakeRepo(many));
    final first = await c.read(notificationCenterProvider.future);
    expect(first.items.length, 30);
    expect(first.hasMore, isTrue);
    await c.read(notificationCenterProvider.notifier).loadMore();
    final page = c.read(notificationCenterProvider).valueOrNull!;
    expect(page.items.length, 45);
    expect(page.hasMore, isFalse);
  });
}
