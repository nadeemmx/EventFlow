# EventFlow — Compliance Audit Summary (Pre-Implementation)

Date: 2026-09-25 · Scope: frontend (`frontend/`), backend (`backend/`), database, email workflows, third-party SDKs.
Method: full repository inspection (routes, views, serializers, models, settings, built `out/` output, `db.sqlite3` contents). No changes were made before this document.

---

## 1. What already exists

### Product & architecture
- Next.js 14 App Router frontend (static export), Tailwind + shadcn/ui design system, 20 marketing pages, auth pages, dashboard.
- Django 4.2 + DRF backend, 363 routes, JWT (simplejwt) auth, tenant-scoped data model, audit logging app, module/role permission engine (`permissions/module_access.py`).
- Auth flows: register (creates tenant + owner), login, refresh, logout, forgot/reset/change password.
- Payment: Razorpay (`create_order`/`verify` + HMAC webhook). Email: SMTP-or-console (`config/settings/base.py:113-121`). WhatsApp/SMS gateways via HTTP.

### Privacy/security controls present
- AES-256-GCM `EncryptedTextField` for gateway/SMTP/WhatsApp secrets (`core/fields.py:55`); secrets `write_only` in serializers.
- File upload validation (magic-byte sniff + size) `core/validators.py:29-84`; strong password validator.
- Throttles on auth endpoints; brute-force lockout (`core/brute_force.py`); production settings hard-fail on missing `SECRET_KEY`/`ENCRYPTION_KEY`/`REDIS_URL` (`config/settings/production.py`).
- CORS allowlist, secure/HSTS headers in production, tenant middleware + subscription gate, tenant-scoped querysets in most viewsets.
- Password reset codes hashed at rest; generic responses to prevent account enumeration on login/forgot-password.
- Tests: ~2,750 lines (`tests/unit`, `tests/api`, `tests/integration`) incl. 5 tenant-isolation tests.
- `.htaccess` security headers (CSP, HSTS, X-Frame-Options, Referrer-Policy, Permissions-Policy).

### Legal & consent present (as shipped)
- Pages exist: `/privacy-policy`, `/terms-of-service`, `/cookie-policy`, `/gdpr`.
- Footer links to Privacy Policy, Terms, Cookie Policy, GDPR.
- Auth forms use `react-hook-form` + zod with proper labels; contact form labels are correctly associated.

### Accessibility present
- `lang="en"`, real landmarks (`header`/`nav`/`main`/`footer`), focus-visible rings on UI primitives, `sr-only` labels in dialogs/sheets, `prefers-reduced-motion` CSS block, Radix toast mounted, `aria-checked`/`aria-expanded` in a few components.

---

## 2. What is missing

