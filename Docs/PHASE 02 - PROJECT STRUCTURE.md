# PHASE 2 — PROJECT STRUCTURE

Project: **EventFlow** (modular monolith)
Stack: Django + DRF + MySQL · Next.js (static export) · Flutter (BLoC)
Hosting: cPanel shared hosting (no Docker / Redis / Celery / WebSockets)

This document specifies **every folder and file** for Backend, Frontend, and
Mobile. No business code is generated in this phase — only the skeleton.

---

## LOCKED DECISIONS

| Area | Decision |
|------|----------|
| Product name | EventFlow · Python package `EventFlow` · Django project `config` |
| Frontend export | Next.js `output: 'export'` (static) → served from `public_html/` |
| Backend deploy | `public_html/api/` via cPanel Passenger WSGI |
| Media deploy | `public_html/media/` |
| UI theme | ShadCN "Slate", Inter font, INR (₹), Asia/Kolkata |
| Mobile theme | Material 3, fl_chart |
| GST | Tenant-configurable rate + CGST/SGST (50/50) ↔ IGST toggle |
| Payment gateway | `PaymentGatewayProvider` interface; manual adapter Phase 1 |
| Layering | API → Serializer → Service → Repository → DB (enforced) |

## SCOPE ADJUSTMENTS

**Added to MVP schema:** `quotations` + `quotation_items`, `tenant_settings`,
refund modeled as `payment_type` on `payments`, `credit_balances` +
`credit_transactions`.
**Deferred to Phase 3 (Enterprise):** `branches`, white-label, custom domains.

---

# A. BACKEND STRUCTURE

