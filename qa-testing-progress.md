# QA Testing Progress Tracker

**App:** EventFlow (multi-tenant event-management SaaS)
**Stack:** Django 4.2.16 + DRF 3.15.2 (backend) · Next.js 14 / React 18 (frontend) · Flutter (mobile) · MySQL (prod) / SQLite (QA) · Redis 8
**Started:** 2026-10-07T13:13:10Z
**Last Updated:** 2026-10-10T17:40:00Z
**Status:** COMPLETE

---

## Progress Summary
- Total: 40
- Completed: 40
- Pending: 0
- In Progress: 0
- Skipped: 0

---

## Test Checklist

| # | Test Type | Status | Started | Completed | Notes |
|---|-----------|--------|---------|-----------|-------|
| 1 | Unit Testing | PASS | 10-10 15:40 | 10-10 15:42 | 122 passed; 31% unit-only src coverage; 69% with full suite |
| 2 | Integration Testing | PASS | 10-10 15:42 | 10-10 15:43 | 19/19 passed |
| 3 | Functional Testing | PARTIAL | 10-10 16:00 | 10-10 17:05 | CRUD OK; invoice_number + duplicate-mobile 500s |
| 4 | End-to-End Testing | PARTIAL | 10-10 16:00 | 10-10 17:05 | booking→invoice PDF OK; invoice# / quotation schema gaps |
| 5 | Regression Testing | PASS | 10-10 15:45 | 10-10 15:47 | 396 passed, 1 skipped, 11 documented xfails |
| 6 | Smoke Testing | PASS | 10-10 16:01 | 10-10 16:01 | health/ready/live + 7 core endpoints 200 |
| 7 | Sanity Testing | PASS | 10-10 16:20 | 10-10 16:25 | commit db65e27 audit fixes verified |
| 8 | UI/UX Testing | PARTIAL | 10-10 17:10 | 10-10 17:30 | login/dashboard/details OK; "New X" routes broken for 13 resources |
| 9 | API Testing | PARTIAL | 10-10 16:00 | 10-10 17:10 | validation solid; HTML 404/500, envelope drift |
| 10 | Data Validation Testing | PARTIAL | 10-10 16:00 | 10-10 17:10 | duplicate mobile → 500 IntegrityError |
| 11 | Database Testing | PASS | 10-10 16:20 | 10-10 16:30 | no migration drift; clean migrate; indexes present |
| 12 | Performance Testing | PASS | 10-10 17:01 | 10-10 17:02 | p50 27ms / p95 31ms |
| 13 | Load Testing | PASS | 10-10 17:02 | 10-10 17:03 | 10c × 20 = 42.4 rps, p95 311ms, 0 errors |
| 14 | Stress Testing | PARTIAL | 10-10 17:03 | 10-10 17:04 | 50c × 20 = 0 errors but p95 1.33s / p99 2.6s |
| 15 | Scalability Testing | PARTIAL | 10-10 17:04 | 10-10 17:05 | single-process dev server only; HA not verified |
| 16 | Rate Limiting & Throttling | PARTIAL | 10-10 17:15 | 10-10 17:18 | login/forgot/contact limits enforced; no Retry-After header |
| 17 | Security Testing | PARTIAL | 10-10 16:15 | 10-10 16:20 | bandit 1 High (MD5), deploy check 1 warning |
| 18 | Penetration Testing | PARTIAL | 10-10 16:50 | 10-10 17:10 | SQLi/IDOR safe; XSS stored unescaped in DB |
| 19 | Vulnerability Testing | FAIL | 10-10 16:15 | 10-10 16:18 | 85 PyPI vulns (4 pkgs); npm 1 critical + 18 high |
| 20 | Authentication & Authorization | PASS | 10-10 16:50 | 10-10 17:00 | JWT + refresh blacklist + 401 paths verified |
| 21 | Role-Based Access Control | PASS | 10-10 16:50 | 10-10 17:00 | staff denied 8/8 privileged ops |
| 22 | Tenant Isolation | PASS | 10-10 16:50 | 10-10 17:00 | 0 cross-tenant leaks on GET/PATCH/DELETE |
| 23 | Audit Logging | PARTIAL | 10-10 17:00 | 10-10 17:02 | AUTH login/logout logged; customer create not |
| 24 | Multi-Tenancy Testing | PASS | 10-10 16:30 | 10-10 17:00 | 2 tenants provisioned, data separated |
| 25 | Backup & Recovery Testing | PASS | 10-10 17:30 | 10-10 17:32 | sqlite online backup → 54 tables, integrity ok, data verified |
| 26 | Disaster Recovery Testing | PARTIAL | 10-10 17:32 | 10-10 17:34 | backup.sh (mysqldump+gzip verify+retention) present; no restore script, no off-site copy |
| 27 | Failover Testing | PARTIAL | 10-10 17:32 | 10-10 17:34 | systemd Restart=on-failure verified in config; live process kill not exercised |
| 28 | Monitoring & Alerting Testing | PARTIAL | 10-10 17:34 | 10-10 17:36 | /health /ready /live + X-Request-ID OK; console-only logging, no metrics/alerting |
| 29 | Chaos Testing | PASS | 10-10 17:05 | 10-10 17:06 | redis flush recovery + webhook garbage OK |
| 30 | Compatibility Testing | PARTIAL | 10-10 17:36 | 10-10 17:37 | Python 3.14.4 / Node 22.23.2 verified; Django 4.2 LTS now EOL |
| 31 | Cross-Browser Testing | PARTIAL | 10-10 17:37 | 10-10 17:38 | Chromium 154 only; Firefox/WebKit unavailable — manual plan provided |
| 32 | Responsive Testing | FAIL | 10-10 17:20 | 10-10 17:25 | horizontal overflow at 375px (778 vs 360) and 768px (1050 vs 753) |
| 33 | Accessibility Testing | PARTIAL | 10-10 17:25 | 10-10 17:30 | axe: 3 critical/serious violations on /bookings; dashboard 0; login 1 |
| 34 | Localization Testing | PARTIAL | 10-10 17:36 | 10-10 17:37 | en-IN ₹/date correct; no i18n framework, no RTL, no locale switch |
| 35 | Payment Gateway Testing | PASS | 10-10 17:36 | 10-10 17:38 | 6/6 tests pass; HMAC verify uses hmac.compare_digest (constant-time) |
| 36 | Subscription & Billing Testing | PASS | 10-10 17:36 | 10-10 17:38 | 57 passed (subscription/credit/invoice/payment selectors); 4 documented xfails |
| 37 | Email/SMS Notification Testing | PARTIAL | 10-10 17:36 | 10-10 17:38 | EmailProvider retries 3×, masks PII, no swallowed exceptions; Twilio path untested live |
| 38 | Third-Party Integration Testing | PARTIAL | 10-10 17:36 | 10-10 17:38 | Razorpay+Twilio+WhatsApp gated by tenant settings; live credentials not provisioned |
| 39 | Compliance Testing | PARTIAL | 10-10 17:00 | 10-10 17:02 | contact ack enforced; privacy request 400 |
| 40 | User Acceptance Testing | PARTIAL | 10-10 17:38 | 10-10 17:40 | read flows + detail views pass; ALL "New X" create flows blocked by routing bug |

