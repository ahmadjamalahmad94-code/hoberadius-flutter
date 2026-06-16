# HobeRadius — Parity Gap Audit & Phased Build Plan

> Captured **2026-06-16**. Read-only audit of the Flutter app
> (`radius-module-app`) against the web RADIUS panel
> (`radius-module`, current `main` HEAD `b68d32f`).
> Audit + plan only — no features built, nothing merged.

Method: 7 parallel deep audits comparing each Flutter feature
(`lib/features/*`, routes, repositories) against the web's
`app/templates/radius/*.html` pages and `app/api/v1/*.py` endpoints.
Classifications: ✅ complete-parity · 🟡 exists-needs-audit ·
🔴 missing-Flutter · 🔴 missing-API.

---

## 0. The governing pattern (read this first)

**Flutter parity tracks the JSON API almost perfectly.** Every web
feature that has a real `/api/v1` endpoint is well covered in Flutter.
Every web feature that is **server-rendered Flask-only (no v1 API)** is
absent in Flutter *and cannot be built there without writing the API
first*. So the backlog splits cleanly into two kinds of work:

- **🟡 Flutter-only gaps** — the API exists; we just need to surface
  more fields/actions/screens. Fast, pure client work.
- **🔴 API-first gaps** — the web feature has no JSON contract. The web
  team must ship `/api/v1` endpoints *before* the Flutter screen
  (matches the matrix rule "API أولًا ثم شاشة Flutter").

This distinction drives the phasing below.

---

## 1. Repo cleanup result (STEP 0 — DONE)

- **Stale locks removed:** `.git/HEAD.lock`, `.git/index.lock`,
  `.git/objects/maintenance.lock` (all zero-byte) deleted; `git status`
  works.
- **Churn branch abandoned:** `wip/save-2026-06-09-redesign` (`7c50ce6`,
  "397 files") was verified **pure CRLF↔LF churn** —
  `git diff 4a32bdb 7c50ce6 --ignore-cr-at-eol` = **0 files with real
  changes** (88791 ins == 88791 del). `main` already holds all the real
  content. Branch **deleted**.
- **On clean `main` at `4a32bdb`** (working tree clean apart from two
  untracked build logs `flutter-web.{err,out}.log`).
- **Root cause fixed:** repo had no `.gitattributes` and
  `core.autocrlf=true`, so LF blobs were checked out as CRLF and a
  sandbox op with different autocrlf committed the CRLF bytes.
  - Added `.gitattributes` (`* text=auto eol=lf`; `.bat/.cmd/.ps1` =
    crlf; `.sh` = lf; binaries `-text`), set `core.autocrlf=false`
    locally, and renormalized the working tree to physical LF.
  - Blobs were already LF, so the renormalize was content-neutral (it
    staged only `.gitattributes`) — genuinely a small commit.
  - **Commit `ce09e53` on branch `chore/normalize-eol` — NOT merged.**

Untracked `flutter-web.{err,out}.log` left in place (out of scope; can
be added to `.gitignore` in a follow-up if desired).

---

## 2. Gap audit — per domain

### P0 — Foundation (login · dashboard · shell · core)

| Domain | Status | Concrete gaps |
|---|---|---|
| Login / Auth | ✅ | Targets `/api/admin/login`, `/me`, `/logout`; shapes match. Adds a server-endpoint picker (ahead of web). Minor: drops `last_login_at/ip`. |
| Shell / Nav | ✅ (superset) | Adaptive sidebar/rail/bottom-nav, 8 sections; broader than web's per-page tab strips. |
| Account | ✅ | Change-password matches. Missing read-only license-identity fields: `managed_by_license_admin`, `external_subject`, `external_password_version`. |
| Theming / i18n | ✅ | Arabic-first RTL forced app-wide; dark mode at/ahead of web. No English leakage. |
| Core states | ✅ | Dio client, Bearer auth, Arabic error normalization, loading/empty/error widgets all present. |
| **Dashboard** | 🟡 | **The real P0 gap.** `/api/v1/dashboard` already returns data Flutter ignores: **`alerts[]`** (deep-link attention panel) **never parsed**; **`recent_batches`** read under the wrong key (`recent`/`audit`) → "آخر النشاطات" card renders **empty** against current server; subscriber counters `expired/expiring_soon/suspended/disabled/banned`, `plans.top`, `db_ok/radius_ok` unused. **Missing-API** for full parity: finance strip (`revenue_today/month/year`) and printed-vs-electronic card dashboard (`card_dashboard.*`) live in the web view context, not in `/api/v1/dashboard`. |

