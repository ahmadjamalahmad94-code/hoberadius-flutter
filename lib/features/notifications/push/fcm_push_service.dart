// Firebase Cloud Messaging implementation of PushService — ANDROID ACTIVE.
//
// Self-gates to mobile (PlatformCapabilities.isMobile); on desktop/web every
// method returns immediately so the Windows build never touches Firebase at
// runtime (it keeps the local_notifier toast path). iOS is deferred —
// firebase_options throws for iOS, so initialize() no-ops there until an iOS
// config is added.
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/platform/platform_capabilities.dart';
import '../../../firebase_options.dart';
import 'push_service.dart';
import 'push_token_api.dart';

const _androidChannel = AndroidNotificationChannel(
  'hoberadius_push',
  'إشعارات HobeRadius',
  description: 'إشعارات النظام والاشتراكات والخدمات',
  importance: Importance.high,
);

/// Background isolate handler — MUST be a top-level function with this pragma.
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is up in the background isolate. The next foreground poll
  // reconciles the center, so there's nothing else to do here.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.android);
}

/// Startup bootstrap called from main() (before runApp): initializes Firebase
/// and registers the background handler so pushes are delivered even when the
/// app is backgrounded/terminated. No-op off Android (mobile, non-iOS).
Future<void> bootstrapFcm() async {
  if (!PlatformCapabilities.isMobile) return;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
  } catch (_) {
    // iOS (deferred) / any init failure → push stays off; app runs normally.
  }
}

class FcmPushService implements PushService {
  FcmPushService();

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  bool _wired = false;
  String? _lastToken;

  @override
  Future<void> initialize(Ref ref) async {
    if (!PlatformCapabilities.isMobile) return; // Android (iOS deferred)
    if (_wired) return;
    try {
      // Idempotent with bootstrapFcm(); safe if main() already initialized.
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (_) {
      return; // iOS deferred / init failure → no push
    }
    _wired = true;

    final messaging = FirebaseMessaging.instance;

    // Permission: iOS prompt + Android 13+ POST_NOTIFICATIONS.
    await messaging.requestPermission();
    final androidPlugin =
        _local.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.createNotificationChannel(_androidChannel);

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _local.initialize(initSettings);

    // (1) register device token now + on refresh.
    final token = await messaging.getToken();
    if (token != null) await _registerToken(ref, token);
    messaging.onTokenRefresh.listen((t) => _registerToken(ref, t));

    // (2) foreground messages → shared center + an OS notification.
    FirebaseMessaging.onMessage.listen((m) async {
      await handleIncomingPush(ref, _toPushMessage(m));
      final n = m.notification;
      if (n != null) {
        await _local.show(
          m.hashCode,
          n.title ?? 'إشعار جديد',
          n.body ?? '',
          NotificationDetails(
            android: AndroidNotificationDetails(
              _androidChannel.id,
              _androidChannel.name,
              channelDescription: _androidChannel.description,
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
        );
      }
    });

    // (3) tap-to-open from a background notification → refresh the center.
    FirebaseMessaging.onMessageOpenedApp.listen((m) {
      handleIncomingPush(ref, _toPushMessage(m));
      // Navigation is handled by the shell (DesktopNotifier.onOpen-style wiring
      // is desktop; on mobile the user lands on the app and sees the badge).
    });
  }

  @override
  Future<void> onLogout(Ref ref) async {
    if (!PlatformCapabilities.isMobile) return;
    final token = _lastToken;
    try {
      if (token != null) {
        await PushTokenApi(ref.read(apiClientProvider)).unregister(token);
      }
    } catch (_) {/* best-effort */}
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {/* best-effort */}
    _lastToken = null;
  }

  PushMessage _toPushMessage(RemoteMessage m) => PushMessage(
        title: m.notification?.title ?? (m.data['title'] ?? '').toString(),
        body: m.notification?.body ?? (m.data['body'] ?? '').toString(),
        link: (m.data['link'] ?? '').toString(),
      );

  Future<void> _registerToken(Ref ref, String token) async {
    _lastToken = token;
    try {
      await PushTokenApi(ref.read(apiClientProvider)).register(token);
    } catch (_) {
      // Non-fatal: registration retries on the next onTokenRefresh.
    }
  }
}
