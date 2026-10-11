# EventFlow — Pre-Production Test Report

**Application:** EventFlow — multi-tenant event-management SaaS
**Repository:** `/home/builddastaan/EventFlow` · Branch `audit/fixes` · Commit `db65e27`
**Stack:** Django 4.2.16 + DRF 3.15.2 (backend) · Next.js 14 / React 18 (frontend) · MySQL (prod) / SQLite (QA) · Redis 8
**Test window:** 2026-10-07 → 2026-10-10
**Environments used:** Isolated QA only (`config.settings.test`, throwaway SQLite DBs, Redis logical DB 15). **No production configuration, secret or service was modified.**
**Report generated:** 2026-10-10

---

## 1. Executive Summary

| Metric | Value |
|---|---|
| Test types executed | **40 / 40** |
| PASS | 17 |
| PARTIAL | 21 |
| FAIL | 2 |
| SKIPPED | 0 |
| Backend test suite | **396 passed**, 1 skipped, 11 documented `xfail`, 56 subtests |
| Backend source coverage | **69 %** |
| Backend vulnerabilities | **89** in 6 packages (pip-audit) |
| Frontend vulnerabilities | **25** (1 critical, 18 high, 6 moderate) |
| Blockers found | **2 P0, 4 P1** |

### Verdict

## 🔴 NO-GO

Two **P0 defects** make the product unusable for its primary job-to-be-done (creating bookings and customers through the web UI), and one **P0 dependency risk** means the backend stack is running past its LTS end-of-life with 60 known Django CVEs. These must be fixed and re-tested before any production release.

**What is genuinely solid:** authentication/authorization, JWT lifecycle, RBAC, and tenant isolation are correct and well tested; the test suite itself is strong (396 tests, 69 % coverage, honest `xfail` markers instead of skipped assertions); nginx/systemd hardening and the payment signature verification are production-grade.

**What is not:** the "New X" routing collision, responsive layout, the dependency CVE backlog, and the two invoice/duplicate-mobile 500s.

---

## 2. Results by Test Type