### P1 — Daily ops (subscribers · plans · cards · sessions · NAS · mikrotik)

| Domain | Status | Concrete gaps |
|---|---|---|
| **Subscribers** | 🟡 (big field gap) | Form omits a large slice of the API whitelist: **temporary speed** (`temporary_speed*`, `temporary_speed_from/to`), **quota & time limits** (`*_quota_mb`, `*_connection_time_min`, `quota_limit_enabled`, `equal_share_*`), **per-subscriber bandwidth override** (`bandwidth_control_enabled`, `download/upload_speed_kbps` — in model, no UI), **PPPoE** (`pppoe_*`), **MikroTik advanced** (`mikrotik_filter_chain/address_list/user_group/queue_priority`, `framed_pool`, `ppp_attributes_extra`), **management bindings** (`balance/group/pool/manager_id` — no pickers), personal extras (`father_name/national_id/city/...`), and the inline `_speed_rules_panel`. List rows lack the web's per-row enable/disable/extend/reset quick-actions. `service_type` in model but no dropdown. |
| Subscriber Groups | 🔴 missing-Flutter + 🔴 missing-API | Service-binding groups (`default_plan_id`, `bandwidth_schedule_id`, `default_auto_renewal`, `connection_schedule`, members) — zero Flutter, and no `/api/v1` endpoint exists. |
| Plans / Profiles | 🟡 | Rich already, but `toBody` omits `loan_enabled`, `max_loan_minutes`, `speed_override_allowed`, and daily/monthly split-quota fields the API accepts. Large web-only activation/billing/portal-policy field set in `plans_form.html` is web-ahead (Flask-form only). |
| Pools | ✅ | Full parity (`radius_resources`). |
| Share Groups | ✅ | Full parity incl. members CRUD + enable/disable. |
| Bandwidth Profiles | 🔴 missing-Flutter | `/bandwidth-profiles` (full CRUD API + `bandwidth_form.html`) has **no Flutter screen**. |
| Bandwidth Schedules / Speed Rules | 🟡 | Core schedule CRUD + apply(dry/live) wired. Missing per-rule **day-of-week (`sr_days`)** scoping and **copy-from-saved-schedule** preset; no inline speed-rules on subscriber/group forms. |
| **Cards** (CRUD/batches/generate/import/recharge/checker) | ✅ | `cards_repository` covers generate, import, batch list/bulk/exports (csv/xlsx/pdf), recharge, and all per-card actions. Checker is v1 only (web also has `cards_checker_v2`). |
| Card Users / 360 / Marketplace | ✅ | Wired incl. marketplace packages panel. |
| Vouchers / Hotspot portal | ✅ | Present + routed. |
| Card Pricing | 🔴 missing-Flutter (+ web-only) | `card_pricing.html` / `card_pricing_batch.html` have no Flutter screen (web admin routes, no v1 API). |
| **Print Templates + Card Render Engine** | 🟡 (largest single-feature gap) | See §3 below — export room exists, **editable designer does not**, Dart render builder ignores ~30 designer keys. |
| Sessions | ✅ | All online/disconnect/lock/temp-speed + accounting history wired. |
| NAS | ✅ | Full CRUD + test. |
| Network Devices (scan/bypass/remote) | ✅ | 13/14 endpoints wired incl. scan, bypass apply/remove, remote-access open/close. |
| Device Fingerprints | 🟡 | List + PULL sync only; no PUSH-script generator (`mt_push_setup`/`mt_setup_script`), no `device_health` view. |
| MikroTik core (`mikrotik.py`) | ✅ | list/add/update/delete/test/test-credentials. |
| **MikroTik control** (44 endpoints) | 🟡 (read-heavy) | ~23/44 wired (live snapshot + backups + reboot/identity/NTP/DNS + guided assistant). **Missing actions:** diagnostics `ping/traceroute/dns-resolve`, **disconnect active hotspot/ppp session from router**, queue edit (`PUT /queues/simple`), address-list CRUD, file download, live traffic stream/SSE, `/health` risk signals. |
| Setup Wizard | 🟡 | 14/16 endpoints; full WireGuard handshake wired. Missing `/setup-wizard/health` + `/server-readiness` pre-flight. Single consolidated screen vs web's v2/v3/fleet-compat variants. |
| Router Alerts | ✅ | Settings GET/PATCH (API itself is thin). |

