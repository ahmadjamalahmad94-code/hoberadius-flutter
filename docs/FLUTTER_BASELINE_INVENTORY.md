# Flutter Baseline Inventory — J3 targets

> Captured during **J0.2** on 2026-05-21, immediately after freezing the
> redesign plan ([docs/FLUTTER_REDESIGN_PLAN.md](FLUTTER_REDESIGN_PLAN.md)).
> Documents the pre-redesign state of the 15 large screens that J3
> will decompose. Screenshot pairs (before / after) are attached
> per-step when each J3 commit lands.

## Repo state snapshot

- Branch: `main`
- HEAD at capture: `fc9d9b2` (J0.1: Freeze Flutter redesign plan)
- Unrelated dirty files at capture (not touched by this work):
  - `lib/features/print_templates/data/print_templates_repository.dart`
  - `lib/features/print_templates/domain/print_template_model.dart`
  - `lib/features/print_templates/presentation/print_templates_screen.dart`
  - `test/print_template_model_test.dart`

## Audit summary

Source: full repository audit performed at the start of this effort.

- 41 screens wired in `lib/core/router/app_router.dart`. No orphans.
- 268 `setState` calls across 32 files (despite Riverpod already wired).
- 40+ hardcoded `Color(0xFF…)` literals outside `lib/core/theme/tokens.dart`.
- 5 canonical web partials map unevenly to mobile today
  (see plan §J2 for the gap list).
- `flutter analyze` is clean. `pubspec.lock` is present.
- Theme is Material 3 with the project's purple brand
  (`#6B5AED`) and matches the web `hub_v2` palette.

## J3 targets — line counts and density

Captured fresh on 2026-05-21 via `wc -l` and `grep -cE '\bsetState\('`:

| # | Step | Path | Lines now | `setState` calls | Goal |
|---|------|------|----------:|-----------------:|-----:|
| 1 | J3.1 | `lib/features/print_templates/presentation/print_templates_screen.dart` | 1472 | 22 | ≤ 350 |
| 2 | J3.2 | `lib/features/cards/domain/card_model.dart` | 1130 | n/a (domain) | ≤ 350 per file across split |
| 3 | J3.3 | `lib/features/subscribers/presentation/subscriber_form_screen.dart` | 987 | 32 | ≤ 350 |
| 4 | J3.4 | `lib/features/admin_control/presentation/admin_control_screen.dart` | 982 | 6 | ≤ 350 |
| 5 | J3.5 | `lib/features/cards/presentation/cards_list_screen.dart` | 955 | 0 | ≤ 350 |
| 6 | J3.6 | `lib/features/cards/presentation/card_checker_screen.dart` | 864 | 9 | ≤ 350 |
| 7 | J3.7 | `lib/features/tools/presentation/tools_screen.dart` | 792 | 14 | ≤ 350 |
| 8 | J3.8 | `lib/features/plans/presentation/plan_form_screen.dart` | 767 | 27 | ≤ 350 |
| 9 | J3.9 | `lib/features/bandwidth_schedules/presentation/bandwidth_schedules_screen.dart` | 757 | 12 | ≤ 350 |
| 10 | J3.10 | `lib/features/cards/presentation/card_batch_edit_screen.dart` | 697 | 16 | ≤ 350 |
| 11 | J3.11 | `lib/features/mikrotik/presentation/mikrotik_screen.dart` | 665 | 12 | ≤ 350 |
| 12 | J3.12 | `lib/features/accounting/presentation/subscriber_finance_screen.dart` | 657 | 7 | ≤ 350 |
| 13 | J3.13 | `lib/features/lifecycle/presentation/lifecycle_screen.dart` | 634 | 8 | ≤ 350 |
| 14 | J3.14 | `lib/features/saas_modules/presentation/saas_modules_screen.dart` | 621 | 1 | ≤ 350 |
| 15 | J3.15 | `lib/features/system_operations/presentation/system_operations_screen.dart` | 530 | 3 | ≤ 350 |
| — | total | — | **12510** | **169** | — |

