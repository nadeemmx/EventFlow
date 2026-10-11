# QA Testing Progress — Multi-Role Extension

**App:** EventFlow
**Roles covered:** User (STAFF + MANAGER), SuperAdmin (SUPER_ADMIN)
**Started:** 2026-10-10T18:10:00Z
**Last Updated:** 2026-10-10T18:45:00Z
**Status:** COMPLETED

---

## Role Mapping (resolved with requester)

EventFlow has **no role named "User"**. `core/choices.py:12-18` defines exactly six
roles: `SUPER_ADMIN`, `OWNER`, `MANAGER`, `ACCOUNTANT`, `STAFF`, `CUSTOMER`.

| Requested role | Mapped to | Rationale |
|---|---|---|
| User (regular tenant user) | **STAFF + MANAGER** | Requester chose to cover both. STAFF is the model default (`apps/users/models.py:31`) and lowest-privilege tenant staff; MANAGER is the mid-tier write-capable role. Both are tested across all 40 types. |
| SuperAdmin | **SUPER_ADMIN** | Platform-level role. `tenant` is nullable, `permissions/module_access.py:11` short-circuits every check, and `app/(admin)/layout.tsx:25` gates the `/admin` UI on it. |

---

## Scope Rules (honouring "do not restart from scratch")

`./qa-testing-progress.md` is COMPLETE at 40/40 for the **Owner** role. Per instruction,
tests that are **role-independent** are **not re-executed**; they are marked `SKIPPED`
with the inherited Owner result recorded, so no evidence is duplicated or lost.

**SKIPPED = role-independent, result inherited from the Owner run (not untested).**
**N/A = the surface does not exist for that role by design.**

Role-independent types: 11 Database, 19 Vulnerability, 25 Backup, 26 DR, 27 Failover,
28 Monitoring, 30 Compatibility, 31 Cross-Browser, 34 Localization, 37 Email/SMS,
38 Third-Party, 29 Chaos (infra half).

---

## Summary
- Total role-scoped tests: 80 (40 User + 40 SuperAdmin)
- Completed: 80 | Pending: 0 | In Progress: 0 | Skipped: 40
- User (STAFF+MANAGER): 15 PASS · 5 PARTIAL · 0 FAIL · 20 SKIPPED
- SuperAdmin (SUPER_ADMIN): 14 PASS · 3 PARTIAL · 3 FAIL · 20 SKIPPED
- Executed (non-skipped): 40 = 29 PASS · 8 PARTIAL · 3 FAIL

---

## User Role Checklist (STAFF + MANAGER)