### P2 — License / sync / backups / system / tools / settings

| Domain | Status | Concrete gaps |
|---|---|---|
| License file | ✅ | `/system/license-file` wired. |
| Admin bridge | 🟡 | `license-sync/identity-sync/heartbeat/events` wired. Unused: `usage-report`, `capacity-status`, `backups/upload-latest`, `restore/poll`, `restore/<ref>/snapshot`, `restore/<ref>/apply`, `service-activations/poll`. |
| Sync queue | ✅ | list/retry/cancel/reconcile wired. |
| System status/diagnostics | ✅ | both wired. |
| **Backups** | 🟡 (restore missing) | `status` + local `run` wired. **Restore entirely missing** in Flutter (web `restore_enabled` + bridge restore endpoints). Google-Drive shown read-only — `google-drive/connect` + `poll` not wired. |
| System settings | ✅ | ~40 catalog keys rendered dynamically + PATCH edit (flat list vs web sections — cosmetic). |
| Tokens | ✅ | list/create(show-once)/revoke. |
| Tenants | 🟡 | CRUD wired; form omits `primary_color`, `logo_url`, and `currency`/`timezone` editing. |
| Webhooks | ✅ | config/test/deliveries wired. |
| Tools (set-speeds, general-adj, test-auth, radius-log) | ✅ | wired. |
| Tools — maintenance | 🟡 | `preview` wired with confirm-phrase; **verify `/tools/maintenance/run` is actually invoked** (only preview is wired in `tools_screen`). |
| Admins | 🟡 | Full CRUD; form omits `avatar_url`, `profile_notes`. |
| Roles | ✅ | Full CRUD + system-role guards. |
| Permissions matrix | 🟡 | Catalog grouped, but renders **raw permission keys** as chip labels — web `_perm_labels.html` localizes each permission to Arabic. |
| Admin profiles / Business operators / Sections admin | 🔴 missing-Flutter + 🔴 missing-API | `business_operators*`, `sections_admin`, `admins_profile_summary` — web-only, no v1 API. |
| Audit log | ✅ | actor/action/target filters + payload dialog. Minor: `user_agent` not rendered. |

### P3 — Finance / services / lifecycle

