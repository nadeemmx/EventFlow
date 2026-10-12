# EventFlow — Pre-Production Test Report

**Date:** 2026-10-06
**Scope:** Local pre-production verification of EventFlow (Next.js 14 frontend + Django 4.2 backend) — API, security, RBAC/tenancy, audit, business logic, database, load, chaos, backup/restore, and browser-based E2E/XSS/responsive/accessibility testing.
**Code under test:** working tree at `db65e27` + uncommitted test/verification changes (no production code was modified in this pass except previously landed fixes `backend/core/cache.py`, `frontend/app/icon.svg`).
**Environment:** local single node — Django `runserver` (1 process) on `:8000` with `config.settings.local` (SQLite, throttle 10000/min), Next.js dev server on `:3000`, Chromium (Playwright). Production targets gunicorn + MySQL (`config.settings.production`) and are **not** executed here (see §Limitations).

**Headline results**

| Gate | Result |
|---|---|
| Full backend suite | **396 passed, 1 skipped, 11 xfailed, 56 subtests — exit 0** (`pytest -q`) |
| Pre-production suite (`tests/preprod`, 125 tests) | **125 passed, 1 skipped, 11 xfailed — exit 0** |
| Backend coverage (`pytest --cov`) | **84.6%** lines (7645/9038) |
| Type check (`tsc --noEmit`) | **0 errors** |
| Lint (`next lint`) | **exit 0**, 3 warnings (`no-img-element`) |
| Production build (`next build`) | **✓ Compiled successfully, 75/75 static pages** |
| Dependency audit (pip-audit + npm audit) | **FAIL — 89 Python vulns (6 pkgs) + 8 npm vulns (1 critical)** |
| Load / concurrency | **0 read errors**, but login storm **3× HTTP 500 (SQLite lock)** |
| Chaos (SIGKILL) | **detect 0.09 s, full recovery 5.83 s, zero data loss** |
| Backup / restore | **restore verified row-exact (399/399)** |

**Status legend:** `PASS` · `PASS*` (passes, with findings listed) · `FAIL` (defect or gate violation proven) · `SKIPPED` (could not be executed in this environment — reason stated).

---

## Summary — 40 Test Types

| # | Test type | Status |
|---|---|---|
| 1 | Unit & integration test suite | PASS |
| 2 | API contract & error envelopes | PASS* |
| 3 | Data validation & boundary values | FAIL* |
| 4 | Authentication (JWT) lifecycle | PASS |
| 5 | Session & token management | PASS* |
| 6 | RBAC — module permissions | PASS |
| 7 | Multi-tenant data isolation | PASS |
| 8 | Authorization negative testing | PASS |
| 9 | Rate limiting & brute-force protection | PASS |
| 10 | CSRF protection | PASS |
| 11 | CORS configuration | PASS |
| 12 | Security & observability response headers | PASS* |
| 13 | SQL injection & query safety | PASS |
| 14 | Cross-site scripting (stored XSS) | PASS |
| 15 | Malformed input & path traversal | PASS |
| 16 | File upload validation | PASS* |
| 17 | Secrets & configuration management | PASS* |
| 18 | Dependency & supply-chain audit | **FAIL** |
| 19 | Error handling & information leakage | PASS |
| 20 | Business logic — booking state machine | PASS |
| 21 | Business logic — payments & refunds | FAIL* |
| 22 | Business logic — invoicing | PASS |
| 23 | Business logic — subscriptions & plan limits | FAIL* |
| 24 | Payment webhook signature verification | PASS* |
| 25 | Audit logging & traceability | FAIL* |
| 26 | Privacy & data-subject requests | FAIL* |
| 27 | Database schema & migration integrity | PASS |
| 28 | Database indexing & query plans | PASS |
| 29 | Reporting & analytics accuracy | PASS* |
| 30 | Performance & latency (single node) | PASS* |
| 31 | Load & stress testing | PASS* |
| 32 | Concurrency & write contention | **FAIL** |
| 33 | Chaos & crash recovery | PASS |
| 34 | Backup & restore drill | PASS* |
| 35 | Health checks, logging & observability | PASS* |
| 36 | End-to-end user flows (browser) | PASS* |
| 37 | Cross-browser compatibility | SKIPPED |
| 38 | Responsive layout & mobile | PASS* |
| 39 | Accessibility (WCAG 2.2 / axe-core) | PASS* |
| 40 | Build & static analysis | PASS* |