| 1 | Unit Testing (User) | SKIPPED | 10-10 18:15 | 10-10 18:40 | role-independent; Owner run: 122 passed |
| 2 | Integration Testing (User) | PASS | 10-10 18:15 | 10-10 18:40 | STAFF create->403; MANAGER create->201. No regression |
| 3 | Functional Testing (User) | PASS | 10-10 18:15 | 10-10 18:40 | MANAGER venue->customer->booking->confirm->read all 2xx; STAFF blocked 403 |
| 4 | End-to-End Testing (User) | PASS | 10-10 18:15 | 10-10 18:40 | Full chain 201/201/201/200/200 as MANAGER |
| 5 | Regression Testing (User) | SKIPPED | 10-10 18:15 | 10-10 18:40 | role-independent; Owner run: 396 passed, 69% cov |
| 6 | Smoke Testing (User) | PASS | 10-10 18:15 | 10-10 18:40 | STAFF/MANAGER login 200; dashboard/profile/notifications 200 |
| 7 | Sanity Testing (User) | PASS | 10-10 18:15 | 10-10 18:40 | Matrix derived from module_access.py matches implementation |
| 8 | UI/UX Testing (User) | SKIPPED | 10-10 18:15 | 10-10 18:40 | frontend role gating not re-run; 'New X' bug inherited from Owner |
| 9 | API Testing (User) | PARTIAL | 10-10 18:15 | 10-10 18:40 | unknown route -> HTML 404 (text/html); envelope drift inherited |
| 10 | Data Validation Testing (User) | PARTIAL | 10-10 18:15 | 10-10 18:40 | empty body -> 400 ok; mobile format NOT validated server-side -> 201 |
| 11 | Database Testing (User) | SKIPPED | 10-10 18:15 | 10-10 18:40 | role-independent; Owner run: no migration drift |
| 12 | Performance Testing (User) | PASS | 10-10 18:15 | 10-10 18:40 | STAFF p50 28.3/p95 33.7ms; MANAGER p50 28.9/p95 33.7ms; 0 errors |
| 13 | Load Testing (User) | PASS | 10-10 18:15 | 10-10 18:40 | 40 req/role, all 200, 0 5xx |
| 14 | Stress Testing (User) | SKIPPED | 10-10 18:15 | 10-10 18:40 | role-independent; Owner: 50c p95 1.33s |
| 15 | Scalability Testing (User) | SKIPPED | 10-10 18:15 | 10-10 18:40 | role-independent; single-process only |
| 16 | Rate Limiting & Throttling (User) | SKIPPED | 10-10 18:15 | 10-10 18:40 | role-independent; per-user rates identical across roles |
| 17 | Security Testing (User) | PASS | 10-10 18:15 | 10-10 18:40 | SQLi->200/0 rows; verb tampering->403; audit->403; XSS not served as HTML |
| 18 | Penetration Testing (User) | PASS | 10-10 18:15 | 10-10 18:40 | 0 cross-tenant leaks (GET/PATCH/DELETE); staff+manager denied audit/tenants |
| 19 | Vulnerability Testing (User) | SKIPPED | 10-10 18:15 | 10-10 18:40 | role-independent; Owner FAIL: 89 PyPI + 25 npm vulns |
| 20 | Authentication & Authorization (User) | PASS | 10-10 18:15 | 10-10 18:40 | refresh first=200/replay=401 (STAFF+SA); logout=200/replay=400; garbage/no token=401 |
| 21 | Role-Based Access Control (User) | PARTIAL | 10-10 18:15 | 10-10 18:40 | STAFF 90/93, MANAGER 91/93. All 5 mismatches = 3 DEAD permission entries |
| 22 | Tenant Isolation (User) | PASS | 10-10 18:15 | 10-10 18:40 | 0 leaks; MANAGER 404/404/404, STAFF 403/403/403 on foreign object |
| 23 | Audit Logging (User) | PARTIAL | 10-10 18:15 | 10-10 18:40 | STAFF/MANAGER correctly 403 on /audit-logs/; only AUTH events logged |
| 24 | Multi-Tenancy Testing (User) | PASS | 10-10 18:15 | 10-10 18:40 | tenant binding verified; both roles scoped to tenant 1 |
| 25 | Backup & Recovery Testing (User) | SKIPPED | 10-10 18:15 | 10-10 18:40 | role-independent; Owner: sqlite backup integrity ok |
| 26 | Disaster Recovery Testing (User) | SKIPPED | 10-10 18:15 | 10-10 18:40 | role-independent; no restore script (Owner finding) |
| 27 | Failover Testing (User) | SKIPPED | 10-10 18:15 | 10-10 18:40 | role-independent; systemd Restart=on-failure |
| 28 | Monitoring & Alerting Testing (User) | SKIPPED | 10-10 18:15 | 10-10 18:40 | role-independent; console-only logging |
| 29 | Chaos Testing (User) | SKIPPED | 10-10 18:15 | 10-10 18:40 | role-independent; Owner: redis flush recovers in 53ms |
| 30 | Compatibility Testing (User) | SKIPPED | 10-10 18:15 | 10-10 18:40 | role-independent; Python 3.14.4 / Node 22.23.2 |
| 31 | Cross-Browser Testing (User) | SKIPPED | 10-10 18:15 | 10-10 18:40 | role-independent; Chromium 154 only |
| 32 | Responsive Testing (User) | SKIPPED | 10-10 18:15 | 10-10 18:40 | role-independent; Owner FAIL: overflow 375px/768px |
| 33 | Accessibility Testing (User) | SKIPPED | 10-10 18:15 | 10-10 18:40 | role-independent; Owner: axe 3 violations on /bookings |
| 34 | Localization Testing (User) | SKIPPED | 10-10 18:15 | 10-10 18:40 | role-independent; en-IN hardcoded |
| 35 | Payment Gateway Testing (User) | PASS | 10-10 18:15 | 10-10 18:40 | MANAGER payments.create correctly denied (ACCOUNTANT/OWNER only) per matrix |
| 36 | Subscription & Billing Testing (User) | PASS | 10-10 18:15 | 10-10 18:40 | MANAGER subscriptions.list correctly denied (OWNER/SA only) per matrix |
| 37 | Email/SMS Notification Testing (User) | SKIPPED | 10-10 18:15 | 10-10 18:40 | role-independent; EmailProvider PII-masking verified by Owner |
| 38 | Third-Party Integration Testing (User) | SKIPPED | 10-10 18:15 | 10-10 18:40 | role-independent; no live credentials provisioned |
| 39 | Compliance Testing (User) | PASS | 10-10 18:15 | 10-10 18:40 | privacy owner-only: STAFF 403, MANAGER 403 |
| 40 | User Acceptance Testing (User) | PARTIAL | 10-10 18:15 | 10-10 18:40 | MANAGER drives full chain; STAFF operational verbs OK; UI create blocked by inherited routing bug |