| Domain | Status | Concrete gaps |
|---|---|---|
| Payment collection | ✅ | requests/review-queue/reconciliation/approve/reject/apply-service all wired. |
| Accounting / ledger / loans | ✅ | wired (loans+debts merged into Loans Center). |
| Wallets / Revenue / Invoices / Distributors | ✅ | all wired incl. distributor balance/assign-batch/settle. |
| Tickets + Service-requests | ✅ | All 4 decisions (approve/reject/request_payment/trial) + billing linkage wired. |
| Services | 🟡 | Served via generic `saas_modules` (list/create/delete); **no PATCH update**, no bespoke services screen. |
| **Store admin console** | 🔴 missing-Flutter | `store.py` (1027 ln) + `store_support.html` (654 ln): packages, deposits (list/create/approve), withdrawals, chat, redeem/purchase — **zero Flutter coverage**. |
| Business Operators console | 🔴 missing-Flutter | Piecemeal (wallets/revenue/events) but no consolidated console; `ledger/corrections` + `pricing/snapshots` unused. |
| Company inventory & expenses | 🔴 missing-Flutter | `company_inventory_expenses.html` — no screen. |
| Lifecycle | ✅ | policies CRUD + disable + preview + run wired. |
| Recycle bin | 🟡 | list + restore wired; **`/archive` POST not invoked**. |
| **Currency handling** | 🟡 (cross-cutting bug) | Tenant default is **JOD**; `payment_collection`, `wallets`, `tickets` fall back to **`ILS`**, and the currency picker is a fixed `['ILS','JOD','USD']` list instead of being driven by tenant `settings.currency`. accounting/distributors correctly use JOD. |

### P4 — Advanced control (network-policy · events · communications)

| Domain | Status | Concrete gaps |
|---|---|---|
| Network Policy (3 kinds, targets, apply/changes/rollback) | ✅ | full CRUD + change-set history + per-router rollback. |
| Network Policy **preview intelligence** | 🟡 | Flutter has core preview (canApply, commandCount, health %, blockers, script). Missing web's risk-level pill, blast-radius, dependency graph, grade taxonomy, canary apply, glossary. |
| **Site exit** (VPS exit manager) | 🔴 missing-Flutter + 🔴 missing-API | `site_exit.html` (806 ln) — entire per-router tunnel exit surface absent; no JSON API. |
| **Network Telegram alerts** | 🔴 missing-Flutter + 🔴 missing-API | `network_telegram_settings.html` — no Flutter, no JSON API. |
| Events center (list/filter/record) | ✅ | matches. |
| Event detail / timeline | 🔴 missing-Flutter | list only, no drill-down. |
| **Events risk / investigations / security** | 🔴 missing-Flutter + 🔴 missing-API | `events_risk/investigations/security.html` — risk engine, fraud flags, investigation workflow — absent on both sides. |
| Communications | ✅ (strongest cluster) | templates/send/audience/campaigns/deliveries/channels/quota + WhatsApp bridge all wired. |
| **WhatsApp auto-reply bot** | 🔴 missing-Flutter + 🔴 missing-API | `communications_bot.html` keyword→reply config — no Flutter, no JSON API. |

### P5 — Portals

| Domain | Status | Concrete gaps |
|---|---|---|
| Customer portals (admin) | ✅ | read-only portal listing matches. |
| Subscriber self-serve portal | 🟡 | Strong (login/summary/usage/finance/sessions/loan+renewal requests). Gaps: no invoices/payments billing list (web `billing` tab), no `requests/<id>` detail call. |
| Card portal / pricing depth | 🟡 | purchase + view wired; pricing/marketplace admin depth pending (see §3). |

### P6 — Reports / settings

| Domain | Status | Concrete gaps |
|---|---|---|
| Financial reports | ✅ | sales daily/monthly/yearly + profit-loss + exports + snapshots. (Verify `reports_cards`/`reports_distributors` coverage.) |
| **Operational reports** | 🟡 | **Data parity is complete** (all 15 API slugs covered) but as **one generic dropdown + auto-column table** vs the web's **19 bespoke `rep_*` pages** (tailored columns, date filters, drill-downs). Missing `rep_login_states_detail` drill-down (no API slug) and `reports_center` hub/landing (KPI hero + catalog). Generic table falls back to raw English column keys for unmapped columns. |

---

## 3. Print Templates + Unified Card Render Engine — current status

