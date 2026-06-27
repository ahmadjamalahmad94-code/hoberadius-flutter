import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/notifications_providers.dart';
import 'fcm_push_service.dart';

/// A normalized push message (decoupled from any specific transport so the
/// shared code never depends on a firebase type).
class PushMessage {
  const PushMessage({this.title = '', this.body = '', this.link = ''});
  final String title;
  final String body;
  final String link;
}

/// Pluggable push transport. The app always depends on this abstraction; the
/// concrete FCM implementation lives in [FcmPushService]. The default is
/// [NoopPushService] (used in tests / when FCM is intentionally off).
abstract class PushService {
  /// Wire up the transport (init Firebase, request permission, register the
  /// device token with the backend, attach foreground/opened handlers).
  /// Safe to call on any platform — implementations gate to mobile.
  Future<void> initialize(Ref ref);

  /// Tear down on logout — delete the device token locally + on the backend so
  /// the signed-out device stops receiving pushes.
  Future<void> onLogout(Ref ref);
}

class NoopPushService implements PushService {
  const NoopPushService();

  @override
  Future<void> initialize(Ref ref) async {}

  @override
  Future<void> onLogout(Ref ref) async {}
}

/// The single switch-point for the push transport. ANDROID-ACTIVE: returns the
/// real [FcmPushService]; it self-gates to mobile, so desktop/web get a no-op
/// at runtime while keeping the Windows `local_notifier` toast path.
final pushServiceProvider = Provider<PushService>((ref) {
  return FcmPushService();
});

/// Initializes the push service once. Watched by the shell so it runs after the
/// user is authenticated.
final pushBootstrapProvider = Provider<void>((ref) {
  ref.read(pushServiceProvider).initialize(ref);
});

/// Shared entry point the FCM implementation calls when a push arrives, so push
/// and polling converge on the SAME notification center: it re-polls the
/// backend (authoritative source) to refresh the badge and pull the new row
/// into the center. The FCM impl additionally shows an OS notification for
/// foreground messages.
Future<void> handleIncomingPush(Ref ref, PushMessage message) async {
  await ref.read(notificationsPollerProvider.notifier).poll();
  ref.invalidate(notificationCenterProvider);
}