```
backend/
│
├── manage.py
├── requirements.txt                         # pins (reads requirements/production.txt)
├── requirements/
│   ├── base.txt                             # Django, DRF, PyJWT, mysqlclient, ReportLab, openpyxl
│   ├── development.txt                      # + django-debug-toolbar, ipython, pytest
│   └── production.txt                       # + gunicorn-compatible cPanel Passenger bits
├── .env.example                             # env var template
├── .gitignore
├── README.md
│
├── config/                                  # Django project package
│   ├── __init__.py
│   ├── settings/
│   │   ├── __init__.py
│   │   ├── base.py                          # shared settings, MySQL engine, DRF, JWT, CORS
│   │   ├── development.py
│   │   ├── production.py
│   │   └── test.py
│   ├── urls.py                              # root URL conf → mounts /api/v1/ router
│   ├── api_router.py                        # DRF DefaultRouter: aggregates every app router
│   ├── wsgi.py                              # WSGI entrypoint
│   ├── asgi.py
│   └── passenger_wsgi.py                    # cPanel Passenger WSGI alias target
│
├── core/                                    # SHARED KERNEL (no business logic)
│   ├── __init__.py
│   ├── base_models.py                       # BaseModel, TenantBaseModel
│   ├── mixins.py                            # TimeStampedMixin, SoftDeleteMixin, AuditMixin
│   ├── choices.py                           # TextChoices: roles, statuses, types
│   ├── constants.py                         # app labels, limits, codes
│   ├── validators.py                        # phone, GST, email, password strength
│   ├── exceptions.py                        # domain exception hierarchy
│   ├── responses.py                         # ok() / error() / paginated() envelope builders
│   ├── pagination.py                        # StandardPagination (20 default / 100 max)
│   └── utils.py                             # id/date/tenant helpers
│
├── apps/                                    # 19 DOMAIN APPS
│   ├── __init__.py
│   │
│   ├── authentication/
│   │   ├── __init__.py  apps.py  admin.py
│   │   ├── serializers.py                   # LoginRequest, RefreshRequest, Password serializers
│   │   ├── views.py                         # LoginView, RefreshView, LogoutView, Forgot/Reset/Change
│   │   ├── backends.py                      # EmailOrMobileBackend
│   │   ├── urls.py
│   │   └── migrations/__init__.py
│   │
│   ├── tenants/
│   │   ├── __init__.py  apps.py  admin.py
│   │   ├── models.py                        # Tenant, TenantSettings
│   │   ├── serializers.py
│   │   ├── views.py                         # TenantDetailView (own tenant)
│   │   ├── urls.py
│   │   └── migrations/__init__.py
│   │
│   ├── users/
│   │   ├── __init__.py  apps.py  admin.py
│   │   ├── models.py                        # User, UserSession
│   │   ├── serializers.py
│   │   ├── views.py                         # UserViewSet, ProfileView, activate/deactivate
│   │   ├── urls.py
│   │   └── migrations/__init__.py
│   │
│   ├── customers/
│   │   ├── __init__.py  apps.py  admin.py
│   │   ├── models.py                        # Customer
│   │   ├── serializers.py
│   │   ├── views.py                         # CustomerViewSet (+ merge action)
│   │   ├── urls.py
│   │   └── migrations/__init__.py
│   │
│   ├── leads/
│   │   ├── __init__.py  apps.py  admin.py
│   │   ├── models.py                        # Lead, FollowUp, Quotation, QuotationItem
│   │   ├── serializers.py
│   │   ├── views.py                         # LeadViewSet (+ convert, followups)
│   │   ├── urls.py
│   │   └── migrations/__init__.py
│   │
│   ├── venues/
│   │   ├── __init__.py  apps.py  admin.py
│   │   ├── models.py                        # Venue, VenueImage
│   │   ├── serializers.py
│   │   ├── views.py                         # VenueViewSet (+ images upload/delete/reorder)
│   │   ├── urls.py
│   │   └── migrations/__init__.py
│   │
│   ├── packages/
│   │   ├── __init__.py  apps.py  admin.py
│   │   ├── models.py                        # Package, PackageItem
│   │   ├── serializers.py
│   │   ├── views.py                         # PackageViewSet
│   │   ├── urls.py
│   │   └── migrations/__init__.py
│   │
│   ├── bookings/
│   │   ├── __init__.py  apps.py  admin.py
│   │   ├── models.py                        # Booking, BookingHistory
│   │   ├── serializers.py
│   │   ├── views.py                         # BookingViewSet (+ confirm/cancel/timeline/calendar)
│   │   ├── urls.py
│   │   └── migrations/__init__.py
│   │
│   ├── payments/
│   │   ├── __init__.py  apps.py  admin.py
│   │   ├── models.py                        # Payment (PAYMENT / REFUND via payment_type)
│   │   ├── serializers.py
│   │   ├── views.py                         # PaymentViewSet (+ refund, receipt)
│   │   ├── urls.py
│   │   └── migrations/__init__.py
│   │
│   ├── invoices/
│   │   ├── __init__.py  apps.py  admin.py
│   │   ├── models.py                        # Invoice (immutable after generation)
│   │   ├── serializers.py
│   │   ├── views.py                         # InvoiceViewSet (+ generate, pdf)
│   │   ├── urls.py
│   │   └── migrations/__init__.py
│   │
│   ├── vendors/
│   │   ├── __init__.py  apps.py  admin.py
│   │   ├── models.py                        # Vendor, BookingVendor
│   │   ├── serializers.py
│   │   ├── views.py                         # VendorViewSet (+ assign)
│   │   ├── urls.py
│   │   └── migrations/__init__.py
│   │
│   ├── inventory/
│   │   ├── __init__.py  apps.py  admin.py
│   │   ├── models.py                        # InventoryItem, InventoryAllocation
│   │   ├── serializers.py
│   │   ├── views.py                         # InventoryViewSet (+ allocate/release)
│   │   ├── urls.py
│   │   └── migrations/__init__.py
│   │
│   ├── staff/
│   │   ├── __init__.py  apps.py  admin.py
│   │   ├── models.py                        # Staff
│   │   ├── serializers.py
│   │   ├── views.py                         # StaffViewSet
│   │   ├── urls.py
│   │   └── migrations/__init__.py
│   │
│   ├── tasks/
│   │   ├── __init__.py  apps.py  admin.py
│   │   ├── models.py                        # Task
│   │   ├── serializers.py
│   │   ├── views.py                         # TaskViewSet (+ status action)
│   │   ├── urls.py
│   │   └── migrations/__init__.py
│   │
│   ├── expenses/
│   │   ├── __init__.py  apps.py  admin.py
│   │   ├── models.py                        # Expense
│   │   ├── serializers.py
│   │   ├── views.py                         # ExpenseViewSet
│   │   ├── urls.py
│   │   └── migrations/__init__.py
│   │
│   ├── subscriptions/
│   │   ├── __init__.py  apps.py  admin.py
│   │   ├── models.py                        # SubscriptionPlan, Subscription, CreditBalance, CreditTransaction
│   │   ├── serializers.py
│   │   ├── views.py                         # SubscriptionViewSet (+ history, renew)
│   │   ├── urls.py
│   │   └── migrations/__init__.py
│   │
│   ├── notifications/
│   │   ├── __init__.py  apps.py  admin.py
│   │   ├── models.py                        # Notification
│   │   ├── serializers.py
│   │   ├── views.py                         # NotificationViewSet (+ mark_read)
│   │   ├── urls.py
│   │   └── migrations/__init__.py
│   │
│   ├── audit_logs/
│   │   ├── __init__.py  apps.py  admin.py
│   │   ├── models.py                        # AuditLog
│   │   ├── serializers.py
│   │   ├── views.py                         # AuditLogViewSet (read-only)
│   │   ├── urls.py
│   │   └── migrations/__init__.py
│   │
│   └── reports/
│       ├── __init__.py  apps.py  admin.py
│       ├── models.py                        # (no persistent tables; read-only aggregates)
│       ├── aggregators.py                   # ORM aggregation queries per report type
│       ├── serializers.py                   # report response serializers
│       ├── views.py                         # ReportViewSet (20 report endpoints)
│       ├── urls.py
│       └── migrations/__init__.py
│
├── services/                                # SERVICE LAYER — all business logic lives here
│   ├── __init__.py
│   ├── base.py                              # base Service: transaction context, audit hook
│   ├── exceptions.py                        # domain service errors
│   ├── auth_service.py
│   ├── tenant_service.py
│   ├── user_service.py
│   ├── customer_service.py
│   ├── lead_service.py
│   ├── venue_service.py
│   ├── package_service.py
│   ├── booking_service.py
│   ├── payment_service.py
│   ├── refund_service.py
│   ├── invoice_service.py
│   ├── vendor_service.py
│   ├── inventory_service.py
│   ├── staff_service.py
│   ├── task_service.py
│   ├── expense_service.py
│   ├── subscription_service.py
│   ├── notification_service.py
│   ├── audit_service.py
│   ├── report_service.py
│   └── dashboard_service.py
│
├── repositories/                            # REPOSITORY LAYER — data access only
│   ├── __init__.py
│   ├── base.py                              # BaseRepository: tenant-aware queryset + pagination
│   ├── tenant_repository.py
│   ├── user_repository.py
│   ├── customer_repository.py
│   ├── lead_repository.py
│   ├── venue_repository.py
│   ├── package_repository.py
│   ├── booking_repository.py
│   ├── payment_repository.py
│   ├── invoice_repository.py
│   ├── vendor_repository.py
│   ├── inventory_repository.py
│   ├── staff_repository.py
│   ├── task_repository.py
│   ├── expense_repository.py
│   ├── subscription_repository.py
│   ├── notification_repository.py
│   └── audit_repository.py
│
├── permissions/                             # RBAC permission classes
│   ├── __init__.py
│   ├── base.py                              # TenantScopedPermission, ModulePermission
│   ├── roles.py                             # IsSuperAdmin, IsOwner, IsManager, IsAccountant, IsStaff, IsCustomer
│   ├── module_access.py                     # module × role matrix enforcement
│   └── feature_limits.py                    # plan-quota enforcement (users/venues/bookings)
│
├── middleware/                              # cross-cutting middleware
│   ├── __init__.py
│   ├── request_context.py                   # thread-local request context (tenant/user)
│   ├── tenant.py                            # TenantMiddleware: resolve + attach tenant
│   ├── audit.py                             # AuditMiddleware: write audit on mutating calls
│   └── subscription.py                      # SubscriptionGateMiddleware: block expired tenants
│
├── gateway/                                 # external provider integrations
│   ├── __init__.py
│   ├── payments/
│   │   ├── __init__.py
│   │   ├── base.py                          # PaymentGatewayProvider interface
│   │   ├── manual.py                        # Phase 1 default adapter
│   │   ├── razorpay.py                      # Phase 2 (stub until chosen)
│   │   └── exceptions.py
│   └── messaging/
│       ├── __init__.py
│       ├── base.py                          # MessagingProvider interface
│       ├── email_provider.py                # SMTP backend
│       └── whatsapp_provider.py             # provider-based (stub)
│
├── reports/                                 # EXPORT ENGINE (PDF/Excel/CSV) — distinct from apps/reports
│   ├── __init__.py
│   ├── pdf.py                               # ReportLab wrappers
│   ├── excel.py                             # openpyxl wrappers
│   ├── csv_export.py
│   └── templates/
│       ├── invoice_template.py
│       ├── receipt_template.py
│       └── report_template.py
│
├── management/                              # Django management commands → cPanel cron
│   ├── __init__.py
│   └── commands/
│       ├── __init__.py
│       ├── expire_tentative_bookings.py
│       ├── send_subscription_reminders.py
│       ├── send_event_reminders.py
│       ├── update_overdue_payments.py
│       ├── cleanup_old_logs.py
│       ├── generate_scheduled_reports.py
│       └── seed_demo_data.py
│
├── utils/                                   # generic helpers (no business rules)
│   ├── __init__.py
│   ├── money.py                             # Decimal arithmetic + INR formatting
│   ├── booking_numbers.py                   # VF-YYYY-000001 generator
│   ├── invoice_numbers.py                   # invoice number generator
│   ├── gst.py                               # CGST/SGST(50/50) ↔ IGST calculator
│   ├── dates.py                             # Asia/Kolkata timezone helpers
│   └── storage.py                           # upload path + tenant quota calc
│
├── static/
│   ├── css/  js/  admin/
│
├── media/                                   # uploads (production: public_html/media)
│   ├── venues/  customers/  invoices/  receipts/  pdf/  profiles/
│
└── tests/
    ├── __init__.py
    ├── factories.py                         # model factories
    ├── unit/                                # services + repositories + validators
    ├── api/                                 # endpoint tests
    └── integration/                         # tenant isolation, RBAC, double-booking
```

