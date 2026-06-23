import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hoberadius_app/core/api/api_endpoint_storage.dart';
import 'package:hoberadius_app/core/auth/auth_controller.dart';
import 'package:hoberadius_app/core/auth/security_key_storage.dart';
import 'package:hoberadius_app/core/auth/token_storage.dart';
import 'package:hoberadius_app/features/notifications/application/notifications_providers.dart';
import 'package:hoberadius_app/features/notifications/push/desktop_toast_bridge.dart';
import 'package:hoberadius_app/features/notifications/push/push_service.dart';
import 'package:hoberadius_app/features/shell/shell_scaffold.dart';
import 'package:hoberadius_app/shared/widgets/responsive_layout.dart';

class _FakeEndpointStorage implements ApiEndpointStorage {
  @override
  Future<String> readBaseUrl() async => 'https://demo.hoberadius.test';
  @override
  Future<void> writeBaseUrl(String baseUrl) async {}
}

class _PendingTokenStorage implements TokenStorage {
  @override
  Future<String?> read() => Completer<String?>().future;
  @override
  Future<void> write(String token) async {}
  @override
  Future<void> clear() async {}
}

class _FakeSecurityKeyStorage implements SecurityKeyStorage {
  @override
  Future<String?> read() async => null;
  @override
  Future<void> write(String key) async {}
  @override
  Future<void> clear() async {}
}

class _AuthedController extends AuthController {
  _AuthedController(super.ref) {
    state = AuthState(
      token: 'tkn',
      admin: AuthAdmin(id: 1, username: 'admin', fullName: 'مدير النظام'),
    );
  }
}

Future<void> _pumpShell(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (ctx, st, child) => ShellScaffold(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (ctx, st) =>
                const Text('CONTENT', textDirection: TextDirection.rtl),
          ),
        ],
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        apiEndpointStorageProvider.overrideWithValue(_FakeEndpointStorage()),
        tokenStorageProvider.overrideWithValue(_PendingTokenStorage()),
        securityKeyStorageProvider.overrideWithValue(_FakeSecurityKeyStorage()),
        authControllerProvider.overrideWith((ref) => _AuthedController(ref)),
        // Stub the notification wiring the shell activates so these chrome
        // tests don't start the 60s poll timer (which would leave a pending
        // timer) or hit the network.
        unreadCountProvider.overrideWithValue(0),
        desktopToastBridgeProvider.overrideWith((ref) {}),
        pushBootstrapProvider.overrideWith((ref) {}),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pump();
}

void main() {
  group('shellLayoutModeForWidth', () {
    test('desktop + tablet-landscape widths keep the full sidebar', () {
      expect(shellLayoutModeForWidth(1920), ShellLayoutMode.fullSidebar);
      expect(shellLayoutModeForWidth(1280), ShellLayoutMode.fullSidebar);
      // Tablet-landscape (1024) and a desktop window shrunk to ~1000 still get
      // the full sidebar — the original bug collapsed these to mobile.
      expect(shellLayoutModeForWidth(1024), ShellLayoutMode.fullSidebar);
      expect(shellLayoutModeForWidth(1000), ShellLayoutMode.fullSidebar);
    });

    test('narrow desktop band uses the icon rail', () {
      expect(shellLayoutModeForWidth(999), ShellLayoutMode.iconRail);
      expect(shellLayoutModeForWidth(900), ShellLayoutMode.iconRail);
      expect(shellLayoutModeForWidth(840), ShellLayoutMode.iconRail);
    });

    test('phone / tablet-portrait widths fall back to the drawer', () {
      expect(shellLayoutModeForWidth(839), ShellLayoutMode.drawer);
      // 810 ≈ tablet-portrait → drawer (matches the owner's requirement).
      expect(shellLayoutModeForWidth(810), ShellLayoutMode.drawer);
      expect(shellLayoutModeForWidth(600), ShellLayoutMode.drawer);
      expect(shellLayoutModeForWidth(380), ShellLayoutMode.drawer);
    });
  });

  group('ShellScaffold renders the right chrome per width', () {
    testWidgets('desktop width shows the full web sidebar (brand visible)',
        (tester) async {
      await _pumpShell(tester, const Size(1400, 900));
      expect(find.text('Hobe Hub'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('mid width shows the collapsed icon rail (brand hidden)',
        (tester) async {
      await _pumpShell(tester, const Size(900, 900));
      // Sidebar present (brand icon chip) but the wordmark is collapsed away,
      // and there is no phone bottom-nav.
      expect(find.byIcon(Icons.wifi_tethering), findsOneWidget);
      expect(find.text('Hobe Hub'), findsNothing);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('phone width falls back to the bottom navigation bar',
        (tester) async {
      await _pumpShell(tester, const Size(420, 900));
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Hobe Hub'), findsNothing);
    });
  });
}
