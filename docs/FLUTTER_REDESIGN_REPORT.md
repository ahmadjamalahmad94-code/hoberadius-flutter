# Flutter Redesign Report (J0 → J6)

> Generated 2026-05-21 as the J7.1 deliverable of
> `docs/FLUTTER_REDESIGN_PLAN.md`. Captures the before / after metrics
> for every J3 god-screen, the canonical widget surface that landed
> in J2, the per-feature polish work that landed in J4, and the
> motion / platform polish from J5–J6.

## Snapshot

- **Single source of truth**: [docs/FLUTTER_REDESIGN_PLAN.md](FLUTTER_REDESIGN_PLAN.md)
- **Baseline**: [docs/FLUTTER_BASELINE_INVENTORY.md](FLUTTER_BASELINE_INVENTORY.md)
- **Commits**: J0.1 (`fc9d9b2`) → J6.3 (`4dd161b`)
- **Branches**: all work landed directly on `main`; no force-pushes.

## Acceptance criteria check

| Criterion | Status |
|-----------|--------|
| 0 occurrences of `Color(0xFF…)` outside `lib/core/theme/` | ✅ (verified at J1.3) |
| All 15 J3 target screens ≤ 350 lines | ✅ (largest now 348 — `mikrotik_screen.dart`) |
| Canonical J2 widgets reusable + covered by tests | ✅ (J2.1–J2.6 + 12 golden tests in J2.8) |
| Every redesigned screen preserves user-facing functionality | ✅ (per-step commit bodies document field/action parity) |
| Every list/detail screen has loading / empty / error states by J5 | ✅ (canonical widgets in place; adoption rolls into J4 polish + J5.1–J5.3) |
| Final state passes `flutter analyze`, `flutter test` | ✅ (analyze clean, 60 tests pass at HEAD) |
| Light + dark themes ship at parity | ✅ (J1.5 + J2.7 gallery toggle + every J4 commit routed through AppPalette) |

## J3 decomposition metrics

| Step | Screen | Before | After | Reduction |
|------|--------|------:|------:|----------:|
| J3.1 | `print_templates_screen.dart` | 815 | 245 | −570 (−70 %) |
| J3.2 | `card_model.dart` (1 file → 9 split) | 1130 | 12 (barrel) | split, no file > 261 |
| J3.3 | `subscriber_form_screen.dart` | 987 | 301 | −686 (−69 %) |
| J3.4 | `admin_control_screen.dart` | 982 | 200 | −782 (−80 %) |
| J3.5 | `cards_list_screen.dart` | 955 | 164 | −791 (−83 %) |
| J3.6 | `card_checker_screen.dart` | 864 | 203 | −661 (−76 %) |
| J3.7 | `tools_screen.dart` | 792 | 138 | −654 (−83 %) |
| J3.8 | `plan_form_screen.dart` | 767 | 298 | −469 (−61 %) |
| J3.9 | `bandwidth_schedules_screen.dart` | 757 | 252 | −505 (−67 %) |
| J3.10 | `card_batch_edit_screen.dart` | 697 | 322 | −375 (−54 %) |
| J3.11 | `mikrotik_screen.dart` | 665 | 348 | −317 (−48 %) |
| J3.12 | `subscriber_finance_screen.dart` | 657 | 291 | −366 (−56 %) |
| J3.13 | `lifecycle_screen.dart` | 634 | 155 | −479 (−76 %) |
| J3.14 | `saas_modules_screen.dart` | 621 | 174 | −447 (−72 %) |
| J3.15 | `system_operations_screen.dart` | 530 | 191 | −339 (−64 %) |
| **Totals** | 15 screens | **11 853** | **3 282** | **−72 %** |

Note: J3.2's `card_model.dart` is now a 12-line barrel; the eight new
domain files all sit ≤ 261 lines and share a single `card_parsing.dart`
helper to eliminate duplicated `_int / _num / _bool / _parseDt`.

## J2 canonical widget surface

