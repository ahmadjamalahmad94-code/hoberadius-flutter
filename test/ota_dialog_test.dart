import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hoberadius_app/core/ota/ota_dialogs.dart';
import 'package:hoberadius_app/core/ota/ota_updater.dart';
import 'package:hoberadius_app/core/theme/app_theme.dart';

class _Fixed extends OtaController {
  _Fixed(OtaState s) : super(enabled: false) {
    state = s;
  }
}

Future<void> _pump(
  WidgetTester tester,
  OtaPhase phase, {
  String error = '',
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        otaControllerProvider.overrideWith(
          (ref) => _Fixed(OtaState(phase: phase, error: error)),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(body: OtaUpdateDialog()),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 50));
  tester.takeException(); // google_fonts asset lookup in tests
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('available: تثبيت / لاحقًا', (tester) async {
    await _pump(tester, OtaPhase.available);
    expect(find.text('يوجد تحديث جديد'), findsOneWidget);
    expect(find.text('تثبيت'), findsOneWidget);
    expect(find.text('لاحقًا'), findsOneWidget);
  });

  testWidgets('downloading: progress bar, no buttons', (tester) async {
    await _pump(tester, OtaPhase.downloading);
    expect(find.text('جاري التحديث…'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('ready: restart (or close when the native channel is missing)',
      (tester) async {
    await _pump(tester, OtaPhase.readyToRestart);
    await tester.pump(); // the async native-channel probe resolves
    await tester.pump();
    expect(find.text('التحديث جاهز'), findsOneWidget);
    // «إعادة التشغيل» while the native channel answers; «إغلاق التطبيق» on an
    // install without it (older APK). Either way there is a restart action.
    expect(
      find.text('إعادة التشغيل').evaluate().length +
          find.text('إغلاق التطبيق').evaluate().length,
      1,
    );
    expect(find.text('لاحقًا'), findsOneWidget);
  });

  testWidgets('failed: retry', (tester) async {
    await _pump(tester, OtaPhase.failed);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
  });

  testWidgets('failed: shows the real reason under the message',
      (tester) async {
    await _pump(tester, OtaPhase.failed, error: 'HTTP 500 from update server');
    expect(find.byKey(const ValueKey('ota-error-detail')), findsOneWidget);
    expect(find.textContaining('HTTP 500'), findsOneWidget);
  });
}
