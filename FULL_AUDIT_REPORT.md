# EVENTFLOW -- COMPLETE DJANGO APPS AUDIT REPORT
Generated: 2026-06-28

---

## TABLE OF CONTENTS
1. Global Infrastructure
2. Per-App Audits (22 apps)
3. Cross-Cutting Issues
4. Security Findings
5. Performance Concerns
6. Code Quality Issues

---

## 1. GLOBAL INFRASTRUCTURE

### Core Base Models (core/base_models.py)
- BaseModel: created_at (auto_now_add), updated_at (auto_now)
- TenantBaseModel extends BaseModel: tenant FK, is_deleted, deleted_at, deleted_by, created_by, updated_by

### Core Mixins (core/mixins.py) -- DEAD CODE
All three mixins (TimeStampedMixin, SoftDeleteMixin, AuditMixin) are stubs with None/False values. Never imported anywhere. The real logic lives in TenantBaseModel.

### EncryptedTextField (core/fields.py)
Uses django.core.signing (HMAC-based) not actual encryption. Anyone with SECRET_KEY can decode stored values. Used for API keys, SMTP passwords, webhook secrets in settings/models.py.

### Razorpay Webhook (config/api_router.py lines 39-92)
- Creates Payment objects directly, bypassing PaymentService
- Searches bookings globally without tenant filter (line 74)
- Uses inline __import__("datetime") (line 86)
- Not wrapped in transaction.atomic

### Feature Limits (permissions/feature_limits.py) -- NEVER ENFORCED
EnforceUserLimit and EnforceVenueLimit always return True. SubscriptionPlan limits (max_users, max_venues, max_bookings_per_month) are defined but never checked.

### AuditMiddleware (middleware/audit.py) -- DEAD CODE
Empty process_view method. Not registered in MIDDLEWARE setting anyway.

### Settings Highlights
- SECRET_KEY defaults to "insecure-dev-key-change-in-production"
- Cache is LocMemCache (no Redis)
- Rate limits: anon 100/hr, user 1000/hr, login 5/min
- JWT: 60min access, 24hr refresh, with rotation and blacklisting
- DEFAULT_AUTO_FIELD = BigAutoField (good)

---

## 2. PER-APP AUDITS

### APP: authentication

Models:
  PasswordResetCode -- user FK, code (hashed via make_password), created_at, is_used
  (No tenant field, acceptable for user-scoped data)

Serializers (6): LoginSerializer, RefreshSerializer, ForgotPasswordSerializer,
  ResetPasswordSerializer (validates match + strength), ChangePasswordSerializer,
  ProfileSerializer

Views (7): LoginView (AllowAny, throttled 5/min), RefreshView (AllowAny, NO throttle),
  LogoutView (IsAuthenticated), ForgotPasswordView (AllowAny, throttled),
  ResetPasswordView (AllowAny, NO throttle), ChangePasswordView (IsAuthenticated),
  ProfileView (IsAuthenticated)

URLs: Defined in both authentication/urls.py AND api_router.py. urls.py content is dead code.

Issues:
  [!] admin.py is empty -- PasswordResetCode not registered
  [!] ResetPasswordView has no rate limiting
  [!] RefreshView has no rate limiting
  [!] ProfileView.put uses setattr bypassing model validation
  [!] Duplicate URL paths (urls.py never included)
  [!] No cleanup of expired/used password reset codes

---

### APP: bookings

Models:
  Booking (TenantBaseModel) -- booking_number (unique), venue FK (nullable),
    customer FK, package FK (nullable), event_type, event_date, guest_count,
    total_amount, advance_amount, status, remarks
    Indexes: (tenant,event_date), (tenant,venue,event_date), (tenant,status), (tenant,created_at)

  BookingHistory (TenantBaseModel) -- booking FK, old_status, new_status, remarks
    Indexes: (tenant,booking), (tenant,created_at)

Serializers (3): BookingSerializer (SerializerMethodField for names),
  BookingHistorySerializer, CalendarSerializer