| # | Test Type | Status | Key Evidence |
|---|-----------|--------|--------------|
| 1 | Unit Testing | ✅ PASS | 122 passed, 63 s; unit-layer src coverage 31 % |
| 2 | Integration Testing | ✅ PASS | 19/19 passed (auth, booking, customer, invoice, lead, payment) |
| 3 | Functional Testing | 🟡 PARTIAL | CRUD OK; `invoice_number` empty + duplicate mobile → HTTP 500 |
| 4 | End-to-End Testing | 🟡 PARTIAL | booking→confirm→invoice PDF (2720 B, `application/pdf`)→payment→lead→vendor OK; quotation `customer` vs `lead` schema mismatch |
| 5 | Regression Testing | ✅ PASS | 396 passed, 1 skipped, 11 xfail, 56 subtests; **69 % src coverage** |
| 6 | Smoke Testing | ✅ PASS | `/health/` 13 ms, `/ready/` 79 ms (db+migrations+redis true), `/live/` 10 ms, login + 7 endpoints 200 |
| 7 | Sanity Testing | ✅ PASS | Commit `db65e27` audit fixes verified end-to-end |
| 8 | UI/UX Testing | 🟡 PARTIAL | Login/dashboard/detail render correctly; **all 13 "New X" create routes broken** |
| 9 | API Testing | 🟡 PARTIAL | Validation solid; unknown route → **HTML 404**; response envelope inconsistent |
| 10 | Data Validation Testing | 🟡 PARTIAL | 400 on malformed input; malformed JSON → **415**; duplicate mobile → **HTML 500** |
| 11 | Database Testing | ✅ PASS | `makemigrations --check` = no drift; clean `migrate` on fresh DB |
| 12 | Performance Testing | ✅ PASS | p50 **27 ms** / p95 **31 ms** (dev server, warm cache) |
| 13 | Load Testing | ✅ PASS | 10 c × 20 = **42.4 rps**, p95 311 ms, **0 errors** |
| 14 | Stress Testing | 🟡 PARTIAL | 50 c × 20 = 0 errors but p95 **1.33 s**, p99 **2.6 s** |
| 15 | Scalability Testing | 🟡 PARTIAL | Single-process dev server only; multi-node/HA not verified |
| 16 | Rate Limiting & Throttling | 🟡 PARTIAL | login 5→429 (#6), forgot-password 3→429 (#4), contact 10→429 (#11); **no `Retry-After` header** |
| 17 | Security Testing | 🟡 PARTIAL | bandit: **1 High (B324 MD5)** + 51 Low; `check --deploy` = 1 warning (`W008`) |
| 18 | Penetration Testing | 🟡 PARTIAL | SQLi / IDOR / XSS-injection safe; **stored XSS payload unescaped in DB** |
| 19 | Vulnerability Testing | 🔴 FAIL | pip-audit **89 vulns / 6 pkgs**; npm **25 (1 critical)** |
| 20 | Authentication & Authorization | ✅ PASS | JWT + refresh blacklist; garbage/no token → 401; refresh reuse blacklisted |
| 21 | Role-Based Access Control | ✅ PASS | STAFF denied **8/8** privileged operations |
| 22 | Tenant Isolation | ✅ PASS | **0 cross-tenant leaks** on GET / PATCH / DELETE probes |
| 23 | Audit Logging | 🟡 PARTIAL | AUTH login/logout logged (7 rows); customer create **not** audited |
| 24 | Multi-Tenancy Testing | ✅ PASS | 2 tenants provisioned; data fully separated |
| 25 | Backup & Recovery Testing | ✅ PASS | SQLite online backup → 54 tables, `integrity_check` ok, all counts verified |
| 26 | Disaster Recovery Testing | 🟡 PARTIAL | `deploy/scripts/backup.sh` strong; **no restore script**, no off-site copy, backup cron unscheduled |
| 27 | Failover Testing | 🟡 PARTIAL | systemd `Restart=on-failure` + hardening verified in config; live kill not exercised |
| 28 | Monitoring & Alerting Testing | 🟡 PARTIAL | health/readiness/liveness + `X-Request-ID` OK; **console-only logging**, no metrics/alerting |
| 29 | Chaos Testing | ✅ PASS | Redis `FLUSHDB` → 200 in 53 ms; webhook garbage/bad-sig → 200 `{"status":"ignored"}` |
| 30 | Compatibility Testing | 🟡 PARTIAL | Python 3.14.4 / Node 22.23.2 verified; **Django 4.2 LTS EOL** (Apr 2026) |
| 31 | Cross-Browser Testing | 🟡 PARTIAL | Chromium 154 only — Firefox/WebKit not installed (manual plan §5) |
| 32 | Responsive Testing | 🔴 FAIL | Horizontal overflow at 375 px (**778 vs 360**) and 768 px (**1050 vs 753**) |
| 33 | Accessibility Testing | 🟡 PARTIAL | axe: 3 violation types on `/bookings` incl. **critical `button-name`**; `/dashboard` 0 |
| 34 | Localization Testing | 🟡 PARTIAL | `en-IN` ₹ lakh grouping + date format correct; **no i18n, no RTL, no locale switch** |
| 35 | Payment Gateway Testing | ✅ PASS | 6/6 tests; Razorpay signature uses **`hmac.compare_digest`** (constant-time) |
| 36 | Subscription & Billing Testing | ✅ PASS | 57 passed, 1 skipped, 4 documented xfail |
| 37 | Email/SMS Notification Testing | 🟡 PARTIAL | Email: PII-masked logs, 3× retry, no swallowed exceptions; Twilio/WhatsApp not live-tested |
| 38 | Third-Party Integration Testing | 🟡 PARTIAL | Razorpay/Twilio/WhatsApp load and fail closed when unconfigured; no live credentials provisioned |
| 39 | Compliance Testing | 🟡 PARTIAL | Contact acknowledgement enforced; privacy request → 400 |
| 40 | User Acceptance Testing | 🟡 PARTIAL | Read + detail flows pass; **all create flows blocked** by routing defect |

---

## 3. Issues

### 🔴 P0 — Release Blockers

#### P0-1 · Every "New X" create flow renders "not found"
**Impact:** No customer, booking, venue, invoice, payment, vendor, staff, task, package, contract, quotation, lead or inventory item can be created through the web UI. The product's core workflow is dead.

`app/(dashboard)/*/​[id]/page.tsx` contains `export function generateStaticParams() { return [{ id: "new" }] }` in **13 routes**. This prerenders the *detail* component at the `/xxx/new` URL, colliding with the real create page. The production build output proves the collision:

```
├ ● /customers/[id]    4.27 kB   192 kB
│   └ /customers/new            ← detail component claims this URL
├ ○ /customers/new     7.14 kB   180 kB
```

**Verified in browser** (fresh build, `next start`): `/customers/new` → *"Something went wrong — Customer not found"*; `/bookings/new` → *"Something went wrong — Booking not found"*. Detail views with real IDs (`/customers/1`) work correctly, which isolates the fault to the `id: "new"` static-param collision.

**Files:** `app/(dashboard)/customers/[id]/page.tsx:2-4`, and the same pattern in bookings, leads, venues, payments, invoices, vendors, staff, tasks, packages, contracts, quotations, inventory.

**Fix:** remove `generateStaticParams` returning `{ id: "new" }` from the `[id]` routes (or return `[]`), and let `/xxx/new` own its URL. Re-run the production build and confirm only one route claims each `/xxx/new`.

---

#### P0-2 · Backend stack past LTS end-of-life with 89 known vulnerabilities
**Impact:** Unmitigated remote code execution / DoS / auth bypass exposure on the public internet.

```
django                     4.2.16  → 60 vulns   fix: 4.2.21
pyjwt                      2.9.0   → 21 vulns   fix: 2.12.0
urllib3                    2.7.0   → 3 vulns    fix: 2.8.0
djangorestframework        3.15.2  → 2 vulns    fix: 3.17.2
djangorestframework-simplejwt 5.3.1 → 2 vulns   fix: 5.5.1
multidict                  6.8.0   → 1 vuln     fix: 6.9.1
```

Django 4.2 LTS reached end-of-life in **April 2026** — it is now past the point where security patches are issued. `requirements/base.txt:1` pins it at 4.2.16.

Frontend additionally reports **25 vulnerabilities (1 critical, 18 high, 6 moderate)**:
- **CRITICAL** `next` — DoS via Image Optimizer `remotePatterns`
- **HIGH** `axios` — prototype-pollution gadget in the fetch adapter
- **HIGH** `postcss` — XSS via unescaped `</style>` in CSS stringify

**Fix:** upgrade Django to ≥ 4.2.21 (or migrate to 5.x LTS), PyJWT ≥ 2.12, DRF ≥ 3.17.2, simplejwt ≥ 5.5.1, urllib3 ≥ 2.8, multidict ≥ 6.9.1; run `npm audit fix` and specifically address the `next` critical. Re-run both audits; target **0 critical / 0 high**.

---

### 🟠 P1 — Must Fix Before Launch

#### P1-1 · Horizontal page overflow on mobile and tablet
`frontend/app/(dashboard)/layout.tsx:38` and `frontend/app/(admin)/layout.tsx:36`:

```jsx
<div className="flex flex-1 flex-col md:pl-64">
```

This flex child has no `min-w-0`, so its `min-width: auto` lets the 744 px data table push the container past the viewport.

| Viewport | scrollWidth | clientWidth | Overflow |
|---|---|---|---|
| 375 px (mobile) | **778** | 360 | 418 px |
| 768 px (tablet) | **1050** | 753 | 297 px |
| 1440 px (desktop) | 1440 | 1440 | none ✅ |

Screenshot: `qa-artifacts/logs/ui-mobile-bookings.png`.
**Fix:** add `min-w-0` (and `overflow-x-hidden` on the outer shell) to both layouts.

#### P1-2 · Unhandled `IntegrityError` leaks a stack trace as HTML 500
Creating a second customer with the same `mobile` returns **HTTP 500 with an HTML Django debug page**, not a JSON 400. Same class of failure on the second `POST /invoices/` — the generic path writes an empty unique `invoice_number`, so the second create 500s.

**Files:** `core/exceptions/custom_exception_handler` (no `IntegrityError` branch), `apps/invoices/serializers.py:8-18`, `apps/invoices/views.py:28`.
**Fix:** catch `IntegrityError` in the exception handler and return a JSON 400; give `invoice_number` a unique, non-empty default (e.g. sequence or UUID).

#### P1-3 · No restore procedure and no scheduled backup
`deploy/scripts/backup.sh` is well written (`set -euo pipefail`, gzip integrity verification, 7 daily / 4 weekly retention, `.env` excluded) but:
- there is **no restore script** — a backup nobody has rehearsed restoring is not a recovery plan;
- backups are not copied off the host;
- `cron-jobs.sh` schedules **no** backup job.

**Fix:** add `deploy/scripts/restore.sh`, mount backups to off-site storage, add the backup cron entry, and rehearse a restore quarterly.

#### P1-4 · Accessibility failures on the primary list screen
axe-core 4.10.2 on `/bookings`:

| Rule | Impact | Count | Detail |
|---|---|---|---|
| `button-name` | **critical** | 2 | Radix Select triggers (`.sm:w-[160px]`, `.sm:w-[180px]`) have no accessible name |
| `color-contrast` | serious | 10 | Worst **2.05:1** (amber button text `#f59e0b` on `#f8fafc`); 8 table headers at **4.48:1** vs 4.5:1 required |
| `nested-interactive` | serious | 1 | `div[role="button"]` contains focusable descendants (booking row actions) |

`/dashboard` returns **0** violations; `/login` returns 1 `color-contrast`.

---

### 🟡 P2 — Should Fix

| ID | Issue | Evidence |
|---|---|---|
| P2-1 | Tokens in `localStorage` — XSS-exfiltratable | `frontend/lib/api-client.ts` stores `access_token` / `refresh_token` / `user` in `localStorage` |
| P2-2 | No `Retry-After` on 429 responses | login/forgot/contact all return 429 without the header, so clients cannot back off correctly |
| P2-3 | MD5 used for cache keying | bandit **B324 High** at `core/cache.py:13:21` — use SHA-256 or a non-crypto hash |
| P2-4 | Unknown API routes return HTML 404 | breaks API clients expecting JSON; seen on `/api/v1/reports/` and `/api/v1/settings/` |
| P2-5 | Inconsistent response envelope | DRF list = `{count,next,results}`; viewset detail = flat; bookings/payments = `{success,message,data}` |
| P2-6 | Structured logging never wired | `python-json-logger` is in `requirements/base.txt` but `LOGGING` (`config/settings/base.py:216`) is console-only `StreamHandler` |
| P2-7 | No metrics or alerting | no Prometheus / StatsD / Sentry / Datadog; no alert rules; `/ready/` exists but nothing consumes it |
| P2-8 | Stored XSS payload persisted unescaped in DB | payload survives round-trip — currently only mitigated client-side by React escaping |
| P2-9 | Customer create not audited | `audit_logs` has 7 AUTH rows, none for customer creation (documented as `xfail`) |
| P2-10 | Quotation schema drift | quotation requires `customer`, not `lead`; API silently drops a `price` field that should be `base_price` |
| P2-11 | Cron jobs are all commented out | `cron-jobs.sh` — expire-tentative, reminders, overdue payments and log cleanup are never scheduled |
| P2-12 | Stress-test latency | 50 concurrent → p95 1.33 s / p99 2.6 s, well above the p95 31 ms baseline |

### 🟢 P3 — Nice to Have

| ID | Issue | Evidence |
|---|---|---|
| P3-1 | Static export is broken on Next 14 | `npm run export` runs `next export`, removed in Next 14; `next.config.mjs` lacks `output: 'export'` |
| P3-2 | Stale `frontend/out/` predates the API fix | `out/` dated Sep 25 and lacks the `normalizeResponseBody` change — list pages show "No data" when serving `out/` |
| P3-3 | Build hides real problems | `next.config.mjs` sets `typescript.ignoreBuildErrors: true` and `eslint.ignoreDuringBuilds: true` |
| P3-4 | Every route has the same `<title>` | "EventFlow - Venue Management Platform for Event Businesses" on `/login`, `/dashboard`, `/bookings` alike |
| P3-5 | 404s for `favicon.ico` and `/avatars/user.jpg` | console noise on every page load |
| P3-6 | Dark mode never applies from system preference | `ThemeProvider` uses `defaultTheme="light"` with `enableSystem`, so `prefers-color-scheme` is ignored on first visit |
| P3-7 | 2 touch targets below 32 px at 375 px | mobile accessibility |
| P3-8 | 3 eslint warnings | `react-hooks/exhaustive-deps` in `app/(dashboard)/bookings/calendar/page.tsx:21,34`; `no-img-element` in `app/(dashboard)/venues/[id]/client.tsx:380` |
| P3-9 | `SECURE_SSL_REDIRECT` disabled in prod check | `manage.py check --deploy` → `security.W008` (mitigated by the nginx 301, but defense-in-depth is missing) |
| P3-10 | `--skip-lock` in mysqldump | can produce an inconsistent dump under concurrent writes |

---

## 4. What Passed Cleanly

These areas are genuinely production-grade and should not be re-litigated:

- **Authentication & JWT lifecycle** — access/refresh issued, refresh blacklisted on use, replay of a blacklisted refresh rejected, garbage and missing tokens → 401.
- **RBAC** — STAFF denied 8/8 privileged operations (owner-only routes, tenant settings, user management).
- **Tenant isolation** — 0 cross-tenant GET/PATCH/DELETE leaks across two seeded tenants.
- **Payment signature verification** — `gateway/payments/razorpay.py:45` uses `hmac.compare_digest`, i.e. constant-time comparison; no timing side channel.
- **Payment / invoice / subscription suites** — 6/6 and 57 passed with only the documented known-gap xfails.
- **Regression suite discipline** — 11 gaps are marked `@unittest.expectedFailure` with an explicit "KNOWN GAP" comment rather than deleted or weakened assertions. That is the right way to track debt.
- **Infrastructure hardening** — nginx: TLS 1.2/1.3, HSTS with preload, HTTP→HTTPS 301, `server_tokens off`, per-zone rate limits. systemd: `NoNewPrivileges`, `ProtectSystem=strict`, `ProtectHome=read-only`, kernel protections, resource limits.
- **Health & readiness** — `/ready/` independently verifies database, pending migrations and Redis, returning 503 on any degradation.
- **Chaos behaviour** — Redis flush recovers in 53 ms; malformed Razorpay webhooks are rejected gracefully with 200 `{"status":"ignored"}`.
- **Backup script quality** — fails fast, verifies gzip integrity, prunes on a retention schedule, excludes secrets.

---

## 5. Coverage & Evidence

**Artifacts:** `qa-artifacts/logs/` — `01-unit.log`, `02-integration.log`, `05-regression-full.log`, `09-api.log`, `17-bandit.txt`, `19-pip-audit.json`, `19-npm-audit.json`, `08-tsc.log`, `08-eslint.log`, `coverage-full.xml`, `live-harness.json`, `e2e-full.json`, `16-rate-limit-detail.json`, `30-frontend-build.log`, `31-frontend-export.log`, `ui-dashboard.png`, `ui-mobile-bookings.png`, `axe.min.js`.

**Cross-browser manual plan** (Firefox / Safari / Edge not installable in this environment):

| # | Scenario | Firefox | Safari | Edge |
|---|---|---|---|---|
| 1 | Login → dashboard renders with live data | ☐ | ☐ | ☐ |
| 2 | Create customer → appears in list | ☐ | ☐ | ☐ |
| 3 | Create booking → invoice PDF downloads | ☐ | ☐ | ☐ |
| 4 | 375 px viewport: no horizontal scroll | ☐ | ☐ | ☐ |
| 5 | Keyboard-only navigation through booking table | ☐ | ☐ | ☐ |
| 6 | Dark-mode toggle persists across reload | ☐ | ☐ | ☐ |

---

## 6. Recommended Remediation Order

1. **Fix P0-1** — remove the `{ id: "new" }` static params from all 13 `[id]` routes; re-run `npm run build` and confirm no duplicate route claims. *~1 hour, unblocks all create flows.*
2. **Fix P0-2** — upgrade Django ≥ 4.2.21, PyJWT ≥ 2.12, DRF ≥ 3.17.2, simplejwt ≥ 5.5.1, urllib3 ≥ 2.8; `npm audit fix` plus the `next` critical. Re-run both audits to zero critical/high.
3. **Fix P1-1** — add `min-w-0` to `app/(dashboard)/layout.tsx:38` and `app/(admin)/layout.tsx:36`; re-test at 375/768/1440.
4. **Fix P1-2** — add `IntegrityError` handling to `core/exceptions/custom_exception_handler` and give `invoice_number` a non-empty unique default.
5. **Fix P1-4** — label the two Select triggers, raise amber-on-slate contrast above 4.5:1, un-nest the row-actions `role="button"`.
6. **Fix P1-3** — write `restore.sh`, schedule the backup cron, copy backups off-host, rehearse one restore.
7. Then the P2 batch (token storage → `httpOnly` cookies, `Retry-After`, MD5 → SHA-256, JSON 404s, envelope consistency, JSON logging + metrics).
8. Re-run this full 40-type pass before declaring GO.

**Re-test gate for GO:** P0 and P1 at zero, backend CVEs at zero critical/high, frontend CVEs at zero critical, responsive overflow gone, axe `/bookings` at zero critical/serious.
