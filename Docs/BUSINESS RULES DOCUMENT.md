# DOCUMENT 05

# BUSINESS RULES DOCUMENT (BRD)

Project: EventFlow

Version: 1.0

Industry: Marriage Lawn & Banquet Management

---

# PURPOSE

This document defines all business rules that govern system behavior.

Business rules take precedence over UI behavior.

Frontend, Backend, Mobile App and Reports must strictly follow these rules.

---

# SECTION 1

# TENANT RULES

Rule T-001

Every record must belong to exactly one tenant.

---

Rule T-002

Cross-tenant data access is prohibited.

---

Rule T-003

A tenant cannot view, modify or delete another tenant's data.

---

Rule T-004

Tenant deletion is prohibited.

Only soft deactivation allowed.

---

Rule T-005

Inactive tenant login prohibited.

---

Rule T-006

Expired subscription restricts access to all business modules except:

* Billing
* Subscription Renewal
* Profile

---

# SECTION 2

# USER RULES

Rule U-001

Every user belongs to exactly one tenant.

---

Rule U-002

One email address cannot exist twice within same tenant.

---

Rule U-003

User role changes must be audit logged.

---

Rule U-004

Owner role cannot be deleted.

---

Rule U-005

At least one active owner must always exist.

---

# SECTION 3

# CUSTOMER RULES

Rule C-001

Customer mobile number must be unique per tenant.

---

Rule C-002

Customer deletion prohibited if:

* Lead exists
  OR
* Booking exists

---

Rule C-003

Customer merge operation allowed.

Example:

Same customer entered twice.

System should support merge.

---

Rule C-004

Customer history must remain permanently available.

---

# SECTION 4

# LEAD MANAGEMENT RULES

Rule L-001

Every lead must belong to a customer.

---

Rule L-002

Lead status progression:

```text
NEW
↓
CONTACTED
↓
SITE_VISIT
↓
NEGOTIATION
↓
QUOTATION_SENT
↓
ADVANCE_RECEIVED
↓
CONVERTED
```

---

Rule L-003

Lost lead can be reopened.

---

Rule L-004

Converted lead automatically creates booking draft.

---

Rule L-005

Every follow-up action must be logged.

---

# SECTION 5

# VENUE RULES

Rule V-001

Venue name must be unique within tenant.

---

Rule V-002

Inactive venue cannot receive bookings.

---

Rule V-003

Venue under maintenance cannot receive bookings.

---

Rule V-004

Venue capacity cannot be below active booking guest count.

---

Rule V-005

Venue deletion prohibited if booking history exists.

---

# SECTION 6

# BOOKING RULES

Rule B-001

Booking number must be unique.

Format:

```text
VF-YYYY-000001
```

Example:

VF-2026-000001

---

Rule B-002

One venue cannot have multiple CONFIRMED bookings on same date.

Example:

Venue A

10-Dec-2026

Confirmed Booking Exists

Second Confirmed Booking = Reject

---

Rule B-003

Tentative bookings allowed.

---

Rule B-004

Tentative booking validity:

Default:

48 Hours

Configurable by Owner.

---

Rule B-005

Expired tentative booking automatically cancelled.

---

Rule B-006

Booking confirmation requires advance payment.

---

Rule B-007

Booking cancellation must release:

* Venue slot
* Inventory allocation
* Vendor reservations

---

Rule B-008

Completed booking cannot be edited.

---

Rule B-009

Cancelled booking cannot be confirmed again.

New booking required.

---

Rule B-010

Past event date bookings cannot be created.

---

Rule B-011

Guest count must not exceed venue capacity.

---

Rule B-012

Booking modifications must be audit logged.

---

# SECTION 7

# EVENT RULES

Rule E-001

Every booking must have exactly one event type.

---

Rule E-002

Event cannot start without confirmed booking.

---

Rule E-003

Event completion requires final settlement review.

---

Rule E-004

Completed event status immutable.

---

# SECTION 8

# PAYMENT RULES

Rule P-001

Payments cannot exceed remaining balance.

---

Rule P-002

Negative payments prohibited.

---

Rule P-003

Payment date cannot be future date.

---

Rule P-004

Booking status automatically updates based on payment state.

Example:

Advance Paid

↓

