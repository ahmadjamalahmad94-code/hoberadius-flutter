import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/notifications/application/notifications_providers.dart';
import 'package:hoberadius_app/features/notifications/data/notifications_repository.dart';
import 'package:hoberadius_app/features/notifications/domain/notification_model.dart';
import 'package:hoberadius_app/features/notifications/push/fcm_push_service.dart';
import 'package:hoberadius_app/features/notifications/push/push_service.dart';

class _CountingRepo implements NotificationsRepository {
  int listCalls = 0;

  @override
  Future<NotificationsPage> list({
    bool unreadOnly = false,
    int limit = 30,
    int offset = 0,
  }) async {
    listCalls++;
    return NotificationsPage(
      items: [AppNotification.fromJson({'id': 1, 'is_read': false})],
      unreadCount: 1,
      limit: limit,
      offset: offset,
      hasMore: false,
    );
  }

  @override
  Future<int> unreadCount() async => 1;
  @override
  Future<int> markRead(int id) async => 0;
  @override
  Future<int> markAllRead() async => 0;
}

void main() {
  test('handleIncomingPush routes a push into the center (re-polls backend)',
      () async {
    final repo = _CountingRepo();
    final c = ProviderContainer(
      overrides: [notificationsRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(c.dispose);

    final probe = FutureProvider<bool>((ref) async {
      await handleIncomingPush(ref, const PushMessage(title: 'مرحبا'));
      return true;
    });
    await c.read(probe.future);

    // poll() hit the repo → badge/center refreshed from the authoritative API.
    expect(repo.listCalls, greaterThan(0));
    expect(c.read(unreadCountProvider), 1);
  });

  test('NoopPushService initialize/onLogout are safe no-ops', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    const svc = NoopPushService();
    final probe = FutureProvider<bool>((ref) async {
      await svc.initialize(ref);
      await svc.onLogout(ref);
      return true;
    });
    expect(await c.read(probe.future), isTrue);
  });

  test('FcmPushService is firebase-gated to mobile — safe no-op on desktop host',
      () async {
    // The test host is desktop (not Android/iOS), so initialize must return
    // before touching Firebase or the network, and onLogout must be safe.
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final svc = FcmPushService();
    final probe = FutureProvider<bool>((ref) async {
      await svc.initialize(ref);
      await svc.onLogout(ref);
      return true;
    });
    expect(await c.read(probe.future), isTrue);
  });
}
