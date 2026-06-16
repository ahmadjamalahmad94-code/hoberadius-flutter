import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/core/api/api_endpoint_storage.dart';
import 'package:hoberadius_app/core/auth/auth_controller.dart';
import 'package:hoberadius_app/core/auth/token_storage.dart';
import 'package:hoberadius_app/features/auth/presentation/login_screen.dart';

class _FakeEndpointStorage implements ApiEndpointStorage {
  @override
  Future<String> readBaseUrl() async => 'https://demo.hoberadius.test';
  @override
  Future<void> writeBaseUrl(String baseUrl) async {}
}

/// Token read never completes, so [AuthController]'s constructor `_restore()`
/// awaits forever and does not overwrite the state we inject for the test.
class _PendingTokenStorage implements TokenStorage {
  @override
  Future<String?> read() => Completer<String?>().future;
  @override
  Future<void> write(String token) async {}
  @override
  Future<void> clear() async {}
}

class _FakeAuthController extends AuthController {
  _FakeAuthController(super.ref, AuthState initial) {
    state = initial;
  }
  @override
  Future<void> login({
    required String baseUrl,
    required String username,
    required String password,
  }) async {}
}

Future<void> _pumpLogin(WidgetTester tester, AuthState state) async {
  tester.view.physicalSize = const Size(700, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        apiEndpointStorageProvider.overrideWithValue(_FakeEndpointStorage()),
        tokenStorageProvider.overrideWithValue(_PendingTokenStorage()),
        authControllerProvider.overrideWith(
          (ref) => _FakeAuthController(ref, state),
        ),
      ],
      child: const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: LoginScreen(),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('login shows Arabic title + fields', (tester) async {
    await _pumpLogin(tester, const AuthState());
    expect(find.text('تسجيل دخول الإدارة'), findsOneWidget);
    expect(find.text('اسم المستخدم'), findsOneWidget);
    expect(find.text('كلمة المرور'), findsOneWidget);
    expect(find.text('دخول'), findsOneWidget);
  });

  testWidgets('login renders the failure-state error banner', (tester) async {
    await _pumpLogin(
      tester,
      const AuthState(error: 'بيانات الدخول غير صحيحة'),
    );
    expect(find.text('بيانات الدخول غير صحيحة'), findsOneWidget);
  });

  testWidgets('login disables actions and shows spinner while loading',
      (tester) async {
    await _pumpLogin(tester, const AuthState(loading: true));
    // The "دخول" label is replaced by a progress indicator while loading.
    expect(find.text('دخول'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
