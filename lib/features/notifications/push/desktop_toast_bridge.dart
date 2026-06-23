import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/platform/platform_capabilities.dart';
import '../application/notifications_providers.dart';
import 'desktop_notifier.dart';

/// Bridges the badge poller to native desktop toasts: whenever a poll surfaces
/// a notification newer than the last one we toasted, raise a Windows toast.
///
/// The first poll only establishes a baseline (it does NOT toast the existing
/// backlog), so the user is only interrupted for genuinely new notifications.
/// No-op on mobile/web — kept alive by the shell via `ref.watch`.
final desktopToastBridgeProvider = Provider<void>((ref) {
  if (!PlatformCapabilities.isDesktop) return;

  // -1 = baseline not yet captured; we skip toasting on the first successful
  // poll so the whole backlog doesn't pop on launch.
  var lastShownId = -1;

  ref.listen(notificationsPollerProvider, (_, next) {
    final state = next.valueOrNull;
    if (state == null) return;
    if (lastShownId < 0) {
      lastShownId = state.latestId;
      return;
    }
    final fresh = state.recent.where((n) => n.id > lastShownId).toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    for (final n in fresh) {
      DesktopNotifier.instance.showNotification(n);
    }
    if (state.latestId > lastShownId) lastShownId = state.latestId;
  });
});
