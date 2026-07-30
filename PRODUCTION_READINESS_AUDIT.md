# EventFlow — Final Production Readiness Audit

**Date:** 2026-06-28
**Auditor:** MiMoCode (Principal Software Architect / Security Auditor / DevOps)
**Target Environment:** Shared cPanel Hosting (No SSH, No Terminal, Passenger WSGI, MySQL, File Manager deployment)

---

## 1. Executive Summary

**Overall Project Score: 38/100**

| Area | Score |
|------|-------|
| Backend | 45/100 |
| Frontend | 52/100 |
| Flutter Mobile | 35/100 |
| Security | 28/100 |
| Performance | 42/100 |
| Production Readiness | 32/100 |
| Shared cPanel Readiness | 48/100 |

The project has a solid architectural foundation with consistent patterns across 21 Django apps, 20+ Next.js pages, and 12 Flutter feature modules. However, **critical security vulnerabilities, placeholder implementations in payment flows, missing Firebase configuration, and multiple data-integrity bugs** prevent production deployment. The cPanel hosting target adds additional complexity with `mysqlclient` compilation requirements and `LocMemCache` fragility.

---

## 2. Critical Issues (Deployment Blockers)

### CR-01: `EncryptedTextField` Is Not Encrypted
- **Severity:** CRITICAL
- **Impact:** All API keys, SMTP passwords, webhook secrets, and Razorpay credentials stored in the database are readable in plaintext by anyone with DB access.
- **File:** `backend/core/fields.py:6-34`
- **Reason:** Uses `django.core.signing` (base64 + HMAC signature), NOT encryption. Signing prevents tampering but does not confidentiality. The field name is misleading.
- **Fix:** Replace with `django-fernet-fields` or `cryptography.fernet.Fernet` for actual AES encryption.

### CR-02: Razorpay Payment Verification Saves `amount=0`
- **Severity:** CRITICAL
- **Impact:** Every Razorpay payment recorded via `verify_razorpay_payment` saves `amount=0`. The booking ledger will show zero for online payments, making all financial reporting wrong.
- **File:** `backend/services/payment_service.py:140-142`
- **Reason:** The payment amount is never extracted from Razorpay's response.
- **Fix:** After verification, fetch the payment details via `gateway.verify_payment_by_id()` or extract amount from the order, and pass it to `repo.create()`.

### CR-03: Dashboard View Missing Tenant Isolation Permission
- **Severity:** CRITICAL
- **Impact:** The dashboard summary view uses `ModuleAccessPermission` but NOT `TenantScopedPermission`. If `request.tenant` is None or misconfigured, the service could return data from wrong tenants.
- **File:** `backend/apps/dashboard/views.py:9`
- **Reason:** Only view among 21 ViewSets without `TenantScopedPermission`.
- **Fix:** Add `TenantScopedPermission` to `permission_classes`.

### CR-04: Invoice Queryset Missing Soft-Delete Filter
- **Severity:** CRITICAL
- **Impact:** Soft-deleted invoices appear in API responses. Users can see, edit, and act on invoices that were supposed to be deleted.
- **File:** `backend/apps/invoices/views.py:23`
- **Reason:** Queryset is `Invoice.objects.filter(tenant=tenant)` — missing `is_deleted=False`.
- **Fix:** Add `.filter(is_deleted=False)` to the queryset.

### CR-05: Notification `mark_read` Writes Invalid Status Value
- **Severity:** CRITICAL
- **Impact:** Setting `status="READ"` violates the `NotificationStatus` choices constraint (only PENDING/SENT/FAILED exist). This will either cause a database error or create an invalid state.
- **File:** `backend/apps/notifications/views.py:25`
- **Reason:** `NotificationStatus` has no `READ` choice. The field uses `choices=NotificationStatus.choices`.
- **Fix:** Either add `READ = "READ"` to `NotificationStatus` choices, or use a separate `is_read` boolean field on the model.