---

## Detailed Results (appended as tests complete)

### Test #1: Unit Testing
- **Status:** PASS
- **Tools:** pytest 9.1.1, pytest-django 4.9.0, pytest-cov 5.0.0
- **Command:** `cd backend && ./venv/bin/python -m pytest tests/unit -q --cov=apps --cov=core ...`
- **Result:** 122 passed, 12 warnings in 63s. Unit-only source coverage 31% (6804 stmts, 4690 missed).
- **Issues:** None at unit level. Coverage of unit layer alone is low; the full suite lifts it to 69%.
- **Completed At:** 2026-10-10T15:42:00Z

### Test #2: Integration Testing
- **Status:** PASS
- **Tools:** pytest + DRF test client + factory_boy
- **Command:** `./venv/bin/python -m pytest tests/integration -q`
- **Result:** 19 passed in 60s (auth, booking, customer, invoice, lead, payment flows)
- **Issues:** None
- **Completed At:** 2026-10-10T15:43:00Z

### Test #5: Regression Testing
- **Status:** PASS
- **Tools:** pytest, coverage
- **Command:** `./venv/bin/python -m pytest -q --cov=apps --cov=core --cov=services --cov=utils --cov=middleware --cov=permissions --cov=repositories --cov=gateway --cov=config`
- **Result:** 396 passed, 1 skipped, 11 xfailed, 56 subtests passed in 84s. Source coverage **69%** (6804 stmts, 2114 missed).
- **Documented gaps (xfailed by design, `@unittest.expectedFailure`):** plan quotas not enforced, payment min validator missing, webhook gateway not tenant-scoped, customer-create not audited, privacy acknowledgement not enforced on privacy requests, 3 API-contract 404s are HTML, duplicate mobile not rejected, non-positive payment not rejected at model level.
- **Completed At:** 2026-10-10T15:47:00Z