The web `card_renderer.py` (2,959 ln) is one normalized model with SVG +
PDF(ReportLab/Arabic) adapters and 4 render-engine profiles.

**What Flutter HAS:**
- A real Dart port: `card_render_model.dart`,
  `card_render_model_builder.dart`, `card_renderer_svg.dart`.
- The **export room** (`export_room.dart`): settings + live-preview +
  template-chips 3 columns, routed.
- **Default-template star + favorites + bulk-delete fixtures** — ✅ full
  parity (`set-default`, `cleanup-fixtures` with confirm).
- **Fit-to-viewport** preview (`object-fit: contain`) — ✅ parity.
- **RTL-safe SVG** (`direction="ltr"` triple defence) — ✅.
- PDF correctly delegated to backend export (bit-identical by design).

**What Flutter is MISSING (the gap):**
- **No editable designer.** Preview shows a `"تصميم مغلق"` lock pill.
  The web's ~44 design inputs (gradient/pattern/preset/colors/fonts/
  bg/logo/QR-style) have no editable Flutter equivalent. `template_form`
  exposes only name/orientation/page-size/rows/cols/mm-positions/font.
- **Strict bg-image picker is built but dead code** (`bg_image_picker.dart`
  referenced by nothing — never wired into a designer).
- **Dart builder ignores ~30 designer keys:** `render_engine`/
  `text_direction`/`credential_label_language` (no RTL default
  composition flip), `qr_size_pct`, portrait default positions (table
  has landscape only → oversized vertical cards), `logo_*` (no logo
  element at all), `qr_style/qr_color/qr_background_color`, per-credential
  styling (`credential_text_color`, surface enabled/color/opacity, font
  sizes), `pattern_color/opacity`, `background_source/style` +
  uploaded-design suppression, full QR login-URL payload.
- **Arabic label mismatch:** Dart hardcodes pill labels `اسم الدخول`/
  `كلمة المرور`; web `_credential_label` returns `USER`/`PASS` (latin
  engine) or `اسم المستخدم`/`كلمة المرور` (arabic engine) — both text
  and language-switching differ.

**Net:** saved web templates that use any advanced designer key render
**differently** (or with defaults) in the Flutter preview. This is the
single highest-value parity item.

---

## 4. Phased build plan

Sized in realistic engineer-days. Each phase ends green
(`flutter analyze` + `flutter test`), small commits, no `git add .`.
🔴-API items are called out as **API-first** — the web team ships the
`/api/v1` endpoint before the Flutter screen.

### Phase P0 — Foundation truth-up (~2 days, Flutter-only)
1. Dashboard: parse + render `alerts[]` with deep-links (data already
   served). **Fix the `recent_batches` key mismatch** (silent empty
   card). Add subscriber attention counters, `plans.top`, `db_ok/
   radius_ok` chips.
2. Account: surface license-identity read-only fields.
3. Decide finance-strip + printed/electronic dashboards →
   **API-first** (extend `/api/v1/dashboard` with `executive.finance` +
   `card_dashboard`) then render.
4. Sweep visible strings for any English leakage; confirm RTL on every
   P0 surface.

### Phase P1 — Daily ops parity (~8–10 days)
1. **Subscriber form completion** (largest): add temporary-speed, quota
   & connection-time, per-subscriber bandwidth override UI, PPPoE,
   MikroTik-advanced, management bindings (group/pool/manager pickers),
   personal extras, `service_type` dropdown. ~3 days.
2. Subscriber **list-row quick-actions** (enable/disable/extend/reset).
3. **Inline speed-rules panel** + per-rule `sr_days` + copy-from-schedule
   preset; reuse in subscriber form. (Unblocks bandwidth-schedules gap.)
4. **Bandwidth Profiles** screen (`/bandwidth-profiles` CRUD).
5. Plans: add `loan_enabled`/`max_loan_minutes`/`speed_override_allowed`
   + daily/monthly split quotas to `toBody`.
