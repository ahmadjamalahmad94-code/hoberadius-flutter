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

## Client-side follow-ups (API EXISTS — needs a new Flutter screen, NOT API-first)
- **Store admin console** — `store.py` (1027 ln) + `store_support.html`:
  packages, deposits (list/create/approve), withdrawals, chat. Large new
  screen.
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
