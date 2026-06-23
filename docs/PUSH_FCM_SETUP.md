# Enabling Firebase Push (FCM) — drop-in guide

Push is **fully scaffolded but inert** until you drop in the Firebase config.
Today the app builds and runs on **mobile and Windows with no Firebase
dependency in the tree** (the in-app notification center, bell badge, and
Windows toasts all work via polling `GET /api/v1/notifications`). FCM is
**mobile-only**; desktop keeps the poll-driven toasts.

## What's already in place (no action needed)
- `lib/features/notifications/push/push_service.dart` — the `PushService`
  abstraction, the `NoopPushService` default, `pushServiceProvider` (the single
  switch-point), `pushBootstrapProvider` (run by the shell), and
  `handleIncomingPush()` — the shared sink that routes any push into the SAME
  notification center (re-polls the backend + refreshes the badge/center).
- `lib/features/notifications/push/fcm_push_service.dart.txt` — the complete
  FCM implementation (token registration, foreground/background/opened
  handlers, local notification for foreground messages). Ships as `.txt` so it
  is not compiled until you enable it.
- `pubspec.yaml` — `firebase_core` / `firebase_messaging` lines, **commented**.

## Exact files / keys YOU must provide
1. **Android:** `android/app/google-services.json` (from the Firebase console,
   for the app's package id `com.hoberadius.app`). Also apply the Google
   Services Gradle plugin:
   - `android/build.gradle`: classpath `com.google.gms:google-services:4.4.2`
   - `android/app/build.gradle`: `apply plugin: 'com.google.gms.google-services'`
   > NOTE: the `android/` folder is git-ignored and regenerated in CI
   > (`flutter create`), so add a CI step that writes `google-services.json`
   > and patches these two Gradle lines (mirror the existing manifest-patch
   > step in `.github/workflows/build.yml`).
2. **iOS:** `ios/Runner/GoogleService-Info.plist` (+ enable Push Notifications
   capability and an APNs key in the Apple Developer portal).
3. **Server key:** add your FCM server credentials to the backend sender (the
   service that calls `notifications_repo.create` can also send the FCM
   message). Not required for the app to build.

## Flip it on (no code rewrite — 4 steps)
1. Uncomment in `pubspec.yaml`:
   ```yaml
   firebase_core: ^3.6.0
   firebase_messaging: ^15.1.3
   flutter_local_notifications: ^18.0.1   # mobile foreground local notif
   ```
   then `flutter pub get`.
2. Add the native config files from above.
3. Rename `fcm_push_service.dart.txt` → `fcm_push_service.dart`.
4. In `push_service.dart`, change the provider body to:
   ```dart
   final pushServiceProvider = Provider<PushService>((ref) {
     return FcmPushService();
   });
   ```
   (add `import 'fcm_push_service.dart';`).

That's it. `pushBootstrapProvider` (already watched by the shell) will call
`FcmPushService.initialize`, register the device token, and route incoming
pushes through `handleIncomingPush` into the existing center + badge.

## Backend counterpart to add when enabling push
The token-registration call posts to `POST /api/v1/devices/push-token`
`{ "token": "...", "platform": "android|ios|..." }`. Add this endpoint
(store the token per tenant/admin) so the backend can target devices. The
read side (`GET /api/v1/notifications`) already exists
(`radius-module` branch `feat/api-notifications`).

## Why deps are commented instead of present-but-unused
`firebase_core` has a Windows implementation that `FetchContent`-downloads the
Firebase C++ SDK at build time. Leaving it in the tree would change the Windows
build footprint before any keys exist. Commenting the two deps keeps both the
mobile and Windows builds byte-for-byte unchanged until you opt in — which is
the hard requirement ("don't break the build if Firebase config is missing").