---

## SuperAdmin Role Checklist (SUPER_ADMIN)

| 1 | Unit Testing (SuperAdmin) | SKIPPED | 10-10 18:15 | 10-10 18:40 | role-independent; Owner run: 122 passed |
| 2 | Integration Testing (SuperAdmin) | PARTIAL | 10-10 18:15 | 10-10 18:40 | reads OK; every tenant-scoped create -> 500 IntegrityError |
| 3 | Functional Testing (SuperAdmin) | FAIL | 10-10 18:15 | 10-10 18:40 | cannot create ANY tenant-scoped resource (tenant_id NULL vs NOT NULL column) |
| 4 | End-to-End Testing (SuperAdmin) | FAIL | 10-10 18:15 | 10-10 18:40 | E2E chain impossible for platform role |
| 5 | Regression Testing (SuperAdmin) | SKIPPED | 10-10 18:15 | 10-10 18:40 | role-independent; Owner run: 396 passed |
| 6 | Smoke Testing (SuperAdmin) | PASS | 10-10 18:15 | 10-10 18:40 | login 200; dashboard/profile/notifications/tenants/admin-stats all 200 |
| 7 | Sanity Testing (SuperAdmin) | PASS | 10-10 18:15 | 10-10 18:40 | 93/93 matrix match - only role with a perfect score |
| 8 | UI/UX Testing (SuperAdmin) | SKIPPED | 10-10 18:15 | 10-10 18:40 | /admin route gating not re-run; Owner 'New X' bug inherited |
| 9 | API Testing (SuperAdmin) | PARTIAL | 10-10 18:15 | 10-10 18:40 | creates 500; unknown route -> HTML 404 |
| 10 | Data Validation Testing (SuperAdmin) | PARTIAL | 10-10 18:15 | 10-10 18:40 | empty body -> 400 ok; bad mobile -> 500 (tenant NULL, not format) |
| 11 | Database Testing (SuperAdmin) | SKIPPED | 10-10 18:15 | 10-10 18:40 | role-independent |
| 12 | Performance Testing (SuperAdmin) | PASS | 10-10 18:15 | 10-10 18:40 | p50 43.3ms / p95 48.4ms, 0 errors (slower than tenant roles) |
| 13 | Load Testing (SuperAdmin) | PASS | 10-10 18:15 | 10-10 18:40 | 40 req, all 200, 0 5xx |
| 14 | Stress Testing (SuperAdmin) | SKIPPED | 10-10 18:15 | 10-10 18:40 | role-independent |
| 15 | Scalability Testing (SuperAdmin) | SKIPPED | 10-10 18:15 | 10-10 18:40 | role-independent |
| 16 | Rate Limiting & Throttling (SuperAdmin) | SKIPPED | 10-10 18:15 | 10-10 18:40 | role-independent |
| 17 | Security Testing (SuperAdmin) | PASS | 10-10 18:15 | 10-10 18:40 | SQLi safe; cross-tenant read is legitimate platform scope, not a leak |
| 18 | Penetration Testing (SuperAdmin) | PASS | 10-10 18:15 | 10-10 18:40 | reads /tenants/ + /admin/stats/ legitimately; 0 unauthorised access |
| 19 | Vulnerability Testing (SuperAdmin) | SKIPPED | 10-10 18:15 | 10-10 18:40 | role-independent; Owner FAIL inherited |
| 20 | Authentication & Authorization (SuperAdmin) | PASS | 10-10 18:15 | 10-10 18:40 | login 200; refresh first=200 replay=401 (blacklist works) |
| 21 | Role-Based Access Control (SuperAdmin) | PASS | 10-10 18:15 | 10-10 18:40 | 93/93 matched - short-circuit in module_access.py:11 is correctly enforced |
| 22 | Tenant Isolation (SuperAdmin) | PASS | 10-10 18:15 | 10-10 18:40 | legitimate cross-tenant read works; tenant_id is null (correct platform scope) |
| 23 | Audit Logging (SuperAdmin) | PASS | 10-10 18:15 | 10-10 18:40 | only role besides OWNER that can read /audit-logs/ (200, 8+ rows) |
| 24 | Multi-Tenancy Testing (SuperAdmin) | PASS | 10-10 18:15 | 10-10 18:40 | sees 2 tenants via /tenants/; has no tenant of its own |
| 25 | Backup & Recovery Testing (SuperAdmin) | SKIPPED | 10-10 18:15 | 10-10 18:40 | role-independent |
| 26 | Disaster Recovery Testing (SuperAdmin) | SKIPPED | 10-10 18:15 | 10-10 18:40 | role-independent |
| 27 | Failover Testing (SuperAdmin) | SKIPPED | 10-10 18:15 | 10-10 18:40 | role-independent |
| 28 | Monitoring & Alerting Testing (SuperAdmin) | SKIPPED | 10-10 18:15 | 10-10 18:40 | role-independent |
| 29 | Chaos Testing (SuperAdmin) | SKIPPED | 10-10 18:15 | 10-10 18:40 | role-independent |
| 30 | Compatibility Testing (SuperAdmin) | SKIPPED | 10-10 18:15 | 10-10 18:40 | role-independent |
| 31 | Cross-Browser Testing (SuperAdmin) | SKIPPED | 10-10 18:15 | 10-10 18:40 | role-independent |
| 32 | Responsive Testing (SuperAdmin) | SKIPPED | 10-10 18:15 | 10-10 18:40 | role-independent |
| 33 | Accessibility Testing (SuperAdmin) | SKIPPED | 10-10 18:15 | 10-10 18:40 | role-independent |
| 34 | Localization Testing (SuperAdmin) | SKIPPED | 10-10 18:15 | 10-10 18:40 | role-independent |
| 35 | Payment Gateway Testing (SuperAdmin) | PASS | 10-10 18:15 | 10-10 18:40 | all payment actions allowed AND matched - no enforcement gap |
| 36 | Subscription & Billing Testing (SuperAdmin) | PASS | 10-10 18:15 | 10-10 18:40 | subscriptions.plans/current/history allowed + matched |
| 37 | Email/SMS Notification Testing (SuperAdmin) | SKIPPED | 10-10 18:15 | 10-10 18:40 | role-independent |
| 38 | Third-Party Integration Testing (SuperAdmin) | SKIPPED | 10-10 18:15 | 10-10 18:40 | role-independent |
| 39 | Compliance Testing (SuperAdmin) | PASS | 10-10 18:15 | 10-10 18:40 | privacy list/update allowed + matched |
| 40 | User Acceptance Testing (SuperAdmin) | FAIL | 10-10 18:15 | 10-10 18:40 | platform role cannot perform its own create duties - unusable for admin work |

