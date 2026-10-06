// Owner 2026-10-07: «ما في صفحة للتحديثات ولا زر لفحص آخر تحديث ولا صفحة
// حول لرقم الإصدار ونسخة التحديث».
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hoberadius_app/core/ota/ota_updater.dart';
import 'package:hoberadius_app/core/ota/release_notes.dart';
import 'package:hoberadius_app/features/more/presentation/about_screen.dart';

class _Fixed extends OtaController {
  _Fixed(OtaState s) : super(enabled: false) {
    state = s;
  }
}

Future<void> _pump(WidgetTester tester, OtaState s) async {
  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        otaControllerProvider.overrideWith((ref) => _Fixed(s)),
        releaseNotesHistoryProvider.overrideWith(
          (ref) async => [
            const ReleaseNote(
                patch: 25, date: '2026-10-06', items: ['حذف الحقول']),
            const ReleaseNote(
                patch: 24, date: '2026-10-05', items: ['تنبيه الحروف']),
          ],
        ),
      ],
      child: const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          // like the app shell: the body is already scrollable
          child: Scaffold(body: SingleChildScrollView(child: AboutScreen())),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  tester.takeException();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('shows version, current patch, check button and history',
      (tester) async {
    await _pump(
        tester, const OtaState(phase: OtaPhase.upToDate, currentPatch: 24));
    expect(find.text(kAppRelease), findsOneWidget);
    expect(find.text('#24'), findsOneWidget);
    expect(find.byKey(const ValueKey('about-check')), findsOneWidget);
    expect(find.textContaining('تحديث #25'), findsOneWidget);
    expect(find.textContaining('(المثبّت)'), findsOneWidget);
  });

  testWidgets('failed download shows the reason and a retry button',
      (tester) async {
    await _pump(
      tester,
      const OtaState(
        phase: OtaPhase.failed,
        currentPatch: 24,
        error: 'HTTP 500',
      ),
    );
    expect(find.byKey(const ValueKey('about-error')), findsOneWidget);
    expect(find.textContaining('HTTP 500'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
  });
}
