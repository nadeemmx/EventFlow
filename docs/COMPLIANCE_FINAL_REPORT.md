# Compliance Implementation — Final Report

Date: 2026-09-25
Scope: legal/privacy/security/accessibility/dark-pattern compliance pass across
`frontend/` (Next.js 14, static export) and `backend/` (Django 4.2 + DRF).
Companion document: `docs/COMPLIANCE_AUDIT.md` (pre-implementation audit).

---

## A. What was implemented

### A1. Legal & business information

| Item | Change | Status |
|---|---|---|
| Business/legal detail source of truth | `frontend/lib/business.ts` — env-driven (`NEXT_PUBLIC_BUSINESS_*`), never invented | Done (owner input pending) |
| Placeholder rendering | `frontend/components/legal/BusinessField.tsx` — missing values render as visible amber placeholders | Done |
| Privacy Policy | Rewritten to match the real implementation (data collected, legal bases, retention, subprocessor wording, rights, contact) | Done |
| Terms of Service | Rewritten; jurisdiction/court venue are placeholders until owner supplies them | Done (owner input pending) |
| Cookie Policy | New page; matches actual cookie usage (session/refresh tokens + consent storage) | Done |
| Refund Policy | New page `/refund-policy`; no invented SLA/guarantee language | Done |
| GDPR page | Rewritten: rights list, how to exercise them, link to `/privacy-request` | Done |
| Privacy request flow | New page `/privacy-request` with reference number, verification and 30-day expectation stated | Done |
| Footer legal links | `Refund Policy`, `Privacy Requests`, `Cookie preferences` (opens preferences panel) added; `Customers` → `/case-studies` | Done |

### A2. Consent & dark patterns

| Item | Change | Status |
|---|---|---|
| Cookie consent | `frontend/lib/consent.ts` + `components/legal/CookieConsent.tsx` — banner, manage-preferences panel, persisted version (`CONSENT_VERSION`), never pre-ticked | Done |
| Form consent | `components/legal/PrivacyConsent.tsx` — required privacy acknowledgement, **optional** marketing opt-in (unchecked by default, separate choice) | Done |
| Public forms now submit | Contact, Demo, Careers, Status-subscribe previously discarded input silently; all now POST to `POST /api/v1/contact/` with consent, required/optional labels, autocomplete, aria-live success/error states | Done |
| Careers upload | Real PDF upload (`components/marketing/CareersApplyForm.tsx`), size/type validated server-side, attached to inbox email | Done |
| Fabricated content removed | Fake testimonials, logos, metrics, team, blog/careers listings, status/help-center claims, "Join 500+ venues", "24/7 support", "zero downtime", fake demo "availability bars" — removed or rewritten honestly | Done |
| Marketing claims softened | Contact FAQ, demo availability, onboarding/migration/support answers now non-committal instead of invented guarantees | Done |

### A3. Accessibility

| Item | Change | Status |
|---|---|---|
| Skip link + main landmark | Skip link in root layout; `<main id="main-content" tabIndex={-1}>` in marketing/auth/dashboard/error layouts | Done |
| DataTable sorting | Real `<button>` sort controls + `aria-sort` on the header | Done |
| Navbar semantics | Site `h1` → paragraph; nav disclosure buttons get `aria-expanded`/`aria-controls`, `Escape` closes, focus management, nav landmarks labelled | Done |
| Combobox ARIA | invoices/payments/leads create forms use proper `combobox` roles | Done |
| Icon semantics | Decorative icons `aria-hidden`; error/success regions `role="alert"`/`role="status"` + `aria-live` | Done |
| Form a11y | Every input labelled, `aria-required`/`aria-invalid`/`aria-describedby` on error, keyboard-usable file input | Done |

### A4. Backend security & privacy (verified by tests)

| Item | Change | Status |
|---|---|---|
| Refresh token rotation | Refresh rotation + blacklist enforced; JWT auth backend fixed (admin login `username` kwarg) | Done |
| Cross-tenant isolation | FK scoping for bookings/leads/inventory/notifications; privacy requests scoped by tenant; serializers mass-assignment fixes | Done |
| Tenant creation | Auth required + mass-assignment surface reduced | Done |
| Rate limiting | New `privacy_request` (5/hour) and `contact` (10/hour) scopes registered in `base/local/test.py` | Done |
| PII in logs | Logging middleware masks email/mobile/IP | Done |
| Encryption key | `local.py` uses a stable `ENCRYPTION_KEY` (no per-boot churn) | Done |
| Management commands | Moved `management/commands/*` → `core/management/commands/` so Django discovers them | Done |
| WhatsApp threading | Provider now receives tenant when sending (`services/notification_service.py`) | Done |

### A5. New privacy feature (`backend/apps/privacy`)