Views: BookingViewSet (ModelViewSet) -- confirm, cancel, timeline,
  mark_in_progress, mark_completed, calendar, outstanding

Query optimization: select_related("customer", "venue", "package") -- GOOD

Issues:
  [!] urls.py is empty (all routing in api_router.py)
  [!] BookingHistory does not filter is_deleted=False in timeline action

---

### APP: contracts

Models:
  Contract (TenantBaseModel) -- booking FK, contract_number (unique), content,
    status (INLINE choices, not from core/choices.py), pdf_file, valid_from,
    valid_until, signed_date, signed_by_name, signed_by_designation,
    template_version, notes
    Indexes: (tenant,status), (tenant,created_at)

Serializers (2): ContractSerializer (3-level deep MethodFields),
  GenerateContractSerializer

Views: ContractViewSet (ModelViewSet) -- generate, pdf, sign, cancel

Query optimization: select_related("booking__customer", "booking__venue") -- GOOD

Issues:
  [!] urls.py is empty
  [!] Inline status choices instead of TextChoices (inconsistent)
  [!] Contract number generation has race condition (no select_for_update)
  [!] No soft delete -- hard delete for contracts unlike other apps
  [!] services.py inside app directory (all others in /backend/services/)

---

### APP: customers

Models:
  Customer (TenantBaseModel) -- full_name, mobile, email, address, remarks
  unique_together: (tenant, mobile)
  Indexes: (tenant,created_at), (tenant,full_name)

Serializers (2): CustomerSerializer, MergeCustomerSerializer

Views: CustomerViewSet (ModelViewSet) -- merge action

Query optimization: select_related("created_by", "updated_by") -- UNNECESSARY
  (neither field exposed in serializer)

Soft delete: Sets is_deleted + deleted_by. Validates no bookings/leads before deleting.

Issues:
  [!] urls.py is empty
  [!] MergeCustomerSerializer has no tenant validation on IDs
  [!] Unnecessary select_related on non-serializer fields

---

### APP: dashboard

No models.py, no serializers.py, no urls.py, no admin.py

Views: DashboardSummaryView (APIView) -- permissions: IsAuthenticated, ModuleAccessPermission

Issues:
  [!!!] MISSING TenantScopedPermission -- only view without it
  [!] No admin (acceptable, no models)

---

### APP: expenses

Models:
  Expense (TenantBaseModel) -- expense_category (free-text CharField, NOT choices enum),
    amount, expense_date, remarks
    Indexes: (tenant,expense_date), (tenant,expense_category), (tenant,created_at)

Serializer: ExpenseSerializer -- note created_by/updated_by not in fields

Views: ExpenseViewSet (ModelViewSet) -- soft delete with full audit (is_deleted + deleted_at + deleted_by + update_fields)

Issues:
  [!] urls.py is empty
  [!] expense_category is free text -- inconsistent with all other categorizations using TextChoices
  [!] updated_at not exposed in serializer despite being on model

---

### APP: inventory

Models:
  InventoryItem (TenantBaseModel) -- item_name, category (InventoryCategory),
    total_quantity, available_quantity, status
    unique_together: (tenant, item_name)

  InventoryAllocation (TenantBaseModel) -- booking FK, inventory_item FK, allocated_quantity

Serializers (2): InventorySerializer, AllocateInventorySerializer

Views: InventoryViewSet (ModelViewSet) -- allocate, release actions

Issues:
  [!] urls.py is empty
  [!] InventoryAllocation not in admin
  [!] Double save in perform_create (sets available_quantity after initial save)
  [!] No select_for_update on allocate/release -- race condition risk
  [!] No quantity validation at serializer level

---

### APP: invoices

Models:
  Invoice (TenantBaseModel) -- booking FK, invoice_number (unique), invoice_date,
    subtotal, tax_amount, total_amount, pdf_file
    Indexes: (tenant,invoice_date), (tenant,created_at)

Serializer: InvoiceSerializer -- only FK IDs, no nested data