## Per-screen notes (qualitative)

These are the qualitative findings the redesign passes will address.

### J3.1 — `print_templates_screen.dart` (1472 L, 22 setState)
List + editor + preview crammed into one file. Editor mixes a form
panel, a live preview surface, and the template list state in the
same widget tree. Local state for the entire wizard, including form
controllers, sits in one `_State`. Splits well into:
list / editor (sections) / preview / Notifier.

### J3.2 — `card_model.dart` (1130 L)
Domain entities + DTOs + JSON serialization in a single file. Sub-
divides into a `domain/` model file, a `data/` DTO mapping file, and a
`data/` adapter for shared serialization helpers.

### J3.3 — `subscriber_form_screen.dart` (987 L, 32 setState)
Most state-heavy form in the app. Seven+ `CollapsibleSection`s
(account / internet / advanced / notifications / subscription /
general / …). Has the existing `WheelTimeRangeField` +
`WheelDaysPickerField` — to be replaced by canonical
`HubAccessSchedule` and `HubSpeedRulesPanel` in **J4.4**, after this
decomposition.

### J3.4 — `admin_control_screen.dart` (982 L, 6 setState)
Long single-scroll admin console with many disjoint utility blocks.
Each block is a candidate sub-widget.

### J3.5 — `cards_list_screen.dart` (955 L, 0 setState)
Big list screen that nevertheless does its filtering / batch
display inside a single build method. No local `setState` (Riverpod-
driven), but extraction will improve readability and let J4 visual
work happen in smaller files.

### J3.6 — `card_checker_screen.dart` (864 L, 9 setState)
Tabs-style screen with stats, lookup, history. Tabs map naturally
to extracted sub-screens.

### J3.7 — `tools_screen.dart` (792 L, 14 setState)
Holds 5+ unrelated tool cards in one screen. Each tool becomes its
own widget + Notifier.

### J3.8 — `plan_form_screen.dart` (767 L, 27 setState)
Mirror of subscriber_form_screen's shape. Same decomposition
approach (sections + FormNotifier).

### J3.9 — `bandwidth_schedules_screen.dart` (757 L, 12 setState)
Today: list + inline form + actions for global bandwidth schedules.
After J2.5 lands, this screen embeds `HubSpeedRulesPanel` so the
inline form goes away.

### J3.10 — `card_batch_edit_screen.dart` (697 L, 16 setState)
Form-shaped, with batch options + per-card options. Same split as
subscriber_form.

### J3.11 — `mikrotik_screen.dart` (665 L, 12 setState)
Diagnostics: ping, ARP, IP-pool, route-list etc. Each diagnostic
card becomes a widget + Notifier.

### J3.12 — `subscriber_finance_screen.dart` (657 L, 7 setState)
Tabs (overview / payments / loans / ledger). Tabs become files.

### J3.13 — `lifecycle_screen.dart` (634 L, 8 setState)
Long single-scroll timeline + actions. Timeline + action rail split.

### J3.14 — `saas_modules_screen.dart` (621 L, 1 setState)
List of SaaS module toggles + config blobs. Module card widget.

### J3.15 — `system_operations_screen.dart` (530 L, 3 setState)
Operations grid + actions. Operation tile widget.

## Screenshot policy (per operator decision)

Visual baselines are captured for the **15 J3 targets only**.
- Light + dark pair per screen.
- Saved under `docs/redesign/<feature>/before/<screen>.png` when each
  J3 step starts.
- Matching `after/` capture committed together with the J3 step.
- The 26 smaller screens get their before/after captured during
  **J4** when their visual redesign lands.

## Open follow-ups (not part of J0)

- 4 pre-existing dirty files under `lib/features/print_templates/`
  and `test/print_template_model_test.dart` remain untouched.
  Plan: address them in **J3.1** when `print_templates_screen.dart`
  decomposes; if they conflict with the decomposition strategy, they
  will be stashed and re-applied or rebased by the operator
  separately.

— end of inventory —
