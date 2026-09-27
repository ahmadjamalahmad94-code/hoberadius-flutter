import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/tokens.dart';

class HobeRadiusApp extends ConsumerWidget {
  const HobeRadiusApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    // Light-only by spec (RTL admin). The dark ThemeData is still
    // half-migrated — many widgets hardcode light AppTokens colors — so a
    // phone set to OS dark mode rendered dark-on-dark artefacts (black time
    // picker, invisible switch labels). Force light app-wide until dark mode
    // is fully built; there is no user-facing theme toggle yet, so this has
    // no UX downside.
    return MaterialApp.router(
      title: 'Hobe Hub',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      themeMode: ThemeMode.light,
      routerConfig: router,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        // Light-only chrome: keep the OS status/nav bars tinted to our light
        // brand surfaces with dark icons (the app forces ThemeMode.light).
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
            systemNavigationBarColor: AppTokens.bg,
            systemNavigationBarIconBrightness: Brightness.dark,
            systemNavigationBarDividerColor: Colors.transparent,
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
