import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/notifications_providers.dart';

/// A normalized push message (decoupled from any specific transport so the
/// in-tree code never imports firebase).
class PushMessage {
  const PushMessage({this.title = '', this.body = '', this.link = ''});
  final String title;
  final String body;
  final String link;
}

/// Pluggable push transport. The app always depends on this abstraction; the
/// concrete FCM implementation is a DROP-IN (see docs/PUSH_FCM_SETUP.md and
/// fcm_push_service.dart.txt). Default is [NoopPushService] so the app builds
/// and runs on mobile + Windows with no Firebase config present.
abstract class PushService {
  /// Wire up the transport (request permission, register the device token with
  /// the backend, attach foreground/background handlers). Must be safe to call
  /// when no config exists — the no-op default simply returns.
  Future<void> initialize(Ref ref);
}

class NoopPushService implements PushService {
  const NoopPushService();

  @override
  Future<void> initialize(Ref ref) async {
    // No Firebase config → push disabled. The in-app center + bell + Windows
    // toasts continue to work via polling.
  }
}

/// The single switch-point. To enable push, flip this to `FcmPushService()`
/// (provided in fcm_push_service.dart.txt) — no other code changes.
final pushServiceProvider = Provider<PushService>((ref) {
  return const NoopPushService();
});

/// Initializes the push service once. Watched by the shell so it runs after the
/// user is authenticated. No-op with the default service.
final pushBootstrapProvider = Provider<void>((ref) {
  ref.read(pushServiceProvider).initialize(ref);
});

/// Shared entry point the concrete FCM implementation calls when a push
/// arrives, so push and polling converge on the SAME notification center:
/// it re-polls the backend (authoritative source) to refresh the badge and
/// pull the new row into the center. The FCM impl additionally shows an OS
/// notification for foreground messages.
Future<void> handleIncomingPush(Ref ref, PushMessage message) async {
  await ref.read(notificationsPollerProvider.notifier).poll();
  ref.invalidate(notificationCenterProvider);
}
