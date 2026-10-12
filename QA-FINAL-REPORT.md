# EventFlow — Final Pre-Production QA Report

**Date:** 2026-10-11
**Branch:** `audit/fixes`
**Scope:** Full 120-test re-run (Owner 40 + STAFF 20 + MANAGER 20 + SUPER_ADMIN 40),
plus pre-run sanity and a deep re-verification of all 12 fixes.

---

## Verdict: **GO-WITH-CAVEATS**

**122 PASS / 10 PARTIAL / 0 FAIL** across 120 tests and 12 fix deep-checks.

All 12 blockers from the original NO-GO are fixed and re-verified. No
regressions were introduced by the fixes. The 10 PARTIALs are environment or
product-scope limitations, not defects — none of them block release.

---

## Headline numbers

| Metric | Before | After |
|--------|--------|-------|
| Backend pytest | 396 passed, 11 xfailed | **454 passed, 7 xfailed** (462 collected) |
| Frontend tests | 10 passed | 10 passed |
| `pip-audit` | 85 vulnerabilities | **0** |
| `npm audit --production` | 9 vulnerabilities | **0** |
| Django | 4.2 (EOL) | **5.2.18 LTS** |
| Frontend route collisions | build-blocking `EEXIST` | **0** |
| Mobile overflow @375px | 418px | **0** |
| Dead permission-matrix entries | 5 | **0** |
| Logout token revocation | access token survived logout | **revoked (401)** |
| Unknown `/api/v1/*` 404 | HTML debug page | **JSON envelope** |

Backend: `454 passed, 1 skipped, 7 xfailed, 71 subtests`.
Frontend: `10/10`.

---

## Phase 1 — Pre-run sanity (6 checks)

| # | Check | Verdict |
|---|-------|---------|
| 1 | `pip-audit` 0 vulnerabilities | PASS |
| 2 | `npm audit --production` 0 vulnerabilities | PASS |
| 3 | Django 5.2.18 + `manage.py check` clean | PASS |
| 4 | 462 tests collect | PASS |
| 5 | Django :8000 / Next :3000 both listening | PASS |
| 6 | Migrations: 1 pending found → inspected → applied | FAIL→REMEDIATED |

**Incident (resolved before the suite started):** one unapplied migration,
`token_blacklist.0013_alter_blacklistedtoken_options_and_more`. Inspected before
acting — it contains only two `AlterModelOptions` operations (verbose names and
a default `ordering`), **no schema change and no data change**. It is metadata
Django emits for the simplejwt version pinned during Fix #2, and belongs to the
token-blacklist app that Fix #9 relies on. Applied; re-checked at **92 applied,
0 pending**.

---

## Phase 2 — Full 120-test re-run

| Role | n | PASS | PARTIAL | FAIL |
|------|---|------|---------|------|
| Owner | 40 | 35 | 5 | **0** |
| STAFF | 20 | 20 | 0 | **0** |
| MANAGER | 20 | 20 | 0 | **0** |
| SUPER_ADMIN | 40 | 35 | 5 | **0** |
| **Total** | **120** | **110** | **10** | **0** |

### RBAC verified live against the declared matrix

The permission posture was not assumed — every allowed and denied surface was
hit with a real request per role and compared against `MODULE_PERMISSIONS`:

| Role | Allowed surfaces reached | Denied surfaces returned 403 |
|------|--------------------------|------------------------------|
| STAFF | 11/11 | 15/15 |
| MANAGER | 20/20 | 9/9 |
| SUPER_ADMIN | all privileged surfaces reachable | fail-closed without `?tenant=` |

Privilege-escalation attempts (`POST /tenants/`, `POST /users/` with
`role=OWNER`, `POST /staff/`) returned **403 for STAFF, MANAGER and
SUPER_ADMIN-without-tenant** in every case tested.

Logout revokes the access token for **all four roles** (`logout=200`, then the
old Bearer token returns **401**).

### The 10 PARTIALs — all environment or scope limits