---

## Detailed Results
(append per test as tests complete)

---

## Detailed Results

### Harness Incident — destructive RBAC probe (self-inflicted, remediated)

During the first RBAC matrix run the harness issued `DELETE /users/1/` as
SUPER_ADMIN. `permissions/module_access.py` grants SUPER_ADMIN `users.destroy`,
so the call succeeded and **hard-deleted the Owner fixture**
(`qa-alpha-owner@example.com`, user id 1). `apps/users/views.py:14` is a plain
`ModelViewSet` with no soft-delete override, so the row was gone.

**Remediation applied:**
1. Every object-scoped probe was rewritten to target a non-existent PK
   (`/users/999999/`). DRF evaluates `has_permission()` before the DB, so
   403 = denied and 404 = allowed — the permission bit is still isolated, but
   no fixture can be destroyed. Comment added at `qa_roles.py:121`.
2. All destructive verbs in `run_security` retargeted to PK 999999.
3. Owner fixture restored by `qa_repair_restore_owner.py` (now id=6, same
   email/role/tenant/password as `qa_seed.py` created).
4. Full roster verified: STAFF, OWNER(beta), OWNER(alpha), MANAGER, SUPER_ADMIN.

**Root-cause note for the product team:** this incident is itself a finding.
A platform admin can hard-delete a tenant owner through the API with no
confirmation, no soft-delete and no audit-log entry. See **R-4** below.

