import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hoberadius_app/core/theme/app_theme.dart';
import 'package:hoberadius_app/shared/widgets/hub_layout.dart';
import 'package:hoberadius_app/shared/widgets/status_pill.dart';

/// Owner report: every new button showed a different font. The action bar
/// set a raw TextStyle on its buttons, which replaced the theme's text style
/// and dropped the app font (Cairo). Pin that the buttons render with the
/// theme's font family.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  String? renderedFamily(WidgetTester tester, String label) {
    final rich = tester.widget<RichText>(
      find.descendant(of: find.text(label), matching: find.byType(RichText)),
    );
    return rich.text.style?.fontFamily;
  }

  testWidgets('action bar buttons keep the app font', (tester) async {
    final theme = AppTheme.light();
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: ActionBar(
            items: [
              ActionItem(
                icon: Icons.add,
                label: 'أساسي',
                primary: true,
                onPressed: () {},
              ),
              ActionItem(icon: Icons.tune, label: 'ثانوي', onPressed: () {}),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    // google_fonts may log a missing-asset error in tests; the style still
    // carries the family name, which is what we assert.
    tester.takeException();

    final expected = theme.textTheme.labelLarge?.fontFamily;
    expect(expected, isNotNull);
    expect(expected, contains('Cairo'));
    expect(renderedFamily(tester, 'أساسي'), expected);
    expect(renderedFamily(tester, 'ثانوي'), expected);
  });
  testWidgets('count grid, info grid and status pill keep the app font',
      (tester) async {
    final theme = AppTheme.light();
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Scaffold(
          body: Column(
            children: [
              CountGrid(items: [CountItem('متاح', 7, tone: PillTone.blue)]),
              InfoGrid(
                items: [
                  InfoItem(icon: Icons.timer, label: 'المدة', value: '٥ دقائق'),
                ],
              ),
              StatusPill(text: 'مفعّل', tone: PillTone.green),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    tester.takeException();
    final expected = theme.textTheme.bodyMedium?.fontFamily;
    expect(expected, contains('Cairo'));
    for (final label in ['متاح', '7', 'المدة', '٥ دقائق', 'مفعّل']) {
      final rich = tester.widget<RichText>(
        find.descendant(of: find.text(label), matching: find.byType(RichText)),
      );
      expect(rich.text.style?.fontFamily, expected, reason: label);
    }
  });
}