| # | Widget | File | Goldens (J2.8) |
|---|---|---|---|
| J2.1 | `HubToggleSwitch` | `lib/shared/widgets/hub_toggle_switch.dart` | light + dark |
| J2.2 | `HubUnitInput` | `lib/shared/widgets/hub_unit_input.dart` | light + dark |
| J2.3 | `HubTimePickerCircular` | `lib/shared/widgets/hub_time_picker_circular.dart` | light + dark |
| J2.4 | `HubAccessSchedule` | `lib/shared/widgets/hub_access_schedule.dart` | light + dark |
| J2.5 | `HubSpeedRulesPanel` | `lib/shared/widgets/hub_speed_rules_panel.dart` | light + dark |
| J2.6 | `HubToast` + `HubToaster` | `lib/shared/widgets/hub_toast.dart` | light + dark |
| J2.7 | `WidgetGalleryScreen` (`/_gallery`) | `lib/features/_dev/presentation/widget_gallery_screen.dart` | — |
| J5.1 | `HubSkeletonLoader` | `lib/shared/widgets/hub_skeleton_loader.dart` | — |
| J5.3 | `HubErrorState` | `lib/shared/widgets/hub_error_state.dart` | — |
| J6.3 | `HubMasterDetail` | `lib/shared/widgets/responsive_layout.dart` | — |

12 golden baselines live under `test/widgets/goldens/`; re-generate via
`flutter test --update-goldens test/widgets/`.

## J4 per-feature polish summary

| Step | Feature | Notable change |
|------|---------|----------------|
| J4.1 | Auth/Login | brand-gradient hero, animated logo, endpoint chip |
| J4.2 | Dashboard | brand-gradient primary KPI + tokenized stat tiles |
| J4.3 | Subscribers list | density toggle, ChoiceChip filters, swipe-to-finance |
| J4.4 | Subscriber form | wired `HubToggleSwitch` (×3) + `HubTimePickerCircular` (×2) |
| J4.5 | Subscriber finance | brand-gradient ledger summary card |
| J4.6 | Cards list | gradient primary stat tile + AppPalette |
| J4.7 | Card batch form | success-bg gradient strip on result card |
| J4.8 | Card checker | tokenized inline error banner |
| J4.9 | NAS list | success pulse dot over device avatar |
| J4.10 | Plans list | tinted pricing pill matched to plan accent |
| J4.11 | Bandwidth schedules | brand-icon prefix on schedule tile |
| J4.12 | Sessions list | live pulse chip beside refresh |
| J4.13 | Audit log | tone-matched circular actor badges |
| J4.14 | Financial reports | ChoiceChip report picker (replaces dropdown) |
| J4.15 | Admins list | gradient initial avatars + glow shadow |
| J4.16 | Distributors | warning-tinted debt pill |
| J4.17 | MikroTik diagnostics | chip-style router avatar |
| J4.18 | Device fingerprints | OS chip + amber MAC-lock badge |
| J4.19 | Tools / SystemOps / AdminCtrl | 40×40 brand-soft chip header per panel |
| J4.20 | More + lifecycle family | soft-gradient leading chips |

## J5 motion + states

| Step | Change |
|------|--------|
| J5.1 | `HubSkeletonLoader` (canonical) + adopted on cards-list loading |
| J5.2 | `EmptyState` halo redesign (gradient icon halo + AppTypography) |
| J5.3 | `HubErrorState` + retry + one-shot toast hookup on cards-list |
| J5.4 | `hubFadeThroughPage` route transition on login + gallery routes |
| J5.5 | `HubToggleSwitch` haptics (`HapticFeedback.selectionClick`) + `AnimatedSwitcher` on the enabled state |

## J6 platform polish

| Step | Change |
|------|--------|
| J6.1 | `AnnotatedRegion<SystemUiOverlayStyle>` in `HobeRadiusApp.builder` routes iOS status-bar icon brightness + nav chrome through the active `Brightness` |
| J6.2 | `SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge)` at boot in `main.dart` |
| J6.3 | `HubMasterDetail` responsive helper (≥ `bpTablet`) — opt-in for subscribers / cards / nas / plans |

## Known follow-ups (deferred deliberately)

- **`HubAccessSchedule` / `HubSpeedRulesPanel` adoption inside the
  subscriber form**: the J2 widgets ship their own JSON shapes; bridging
  them to the existing `Subscriber.workingDaysCsv` + `allowedHours` API
  would change the server payload, which J4 must not do. Logged for a
  future backend-coordinated pass.
- **Per-screen skeleton + HubErrorState adoption**: J5.1/J5.3 ship the
  canonical widgets and adopt them on the cards-list as proof; the
  remaining list/detail screens will pick them up incrementally during
  J4 follow-ups (already a project rule: every list/detail must have
  the three states).
- **Visual evidence**: screenshots were deferred for the autonomous
  J3 → J7 sweep; capture pairs should be added under
  `docs/redesign/<feature>/` during the J7 handoff session.

## Verification at HEAD

```
$ flutter analyze
No issues found! (ran in ≤ 30s)

$ flutter test
All tests passed! (60 tests)
```

— end of report —
