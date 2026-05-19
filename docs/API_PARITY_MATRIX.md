# API Parity Matrix — Flask Web ⇄ JSON API ⇄ Flutter Client

> Source of truth for backend/Flutter alignment. Update this whenever you add or change a feature in either side.

**Legend**:
- `✅ ready` — endpoint exists + Flutter wired to it
- `⚠️ partial` — endpoint exists but missing fields or actions
- `❌ missing` — no API yet
- `📱 mobile` — should be in the mobile/desktop app
- `🌐 web-only` — kept exclusively on the Flask web admin
- `🔧 flag` — admin/super-admin only

The Flask web app at `/admin/radius/*` is the primary web interface. The Flutter app at `radius-module-app` is the Android/iOS/Windows admin client. Both consume the same backend services; only the protocol differs (HTML form-post vs JSON).

---

## Core domain (mobile-first)

| Feature | Web routes | Backend service | API now | Missing API | Flutter screen | Status | Priority | Slice |
|---|---|---|---|---|---|---|---|---|
| **Login** | `/login`, `/logout` | `AdminsService.authenticate` | `POST /api/admin/login` `GET /api/admin/me` `POST /api/admin/logout` | — | `LoginScreen` | ✅ ready | P0 | done |
| **Dashboard** | `GET /` | `build_dashboard_metrics` | `GET /api/v1/dashboard` | — | `DashboardScreen` | ✅ ready | P0 | done |
| **Subscribers (Users) list** | `GET /users` | `UsersService.list` | `GET /api/v1/accounts` | — | `SubscribersListScreen` | ✅ ready | P0 | done |
| **Subscriber create** | `POST /users` | `UsersService.create` | `POST /api/v1/accounts` | full metadata + working_days + bandwidth fields | `SubscriberFormScreen (new)` | ⚠️ partial | P0 | **A** |
| **Subscriber update** | `POST /users/<u>` | `UsersService.update` | `PATCH /api/v1/accounts/<u>` | same as create — full RM-H1 fields | `SubscriberFormScreen (edit)` | ⚠️ partial | P0 | **A** |
| **Subscriber detail** | `GET /users/<u>/edit` | `UsersService.get` | `GET /api/v1/accounts/<u>` | metadata not flattened in response | `SubscriberFormScreen` | ⚠️ partial | P0 | **A** |
| **Subscriber delete** | `POST /users/<u>/delete` | `UsersService.delete` | `DELETE /api/v1/accounts/<u>` | — | swipe-to-delete | ✅ ready (api) | P1 | A |
| **Subscriber toggle** | `POST /users/<u>/toggle` | enable/disable | `POST /api/v1/accounts/<u>/disable` `POST /api/v1/accounts/<u>/enable` | — | from list/detail | ✅ ready (api) | P1 | A |
| **Subscriber extend time** | `POST /users/<u>/extend` | `UsersService.extend_time` | `POST /api/v1/accounts/<u>/extend_time` | — | from detail | ✅ ready (api) | P1 | A |
| **Subscriber usage** | inline in edit form | direct DB | `GET /api/v1/accounts/<u>/usage` | — | detail card | ✅ ready (api) | P1 | A |
| **Plans (Profiles) list** | `GET /plans` | `PlansService.list` | `GET /api/v1/profiles` | — | `PlansListScreen` | ✅ ready | P0 | done |
| **Plans create** | `POST /plans` | `PlansService.create` | — | `POST /api/v1/profiles` | new screen | ❌ missing | P1 | **B** |
| **Plans update** | `POST /plans/<id>` | `PlansService.update` | — | `PATCH /api/v1/profiles/<id>` | edit screen | ❌ missing | P1 | **B** |
| **Plans delete** | `POST /plans/<id>/delete` | `PlansService.delete` | — | `DELETE /api/v1/profiles/<id>` | swipe-to-delete | ❌ missing | P1 | **B** |
| **Cards generate** | `POST /cards/generate` | `CardsService.generate_batch` | `POST /api/v1/cards/generate` | — | `CardBatchFormScreen` | ✅ ready | P0 | done |
| **Cards batches list** | `GET /cards/batches` | `CardsService.list_batches` | — | `GET /api/v1/cards/batches` | `CardsListScreen` (currently empty) | ❌ missing | P1 | B/C |
| **Cards of batch** | `GET /cards/batches/<id>/cards` | repo direct | — | `GET /api/v1/cards/batches/<id>/cards` | batch detail screen | ❌ missing | P1 | B/C |
| **Cards revoke** | `POST /cards/<id>/revoke` | `CardsService.revoke_card` | `POST /api/v1/cards/<id>/revoke` | — | from batch detail | ✅ ready (api) | P1 | C |
| **NAS list** | `GET /devices` | `NasService.list` | `GET /api/v1/nas` | — | `NasListScreen` | ✅ ready | P0 | done |
| **NAS create** | `POST /devices` | `NasService.create` | — | `POST /api/v1/nas` | new screen | ❌ missing | P1 | **C** |
| **NAS update** | `POST /devices/<id>` | `NasService.update` | — | `PATCH /api/v1/nas/<id>` | edit screen | ❌ missing | P1 | **C** |
| **NAS delete** | `POST /devices/<id>/delete` | `NasService.delete` | — | `DELETE /api/v1/nas/<id>` | swipe-to-delete | ❌ missing | P1 | **C** |
| **NAS test** | `POST /devices/<id>/test` | `NasService.test_device` | — | `POST /api/v1/nas/<id>/test` | test button | ❌ missing | P1 | **C** |
| **Online sessions** | `GET /online` | `SessionsService.list_online` | `GET /api/v1/sessions/online` | — | new mobile screen | ✅ ready (api) | P1 | D |
| **Disconnect session** | `POST /online/disconnect` | `SessionsService.disconnect` | `POST /api/v1/sessions/disconnect` | — | from sessions | ✅ ready (api) | P1 | D |
| **Admins list** | `GET /admins` | `AdminsService.list_admins` | — | `GET /api/admin/admins` | `AdminsListScreen` | ❌ missing | P1 | **D** |
| **Admin create** | `POST /admins` | `AdminsService.create_admin` | — | `POST /api/admin/admins` | new screen | ❌ missing | P1 | **D** |
| **Admin update** | `POST /admins/<id>` | `AdminsService.update_admin` | — | `PATCH /api/admin/admins/<id>` | edit screen | ❌ missing | P1 | **D** |
| **Admin delete** | `POST /admins/<id>/delete` | `AdminsService.delete_admin` | — | `DELETE /api/admin/admins/<id>` | from list | ❌ missing | P2 | D |
| **Roles list** | `GET /roles` | `AdminsService.list_roles` | — | `GET /api/admin/roles` | `RolesListScreen` | ❌ missing | P1 | **D** |
| **Role create/update/delete** | `POST /roles*` | `AdminsService.*role` | — | full CRUD | role form | ❌ missing | P2 | D |
| **Audit log** | `GET /audit` | `RadiusAuditService.list` | — | `GET /api/v1/audit` | read-only mobile view | ❌ missing | P2 | D |

