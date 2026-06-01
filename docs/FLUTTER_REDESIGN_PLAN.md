# Flutter App Redesign Plan (J0 → J7)

> Approved on 2026-05-21. Single source of truth for the entire
> redesign effort. Every commit during this work cites a step from
> this plan via its `J<phase>.<step>` prefix.

## Mission

Redesign the existing Flutter app (`hoberadius-flutter`) as a
**frontend-only** effort to match the web project's polished, premium
SaaS look and feel. Functionality and API contracts stay identical.

## Strict process rules (binding)

These rules apply to every commit in this plan:

1. Do not modify backend, API contracts, database schema, or business logic.
2. Do not delete or remove any existing feature.
3. Do not jump to visual redesign before completing foundation steps.
4. Never use `git add .` — stage only the exact files changed.
5. One small logical commit per task / step.
6. Push immediately after each successful commit.
7. Every commit message follows: `J<phase>.<step>: <imperative summary>`.
8. Before every commit, verify:
   - `flutter analyze` is clean (no warnings, no errors).
   - `flutter test` passes when tests exist or are affected.
   - `git diff --check` is clean.
   - `git status --short` reports only the intended files.
   - For visual changes, capture/update before/after evidence.
9. If a step fails verification, fix it before moving on.
10. Do not continue with a dirty or broken working tree.
11. If unrelated dirty files appear, stop and report them — do not touch
    them unless they are required for the current step.

## Hard acceptance criteria for the redesign

- 0 occurrences of `Color(0xFF…)` outside the approved theme / token files.
- All large screen files targeted in **J3** are reduced to **≤ 350
  lines** unless explicitly documented as an approved exception.
- Canonical widgets from **J2** are reusable and covered by tests
  where practical.
- Every redesigned screen preserves the same user-facing functionality.
- Every list / detail screen has loading, empty, and error states by
  the end of **J5**.
- Final state passes `flutter analyze`, `flutter test`, and a release
  build verification on both Android and iOS targets.
- Light **and** dark themes ship at full parity across every canonical
  widget and every redesigned screen (decision: full dark mode).

## Plan overview

| Phase | Title | Approx. commits |
|-------|-------|----------------:|
| J0 | Plan freeze + baseline | 2 |
| J1 | Design-system tightening | ≈ 6 |
| J2 | Canonical mobile widgets (×5 + toast) | ≈ 8 |
| J3 | Decompose god-screens (15 files > 500 lines) | ≈ 15 |
| J4 | Per-feature redesign passes | ≈ 20 |
| J5 | Motion + loading / empty / error states | ≈ 5 |
| J6 | iOS / Android / tablet polish | ≈ 3 |
| J7 | Final QA + handoff | ≈ 2 |

Order is strict: each phase ends before the next begins.

---

## J0 — Plan freeze + baseline

- **J0.1** Save this plan as `docs/FLUTTER_REDESIGN_PLAN.md`.
  Commit + push.
- **J0.2** Document the baseline inventory of the **15 large screens**
  (the J3 targets) in `docs/FLUTTER_BASELINE_INVENTORY.md`. Capture
  before/after evidence will be attached per screen when J3 starts —
  full screenshot capture across all 41 screens is **out of scope**
  (operator decision: «لقطات للشاشات الـ 15 الكبيرة فقط»).

**Acceptance**: both docs in `docs/`, both commits pushed, working
tree shows only the unrelated pre-existing `print_templates` dirty
files (reported in J0 but not touched).

---

## J1 — Design-system tightening (≈ 6 commits)

Goal: no color, spacing, radius, or shadow literal lives outside
`lib/core/theme/tokens.dart` and its sibling files.

- **J1.1** Extend `tokens.dart`: explicit `state` colors
  (success / warning / danger / info each with Bg / Fg / Strong);
  gradient tokens; motion tokens (durations + curves).
- **J1.2** Remove legacy aliases (`navy900`, `cyan500`, `purple`).
  Replace usages with the correct tokens across the codebase.
- **J1.3** Sweep all 40+ ad-hoc `Color(0xFF…)` literals outside
  `tokens.dart` (`grep -r "Color(0xFF" lib/`) → token references or
  new tokens.
- **J1.4** Extract `lib/core/theme/spacing.dart` (8-pt grid) and
  `lib/core/theme/motion.dart` (durations / easing curves) out of
  `tokens.dart` for clearer separation of concerns.
- **J1.5** Implement a **production-grade dark theme** with full
  parity to light (decision locked: «Implement a full production-grade
  dark mode … maintain complete parity between light and dark themes
  across all canonical widgets and redesigned screens»).
  Updates `app_theme.dart` to expose `ThemeData.dark()` for real, adds
  a theme controller (Riverpod) backed by `shared_preferences`, and
  wires a system / light / dark switcher into Settings / More.