### Test #6: Smoke Testing
- **Status:** PASS
- **Tools:** curl, live Django server (isolated QA settings)
- **Command:** `curl /health/ /ready/ /live/` + login + 7 authenticated GETs
- **Result:** health 200 (13ms), ready 200 (79ms, db+migrations+redis all true), live 200 (10ms), login 200, dashboard/profile/customers/bookings/venues/leads/invoices all 200 (28–54ms).
- **Completed At:** 2026-10-10T16:01:00Z

### Test #29: Chaos Testing
- **Status:** PASS
- **Tools:** redis-cli, curl, malformed-payload probes
- **Result:** `FLUSHDB` on cache → next request 200 in 53ms (graceful cache-miss recovery). Razorpay webhook with garbage body and bad signature → 200 `{"status":"ignored"}` (no crash, no unhandled exception). 50× health burst → 50× 200.
- **Completed At:** 2026-10-10T17:06:00Z

### Test #30–34: Frontend Quality (UI/UX, Compatibility, Cross-Browser, Responsive, Accessibility, Localization)
- **Status:** PARTIAL (32 Responsive = FAIL)
- **Tools:** Playwright (Chromium 154), axe-core 4.10.2, tsc, eslint
- **Commands:** `npx tsc --noEmit` (0 errors), `npx eslint .` (0 errors, 3 warnings), `npm run build` (OK), axe.run on /bookings, /dashboard, /login
- **Findings:**
  - **Responsive FAIL** — `app/(dashboard)/layout.tsx:38` and `app/(admin)/layout.tsx:36` use `flex flex-1 flex-col md:pl-64` **without `min-w-0`**. Wide data tables force the flex child wider than the viewport: 375px viewport → scrollWidth 778 (overflow 418px); 768px → scrollWidth 1050. Desktop 1440px → OK (no overflow).
  - **Accessibility** — axe on `/bookings`: 3 violation types (2× critical `button-name` on unlabeled Radix Select triggers `.sm:w-[160px]`/`.sm:w-[180px]`; 10× serious `color-contrast` — worst 2.05:1 amber-on-slate and 8× table headers at 4.48:1 vs 4.5:1 required; 1× serious `nested-interactive` — `div[role="button"]` with focusable children). `/dashboard`: 0 violations. `/login`: 1 `color-contrast`.
  - **Cross-browser** — only Chromium 154 present in the environment; Firefox/WebKit not installed. Marked PARTIAL with manual test plan in the report.
  - **Localization** — `lib/utils.ts` hardcodes `en-IN` (`formatINR`, `formatDate`, `formatDateTime`); ₹2,00,000 lakh grouping and "10 Oct 2026, 05:16 pm" confirmed correct in UI. No i18n framework, no RTL support, no locale switcher.
  - **UI/UX** — login, dashboard, and detail pages (`/customers/1`) render correctly; skip-link, labelled nav, and form labels present. Theme provider defaults to `light` so `enableSystem` never applies `prefers-color-scheme: dark` on first visit.
- **Completed At:** 2026-10-10T17:30:00Z