| Test | Why PARTIAL |
|------|-------------|
| Scalability (Owner + Super) | single-process `runserver`; HA / multi-worker not exercised |
| Rate Limiting (Owner + Super) | throttle active on bad login; `Retry-After` header not emitted, and throttling is not enforced under the dev server |
| Cross-Browser (Owner + Super) | Chromium only in this environment; Firefox/WebKit need a manual plan |
| Localization (Owner + Super) | en-IN currency/date formatting only; no i18n framework or locale switch |
| Third-Party (Owner) | Razorpay / Twilio / WhatsApp gated on tenant settings; no live credentials in the QA environment |
| UI/UX (Super) | no `/tenants` page in the frontend — **the one product-scope gap noted below** |

None of these is a regression, and none blocks release.

---

## Phase 3 — Fix deep-checks (12/12 PASS)

Every fix was re-verified in isolation *after* the full re-run, so a green
suite could not mask a fix that had quietly broken.

| Fix | Area | Result |
|-----|------|--------|
| 1 | New-X `generateStaticParams` collision | PASS — all 12 `/new` routes return 200 |
| 2 | Django 5.2.18 LTS + dependency pins | PASS — 5.2.18, `pip-audit` 0 |
| 3 | Next 16 build + prod deps | PASS — `:3000` pages 200, prod audit 0 |
| 4 | SUPER_ADMIN create with `?tenant=` | PASS — tenant 201, customer 201 |
| 5 | `min-w-0` responsive overflow | PASS — 15 checks (5 pages × 3 viewports), overflow 0 |
| 6 | Duplicate mobile → 400 JSON | PASS — was a 500 |
| 7 | `restore.sh` + dry-run | PASS — syntax valid, `--list` runs |
| 8 | Permission-matrix drift | PASS — 0 dead entries (5 found and removed, not the 3 originally reported) |
| 9 | Logout revokes access token | PASS — all 4 roles `200` then `401` |
| 10 | Mobile validation accepts UI formats | PASS — `+91 98765 43211`, `+919876543211`, `09876543211` all 201; garbage → 400 |
| 11 | User delete guard + audit trail | PASS — no/wrong confirm 400, correct 200, then 404; `DELETE` present in audit |
| 12 | JSON 404 for unknown API routes | PASS — 404 + `application/json` + `success:false` |

---

## Caveats (non-blocking, carry into release)

1. **No `/tenants` page in the frontend.** SUPER_ADMIN can manage tenants via
   the API (create/list/update all verified) but there is no UI surface. The
   only frontend gap found in this run.
2. **Tailwind is still v3** (not v4). No functional impact; noted for a future
   upgrade.
3. **Extra-action grants not declared in the matrix:** `tenants.activate` /
   `disable` / `suspend` and `payments.create_order` / `verify` are reachable
   but absent from `MODULE_PERMISSIONS`. They fail closed by default (the
   inverse-drift test documents this posture) — the matrix should be brought in
   line so an access-control audit reads true.
4. **Duplicate delete-guard logic** lives in both the settings service and the
   users service. Harmless today; consolidate to one owner.
5. **`OFFSITE_REMOTE` backup target is config-only** — the off-site copy is not
   exercised in the QA environment.
6. **Report inaccuracy corrected during this run:** `deploy/scripts/crontab.txt:29`
   *does* schedule `backup.sh`, contradicting the original report; and 5 dead
   matrix entries were found, not the 3 originally reported.

---

## Known-good baseline to protect

- Backend **454 passed / 7 xfailed**; frontend **10/10**.
- `pip-audit` **0**, `npm audit --production` **0**.
- **92 migrations applied, 0 pending.**
- `health` / `ready` / `live` all **200**.
- All 12 `/new` routes **200**; zero horizontal overflow at 375/768/1440px.

Any future change that moves one of these numbers is a regression.

---

## Sign-off

**GO-WITH-CAVEATS.** Safe for production release. The 10 PARTIALs are
environment or product-scope limitations and the 6 caveats above are
non-blocking follow-ups.

Tagged `qa-pass-2026-10-11` → commit `9103586` on `audit/fixes` (239 files:
the 12 fixes, their regression tests, `restore.sh`, and the QA reports).
Not pushed. The tag was created only after the fixes were committed, so it
certifies the fixed code rather than the pre-fix `db65e27`.

---
*Web QA complete. Mobile handoff ready.*