- **J1.6** Add `AppTypography` (display / title / body / label /
  caption with locked weights) and replace ad-hoc `TextStyle`s in
  `app_theme.dart` and widgets where convenient.

**Acceptance**: `flutter analyze` clean, dark mode toggles correctly,
`grep -r "Color(0xFF" lib/` returns **0** results outside
`lib/core/theme/`.

---

## J2 — Canonical mobile widgets (≈ 8 commits)

Build mobile equivalents of the web's five canonical building blocks
plus a toast system. Every widget supports light + dark themes.

| # | Widget | File | Web parallel |
|---|---|---|---|
| J2.1 | `HubToggleSwitch` (modernized Switch + label + variants) | `lib/shared/widgets/hub_toggle_switch.dart` | `toggle_switch.html` |
| J2.2 | `HubUnitInput` (value + unit dropdown, smart-units list) | `lib/shared/widgets/hub_unit_input.dart` | `unit_input.html` |
| J2.3 | `HubTimePickerCircular` (analog clock-face dialog) | `lib/shared/widgets/hub_time_picker_circular.dart` | `time_picker_circular.html` |
| J2.4 | `HubAccessSchedule` (simple + advanced day/time windows) | `lib/shared/widgets/hub_access_schedule.dart` | `access_schedule.html` |
| J2.5 | `HubSpeedRulesPanel` (summary-card + expand + bulk actions) | `lib/shared/widgets/hub_speed_rules_panel.dart` | `_speed_rules_panel.html` |
| J2.6 | `HubToast` (floating success / error / info messenger) | `lib/shared/widgets/hub_toast.dart` | `uf-toast` in users_form |
| J2.7 | `WidgetGalleryScreen` (source-only development gallery, not mounted in production router) | `lib/features/_dev/presentation/widget_gallery_screen.dart` | — |
| J2.8 | Golden tests for J2.1 – J2.6 in both themes | `test/widgets/...` | — |

**Acceptance**: gallery screen renders every widget, golden tests pass
on both themes, contracts (inputs / outputs / JSON shape) match the
web counterparts where applicable.

---

## J3 — Decompose god-screens (≈ 15 commits)

For each oversized screen: extract sub-widgets into a sibling
`widgets/` folder, move state to a Riverpod `Notifier` /
`AsyncNotifier`, reuse canonical widgets where possible, and keep the
top-level screen file **≤ 350 lines** of composition only.

Ordered by current size (longest first):

| Step | Screen | Lines today |
|------|--------|------------:|
| J3.1 | `print_templates_screen.dart` | 1470 |
| J3.2 | `card_model.dart` (domain / DTO / serialization split) | 1130 |
| J3.3 | `subscriber_form_screen.dart` | 987 |
| J3.4 | `admin_control_screen.dart` | 982 |
| J3.5 | `cards_list_screen.dart` | 955 |
| J3.6 | `card_checker_screen.dart` | 864 |
| J3.7 | `tools_screen.dart` | 792 |
| J3.8 | `plan_form_screen.dart` | 767 |
| J3.9 | `bandwidth_schedules_screen.dart` | 757 |
| J3.10 | `card_batch_edit_screen.dart` | 697 |
| J3.11 | `mikrotik_screen.dart` | 665 |
| J3.12 | `subscriber_finance_screen.dart` | 657 |
| J3.13 | `lifecycle_screen.dart` | 634 |
| J3.14 | `saas_modules_screen.dart` | 621 |
| J3.15 | `system_operations_screen.dart` | 530 |

**Acceptance per step**: original screen file ≤ 350 lines; before /
after line counts noted in the commit body; `flutter analyze` clean;
functional smoke test (manual navigate-through) preserves behavior.

---

## J4 — Per-feature redesign passes (≈ 20 commits)

Visual redesign pass per feature using the J2 canonical widgets and
the J1 token / typography system. Each step ships a polished, dense,
SaaS-grade layout while preserving every action and field.