`FAIL*` = defect proven by a test (11 are captured as `@unittest.expectedFailure` known gaps with `file:line` references; failing an expected-failure test means the gap still exists — they are never made green by weakening an assertion).

---

## Detailed results

### 1. Unit & integration test suite — PASS
- **Evidence:** `pytest -q` → `396 passed, 1 skipped, 11 xfailed, 16 warnings, 56 subtests passed in 86.63s`, exit 0 (`/tmp/opencode/eventflow-logs/pytest-final-full2.log`). Pre-prod subset → `125 passed, 1 skipped, 11 xfailed` (`/tmp/opencode/eventflow-logs/preprod-final.log`). Coverage `--cov` → 84.59% (`/tmp/opencode/eventflow-logs/pytest-cov-final.log`, `coverage-final.json`).
- **Issues:** none. Lowest-covered modules (≥40 stmts, <60%): `config/settings/production.py` 12.5%, `gateway/messaging/whatsapp_provider.py` 22.1%, `services/notification_service.py` 26.4%, `gateway/payments/razorpay.py` 29.4%, `apps/contracts/services.py` 30.9%, `apps/settings/services.py` 40.8%, `services/payment_service.py` 48.3%, `services/report_service.py` 56.1% — external-gateway and settings code paths are the main coverage debt.

### 2. API contract & error envelopes — PASS*
- **Evidence:** 26-endpoint probe + `tests/preprod/test_api_contract.py` (envelopes `{success,message,data}` / `{success,data,pagination}` / `{count,results}`; 405 on `DELETE /api/v1/auth/login/`; invalid JSON → 400; unknown JSON routes).
- **Issues:** 3 known gaps returned HTML instead of JSON: unknown API route, `GET /api/v1/reports/`, `GET /api/v1/settings/` (`tests/preprod/test_api_contract.py:172,189,200`) — Django 404 view falls through, so axios clients get a parse error. A companion test proves unknown routes currently return HTML 404, so the contract is measured, not assumed.

### 3. Data validation & boundary values — FAIL*
- **Evidence:** null/wrong-type payloads → 400 with field errors; missing confirm-password → 400; malformed email/phone rejected (preprod suite green).
- **Issues:** duplicate mobile inside a tenant → **HTTP 500** (`IntegrityError` unhandled) despite DB unique constraint `(tenant_id, mobile)` — `tests/preprod/test_data_validation.py:70`. Requires a serializer pre-validation returning 400/409.

### 4. Authentication (JWT) lifecycle — PASS
- **Evidence:** login → 200 + access/refresh pair; invalid credentials → 401; token shape/expiry (`ACCESS_TOKEN_LIFETIME` 60 min, `REFRESH_TOKEN_LIFETIME` 1440 min, rotation + blacklist enabled in `config/settings/base.py`); login probe `/tmp/opencode/eventflow-logs/login.json`.
- **Issues:** none.

### 5. Session & token management — PASS*
- **Evidence:** refresh via `refresh_token` field → 200; **refresh reuse after rotation → 401 "Invalid or expired refresh token"** (blacklist works) — verified live in the browser flow; logout clears `localStorage` tokens and redirects to `/login`.
- **Issues:** access token issued before logout stays valid until its 60-minute expiry (stateless JWT — no server-side access-token revocation list). Documented risk; mitigate with short TTL or a denylist if required by policy.

### 6. RBAC — module permissions — PASS
- **Evidence:** `tests/preprod/test_rbac_tenancy.py` — SUPER_ADMIN/OWNER/EVENT_MANAGER/STAFF/VIEWER matrices across users, tenants, venues, customers, bookings, invoices, settings, reports; cross-role 403s asserted.
- **Issues:** none.

