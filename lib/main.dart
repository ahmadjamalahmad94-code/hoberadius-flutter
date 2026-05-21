import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // J6.2: opt into Android's edge-to-edge mode so the scaffold can
  // paint underneath the system bars; AnnotatedRegion in HobeRadiusApp
  // owns the icon brightness + chrome tint per theme.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const ProviderScope(child: HobeRadiusApp()));
}