---

# B. FRONTEND STRUCTURE (Next.js — static export)

```
frontend/
│
├── package.json
├── package-lock.json
├── next.config.mjs                          # output: 'export', images unoptimized
├── tsconfig.json
├── tailwind.config.ts
├── postcss.config.mjs
├── components.json                          # ShadCN config
├── .env.example                             # NEXT_PUBLIC_API_URL
├── .eslintrc.json
├── .gitignore
├── README.md
│
├── public/
│   ├── logo.svg  favicon.ico
│   └── icons/
│
├── app/                                     # Next.js App Router
│   ├── layout.tsx                           # root layout + providers
│   ├── page.tsx                             # landing → redirect to /dashboard or /login
│   ├── globals.css                          # Tailwind + ShadCN tokens (Slate)
│   ├── not-found.tsx
│   │
│   ├── (auth)/                              # PUBLIC route group
│   │   ├── layout.tsx
│   │   ├── login/page.tsx
│   │   ├── forgot-password/page.tsx
│   │   └── reset-password/page.tsx
│   │
│   ├── (dashboard)/                         # PROTECTED route group (client-side guard)
│   │   ├── layout.tsx                       # sidebar + topbar shell
│   │   │
│   │   ├── dashboard/page.tsx
│   │   │
│   │   ├── customers/
│   │   │   ├── page.tsx                     # list (server-paginated DataTable)
│   │   │   ├── new/page.tsx
│   │   │   ├── [id]/page.tsx
│   │   │   └── [id]/edit/page.tsx
│   │   │
│   │   ├── leads/
│   │   │   ├── page.tsx  new/page.tsx
│   │   │   ├── [id]/page.tsx
│   │   │   └── [id]/edit/page.tsx
│   │   │
│   │   ├── bookings/
│   │   │   ├── page.tsx
│   │   │   ├── new/page.tsx                 # multi-step wizard
│   │   │   ├── [id]/page.tsx                # detail + timeline
│   │   │   ├── [id]/edit/page.tsx
│   │   │   └── calendar/page.tsx            # daily/weekly/monthly view
│   │   │
│   │   ├── venues/                          # list/new/[id]/[id]/edit
│   │   ├── packages/                        # same pattern
│   │   ├── payments/                        # list/new/[id]/[id]/refund
│   │   ├── invoices/                        # list/[id]/[id]/pdf-preview
│   │   ├── vendors/                         # list/new/[id]/[id]/edit/assign
│   │   ├── inventory/                       # list/new/[id]/[id]/edit/allocations
│   │   ├── staff/                           # list/new/[id]/[id]/edit
│   │   ├── tasks/                           # board/detail/new/edit
│   │   │
│   │   ├── reports/
│   │   │   ├── page.tsx                     # analytics dashboard
│   │   │   ├── revenue/page.tsx
│   │   │   ├── bookings/page.tsx
│   │   │   ├── occupancy/page.tsx
│   │   │   ├── payments/page.tsx
│   │   │   ├── leads/page.tsx
│   │   │   ├── vendors/page.tsx
│   │   │   ├── inventory/page.tsx
│   │   │   ├── staff/page.tsx
│   │   │   └── subscription/page.tsx
│   │   │
│   │   ├── subscriptions/                   # current-plan/billing/renew/upgrade
│   │   ├── notifications/page.tsx
│   │   ├── audit-logs/                      # list/[id]
│   │   └── settings/                        # business/users/roles/notifications/invoice/security
│   │
│   └── (portal)/                            # CUSTOMER portal route group
│       ├── layout.tsx
│       └── dashboard/                       # booking/payments/invoices/timeline
│
├── components/                              # shared UI
│   ├── ui/                                  # ShadCN primitives (button, input, table, dialog, ...)
│   ├── layout/                              # sidebar, topbar, shell, breadcrumbs
│   ├── data/                                # data-table, empty-state, skeleton, pagination
│   ├── form/                                # form-field, date-picker, select, file-upload
│   ├── charts/                              # Recharts wrappers (line/bar/pie/area)
│   └── common/                              # status-badge, page-header, confirm-dialog
│
├── features/                                # feature modules (api + hooks + schemas + components)
│   ├── dashboard/                           # api.ts hooks.ts components/
│   ├── crm/
│   │   ├── customers/                       # api.ts hooks.ts schemas.ts components/
│   │   └── leads/
│   ├── bookings/
│   ├── venues/
│   ├── packages/
│   ├── payments/
│   ├── invoices/
│   ├── vendors/
│   ├── inventory/
│   ├── staff/
│   ├── tasks/
│   ├── reports/
│   ├── subscriptions/
│   ├── notifications/
│   ├── audit-logs/
│   └── settings/
│
├── hooks/                                   # global hooks
│   ├── use-auth.ts  use-current-user.ts
│   ├── use-debounce.ts  use-permissions.ts
│
├── lib/                                     # core libraries
│   ├── api-client.ts                        # Axios instance + interceptors + token refresh
│   ├── query-client.ts                      # TanStack Query setup
│   ├── auth.ts                              # cookie-based token storage helpers
│   ├── utils.ts                             # cn() + formatters
│   └── constants.ts
│
├── services/                                # centralized API service modules
│   ├── auth.service.ts  users.service.ts
│   ├── customers.service.ts  leads.service.ts
│   ├── bookings.service.ts  venues.service.ts
│   ├── payments.service.ts  invoices.service.ts
│   ├── vendors.service.ts  inventory.service.ts
│   ├── staff.service.ts  tasks.service.ts
│   ├── reports.service.ts  dashboard.service.ts
│   ├── subscriptions.service.ts  notifications.service.ts
│   └── index.ts
│
├── stores/                                  # Context API global state
│   ├── auth-context.tsx                     # user, tenant, permissions
│   ├── tenant-context.tsx
│   └── theme-context.tsx
│
├── types/
│   ├── api.ts                               # response envelope types
│   ├── models.ts                            # entity types mirroring backend
│   ├── enums.ts                             # status / role enums
│   └── index.ts
│
├── utils/
│   ├── format.ts                            # INR + Asia/Kolkata formatting
│   ├── validation.ts                        # shared zod schemas
│   └── permissions.ts                       # role-based menu/route visibility
│
└── lib/route-guard.tsx                      # client-side route protection (static export = no server mw)
```