### 7. Multi-tenant data isolation — PASS
- **Evidence:** cross-tenant read/write attempts → 403/404 on every scoped route; guest count capped by venue capacity (80) in booking tests; every hot list query tenant-filtered.
- **Issues:** none.

### 8. Authorization negative testing — PASS
- **Evidence:** unauthenticated access to protected routes → 401; wrong-role → 403; object-level checks (`get_object` scoping) asserted across customers/bookings/invoices/reports in preprod suite.
- **Issues:** none.

### 9. Rate limiting & brute-force protection — PASS
- **Evidence:** `RateLimitingTests` overrides `rest_framework.settings.api_settings.DEFAULT_THROTTLE_RATES` in-process (with cache flush + restore) and drives login past the strict limit → **429** with `Retry-After`-style throttle response; per-client throttle asserted.
- **Issues:** production `local.py` default is 10000/min (dev convenience) — production settings must keep the strict rate (see §17).

### 10. CSRF protection — PASS
- **Evidence:** Django session-CSRF paths + DRF token/JWT flows tested; cookie-authenticated state-changing requests verified; template-render capture disabled during error-page tests (Python 3.14 + Django 4.2 workaround).
- **Issues:** none.

### 11. CORS configuration — PASS
- **Evidence:** preflight from `http://localhost:3000` → `Access-Control-Allow-Origin: http://localhost:3000` + `Allow-Credentials: true`; preflight from `https://evil.example` → **no `Access-Control-Allow-Origin` header** (verified live and in `test_operations.py::test_cors_reflects_only_allowed_origin`). Production origin allow-lists configured in `deploy/scripts/deploy.sh` and `DEPLOYMENT.md`.
- **Issues:** local dev allows `localhost/127.0.0.1:3000/3001` by design.

