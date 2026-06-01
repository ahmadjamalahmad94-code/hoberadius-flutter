# Flutter Windows ⇄ Web Parity Plan

> Goal: bring the **Windows build of the Flutter admin** to 100 % visual
> and behavioural parity with the web admin at its current HEAD, with the
> exact styles, the unified card renderer, the print-templates redesign
> and every visual fix that landed in the most recent web session —
> **without touching the mobile (Android / iOS) build**.

The web reference is `radius-module/` at the commits between
`59067d5` (Sept 2025 print-templates baseline) and `9300cef` (the
"fit-to-viewport" designer canvas).

## Why a separate plan from `FLUTTER_REDESIGN_PLAN.md`

That earlier plan (J0 → J7) finished at `f33bad1` and froze the Flutter
codebase at "matches the web admin as it was at J0 baseline". Since then
the web admin gained:

- Unified card render engine (model + SVG + ReportLab adapters).
- Print-templates 3-column page (designer + export + chips + live preview).
- Default-template + favorites + bulk-delete test fixtures.
- Strict background-image picker (drag/drop, validation, thumb).
- Card preview "fit-to-viewport" layout.
- Arabic PDF via Almarai TTF + reshape + bidi.
- RTL-safe SVG (direction="ltr" pinning).
- QR white-panel tightening, system health dashboard, ...

None of that is in Flutter yet. This plan covers the gap.

## North-star acceptance criteria

A reviewer must be able to open `/admin/radius/print-templates` in
Chrome AND the same screen in the Flutter Windows build, screenshot both,
overlay them at the same DPI, and find no perceptible difference:

- Same 3-column export layout.
- Same locked card preview (same fonts, same percentages, same QR shape).
- Same designer drawer with the same form fields and the same strict
  bg-image picker.
- Same template-chip list, same default-star UI, same cleanup button,
  same "تنظيف القوالب التجريبية" copy.
- Same Arabic-aware PDF on both — exported from Windows must be byte-
  comparable (modulo timestamp) to one exported from the web.

Mobile (Android / iOS) builds:
- `flutter analyze` clean on every commit.
- `flutter test` clean on every commit.
- No mobile-specific screen changes other than what the
  responsive widgets (`HubMasterDetail`) already do.
- Mobile build still produces the same APK/IPA structure.

---

## Phase A — Inventory + Safety Net (≈ 0.5 day)

The first thing tomorrow is to make sure we can detect ANY regression
on mobile before it ships. Then we lay the parity baseline.

### A1. Capture mobile golden screenshots
- Generate golden baselines for every existing screen at the
  `bpPhone` and `bpTablet` widths using `golden_toolkit`. New
  goldens go under `test/screens/goldens/`.
- Build the mobile APK once (`flutter build apk --release`) and
  store size + asset graph in `docs/MOBILE_BASELINE.md`.
- Commit: `A1: freeze mobile golden screenshots`.

### A2. Diff the web's print-templates HTTP surface
- Hit each web endpoint with `curl` from a script in
  `tools/diff_web_admin.sh`. Save the responses under
  `tools/web_snapshots/`. We will replay these snapshots in Dart
  contract tests later.
- Routes to snapshot:
    * `GET /admin/radius/print-templates`
    * `GET /admin/radius/print-templates/<id>/preview-fragment`
    * `GET /admin/radius/print-templates/<id>/export.pdf` (sample +
      batch)
    * `GET /admin/radius/print-templates/export` (redirect target)
- Commit: `A2: capture web reference snapshots for parity tests`.

### A3. Pin the dependency story
- Add to `pubspec.yaml` (Windows-targeted, no mobile impact):
    * `flutter_svg` — render the unified SVG inline in the preview.
    * `printing` — PDF preview window on Windows.
    * `pdfx` (or `syncfusion_flutter_pdfviewer`) — PDF viewer
      embedded inside the export screen.
    * `file_picker` — already present, double-check version.
    * `desktop_drop` — drag-drop background image on Windows.
- Use platform check (`Platform.isWindows`) to guard every desktop-
  only code path, so the mobile build never imports anything heavy.
- Commit: `A3: pin desktop dependencies behind Platform guards`.

---

## Phase B — Card Renderer Engine (≈ 1.5 days, 6 commits)

