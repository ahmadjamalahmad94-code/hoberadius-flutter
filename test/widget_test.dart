// Smoke test: the app boots, the router redirects unauthenticated traffic to
// /login, and the login screen renders without throwing.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hoberadius_app/app.dart';
import 'package:hoberadius_app/core/auth/token_storage.dart';

/// No saved session. (The real secure storage never answers inside a widget
/// test; since fix3 the app waits for the saved token before deciding —
/// a reload keeps its page — so the test gives it an empty store.)
class _NoToken implements TokenStorage {
  @override
  Future<void> clear() async {}
  @override
  Future<String?> read() async => null;
  @override
  Future<void> write(String token) async {}
}

void main() {
  testWidgets('app boots and lands on login', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [tokenStorageProvider.overrideWithValue(_NoToken())],
        child: const HobeRadiusApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('دخول'), findsOneWidget);
    expect(find.text('IP أو دومين الخادم'), findsOneWidget);
  });
}