Views: InvoiceViewSet (ModelViewSet) -- generate, pdf, email actions

Query optimization: select_related("booking__customer", "booking__venue", "booking__tenant")
  -- booking__tenant is REDUNDANT (already filtered by tenant)

Issues:
  [!] urls.py is empty
  [!!!] MISSING is_deleted=False filter in get_queryset
  [!] No soft delete -- hard delete for invoices
  [!] Invoice number generation race condition

---

### APP: leads

Models:
  Lead (TenantBaseModel) -- customer FK, lead_source, event_type,
    expected_event_date, expected_guest_count, lead_status, assigned_to FK

  FollowUp (TenantBaseModel) -- lead FK, followup_date, notes, next_action

  Quotation (TenantBaseModel) -- lead FK (nullable), customer FK, venue FK,
    package FK, valid_until, status, subtotal, tax_amount, total_amount

  QuotationItem (TenantBaseModel) -- quotation FK, item_name, quantity,
    unit_price, total_price (NO ordering defined)

Serializers (5): LeadSerializer, FollowUpSerializer, QuotationItemSerializer,
  QuotationListSerializer, QuotationDetailSerializer, CreateQuotationSerializer

Views: LeadViewSet (ModelViewSet) -- convert, followups, add_followup
  QuotationViewSet (GenericViewSet) -- list, retrieve, create, update, destroy,
  send, accept, reject

Query optimization: Good use of select_related + prefetch_related("items")

Issues:
  [!] urls.py is empty
  [!] N+1 in QuotationListSerializer.get_item_count -- obj.items.count() per row
  [!] QuotationItem model has no ordering in Meta
  [!] QuotationViewSet.destroy does not set deleted_by (incomplete soft delete)
  [!] LeadViewSet does not override perform_destroy -- hard deletes
  [!] FollowUp queryset in followups action does not filter is_deleted=False
  [!] QuotationViewSet.retrieve rebuilds queryset instead of using cached one

---

### APP: notifications

Models:
  Notification (BASEMODEL, NOT TenantBaseModel) -- tenant FK (nullable),
    user FK (nullable), title, message, channel, status
  CRITICAL: No is_deleted field, no deleted_by, no created_by/updated_by

Serializer: NotificationSerializer -- does NOT expose user or tenant

Views: NotificationViewSet (ReadOnlyModelViewSet) -- mark_read action

Issues:
  [!] urls.py is empty
  [!!!] Uses BaseModel instead of TenantBaseModel -- no soft delete, no audit fields
  [!!!] mark_read sets status="READ" but NotificationStatus choices are
       PENDING/SENT/FAILED -- writes invalid value to DB
  [!] No is_deleted filter (model lacks the field)

---

### APP: packages

Models:
  Package (TenantBaseModel) -- name, description, base_price, status
    unique_together: (tenant, name)

  PackageItem (TenantBaseModel) -- package FK (related_name="items"),
    item_name, quantity, unit_price

Serializers (2): PackageItemSerializer, PackageSerializer (nested items, read-only)

Views: PackageViewSet (ModelViewSet) -- basic CRUD

Query optimization: prefetch_related("items") -- GOOD

Issues:
  [!] urls.py is empty
  [!] No soft delete override -- hard deletes for packages
  [!] PackageItem ordering is -created_at, not user-defined order

---

### APP: payments

Models:
  Payment (TenantBaseModel) -- booking FK, amount, payment_method, payment_type,
    transaction_reference, payment_date, notes
    Indexes: (booking,payment_type), (tenant,payment_date), (tenant,created_at)

Serializers (2): PaymentSerializer, RefundSerializer (defined but unused in views)

Views: PaymentViewSet (ModelViewSet) -- refund, receipt, outstanding,
  receipt_pdf, summary, create_order, verify

Transaction usage: PaymentService uses @transaction.atomic on create/refund -- GOOD