The web's `card_renderer.py` is the single source of truth. Mirror its
model into Dart. This is the biggest chunk because everything else
consumes it.

### B1. Port the render model into Dart
- New file `lib/features/print_templates/domain/card_render_model.dart`:
    * Constants `kCanvasLandscape = Size(1000, 600)`,
      `kCanvasPortrait = Size(600, 1000)`.
    * Immutable `CardRenderModel` with `canvas`, `orientation`,
      `background`, `elements`, `cardId`, `username`, `password`.
    * Element types as a sealed class: `CardRect`, `CardText`,
      `CardPill`, `CardQr` — one per `kind` in the Python model.
    * `_DEFAULT_POSITIONS` mirrored byte-for-byte.
- Pure Dart, no Flutter imports — same as the Python version.
- Commit: `B1: port card render model to Dart`.

### B2. Port the builder
- `buildCardRenderModel(template, card, {overrides})` in
  `lib/features/print_templates/domain/card_render_model_builder.dart`.
- Same field-name resolution (`layout_json` keys, legacy
  `username_x`/`y`, `password_x`/`y`, `qr_x`/`y` translation to
  canvas fractions).
- Same default-position fallback when `(0, 0)` is present.
- Same `_show_flags`, same override-key whitelist.
- Commit: `B2: builder + position resolver in Dart`.

### B3. SVG adapter
- `renderCardSvg(model, {maskPassword = true})` in
  `lib/features/print_templates/data/card_renderer_svg.dart`.
- Emit identical SVG markup to the Python adapter — same `viewBox`,
  same `direction="ltr"`, same `preserveAspectRatio`, same
  pattern overlay (signal / wave / grid / clean), same QR walk via
  a Dart QR matrix package (`qr_flutter` or `barcode` — local
  evaluation needed; QR matrix must match server output exactly).
- Display the SVG via `flutter_svg`'s `SvgPicture.string`.
- Commit: `B3: SVG adapter + flutter_svg display`.

### B4. PDF adapter (Windows-only)
- Wrap the existing backend PDF — i.e. **do not re-render the PDF
  locally**. Hit `GET /api/v1/print-templates/<id>/export.pdf` and
  display the response in the `printing` package's PDF viewer.
- This guarantees BIT-IDENTICAL output to the web export — the
  source of truth stays server-side.
- Commit: `B4: PDF preview window powered by backend export`.

### B5. Renderer parity tests
- Port `tests/test_card_renderer.py` invariants to Dart:
    * model contains user/pass/qr;
    * password masked in SVG;
    * internal ratios preserved across `cards_per_row`;
    * QR coords in canvas units;
    * bg image surfaces in SVG;
    * portrait vs landscape canvas dims;
    * SVG XML-escapes user text;
    * SVG root + every <text> carry `direction="ltr"`.
- Commit: `B5: regression suite for the Dart renderer`.

### B6. Golden snapshots
- Build a `WidgetGalleryScreen`-style screen under
  `lib/features/print_templates/presentation/_dev/card_renderer_gallery.dart`
  showing the SVG output of each preset (modern / dark / gold /
  minimal / telecom / neon / aurora / fiber / sunset / matrix).
- Capture a golden for each. These are the visual baseline the
  Windows UI must match — if anything regresses, the golden
  diff catches it.
- Commit: `B6: golden gallery of every preset`.

---

## Phase C — Print-Templates Experience (≈ 2 days, 8 commits)

Now build the user-facing screen on top of the renderer. One commit
per logical chunk so reviews stay focused.

### C1. Page scaffolding
- Rewrite `print_templates_screen.dart` to mirror the web's three
  regions:
    * Hero strip (title + 5 CTAs).
    * 3-column shell: settings · live preview · template chips.
    * Designer drawer (`<details>`-equivalent in Flutter:
      `ExpansionTile` styled as a drawer).
    * Templates table.
    * Jobs history table.
- On Windows ONLY use the 3-column layout; on mobile, the existing
  `HubMasterDetail` collapses it into the single-column form we
  already have. Platform guarded via `LayoutBuilder` + width
  breakpoint (`AppTokens.bpTablet`).
- Commit: `C1: print_templates_screen scaffold (Windows 3-column)`.

### C2. Settings column
- Batch selector dropdown (calls the existing
  `cardsService.listBatches()`).