> Note: Because the build is `output: 'export'`, there is **no Next.js server
> middleware**. Route protection is client-side (`route-guard.tsx`) and enforced
> authoritatively by the backend RBAC on every API call.

---

# C. MOBILE STRUCTURE (Flutter — BLoC + clean architecture)

```
mobile/
│
├── pubspec.yaml
├── analysis_options.yaml
├── .env.example                             # API base URLs per flavor
├── .gitignore
├── README.md
│
├── android/
├── ios/
├── web/
│
├── lib/
│   ├── main.dart                            # entry: MultiBlocProvider + runApp
│   ├── injection.dart                       # service locator (get_it)
│   │
│   ├── core/
│   │   ├── config/
│   │   │   ├── app_config.dart              # dev/prod API URLs
│   │   │   └── flavor.dart
│   │   ├── constants/
│   │   │   ├── app_constants.dart
│   │   │   ├── api_endpoints.dart
│   │   │   └── storage_keys.dart
│   │   ├── theme/
│   │   │   ├── app_theme.dart               # Material 3
│   │   │   ├── app_colors.dart
│   │   │   └── app_text_styles.dart
│   │   ├── network/
│   │   │   ├── dio_client.dart              # Dio setup
│   │   │   ├── auth_interceptor.dart        # JWT attach + refresh on 401
│   │   │   ├── error_interceptor.dart
│   │   │   └── api_response.dart
│   │   ├── storage/
│   │   │   └── secure_storage_service.dart  # flutter_secure_storage
│   │   ├── errors/
│   │   │   ├── exceptions.dart
│   │   │   └── failures.dart
│   │   ├── routing/
│   │   │   ├── app_router.dart              # go_router
│   │   │   ├── route_names.dart
│   │   │   └── guards.dart                  # auth + role guards
│   │   └── utils/
│   │       ├── formatters.dart              # INR + Asia/Kolkata
│   │       ├── validators.dart
│   │       └── enum_helpers.dart
│   │
│   ├── shared/
│   │   ├── widgets/                         # app_button, app_text_field, status_chip, loading, ...
│   │   │   └── charts/                      # fl_chart wrappers
│   │   └── layout/                          # app_scaffold, app_drawer, bottom_nav
│   │
│   ├── auth/                                # global auth session
│   │   ├── auth_bloc.dart  auth_event.dart  auth_state.dart
│   │   └── auth_session.dart
│   │
│   ├── features/
│   │   ├── authentication/
│   │   │   ├── data/
│   │   │   │   ├── datasources/auth_remote_datasource.dart
│   │   │   │   └── models/ (login_request_model, auth_response_model)
│   │   │   ├── domain/
│   │   │   │   ├── entities/user_entity.dart
│   │   │   │   ├── repositories/auth_repository_contract.dart
│   │   │   │   └── usecases/login_usecase.dart
│   │   │   └── presentation/
│   │   │       ├── bloc/login_bloc.dart (+ _event, _state)
│   │   │       ├── pages/login_page.dart
│   │   │       ├── pages/forgot_password_page.dart
│   │   │       └── widgets/
│   │   │
│   │   ├── dashboard/                       # data/ domain/ presentation/bloc+pages
│   │   ├── crm/
│   │   │   ├── customers/
│   │   │   └── leads/
│   │   ├── bookings/                        # incl. calendar
│   │   ├── venues/
│   │   ├── payments/
│   │   ├── invoices/
│   │   ├── notifications/
│   │   ├── customer_portal/                 # customer-facing subset
│   │   └── profile/
│   │
│   └── (each feature follows data/ domain/ presentation/ — one BLoC per module)
│
└── test/
    ├── unit/
    ├── widget/
    └── integration/
```

---

# D. DEPLOYMENT LAYOUT (cPanel shared hosting)

```
public_html/
├── index.html                  # Next.js static export (app.yourdomain.com)
├── _next/                      # Next.js static assets
├── api/                        # Django (Passenger WSGI) — api.yourdomain.com
│   ├── passenger_wsgi.py
│   └── (backend project files)
└── media/                      # uploads — media.yourdomain.com
```

END OF PHASE 2.