| Step | Feature | Highlights |
|------|---------|------------|
| J4.1 | Auth / Login | Premium hero, endpoint chip, animated logo |
| J4.2 | Dashboard | Gradient KPI cards, mini sparklines, collapsible sections |
| J4.3 | Subscribers list | Density toggle, filter chips, swipe actions |
| J4.4 | Subscriber form | Apply `HubAccessSchedule`, `HubSpeedRulesPanel`, `HubUnitInput`, `HubTimePickerCircular`, `HubToggleSwitch` |
| J4.5 | Subscriber finance | Timeline view + ledger summary card |
| J4.6 | Cards list + batches | Grid view, batch progress meter |
| J4.7 | Card form + generate | Stepper / wizard UI |
| J4.8 | Card checker | Scanner-style intro + result card |
| J4.9 | NAS list + form | Device cards + status pulse |
| J4.10 | Plans list + form | Pricing-focused layout |
| J4.11 | Bandwidth schedules | Embed `HubSpeedRulesPanel` |
| J4.12 | Sessions list | Live status + auto-refresh hint |
| J4.13 | Audit log | Timeline + actor badges |
| J4.14 | Reports (financial + operational) | `fl_chart` charts + chip filters |
| J4.15 | Admins + Roles | User cards + role matrix |
| J4.16 | Distributors | Balance + actions menu |
| J4.17 | MikroTik diagnostics | Health card cluster |
| J4.18 | Device fingerprints | Device tile + lock indicator |
| J4.19 | Tools / System Operations / Admin Control | Tool gallery grid |
| J4.20 | Lifecycle / Backups / Recycle bin / Print templates / More | Layout polish + density |

**Acceptance per step**: light + dark screenshot pair stored under
`docs/redesign/<feature>/`; analyze clean; functional smoke test;
canonical widget count documented in the commit body.

---

## J5 — Motion + loading / empty / error states (≈ 5 commits)

- **J5.1** `HubSkeletonLoader` adopted everywhere a list / detail
  awaits data.
- **J5.2** `HubEmptyState` polish (illustration + CTA) on every empty
  list.
- **J5.3** `HubErrorState` + retry button + toast hookup on every
  failing request path.
- **J5.4** Page transitions (`FadeThrough` / `SharedAxis` / `Hero`)
  applied per route family.
- **J5.5** Haptics + `AnimatedSwitcher` micro-interactions on primary
  controls (toggles, confirm buttons, FAB).

**Acceptance**: every list / detail screen demonstrably renders the
three states; transitions feel intentional; analyze clean.

---

## J6 — iOS / Android / tablet polish (≈ 3 commits)

- **J6.1** iOS: Cupertino haptics, safe-area handling, status-bar
  style per route, back-gesture preserved.
- **J6.2** Android: edge-to-edge, Material You compat, dynamic
  status-bar tint where supported.
- **J6.3** Tablet / landscape: master-detail in Subscribers, Cards,
  NAS, Plans where it improves density.

**Acceptance**: side-by-side screenshots on at least one phone + one
tablet on each platform.

---

## J7 — Final QA + handoff (≈ 2 commits)

- **J7.1** `docs/FLUTTER_REDESIGN_REPORT.md`: per-screen before / after
  metrics (lines, widget count, canonical adoption), screenshot pairs,
  remaining notes.
- **J7.2** Update `README.md`, write `docs/FLUTTER_DESIGN_SYSTEM.md`,
  freeze the golden-snapshot baseline for J2 widgets.

**Acceptance**: `flutter analyze` clean, `flutter test` passes,
release build succeeds on both platforms (`flutter build apk
--release` + `flutter build ios --release --no-codesign`),
all phase acceptance criteria above are satisfied.

---

## Execution trail (irregularities)

- **J1.3** was executed in code but its commit was lost to a concurrent
  commit race. The actual J1.3 work — extending `tokens.dart` with
  `surfaceMuted` / `surfaceTinted` / `slate100|200|500` / `borderNeutral` /
  `overlayLightLg|Sm` / `successMed` / `warningMed` / `dangerMed` /
  `infoMed`, plus the sweep of 80+ `Color(0xFF…)` literals across ~23
  files — was absorbed into the two operator commits
  [22c3948](https://github.com/ahmadjamalahmad94-code/hoberadius-flutter/commit/22c3948)
  («Add Flutter card print export operations room») and
  [72b5b9d](https://github.com/ahmadjamalahmad94-code/hoberadius-flutter/commit/72b5b9d)
  («Complete Flutter print template API models»). Operator decision
  (2026-05-21): document the slip and continue from J1.4 — no revert,
  rebase, or history rewrite.
- After this irregularity, `flutter analyze` is clean and the J1.3
  acceptance criterion («0 `Color(0xFF…)` outside tokens») is satisfied,
  verified by `grep -r "Color(0x" lib/` returning zero results outside
  `lib/core/theme/tokens.dart`.

## Decisions taken (locked)

- **Dark mode**: full production-grade dark theme, parity across
  every canonical widget and every redesigned screen.
- **Baseline screenshots**: limited to the 15 large screens targeted
  by J3 (not all 41 screens).
- **Plan freeze**: this document is the single source of truth — any
  deviation requires updating this file in the same commit.

---

## Reporting after every step

Every step's commit body must include:

```
Files changed:
  …

Verification:
  flutter analyze: <result>
  flutter test:    <result or "n/a">
  git diff --check: clean
  git status --short: <expected files only>

Visual evidence: <path to screenshot pair OR "documented inline">
Next step: <J?.?>
```

— end of plan —