- Override fields: hotspot, price, validity, footer (same names
  as web).
- Progress indicator widget (same 4 steps the web has).
- Export PDF + Sample PDF action buttons.
- Cleanup-fixtures button + confirmation dialog.
- Commit: `C2: settings column with overrides + progress`.

### C3. Live preview column
- Embeds the unified SVG via `SvgPicture.string`.
- Debounced rebuild when the selected template / batch / overrides
  change — same 180 ms timer the web uses.
- "تصميم مغلق" lock pill in the header.
- Commit: `C3: live preview column powered by the SVG adapter`.

### C4. Template chips column
- Scrollable list of template chips, each with a small swatch +
  meta + star button + "ملف PDF تجريبي" button.
- Click selects + triggers live preview rebuild.
- Default-template chip auto-selected on first paint.
- Commit: `C4: template chips with star + sample-pdf action`.

### C5. Star → default template
- Wire the star button to the existing
  `PATCH /api/v1/print-templates/<id>/set-default` endpoint
  (already added on the web side).
- Optimistic UI: flip the star locally, rollback on failure.
- Commit: `C5: star button → set-default round-trip`.

### C6. Bulk-delete test fixtures
- Cleanup button calls
  `POST /api/v1/print-templates/cleanup-fixtures`.
- Confirmation dialog with the exact Arabic copy from the web.
- Show count of purged rows in a toast (use existing `HubToaster`).
- Commit: `C6: cleanup-fixtures button + confirmation flow`.

### C7. Strict background-image picker
- Replace the current basic `FilePicker` flow with the equivalent
  of the web's `[data-bg-picker]`:
    * Trigger button with icon + dashed border.
    * Thumbnail + filename + human-readable size when chosen.
    * Clear button.
    * Inline Arabic error for wrong type / oversize.
    * Drag-drop support via `desktop_drop` on Windows.
- Same MIME whitelist + 1.5 MB cap as the server side.
- Commit: `C7: strict bg-image picker matching the web component`.

### C8. Designer drawer
- Expandable drawer below the export room.
- Contains the existing template form (already in
  `template_form.dart`), but every field default + position is
  now sourced from `_DEFAULT_POSITIONS` so newly created templates
  hit the renderer fallback exactly like on the web.
- Mm-position inputs default to `0` and JS-equivalent logic in
  Dart skips inline positioning when zero.
- Commit: `C8: designer drawer + default-position parity`.

---

## Phase D — Cross-Cutting Polish (≈ 1 day, 5 commits)

These are smaller but visible.

### D1. Arabic font in the app
- Ship the same Almarai TTF the web embeds (already in
  `app/static/fonts/`). Add to `assets/fonts/` and declare in
  `pubspec.yaml` with the same family name "Almarai".
- Wire `ThemeData.textTheme` to fall back to Almarai for Arabic
  glyphs. Latin stays on the existing Cairo / Inter default.
- Commit: `D1: Almarai TTF + theme fallback for Arabic`.

### D2. RTL-safe SVG
- Port the web's `direction="ltr"` defence to the SVG adapter —
  the Dart renderer must always emit it, and `flutter_svg` must
  honour it. Add a widget test that snapshots both directions.
- Commit: `D2: pin SVG text LTR even inside MaterialApp(rtl)`.

### D3. Card preview viewport (fit-to-screen)
- `CardPreviewViewport` widget that implements the same
  "contain-style" sizing the web CSS uses:
  `width = min(viewport_w, viewport_h * canvas_aspect)`.
- Used by C3 + C8 so the designer canvas + the live preview share
  one implementation.
- Commit: `D3: CardPreviewViewport with object-fit:contain semantics`.

### D4. PDF preview window
- Tap "ملف PDF تجريبي" or "تصدير PDF للحزمة" on Windows opens a
  separate flutter window (use `desktop_multi_window`) showing
  the PDF via `printing.PdfPreview`.
- Mobile keeps the existing "download to file system" flow —
  Platform-guarded so iOS / Android never imports
  `desktop_multi_window`.
- Commit: `D4: dedicated Windows PDF preview window`.

### D5. Keyboard shortcuts
- Windows-only: `Ctrl + S` saves the template, `Ctrl + P` opens
  PDF preview, `Esc` closes the designer drawer, `Ctrl + F`
  focuses the template-chip filter.