| # | Gap | Evidence |
|---|---|---|
| M1 | No refund policy page (Terms links "our refund policy" which doesn't exist) | no `refund*` route |
| M2 | No cookie consent mechanism (banner/preferences) anywhere | zero `document.cookie`/consent code |
| M3 | No consent checkbox or privacy link in any of the ~25 forms | `components/ui/checkbox.tsx` never used in a form |
| M4 | No privacy-request / data-deletion workflow (no endpoint, no page) | grep `consent\|gdpr\|deletion` → 0 backend hits |
| M5 | No email unsubscribe infrastructure (no marketing email exists either) | grep `unsubscribe` → 0 |
| M6 | No data-retention enforcement: the only retention job (`cleanup_old_logs`) is unregistered and cron would fail | `management/commands/` not an installed app |
| M7 | No skip link, no `<main>` on auth/not-found/error pages, sortable table headers not keyboard accessible | see §7 report |
| M8 | No business-details configuration: legal identity is missing, and current pages **invent** it | `privacy-policy`, `gdpr`, `terms` contain a fabricated address/entity |
| M9 | No email verification on registration | `services/auth_service.py` |
| M10 | Frontend never calls the logout API → refresh tokens stay valid server-side | `services/auth.service.ts` |

---

## 3. What needs modification

### Critical / High (code)
1. **Anonymous tenant creation** `POST /api/v1/tenants/` is `AllowAny` and accepts `subscription_plan`/status fields (`apps/tenants/views.py:16-19`).
2. **Mass assignment on tenant update** — raw `request.data` passed to service, allowing `subscription_status`/`status` writes (`apps/tenants/views.py:56-61`).
3. **Refresh tokens are never rotated/blacklisted** and inactive users can still refresh (`services/auth_service.py:111-123`).
4. **Cross-tenant FK writes** — booking/lead/quotation serializers use unscoped `PrimaryKeyRelatedField` defaults (`apps/bookings/serializers.py:5-22`, `apps/leads/serializers.py:10-92`).
5. **JWT access+refresh tokens stored in plaintext** in `user_sessions` and in frontend `localStorage` (`apps/users/models.py:58-72`, `lib/api-client.ts:11,23`).
6. **Notifications are tenant-scoped but not user-scoped** (`apps/notifications/views.py:16-20`).
7. **PII in logs** — `str(request.user)` (name+email) in request logs; recipient emails/mobiles in gateway logs (`core/logging_middleware.py:25`, `gateway/messaging/*`).
8. **`local.py` regenerates `ENCRYPTION_KEY` every boot** → previously encrypted values become unreadable (`config/settings/local.py:35`).
9. **Django admin login broken** — auth backend only accepts `email=` kwarg (`apps/authentication/backends.py:7`).
10. **`localStorage.clear()` on refresh failure** wipes unrelated app keys; refresh interceptor has no single-flight guard (`lib/api-client.ts:23-36`).
11. **WhatsApp settings resolved without tenant filter** (`gateway/messaging/whatsapp_provider.py:19`).

### Content (legal/marketing accuracy)
12. Legal pages **invent** an entity/address/jurisdiction: "EventFlow Inc., 100 Innovation Drive, Suite 300, San Francisco, CA 94105", "California law", `dpo@eventflow.com` — none verified anywhere in the repo.
13. Cookie Policy claims Google Analytics, Google Ads and LinkedIn cookies **that the app does not use**, plus consent-by-browsing language that is not a valid consent mechanism.
14. Privacy Policy claims "SOC 2 compliance", "penetration testing", "TLS 1.3/AES-256 at rest" — contradicted by `pricing/PricingClient.tsx:111` ("SOC 2 in progress") and unverifiable from code.
15. Fabricated proof elements: named testimonials with revenue figures, fake client logos, "500+ venues / 50,000+ events / ₹100Cr+", fake team roster, fake blog authors, fake job openings, fake status incidents, fake help-centre article counts.
16. Forms claim to submit but silently discard data (contact, demo, careers, status subscribe).
17. Broken/CTA links: 4 × `/signup` (no such route), footer "Customers" → auth-gated dashboard, `/staff/new`, `/inventory/new`, `/tasks/new` missing.

### Accessibility (WCAG 2.2 AA)
18. No skip link; duplicate `<h1>` on every dashboard page; click-only sortable `<th>`; mobile nav toggle without `aria-expanded`/focus trap; placeholder-only inputs; unlabelled `<nav>` landmarks; heading skips; icons not `aria-hidden`; `autocomplete` only on auth forms; no `aria-live` for async status.

### Data minimization / forms
19. Marketing forms collect phone/resume/company without marking required vs optional, without consent, without server-side validation (they don't reach the server at all).
20. Settings tabs are not `<form>` elements (no native validation/Enter submit) — noted, lower priority.

---

## 4. What requires business-owner input

| Item | Why |
|---|---|
| Legal entity name & registration details | Must not be invented; currently fabricated |
| Registered/published address | Needed in Privacy Policy, Terms, contact page |
| Support email, privacy/DPO email, refunds email | Current values are invented placeholders |
| Governing law / jurisdiction / dispute venue | Currently defaults to California — unverified |
| Refund rules (trial, monthly, annual, partial, pro-rata) | Business decision; policy must not invent a guarantee |
| Cancellation & renewal terms (auto-renew on/off, notice period) | Business decision |
| Data retention periods per record class | Business + legal decision |
| GST/tax ID & invoicing entity (if India) | Verified tax details only |
| Effective dates of policies | Owner sign-off |
| Which analytics/marketing tools (if any) will be used | Determines cookie policy + consent scope |
| Whether self-service deletion or request-only deletion is offered | Product + legal decision |

## 5. What requires legal review
- Lawful basis per processing activity (contract / legitimate interest / consent) and jurisdiction-specific wording (GDPR, India DPDP Act, CCPA as applicable).
- Enforceability of liability/dispute clauses and any refund commitments.
- Controller vs processor allocation for venue-owner-entered customer data (B2B2C).
- Cross-border transfer disclosures (cloud/email/payment providers).
- Marketing consent/opt-in rules if promotional email or push is ever added.
- Children's/age provisions for the chosen jurisdictions.

## 6. What can be implemented immediately (no legal input needed)
1. Business-details configuration with **clearly marked placeholders** (no invented data).
2. Accurate rewrite of Privacy Policy, Terms, Refund Policy, Cookie Policy, GDPR page to match the real implementation.
3. Cookie consent banner (accept / reject non-essential / manage preferences, versioned + timestamped, accessible), plus a "Cookie preferences" reopen control.
4. Consent + required/optional labelling on all public forms; server-side validation via a real contact endpoint (currently forms discard data).
5. Dark-pattern pass: remove fabricated testimonials/logos/metrics/team/blog/jobs/incidents; fix broken CTAs.
6. Accessibility fixes listed in §3.18.
7. Backend security fixes in §3.1-3.11 (server-side enforcement, preserving API contracts where safe).
8. Privacy request workflow (submit → review → status) with authorization and audit trail; documented retention exceptions.
9. Log PII masking; register retention/cleanup commands; fix `local.py` encryption key stability; fix admin login.
10. Tests for consent storage, privacy requests, tenant isolation/mass-assignment, refresh rotation, contact endpoint.

---

**Report of executed changes, verification results and remaining risks: see §Final Report (delivered after implementation).**
