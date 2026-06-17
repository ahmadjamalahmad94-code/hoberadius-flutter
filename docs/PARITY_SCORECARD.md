# HobeRadius Flutter ⇄ Web — Parity Scorecard

> Updated 2026-06-17 (theme-match + no-breakage certification pass). Scope: how
> completely the Flutter app matches the web RADIUS panel — **both
> data/behaviour AND style/colors**. "API-first" = blocked on a new web
> `/api/v1` endpoint (see `API_FIRST_BACKLOG.md`); those are NOT counted
> against Flutter since they can't be built client-side yet.

## Overall: ~93%  (≈99% of the API-backed surface; remainder is API-first)

> **Quality gate CERTIFIED:** style/colors at the token level (100%); every one
> of the 68 routed screens passes the no-overflow sweep at 360/600/1280 px; the
> stub/fake scan is clean. The path to a higher headline number is now almost
> entirely **web-side API work** — see `API_FIRST_BACKLOG.md`.

| Domain | % | Notes |
|---|---:|---|
| **Style / colors / theme** | 100% | Tokens matched to `hub_tokens.css` (palette, text, borders, shadows, pills, brand ramp); Cairo font; light web-style sidebar; card/button/input themes via tokens. |
| Login / Auth | 100% | Endpoints + Arabic + failure/loading states. |
| Dashboard | 95% | alerts[] + recent_batches + counters + db/radius chips. Finance strip + printed/electronic split = API-first (dashboard endpoint extension). |
| Subscribers | 95% | Full `_EDITABLE` form + list actions + 360. Subscriber-group picker & granular temp-speed = API-first. |
| Cards / card-users | 95% | CRUD/batches/recharge/checker/marketplace + create-package. Deeper card_pricing matrix = API-first. |
| Plans / Bandwidth | 95% | Advanced plan fields + Bandwidth Profiles CRUD. `sr_days`/unit-value pairs = API-first. |
| Sessions | 90% | online/disconnect/lock/temp-speed/accounting. Speed columns + speed-type filter = API-first. |
| NAS / network-devices | 100% | CRUD/test/scan/bypass/remote-access fully wired. |
| MikroTik | 80% | core + control + diagnostics + /health + per-row disconnect/queue/address-list/file. topology / login-designer / programming / audit-timeline / recovery / permission-matrix / metrics-push generators / SSE = web-only (API-first). |
| License / System / Backups | 95% | license file, sync, admin-bridge, Drive connect, restore, capacity. |
| Finance / Services | 90% | collection/wallets/ledger/loans/invoices/tickets/lifecycle/recycle + business-ops console. Store console + company inventory/expenses = API-first. |
| Network Policy | 90% | CRUD/apply/changes/rollback/targets + preview intelligence. site-exit = API-first. |
| Events | 50% | center + record + business summary. detail/risk/investigations/security = API-first. |
| Communications | 90% | channels/campaigns/templates/quota/whatsapp-bridge. bot + telegram alerts = API-first. |
| Portals | 95% | subscriber portal (+payments/request-detail), customer portals, hotspot/card portal. |
| Reports | 90% | financial + operational center hub + bespoke per-report UX. rep_login_states_detail = API-first. |
| Print Templates | 90% | render engine byte-faithful (portrait/RTL/engine/logo/QR/credential/pattern) + editable designer + bg-picker. Drag-position canvas = minor follow-up. |
| Admin / Audit / Settings / Tenants / Roles | 98% | avatar_url, tenant branding/currency, per-permission Arabic labels, readable audit action+target. business-operators-profile / sections-admin = web-only (API-first). |

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
  screen_overflow_sweep_test.dart` pumps **all 68 routed screens** at 360 /
  600 / 1280 px with a fake API client and asserts `takeException()` is null
  (no RenderFlex overflow). **All 68 certified.** ~21 screens had real
  violations — fixed: StatusPill flexible label; `isExpanded` on every
  dropdown; over-stuffed headers → Expanded/Wrap; fragile fixed-aspect stat
  grids → content-height Wrap / generous heights; payment-collection toggles
  & pills → full-width / Wrap; business-ops illegal Expanded-in-Wrap → Text;
  distributor form ListTile → Material; print-templates desktop room gates on
  width. Plus two real robustness fixes (form controllers guard post-dispose
  `state =`; edit screens defer the initial load off `initState`).

## Remaining non-API client follow-ups (small)
- Print-templates drag-position canvas (designer positions are editable via
  numeric mm fields today; drag handles are a nicety, not parity-blocking).
- Subscriber-360 generic `services` panel (shape ambiguous → API-first).