Confirmed

---

Rule P-005

Outstanding balance calculation:

```text
Outstanding =
Total Amount
-
Total Payments
```

---

Rule P-006

Payment modification requires audit logging.

---

Rule P-007

Deleted payments prohibited.

Only reversal entries allowed.

---

# SECTION 9

# REFUND RULES

Rule R-001

Refund only allowed for cancelled bookings.

---

Rule R-002

Refund amount cannot exceed total received amount.

---

Rule R-003

Refund transaction must create audit entry.

---

Rule R-004

Refund invoice mandatory.

---

# SECTION 10

# INVOICE RULES

Rule I-001

Invoice number must be unique.

---

Rule I-002

Generated invoice immutable.

---

Rule I-003

Invoice deletion prohibited.

---

Rule I-004

Invoice regeneration allowed only through revision process.

---

Rule I-005

GST calculation based on tenant configuration.

---

# SECTION 11

# VENDOR RULES

Rule VD-001

Vendor mobile number unique per tenant.

---

Rule VD-002

Inactive vendor cannot be assigned.

---

Rule VD-003

Vendor assignment requires confirmed booking.

---

Rule VD-004

Vendor payment cannot exceed agreed amount.

---

Rule VD-005

Vendor history permanently retained.

---

# SECTION 12

# INVENTORY RULES

Rule IN-001

Inventory quantity cannot be negative.

---

Rule IN-002

Allocated quantity cannot exceed available quantity.

---

Rule IN-003

Inventory allocation creates reservation.

---

Rule IN-004

Booking cancellation releases inventory.

---

Rule IN-005

Inventory deletion prohibited if allocation history exists.

---

Rule IN-006

Damaged inventory reduces available stock.

---

# SECTION 13

# STAFF RULES

Rule S-001

Inactive staff cannot receive tasks.

---

Rule S-002

Staff deletion prohibited.

Soft deactivate only.

---

Rule S-003

Assigned task history retained permanently.

---

# SECTION 14

# TASK RULES

Rule TK-001

Task must belong to booking.

---

Rule TK-002

Completed task cannot be edited.

---

Rule TK-003

Overdue tasks must be highlighted.

---

Rule TK-004

Cancelled booking auto-cancels pending tasks.

---

# SECTION 15

# REPORTING RULES

Rule RP-001

Reports must always respect tenant isolation.

---

Rule RP-002

Financial reports visible only to:

OWNER

ACCOUNTANT

---

Rule RP-003

Reports generated from live database.

No cached reports.

---

# SECTION 16

# SUBSCRIPTION RULES

Rule SB-001

Tenant must have active subscription.

---

Rule SB-002

Trial period default:

14 Days

---

Rule SB-003

Subscription expiry notifications:

30 Days Before

15 Days Before

7 Days Before

1 Day Before

---

Rule SB-004

Expired subscription restricts access.

---

Rule SB-005

Subscription renewal preserves all data.

---

# SECTION 17

# NOTIFICATION RULES

Rule N-001

Booking confirmation notification mandatory.

---

Rule N-002

Payment receipt notification mandatory.

---

Rule N-003

Subscription expiry reminders mandatory.

---

Rule N-004

Notification failure must be logged.

---

# SECTION 18

# AUDIT RULES

Audit logging mandatory for:

* Login
* Logout
* Booking Creation
* Booking Update
* Booking Cancellation
* Payment Entry
* Refund
* Invoice Generation
* User Creation
* User Role Change
* Subscription Change

---

# SECTION 19

# DATA RETENTION RULES

Rule DR-001

Business data never physically deleted.

---

Rule DR-002

Audit logs retained permanently.

---

Rule DR-003

Invoices retained permanently.

---

Rule DR-004

Payment history retained permanently.

---

# SECTION 20

# SHARED HOSTING RULES

Rule SH-001

No Redis dependency.

---

Rule SH-002

No Celery dependency.

---

Rule SH-003

Background jobs executed via cPanel Cron.

---

Rule SH-004

System must function without WebSockets.

---

Rule SH-005

All scheduled actions must be executable through Django Management Commands.

Examples:

* Expire Tentative Bookings
* Send Subscription Reminders
* Generate Scheduled Reports

END OF DOCUMENT 05
