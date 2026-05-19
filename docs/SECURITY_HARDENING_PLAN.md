# Security hardening plan — pre-production checklist

Status: **plan only** — no code changes yet. This document captures what the
current Flask/Flutter API surface needs before going to a real VPS. Each item
is sized so it can be done as a single small slice.

## 1. Token expiry enforcement

**Current state**: `app/api/admin_auth.py` mints a fresh `api_token` on login
via `api_tokens_repo.create_token(...)` without setting `expires_at`. The DB
row has the column (`expires_at TEXT NULL`), but the auth middleware in
`app/api/auth.py` never reads it. Tokens issued today live forever until
manually revoked.

**Risk**: a token leaked from a single device (lost phone, browser cache,
copy-paste into chat) stays valid until an admin notices and revokes it via
the web UI.

**Plan**:
1. In `admin_auth.admin_login`: when minting the token, set
   `expires_at = utcnow() + ENV(HOBERADIUS_TOKEN_TTL_HOURS, default=24*7)`.
   Pass through `api_tokens_repo.create_token` (add `expires_at` kwarg —
   the column already exists; only the helper needs the param).
2. In `auth.require_api_token` after `resolve_by_plain(token)` returns the
   row: if `rec["expires_at"]` is set and parsed datetime is past `utcnow()`
   → return 401 with code `token_expired`. Best-effort flag the row as
   `revoked = 1` to keep the active set small.
3. Surface `expires_at` in the login response (already returned, currently
   `None`) so the Flutter client can warn the user.
4. Add a refresh endpoint `POST /api/admin/refresh` that mints a new token
   from a still-valid one, atomically revoking the old one. Optional in v1;
   for now the Flutter app re-prompts for credentials on expiry.

**Size**: ~30 lines of Python + 1 small test. Safe to ship without Flutter
changes; older Flutter builds keep working until their token expires, then
hit the existing login screen path.

## 2. Disable the dev-token fallback in production

**Current state**: [`app/api/auth.py:33-37`](C:/Users/Ahmad J Ahmad/Desktop/hub/radius-module/app/api/auth.py:33)
falls back to a literal `dev-token-please-change` when
`HOBERADIUS_API_TOKENS` env is unset. The token grants tenant_id=1 with no
rate-limit ceiling.

**Risk**: if `HOBERADIUS_API_TOKENS` is forgotten on deploy, the system
ships with a publicly-known admin token. Every endpoint behind
`require_api_token` is exposed.

**Plan**:
1. Add `HOBERADIUS_ENV` (or reuse `FLASK_ENV`). When the value is `prod` /
   `production`, `_allowed_env_tokens()` returns `()` instead of falling
   back. An empty allow-list with no `api_tokens` row in DB means every
   request gets 401 — fail-closed.
2. Log a `WARNING` once at app startup if the dev fallback is engaged
   outside `dev`/`testing` — visible in the docker logs.
3. Document the required env vars in `deploy/.env.example` (file already
   exists; only the comment needs an update).
4. Add a startup health-line: `radius adapter initialized: mode=sqlite,
   auth=env|db, dev-fallback=on|off` so the operator knows on boot.

**Size**: ~20 lines + doc update. Independent of Flutter.

## 3. CORS allow-list for VPS

**Current state**: [`app/__init__.py`](C:/Users/Ahmad J Ahmad/Desktop/hub/radius-module/app/__init__.py:43-78)
reads `HOBERADIUS_CORS_ORIGINS` (csv) and defaults to `*`. The default
permits any browser origin to call `/api/*` with a stored bearer token. The
preflight handler echoes `Origin` back when `*`, which is fine in dev but
broad in prod.

**Risk**: a malicious site loaded in an admin's browser can read API
responses if it gets a valid token (e.g. via XSS on a sister web app).

