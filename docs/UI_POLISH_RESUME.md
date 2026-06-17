# UI/UX Polish Pass — Status & Resume Note

Branch: `feat/parity-theme-match`. Owner reviewed the app on his phone and
flagged a batch of repeating UI patterns to fix **systematically** (shared
components + theme first, then sweep every screen). This note tracks the batch
so a fresh session can continue precisely.

Standing rules: tested (`flutter analyze` clean + suite + overflow sweep green),
no design breakage, RTL, web-style density, no fake/stubbed data.

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

## REMAINING (client-side, do next — biggest visible wins)

Do these as a shared-first pass, then re-run the overflow sweep across all 71
screens.

- **Items 2 / 9 / 11 — density / wasted space / “scattered” layout (GLOBAL):**
  the owner’s #1 theme. Approach:
  - Spacing tokens already exist (`AppTokens.s4…s40`). Define + apply a
    **max-content-width + centering** rule for wide screens and tighten the
    default content padding in the shell `_ContentArea`
    (`shell_scaffold.dart`, currently `EdgeInsets.all(s12)` on mobile) and in
    `PageHeader` / `AppCard`.
  - Kill large empty regions (e.g. speed-plan «معاينة التغيير») — screens that
    put a `Column` at the top of a tall scroll view; constrain/center content
    or use `Spacer`/`Center` so there’s no dead bottom region.
  - Shrink oversized helper/section labels (audit `titleLarge`/oversized
    `Text` in form section headers).
  - VERIFY each change against `test/screens/screen_overflow_sweep_test.dart`.

- **Item 3 — card packages (حزم البطاقات) as CARD view, not table:**
  `lib/features/cards/presentation/cards_list_screen.dart` renders a `_Table`.
  Convert to a responsive card/grid (mirror the subscribers/other card grids;
  use a `Wrap`/`GridView` of `AppCard`s). Keep sweep green.

- **Item 4 — template designer live preview:**
  `lib/features/print_templates/` — the SVG render engine exists
  (`data/card_renderer_svg.dart`). Wire a live preview widget into the designer
  so edits reflect on-screen.

- **Item 5 — split template page into «تصميم» (design) vs «طباعة» (print):**
  `print_templates_screen.dart` — reorganize into two tabs/sections: design
  (editor + live preview) and print (pick package + template → export PDF).

## Shared components/rules established (reuse these)
- `HubSwitchRow` — labelled toggle row (use for ALL switches; sweep the other
  ~23 files still using raw `SwitchListTile`/`Switch`/`FilterChip`).
- `HubToggleSwitch` — compact bare switch (already existed).
- `NavHistory` / shell `PopScope` — back-button policy.
- Picker themes live in `app_theme.dart` light().
- App is forced light (`ThemeMode.light` in `app.dart`); dark theme is parked.
