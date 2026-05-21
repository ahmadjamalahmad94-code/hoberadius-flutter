import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/core/theme/dark_tokens.dart';
import 'package:hoberadius_app/core/theme/tokens.dart';

/// Shared test harness for J2 canonical-widget goldens.
///
/// Skips the production [AppTheme] factories so we don't pull in
/// GoogleFonts (which would try to fetch Cairo over the network in a
/// hermetic test environment). The harness ThemeData below mirrors the
/// same ColorScheme and component themes so the colors/spacings
/// captured in goldens stay representative — only the typography
/// falls back to the platform default, which is the part of the theme
/// we deliberately want decoupled from network state.
Future<void> pumpGolden(
  WidgetTester tester, {
  required Brightness brightness,
  required Widget child,
  TextDirection direction = TextDirection.rtl,
  Size size = const Size(420, 700),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _harnessTheme(brightness),
      home: Directionality(
        textDirection: direction,
        child: Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pumpAndSettle(const Duration(milliseconds: 400));
}

ThemeData _harnessTheme(Brightness brightness) {
  if (brightness == Brightness.dark) {
    return ThemeData.dark(useMaterial3: true).copyWith(
      colorScheme: const ColorScheme.dark(
        primary: DarkTokens.brand,
        onPrimary: Colors.white,
        primaryContainer: DarkTokens.brandSoft,
        onPrimaryContainer: DarkTokens.brandInk,
        secondary: DarkTokens.brandInk,
        onSecondary: Colors.white,
        surface: DarkTokens.card,
        onSurface: DarkTokens.textPrimary,
        surfaceContainerHighest: DarkTokens.soft,
        outline: DarkTokens.border,
        outlineVariant: DarkTokens.borderSoft,
        error: DarkTokens.red,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: DarkTokens.bg,
    );
  }
  return ThemeData.light(useMaterial3: true).copyWith(
    colorScheme: const ColorScheme.light(
      primary: AppTokens.brand,
      onPrimary: Colors.white,
      primaryContainer: AppTokens.brandSoft,
      onPrimaryContainer: AppTokens.brandInk,
      secondary: AppTokens.brandInk,
      onSecondary: Colors.white,
      surface: AppTokens.card,
      onSurface: AppTokens.textPrimary,
      surfaceContainerHighest: AppTokens.soft,
      outline: AppTokens.border,
      outlineVariant: AppTokens.borderSoft,
      error: AppTokens.red,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: AppTokens.bg,
  );
}

/// Convenience: golden-file path resolver inside `goldens/`.
String goldenPath(String name) => 'goldens/$name.png';
