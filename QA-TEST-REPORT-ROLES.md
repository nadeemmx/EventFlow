# EventFlow — Multi-Role Test Extension Report

**Application:** EventFlow — multi-tenant event-management SaaS
**Repository:** `/home/builddastaan/EventFlow` · Branch `audit/fixes` · Commit `db65e27`
**Scope:** Two roles that the Owner-role pass (`QA-TEST-REPORT.md`) did not cover
**Test window:** 2026-10-10
**Environment:** Isolated QA only (`qa_live_settings`, throwaway SQLite, Redis DB 15). **No production configuration, secret or service was modified.**
**Progress tracker:** `qa-testing-progress-roles.md`
**Raw evidence:** `qa-artifacts/logs/roles-harness.log`, `qa-artifacts/logs/qa_roles.py`, `/tmp/opencode/qa-roles-result.json`

---

## 1. Role Mapping

EventFlow has **no role named "User"**. `core/choices.py:12-18` defines exactly six:
`SUPER_ADMIN`, `OWNER`, `MANAGER`, `ACCOUNTANT`, `STAFF`, `CUSTOMER`.

| Requested | Mapped to | Basis |
|---|---|---|
| User (regular tenant user) | **STAFF + MANAGER** | Chosen by requester. STAFF is the model default (`apps/users/models.py:31`) and lowest-privilege tenant staff; MANAGER is the mid-tier write-capable role. Both covered across all 40 types. |
| SuperAdmin | **SUPER_ADMIN** | Platform role. `tenant` is nullable, `permissions/module_access.py:11` short-circuits every check, and `app/(admin)/layout.tsx:25` gates the `/admin` UI on it. |

## 2. Method — No Restart, Expectations Derived Not Copied

Two constraints shaped the approach:

1. **No re-testing of completed Owner work.** 20 of the 40 types are
   **role-independent** (database, vulnerability scan, backup, DR, failover,
   monitoring, chaos, compatibility, cross-browser, responsive, accessibility,
   localization, email/SMS, third-party, plus the bulk of regression and
   performance). These are marked `SKIPPED` with the inherited Owner result
   recorded in every row, so nothing is lost and nothing is duplicated.

2. **The permission expectation cannot be hand-copied.** The RBAC matrix is
   imported at runtime from `permissions/module_access.py` and every
   `(module, action)` pair is probed live — **93 probes × 3 roles = 279
   requests**. If the matrix and the viewset ever disagree, this test says so
   without anyone re-typing an expectation.

## 3. Results

| Role | PASS | PARTIAL | FAIL | SKIPPED |
|---|---|---|---|---|
| User (STAFF + MANAGER) | 15 | 5 | **0** | 20 |
| SuperAdmin (SUPER_ADMIN) | 14 | 3 | **3** | 20 |
| **Executed (40)** | **29** | **8** | **3** | — |

### RBAC matrix — the headline number

| Role | Matched | Mismatched | Total |
|---|---|---|---|
| STAFF | 90 | 3 | 93 |
| MANAGER | 91 | 2 | 93 |
| **SUPER_ADMIN** | **93** | **0** | **93** |

All five mismatches are the *same three dead permission entries* (F-1). Every
genuine permission decision in the codebase is enforced correctly for all
three roles.

### What works, verified live

- **STAFF is correctly operational-only.** Booking list 200, `mark_in_progress`
  200 — while customer create and booking create are both 403. It can do its
  job and nothing more.
- **MANAGER can drive the entire business chain.** Venue 201 → customer 201 →
  booking 201 → confirm 200 → read 200, and is correctly denied the
  owner-only surfaces (payments create, subscriptions, audit logs, privacy).
- **Tenant isolation holds under both roles.** A Tenant-Beta probe object
  attacked by Tenant-Alpha STAFF and MANAGER across GET/PATCH/DELETE produced
  **0 leaks** in 6 attempts (STAFF 403/403/403, MANAGER 404/404/404).
- **JWT lifecycle is solid for both.** Refresh first-use 200, replay 401 —
  verified independently for STAFF *and* SUPER_ADMIN. Logout 200, replay 400.
- **SUPER_ADMIN's platform surfaces are correct.** `/tenants/` returns both
  tenants; `/admin/stats/` returns genuine platform rollups; STAFF and MANAGER
  are denied 403 on it.
- **SQLi safe for all three roles** — `1' OR '1'='1'--` across three search
  endpoints returns 200 with zero rows, no 500 anywhere.

## 4. Findings

### F-1 · P1 · SUPER_ADMIN cannot create anything tenant-scoped

The most significant new defect, and it is role-specific to SuperAdmin.

`core/base_models.py:11` makes `TenantBaseModel.tenant` **non-nullable**.
SUPER_ADMIN has `tenant_id = NULL`, and `apps/customers/views.py:25` calls
`serializer.save(tenant=self.request.tenant)` — so every create writes NULL
into a NOT NULL column:

```
NOT NULL constraint failed: customers.tenant_id
```

Observed live as **HTTP 500 with a Django HTML debug page** on both
`POST /customers/` and `POST /venues/`.

