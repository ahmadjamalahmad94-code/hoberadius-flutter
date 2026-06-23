import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/notifications_repository.dart';
import '../domain/notification_model.dart';

/// How often the bell badge polls for the unread count / new notifications.
/// Kept modest to be gentle on the server (the center screen refreshes on
/// demand via pull-to-refresh).
const Duration kNotificationsPollInterval = Duration(seconds: 60);

// ───────────────────────────────────────────────────────────────────────
// Notification Center list controller (paginated)
// ───────────────────────────────────────────────────────────────────────
class NotificationCenterController extends AsyncNotifier<NotificationsPage> {
  static const _pageSize = 30;

  @override
  Future<NotificationsPage> build() {
    return ref.read(notificationsRepositoryProvider).list(limit: _pageSize);
  }

  Future<void> refresh() async {
    state = const AsyncLoading<NotificationsPage>().copyWithPrevious(state);
    state = await AsyncValue.guard(
      () => ref.read(notificationsRepositoryProvider).list(limit: _pageSize),
    );
    _syncPoller();
  }

  /// Appends the next page (if any).
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore) return;
    final next = await ref.read(notificationsRepositoryProvider).list(
          limit: _pageSize,
          offset: current.items.length,
        );
    state = AsyncData(
      NotificationsPage(
        items: [...current.items, ...next.items],
        unreadCount: next.unreadCount,
        limit: next.limit,
        offset: next.offset,
        hasMore: next.hasMore,
      ),
    );
  }

  Future<void> markRead(int id) async {
    final current = state.valueOrNull;
    if (current == null) return;
    // Optimistic local update.
    final updated = current.items
        .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
        .toList();
    final newUnread = (current.unreadCount - 1).clamp(0, 1 << 31);
    state = AsyncData(_withItems(current, updated, unreadCount: newUnread));
    try {
      final serverUnread =
          await ref.read(notificationsRepositoryProvider).markRead(id);
      final c = state.valueOrNull;
      if (c != null) {
        state = AsyncData(_withItems(c, c.items, unreadCount: serverUnread));
      }
    } catch (_) {
      // Leave the optimistic state; the next refresh reconciles.
    }
    _syncPoller();
  }

  Future<void> markAllRead() async {
    final current = state.valueOrNull;
    if (current == null) return;
    final updated =
        current.items.map((n) => n.copyWith(isRead: true)).toList();
    state = AsyncData(_withItems(current, updated, unreadCount: 0));
    try {
      await ref.read(notificationsRepositoryProvider).markAllRead();
    } catch (_) {}
    _syncPoller();
  }

  NotificationsPage _withItems(
    NotificationsPage base,
    List<AppNotification> items, {
    required int unreadCount,
  }) {
    return NotificationsPage(
      items: items,
      unreadCount: unreadCount,
      limit: base.limit,
      offset: base.offset,
      hasMore: base.hasMore,
    );
  }

  void _syncPoller() {
    // Keep the bell badge in step after a mark action.
    ref.read(notificationsPollerProvider.notifier).poll();
  }
}

final notificationCenterProvider =
    AsyncNotifierProvider<NotificationCenterController, NotificationsPage>(
  NotificationCenterController.new,
);

// ───────────────────────────────────────────────────────────────────────
// Badge / desktop-toast poller
// ───────────────────────────────────────────────────────────────────────
class NotificationPollState {
  const NotificationPollState({this.unreadCount = 0, this.recent = const []});
  final int unreadCount;

  /// Most-recent notifications (newest first) — used to surface desktop toasts
  /// for items newer than the last-seen id.
  final List<AppNotification> recent;

  /// The newest notification id seen in this poll (0 when none).
  int get latestId => recent.isEmpty ? 0 : recent.first.id;
}

/// Polls the unread count + recent notifications on an interval. Started lazily
/// when first watched (the bell lives in the authenticated shell), and stopped
/// automatically when no longer watched.
class NotificationsPoller extends AsyncNotifier<NotificationPollState> {
  Timer? _timer;

  @override
  Future<NotificationPollState> build() async {
    _timer?.cancel();
    _timer = Timer.periodic(kNotificationsPollInterval, (_) => poll());
    ref.onDispose(() => _timer?.cancel());
    return _fetch();
  }

  Future<NotificationPollState> _fetch() async {
    final page =
        await ref.read(notificationsRepositoryProvider).list(limit: 20);
    return NotificationPollState(
      unreadCount: page.unreadCount,
      recent: page.items,
    );
  }

  /// Force an immediate poll (on resume, after mark-read, after a push).
  Future<void> poll() async {
    final next = await AsyncValue.guard(_fetch);
    // Preserve last-known-good on transient failure.
    if (next is AsyncData<NotificationPollState>) state = next;
  }
}

final notificationsPollerProvider =
    AsyncNotifierProvider<NotificationsPoller, NotificationPollState>(
  NotificationsPoller.new,
);

/// The unread count for the bell badge (0 while loading / on error).
final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsPollerProvider).valueOrNull?.unreadCount ?? 0;
});
