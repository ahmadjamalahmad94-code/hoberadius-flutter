# Firebase Push (FCM) — ANDROID ACTIVE

Push is **live for Android** (Firebase project `hoberadius`, package
`com.hoberadius.app`). iOS is **deferred** (no `GoogleService-Info.plist`;
`firebase_options` throws for iOS, so `initialize()` no-ops there). Desktop /
Windows never touch Firebase — they keep the poll-driven `local_notifier`
toasts. The in-app center + bell badge keep working on every platform via
polling `GET /api/v1/notifications`.

## What's wired (this branch)
- `pubspec.yaml` — `firebase_core`, `firebase_messaging`, `flutter_local_notifications` enabled.
- `lib/firebase_options.dart` — **Android-only** `FirebaseOptions` (other platforms throw).
- `lib/main.dart` — calls `bootstrapFcm()` (init Firebase + register the background handler; Android only).
- `lib/features/notifications/push/fcm_push_service.dart` — `FcmPushService`:
  init, `requestPermission()` (incl. Android 13+ `POST_NOTIFICATIONS`), high-importance
  channel, token register + `onTokenRefresh`, foreground `onMessage` (→ center + OS notif),
  `onMessageOpenedApp`, and `onLogout` (delete token locally + on backend).
- `push_service.dart` — `pushServiceProvider` returns `FcmPushService` (self-gates to mobile).
- `push_token_api.dart` — the `POST`/`DELETE /api/v1/devices/push-token` calls.
- `auth_controller.logout()` — calls `pushService.onLogout` before clearing the session.

## Android config persistence (since `android/` is git-ignored + CI-generated)
The Firebase Android config is **not** committed under `android/` (git-ignored).
Instead the source of truth is tracked and re-applied on every generation:
- `tool/firebase/google-services.json` — the verbatim **client** config (committed; package-restricted, safe to commit).
- `tool/configure_android.sh` — idempotent inject step. Run it **after**
  `flutter create --platforms=android .`. It:
  1. copies `tool/firebase/google-services.json` → `android/app/google-services.json`
  2. forces `applicationId = com.hoberadius.app` (must match the json's `package_name`)
  3. applies the `com.google.gms.google-services` Gradle plugin (Kotlin-DSL settings + app; Groovy fallback handled)
  4. adds the INTERNET permission + cleartext-traffic to the release manifest

### CI wiring (one line)
In the Android build workflow (the `ci/android-apk` branch's
`.github/workflows/build.yml`), right **after** the `flutter create
--platforms=android …` step, add:
```bash
bash tool/configure_android.sh
```
This replaces that workflow's inline applicationId/manifest tweaks and guarantees
a fresh `flutter create` keeps `com.hoberadius.app` + `google-services.json` + the plugin.

> ⚠️ The committed `google-services.json` is the **client** config (API key is
> package-restricted). The Firebase **Admin SDK private-key JSON** (server
> sender credentials) is server-only and must **NEVER** be committed to this app repo.

## firebase_options.dart (Android values)
```
apiKey:            AIzaSyA73rNU5ypuxTKzoQ9PqS9EEvIeJBAVUt0
appId:             1:358020404999:android:82102636924bea5a4297a2
messagingSenderId: 358020404999
projectId:         hoberadius
storageBucket:     hoberadius.firebasestorage.app
```

## Token registration (backend contract)
On token availability + refresh the app calls (auth via the existing Bearer token):
```
POST   /api/v1/devices/push-token   { "token": "<fcm>", "platform": "android" }
DELETE /api/v1/devices/push-token   { "token": "<fcm>" }      (on logout)
```
This endpoint is **live on `radius-module` main** (`app/api/v1/devices.py`):
register/upsert + unregister, tenant+admin scoped, idempotent. The read side
(`GET /api/v1/notifications`) also shipped on radius-module main.

## Build caveats
- **Windows:** `firebase_core` has a Windows implementation that
  `FetchContent`-downloads the Firebase C++ SDK at build time, so the Windows
  build now pulls that SDK (slower first build, needs network). **Runtime is
  unaffected** — all Firebase calls are gated by `PlatformCapabilities.isMobile`,
  so Windows never initializes Firebase and keeps the `local_notifier` toasts.
- **iOS:** deferred. To enable later: add `ios/Runner/GoogleService-Info.plist`,
  an iOS entry in `firebase_options.dart`, Push Notifications capability + APNs
  key, then `platform == iOS` in `DefaultFirebaseOptions.currentPlatform`.

## To enable Android push end-to-end (owner checklist)
1. Ensure the backend `POST/DELETE /api/v1/devices/push-token` endpoint is live.
2. Add `bash tool/configure_android.sh` to the CI Android build (after `flutter create`).
3. Send a test message from the Firebase console / your server to a registered token.
