# UI/UX Polish Pass — Status & Resume Note

Branch: `feat/parity-theme-match`. Owner reviewed the app on his phone and
flagged a batch of repeating UI patterns to fix **systematically** (shared
components + theme first, then sweep every screen). This note tracks the batch
so a fresh session can continue precisely.

Standing rules: tested (`flutter analyze` clean + suite + overflow sweep green),
no design breakage, RTL, web-style density, no fake/stubbed data.

## STRUCTURE ALIGNMENT — DONE (branch `feat/parity-structure`, off `f7c6985`)
The owner's governing requirement (1:1 web-mirror nav) is complete:
- `docs/STRUCTURE_MAP.md` — web `_sidebar.html` (radius-module@5616346) vs the
  Flutter nav, every mismatch + route map + gaps. (commit `3563c48`)
- `navigation_schema.dart` rebuilt to the web's 11 groups in order with web
  Arabic labels + page placement; `test/nav_structure_test.dart` locks it.
  (commit `e191bc4`) — `flutter analyze` clean, 362 tests pass.

## UI POLISH — COMPLETE (on `feat/parity-structure`)
All client-side polish items are done. Order executed: item 3 (cards→card
view, commit `eb6e139`) → items 2/9/11 (density: shell content centering +
`AppTokens.contentMaxWidth` + denser `PageHeader`, commit `a6318a8`) → item 4
(designer live preview) + item 5 (split print-templates into «تصميم»/«طباعة»)
both in commit `d826f08`. Item 10 stays BLOCKED (API-first, see below).
`flutter analyze` clean; 362 tests pass; overflow sweep green (72 screens).

## DONE (committed)

- **Reverse-sync** (commit `b98262a`) — network-policy merged into the router
  dashboard, remote-access kind removed. (Prior task, not part of this batch.)

- **Item 1 — time/date picker rendered black (CRITICAL):** FIXED at theme level.
  - Root cause: `themeMode` defaulted to `ThemeMode.system`; on a phone in OS
    dark mode the half-migrated `AppTheme.dark()` rendered dark-on-dark. No
    user-facing theme toggle exists.
  - `lib/app.dart`: forced `ThemeMode.light` (light-only by spec).
  - `lib/core/theme/app_theme.dart`: added explicit `TimePickerThemeData` +
    `DatePickerThemeData` (branded, high-contrast) so pickers are always
    readable. Commit `5c481f5`.

- **Item 6 — invisible switch labels** and **Item 7 — oversized/haphazard
  switches:** FIXED. Same dark-mode root cause (labels were dark-on-dark);
  forcing light resolves it. Plus a component-level fix so it can't recur:
  - NEW `lib/shared/widgets/hub_switch_row.dart` (`HubSwitchRow`) — the
    canonical aligned **label + compact switch** row (visible label, optional
    subtitle, taps anywhere). Built on the existing compact `HubToggleSwitch`.
  - Refactored `router_alerts_screen.dart` (the «الإعدادات العامة» screen):
    replaced the `FilterChip`-as-toggle `Wrap` (the “big purple pills, no
    text”) with `HubSwitchRow` rows. Commit `5c481f5`.

- **Item 8 — Android BACK button exits the app (HIGH):** FIXED centrally.
  - Root cause: the app navigates only with go_router `go`/`goNamed` (zero
    `push`), so there was no back stack.
  - NEW `lib/core/router/nav_history.dart` (`NavHistory` + provider) — records
    visited locations, trims forward trail on back.
  - `shell_scaffold.dart`: records each location and wraps the shell in a
    `PopScope` — pop nested route → else walk nav-history → else go home tab →
    else double-back-to-exit. `test/nav_history_test.dart` covers it.
    Commit `dd32c41`.

## BLOCKED — API-first (do NOT stub)

- **Item 10 — «ما يحتاج انتباه» filter not applied:** the dashboard ALREADY
  sends `?attention=…` (`dashboard_screen.dart:409-413`) and
  `subscribers_list_screen.dart` ignores it. BUT the JSON API
  `/api/v1/accounts` (`accounts_list` in web `app/api/v1/accounts.py:236`) only
  supports `status`/`search`/`plan_id` — **no `attention` param** (the web
  computes `expired`/`expiring_3d` only on its HTML `users.py:602` route), and
  the Flutter `Subscriber` model carries no expiry-window flag, so it cannot be
  filtered client-side faithfully. → **API-first**: needs `attention` added to
  `/api/v1/accounts`. Once it exists: read the query param in
  `subscribers_list_screen.dart`, thread it through `subscribersListProvider`
  → `SubscribersRepository.list(attention:)`, and render a clearable filter
  chip.

## DONE — client-side polish (this batch)

- **Items 2 / 9 / 11 — density / wasted space / “scattered” layout (GLOBAL):**
  DONE (commit `a6318a8`). Added `AppTokens.contentMaxWidth = 1180`; shell
  `_ContentArea` now centers content (`Align.topCenter` + `ConstrainedBox`)
  instead of left-aligning at 1280; `PageHeader` titles dropped a step
  (`titleLarge`/compact `titleMedium`, was `headlineSmall`/`titleLarge`) for
  denser web-like headers across every screen. Goldens regenerated; sweep green.

- **Item 3 — card packages (حزم البطاقات) as CARD view, not table:**
  DONE (commit `eb6e139`). `cards_batches_table.dart` rewritten from a wide
  `DataTable` to a responsive `LayoutBuilder` + `Wrap` of `_BatchCard`s (1 col
  <1100px, 2 cols ≥1100); selection via `selectedBatchIdsProvider`, all actions
  preserved. Outer redundant `AppCard` wrapper removed from the list screen.

- **Item 4 — template designer live preview:** DONE (commit `d826f08`).
  NEW `widgets/template_live_preview.dart` (`TemplateLivePreview`) renders the
  real card SVG engine (`buildCardRenderModel` → `CardSvgView`, same renderer
  the export PDF uses) and rebuilds on every designer field change. Wired into
  the design section beside the editor.

- **Item 5 — split template page into «تصميم» (design) vs «طباعة» (print):**
  DONE (commit `d826f08`). `print_templates_screen.dart` split via a
  `SegmentedButton`: «تصميم» = editor (form + designer) + live preview;
  «طباعة» = saved-template list + desktop export room → preview/export PDF.

## Shared components/rules established (reuse these)
- `HubSwitchRow` — labelled toggle row (use for ALL switches; sweep the other
  ~23 files still using raw `SwitchListTile`/`Switch`/`FilterChip`).
- `HubToggleSwitch` — compact bare switch (already existed).
- `NavHistory` / shell `PopScope` — back-button policy.
- Picker themes live in `app_theme.dart` light().
- App is forced light (`ThemeMode.light` in `app.dart`); dark theme is parked.