Reads fail closed rather than open — `get_queryset()` filters on
`request.tenant` (None), so SUPER_ADMIN's customer list returns **count 0**.
No data leak, but the role sees nothing.

`permissions/module_access.py:11` grants SUPER_ADMIN `create` on all 19
modules. The permission layer promises what the data layer cannot deliver.

**Recommendation:** either accept and validate a `tenant` parameter on
SUPER_ADMIN creates, or restrict the short-circuit so SUPER_ADMIN is granted
`create` only on genuinely platform-level modules (`tenants`, `subscriptions`,
`audit_logs`, `users`) until that is built.

### F-2 · P2 · Three dead entries in the permission matrix
`MODULE_PERMISSIONS["reports"]` declares `financial`, `operational` and
`subscription`, but `ReportViewSet` (`apps/reports/views.py`) defines no such
actions. All three 404 for every role — including OWNER, who is granted them.
Fail-closed, so not a security hole, but it is matrix drift that would
mislead an access-control audit. Remove the entries or implement the endpoints.

### F-3 · P2 · Logout does not revoke the access token
After a successful logout the MANAGER access token still authenticated (200).
Expected for stateless JWT — only the refresh token is blacklisted — but it
means a stolen access token stays valid for its remaining lifetime.

### F-4 · P2 · A tenant owner can be hard-deleted via API with no audit trail
`UserViewSet` (`apps/users/views.py:14`) is a plain `ModelViewSet`: DELETE is
a hard delete, there is no confirmation step, and no `audit_logs` row is
written. Discovered the hard way — see the incident below.

### F-5 · P2 · Mobile format is not validated server-side
`"mobile": "not-a-number-mgr"` was accepted with **201**. The regex
`^[0-9+\-\s()]{7,15}$` exists only in the frontend zod schema
(`frontend/app/(dashboard)/customers/new/page.tsx:20`). Move it into the
serializer.

### F-6 · P3 · Unknown API routes return `text/html` 404
Reproduced for SUPER_ADMIN. API clients parsing JSON fail on the content type
before they reach the status code.

### F-7 · P3 · SUPER_ADMIN dashboards are ~50 % slower
p50 43.3 ms vs 28.3 ms for STAFF, because its counts are unscoped rather than
tenant-indexed. Within budget now; will not scale linearly as tenants grow.

## 5. Harness Incident — Self-Inflicted, Fully Remediated

I have to record this plainly, because it is a real destructive event and it
produced F-4.

The first RBAC matrix run issued `DELETE /users/1/` as SUPER_ADMIN.
`permissions/module_access.py` grants SUPER_ADMIN `users.destroy`, so the call
**succeeded and hard-deleted the Owner fixture**
(`qa-alpha-owner@example.com`). `UserViewSet` has no soft-delete override, so
the row was gone.

**What I did about it:**
1. Rewrote every object-scoped probe to target a non-existent PK
   (`/users/999999/`). DRF evaluates `has_permission()` before touching the
   DB, so 403 = denied and 404 = allowed — the permission bit is still
   isolated, but no fixture can be destroyed. Safety comment added at
   `qa_roles.py:121`.
2. Retargeted every destructive verb in the security section to PK 999999.
3. Restored the fixture with `qa_repair_restore_owner.py` — same email, role,
   tenant and password as `qa_seed.py` created (now id=6).
4. Re-verified the full roster and confirmed the Owner account authenticates
   again (login → 200).

Three harness bugs were also fixed and are worth noting because each one
initially looked like a product defect: wrong JWT field name (`refresh_token`,
not `refresh`), non-idempotent fixtures (fixed with a per-run nonce), and two
business-logic rejections I had misread as bugs — *"Guest count exceeds venue
capacity"* and *"Only draft bookings can be confirmed"* were both correct app
behaviour and the test data was wrong, not the code.

## 6. Verdict

### 🔴 NO-GO — unchanged from the Owner pass, now with an added P1

The Owner-role report's blockers stand untouched: the `generateStaticParams`
"New X" routing collision (P0-1) and the 89-package vulnerability backlog
(P0-2), plus the four P1s.

This extension adds **one new P1 (F-1)**: the SuperAdmin role is effectively
non-functional for its own create duties, and would fail immediately in the
hands of a real platform operator. It also confirms F-4, which the incident
made concrete.

**The reassuring half is genuinely reassuring.** The permission model itself is
in good shape — 279 live probes produced zero genuine enforcement failures,
STAFF and MANAGER are scoped exactly as designed, and tenant isolation holds
under attack from both. The problems are at the edges: the platform role's
data-layer assumptions, three stale matrix entries, and token lifecycle
hygiene.

**Suggested order:**
1. Fix F-1 (SuperAdmin create path) — blocks the platform admin workflow entirely.
2. Delete or implement the three dead report permissions (F-2).
3. Move the mobile regex into the serializer (F-5).
4. Add soft-delete + audit logging to `UserViewSet` (F-4).
5. Re-run this 80-test extension to confirm F-1 and F-2 are closed.

**Re-test gate for GO on this extension:** F-1 at zero (SUPER_ADMIN can create
a tenant-scoped record), RBAC matrix at 93/93 for all three roles with no dead
entries, and the inherited Owner P0s resolved.