Issues:
  [!] urls.py is empty
  [!] No soft delete -- hard deletes for payments
  [!] RefundSerializer defined but never used
  [!] Razorpay webhook creates Payment outside transaction
  [!] Razorpay webhook has csrf_exempt (acceptable for webhooks)

---

### APP: reports

No models.py. Service-only app.

Serializers (9): All plain Serializer classes for report structures.
  NEVER USED IN VIEWS -- views return raw service data.

Views: ReportViewSet (GenericViewSet) -- 9 report actions + export

Issues:
  [!] urls.py and admin.py both empty
  [!] Report serializers defined but never instantiated in any view
  [!] export action returns ok({"error": ...}) with 200 status for unknown types

---

### APP: settings

Models (8): PaymentGatewaySettings, WhatsAppSettings, EmailSettings,
  InvoiceSettings, BookingSettings, NotificationSettings, SecuritySettings,
  BrandingSettings -- all TenantBaseModel with encrypted fields where needed

Serializers (11): One per settings model + OrganizationSettingsSerializer,
  ProfileSerializer, UserSerializer, RoleSerializer, SettingsSubscriptionSerializer

Views: SettingsViewSet (GenericViewSet) -- GOD VIEW with 17 actions covering
  all settings categories + user management + roles + subscription

Issues:
  [!] admin.py is empty -- none of 8 settings models registered
  [!!!] God-view anti-pattern -- 17 actions in one ViewSet
  [!] services.py + repositories.py inside app directory (inconsistent with project pattern)
  [!] Cache invalidation calls CacheService.clear() -- nukes entire cache, not just settings
  [!] BrandingSettings has custom_css/custom_js -- XSS injection vector if compromised
  [!] SecuritySettings allowed_ips is unparsed TextField

---

### APP: staff

Models:
  Staff (TenantBaseModel) -- name, mobile, email, designation, joining_date, status
    unique_together: (tenant, mobile)

Serializer: StaffSerializer -- straightforward

Views: StaffViewSet (ModelViewSet) -- soft delete

Issues:
  [!] urls.py is empty
  [!] Soft delete incomplete -- sets is_deleted + deleted_by but NOT deleted_at

---

### APP: subscriptions

Models:
  SubscriptionPlan (BASEMODEL) -- plan_name, monthly_price, yearly_price,
    max_users, max_venues, max_bookings_per_month, storage_limit_mb,
    features (JSONField), status

  Subscription (BASEMODEL) -- tenant FK, plan FK, start_date, end_date,
    billing_cycle, status

  CreditBalance (BASEMODEL) -- tenant FK, credit_type, balance
    unique_together: (tenant, credit_type)

  CreditTransaction (BASEMODEL) -- tenant FK, credit_balance FK, quantity,
    transaction_type, description

CRITICAL: All 4 models use BaseModel, not TenantBaseModel. No soft delete, no audit fields.

Serializers (3): SubscriptionPlanSerializer (fields="__all__"), SubscriptionSerializer,
  RenewSubscriptionSerializer

Views: SubscriptionViewSet (GenericViewSet) -- plans, current, history, renew

Issues:
  [!] urls.py is empty
  [!] SubscriptionPlanSerializer uses fields="__all__" -- exposes everything
  [!] Plan limits (max_users etc.) NEVER ENFORCED anywhere
  [!] CreditBalance and CreditTransaction are DEAD MODELS -- no views, no admin
  [!] No is_deleted filtering (models lack the field)
  [!] CreditBalance/CreditTransaction not registered in admin

---

### APP: tasks

Models:
  Task (TenantBaseModel) -- booking FK, assigned_to FK (Staff, nullable),
    title, description, priority, status, due_date
    Indexes: (tenant,status), (tenant,assigned_to), (tenant,created_at)

Serializers (2): TaskSerializer, TaskStatusSerializer

Views: TaskViewSet (ModelViewSet) -- status action

Issues:
  [!] urls.py is empty
  [!] AuditLog creation in perform_update NOT wrapped in transaction.atomic
  [!] TaskSerializer does not expose nested booking/assigned_to names