### 12. Security & observability response headers — PASS*
- **Evidence (live):** `X-Frame-Options: DENY`, `X-Content-Type-Options: nosniff`, `Referrer-Policy: same-origin`, `Cross-Origin-Opener-Policy: same-origin`, `X-Request-ID`, `X-Response-Time-Ms` on API responses; asserted in `tests/preprod/test_operations.py::SecurityHeaderTests`.
- **Issues:** app-level responses carry **no CSP and no HSTS** (correctly the edge's job); `deploy/nginx/eventflow.conf` adds `Content-Security-Policy`, `Strict-Transport-Security`, `Permissions-Policy`, `X-XSS-Protection` — **config-file evidence only, not runtime-verified** (no nginx in local run).

### 13. SQL injection & query safety — PASS
- **Evidence:** classic probes (`' OR '1'='1`, `'; DROP TABLE customers; --`, UNION payloads in search/list filters) → parameterised ORM handling, no error, no data leak; API-wide probe log `/tmp/opencode/eventflow-logs/security-probe.log`.
- **Issues:** none.

### 14. Cross-site scripting (stored XSS) — PASS
- **Evidence:** stored payload `<script>alert('xss')</script>` in a customer name renders as **literal text** in the list and detail views; browser assertion `inlineXssScripts: 0`, no dialogs, no injected DOM nodes — screenshots `02-customers-xss-rendered-literal-1440.png`, `03-customer-detail-xss-1440.png`.
- **Issues:** none.

### 15. Malformed input & path traversal — PASS
- **Evidence:** invalid JSON body → 400 (not 500). URL traversal `/media/../../../../etc/passwd`, `/static/../../../etc/passwd`, `/api/v1/customers/../../../../etc/passwd` → **404**; encoded `%2e%2e%2f…` → **400**; zero `/etc/passwd` content in any response. Upload with `filename=../../evil.pdf` stored as `media/contact/resumes/2026/10/evil.pdf` (basename sanitised, nothing written outside `media/`).
- **Issues:** none.

### 16. File upload validation — PASS*
- **Evidence:** fake PDF (text content, `application/pdf`) → **rejected**, message cites magic-byte mismatch `Detected: text/plain`; `.txt` extension → **rejected** (extension allow-list); 26 MB file → **400** `File too large (26MB). Maximum allowed: 20MB.`; valid PDF → **201** and physically stored at `media/contact/resumes/2026/10/ok.pdf`; contact submission without `privacy_acknowledged` → **400**.
- **Issues:** validator allows 20 MB while `DATA_UPLOAD_MAX_MEMORY_SIZE = 10MB` (`backend/config/settings/base.py:126`, `production.py:84`) — inconsistent limits; multipart file parts bypass the Django cap today, non-file bodies over 10 MB would fail differently. Harmless but confusing.

### 17. Secrets & configuration management — PASS*
- **Evidence:** `config/settings/production.py:5` `DEBUG = False`; lines 7–10 refuse to boot without `DJANGO_SECRET_KEY` and reject the insecure default; lines 38/41/47 require `REDIS_URL`/`ENCRYPTION_KEY`. Secret-pattern scan of all tracked files → only the fake test fixture `sk_test_abcdef123456` in `backend/tests/unit/test_encrypted_field.py:15`. `.env`/`.env.*` gitignored, only `.env.example` (empty values) tracked.
- **Issues:** `base.py:7` carries a dev fallback `insecure-dev-key-change-in-production` — safe only because `production.py` rejects it; keep that guard under review. Local dev runs `DEBUG = True` (expected, never for production).

### 18. Dependency & supply-chain audit — **FAIL**
- **Evidence:** `pip-audit 2.10.1` → **89 known vulnerabilities in 6 installed packages** (`/tmp/opencode/eventflow-logs/pip-audit.json`):
  - `Django==4.2.16` — **60** (4.2 LTS; many advisories post-date the pin — `backend/requirements/base.txt:1`)
  - `PyJWT==2.9.0` — 21 (`requirements/base.txt:11`)
  - `urllib3 2.7.0` — 3
  - `djangorestframework==3.15.2` — 2
  - `djangorestframework-simplejwt==5.3.1` — 2
  - `multidict 1.26.x` — 1
  `npm audit --omit=dev` → **1 critical, 4 high, 3 moderate** (`/tmp/opencode/eventflow-logs/npm-audit.json`): **critical `next`** (Image Optimizer / RSC DoS advisories, installed 14.2.35), `axios` 1.18.0 (prototype pollution), `postcss`, `nanoid`, `source-map-js`, `@react-three/drei`, `fflate`, `uuid` — all report fix versions available.
- **Issues:** no runtime exploit was attempted (out of scope); this is a gate failure that must be cleared by dependency upgrades + regression run before production. Do **not** upgrade blindly — Django 4.2 → 5.x is a major migration.

### 19. Error handling & information leakage — PASS
- **Evidence:** API error bodies are structured (`{success:false,message,errors}`); no `Traceback`/`site-packages` in API responses (`test_operations.py::test_error_responses_do_not_leak_server_stack`); 500s return generic messages; Django debug pages appear only for HTML 404s under `DEBUG=True` (dev-only setting).
- **Issues:** HTML 404/500 pages under `DEBUG=True` would leak traces if a dev config reached production — guarded by §17's `DEBUG = False` + boot-time checks.

### 20. Business logic — booking state machine — PASS
- **Evidence:** `tests/preprod/test_business_logic.py` — PENDING→CONFIRMED/CANCELLED/COMPLETED transitions, illegal transitions rejected (400), double-booking window conflicts, capacity/venue closure rules, cancellation release semantics.
- **Issues:** none.

### 21. Business logic — payments & refunds — FAIL*
- **Evidence:** payment create/read/refund happy paths + over-payment rejection (`amount > outstanding`) tested; refunds recompute outstanding correctly; amounts round to 2dp.
- **Issues:** `services/payment_service.py:28` only compares `amount > outstanding` — **zero and negative payment amounts are accepted** (`tests/preprod/test_business_logic.py:275` and `:368`; live probe: `amount=0` with `payment_date` → **201**). Understates/misstates revenue reports. Fix: `MinValueValidator` on the model plus a service-layer `amount > 0` check.

### 22. Business logic — invoicing — PASS
- **Evidence:** invoice generation, line-item totals, GST/tax computation, numbering uniqueness (DB unique on `invoices.invoice_number`), status transitions tested in preprod suite.
- **Issues:** none.

### 23. Business logic — subscriptions & plan limits — FAIL*
- **Evidence:** subscription CRUD, renewal, expiry and status transitions pass.
- **Issues:** plan quotas are **not enforced at the API boundary** — `permissions/feature_limits.py` `EnforceVenueLimit` is a stub returning `True` and `EnforceUserLimit` is unused, so a tenant on the smallest plan can create unlimited venues/users (`tests/preprod/test_business_logic.py:347,358`).

### 24. Payment webhook signature verification — PASS*
- **Evidence:** 11 webhook tests pass — valid HMAC accepted, invalid/tampered-body signature rejected, non-POST rejected, no-gateway-configured ignored, unmatched-order handled without 500 (`tests/preprod/test_business_logic.py::…webhook…`, run `-k webhook` → `11 passed, 1 xfailed`).
- **Issues:** webhook gateway lookup is **not tenant-scoped** — first active gateway row wins (`config/api_router.py:46-52`), so a signature minted with one tenant's secret can be accepted where another tenant's gateway was expected (`tests/preprod/test_business_logic.py:149`). Cross-tenant payment-crediting risk.

### 25. Audit logging & traceability — FAIL*
- **Evidence:** audit middleware writes rows for login, update/delete and MERGE operations; `X-Request-ID` correlates request → response; audit rows carry actor/tenant/IP/timestamp; asserted in `tests/preprod/test_audit_compliance.py`.
- **Issues:** **customer CREATE writes no audit row** — only MERGE is audited (`services/customer_service.py:29`) (`tests/preprod/test_audit_compliance.py:135`). Creates of other entities should be confirmed the same way in a follow-up audit sweep.

### 26. Privacy & data-subject requests — FAIL*
- **Evidence:** privacy request lifecycle (submit→verify→export/delete→complete) tested; export/delete honour tenant scope; contact form enforces `privacy_acknowledged` (live 400 without it).
- **Issues:** `/api/v1/privacy/submit/` treats `privacy_acknowledged` as optional and drops it (`apps/privacy/serializers.py:9`) (`tests/preprod/test_audit_compliance.py:203`) — inconsistent consent enforcement between contact and privacy endpoints.

### 27. Database schema & migration integrity — PASS
- **Evidence:** `showmigrations` → **0 unapplied**; `makemigrations --check` → clean (no model/schema drift); `manage.py check` → **0 issues**; 53 tables, 91 migrations applied; live `db-*.log` in `/tmp/opencode/eventflow-logs/`.
- **Issues:** none.

### 28. Database indexing & query plans — PASS
- **Evidence:** FK-column scan via `PRAGMA table_info` + `index_list`/`index_info` → **0 FK columns without an index**; 23 unique constraints incl. `(tenant_id, mobile)` on customers, unique `users.email`, unique `invoices.invoice_number`; `EXPLAIN QUERY PLAN` on hot tenant-scoped list queries shows index usage (`idx_customers_tenant_*` etc.).
- **Issues:** an earlier automated scan reported "166 missing indexes" — that check was itself buggy (it matched indexes by name, not column) and was corrected; the 0/FK result above is the verified one.

### 29. Reporting & analytics accuracy — PASS*
- **Evidence:** `/reports` hub renders; `/reports/revenue` shows correct totals for a seeded case (₹1,00,000 revenue, ₹0 refunds, ₹1,00,000 net); report figures cross-checked against DB aggregates; screenshot `06-revenue-report-invalid-date.png`.
- **Issues:** revenue report header renders **"Period: Invalid Date – Invalid Date"** — frontend date-range formatting bug (server-side figures are correct).

### 30. Performance & latency (single node) — PASS*
- **Evidence:** `/tmp/opencode/eventflow-logs/load-test.json` (12 s phases, single `runserver` process): reads p50 159 ms / p95 207 ms @ 5 conn, 0 errors; p50 climbs to 1835 ms / p95 2580 ms @ 50 conn because one dev process serialises requests.
- **Issues:** numbers are **not production-representative** (no gunicorn/MySQL/Redis). Use them only as a functional-during-load sanity signal.

### 31. Load & stress testing — PASS*
- **Evidence:** read mix c5→c50 with **0 errors**; customers list at c50: p50 1906 ms, p95 2583 ms, 0 errors; write churn 397/397 → **201**; forgot-password storm 209/209 → 200 (p95 279 ms).
- **Issues:** throughput plateaus ≈27 rps at c25–c50 (single process) — expected locally; no queue/backpressure errors observed.

### 32. Concurrency & write contention — **FAIL**
- **Evidence:** login storm at concurrency 20 → **127 requests: 124×200, 3× HTTP 500** with `sqlite3.OperationalError: database is locked` (2.36% error rate) — `/tmp/opencode/eventflow-logs/load-test.json`.
- **Issues:** SQLite-specific artifact of the local stack (production uses MySQL with `CONN_MAX_AGE=600`), so this is a **local-environment failure, not a proven production defect** — but it must be re-run against MySQL before go-live, and it demonstrates the app does not translate DB-lock into a clean 503/retry.

### 33. Chaos & crash recovery — PASS
- **Evidence:** `kill -9` on the backend (script `/tmp/opencode/eventflow-qa/chaos_test.sh`, log `chaos.log`): outage detected in **0.09 s**, total recovery **5.83 s**; during outage health/API fail fast with connection-refused (no hung requests); after restart `/health/`, `/ready/`, login, a **pre-outage JWT**, and the frontend all return 200; frontend `/customers` during outage redirects to `/login` gracefully — no white screen, no console errors (`07-backend-down-customers.png`, `08-recovered-customers.png`).
- **Issues:** server-down is rendered identically to logged-out (redirect to login) — a UX finding, not a defect; consider an "offline" state.

### 34. Backup & restore drill — PASS*
- **Evidence:** snapshot via Python `sqlite3.Connection.backup()` → `/tmp/opencode/eventflow-backup/db-20261006_223854.sqlite3` (2.49 MB) + `dumpdata` JSON (422 KB); deleted 5 customers (399→394) → restore via `os.replace` → **399 rows with all 5 originals back, byte-verified**; post-restore `/health/`, `/ready/`, login all 200.
- **Issues:** `deploy/scripts/backup.sh` is `mysqldump`-only with **no restore script and no restore drill against MySQL**; the verified drill here is SQLite. Production backup/restore must be rehearsed on MySQL.

### 35. Health checks, logging & observability — PASS*
- **Evidence:** `/health/` 200, `/ready/` 200 (checks database + migrations + cache; **returns 503 when any check fails** — proven by `test_operations.py::test_readiness_degrades_to_503_when_database_unreachable`), `/live/` 200. `RotatingFileHandler` 10 MB×5 in `config/settings/production.py`; `X-Request-ID`/`X-Response-Time-Ms` per response; error envelope never leaks traces (§19).
- **Issues:** no centralized log shipping/APM/metrics endpoint in-app (nginx + file logs only) — acceptable for this stage, list as an ops follow-up.

### 36. End-to-end user flows (browser) — PASS*
- **Evidence:** Playwright Chromium: login (`owner@eventflow.com`) → `/dashboard` with real data → customers list (399 rows, Page 1 of 40) → customer detail → logout (redirect `/login`, `localStorage` tokens cleared, refresh reuse → 401). Keyboard a11y: first Tab = "Skip to content", Enter moves focus to `#main-content`. Console clean except deliberate probes. Screenshots `01-dashboard-1440.png`, `02…`, `03…`, `05-reports-page.png`, `08-recovered-customers.png`.
- **Issues:** access token remains usable for up to 60 min after logout (§5).

### 37. Cross-browser compatibility — SKIPPED
- **Evidence:** Playwright browser registry contains Chromium + headless shell only (no Firefox/WebKit binaries installed; installing them was not authorized in this pass).
- **Issues:** re-run the E2E suite on Firefox + WebKit before production sign-off.

### 38. Responsive layout & mobile — PASS*
- **Evidence:** overflow measurements (`document.scrollWidth` vs viewport) at 375 / 768 / 1440 px: `/dashboard` **no overflow at any width**; screenshots `resp-*-{mobile,tablet,desktop}.png`.
- **Issues:** tables are not responsive — `/customers` overflows at 375 px (506 vs 360) and 768 px (872 vs 753); `/bookings` overflows at 375 px (673 vs 360) and 768 px (1104 vs 753). Mobile users must scroll horizontally; consider responsive table/card patterns.

### 39. Accessibility (WCAG 2.2 / axe-core) — PASS*
- **Evidence:** axe-core 4.12.1 (injected from `frontend/node_modules/axe-core/axe.min.js`): `/dashboard` **0 violations** (39 passes); `/login` 2 (color-contrast, page-has-heading-one); `/customers/2` 3 color-contrast; `/invoices` 9; `/settings` 12; `/bookings` 15 (incl. **2 critical button-name** on unnamed Radix comboboxes + 11 contrast + 2 nested-interactive); `/payments` 11 (2 button-name); `/leads` 12 (2 button-name); `/notifications` 3 (1 button-name, 1 contrast, 1 heading-order).
- **Issues:** unnamed interactive controls on bookings/payments/leads/notifications are the highest-priority a11y defects (screen-reader blockers); repeated contrast failures on muted text (`#65758b` on `#f8fafc` = 4.48:1, amber `#f59e0b` = 2.05:1) fail AA (4.5:1 / 3:1).

### 40. Build & static analysis — PASS*
- **Evidence:** `npx tsc --noEmit` → **0 errors**; `npx next lint` → **exit 0**, 3 `no-img-element` warnings (`/tmp/opencode/eventflow-logs/lint-final.log`); `next build` → `✓ Compiled successfully`, `✓ Generating static pages (75/75)`, 83 routes (`/tmp/opencode/eventflow-logs/build-final.log`).
- **Issues:** replace `<img>` with `next/image` on the 3 flagged spots to silence LCP warnings.

---

## Findings register

| ID | Sev | Finding | Reference |
|---|---|---|---|
| F-01 | **Critical** | 89 known Python vulns (Django 4.2.16 ×60, PyJWT ×21, urllib3, DRF, SimpleJWT, multidict) | `pip-audit` → `logs/pip-audit.json`, `requirements/base.txt:1,11` |
| F-02 | **Critical** | 1 critical + 4 high npm vulns (Next.js DoS advisories, axios prototype pollution, postcss XSS) | `logs/npm-audit.json` |
| F-03 | High | Razorpay webhook gateway lookup not tenant-scoped | `config/api_router.py:46-52`, `test_business_logic.py:149` |
| F-04 | High | Plan quota enforcement is a stub (`EnforceVenueLimit`→True, `EnforceUserLimit` unused) | `permissions/feature_limits.py`, `test_business_logic.py:347,358` |
| F-05 | High | Zero/negative payment amounts accepted → revenue distortion | `services/payment_service.py:28`, `test_business_logic.py:275,368` |
| F-06 | High | Duplicate `(tenant, mobile)` POST → HTTP 500 (`IntegrityError`) | `test_data_validation.py:70` |
| F-07 | Medium | Customer CREATE not audited (only MERGE) | `services/customer_service.py:29`, `test_audit_compliance.py:135` |
| F-08 | Medium | `/privacy/submit/` drops/ignores `privacy_acknowledged` | `apps/privacy/serializers.py:9`, `test_audit_compliance.py:203` |
| F-09 | Medium | Login storm → 3× HTTP 500 (SQLite `database is locked`); needs MySQL re-test + graceful 503 | `logs/load-test.json` |
| F-10 | Medium | HTML (non-JSON) 404 for unknown API route, `/api/v1/reports/`, `/api/v1/settings/` | `test_api_contract.py:172,189,200` |
| F-11 | Medium | `/bookings`, `/payments`, `/leads`, `/notifications` have unnamed controls (axe critical) + widespread contrast failures | axe scans §39 |
| F-12 | Medium | `/customers` and `/bookings` tables overflow at 375/768 px | measurements §38 |
| F-13 | Low | Revenue report header shows "Period: Invalid Date – Invalid Date" | `06-revenue-report-invalid-date.png` |
| F-14 | Low | `deploy/scripts/backup.sh` has no restore counterpart/drill on MySQL | `deploy/scripts/backup.sh` |
| F-15 | Low | Upload limits inconsistent (validator 20 MB vs `DATA_UPLOAD_MAX_MEMORY_SIZE` 10 MB) | `base.py:126`, `production.py:84` |
| F-16 | Low | Server-down UI indistinguishable from logged-out (redirects to login) | `07-backend-down-customers.png` |
| F-17 | Low | Access token survives logout up to 60 min (no denylist) | `config/settings/base.py` JWT config |
| F-18 | Low | 3 `no-img-element` lint warnings; lowest coverage in gateway/notification modules | `logs/lint-final.log`, `coverage-final.json` |

---

## Limitations & not tested (with reasons)

1. **MySQL / production settings** — local stack runs SQLite + `config.settings.local`; `config.settings.production` boot requirements were verified by code/config inspection only (it raises without secrets).
2. **Real-time/WebSocket** — no `channels`/`socket.io`/`ws` in the tree; feature N/A.
3. **Firefox / WebKit** — Playwright Chromium-only install (§37).
4. **Email/SMS delivery (SMTP, Twilio, WhatsApp)** — external providers not contacted; provider adapters are covered only by unit-level mocks (also the least-covered modules, §1).
5. **Razorpay live payments** — sandbox/live capture not exercised; webhook crypto verified with computed HMACs only.
6. **Edge stack (nginx CSP/HSTS, TLS)** — configuration evidence only; no nginx running locally (§12).
7. **Production load numbers** — all §30–§32 results are single-process/SQLite and must be re-run on the production topology.
8. **No production deployment, destructive migration, or git commit/push** was performed in this pass (per policy).

## Reproduce

```bash
# backend
cd backend && ./venv/bin/python manage.py runserver 0.0.0.0:8000 --settings=config.settings.local
./venv/bin/python -m pytest -q                      # 396 passed, 1 skipped, 11 xfailed
./venv/bin/python -m pytest tests/preprod -q        # 125 passed, 1 skipped, 11 xfailed
./venv/bin/python -m pytest --cov -q                # 84.6% lines

# frontend
cd frontend && npx tsc --noEmit && npx next lint && npm run build

# audits
cd backend && ./venv/bin/pip-audit --format json
cd frontend && npm audit --omit=dev
```

## Artifact index

- Test logs: `/tmp/opencode/eventflow-logs/` (`pytest-final-full2.log`, `preprod-final.log`, `pytest-cov-final.log`, `tsc-final.log`, `lint-final.log`, `build-final.log`, `load-test.json`, `chaos.log`, `pip-audit.json`, `npm-audit.json`, `db-*.log`, `upload-*.json`)
- Screenshots: `/home/builddastaan/EventFlow/.playwright-mcp/evidence/` (`01`–`08`, `resp-*`)
- Backup drill: `/tmp/opencode/eventflow-backup/`
- Load/chaos harnesses: `/tmp/opencode/eventflow-qa/` (`load_test.py`, `chaos_test.sh`, `kill_backend.sh`, `start_backend.sh`)
- Test suites: `backend/tests/preprod/` (11 files, incl. `test_operations.py` for health/readiness/headers/CORS)

**Post-run environment state:** test data cleaned — customers back to the single seed row, QA contact messages and uploaded files removed; `/health/` 200, `/ready/` 200; backend and frontend left running.
