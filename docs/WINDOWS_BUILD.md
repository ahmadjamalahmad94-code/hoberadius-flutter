# Windows Build Guide

Quick onboarding for running the HobeRadius admin on Windows after
the J8 parity work.

## Prerequisites

1. Flutter SDK ≥ 3.19 with `flutter doctor` clean for the Windows
   target (Visual Studio C++ build tools installed).
2. Windows 10 (≥ 1809) / Windows 11 with **Developer Mode**
   enabled — required because some Flutter plugins use symlinks.
3. Project bootstrapped: `flutter pub get` from project root.

## Run

```powershell
flutter run -d windows --dart-define=API_BASE_URL=https://radius.your-vps.com
```

Use `http://localhost:5000` instead while developing against a
local radius-module Flask backend.

## Build a release

```powershell
flutter build windows --release --dart-define=API_BASE_URL=https://radius.your-vps.com
```

The unpacked release sits under `build\windows\x64\runner\Release\`.
The print-templates feature pulls Almarai TTFs from the bundled
`data\flutter_assets\assets\fonts\` directory — confirm both
files exist after the build.

## What's different from mobile

| Surface | Mobile | Windows |
|---------|--------|---------|
| Print-templates page | Single-column form + list | 3-column export room (settings · live SVG preview · template chips) + form below |
| PDF export | `file_saver` download | `printing.PdfPreview` window with save/share/print actions |
| Background image picker | Tap to pick | Drag-drop OR tap to pick (with thumbnail + size + clear) |
| Live preview | (none on the existing single-column screen) | Inline SVG via `flutter_svg`, locked aspect-ratio, fit-to-viewport sizing |
| Keyboard shortcuts | (none) | Ctrl+P export, Ctrl+Shift+X cleanup, Esc close |

All of these sit behind `PlatformCapabilities.isWindows` /
`supportsDesktopLayout` guards in
`lib/core/platform/platform_capabilities.dart` — the Android / iOS
builds never import the desktop-specific plugins.

## Tests to run locally

```powershell
flutter analyze
flutter test                                   # full suite
flutter test test/parity/                      # parity + mobile-safety
flutter test test/card_renderer_svg_test.dart  # renderer invariants
```

Optional (requires the radius-module backend running):

```bash
# bash on WSL or git-bash
BASE=http://localhost:5555 ADMIN_USER=admin ADMIN_PASS=admin \
  ./tools/diff_web_admin.sh
flutter test test/parity/web_contract_test.dart
```

## Where to look in the code

- Render engine (Dart, shared with the SVG preview):
  `lib/features/print_templates/domain/card_render_model.dart`
  `lib/features/print_templates/domain/card_render_model_builder.dart`
  `lib/features/print_templates/data/card_renderer_svg.dart`
- Desktop screen pieces:
  `lib/features/print_templates/presentation/desktop/`
- PDF preview launcher:
  `lib/features/print_templates/presentation/widgets/pdf_preview_launcher.dart`
- Strict bg-image picker:
  `lib/features/print_templates/presentation/widgets/bg_image_picker.dart`
- Web reference (the source of truth for renderer behaviour):
  `radius-module/app/radius/services/card_renderer.py`

## Common pitfalls

- **APK size jumped after a Windows-parity commit** — open
  `docs/MOBILE_BASELINE.md`, run `tools/freeze_mobile_baseline.sh`,
  diff `docs/mobile_assets.txt`. Likely cause: a new asset under
  `assets/` not declared properly in pubspec.yaml leaked into the
  Android variant.
- **`flutter run -d windows` complains about plugin symlinks** —
  enable Developer Mode (Settings → System → For developers).
- **Arabic text renders as boxes in the PDF preview** — confirm the
  backend (`radius-module`) ships `app/static/fonts/Almarai-*.ttf`.
  The PDF is generated server-side; the Flutter app only displays it.
- **Designer canvas clips on portrait** — confirm
  `lib/features/print_templates/presentation/desktop/preview_column.dart`
  is still using the `_PreviewViewport` fit-to-viewport math from
  the web's P5 commit. The card should always sit centered with
  letterboxing on the long axis.
