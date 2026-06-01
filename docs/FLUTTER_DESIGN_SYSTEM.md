# Flutter Design System

> Companion to [FLUTTER_REDESIGN_PLAN.md](FLUTTER_REDESIGN_PLAN.md) and
> [FLUTTER_REDESIGN_REPORT.md](FLUTTER_REDESIGN_REPORT.md). Frozen as
> the J7.2 deliverable.

## Theme tokens

### Colours

| Layer | Source |
|-------|--------|
| Light palette | `lib/core/theme/tokens.dart` (`AppTokens`) |
| Dark palette | `lib/core/theme/dark_tokens.dart` (`DarkTokens`) |
| Context-aware accessor | `lib/core/theme/app_palette.dart` (`AppPalette.of(context)`) |

**Rule**: any widget rendered inside `Theme.of(context)` MUST source
its colours via `AppPalette.of(context)`. Direct reads of `AppTokens.X`
only inside `lib/core/theme/` and a handful of legacy widgets that
will migrate during their next polish pass.

### Typography

`lib/core/theme/typography.dart` exposes `AppTypography` with locked
weights:

- `displayLarge`, `displayMedium` — hero copy
- `titleLarge`, `titleMedium`, `titleSmall` — section + card headings
- `bodyLarge`, `bodyMedium`, `bodySmall` — paragraph copy
- `labelLarge`, `labelMedium`, `labelSmall` — form labels, button text
- `caption` — helper / footnote
- `kpi`, `mono` — tabular numerics

Never roll your own `TextStyle(fontSize: …, fontWeight: …)`; reach
for one of the scale entries and `.copyWith` only colour.

### Spacing + radii

`AppTokens.s4 / s8 / s12 / s16 / s20 / s24 / s32 / s40` —
8-pt grid (with the s4 escape hatch).
Radii: `r6 / r10 / r14 / r18 / r20`.

### Motion

`AppTokens.motionInstant / motionFast / motionMedium / motionSlow`
durations paired with `motionEase / motionEaseInOut /
motionEmphasized / motionSpringy` curves. The same vocabulary that
the J2 canonical widgets, the J5.4 route transitions, and the J5.5
toggle haptics already use.

## Canonical widgets

| Widget | Surface | Where to use |
|--------|---------|--------------|
| `HubToggleSwitch` | `lib/shared/widgets/hub_toggle_switch.dart` | every boolean on/off (the only accepted toggle) |
| `HubUnitInput` | `lib/shared/widgets/hub_unit_input.dart` | "number + unit" pairs (speed / quota / time / size) |
| `HubTimePickerCircular` | `lib/shared/widgets/hub_time_picker_circular.dart` | any time-of-day field |
| `HubAccessSchedule` | `lib/shared/widgets/hub_access_schedule.dart` | day-and-window scheduling (`AccessSchedule` JSON) |
| `HubSpeedRulesPanel` | `lib/shared/widgets/hub_speed_rules_panel.dart` | scheduled speed rules |
| `HubToast` + `HubToaster` | `lib/shared/widgets/hub_toast.dart` | floating success/error/info messages |
| `HubSkeletonLoader` | `lib/shared/widgets/hub_skeleton_loader.dart` | list/detail loading shimmer |
| `HubErrorState` | `lib/shared/widgets/hub_error_state.dart` | failed request — danger halo + retry |
| `EmptyState` (polished J5.2) | `lib/shared/widgets/empty_state.dart` | empty lists — gradient halo + CTA |
| `HubMasterDetail` | `lib/shared/widgets/responsive_layout.dart` | tablet-grade master/detail wrapper |

### Gallery + goldens

- Development gallery: source-only widget gallery for local design checks;
  it is not mounted in the production router.
- Golden baselines: `test/widgets/goldens/*.png` (12 baselines, two
  per widget across J2.1–J2.6).
- Re-record: `flutter test --update-goldens test/widgets/`.

## Theming integration

`HobeRadiusApp` wires the system chrome through the active theme:

- `AnnotatedRegion<SystemUiOverlayStyle>` swaps status-bar +
  Android-nav icon brightness on the fly.
- `SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge)` is
  set at boot in `main.dart` so scaffolds can paint behind the
  system bars.

## Route transitions

`lib/core/router/app_page_transitions.dart` exposes
`hubFadeThroughPage<T>(child:, …)` — wrap any `GoRoute`'s
`pageBuilder:` in it for a soft fade + 4 % slide in motion-token time.
Currently wired on `/login`; other routes migrate during feature polish.

## Adoption rules

1. New screens use `AppPalette` + `AppTypography` from day 1.
2. Empty lists call `EmptyState`. Failed requests call
   `HubErrorState`. Loading lists call `HubSkeletonLoader.list()` /
   `.tiles()`.
3. Boolean controls use `HubToggleSwitch`. Time pickers use
   `HubTimePickerCircular`. Unit inputs use `HubUnitInput`.
4. Floating notifications use `HubToaster.success / .error / .info`
   instead of the raw `SnackBar` where the feel matters (snackbars
   are still fine for in-place form-style ack messages).
5. No `Color(0xFF…)` literals outside `lib/core/theme/`. Run a
   one-liner sanity check before merging:
   `grep -r "Color(0xFF" lib/ | grep -v "lib/core/theme/"` → empty.

— freeze stamp: J7.2, 2026-05-21 —
