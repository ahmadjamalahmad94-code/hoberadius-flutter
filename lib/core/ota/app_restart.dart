import 'package:flutter/services.dart';

/// Restarts the Android process so Shorebird boots the freshly downloaded
/// patch (patches only load at process start).
///
/// The native side is a tiny channel added to MainActivity by
/// `tool/configure_android.sh`. Installs built before it existed don't have
/// it: [isSupported] is then false and [restartOrClose] closes the app
/// instead — the operator reopens it and the update is applied.
class AppRestart {
  const AppRestart._();

  static const _channel = MethodChannel('hoberadius/app_restart');

  static Future<bool> isSupported() async {
    try {
      return await _channel.invokeMethod<bool>('supported') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  static Future<void> restartOrClose() async {
    try {
      await _channel.invokeMethod<void>('restart');
      return;
    } on MissingPluginException {
      // fall through
    } on PlatformException {
      // fall through
    }
    await SystemNavigator.pop();
  }
}
