# RESUME HERE — client-side backlog remaining (branch feat/parity-p1-daily-ops)

Done this session: print-templates **editable designer** (render engine
byte-faithful: portrait/RTL/engine/logo/QR/credential + designer UI + revived
bg-picker), store console **reclassified → API-first**, mikrotik **/health
risk panel**, admin **avatar_url** field.

Still to build (all have a working admin `/api/v1`; just need Flutter UI):
1. ✅ **Business-operators console** — DONE. `lib/features/business_ops/`
   (model+repo+screen), route `/business-ops` + nav entry under finance.
   Wires `GET /business/summary` (KPI hero), `GET /finance/ledger` +
   `POST /finance/ledger/corrections`, `GET|POST /pricing/snapshots`. Test:
   `test/business_ops_repository_test.dart`.
2. ✅ **Operational-reports bespoke UX** — DONE. New `reports_center_screen`
   hub (KPI strip + category-grouped report cards) at `/operational-reports`;
   `operational_report_detail_screen` at `/operational-reports/:slug` with
   curated per-slug columns (catalog in `domain/operational_report_catalog`),
   per-kind cell formatting (date/bytes/duration/bool/amount), server search,
   and a client-side date-range drill-down on each report's primary timestamp
   (API only exposes q/limit/offset). Old generic dropdown screen removed.
   Tests: `operational_report_catalog_test` + repointed model test.
3. ✅ **Per-permission Arabic labels** — DONE. `/api/v1/permissions` localises
   only the group prefix (10/16) and returns raw permission keys, so the full
   `_perm_labels` catalogue is mirrored client-side in
   `admins/domain/permission_labels.dart` (PERM_LABELS + GROUP_LABELS +
   GROUP_META icon/colours). `role_form_screen` now shows the Arabic label per
   chip (raw key in tooltip) + group icon/label. Test:
   `permission_labels_test`.
4. ✅ **Deeper mikrotik control UI** — DONE. Threaded routerId+onChanged into
   `_LiveSnapshotPanel`→`_LiveSectionCard`→`_RouterRowPreview` and added a
   `_RouterRowActions` consumer that renders per-section controls: disconnect
   on hotspot_active/ppp_active (reads row `.id`), simple-queue edit dialog
   (max-limit + disable), address-list delete + section-level add dialog, and
   file download (new repo `downloadRouterFile` → FileSaver). Test:
   `mikrotik_repository_control_test`.
5. ✅ **Print-designer minor** — DONE (pattern fields). `pattern_color` +
   `pattern_opacity` added to `CardBackground` (model + builder parse), SVG
   adapter now uses the picked colour for grid/signal/wave deco and the
   saved/legacy overlay opacity (grid 0.20 / signal 0.18 / wave 0.30) — byte-
   faithful to the web `_svg_defs`/`_svg_background`. Designer exposes a colour
   + opacity control (hidden on `clean`). Tests added to
   `card_renderer_svg_test`. Optional drag-canvas for element positions NOT
   done — left as future polish (positions still set via the numeric x/y
   fields, which remain functional).

---

# API-First Backlog — Flutter parity items needing a NEW web-side API

> Every item here is a parity gap the Flutter app **cannot** close until the
> web (`radius-module`) ships a `/api/v1` JSON endpoint. They are flagged, not
> faked (no WebView, no stub data). Build these on `radius-module` afterward to
> reach true 100% parity. Maintained across P1→P6.

## Subscribers
- Granular temporary-speed scheduling: `temporary_speed_duration_minutes`,
  `temporary_{download,upload}_speed_kbps`, `temporary_speed_from/to` — not in
  `/api/v1/accounts` `_EDITABLE` (only the `temporary_speed` bool is).
- Subscriber-group **picker** — no `/api/v1/subscriber-groups` list endpoint
  (the `group` field is free-text in Flutter for now).
- Subscriber-360 `services` panel — `/accounts/<u>/360` returns a generic
  `services` map with no documented shape to render meaningfully.

## Plans / Bandwidth
- Per-rule day-of-week (`sr_days`) + copy-from-saved-schedule preset on
  bandwidth schedules — `/api/v1/bandwidth-schedules` has no `days` /
  `source_schedule` field.