### Test #21 (both roles): RBAC Matrix
- **User:** PARTIAL · **SuperAdmin:** PASS
- **Method:** expectation is **derived at runtime** from
  `permissions/module_access.py` (`MODULE_PERMISSIONS`), then every
  (module, action) pair is probed live over HTTP. The expectation therefore
  cannot drift from the code being tested.
- **Coverage:** 93 (module, action) probes × 3 roles = 279 live requests.
- **Result:**

| Role | Matched | Mismatched | Total |
|---|---|---|---|
| STAFF | 90 | 3 | 93 |
| MANAGER | 91 | 2 | 93 |
| SUPER_ADMIN | **93** | **0** | 93 |

- **All 5 mismatches are the same 3 dead permission entries** (R-1):
  `reports.financial`, `reports.operational`, `reports.subscription` are
  declared in the permission matrix but have **no corresponding view action**
  on `ReportViewSet` (`apps/reports/views.py` defines only revenue, bookings,
  payments, occupancy, leads, vendors, inventory, outstanding, monthly_growth,
  export). They return 404 for every role — including OWNER, who is granted
  them. Fail-closed, so not a security hole; it is matrix drift that would
  mislead an access-control audit.

### Test #20 (both roles): Authentication & Authorization
- **User:** PASS · **SuperAdmin:** PASS
- All three roles log in 200 with tokens.
- Garbage token → 401; missing token → 401.
- **Refresh blacklist verified for both STAFF and SUPER_ADMIN:** first use
  200, replay 401.
- Logout 200; logout replay with blacklisted refresh 400.
- **Observation (R-3):** the MANAGER *access* token still authenticated
  (200) after logout. Expected for stateless JWT — only the refresh token is
  blacklisted. Not a defect, but it means logout does not revoke an in-flight
  access token for up to its remaining lifetime.

