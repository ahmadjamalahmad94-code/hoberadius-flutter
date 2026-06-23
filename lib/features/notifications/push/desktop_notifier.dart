import 'package:flutter/foundation.dart';
import 'package:local_notifier/local_notifier.dart';

import '../../../core/platform/platform_capabilities.dart';
import '../domain/notification_model.dart';

/// Native desktop toast surface. On Windows (and other desktop OSes) a new
/// in-app notification raises a real OS toast; tapping it opens the center via
/// [onOpen]. Guarded by [PlatformCapabilities.isDesktop] — on mobile/web every
/// method is a no-op (mobile uses the in-app center + bell; push toasts there
/// come from FCM once enabled).
class DesktopNotifier {
  DesktopNotifier._();
  static final DesktopNotifier instance = DesktopNotifier._();

  bool _ready = false;
  bool _initFailed = false;

  /// Called when the user taps a toast (set by the shell → opens the center).
  VoidCallback? onOpen;

  Future<void> ensureInitialized() async {
    if (_ready || _initFailed) return;
    if (!PlatformCapabilities.isDesktop) return;
    try {
      await localNotifier.setup(
        appName: 'Hobe Hub',
        // Windows needs a Start-menu shortcut for toasts; create it if absent.
        shortcutPolicy: ShortcutPolicy.requireCreate,
      );
      _ready = true;
    } catch (_) {
      // Never let a notification-plugin failure break the app.
      _initFailed = true;
    }
  }

  /// Raises a desktop toast for [n]. No-op off desktop / before init.
  Future<void> showNotification(AppNotification n) async {
    if (!PlatformCapabilities.isDesktop) return;
    await ensureInitialized();
    if (!_ready) return;
    try {
      final toast = LocalNotification(
        title: n.title.isEmpty ? 'إشعار جديد' : n.title,
        body: n.body,
      );
      toast.onClick = () => onOpen?.call();
      await toast.show();
    } catch (_) {
      // swallow — a toast failure must not surface to the user
    }
  }
}