---

### APP: tenants

Models:
  Tenant (BASEMODEL) -- business_name, owner_name, email (unique), mobile,
    address, gst_number, logo, subscription_plan FK, subscription_status, status

  TenantSettings (BASEMODEL) -- tenant OneToOneField, company_logo, company_name,
    gst_details, invoice_prefix, currency, timezone, gst_rate,
    tentative_booking_validity_hours

Serializers (2): TenantSerializer, TenantSettingsSerializer

Views: TenantViewSet (GenericViewSet) -- create (AllowAny), list, retrieve,
  update, partial_update, settings

Issues:
  [!] urls.py is empty
  [!] TenantViewSet.list() queryset is Tenant.objects.all() (global, not scoped)
  [!] settings action missing @action decorator -- not routable
  [!] create has no rate limiting
  [!] TenantSettings not registered in admin

---

### APP: users

Models:
  User (AbstractBaseUser, PermissionsMixin) -- tenant FK (nullable), full_name,
    email (unique), mobile, role, is_active, is_staff, last_login,
    created_at, updated_at

  UserSession -- user FK, access_token (PLAINTEXT TextField),
    refresh_token (PLAINTEXT TextField), device_name, ip_address,
    created_at, expires_at

Serializer: UserSerializer -- password write_only

Views: UserViewSet (ModelViewSet) -- activate, deactivate

Issues:
  [!] urls.py is empty
  [!!!] UserSession stores tokens in PLAINTEXT -- should be hashed
  [!] SUPER_ADMIN path in get_queryset missing select_related("tenant")
  [!] UserSession not in admin
  [!] No is_deleted filter (uses is_active deactivation instead)

---

### APP: vendors

Models:
  Vendor (TenantBaseModel) -- name, vendor_type, mobile, email, address, status
    unique_together: (tenant, mobile)

  BookingVendor (TenantBaseModel) -- booking FK, vendor FK, agreed_amount, status

Serializers (2): VendorSerializer, AssignVendorSerializer

Views: VendorViewSet (ModelViewSet) -- assign action

Issues:
  [!] urls.py is empty
  [!] BookingVendor not in admin
  [!] assign action has no duplicate check

---

### APP: venues

Models:
  Venue (TenantBaseModel) -- name, venue_type, capacity, description, address,
    latitude, longitude, weekday_price, weekend_price, peak_price, status
    unique_together: (tenant, name)

  VenueImage (TenantBaseModel) -- venue FK, image, display_order

Serializers (2): VenueSerializer, VenueImageSerializer

Views: VenueViewSet (ModelViewSet) -- images action

Query optimization: prefetch_related("images") -- GOOD

Issues:
  [!] urls.py is empty
  [!] VenueImage not in admin
  [!] VenueImageSerializer imported inside method (lazy import)
  [!] MAX_VENUE_IMAGES (20) from constants never enforced
  [!] Delete validation Booking.objects.filter(venue=instance) not tenant-scoped

---

### APP: audit_logs

Models:
  AuditLog (BASEMODEL, NOT TenantBaseModel) -- tenant FK (nullable), user FK,
    module, action, record_id (BigIntegerField), old_data (TextField),
    new_data (TextField), ip_address (CharField)

CRITICAL: Uses BaseModel. No soft delete, no is_deleted.

Serializer: AuditLogSerializer -- exposes all fields except tenant

Views: AuditLogViewSet (ReadOnlyModelViewSet) -- list and retrieve only

Issues:
  [!] urls.py is empty
  [!] old_data/new_data stored as Python repr string, not JSON
  [!] ip_address is CharField not GenericIPAddressField
  [!] record_id is BigIntegerField -- breaks if any model uses UUID PKs

---

## 3. CROSS-CUTTING ISSUES

### Tenant Isolation Gaps
  - dashboard: Missing TenantScopedPermission
  - invoices: No is_deleted=False filter
  - subscriptions: No tenant filtering via TenantBaseModel (manual FKs)
  - Razorpay webhook: Searches bookings without tenant filter
  - Tenant list: Queryset is Tenant.objects.all()
  - invoices: Redundant booking__tenant in select_related