- Implemented via `Shortcuts` + `Actions` widgets; the same
  widgets render nothing on mobile (no shortcuts registered).
- Commit: `D5: Windows keyboard shortcuts`.

---

## Phase E — Verification + Mobile Regression Check (≈ 0.5 day)

### E1. Golden diff vs web screenshots
- For each of the 10 presets, capture the Flutter Windows
  screenshot at the same DPI as the web reference snapshot. Diff
  using `image` package + `ImageDiff`. Fail the build on > 1 %
  pixel delta in the card area.
- Commit: `E1: Windows-vs-web pixel diff CI test`.

### E2. Mobile regression check
- Re-run the A1 mobile goldens. Any difference at all → revert
  that commit and isolate the offending change behind a
  `Platform.isWindows` guard.
- Run `flutter build apk --release` and compare the APK size +
  asset graph against `docs/MOBILE_BASELINE.md`. Any unexpected
  asset (e.g. Almarai picked up by mobile) → restrict via
  pubspec.yaml `flavors` or asset patterns.
- Commit: `E2: mobile regression sweep — no APK delta`.

### E3. Backend contract tests
- Replay the A2 web snapshots against the Dart repositories. Any
  shape change in the backend response that breaks the Dart code
  is caught here, not at runtime.
- Commit: `E3: web snapshot contract tests`.

---

## Phase F — Documentation Refresh (≈ 0.5 day)

### F1. Update `FLUTTER_REDESIGN_REPORT.md`
- Add a "Phase J8 — Windows Parity" section with:
    * the new files,
    * the new dependencies,
    * the screenshots,
    * the mobile-safety guarantees.
- Commit: `F1: report Phase J8 (Windows parity)`.

### F2. Update `README.md`
- Add the new `flutter run -d windows` example with the same
  `--dart-define=API_BASE_URL=…` pattern the existing README uses.
- Document the new font assets and the `printing` /
  `desktop_drop` / `desktop_multi_window` dependencies as
  Windows-only.
- Commit: `F2: README update for Windows build`.

### F3. Update onboarding
- If `ONBOARDING.md` exists, mention the Windows path. Otherwise
  add a one-pager under `docs/WINDOWS_BUILD.md`.
- Commit: `F3: Windows onboarding doc`.

---

## Strict rules during execution

1. **No `git add .`** anywhere. Stage exact files only.
2. **One logical commit per step.** Naming `A1`, `B1`, `C1`, …
   matches this plan so the history reads like the plan.
3. **`flutter analyze` clean before each commit.** If it isn't,
   fix it in the same commit; never push warnings.
4. **`flutter test` clean before each commit.** New tests added
   in the same commit as the feature they cover.
5. **Every desktop-specific dependency MUST sit behind
   `Platform.isWindows`** (or `kIsWeb` where relevant). The mobile
   build must never import `printing` / `desktop_drop` /
   `desktop_multi_window`.
6. **Do not touch unrelated dirty files.** This plan only edits
   the print-templates feature + shared design tokens + docs.
7. **Preserve existing behaviour on every screen we don't list.**
   Subscribers, plans, NAS, admins, etc. stay untouched.
8. **Backend API must not change.** Anything missing on the server
   side gets a new web commit (separate session) BEFORE the Flutter
   side consumes it. No silent contract drift.
9. **Arabic copy** matches the web's exact strings. We import the
   same `messages_ar.arb` keys instead of re-typing strings.
10. **Never bypass hooks** (`--no-verify` / `--no-gpg-sign` / etc.).

## Order of operations tomorrow

1. **Morning** (≈ 3 hrs): Phase A → Phase B steps 1–3.
2. **Afternoon** (≈ 4 hrs): Phase B step 4 onwards + start
   Phase C (settings + preview column).
3. **Evening only if energy left**: continue Phase C.

If anything blocks you that needs a backend change, capture it in
`docs/PARITY_BLOCKERS.md` and pivot to the next non-blocked step.
The plan is designed so the renderer engine (B1–B5) can ship by
end-of-day-1 without ANY UI work — that already unlocks PDF /
preview parity on its own.

Sleep well. The plan is ready for you to execute step by step.