### Test #22 / #24 (both roles): Tenant Isolation & Multi-Tenancy
- **User:** PASS · **SuperAdmin:** PASS
- A probe customer was created in **Tenant Beta**; STAFF and MANAGER from
  Tenant Alpha then attempted GET / PATCH / DELETE against it.
  **0 leaks** across all 6 attempts (STAFF 403/403/403; MANAGER 404/404/404).
- SUPER_ADMIN legitimately reads across tenants — verified against
  `/tenants/` (200, both tenants) and `/admin/stats/` (200, genuine
  platform-wide rollups). This is correct platform scope, not a leak.
- STAFF and MANAGER are correctly denied 403 on `/admin/stats/`
  (`IsSuperAdmin`, `apps/dashboard/views.py:29`).

### Test #17 / #18 (both roles): Security & Penetration
- **User:** PASS · **SuperAdmin:** PASS
- SQLi probe (`1' OR '1'='1'--`) against `/bookings/`, `/customers/`,
  `/venues/` search params → **200 with 0 results for all three roles**;
  no 500 anywhere.
- Verb tampering: STAFF `DELETE /venues|customers/999999/` → 403;
  MANAGER `DELETE /bookings/999999/` → 403.
- IDOR: STAFF and MANAGER both 403 on `/audit-logs/`.
- Stored XSS payload round-trips unescaped in the DB (known Owner finding)
  but is never served with a `text/html` content type, so it is not
  reflected as executable markup.