### N+1 Query Risks
  - QuotationListSerializer.get_item_count: obj.items.count() per row
  - BookingHistory/Payment __str__: Accesses booking.booking_number
  - FollowUp.__str__: 2-level deep lead.customer.full_name
  - QuotationViewSet.retrieve: Rebuilds queryset

### Missing transaction.atomic
  - TaskViewSet.perform_update (audit log write)
  - ContractService (sign, cancel)
  - LeadService.convert_lead (creates lead + booking)
  - CustomerService.merge_customers (moves data)
  - Razorpay webhook payment creation

### Contract/Invoice Number Race Conditions
  Sequential generation without select_for_update or DB-level sequences.

### Soft Delete Inconsistencies
  - customers: Missing deleted_at
  - staff: Missing deleted_at
  - quotations: Missing deleted_by
  - contracts: Hard delete (no override)
  - invoices: Hard delete (no override)
  - packages: Hard delete (no override)
  - payments: Hard delete (no override)
  - leads: Hard delete (no override)

---

## 4. SECURITY FINDINGS

  [HIGH] EncryptedTextField uses signing not encryption -- SECRET_KEY compromise exposes all stored secrets
  [HIGH] UserSession stores JWT tokens in plaintext
  [HIGH] Plan subscription limits never enforced
  [HIGH] BrandingSettings custom_css/custom_js could enable XSS
  [HIGH] Razorpay webhook creates payments without tenant validation
  [MED] ResetPasswordView has no rate limiting
  [MED] RefreshView has no rate limiting
  [MED] Tenant create has no rate limiting
  [MED] Invoice queryset missing is_deleted filter
  [MED] No CSRF protection on Razorpay webhook (csrf_exempt, acceptable)
  [LOW] DEFAULT_AUTO_FIELD is BigAutoField (good)
  [LOW] Hardcoded default SECRET_KEY (mitigated by env var)
  [LOW] ALLOWED_HOSTS restrictive in production

---

## 5. PERFORMANCE CONCERNS

  - QuotationListSerializer.get_item_count does COUNT query per row despite prefetch
  - Settings cache invalidation nukes entire LocMemCache
  - Report serializers defined but never used (no output shaping/validation)
  - Expenses/Vendors/Staff select_related on non-serializer fields
  - invoices redundant booking__tenant select_related
  - Inventory perform_create does double save
  - LocMemCache in production (no shared cache for multi-process)

---

## 6. CODE QUALITY ISSUES

  - core/mixins.py: Dead code (3 unused stub mixins)
  - middleware/audit.py: Dead code (empty, not registered)
  - All 21 app urls.py files are empty (routing centralized in api_router.py)
  - Most admin.py files are minimal single-line registrations
  - subscriptions CreditBalance/CreditTransaction: Dead models (no views/admin)
  - reports serializers: Defined but never used
  - settings god-view: 17 actions in one ViewSet
  - Inconsistent soft delete implementations across apps
  - contracts uses inline status choices vs TextChoices everywhere else
  - notifications mark_read writes invalid status value
  - No signals.py files anywhere (audit is manual)
  - No custom managers anywhere (all use default ORM managers)
  - services.py inside contracts/ and settings/ apps but not others
  - Settings repositories.py inside app directory (inconsistent)

---

## APPS WITHOUT URLS.PY CONTENT (all 21):
authentication, bookings, contracts, customers, expenses, inventory,
invoices, leads, notifications, packages, payments, reports, settings,
staff, subscriptions, tasks, tenants, users, vendors, venues, audit_logs

All routing is centralized in config/api_router.py.

## APPS WITHOUT MODELS:
reports, dashboard

## APPS USING BASEMODEL INSTEAD OF TENANTBASEMODEL:
notifications, audit_logs, subscriptions (all 4 models), tenants (both models),
users (User model -- by design)

