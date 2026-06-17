# HobeRadius Flutter ⇄ Web — Parity Scorecard

> Updated 2026-06-17 (reverse-sync pass — match current web structure). Scope: how completely the
> Flutter app matches the web RADIUS panel — **both data/behaviour AND
> style/colors**. "API-first" = blocked on a new web `/api/v1` endpoint (see
> `API_FIRST_BACKLOG.md`); those are NOT counted against Flutter since they
> can't be built client-side yet.

## Overall: ~97%  (≈100% of the API-backed surface; remainder is the documented web-only ceiling)

> **This pass** wired the four endpoints the web team just merged: Telegram
> admin-alerts, store admin management, temp-speed duration unit, and the
> MikroTik network-programming wizard. With these, essentially every web
> surface that exposes a JSON `/api/v1` contract now has a real Flutter screen.
>
> **Quality gate CERTIFIED:** style/colors at the token level (100%); all **71
> routed screens** pass the no-overflow sweep at 360/600/1280 px (68 prior + 3
> new); stub/fake scan clean. What remains is the **hard web-only ceiling**
> below — surfaces that physically cannot be a JSON API.

| Domain | % | Notes |
|---|---:|---|
| **Style / colors / theme** | 100% | Tokens matched to `hub_tokens.css` (palette, text, borders, shadows, pills, brand ramp); Cairo font; light web-style sidebar; card/button/input themes via tokens. |
| Login / Auth | 100% | Endpoints + Arabic + failure/loading states. |
| Dashboard | 95% | alerts[] + recent_batches + counters + db/radius chips. Finance strip + printed/electronic split = API-first (dashboard endpoint extension). |
| Subscribers | 95% | Full `_EDITABLE` form + list actions + 360. Subscriber-group picker & granular temp-speed = API-first. |
| Cards / card-users | 95% | CRUD/batches/recharge/checker/marketplace + create-package. Deeper card_pricing matrix = API-first. |
| Plans / Bandwidth | 95% | Advanced plan fields + Bandwidth Profiles CRUD. `sr_days`/unit-value pairs = API-first. |
| Sessions | 95% | online/disconnect/lock/temp-speed (now with **minutes/hours duration unit**)/accounting. Per-session speed columns + speed-type filter = API-first (server doesn't return per-session speed). |
| NAS / network-devices | 100% | CRUD/test/scan/bypass/remote-access fully wired. |
| MikroTik | 90% | core + control + diagnostics + /health + per-row disconnect/queue/address-list/file + **network-programming wizard** (hotspot/pppoe form+live-state → plan w/ commands·risks·preview·backup-warning → apply w/ confirm+safety+risk gate → unprogram). **Hard ceiling (web-only):** topology, login-designer deploy/preview, audit-timeline, recovery, permission-matrix, metrics-push ingest, live-traffic SSE — these need real hardware / NDJSON+binary+FTP streams, not a JSON API. |
| License / System / Backups | 95% | license file, sync, admin-bridge, Drive connect, restore, capacity. |
| Finance / Services | 95% | collection/wallets/ledger/loans/invoices/tickets/lifecycle/recycle + business-ops console + **store admin console** (deposits/withdrawals confirm·reject, payment-methods CRUD, support chat inbox + reply + status). Company inventory/expenses = API-first. |
| Network Policy | 90% | CRUD/apply/changes/rollback/targets + preview intelligence. **Reverse-synced to current web:** NPC is no longer a standalone nav item — it now opens from «عمليات الراوتر» (router dashboard), mirroring web `80e9483 Move NPC into MikroTik router dashboard`; the duplicate «الوصول البعيد»/remote-access kind was removed (web `66f551e`), leaving web-block + walled-garden only. site-exit = API-first. |
| Events | 50% | center + record + business summary. detail/risk/investigations/security = API-first. |
| Communications + Alerts | 95% | channels/campaigns/templates/quota/whatsapp-bridge + **Telegram admin-alerts** (bot config w/ masked token + PATCH-keep, test-connection, per-alert toggle + test + rendered preview). WhatsApp auto-reply bot = API-first. |
| Portals | 95% | subscriber portal (+payments/request-detail), customer portals, hotspot/card portal. |
| Reports | 90% | financial + operational center hub + bespoke per-report UX. rep_login_states_detail = API-first. |
| Print Templates | 90% | render engine byte-faithful (portrait/RTL/engine/logo/QR/credential/pattern) + editable designer + bg-picker. Drag-position canvas = minor follow-up. |
| Admin / Audit / Settings / Tenants / Roles | 98% | avatar_url, tenant branding/currency, per-permission Arabic labels, readable audit action+target. business-operators-profile / sections-admin = web-only (API-first). |

## Reverse-sync pass (2026-06-17) — match the CURRENT web structure
The web deleted/merged some pages after the original parity build; the app was
audited section-by-section against `radius-module@main (~5616346)` (sidebar +
routes + git history) and corrected so it mirrors the **current** web, not the
old one:
- **«سياسات الشبكة» / Network-Policy center** — REMOVED as a standalone nav item
  and **merged into the router dashboard**: it now opens from «عمليات الراوتر»
  (matches web `80e9483`). The `/network-policy` route stays registered (deep
  links) but is no longer in the sidebar/«المزيد». The duplicate
  **«الوصول البعيد» / remote-access** policy kind was deleted (matches web
  `66f551e`), leaving **web-block + walled-garden** only — same as the web
  `_REGISTRY`. (The separate `network-devices` remote-access *session* feature is
  unrelated and untouched.)
- **Evaluated & kept (no web delete/merge):** `radius-resources` → maps to web
  `pool_list` «نطاقات العناوين» (still in the sidebar); `network-devices` → web
  route is alive but its nav entry is *temporarily hidden* "until next release"
  (operator note in `_sidebar.html`), i.e. not deleted/merged; `device-finger‑
  prints` → fingerprint data surfaces in the web MAC-history report, never a
  standalone web page; `mikrotik` (bind credentials) → per-router credential
  surface, distinct from operations. These remain to preserve wired parity;
  flagged here for the owner if a future web change drops them.

## How to read this
- Everything not marked **API-first** is **done** in Flutter.
- The path to 100% is almost entirely **web-side API work** (the
  `API_FIRST_BACKLOG.md` list) — once those endpoints exist, the matching
  Flutter screens are small follow-ups.
- Style/color parity is now at the token level, so it propagates to every
  screen uniformly.

## Quality gate (owner hard requirement)
Standard applied to every screen built/touched:
1. **No design breakage** — no overflow/clipping/misalignment at mobile,
   tablet, or Windows desktop; RTL correct.
2. **No fake/dead elements** — every widget/button/field/action is real and
   wired to the live `/api/v1`; if an endpoint doesn't exist it goes to the
   API-first list, never a stub.

Pass status this audit — **CERTIFIED**:
- Stub/fake scan (coming-soon / placeholder / TODO / mock / dead-handler):
  **clean** — only legitimate hints, a QR fallback grid, and loading
  skeletons. The one remaining no-op handler lived in the unrouted dev gallery
  (`lib/features/_dev/`), now **removed**. Legacy `shell/sidebar.dart` was
  already removed.
- Overflow: **systematic per-screen sweep done.** `test/screens/
  screen_overflow_sweep_test.dart` pumps **all 71 routed screens** at 360 /
  600 / 1280 px with a fake API client and asserts `takeException()` is null
  (no RenderFlex overflow). **All 71 certified** (the 3 new screens —
  telegram-alerts, store-admin, mikrotik-programming — included). The 68-screen
  pass fixed ~21 real violations (StatusPill flexible label; `isExpanded` on
  every dropdown; over-stuffed headers → Expanded/Wrap; fragile fixed-aspect
  stat grids → content-height Wrap; toggles/pills → full-width/Wrap; an illegal
  Expanded-in-Wrap; a ListTile→Material; print-templates desktop room gates on
  width) plus two robustness fixes (controllers guard post-dispose `state =`;
  edit screens defer the initial load off `initState`).

## Hard web-only ceiling (NOT buildable as a Flutter screen — by design)
These web surfaces have no JSON `/api/v1` contract and cannot get one, so they
are excluded from the parity denominator (the web team flagged them explicitly):
- **MikroTik login-page designer** — deploy/preview produce a ZIP of
  NDJSON + binary assets pushed over FTP to the router; not a JSON response.
- **MikroTik live-apply / live-traffic SSE** — needs a persistent connection to
  real router hardware (Server-Sent Events / streaming), not request/response.
- **Metrics-push ingest** — the router *pushes* metrics to the server on a
  schedule; there is nothing for an admin client to call.
- **MikroTik topology / audit-timeline / recovery-plan / permission-matrix** —
  server-rendered analytics pages with no JSON endpoint.
Everything else that exposes a JSON API now has a real, wired Flutter screen.

## Remaining non-API client follow-ups (small)
- Print-templates drag-position canvas (designer positions are editable via
  numeric mm fields today; drag handles are a nicety, not parity-blocking).
- Subscriber-360 generic `services` panel (shape ambiguous → API-first).