**Plan**:
1. In production (`HOBERADIUS_ENV=prod`) the default flips to the empty
   string and `Access-Control-Allow-Origin` is set only for explicit
   matches. No `*` echo. If `HOBERADIUS_CORS_ORIGINS` is empty in prod →
   no CORS headers at all (same-origin only — appropriate when the Flutter
   app talks to its own VPS over HTTPS).
2. Document recommended values in `.env.example`:
   - `HOBERADIUS_CORS_ORIGINS=https://app.hoberadius.com,https://admin.hoberadius.com`
   - Mobile/desktop Flutter binaries don't need any entry — they use the
     `Authorization` header and are not subject to CORS.
3. Keep `*` only when `HOBERADIUS_ENV=dev` (default), so local Flutter web
   builds still work.

**Size**: ~15 lines + doc. Independent of Flutter.

## 4. Permission decorators for CUD actions

**Current state**: every `/api/v1/*` write only requires
`require_api_token`. The admin's `role.permissions` array is fetched at
login time (returned to Flutter), but the server never re-checks
permissions on subsequent calls. A token belonging to a `viewer` role can
still POST/PATCH/DELETE anything.

**Risk**: privilege escalation by token alone. Once an admin logs in with
any role, the token they receive has effectively `admin:full` scope.

**Plan**:
1. Add `app/api/permissions.py` with:
   ```python
   def require_permission(perm: str): ...      # decorator
   def admin_from_token() -> Optional[Admin]:  # helper
   ```
   Resolves the calling admin via the existing `api_tokens.created_by`
   linkage already used by `/api/admin/me`. Checks
   `AdminsService.permissions_of(admin)` against the required perm.
   `is_super_admin` bypasses the check.
2. Apply incrementally to one resource at a time so old clients don't break
   all at once:
   - Slice C+ NAS endpoints: `nas.write`, `nas.test`, `nas.delete`
   - Slice D Admins endpoints: `admins.read`, `admins.write`,
     `roles.write` (super_admin only on roles)
   - Retrofit accounts/profiles after a soak: `subscribers.write`,
     `plans.write`
3. Keep a transitional env switch `HOBERADIUS_ENFORCE_PERMS=0|1` so the
   feature can be flipped without redeploying when the role catalogue is
   tuned.
4. Return 403 `forbidden` with the required perm in `details` so the
   Flutter client can show a precise "you need permission X" message.

**Constants**: `app/radius/core/constants.py` already declares
`ALL_PERMISSIONS` (the values the role editor uses); reuse those exact
strings so the web admin and the API agree.

**Size**: ~60 lines for the decorator + helper, then ~3 lines per endpoint
to apply it. Per-resource cadence keeps the blast radius small.

## 5. Bonus — already covered, just confirm before prod

- ✅ Password hashing: `admins_repo.hash_password` uses scrypt
  (n=16384, r=8, p=1, dklen=32). Acceptable.
- ✅ API tokens stored only as SHA-256 hash (`api_tokens_repo.hash_token`).
  Plain token shown to the user exactly once.
- ✅ CSRF on web admin: `app/__init__.py` `_csrf_check` is active for all
  non-`/api/*` POST requests. JSON API correctly bypasses CSRF because it
  authenticates with bearer tokens.
- ✅ Rate limit per token: `_rate_limit_check` already enforces 60 req/min
  default; per-tenant tier configurable.
- ⚠️ HTTPS / nginx: the deploy pack already has nginx config, but verify
  `proxy_set_header X-Forwarded-For` is set so the admin login captures
  real client IP.
- ⚠️ Audit log retention: `audit_repo` has no pruning. Plan a `--days N`
  retention job before scaling.

## Recommended order (after Slice C/D feature work)

1. Item 2 (disable dev fallback) — smallest, biggest payoff.
2. Item 1 (token expiry).
3. Item 3 (CORS allowlist).
4. Item 4 (permissions) — per resource, gated by env switch.

Each item is shippable in a single ~30-minute slice; do not bundle them.
