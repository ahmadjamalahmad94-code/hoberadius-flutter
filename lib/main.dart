import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'features/notifications/push/fcm_push_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // J6.2: opt into Android's edge-to-edge mode so the scaffold can
  // paint underneath the system bars; AnnotatedRegion in HobeRadiusApp
  // owns the icon brightness + chrome tint per theme.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  // Initialize Firebase + register the FCM background handler (Android only;
  // no-op on desktop/web/iOS). Foreground/token wiring happens post-auth via
  // pushBootstrapProvider watched by the shell.
  await bootstrapFcm();
  runApp(const ProviderScope(child: HobeRadiusApp()));
}