### CR-06: Subscription Plan Limits Never Enforced
- **Severity:** CRITICAL
- **Impact:** Any tenant can create unlimited users and venues regardless of their subscription plan. The enforcement permissions always return `True`.
- **File:** `backend/permissions/feature_limits.py` (EnforceUserLimit, EnforceVenueLimit)
- **Reason:** Both permission classes contain `return True` as their implementation.
- **Fix:** Implement actual count-based checks against subscription plan limits.

### CR-07: Razorpay Webhook Creates Payments Without Tenant Validation
- **Severity:** CRITICAL
- **Impact:** The webhook searches for bookings globally (`Booking.objects.filter(booking_number=...)`) not scoped to a tenant. A crafted webhook could potentially create payment records against bookings from any tenant.
- **File:** `backend/config/api_router.py:74-76`
- **Reason:** No tenant filter on the Booking lookup.
- **Fix:** Scope the booking lookup to a tenant, or validate the webhook's tenant context from the payment metadata.

### CR-08: Frontend Build Suppresses ALL Errors
- **Severity:** CRITICAL
- **Impact:** `eslint.ignoreDuringBuilds: true` and `typescript.ignoreBuildErrors: true` mask every linting error and type error. The build will succeed even with broken code, null pointer errors, and type mismatches.
- **File:** `frontend/next.config.mjs:8-13`
- **Reason:** Both flags are set to `true`.
- **Fix:** Set both to `false` for production builds.

### CR-09: Razorpay Payment Signature Verification Vulnerable to Timing Attack
- **Severity:** CRITICAL
- **Impact:** `verify_payment` uses `==` for HMAC comparison. An attacker can brute-force the signature byte-by-byte using timing differences.
- **File:** `backend/gateway/payments/razorpay.py:54`
- **Reason:** Uses `expected == signature` instead of `hmac.compare_digest`.
- **Fix:** Replace with `hmac.compare_digest(expected, signature)`.