6. **MikroTik control actions**: diagnostics (ping/traceroute/dns),
   active-session disconnect, queue edit, address-list CRUD, file
   download, live-traffic stream. (Endpoints already exist.)
7. Setup wizard: server-readiness/health pre-flight; confirm
   fleet-compat / v3 router-service-flow paths.
8. Device fingerprints: `device_health` view + PUSH-script generator.
9. **API-first:** Subscriber Groups — web ships `/api/v1/subscriber-groups`,
   then Flutter form + members.

### Phase P2 — Print-templates designer + license/system (~6–8 days)
1. **Editable card-template designer** (the §3 gap): wire the dead
   `bg_image_picker`, add gradient/pattern/preset/color/font/QR-style/
   logo controls, and **complete the Dart render builder** (render-engine
   profiles, portrait defaults, logo element, QR styling, per-credential
   styling, label language). ~4 days. Highest visual-parity value.
2. **Backups restore flow** + Google-Drive connect/poll (API-first if the
   restore contract needs hardening; bridge endpoints already exist).
3. Admin-bridge: capacity-status, usage-report, upload-latest.
4. Tenant branding fields; admin `avatar_url`/`profile_notes`;
   per-permission Arabic labels; verify maintenance `run`.

### Phase P3 — Finance & services depth (~5–6 days)
1. **Currency fix** (cross-cutting): default JOD, drive picker from
   tenant `settings.currency`, purge `ILS` fallbacks.
2. **Store admin console** (deposits/withdrawals approval, chat,
   packages) — large; confirm `store.py` is the intended Flutter surface.
3. Business-operators console + `ledger/corrections` + `pricing/snapshots`.
4. Services PATCH-update; recycle-bin `archive`; company inventory/expenses.

### Phase P4 — Advanced control (~6–8 days, mostly API-first)
1. Network-policy preview **intelligence layer** (risk/blast-radius/
   dependency/grade/canary/glossary) — API likely already returns
   richer preview; surface it.
2. Event **detail/timeline** drill-down.
3. **API-first cluster** (web ships `/api/v1` first, then Flutter):
   site-exit manager, network Telegram alerts, events risk/
   investigations/security, WhatsApp auto-reply bot.

### Phase P5 — Portals (~3 days)
1. Subscriber-portal billing/invoices list + `requests/<id>` detail.
2. Card-portal pricing/marketplace admin depth.

### Phase P6 — Reports (~4–5 days)
1. Bespoke per-report UX for the 15 operational slugs (tailored columns,
   date filters, drill-downs) replacing the generic table.
2. `reports_center` hub (KPI hero + catalog) + `rep_login_states_detail`
   drill-down (**API-first** for the detail slug).
3. Verify `reports_cards` / `reports_distributors` coverage.

---

## 5. API-first backlog (web team — blockers for Flutter)

These have **no `/api/v1` contract today**; Flutter cannot reach parity
until the web ships endpoints:

- Subscriber Groups (service-binding groups)
- Site exit / VPS tunnel exit manager
- Network Telegram alert settings
- Events: risk engine, investigations, security, event-detail/timeline
- WhatsApp auto-reply bot config
- Business operators console; sections admin; admin profile summary
- `rep_login_states_detail` report slug
- Dashboard finance + printed/electronic context (extend `/api/v1/dashboard`)

---

## 6. Already at full parity (no action)

Login, shell/nav, account (core), theming/i18n, core states, pools,
share groups, cards CRUD/batches/recharge/checker, card-users/360/
marketplace, vouchers, hotspot portal, sessions, NAS, network devices,
mikrotik core, router alerts, license file, sync queue, system status/
diagnostics, system settings, tokens, webhooks, tools (4 of 5), roles,
audit log, payment collection, accounting/ledger/loans, wallets, revenue,
invoices, distributors, tickets+service-requests, lifecycle, network
policy CRUD/apply/rollback, communications (full), customer portals,
financial reports.
