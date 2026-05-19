// Smoke test: the app boots, the router redirects unauthenticated traffic to
// /login, and the login screen renders without throwing.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hoberadius_app/app.dart';

void main() {
  testWidgets('app boots and lands on login', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: HobeRadiusApp()));
    await tester.pumpAndSettle();
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('دخول'), findsOneWidget);
  });
}