### CR-10: Flutter Missing Firebase Configuration Files
- **Severity:** CRITICAL
- **Impact:** `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are missing. Firebase initialization will crash on launch, silently disabling push notifications.
- **File:** `mobile_app/android/app/google-services.json` (missing), `mobile_app/ios/Runner/GoogleService-Info.plist` (missing)
- **Reason:** Files not present in the repository.
- **Fix:** Generate from Firebase Console and add to the repository (or use environment-based config).

---

## 3. High Priority Issues

### HIGH-01: Brute Force Protection Uses LocMemCache
- **File:** `backend/core/brute_force.py:all`
- **Impact:** On shared cPanel with multiple WSGI workers, each worker has its own cache. Brute force state is lost on worker recycle. Attacker can retry immediately after restart.
- **Fix:** Use database-backed cache or `django.core.cache.backends.locmem` with file persistence, or implement rate limiting in middleware using database.

### HIGH-02: Payment Amount Never Captured in Razorpay Webhook
- **File:** `backend/config/api_router.py:67,80-83`
- **Impact:** The webhook reads `amount` from Razorpay's payload but the payment model saves it correctly here (line 83). However, `verify_razorpay_payment` (HIGH-02a) saves `amount=0`. Conflicting implementations.
- **Fix:** Consolidate payment recording logic.

### HIGH-03: `email_invoice` Is a Stub
- **File:** `backend/services/invoice_service.py:140-147`
- **Impact:** The "Email Invoice" button in the UI returns success but never sends an email.
- **Fix:** Wire up `EmailProvider.send_email()` with the invoice PDF as attachment.

### HIGH-04: `Logs/` Directory Not Created in Production
- **File:** `backend/config/settings/production.py:64`
- **Impact:** `RotatingFileHandler` will raise `FileNotFoundError` at startup if `logs/` directory doesn't exist.
- **Fix:** Add `os.makedirs(BASE_DIR / "logs", exist_ok=True)` or use `manage.py` to create it.

### HIGH-05: LocMemCache Ineffective Across Workers
- **File:** `backend/config/settings/base.py:157-162`
- **Impact:** Dashboard cache, settings cache, and brute force protection all use `LocMemCache`. On multi-worker cPanel, cache is not shared.
- **Fix:** Use file-based cache or database cache for shared hosting.

### HIGH-06: Lead Convert Bypasses Booking Validation
- **File:** `backend/services/lead_service.py:29`
- **Impact:** `convert_lead` calls `bk_service.repo.create()` directly, bypassing `BookingService.create_booking` which checks double-booking, venue availability, and records history.
- **Fix:** Call `bk_service.create_booking()` instead.

### HIGH-07: Dashboard N+1 Query on Pending Payments
- **File:** `backend/services/dashboard_service.py:57-63`
- **Impact:** For each booking, `payment_repo.get_total_paid(booking)` is called individually. With 100 bookings, this is 100+ separate queries.
- **Fix:** Use a single annotated query with `Subquery` or `annotate`.

### HIGH-08: Race Condition on Booking/Invoice Number Generation
- **File:** `backend/utils/booking_numbers.py`, `backend/utils/invoice_numbers.py`
- **Impact:** Non-atomic number generation can produce duplicates under concurrent requests. InvoiceService retries on IntegrityError, but BookingService does not.
- **Fix:** Use `select_for_update` or database-level unique constraints with retry logic.

### HIGH-09: Frontend SiteHeader Uses `<a>` Instead of `<Link>`
- **File:** `frontend/components/marketing/SiteHeader.tsx:32,43,53,58,87,97,104`
- **Impact:** Every navigation click causes a full page reload instead of client-side routing. Destroys SPA experience.
- **Fix:** Import and use `next/link` `<Link>` component.

### HIGH-10: UserNav Has Hardcoded User Data
- **File:** `frontend/components/layout/UserNav.tsx:17,44,52-54`
- **Impact:** Notification count hardcoded to 3, user name "Admin User", email "admin@eventflow.com", avatar path `/avatars/user.jpg` (file doesn't exist).
- **Fix:** Use `useAuth()` context for user data and notifications API for count.

### HIGH-11: JWT Tokens Stored in Plaintext in Database
- **File:** `backend/apps/authentication/models.py` (UserSession model)
- **Impact:** `access_token` and `refresh_token` are raw TextFields. DB compromise exposes all active sessions.
- **Fix:** Store only token hashes, or encrypt using proper `EncryptedTextField`.

### HIGH-12: Webhook Error Response Leaks Internal Details
- **File:** `backend/config/api_router.py:90-92`
- **Impact:** `str(e)` in the exception handler can expose DB connection strings, stack traces, and internal paths to API callers.
- **Fix:** Return generic error message, log the detailed error.

### HIGH-13: WhatsApp Provider Missing Tenant Filter
- **File:** `backend/gateway/messaging/whatsapp_provider.py:19`
- **Impact:** `WhatsAppSettings.objects.filter(is_active=True).first()` fetches the first active config globally, not per-tenant. Multi-tenant deployments will use wrong credentials.
- **Fix:** Filter by `tenant` parameter.

### HIGH-14: Flutter Stream Subscription Leaks
- **File:** `mobile_app/lib/core/services/notification_service.dart`, `mobile_app/lib/core/network/network_info.dart`
- **Impact:** `NotificationService.dispose()` and `NetworkInfo.dispose()` are never called. Stream subscriptions leak for app lifetime.
- **Fix:** Call dispose in the app's root widget `dispose()` method.

---

## 4. Medium Priority Issues

| # | File | Issue |
|---|------|-------|
| MED-01 | `backend/services/base.py:15-16` | `validate_business_rules()` defined but never called — dead code |
| MED-02 | `backend/core/exceptions.py:53` | `DomainException.code` parameter accepted but never used as HTTP status |
| MED-03 | `backend/repositories/base.py:38` | No validation that filter keys are actual model fields — causes unhandled 500 |
| MED-04 | `backend/config/api_router.py:31-33` | Module-level imports of `razorpay` and `PaymentGatewaySettings` — if either fails, ALL routes break |
| MED-05 | `backend/services/refund_service.py:17` | Uses raw string `"REFUNDED"` instead of `BookingStatus.REFUNDED` enum |
| MED-06 | `backend/services/payment_service.py:53` | Uses raw strings `"CANCELLED"`, `"REFUNDED"` instead of enum constants |
| MED-07 | `frontend/lib/seo.ts:8` | Hardcoded `baseUrl = "https://eventflow.com"` — should use env var |
| MED-08 | `frontend/app/(marketing)/contact/page.tsx` | Contact form `action="#"` — no backend submission, form does nothing |
| MED-09 | `mobile_app/lib/core/services/notification_service.dart` | No `WidgetsBindingObserver` for lifecycle handling |
| MED-10 | `mobile_app/lib/main.dart:30-32` | Global error handler missing — no `FlutterError.onError` or `runZonedGuarded` |
| MED-11 | `backend/apps/bookings/views.py:21` | Booking queryset filters `is_deleted=False` but invoice/quotation views do not — inconsistent |
| MED-12 | `frontend/package.json:8` | `"export": "next build && next export"` — `next export` removed in Next.js 14+ |
| MED-13 | `backend/services/report_service.py:293` | Filename in Content-Disposition not sanitized — potential header injection |
| MED-14 | `mobile_app` | 5 unused runtime dependencies (freezed_annotation, json_annotation, pull_to_refresh, cached_network_image, flutter_svg) |
| MED-15 | `frontend` | 6 unused dependencies (~1.8MB): @react-three/drei, @react-three/fiber, three, @types/three, gsap, animejs |
| MED-16 | `mobile_app/lib/features/payments/` | Razorpay checkout UI not implemented — BLoC exists but no `Razorpay().open()` call |

---

## 5. Low Priority Improvements

| # | File | Issue |
|---|------|-------|
| LOW-01 | `backend/core/health.py:1` | Unused `import os` |
| LOW-02 | `backend/core/cache.py:12` | `hashlib.md5` flagged by security scanners (non-cryptographic use) |
| LOW-03 | `backend/core/logging_middleware.py:19-26` | Extra dict fields never rendered by formatter |
| LOW-04 | `backend/services/base.py:13` | `get_repository()` raises `NotImplementedError` — dead code if all subclasses override |
| LOW-05 | `frontend/lib/colors.ts` | Duplicates tailwind.config.ts values, never imported by components |
| LOW-06 | `frontend/lib/theme.ts` | Exports unused font/button objects |
| LOW-07 | `frontend/app/(portal)/dashboard/` | Empty route group — dead directory |
| LOW-08 | `frontend/features/` | 16 empty feature directories — abandoned architecture |
| LOW-09 | `frontend/components/charts/`, `data/`, `form/`, `utils/` | Empty directories |
| LOW-10 | `frontend/public/icons/` | Empty — no favicon, no apple-touch-icon |
| LOW-11 | `mobile_app` | `web/manifest.json` uses default Flutter blue instead of app indigo |
| LOW-12 | `mobile_app` | `MainShell` bottom nav hardcodes colors, breaks dark mode |
| LOW-13 | `mobile_app` | Duplicate BLoC test files in `test/bloc/` and `test/features/` |
| LOW-14 | `mobile_app/android` | Deprecated `com.google.android.play:core:1.10.3` |
| LOW-15 | `backend/apps/core/mixins.py`, `backend/middleware/audit.py` | Dead code — stubs never imported |

---

## 6. Shared cPanel Deployment Checklist

| Item | Status | Notes |
|------|--------|-------|
| Passenger WSGI | ✅ Ready | `config/wsgi.py` exists with standard Django WSGI setup. `api.htaccess` configured for Passenger. |
| WSGI Entry Point | ✅ Ready | `PassengerStartupFile passenger_wsgi.py` referenced in htaccess. Need to create `passenger_wsgi.py` in deployment root. |
| MySQL | ⚠ Needs Work | `mysqlclient==2.2.4` requires C compilation (`gcc`, `mysql_config`). May fail on shared hosting without dev tools. Consider `PyMySQL` as fallback. |
| WhiteNoise | ✅ Ready | `whitenoise==6.7.0` configured in production settings with `CompressedManifestStaticFilesStorage`. |
| collectstatic | ✅ Ready | `STATIC_ROOT = BASE_DIR / "staticfiles"` configured. Can run via cPanel Python app or File Manager. |
| Media Files | ⚠ Needs Work | `DEFAULT_FILE_STORAGE = "FileSystemStorage"` — works but no backup strategy. Large uploads could fill disk. `DATA_UPLOAD_MAX_MEMORY_SIZE = 10MB` set. |
| Cron Jobs | ✅ Ready | 6 management commands available: `cleanup_expired_tokens`, `send_notifications`, `send_emails`, `retry_failed_notifications`, `generate_scheduled_reports`, `validate_deployment`. Can be scheduled via cPanel Cron. |
| Email (SMTP) | ✅ Ready | Real SMTP implementation with retry logic. Falls back to console backend if unconfigured. |
| WhatsApp | ⚠ Needs Work | Twilio/Gupshup/Business API implementations exist. Missing tenant filter on settings lookup. Requires Twilio SDK (`twilio==9.3.0`). |
| Firebase | ⚠ Needs Work | Backend has no Firebase dependency (good). Mobile app requires `google-services.json` — must be added manually. |
| Razorpay | ⚠ Needs Work | SDK integrated (`razorpay>=1.4.0`). Webhook handler exists but has tenant isolation issue (CR-07). Payment verification saves amount=0 (CR-02). |
| Static Files | ✅ Ready | WhiteNoise serves with compression. No external CDN dependency. |
| Environment Variables | ⚠ Needs Work | 17 variables needed. `.env` file not committed (good). Must be set via cPanel or `.env` file. |
| SSL Compatibility | ✅ Ready | `SECURE_PROXY_SSL_HEADER`, `SESSION_COOKIE_SECURE`, `CSRF_COOKIE_SECURE`, HSTS all configured in production settings. |
| Backups | ❌ Not Ready | No automated backup mechanism. No management command for DB dump. Must rely on cPanel's backup tool. |
| Logs Directory | ❌ Not Ready | `production.py:64` references `BASE_DIR / "logs" / "django.log"` but directory doesn't exist and isn't auto-created. App will crash on startup. |
| Redis | ✅ Not Required | LocMemCache used. No Redis dependency. |
| Celery | ✅ Not Required | Management commands + cron replace Celery. |
| Docker | ✅ Not Required | No Docker dependencies. |
| Supervisor | ✅ Not Required | Not referenced. |

### cPanel Deployment Steps (Verified)

1. Upload backend files via File Manager to `public_html/api/` or subdomain root
2. Create `passenger_wsgi.py` pointing to `config.wsgi.application`
3. Create MySQL database via MySQL Wizard
4. Set environment variables via `.env` file or cPanel Python app config
5. Run `python manage.py migrate` via cPanel Python terminal (if available) or create a one-time management command
6. Run `python manage.py collectstatic` (WhiteNoise handles serving)
7. Set up cron jobs for: token cleanup, notification sending, email processing
8. Upload frontend `out/` directory to `public_html/` or main domain
9. Configure `.htaccess` for SPA routing on frontend

---

## 7. Flutter Release Checklist

| Item | Status | Notes |
|------|--------|-------|
| APK Build | ⚠ Needs Work | `build.gradle.kts` configured with release signing, minification, ProGuard. But signing defaults to hardcoded "eventflow" password — insecure for production. |
| AAB Build | ⚠ Needs Work | Same signing config issues. `compileSdk = 36`, `targetSdk = 36` — latest. `minSdk = flutter.minSdkVersion` (21). |
| Firebase | ❌ Not Ready | No `google-services.json` or `GoogleService-Info.plist`. App will crash on Firebase init. |
| Notifications | ❌ Not Ready | Firebase messaging code exists but non-functional without Firebase config. `NotificationService.dispose()` never called — stream leaks. |
| Guest Mode | ✅ Ready | Fully functional with demo data provider, login-required sheets, upgrade prompts. |
| Offline Mode | ⚠ Needs Work | Dashboard and Bookings have offline cache. Payments, Invoices, Venues, Leads, Customers do not. No TTL/expiry. Cache keys not user-scoped. |
| Razorpay | ❌ Not Ready | BLoC/repository plumbing exists but no checkout UI. `Razorpay().open()` never called. Payment collection non-functional. |
| Permissions | ⚠ Needs Work | `permission_handler` declared but never imported. Camera/gallery permissions rely on `image_picker` implicit handling. |
| Signing | ⚠ Needs Work | Release signing uses env vars with hardcoded fallbacks. Keystore file excluded via `.gitignore`. |
| Play Store Readiness | ❌ Not Ready | Missing: Firebase config, working payment flow, proper signing, notification permissions in manifest, deprecated `play:core` library. |
| Dependencies | ⚠ Needs Work | 5 unused runtime deps (freezed_annotation, json_annotation, pull_to_refresh, cached_network_image, flutter_svg). Deprecated `com.google.android.play:core`. |
| Theme | ⚠ Needs Work | Excellent light/dark themes but `MainShell` bottom nav hardcodes colors breaking dark mode. `web/manifest.json` uses wrong theme color. |
| Error Handling | ⚠ Needs Work | No global error handler. 5 locations swallow errors with `catch (_) {}`. No crash reporting (Sentry/Crashlytics). |
| Tests | ⚠ Needs Work | BLoC tests are solid (10 test files). No widget, repository, or integration tests. `test/repository/` empty. |

---

## 8. Feature Completeness

| Feature | Backend | Frontend | Mobile | Notes |
|---------|---------|----------|--------|-------|
| Authentication | ✅ | ✅ | ✅ | JWT with refresh, blacklisting, password reset |
| Guest Mode | N/A | N/A | ✅ | Demo data provider with 20 bookings, 40 customers |
| Dashboard | ✅ | ✅ | ✅ | Summary API, responsive dashboard, charts |
| Bookings | ✅ | ✅ | ✅ | Full CRUD + status transitions + calendar |
| Customers | ✅ | ✅ | ✅ | Full CRUD + search + tenant isolation |
| Leads | ✅ | ✅ | ✅ | Full CRUD + convert + followup + quotations |
| Venues | ✅ | ✅ | ✅ | Full CRUD + filtering |
| Invoices | ✅ | ✅ | ✅ | Generate + PDF + email (email is stub) |
| Payments | ✅ | ✅ | ⚠ | Manual payments work. Razorpay verification broken. Mobile checkout UI missing. |
| Notifications | ✅ | ✅ | ⚠ | In-app + email + WhatsApp. mark_read has invalid status. Mobile push non-functional. |
| Settings | ✅ | ✅ | ⚠ | 17-action god-view. Frontend has 13 tabs. Mobile settings pages are placeholders. |
| Profile | ✅ | ✅ | ✅ | Profile view + image upload |
| Reports | ✅ | ✅ | ❌ | Revenue, bookings, payments, occupancy, leads, vendors, inventory. Mobile reports feature empty. |
| Contracts | ✅ | ✅ | N/A | Full CRUD + sign action |
| Quotations | ✅ | ✅ | N/A | Full CRUD + accept/reject/send |
| Inventory | ✅ | ✅ | N/A | Full CRUD + allocate/release |
| Staff | ✅ | ✅ | N/A | Full CRUD |
| Tasks | ✅ | ✅ | N/A | Full CRUD + status change |
| Expenses | ✅ | ✅ | N/A | Full CRUD |
| Vendors | ✅ | ✅ | N/A | Full CRUD |
| Packages | ✅ | ✅ | N/A | Full CRUD |
| Subscriptions | ✅ | ✅ | N/A | Plan management (limits not enforced) |
| Audit Logs | ✅ | ✅ | N/A | Read-only view |
| Uploads | ✅ | N/A | ✅ | Profile image upload via FormData |
| Search | ✅ | ✅ | ✅ | DRF SearchFilter + mobile search sheets |
| Filtering | ✅ | ✅ | ✅ | DRF DjangoFilterBackend + frontend filter UIs |
| Pagination | ✅ | ✅ | ✅ | DRF StandardPagination (20/page) |
| Offline Mode | N/A | N/A | ⚠ | Dashboard + Bookings only. No TTL. Not user-scoped. |

---

## 9. Code Quality Assessment

### Architecture
- **Backend:** Clean service-repository pattern with 21 apps. Consistent base classes. Centralized routing in `api_router.py`. Some inconsistency (contracts/settings have local services.py, others don't).
- **Frontend:** Clean services → hooks → pages architecture. Tanstack Query for server state. shadcn/ui components. Static export configured.
- **Mobile:** Clean Architecture with BLoC + Repository pattern. GetIt DI. GoRouter routing. Consistent across 12 features.

### SOLID Violations
- `SettingsViewSet` is a 17-action god-view handling settings, users, roles, subscriptions, and profile
- `DashboardService._compute_summary` mixes aggregation with iteration
- `InvoiceService.generate_pdf` has 130+ lines of ReportLab layout code in a service method

### DRY Violations
- Booking/Invoice/Contract number generation logic duplicated across 3 utility files
- PDF generation code duplicated between `InvoiceService.generate_pdf` and `PaymentService.generate_receipt_pdf`
- WhatsApp provider has 3 near-identical API integration methods

### Dead Code
- `core/mixins.py` — stub never imported
- `middleware/audit.py` — stub never registered
- `CreditBalance`/`CreditTransaction` models — never used in views/serializers
- `Report serializers` — defined but never instantiated
- `services/base.py:validate_business_rules()` — never called
- Frontend `features/` directory tree — 16 empty directories
- Frontend `lib/colors.ts`, `lib/theme.ts` — exported but never consumed
- Mobile `freezed_annotation`, `json_annotation`, `pull_to_refresh`, `cached_network_image`, `flutter_svg` — unused

---

## 10. Security Audit Summary

| Category | Status | Details |
|----------|--------|---------|
| SQL Injection | ✅ Safe | All queries use Django ORM parameterized queries. No raw SQL. |
| XSS | ⚠ Low Risk | Backend returns JSON only (no HTML rendering). Frontend uses React (auto-escapes). Marketing pages use `dangerouslySetInnerHTML` nowhere. |
| CSRF | ⚠ Partial | CSRF middleware enabled. Razorpay webhook is `csrf_exempt` (expected for webhooks). Frontend uses Bearer tokens (not cookies for API). |
| Broken Authentication | ⚠ Issues | JWT with blacklist. Brute force protection exists but ineffective with LocMemCache. Password reset codes expire after 24h. |
| IDOR | ⚠ Low Risk | TenantScopedPermission on all ViewSets except Dashboard. DRF `get_object()` uses queryset filtering. |
| Tenant Isolation | ⚠ Issues | Dashboard view missing TenantScopedPermission (CR-03). WhatsApp provider missing tenant filter (HIGH-13). Razorpay webhook global booking lookup (CR-07). |
| Privilege Escalation | ⚠ Needs Review | `ModuleAccessPermission` exists but subscription limits not enforced (CR-06). |
| Mass Assignment | ✅ Safe | Serializers explicitly define fields. `perform_create` passes tenant manually. |
| Secret Exposure | ❌ Critical | `EncryptedTextField` is not encrypted (CR-01). JWT tokens in plaintext DB (HIGH-11). Default SECRET_KEY is insecure. |
| File Upload | ⚠ Basic | 10MB limit configured. No file type validation visible in upload endpoints. |
| JWT Issues | ⚠ Issues | Access token 60min, refresh 24hr. Rotate + blacklist enabled. But tokens in plaintext DB. |
| Password Reset | ✅ Basic | Code-based reset with 24h expiry. Password strength validation exists but doesn't enforce special chars. |
| Session Security | ✅ Good | `SESSION_COOKIE_SECURE = True`, `SESSION_COOKIE_HTTPONLY = True`, `SESSION_COOKIE_SAMESITE = "Lax"` in production. |
| Cookie Security | ✅ Good | `CSRF_COOKIE_SECURE = True` in production. |
| CORS | ⚠ Configurable | Whitelist via env var. Credentials allowed. Must be configured per-domain. |
| Security Headers | ✅ Good | HSTS, X-Content-Type-Options, X-Frame-Options, X-XSS-Protection configured. CSP missing. |

---

## 11. Performance Assessment

| Issue | Severity | Location |
|-------|----------|----------|
| Dashboard N+1 on pending payments | HIGH | `dashboard_service.py:57-63` |
| Report service Python-level aggregation | MEDIUM | `report_service.py` multiple methods |
| Settings cache clear flushes entire LocMemCache | MEDIUM | `cache.py` |
| Unnecessary select_related on unused fields | LOW | Multiple ViewSets |
| LocMemCache per-worker isolation | HIGH | `base.py:157-162` |
| No database connection pooling | MEDIUM | Shared hosting limitation |
| No CDN for static/frontend assets | LOW | WhiteNoise serves directly |
| Frontend unused dependencies (~1.8MB) | LOW | `package.json` |
| Mobile unused dependencies | LOW | `pubspec.yaml` |

---

## 12. Testing Assessment

### Backend Tests
- **34 test files** across unit, integration, and API tests
- **API tests:** 93 test methods across 16 files. Real assertions, proper auth setup. Some gaps (missing tenant isolation tests in inventory/payments, missing delete/validation tests).
- **Integration tests:** 6 test files covering auth, booking, customer, invoice, lead, payment flows.
- **Unit tests:** 12 test files covering brute force, cache, encrypted fields, health, middleware, management commands, subscriptions, tenants, users, password reset.
- **Quality:** Tests are real and functional. Factories exist but underused (only 7 factories, API tests build objects manually).

### Flutter Tests
- **21 test files** across BLoC, features, and core utilities
- BLoC tests use `bloc_test` + `mocktail` properly
- Validator and formatter tests are thorough
- **Missing:** Widget tests, repository tests, integration tests, data source tests
- `test/repository/` directory exists but is empty
- Duplicate test files in `test/bloc/` and `test/features/`

### Frontend Tests
- **No test files found** in the frontend project

---

## 13. Final Verdict

### **D) Internal Testing Only**

**Rationale:** The project has a well-structured architecture and substantial feature implementation across all three platforms. However, it cannot be deployed to production in its current state due to:

1. **10 Critical Issues** including broken payment processing, missing encryption, tenant isolation gaps, and missing Firebase configuration
2. **14 High Priority Issues** including cache fragility, race conditions, stub implementations, and data integrity problems
3. **Missing production infrastructure** (logs directory, backup strategy, proper error monitoring)
4. **Incomplete mobile payment flow** (Razorpay checkout UI not implemented)
5. **Security vulnerabilities** (timing attack on payment verification, plaintext JWT storage, ineffective brute force protection)

**To reach Production Ready (B), the following must be fixed:**
- All 10 Critical issues
- At minimum HIGH-01, HIGH-03, HIGH-04, HIGH-05, HIGH-06, HIGH-07, HIGH-08, HIGH-11, HIGH-12, HIGH-13
- Flutter Firebase configuration
- Flutter Razorpay checkout UI
- Frontend UserNav dynamic data

**Estimated effort to reach Production Ready:** 3-5 days of focused development.
