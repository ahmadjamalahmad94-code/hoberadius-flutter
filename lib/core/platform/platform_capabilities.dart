import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

/// Single source of truth for "what does this build of the app
/// support?" — every desktop-only feature checks one of these
/// constants before importing the heavy plugin. The mobile build
/// short-circuits, the import is never reached, and the APK never
/// gains a desktop-only dependency at runtime.
///
/// Used by:
///   * `PdfPreviewLauncher` — only imports `printing` on Windows.
///   * `BackgroundImageDropTarget` — only imports `desktop_drop`
///     when `isDesktop` is true.
///   * `print_templates_screen` — only renders the 3-column
///     export-room layout when `isDesktop && !isMobile`.
class PlatformCapabilities {
  PlatformCapabilities._();

  /// True when the host is a desktop OS (Windows / macOS / Linux)
  /// AND we are NOT on web — web is a separate code path that
  /// handles file pickers natively.
  static bool get isDesktop {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  /// True specifically on Windows. Some helpers (`desktop_multi_window`,
  /// `printing` print-dialog) are Windows-only inside this project.
  static bool get isWindows {
    if (kIsWeb) return false;
    return Platform.isWindows;
  }

  /// True when running on a phone/tablet form-factor build (Android
  /// or iOS). The mobile safety rules in
  /// `docs/MOBILE_BASELINE.md` apply when this is true.
  static bool get isMobile {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  /// True on web. Some flows (file download, PDF preview) take a
  /// browser-specific path that neither mobile nor desktop reaches.
  static bool get isWeb => kIsWeb;

  /// True when an embedded PDF preview window is supported. Today
  /// that's Windows only — mobile uses the existing file_saver
  /// "download to disk" flow, web uses an `<iframe>`.
  static bool get supportsEmbeddedPdfPreview => isWindows;

  /// True when drag-and-drop onto designer surfaces is supported.
  /// Desktop OS only — mobile keeps the standard tap-to-pick UX.
  static bool get supportsDragDrop => isDesktop;

  /// True when the multi-column desktop layout (3-column export
  /// room) should render. Falls back to the single-column mobile
  /// layout on phones / tablets / web at narrow widths.
  static bool get supportsDesktopLayout =>
      isDesktop ||
      // Web at desktop widths also takes this path. The caller
      // additionally checks MediaQuery width via AppTokens.bpDesktop.
      isWeb;

  /// Human-readable label for diagnostic surfaces (e.g. About panel,
  /// crash reports).
  static String describe() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      default:
        return 'unknown';
    }
  }
}
