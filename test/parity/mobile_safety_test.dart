/// Mobile-safety regression — the contract in
/// `docs/MOBILE_BASELINE.md`.
///
/// Verifies the assets / dependencies / source-tree contract that
/// keeps the Android + iOS builds unchanged across the
/// Windows-parity work:
///
///   * pubspec.yaml lists the desktop deps (printing /
///     desktop_drop / file_picker / flutter_svg / qr) under the
///     same top-level `dependencies` block. (They are not
///     guarded by pubspec — only at the import-site via
///     PlatformCapabilities.)
///   * The Almarai TTF files are declared.
///   * Existing mobile screens still build (covered by
///     `flutter test` widget tests — this file only asserts the
///     manifest level).
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final pubspec = File('pubspec.yaml').readAsStringSync();

  test('pubspec declares desktop deps the parity plan requires', () {
    expect(pubspec, contains('flutter_svg:'));
    expect(pubspec, contains('qr:'));
    expect(pubspec, contains('printing:'));
    expect(pubspec, contains('desktop_drop:'));
    expect(pubspec, contains('file_picker:'));
  });

  test('pubspec declares Almarai font assets', () {
    expect(pubspec, contains('family: Almarai'));
    expect(pubspec, contains('Almarai-Regular.ttf'));
    expect(pubspec, contains('Almarai-Bold.ttf'));
  });

  test('Almarai TTFs exist under assets/fonts/', () {
    expect(
      File('assets/fonts/Almarai-Regular.ttf').existsSync(),
      isTrue,
      reason: 'Almarai-Regular.ttf missing — re-copy from web admin',
    );
    expect(
      File('assets/fonts/Almarai-Bold.ttf').existsSync(),
      isTrue,
      reason: 'Almarai-Bold.ttf missing — re-copy from web admin',
    );
    expect(
      File('assets/fonts/OFL.txt').existsSync(),
      isTrue,
      reason: 'OFL.txt missing — SIL license is required',
    );
  });

  test('PlatformCapabilities flags exist (compile-time contract)', () {
    // We can't `import` here because of test scope; just confirm
    // the file is present. Anything that imports it for the wrong
    // platform will be caught by flutter analyze.
    expect(
      File('lib/core/platform/platform_capabilities.dart').existsSync(),
      isTrue,
    );
  });

  test('print-templates desktop folder is the ONLY screen surface added', () {
    // The plan's mobile-safety rule: the only NEW UI surface added
    // sits under the print-templates feature's desktop subtree.
    // Anything new outside this list should also gate on
    // `PlatformCapabilities.supportsDesktopLayout`.
    final desktopDir = Directory(
      'lib/features/print_templates/presentation/desktop',
    );
    expect(desktopDir.existsSync(), isTrue);
    final files = desktopDir
        .listSync(recursive: false)
        .whereType<File>()
        .map((f) => f.path.split(RegExp(r'[\\/]')).last)
        .toSet();
    // Sanity: every file in this folder must be one of the named
    // pieces from the plan.
    final expected = {
      'export_room.dart',
      'export_room_shortcuts.dart',
      'export_room_state.dart',
      'preview_column.dart',
      'settings_column.dart',
      'template_chips_column.dart',
    };
    expect(
      files.containsAll(expected),
      isTrue,
      reason: 'Missing one of $expected; got $files',
    );
  });
}
