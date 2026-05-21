import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/core/theme/tokens.dart';

/// Mobile screen harness — pumps any top-level screen at the two mobile
/// breakpoints declared in `AppTokens` so we can freeze the mobile
/// look-and-feel against the Windows-parity work landing in
/// `docs/FLUTTER_WINDOWS_PARITY_PLAN.md`.
///
/// Usage:
///
/// ```dart
/// testWidgets('print_templates phone', (tester) async {
///   await pumpMobileScreen(
///     tester,
///     breakpoint: MobileBreakpoint.phone,
///     child: const PrintTemplatesScreen(),
///   );
///   await expectLater(
///     find.byType(PrintTemplatesScreen),
///     matchesGoldenFile('goldens/print_templates_phone.png'),
///   );
/// });
/// ```
enum MobileBreakpoint {
  phone(360, 720),
  tablet(600, 960);

  const MobileBreakpoint(this.width, this.height);
  final double width;
  final double height;
}

Future<void> pumpMobileScreen(
  WidgetTester tester, {
  required MobileBreakpoint breakpoint,
  required Widget child,
  Brightness brightness = Brightness.light,
  TextDirection direction = TextDirection.rtl,
}) async {
  final size = Size(breakpoint.width, breakpoint.height);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: AppTokens.bg,
      ),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
      home: MediaQuery(
        data: MediaQueryData(size: size, devicePixelRatio: 1),
        child: Directionality(
          textDirection: direction,
          child: child,
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pumpAndSettle(const Duration(milliseconds: 300));
}

/// Convenience: golden path resolver inside `test/screens/goldens/`.
String mobileGolden(String name) => 'goldens/$name.png';
