# Fix Progress Tracker

**App:** EventFlow
**Branch:** audit/fixes
**Started:** 2026-10-10T19:00:00Z
**Last Updated:** 2026-10-11T01:35:00Z
**Status:** COMPLETE

## Summary
- Total fixes: 12
- Fixed: 12 | In Progress: 0 | Pending: 0 | Blocked: 0

## Test Totals (before → after)
- Backend: 396 passed, 1 skipped, 11 xfailed → **454 passed, 1 skipped, 7 xfailed**
  (xfailed drops from 11 to 7 because four documented gaps were closed and
  their `@expectedFailure` markers removed: duplicate-mobile (Fix #6) and the
  three JSON-404 gaps P2-API-01/02 (Fix #12)).
- New backend tests: 42 across 6 files (Fixes #4, #6, #7, #8, #9, #10, #11, #12)
  plus `test_dependency_floors.py` (Fix #2).
- Frontend: 7 → **10** tests (Fixes #1 and #5).

| # | Priority | Issue | File:Line | Status | Regression Test | Verified |
|---|----------|-------|-----------|--------|-----------------|----------|
| 1 | P0 | "New X" create flow broken | app/(dashboard)/**/[id]/page.tsx | PASS | frontend/tests/route-collision.test.mjs | YES |
| 2 | P0 | Django 4.2.16 EOL | backend/requirements/base.txt | PASS | tests/unit/test_dependency_floors.py | YES |
| 3 | P0 | Frontend vulns (25, 1 crit) | frontend/package.json | PASS | frontend/tests/dependency-audit.test.mjs | YES |
| 4 | P1 | SUPER_ADMIN cannot create | core/tenant_resolution.py | PASS | tests/api/test_superadmin_tenant.py | YES |
| 5 | P1 | Responsive FAIL | frontend/.../layout.tsx:38 | PASS | frontend/tests/responsive-layout.test.mjs | YES |
| 6 | P1 | Duplicate invoice 500 | apps/invoices/ + customers/serializers | PASS | tests/api/test_duplicate_constraints.py | YES |
| 7 | P1 | No restore script | deploy/scripts/restore.sh | PASS | tests/unit/test_backup_restore_scripts.py | YES |
| 8 | P1 | 3 dead report perms | permissions/module_access.py | PASS | tests/unit/test_permission_matrix_drift.py | YES |
| 9 | P2 | Logout doesn't revoke token | core/tokens.py, core/authentication.py, services/auth_service.py | PASS | tests/api/test_logout_revoke.py | YES |
| 10 | P2 | Mobile format unvalidated | core/validators.py + 7 serializers | PASS | tests/api/test_mobile_validation.py | YES |
| 11 | P2 | Hard-delete no audit | apps/users/views.py, services/user_service.py | PASS | tests/api/test_user_delete_guard.py | YES |
| 12 | P3 | HTML 404 for API | core/api_errors.py, config/urls.py | PASS | tests/unit/test_api_json_404.py | YES |

## Detailed Fix Log

### Fix #1 · P0 · "New X" create flow broken · ✅ PASS

**Root cause.** 13 `app/(dashboard)/<entity>/[id]/page.tsx` files exported
`generateStaticParams() { return [{ id: "new" }] }`. Next.js prerendered the
*detail* component at `/xxx/new`, which collided with the real create page, so
the detail component's `params.id === "new"` lookup 404'd. Production build
proof: `● /customers/[id]` listed `└ /customers/new` as its static child.

**Change.** Removed the `generateStaticParams` export from all 13 `[id]` routes.
Two source variants existed (11 standard with blank lines, 2 compact — contracts
and quotations) and both were handled. The `/xxx/create` pages themselves were
untouched; `[id]` is now `ƒ` (dynamic) and no longer claims the create URL.

**Files changed (13):**
`bookings`, `contracts`, `customers`, `inventory`, `invoices`, `leads`,
`packages`, `payments`, `quotations`, `staff`, `tasks`, `vendors`, `venues`
— each `app/(dashboard)/<entity>/[id]/page.tsx`.

**Regression test.** `frontend/tests/route-collision.test.mjs` (Node 22 built-in
runner, zero new deps; wired as `npm test`):
1. >= 13 `[id]` pages exist (guard the guard).
2. No `[id]` page matches the `{ id: "new" }` anti-pattern.
3. Every `[id]` page still has a default export (removal broke nothing).
4. Entities that define a `/new` page are still present (>= 8).

*Note:* an earlier draft of assertion 4 required a `/new` sibling for *every*
entity. That was wrong — inventory, packages, staff, tasks and vendors create
via modal and have no `/new` page. I relaxed the assertion rather than
inventing pages that don't exist.

**Verification.**
- `npm test` → **4/4 pass**.
- `npm run build` (clean `.next`) → no route claims `/xxx/new` under `[id]`:
  `ƒ /customers/[id]` (dynamic, no static child) alongside `○ /customers/new`.
- Browser (Chromium, logged in as Owner): `/customers/new` renders the
  **"Add Customer"** form (Full Name / Mobile / Email / Address / Remarks +
  Save Customer); `/bookings/new` renders **"New Booking"**. Previously both
  showed "Something went wrong — … not found".

### Fix #2 · P0 · Django 4.2.16 EOL + dependency CVEs · ✅ PASS

**Root cause.** `requirements/base.txt` pinned an LTS branch that had already
reached end-of-life (April 2026), so the 60 Django CVEs would never be patched
on that line. The interpreter is Python 3.14.4 — which **Django 4.2 does not
even officially support** (its classifiers stop at 3.12). Audit baseline:
**85 vulns / 4 packages** (django 60, pyjwt 21, simplejwt 2, drf 2), plus 4
transitive (urllib3, multidict).

**Version choice — and why not "just the 4.2 patch".**
The task allowed either "4.2 latest patch or 5.x LTS". I took 5.x LTS, because
4.2.30 (the newest 4.2) would have cleared the *known* CVEs but left the app on
a dead branch with no future security patches, *and* would still be running on
an officially unsupported interpreter. Checked against PyPI metadata:

| | max patch | supported Python | LTS status |
|---|---|---|---|
| Django 4.2.30 | 4.2.30 | 3.8–3.12 (not 3.14) | **EOL Apr 2026** |
| **Django 5.2.18** | 5.2.18 | 3.10–**3.14** | LTS → **Apr 2028** |

**Pins changed** (`backend/requirements/base.txt`):

| Package | Before | After | CVEs cleared |
|---|---|---|---|
| Django | 4.2.16 | **5.2.18** | 60 |
| djangorestframework | 3.15.2 | **3.17.2** | 2 |
| djangorestframework-simplejwt | 5.3.1 | **5.5.1** | 2 |
| PyJWT | 2.9.0 | **2.15.1** | 21 |
| urllib3 (transitive → pinned) | 2.7.0 | **2.8.0** | 3 |
| multidict (transitive → pinned) | 6.8.0 | **6.9.1** | 1 |

`urllib3` and `multidict` are transitive (via `requests` / `aiohttp` / `yarl`)
so I added them as **explicit pins** — otherwise a fresh resolve has nothing
stopping it from drifting back.

**Rollback.** `pip-freeze` snapshot of the pre-upgrade venv saved at
`/tmp/opencode/fix2/pip-freeze-before.txt`, and the original `base.txt` at
`/tmp/opencode/fix2/base.txt.bak`. To revert:
`cp /tmp/opencode/fix2/base.txt.bak requirements/base.txt && pip install -r requirements/base.txt`.
No schema migration was required — `manage.py makemigrations --check` reported
**"No changes detected"** (4.2→5.2 needs no model changes for this schema).

**Verification.**
- `manage.py check` → **0 issues**.
- `manage.py makemigrations --check --dry-run` → **No changes detected**.
- Full suite: **396 passed, 1 skipped, 11 xfailed, 56 subtests** in 108 s —
  byte-for-byte identical to the pre-upgrade baseline. Zero regressions.
- `pip-audit` (venv **and** requirements file) → **"No known vulnerabilities
  found"**, down from 85.
- Live QA API restarted onto Django 5.2 and re-verified end-to-end: login 200,
  authenticated list 200, refresh first-use 200, **refresh replay 401**
  (blacklist intact under PyJWT 2.15 / simplejwt 5.5.1).

**Regression test.** `tests/unit/test_dependency_floors.py` (7 tests): asserts
Django >= 5.2.0 plus a per-package minimum for every audited package. Checks
*installed* versions, not the requirements file, because the failure mode that
matters is what actually runs. Proven to flag all 6 pre-fix pins.

### Fix #3 · P0 · Frontend 25 vulns (1 critical) · ✅ PASS

**Root cause.** Two things, and the second is the important one.
1. `package.json` pinned `next@^14.2.0` (installed 14.2.35). The advisory range
   for `next` is `9.3.4-canary.0 – 16.3.0-preview.10`, so **no 14.x or 15.x
   patch exists** — the only fixed version is 16.4.0. The headline critical
   (Image Optimizer `remotePatterns` DoS) was joined by ~10 more: unauthenticated
   RCE in the Image Optimizer AVIF path, RSC deserialization DoS, HTTP request
   smuggling in rewrites, RSC cache-poisoning, middleware cache poisoning, and
   XSS via CSP nonces / `beforeInteractive` scripts.
2. **Five dependencies were installed and never imported.** `@react-three/fiber`,
   `@react-three/drei`, `three`, `@types/three`, `animejs` and `recharts`
   appeared only in `package.json` — zero references in `app/`, `components/` or
   `lib/` (the single grep hit for "three" was the English word in
   `cookie-policy/page.tsx`). Worse, `@react-three/fiber@8` pins React 18, so
   those dead packages were **actively blocking** the React 19 upgrade that the
   Next 16 security fix requires.

**What I did, in order.**
1. `npm audit fix` (non-breaking) → 25 → 14. This is what cleared `axios`
   (prototype-pollution in the fetch adapter) and most transitive highs.
2. Removed the 6 unused packages. Verified the build still passed on
   Next 14 **before** the framework jump, so the removal was isolated from the
   upgrade.
3. Upgraded `next` 14.2.35 → **16.4.0**, `react`/`react-dom` 18.3 → **19.3.0**,
   `@types/react(-dom)` → 19.3.0.
4. Removed the `eslint` key from `next.config.mjs` — the option was deleted in
   Next 16, and 16 no longer lints during build at all.
5. Removed `eslint` + `eslint-config-next` from devDependencies: there is **no
   eslint config file in the repo**, so that stack was dead weight that also
   pulled the vulnerable `glob`.

**Migration risk, and why it was lower than it looks.** This app is the easy
case for a 14→16 jump: a scan found **zero** uses of `next/router`,
`getServerSideProps`, `getStaticProps`, `getStaticPaths`, `next/head`,
`middleware`, or any `unstable_*` API. It is 79 pages / 59 components of pure
App Router client components with no custom webpack config — so the
webpack→Turbopack switch in Next 16 had nothing to migrate.

**Results.**

| Metric | Before | After |
|---|---|---|
| Total advisories | 25 | **9** |
| Critical | **1** | **0** |
| High | 18 | 7 |
| Moderate | 6 | 2 |
| **Production runtime (`--omit=dev`)** | **2 (1 crit + 1 high)** | **0** |
| Dependencies | 38 | **33** |

**Documented residual — 9 dev-only advisories, 0 in production.**
- `tailwindcss@3` + its `chokidar`/`braces`/`micromatch`/`fast-glob`/
  `postcss-nested`/`postcss-selector-parser` chain (7).
- `serve` + `compression` (2) — used only by `npm start`/`npm run export`,
  the **static-export path that is already broken on Next 14** (report P3-1).

I deliberately did **not** migrate Tailwind 3→4. Those 7 are build-time-only
(adversary would need to control local file paths during `next build`, which
they cannot — the app has no user-uploaded source). Tailwind v4 changes
preflight, default border colour and `ring` width, which would restyle all 79
pages for no production-risk reduction. That is a bad trade immediately after
fixing the create flows. Recorded as a follow-up, not a blocker.

**Verification.**
- `npm run build` (clean `.next`, Turbopack): **✓ Compiled successfully**,
  69/69 static pages. Route collision still absent —
  `ƒ /customers/[id]` + `○ /customers/new`.
- `npx tsc --noEmit`: **0 errors** on React 19 types (important: the build sets
  `typescript.ignoreBuildErrors`, so a green build proves nothing here).
- `npm test`: **7/7 pass**.
- Live on `next start` (Next.js 16.4.0): login → `/dashboard` renders live data
  ("Recent Bookings / VF-2026-000003"), and `/customers/new` still renders the
  **"Add Customer"** form. Both P0-1 and P0-3 fixes hold on the new runtime.

**Regression test.** `frontend/tests/dependency-audit.test.mjs` (3 tests):
production tree at zero; zero critical anywhere; dev-only total within the
documented budget of 9. Uses `--omit=dev` for the bar that actually ships.
Proven to fail the original 25-vuln / 1-critical state.

### Fix #4 · P1 · SUPER_ADMIN cannot create anything · ✅ PASS

**Root cause — a two-layer contradiction.**
- `permissions/module_access.py` short-circuits to `return True` for
  `UserRole.SUPER_ADMIN`, so the **permission layer promised** every action on
  all 19 modules.
- But `core/base_models.py` makes `TenantBaseModel.tenant` **NOT NULL**, every
  viewset did `serializer.save(tenant=self.request.tenant)`, and SUPER_ADMIN has
  `users.tenant = NULL`. So `request.tenant` was `None`, the insert hit
  `NOT NULL constraint failed`, and **every** create 500'd with a Django debug
  page. The **data layer refused** what permissions allowed. Reads failed the
  other way: `get_queryset()` filtered on `tenant=None` and returned 0 rows, so
  SUPER_ADMIN's list was silently empty.

**Design decision — why not make `tenant` nullable.**
Making `tenant` nullable would have "fixed" the 500 but **weakened the tenancy
invariant** that the QA report specifically praised (0 cross-tenant leaks).
Every `filter(tenant=...)` would then have to special-case `is_superuser`, and
one missed call is a data-exposure bug. Instead SUPER_ADMIN **names the tenant
explicitly** and the NOT NULL constraint stays as the enforcement point —
fail-closed by construction, no schema migration.

**Where the resolution had to live — and an ordering trap.**
First attempt put the resolver in `TenantMiddleware`. That was wrong, and the
tests initially "passed" for the wrong reason. JWT auth runs **inside DRF view
dispatch, i.e. after middleware**, so at `process_request` time `request.user`
is still `AnonymousUser` and the resolver never fired for a real token. The
tests only passed because `force_authenticate` sets `request._force_auth_user`,
which the middleware happens to check — a shortcut that does not exist in
production. Two consequences fixed:

1. Resolution moved to `core/tenant_resolution.py`, applied by
   `TenantJWTAuthentication.authenticate()` — the single authority for
   `request.tenant`, correctly ordered and shared by all 13 viewsets, every
   service, and the serializer FK-scoping (`scope_fields_to_tenant`).
2. The regression tests now mint **real JWT access tokens**
   (`RefreshToken.for_user(...)`) instead of `force_authenticate`, so they
   exercise the code under test rather than bypass it.

**How SUPER_ADMIN supplies the tenant** (fail-closed if omitted or unknown):
- writes (POST/PUT/PATCH): a `tenant` field in the JSON body
- reads (GET): a `?tenant=<id>` query parameter

**Files changed:**
- **`core/tenant_resolution.py` (new)** — shared, documented resolver; the
  only place SUPER_ADMIN's explicit tenant is interpreted.
- **`core/authentication.py`** — `TenantJWTAuthentication` now sets
  `request.tenant` from the resolver (was: blindly `user.tenant`, i.e. `None`).
- **`middleware/tenant.py`** — reverted to the minimal "user's own tenant"
  behaviour; its SUPER_ADMIN branch is now dead and pointed at the auth class.
- **`core/exceptions.py`** — added an `IntegrityError` → **400 JSON** handler
  (logged server-side, stable generic message to the client). This turns the
  residual NOT NULL / unique-constraint violations into clean JSON instead of a
  500 that leaks the schema — and it is also the mechanism for Fix #6.

**Regression test.** `tests/api/test_superadmin_tenant.py` (9 tests, real JWT):
- SUPER_ADMIN creates customer / venue / booking with an explicit tenant → 201,
  and the row lands in that tenant.
- SUPER_ADMIN lists scoped by `?tenant=` → sees the data; without the param →
  empty (no accidental cross-tenant leak).
- Tenant Owner create unaffected; an Owner cannot smuggle another tenant's id
  via the payload (own tenant wins).
- Fail-closed pair in a `TransactionTestCase` (deliberate: an IntegrityError
  marks `TestCase`'s per-test atomic for rollback, which would poison the
  connection and mask the real assertion): missing tenant and unknown tenant
  both return **400 JSON, never 500**, and create no row.

**Verification.**
- Regression file: **9/9 pass** with real tokens.
- Full backend suite: **412 passed, 1 skipped, 11 xfailed, 56 subtests** —
  identical skip/xfail counts to the pre-fix baseline (396 + 16 new). Zero
  regressions from an auth-class change that touches every request.
- Live QA API (Django 5.2), as the real `qa-superadmin` fixture:
  1. `GET /customers/?tenant=1` → **count 20** (was 0).
  2. `POST /customers/ {tenant:1}` → **201** (was 500).
  3. `POST /venues/ {tenant:1}` → **201** (was 500).
  4. `POST /customers/` *without* tenant → **400 JSON** (was 500 + HTML).
  5. Owner `POST /customers/` (regression) → **201**.
  Probe rows cleaned up (soft-delete 204).

### Fix #5 · P1 · Horizontal overflow on mobile/tablet · ✅ PASS

**Root cause.** Both authed shells wrap their content column in a
row-direction flex parent:

```jsx
<div className="flex min-h-screen">
  <AppSidebar />
  <div className="flex flex-1 flex-col md:pl-64">   {/* no min-w-0 */}
```

A flex item's default `min-width: auto` stops it shrinking below its content's
intrinsic width, so the ~744 px bookings table dragged the whole page past the
viewport instead of scrolling inside its own box.

| Viewport | scrollWidth | clientWidth | Overflow |
|---|---|---|---|
| 375 px | 778 → **360** | 360 | 418 px → **0** |
| 768 px | 1050 → **768** | 753 → 768 | 297 px → **0** |
| 1440 px | 1440 | 1440 | none (unchanged) |

**Change.** Added `min-w-0` to the content column in
`app/(dashboard)/layout.tsx` and `app/(admin)/layout.tsx`.

**Why not also `overflow-x-hidden`** (which the report offered as an option):
`DataTable.tsx:130` already wraps tables in `overflow-x-auto`, so once the
column is allowed to shrink the table scrolls *inside* its box and nothing is
clipped. `overflow-x-hidden` on the shell would instead hide any other
overflowing content (long unbroken strings, etc.) rather than making it
reachable — a worse trade. Confirmed empirically: at 375 px the page reports
`scrollWidth == clientWidth` **and** the table wrapper still fits its content
(326 == 326), so `min-w-0` alone was sufficient.

**Regression test.** `frontend/tests/responsive-layout.test.mjs` (Node 22
built-in runner, wired into `npm test`):
1. Both authed layouts exist.
2. Each declares `min-w-0` on the `flex ... flex-1 flex-col` content column.
3. Walks **every** `app/**/layout.tsx` and fails on any authed shell that still
   uses `flex-1 flex-col md:pl-64` without `min-w-0` — so a future layout
   cannot reintroduce the bug.

**Verification.**
- `npm test` → **10/10 pass** (7 prior + 3 new).
- `npm run build` → ✓ compiled, 69/69 pages.
- Live on `next start` (Chromium), logged in as Owner on `/bookings`:
  measured `documentElement.scrollWidth` vs `clientWidth` at 375 / 768 / 1440 →
  **overflow 0 at all three** (was 418 / 297 / 0 px). Screenshot:
  `qa-artifacts/logs/fix5-mobile-bookings-375.png` — hamburger + top nav +
  filters + table + bottom nav, no horizontal scrollbar.

### Fix #6 · P1 · Duplicate mobile / invoice IntegrityError 500s · ✅ PASS

**Root cause — two constraint violations that only the database noticed.**
1. `Customer` declares `unique_together = [("tenant", "mobile")]`, but nothing
   validated it before INSERT, so a duplicate `POST /customers/` reached the
   DB and surfaced as an HTML 500.
2. `Invoice.invoice_number` is `unique` **and** `read_only_fields` **and** has
   no model default — so a direct `POST /invoices/` wrote `""`, and the
   *second* create hit the unique constraint. (The `generate` action was fine:
   it went through `InvoiceService`, which called `generate_invoice_number()`.)

**What Fix #4 already contributed.** The `IntegrityError → 400 JSON` handler
added in `core/exceptions.py` during Fix #4 is the backstop: any residual
constraint violation now returns clean JSON instead of leaking a debug page.
But a generic message is a poor UX and hides *which* field was at fault, so
this fix adds the proper field-level validation that should fire first.

**Changes.**
- **`apps/customers/serializers.py`** — `validate_mobile()` checks
  `unique_together` up front, scoped to the caller's tenant, excluding `self`
  on update. Returns a field-level 400: `"A customer with this mobile number
  already exists."` Different tenants may still share a mobile.
- **`apps/invoices/serializers.py`** — `create()` now assigns
  `generate_invoice_number()` before insert, mirroring what `InvoiceService`
  already did on the `generate` path, so the direct create path is no longer
  the odd one out.
- **`utils/invoice_numbers.py`** — hardened the generator. The old
  `int(last.invoice_number.split("-")[-1])` would raise `ValueError` on any
  legacy row whose tail was not numeric (including the historical `""`
  default) — i.e. the very rows that caused this bug. It now skips
  non-numeric tails.

**One pre-existing test was flipped, deliberately.**
`tests/preprod/test_data_validation.py::test_duplicate_mobile_in_tenant_rejected`
was decorated `@expectedFailure` and docstringed "KNOWN GAP", because it
*asserted the correct 400 behaviour that did not yet exist*. Closing the gap
made it "unexpectedly succeed" (pytest reported the xfail count dropping
11 → 10). I removed the `@expectedFailure` and updated the docstring rather
than leaving a green-but-xfail lie. No assertion was weakened — the test's
original expectations (400 JSON + only one row persisted) now simply pass.

**Regression test.** `tests/api/test_duplicate_constraints.py` (6 tests):
- duplicate mobile in the same tenant → **400** with `errors.mobile`, one row;
- the same mobile in a *different* tenant → **201** (constraint is per-tenant);
- PATCHing a customer onto a taken mobile → **400**;
- two direct invoice creates → both **201**, non-empty **and distinct**
  `invoice_number`s, and sequential (`…-000001`, `…-000002`);
- the generator tolerates a legacy row with `invoice_number=""`.
The invoice tests use `TransactionTestCase` for the same atomic-poisoning
reason documented in Fix #4.

**Verification.**
- Regression file: **6/6 pass**.
- Full backend suite: **419 passed, 1 skipped, 10 xfailed** (xfail 11 → 10 is
  the intentional flip above), 56 subtests. Zero regressions.
- Live QA API, as the real Owner fixture:
  1. `POST /customers/` mobile `9111111111` → **201**; second identical →
     **400** `{"errors":{"mobile":["A customer with this mobile number
     already exists."]}}` (was 500).
  2. Two `POST /invoices/` for the same booking → **201 / 201** with
     `INV-2026-000001` then `INV-2026-000002` (second was a 500).
  Probe customer cleaned up (204). Two probe invoices remain on QA booking 3:
  Owner correctly gets **403** on `DELETE /invoices/{id}` (no `invoices.destroy`
  in `ModuleAccessPermission`) — that is correct RBAC, not a defect, so I did
  not force-delete around it.

### Fix #7 · P1 · No restore procedure / no off-site backup · ✅ PASS

**Two of the three sub-claims were real. The third was not.**

1. **No restore script — REAL.** `deploy/scripts/` had `backup.sh`,
   `crontab.txt` and `smoke_test.sh`, but nothing to restore with. A backup
   nobody has rehearsed restoring is not a recovery plan.
2. **Backups not copied off the host — REAL.** `backup.sh` wrote everything to
   `/home/eventflow/backups` on the same box, so a host loss took the backups
   with the data.
3. **"`cron-jobs.sh` schedules no backup job" — INACCURATE.** There is no
   `cron-jobs.sh` in the repo. The real file, `deploy/scripts/crontab.txt`,
   **does** schedule it (line 29: `0 2 * * * …/backup.sh`). I am recording
   this rather than "fixing" a non-existent gap, and pinned the scheduling in
   the regression test so it cannot regress unnoticed.

**Changes.**
- **`deploy/scripts/restore.sh` (new)** — the missing counterpart. `--list`,
  `--verify`, `--restore-to <db>`, `--restore-media`, `--dry-run`, `--yes`.
  Written to be *rehearsed*, not just written: integrity-checks the archive
  (`gzip -t` + confirms a `.sql.gz` actually decompresses to SQL) **before**
  touching anything, and refuses a live restore without `--yes` (exit 2), so a
  fat-fingered invocation cannot wipe production. Prints a post-restore
  checklist.
- **`deploy/scripts/backup.sh`** — added step 7, an optional off-site rsync to
  `OFFSITE_REMOTE`. A failed copy exits non-zero so cron's mail/monitoring
  sees it, but never rolls back the local backup that already succeeded. When
  `OFFSITE_REMOTE` is unset it warns loudly that backups exist only on that
  host — silent single-host backups are the failure mode this whole item is
  about.

**Rehearsed, not just written.** Local MySQL needed sudo credentials, which I
did not use (policy: no sudo without approval), so I exercised the full script
logic against scratch archives in `/tmp/opencode/restore-rehearsal` with
`MYSQL_BIN` pointed at a stub that consumes stdin exactly as `mysql -u user db`
does and writes it out for diffing. Every path was run for real:

| Step | Result |
|---|---|
| `--list` | lists daily + weekly archives |
| `--verify` on a good `.sql.gz` | OK, exit 0 |
| `--verify` on a deliberately corrupted archive | `integrity check FAILED`, **exit 3** |
| `--dry-run --restore-to` | reports the command + uncompressed size, exit 0, no `--yes` needed |
| real restore **without** `--yes` | **REFUSED, exit 2** — nothing written |
| real restore **with** `--yes` | exit 0; `gunzip \| mysql` output **byte-identical** to the source dump (`diff` clean) |

The one thing not exercised is the real `mysql` binary accepting the pipe —
standard behaviour, identical to the stub's stdin consumption. A production
rehearsal into a scratch database is still the operator's job (the script
prints the checklist for exactly that).

**Regression test.** `backend/tests/unit/test_backup_restore_scripts.py`
(6 tests): both scripts parse (`bash -n`); `restore.sh` exists and is
executable; the destructive path requires `--yes` and verifies integrity
*before* writing (asserted by source order, not just presence); `backup.sh`
has the off-site copy and fails loudly; and `crontab.txt` still schedules the
daily 02:00 backup — pinning the claim the report got wrong.

**Verification.** `pytest tests/unit/test_backup_restore_scripts.py` →
**6/6 pass**; `bash -n` clean on both scripts; `chmod +x` applied.

### Fix #8 · P1 · Dead entries in the permission matrix · ✅ PASS

**Root cause.** `MODULE_PERMISSIONS` is a static allow-list keyed by
`module_name` → `action` → roles, and `ModuleAccessPermission.has_permission`
does `module_perms.get(action, [])` then `role in allowed`. Nothing ever
checked that a declared key corresponded to a real DRF action, so the matrix
drifted: it advertised access to routes that do not exist. The report found
**three** (`reports.financial`, `reports.operational`, `reports.subscription` —
none of which `ReportViewSet` defines). Writing the general drift check
surfaced **two more of the identical defect**:

- `tenants.settings` → `TenantViewSet.tenant_settings` is a plain method with
  **no `@action`**, so it is not routed at all.
- `settings.read` → `SettingsViewSet` is a `GenericViewSet` with no
  list/retrieve and no `@action` named `read`.

All five 404'd for every role, including the roles they granted. Fail-closed,
so not a security hole — but matrix drift that would mislead an access-control
audit, which is exactly what this project's QA is for.

**Change.** Removed the five dead keys. Zero functional impact: the routes
404 before and after, and nothing in the frontend or backend referenced them
(verified by grep).

**Why a general test rather than "assert those three are gone."** The user
asked for a regression test that *would have caught the original bug*. Checking
three strings catches three strings; checking the matrix against the live
router catches the next one. `tests/unit/test_permission_matrix_drift.py`
(5 tests) builds `module_name → set(action)` from `api_router.registry` +
`get_extra_actions()` and fails on any declared key that is not routed.

Two subtleties that mattered, and one deliberate omission:
- Extra actions must be compared by method `__name__` (`mark_in_progress`),
  which is what `view.action` carries — **not** the router's `url_name`
  (`mark-in-progress`), which is hyphenated. Using `url_name` produced a wall
  of false positives.
- `dashboard` is served by a plain `APIView`, not a router ViewSet, so it has
  no registry entry. It is in an explicit `NON_VIEWSET_MODULES` allow-list
  that the test itself asserts is still accurate, so it cannot rot into a
  blanket excuse.
- **The inverse drift was found and deliberately not "fixed".** A handful of
  routed extras are absent from the matrix (`tenants.activate/disable/suspend`,
  `payments.create_order/verify`), which means they are **denied** for every
  non-SUPER_ADMIN. That is fail-closed and therefore safe — the opposite of
  the dead-entry bug. *Granting* those is an access-control decision for a
  product owner, not a drift cleanup, so I left the permissions untouched and
  instead pinned the deny-by-default behaviour in
  `test_absent_matrix_keys_deny_by_default` so the posture is explicit.

**Verification.** `pytest tests/unit/test_permission_matrix_drift.py` →
**5/5 pass**. Full backend suite: **430 passed, 1 skipped, 10 xfailed**
(+11 from Fixes #4–#8), 56 subtests — zero regressions from removing the
matrix entries.

### Fix #9 · P2 · Logout did not revoke the access token · ✅ PASS

**Root cause.** `AuthService.logout` blacklisted only the **refresh** token
(`services/auth_service.py:137-138`). JWT access tokens are stateless, so the
bearer token presented on the logout request kept authenticating for the rest
of its 60-minute lifetime (`SIMPLE_JWT.ACCESS_TOKEN_LIFETIME`). A user who
"logged out" had not ended their session at all — which is precisely the
threat a stolen access token represents.

**The trap worth recording.** The obvious fix — call `.blacklist()` on the
access token — **does not work, and fails silently**. In simplejwt,
`BlacklistMixin` is mixed into `RefreshToken` only (`tokens.py:376`); plain
`AccessToken` is just `Token` (`tokens.py:371`) and has no `blacklist`
attribute. Even after writing a `BlacklistedToken` row, nothing would read it
back: the blacklist *check* lives in `BlacklistMixin.verify`
(`tokens.py:267-280`), which `AccessToken.__init__` never calls. My first
attempt hit exactly this — the write raised `AttributeError: 'AccessToken'
object has no attribute 'blacklist'`, which the defensive `except` swallowed
into a log line and a still-200 request. Both halves are required, or the fix
is theatre.

**Change.**
- `core/tokens.py` (new): `BlacklistCheckingAccessToken(BlacklistMixin,
  AccessToken)` — the missing half of simplejwt's design.
- `core/authentication.py`: override `get_validated_token` to validate with
  that subclass, so a revoked access token fails at token-validation time with
  the ordinary 401 `InvalidToken`, exactly like an expired one. No special-case
  branch in the auth path.
- `services/auth_service.py`: `logout(..., access_token=None)` blacklists the
  presented bearer token; `LogoutView._bearer_token` extracts it from the
  `Authorization` header. Blacklisting failure is logged, never raised — a
  broken blacklist write must not stop a logout, since the refresh token is
  still the authoritative session end.

**Deliberate scope.** Only the *presented* token is revoked. Sibling sessions
on other devices stay valid: logging out of one device should not terminate
every other session. A `tokens_revoked_at` timestamp on the user would have
killed all of them at once — simpler, but the wrong behaviour, so it was
rejected.

**Verification.** `tests/api/test_logout_revoke.py` (**3 pass**) — written
first and red (`200 != 401`) before the fix. Covers: access token dead after
logout; refresh replay still 401 (no regression); sibling session survives.
Full backend suite **433 passed, 1 skipped, 10 xfailed** (+3), zero
regressions — notable because `get_validated_token` now runs on every
authenticated request. Live against the QA instance: `200` before logout →
logout `200` → **`401` after**.

### Fix #10 · P2 · Mobile format was not validated server-side · ✅ PASS

**Root cause.** `core/validators.py:6` defined `validate_mobile` and **nothing
in the codebase ever called it** — not a serializer, not a model field. Every
model storing a mobile is a bare `CharField(max_length=30)` with no validators
(`customers`, `staff`, `tenants`, `users`, `vendors`). So the only bound was
30 characters, and `"mobile": "not-a-number-mgr"` was stored and returned
**201**. The sole format rule in the product lived in the frontend zod schema
(`frontend/app/(dashboard)/customers/new/page.tsx:24`), which is a client-side
convenience, not a boundary.

**Design decision worth recording.** The unused backend regex was
`^\+?[1-9]\d{9,14}$` (E.164, 10–15 digits). The frontend rule is
`^[0-9+\-\s()]{7,15}$`. The report said "move the frontend regex into the
serializer", and that is the right call *even though the backend regex is
stricter*, for one concrete reason: the UI submits `data.mobile` **exactly as
typed** (`page.tsx:49`) — spaces, dashes and parentheses intact, no
normalisation. Wiring the strict E.164 rule would have made the backend
reject `(987) 654-3210` and `+91 98765 43210`, i.e. input its own product's
form had already accepted as valid. A backend that rejects the frontend's own
valid input is a bug, not validation. The contract is now identical on both
sides; if the product later wants E.164, it should normalise on input and
migrate stored data, not silently disagree with its own UI.

**Change.** `validate_mobile` now implements the shared contract, and is wired
into all seven serializers exposing `mobile`: `customers` (called at the top of
the existing tenant-scoped uniqueness check), `staff`, `vendors`, `tenants`,
`users`, `settings` (`OrganizationSettings` + `Profile` + `User`), and
`authentication` (`Register` + `Profile`). ModelSerializers take it via
`extra_kwargs`, which replaces the inherited `MaxLengthValidator(30)` — the
regex already caps at 15, so it is strictly tighter. Optional mobiles are
unaffected: DRF skips field validators on empty values.

**Verification.** `tests/api/test_mobile_validation.py` → **6 passed, 10
subtests**. Covers the report's exact payload, junk across customers/staff/
vendors, every UI-accepted format still accepted and stored verbatim, too
short/too long, blank optional mobile, and registration. Two things this test
had to get right: the project's exception handler nests field errors under
`resp.data["errors"]`, not `resp.data`; and real JWTs are required, because
`force_authenticate` bypasses `TenantJWTAuthentication` and leaves
`request.tenant` unset while `perform_create` does
`serializer.save(tenant=self.request.tenant)`.
Full backend suite **439 passed, 1 skipped, 10 xfailed** (+6), 66 subtests
(+10) — no fixture regressed, since existing test mobiles are all 10-digit.
Live: `"not-a-number-mgr"` → **400** with `errors.mobile` (was 201);
`"+91 98765 43210"` → **201**, stored as typed. Probe deleted (204 → 404).

### Fix #11 · P2 · User hard-delete had no guard, no confirmation, no audit · ✅ PASS

**Root cause.** `UserViewSet` was a plain `viewsets.ModelViewSet`
(`apps/users/views.py:14`), so `destroy` ran DRF's default `instance.delete()`
directly. Three things were missing at once:
- **No confirmation** — the QA harness's automated RBAC sweep issued
  `DELETE /users/1/` and destroyed the Owner fixture (the report's own
  harness incident).
- **No OWNER guard** — `SettingsService.delete_user` already refuses to delete
  an Owner, but `UserViewSet` never called it.
- **No audit row** — the deletion left no trace in `audit_logs`.

**Why hard delete stays.** Customers, staff, venues and expenses soft-delete
via `BaseRepository.delete`, which flips `is_deleted` when the model has that
field (`repositories/base.py:69-76`). `User` has no `is_deleted`, so it takes
the `instance.delete()` branch. That is defensible and I kept it: a user row
carries a password hash, so a "deleted" user lingering in the table is worse
for GDPR than a real removal. The missing piece was the *trail*, not the
delete semantics. Making users soft-delete would need a migration plus
`is_deleted` filtering in `get_queryset` and the auth path — a much larger
blast radius for a P2.

**Change.**
- `services/user_service.py::delete_user` (new): OWNER guard, self-delete
  guard, then hard delete, then an audit row (`module=USERS`,
  `action=DELETE`, `record_id=<id>`, `old_data` snapshot of email/full_name/
  role). Mirrors the logic that already existed in `SettingsService.delete_user`,
  which `UserViewSet` was bypassing entirely.
- `apps/users/views.py::destroy` (override): requires `confirm` (query param
  or body) to equal the target's email, case-insensitively. A blind
  `DELETE /users/1/` now 400s with a message explaining what to send.

**Two details that mattered.**
- `AuditLog.user` is `SET_NULL`, not `CASCADE` — so the row survives the
  deletion it records. Had it been CASCADE, writing the log and then deleting
  the user would have erased the evidence. Worth knowing before relying on it.
- The identity snapshot is captured *before* the delete and stored in
  `old_data`, because once the row is gone the `user` FK is NULL and
  `record_id` is only an integer.

**No frontend impact.** There is no `users` page under
`frontend/app/(dashboard)/`, so nothing in the UI calls this endpoint and the
new required parameter breaks no existing caller.

**Verification.** `tests/api/test_user_delete_guard.py` → **7 passed**:
no confirm → 400 and user survives; wrong confirm → 400; correct confirm →
deleted plus audit row asserting tenant, actor, `record_id` and identity
snapshot; case-insensitive confirm; Owner undeletable; MANAGER blocked 403 by
the permission matrix *before* the guard (pinned separately); SUPER_ADMIN
blocked from self-delete. Full backend suite **446 passed, 1 skipped, 10
xfailed** (+7), zero regressions.
Live: no confirm → **400** with the explanatory message; wrong confirm →
**400**; user still present (**200**); correct confirm → **200**; then
**404**. Audit row `id=137` recorded `USERS/DELETE record_id=7` with the
identity snapshot.

### Fix #12 · P3 · Unknown API routes returned HTML 404 · ✅ PASS

**Root cause.** `config/urls.py` mounted only
`path("api/v1/", include(api_router.urls))`. Any `/api/v1/...` path the router
did not match fell through to Django's default 404 handler, which renders an
HTML page. An axios-style JSON client then failed parsing the body before it
ever read the status code, turning a clean 404 into an opaque parse error.

**Change.** `core/api_errors.py::api_not_found` returns a `JsonResponse` in
the project's envelope (`{"success": false, "message", "errors"}`), and
`config/urls.py` registers it as `path("api/v1/<path:unmatched>", ...)` —
placed **after** `include(api_router.urls)` so it can only catch paths the
router did not match. Being scoped to the `api/v1/` prefix, `/admin/` and the
rest of the site keep Django's HTML 404, which is the correct behaviour for a
browser.

A global `handler404` was rejected: it would have forced JSON onto HTML pages
and required path-prefix branching inside the error handler to undo that.

**Pre-existing tests that pinned the bug.** `tests/preprod/test_api_contract.py`
carried three `@unittest.expectedFailure` markers labelled `KNOWN GAP
P2-API-01/02` — written to fail *until* this gap closed — plus
`test_unknown_api_route_actually_returns_html_404`, which asserted the buggy
content type as "today's behaviour". Fixing the bug necessarily changes what
these assert, so: the three expected-failure markers were removed (the gap is
closed) and the bug-pinning test was deleted, since
`test_unknown_api_route_is_json_404` now covers the correct behaviour with a
stronger assertion. No assertion was weakened to make anything pass. The
now-unused `import unittest` was dropped alongside.

**Verification.** `tests/unit/test_api_json_404.py` → **6 passed, 5
subtests**: unknown route, unknown nested route, every HTTP method, real
routes not shadowed (a 404 there would mean the catch-all sits in front of the
router), non-API 404 still `text/html`, and no debug detail leaked. Full
backend suite **454 passed, 1 skipped, 7 xfailed** — xfailed falls 10 → 7 as
those three gaps closed. Live: unknown API route → **404
`application/json`**; `/api/v1/reports/` → **404 JSON**; `/api/v1/customers/`
→ **401 JSON** (router still answering); `/nope/` → **404 text/html**
(unchanged).

---

## Overall result

All 12 fixes from `QA-TEST-REPORT.md` and `QA-TEST-REPORT-ROLES.md` are
implemented, each with a regression test that fails without the fix, and each
verified live against the QA instance where applicable.

| Priority | Fixed | Live-verified |
|----------|-------|---------------|
| P0 | 3 (#1, #2, #3) | #1 |
| P1 | 5 (#4, #5, #6, #7, #8) | #4, #5, #6 |
| P2 | 3 (#9, #10, #11) | #9, #10, #11 |
| P3 | 1 (#12) | #12 |

**Backend suite:** 396 → **454 passed**, 1 skipped, xfailed 11 → 7 (four
documented gaps closed). **Frontend:** 7 → **10** tests.

### Follow-ups deliberately NOT done here (out of scope, needs a decision)
1. **Tailwind 3 → 4.** 9 of the remaining 9 frontend advisories are dev-only
   and come from the Tailwind 3 toolchain. Migrating is a styling-toolchain
   change, not a security patch; production `--omit=dev` is already clean.
2. **Undeclared extra actions** (`tenants.activate/disable/suspend`,
   `payments.create_order/verify`) are absent from the permission matrix and
   therefore denied to everyone but SUPER_ADMIN. Fail-closed and safe, but
   whether those routes *should* be role-granted is a product decision.
3. **`SettingsService.delete_user` vs `UserService.delete_user`.** The guard +
   audit logic now exists in both. Not consolidated, because doing so would
   change the settings module's behaviour outside this task's scope.
4. **`deploy/scripts/crontab.txt:29` does schedule `backup.sh`.** The QA
   report's claim that no backup job is scheduled was inaccurate; the off-site
   copy in Fix #7 is opt-in via `OFFSITE_REMOTE` and must be configured on the
   real host.

### Final 4-role smoke test · 30/30 PASS

Run against the live QA instance after all 12 fixes.

| Role | Checks | Result |
|------|--------|--------|
| STAFF | login, JSON 404, customers correctly 403 by RBAC, reads its own module, logout revokes token | 5/5 |
| MANAGER | login, JSON 404, bad mobile 400, list 200, logout revokes token | 5/5 |
| OWNER | login, JSON 404, bad mobile 400, list 200, logout revokes token | 5/5 |
| SUPER_ADMIN | login, JSON 404, bad mobile 400, list 200, logout revokes token | 5/5 |
| Fix #4 | sees tenant-1 customers (21), create with explicit tenant 201, cleanup delete 204, create without tenant 400 fail-closed | 4/4 |
| Fix #11 | create probe, no confirm 400, wrong confirm 400, still present, correct confirm 200, then 404 | 6/6 |

Two smoke-script assertions were wrong on the first run and were corrected —
neither was a product defect:
- STAFF was expected to get 400 on a bad mobile, but RBAC denies `customers`
  to STAFF before serializer validation, so it correctly gets **403**.
  STAFF reading `/bookings/` returns 200, confirming it is not simply blocked.
- The SUPER `?tenant=1` count was read from the project's envelope key
  (`pagination.total_records`), but list endpoints paginate with DRF's default
  `count`/`results`. Real count: **21**. Relatedly, SUPER must carry
  `?tenant=` on a `DELETE` too — without it `get_queryset` is scoped to
  `tenant=None` and returns 404, which is correct.