- Plan alternate-unit fields (`duration_unit/value`, `validity_unit/value`,
  `data_unit/value`), `burst_raw`, `router_ids`, `on_login`/`on_logout`
  router-script hooks — accepted by the profiles whitelist but have no
  meaningful single-field form representation (need a structured contract).

## Sessions
- Current-speed / speed-state columns + special/temporary/none speed-type
  quick-filter — `/api/v1/sessions/online` doesn't return per-session speed
  data (computed server-side in the web template).

## Advanced control (P4 — web-only pages, no `/api/v1`)
- **Site exit** (`site_exit.html`, 806 ln) — per-router VPS/tunnel selected-
  sites exit manager. No JSON API.
- **Events risk / investigations / security** (`events_risk.html`,
  `events_investigations.html`, `events_security.html`) — risk-rule engine,
  fraud flags + `risk_score`, investigation workflow. No JSON API.
- **Event detail / entity timeline** (`events_detail.html`) — `/events` has no
  per-event detail endpoint.
- **Network Telegram alerts** (`network_telegram_settings.html`) — bot_token/
  chat_id/thread_id for network-device alerts. No JSON API.
- **WhatsApp auto-reply bot** (`communications_bot.html`) — keyword→reply
  config. No JSON API.

## Reports / admin (P6 — refinements; data parity already met)
- **Operational reports per-report UX** — all 15 API slugs are covered by a
  generic dropdown+table; the web ships 19 bespoke `rep_*` pages with tailored
  columns, date filters, and drill-downs (client-side polish, API exists).
- **`reports_center` hub** — KPI hero + report catalog landing (client-side).
- **`rep_login_states_detail`** drill-down — no API slug (API-first).
- **Per-permission Arabic labels** — role form shows raw permission keys; web
  `_perm_labels.html` localizes each (client-side mapping; needs the label
  catalogue, ideally exposed by the permissions API).
- **Admin form `avatar_url` + `profile_notes`** — accepted by the admins API,
  not yet in the Flutter admin form (client-side).
- **Audit `user_agent`** — returned by `/audit`, not rendered (minor).

## Reclassified to API-first (discovered during client-side build)
- **Store admin console** — RECLASSIFIED: every `/api/v1/store/*` endpoint
  requires a **store token** (customer/operator login via `_require_store_token`),
  NOT the admin token the Flutter app holds. `store_support.html` is a
  Flask server-rendered admin page with no admin-authenticated `/api/v1`.
  Needs new admin-token endpoints (list/approve deposits + withdrawals,
  admin chat, package admin) before a Flutter console can exist.

## Client-side follow-ups (API EXISTS — needs a new Flutter screen, NOT API-first)
- **Business-operators console** — wire `business_os` `POST /finance/ledger/
  corrections` and `/pricing/snapshots` (GET/POST) into a dedicated console.
- **Company inventory & expenses** — `company_inventory_expenses.html`.
- **Print-templates editable designer** — gradient/pattern/preset/colors/
  fonts/logo/QR-style controls; revive `bg_image_picker`; logo element +
  portrait position table + render-engine RTL composition profiles +
  `pattern_color/opacity` (CardBackground model fields).
- **MikroTik control UI** — disconnect buttons on active lists, simple-queue
  edit dialog, address-list management UI, `/health` risk panel, file
  download, live-traffic SSE (repository methods already wired in P1f).

## MikroTik (web-only pages, no `/api/v1`)
- `mt_topology` (network topology), `mt_login_designer` (hotspot login page
  designer), `mt_programming` (router script programming), `mt_audit_timeline`,
  `mt_recovery_plan` / `mt_problems`, `mt_permission_matrix`.
- `mt_metrics_setup` / `mt_push_setup` / `mt_setup_script` — PUSH-mode
  scheduler-script generators (metrics + DHCP fingerprints).
- `device_health.html` per-device fingerprint health.
- Setup-wizard `health` + `server-readiness` preflight (2 endpoints exist but
  unused; everything else wired) — keep until confirmed in API.