---

## Operational / config (web-better but mobile-helpful)

| Feature | Web routes | API now | Plan |
|---|---|---|---|
| **MikroTik configs** | `/mt*` (CRUD + test) | `GET/POST/PATCH/DELETE /api/v1/mikrotik` + `/test` | ✅ ready (api), defer Flutter UI |
| **Webhooks** | `/webhooks*` | `GET/POST /api/v1/webhooks/config` `POST /api/v1/webhooks/test` | ✅ ready (api), defer Flutter UI |
| **System status** | `/_status` | covered by `/api/v1/dashboard.system` | ⚠️ partial; consider `/api/v1/status` later |
| **Sync queue** | `/sync*` | — | ❌ missing; useful as read-only mobile widget |
| **Settings** | `/settings` | — | 🌐 web-only |
| **Tenants** | `/tenants*` | — | 🌐 web-only (super-admin) |
| **API tokens** | `/tokens*` | — | 🌐 web-only (security) |

## Web-only by design

| Feature | Reason |
|---|---|
| Reports (10 reports) | heavy data tables, web UX better. JSON export later if needed. |
| Tools (set_speeds bulk, maintenance, general_adj, test_auth UI, radius_log live) | bulk/diag tools, web-better. `tool_radius_log.json` already callable. |
| SaaS modules (invoices/vouchers/tickets/services/bandwidth/pools) | separate billing workflow; mobile app focuses on RADIUS ops. |
| Share groups | infrequent admin task. |
| Overviews (`/users/overview`, `/plans/overview`) | analytical, web tables. |

---

## Per-slice scope

### Slice A — Subscribers full parity
- **Backend**: extend `accounts_create` + `accounts_patch` to accept all RM-H1 fields and `metadata` JSON; serializer to flatten metadata for GET.
- **Flutter**: hook `SubscriberFormScreen` to real create/update; round-trip metadata; add disable/enable/extend actions on the detail.
- **Audit**: every write already goes through `UsersService` which records audit entries — no extra work.

### Slice B — Plans CUD
- **Backend**: add `POST /api/v1/profiles`, `PATCH /api/v1/profiles/<id>`, `DELETE /api/v1/profiles/<id>` calling `PlansService`. Full RM-H3 fields incl. metadata.
- **Flutter**: restore `PlanFormScreen` (delete now, write fresh from the model); add to router.

### Slice C — NAS CUD + test + Cards batches
- **Backend NAS**: `POST/PATCH/DELETE /api/v1/nas` + `POST /api/v1/nas/<id>/test` calling `NasService`.
- **Backend Cards**: `GET /api/v1/cards/batches`, `GET /api/v1/cards/batches/<id>/cards`.
- **Flutter NAS**: restore `NasFormScreen` connected. Test button in list.
- **Flutter Cards**: real batches list + drill-down.

### Slice D — Admins + Roles + Online sessions + Audit
- **Backend Admins/Roles**: `/api/admin/admins` and `/api/admin/roles` full CRUD with permission check (`is_super_admin` for write).
- **Backend Audit**: `GET /api/v1/audit`.
- **Flutter**: real Admins/Roles forms; Online sessions screen with disconnect; Audit feed.

### Slice E — Platform builds
- Android build (debug APK) workflow + signing setup notes (no Play Store yet).
- Windows build requirements (Visual Studio Build Tools 2022 + Desktop C++) — documented but not required during dev on this machine.
- iOS notes (defer — needs macOS).

---

## Cross-slice rules

1. **Single source of truth**: every write goes through the same `*Service` class as the web form. No reimplementing validation in API handlers.
2. **Audit**: services already call `RadiusAuditService.record` — both web and API writes get logged identically.
3. **Permissions**: the JSON login mints an api_token tied to the admin. Future enforcement layer = read `permissions` from the admin row → check on each API write. Slice D will introduce a `require_permission(perm)` decorator on Flask side.
4. **Response shape**: every endpoint returns `{ok, data, meta}` via `api.responses.ok/fail`. Flutter `ApiClient` already unwraps this.
5. **No web break**: every change adds API routes — never modifies the HTML form handlers. The web admin keeps working unchanged.