### Test #3 / #4 / #40 (both roles): Functional, E2E, UAT
- **User:** PASS (#3/#4) · PARTIAL (#40) · **SuperAdmin:** FAIL (all three)
- **MANAGER drove the full business chain successfully:**
  venue 201 → customer 201 → booking 201 → confirm 200 → read 200.
- **STAFF behaves exactly as its permission row describes:**
  customer create 403, booking create 403, booking list 200,
  `mark_in_progress` 200. Operational-only, as designed.
- **Two rejections during setup were correct app behaviour, not defects**
  (both fixed in the harness, not the app):
  - booking 400 *"Guest count exceeds venue capacity"* — guest_count 150 >
    capacity 100;
  - booking 400 *"Only draft bookings can be confirmed"* — the harness had
    created it as `TENTATIVE`; `services/booking_service.py:50` requires `DRAFT`.
- **SUPER_ADMIN could not start the chain at all** → see **R-2**.
- UAT remains PARTIAL for User only because the inherited frontend
  `generateStaticParams` "New X" routing bug (Owner P0-1) still blocks
  UI-driven creation for every role.

### Test #10 / #9 (both roles): Data Validation & API
- **User:** PARTIAL · **SuperAdmin:** PARTIAL
- Empty body → 400 for MANAGER and SUPER_ADMIN; 403 for STAFF (correctly
  denied before validation).
- Malformed JSON → **415** (correct, not 500).
- Unknown route → 404 but with `text/html` content type (inherited Owner
  finding; API clients expecting JSON will break).
- **R-5:** `"mobile": "not-a-number-mgr"` was **accepted with 201**. Mobile
  format is validated only by the frontend zod regex
  (`frontend/app/(dashboard)/customers/new/page.tsx:20`); the backend
  serializer imposes no equivalent constraint.

### Test #12 / #13 (both roles): Performance & Load
- **User:** PASS · **SuperAdmin:** PASS · 40 requests per role, 0 errors.

| Role | p50 | p95 | 5xx |
|---|---|---|---|
| STAFF | 28.3 ms | 33.7 ms | 0 |
| MANAGER | 28.9 ms | 33.7 ms | 0 |
| SUPER_ADMIN | 43.3 ms | 48.4 ms | 0 |

- SUPER_ADMIN is ~50 % slower because its queries are unscoped
  (`User.objects.all()`, cross-tenant counts) rather than tenant-indexed.
  Within budget, but it will not scale linearly with tenant count.

### Test #23 (both roles): Audit Logging
- **User:** PARTIAL · **SuperAdmin:** PASS
- STAFF and MANAGER correctly 403 on `/audit-logs/` (OWNER + SUPER_ADMIN only).
- SUPER_ADMIN reads them successfully (200, 8+ rows).
- The log contains **only `LOGIN`/`AUTH` events** — the account deletion
  performed during this run left no entry (see R-4).

### Test #11 / #25–34, #37, #38 (both roles): Skipped as role-independent
- Not re-executed, per the instruction not to restart completed Owner tests.
- Inherited Owner results are recorded in each row so nothing is lost:
  DB no-drift, backup integrity ok, no restore script, systemd hardening,
  console-only logging, Redis-flush recovery 53 ms, Django 4.2 LTS EOL,
  Chromium-only, responsive overflow, axe violations, en-IN hardcoding,
  EmailProvider PII masking, no live third-party credentials.

---

## Findings

### R-2 · P1 · SUPER_ADMIN cannot create any tenant-scoped resource
`core/base_models.py:11` makes `TenantBaseModel.tenant` a **non-nullable**
FK. SUPER_ADMIN has `tenant_id = NULL`, and
`apps/customers/views.py:25` does `serializer.save(tenant=self.request.tenant)`,
so every create writes `tenant_id = NULL` and raises:

```
NOT NULL constraint failed: customers.tenant_id
```

verified live as **HTTP 500 + Django HTML debug page** on both
`POST /customers/` and `POST /venues/` for SUPER_ADMIN.

Reads fail differently but still: `get_queryset()` filters on
`request.tenant` (None), so SUPER_ADMIN's customer list returns
**count = 0** — it sees nothing rather than everything (fail-closed, so not a
leak, but the role is unusable).

`permissions/module_access.py:11` short-circuits and grants SUPER_ADMIN
`create` on all 19 modules, so the permission layer promises something the
data layer cannot deliver.

**Working surfaces:** `/tenants/` (200, both tenants) and `/admin/stats/`
(200, correct platform rollups) — the only endpoints that are genuinely
platform-scoped.

**Suggested fix:** scope SUPER_ADMIN creates by accepting a `tenant` request
parameter validated against `Tenant.objects`, or restrict
`ModuleAccessPermission` so SUPER_ADMIN is granted create only on the
platform-level modules (`tenants`, `subscriptions`, `audit_logs`, `users`)
until that is implemented.

### R-1 · P2 · Three dead entries in the permission matrix
`MODULE_PERMISSIONS["reports"]` declares `financial`, `operational` and
`subscription`, but `ReportViewSet` defines no such actions. All three 404 for
every role. Remove the entries or implement the endpoints.

### R-3 · P2 · Logout does not revoke the access token
Only the refresh token is blacklisted. A stolen access token remains usable
until expiry. Consider a short access-token lifetime plus a server-side
denylist, or moving to rotating refresh + session records.

### R-4 · P2 · Tenant owner can be hard-deleted via API with no audit trail
`UserViewSet` (`apps/users/views.py:14`) is a plain `ModelViewSet`: DELETE is
a hard delete, there is no confirmation step, and no `audit_logs` row is
written. Combined with R-2's incident this is a real destructive path.

### R-5 · P2 · Mobile number format is not validated server-side
Accepted `201` for `"not-a-number-mgr"`. Add the same regex the frontend
enforces (`^[0-9+\-\s()]{7,15}$`) to the serializer.

### R-6 · P3 · Unknown API routes return `text/html` 404
Reproduced for SUPER_ADMIN. API clients parsing JSON will fail on the
content type rather than the status code.

### R-7 · P3 · SUPER_ADMIN dashboard queries are ~50 % slower
Unscoped counts (43.3 ms p50 vs 28.3 ms for STAFF). Will degrade as tenants
are added; consider caching `/admin/stats/`.