### Test #8 / #40: UI/UX + User Acceptance (routing blocker)
- **Status:** PARTIAL
- **Result:** Read flows (dashboard, list, detail) pass UAT. **Every "New X" create flow is broken** — `app/(dashboard)/*/​[id]/page.tsx` contains `export function generateStaticParams() { return [{ id: "new" }] }` in **13 routes** (bookings, customers, leads, venues, payments, invoices, vendors, staff, tasks, packages, contracts, quotations, inventory). This prerenders the detail component at `/xxx/new`, colliding with the real create page (`build` output shows both `● /customers/[id] → └ /customers/new` and `○ /customers/new`). Result: navigating to `/customers/new` and `/bookings/new` renders "Customer not found" / "Booking not found". Confirmed in browser on the fresh production build served by `next start`.
- **Completed At:** 2026-10-10T17:40:00Z

### Test #25–28: Backup, DR, Failover, Monitoring
- **Status:** 25 PASS; 26/27/28 PARTIAL
- **Tools:** sqlite3 online backup, file/script review
- **Result:**
  - **25 Backup & Recovery (PASS)** — `sqlite3.Connection.backup()` of the QA DB restored to a fresh file: 54 tables, `PRAGMA integrity_check` = ok, row counts verified (3 users, 2 tenants, 1 booking, 1 payment, 4 customers, 7 audit_logs).
  - **26 DR (PARTIAL)** — `deploy/scripts/backup.sh` exists and is well built (`set -euo pipefail`, mysqldump|gzip, gzip integrity verification with non-zero exit on failure, 7 daily / 4 weekly retention, `.env` excluded). Gaps: **no restore script**, no off-site/remote copy, and the backup cron is **not** present in `cron-jobs.sh`.
  - **27 Failover (PARTIAL)** — `deploy/systemd/eventflow.service` has `Restart=on-failure`, `RestartSec=5`, and solid hardening (`NoNewPrivileges`, `ProtectSystem=strict`, `ProtectHome=read-only`, kernel protections). A live process-kill failover was not exercised in this environment.
  - **28 Monitoring & Alerting (PARTIAL)** — `/health/`, `/ready/` (db + migrations + redis, 503 on degraded), `/live/` all work; `core/logging_middleware.py` emits `X-Request-ID` and logs request ids. Gaps: `LOGGING` in `config/settings/base.py:216` is **console-only `StreamHandler`** despite `python-json-logger` being in requirements (never wired); no metrics endpoint, no Prometheus/StatsD/Sentry/Datadog integration, no alert rules, no `cleanup_old_logs` actually scheduled.
- **Completed At:** 2026-10-10T17:36:00Z

### Test #35–38: Payments, Subscription/Billing, Notifications, Third-Party
- **Status:** 35/36 PASS; 37/38 PARTIAL
- **Tools:** pytest (payment/invoice + subscription/credit/notification selectors), static review of `gateway/`
- **Result:**
  - **35 Payment Gateway (PASS)** — `tests/integration/test_payment_flow.py` + `test_invoice_flow.py`: 6 passed. `gateway/payments/razorpay.py:45` derives the expected signature with `hmac.new(...).hexdigest()` and compares via **`hmac.compare_digest`** (constant-time — no timing side channel). Order creation converts rupees → paise correctly.
  - **36 Subscription & Billing (PASS)** — selector run over subscription/credit/invoice/payment/notification/export/backup tests: **57 passed, 1 skipped, 4 xfailed** (the xfails are the documented KNOWN GAPs, not new failures).
  - **37 Email/SMS (PARTIAL)** — `gateway/messaging/email_provider.py` masks recipient PII in logs (`mask_email`), retries 3× on `SMTPException`, returns a result object instead of swallowing. Twilio/WhatsApp providers exist and are tenant-settings-gated but were not exercised against live credentials.
  - **38 Third-Party (PARTIAL)** — Razorpay, Twilio and WhatsApp integrations all load and fail closed when unconfigured. Live vendor credentials were not provisioned for this QA run (by design — no production config touched).
- **Completed At:** 2026-10-10T17:38:00Z