| Endpoint | Behaviour | Status |
|---|---|---|
| `POST /api/v1/contact/` | AllowAny, `contact` throttle, requires `privacy_acknowledged`, sources `contact/demo/careers/status`, optional PDF resume, stores `ContactMessage`, emails inbox + requester confirmation | Done |
| `POST /api/v1/privacy/submit/` | AllowAny, `privacy_request` throttle, creates `PrivacyRequest`, returns `PR-######`, emails confirmation | Done |
| `GET /api/v1/privacy/requests/` | Authenticated, `ModuleAccessPermission` (`privacy` module: SUPER_ADMIN + OWNER), tenant-scoped (super admin sees all) | Done |
| `GET/PATCH /api/v1/privacy/requests/{id}/` | Detail + status update; `responded_at` stamped on ACTIONED/REJECTED/CLOSED; cross-tenant access → 404 | Done |
| Admin | Django admin registered for both models | Done |
| Migration | `apps/privacy/migrations/0001_initial.py` applied (+ pending `tenants/0003` field migration caught up) | Done |

---

## B. Decisions only the business owner can make

1. **Legal entity details** — set `NEXT_PUBLIC_BUSINESS_LEGAL_NAME`, `ADDRESS`, `REGISTRATION_NUMBER`, `TAX_ID`, `PHONE`, `JURISDICTION`, `DISPUTE_VENUE`, `PRIVACY_EMAIL`, `REFUNDS_EMAIL`, `POLICY_EFFECTIVE_DATE`. Until set, every page shows a visible placeholder — nothing was invented.
2. **Policy text needs a lawyer.** The pages are accurate about *what the product does*, but they are not legal advice and no jurisdiction was chosen for you.
3. **Inbox addresses** — backend `CONTACT_INBOX_EMAIL`, `PRIVACY_INBOX_EMAIL` (default `noreply@eventflow.com`). Today's email backend is **console** unless `EMAIL_HOST` is set; in production you must configure SMTP or nothing is delivered.
4. **Marketing consent** — current opt-in is an unchecked checkbox stored on the record. If you want real consent evidence (double opt-in, timestamped consent log), that is a follow-up decision.
5. **"Start Free Trial" claim** — used site-wide; the backend has a `TRIAL` subscription status, but no trial-length/limits are defined anywhere. Confirm or change the copy.
6. **Careers openings** — `positions` is intentionally empty (fabricated listings were removed). Add real roles when you have them.
7. **Status page** — `/status` has no real incident data source; confirm whether you want a real status provider or an honest "no public status page yet" state.

---

## C. Risk classification

**Mitigated (verified)**
- Cross-tenant data access, token refresh abuse, mass assignment, unauthenticated tenant creation, public-form spam (throttling + consent), PII in logs, silent no-op forms, fabricated trust signals/testimonials, basic keyboard/screen-reader blockers.

**Needs review before launch (open risk)**
- Legal accuracy/jurisdiction of policies — **owner + counsel**.
- No automated accessibility audit has been run (axe/pa11y) — fixes are manual and structural only.
- Consent is stored client-side only; there is no server-side consent log or audit trail.
- GDPR fulfilment (export/erasure) is a **manual operator workflow** — there is no automated job; retention rules are documented, not enforced by a scheduler.
- Email is not deliverable in production until SMTP is configured.
- `next.config.js` still sets `typescript.ignoreBuildErrors: true` and `eslint.ignoreDuringBuilds: true` — I ran `tsc` manually (clean) but the guard should be flipped on.
- No ESLint configuration or `lint` script exists in the frontend at all.
- No frontend unit/E2E test harness exists (backend: 242 tests passing).

---

## D. Verification performed

| Check | Command / method | Result |
|---|---|---|
| Backend test suite | `backend/venv/bin/pytest -q` | **242 passed** (13 new privacy/contact tests included) |
| New endpoint tests | `pytest tests/api/test_privacy.py -q` | 13 passed |
| Django system check | `manage.py check` (local settings) | No issues |
| Type check | `npx tsc --noEmit` (frontend) | exit 0, no errors |
| Production build | `npm run build` | `✓ Compiled successfully`, static export written (`out/` incl. `privacy-request`, `refund-policy`) |
| Live API | curl against `localhost:8000` | contact 201 (JSON + multipart PDF), consent-missing 400, over-length 400, bad email 400, privacy submit 201 `PR-000001`, anon list 401, owner list 200 tenant-scoped, super-admin detail 200 |
| Page smoke test | curl `localhost:3000` | `/`, `/contact/`, `/demo/`, `/careers/`, `/status/`, `/privacy-request/`, all five policy pages, `/dashboard/`, `/login/` → **200** |
| Accessibility markers | HTML grep | skip link `Skip to`, `id="main-content"`, `Cookie preferences` present |
| Dev server health | `/tmp/opencode/frontend.log` after restart | no errors since restart |
| Lint | `npm run lint` | **not available** — project has no lint script/config (reported honestly) |

Servers running for manual testing: backend `:8000`, frontend `:3000`
(credentials: `owner@eventflow.com` / `Password123`, `admin@eventflow.com` / `Admin@12345`).

---

## E. Not done / explicitly out of scope

- No claims of certifications, uptime, penetration tests, customer counts or team size exist anywhere in the rewritten copy.
- No automated accessibility or security scanner run in this pass (backend test suite + manual curl only).
- No frontend tests written (no test harness configured).
- No migration/erasure automation, no consent database, no subprocessor list (would need real vendor information from the owner).
- No git commit was made — all changes are staged on disk for your review.
