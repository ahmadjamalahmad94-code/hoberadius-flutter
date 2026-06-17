import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/core/api/api_client.dart';
import 'package:hoberadius_app/core/api/api_endpoint_storage.dart';
import 'package:hoberadius_app/core/auth/security_key_storage.dart';
import 'package:hoberadius_app/core/auth/token_storage.dart';
import 'package:hoberadius_app/core/theme/tokens.dart';

/// Shared harness for the systematic per-screen overflow sweep (owner hard
/// rule #2: no design breakage at any width). Each routed screen is pumped
/// inside the same vertical-scroll content wrapper the shell uses, at the
/// narrow mobile / tablet / Windows widths, with a fake API client so the
/// screen resolves to a real rendered state (loaded-empty or error — both are
/// valid to overflow-check). A horizontal RenderFlex overflow surfaces as a
/// FlutterError caught by `takeException()`.

class _MemTokenStorage implements TokenStorage {
  @override
  Future<void> clear() async {}
  @override
  Future<String?> read() async => 'test-token';
  @override
  Future<void> write(String token) async {}
}

class _MemEndpointStorage implements ApiEndpointStorage {
  @override
  Future<String> readBaseUrl() async => 'http://127.0.0.1:5000';
  @override
  Future<void> writeBaseUrl(String baseUrl) async {}
}

class _MemSecurityKeyStorage implements SecurityKeyStorage {
  @override
  Future<void> clear() async {}
  @override
  Future<String?> read() async => null;
  @override
  Future<void> write(String key) async {}
}

/// Returns a benign, permissive envelope for ANY request so every screen's
/// providers resolve. List screens see empty collections; object screens get
/// an empty map (→ model defaults). Binary endpoints get a couple of bytes.
class _BenignAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.responseType == ResponseType.bytes) {
      return ResponseBody.fromBytes(
        Uint8List.fromList(const [37, 80, 68, 70]),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/octet-stream'],
        },
      );
    }
    const body = {
      'ok': true,
      'data': {
        'items': <dynamic>[],
        'rows': <dynamic>[],
        'sections': <dynamic>[],
        'data': <dynamic>[],
        'count': 0,
        'total': 0,
      },
    };
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

ApiClient buildFakeApiClient() {
  final client = ApiClient(
    _MemTokenStorage(),
    _MemEndpointStorage(),
    securityKeyStorage: _MemSecurityKeyStorage(),
  );
  client.dio.httpClientAdapter = _BenignAdapter();
  return client;
}

/// Sweep widths: 360 (smallest phone), 600 (tablet-portrait), 1280 (Windows
/// desktop). Horizontal overflow is almost always a narrow-width problem, but
/// wide is checked too so nothing assumes a fixed huge viewport.
const sweepWidths = <double>[360, 600, 1280];

Future<void> pumpScreenAtWidth(
  WidgetTester tester,
  Widget screen,
  double width, {
  ApiClient? client,
}) async {
  final size = Size(width, 2200);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(client ?? buildFakeApiClient()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        // Deterministic default font (no GoogleFonts runtime fetch in tests) so
        // results are stable and reflect STRUCTURAL layout, not font-fetch
        // metric noise. Matches the dashboard overflow-guard template.
        theme: ThemeData.light(useMaterial3: true).copyWith(
          scaffoldBackgroundColor: AppTokens.bg,
        ),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            // Mirrors the shell's _ContentArea: vertical scroll so only
            // HORIZONTAL overflow (the real design-breakage risk) is flagged.
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: screen,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  // Resolve provider futures + any post-frame work.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 350));
}

/// Pumps [screen] at each [sweepWidths] entry, asserting no overflow/clipping
/// at each. Disposes the tree between widths so async work from one width can't
/// leak into the next (keeps the per-width check isolated + deterministic).
Future<void> expectNoOverflowAcrossWidths(
  WidgetTester tester,
  Widget Function() build,
  String name,
) async {
  for (final width in sweepWidths) {
    await pumpScreenAtWidth(tester, build(), width);
    expect(
      tester.takeException(),
      isNull,
      reason: '$name overflowed/threw at ${width.toInt()}px',
    );
  }
}
