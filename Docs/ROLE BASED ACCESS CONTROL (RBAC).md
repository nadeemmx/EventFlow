# DOCUMENT 04

# ROLE BASED ACCESS CONTROL (RBAC)

Project: EventFlow

Version: 1.0

Architecture: Multi-Tenant SaaS

Backend: Django + DRF

Frontend: Next.js

Mobile: Flutter (BLoC)

---

# OBJECTIVE

Provide strict access control ensuring:

* Tenant isolation
* Data security
* Permission-based operations
* API authorization
* Screen-level restrictions

---

# SYSTEM ROLES

Level 1

SUPER_ADMIN

Level 2

OWNER

Level 3

MANAGER

Level 4

ACCOUNTANT

Level 5

STAFF

Level 6

CUSTOMER

---

# ROLE HIERARCHY

SUPER_ADMIN

↓

OWNER

↓

MANAGER

↓

ACCOUNTANT

↓

STAFF

↓

CUSTOMER

---

# SUPER ADMIN

Purpose:

Platform Owner

Controls Entire SaaS

---

Access Scope

All Tenants

All Users

All Modules

All Reports

All Subscription Data

---

Permissions

Tenant Management

CREATE

READ

UPDATE

DELETE

---

Subscription Management

CREATE

READ

UPDATE

DELETE

---

User Management

READ ALL USERS

BLOCK USERS

ACTIVATE USERS

RESET PASSWORDS

---

System Reports

FULL ACCESS

---

Audit Logs

FULL ACCESS

---

System Settings

FULL ACCESS

---

Restrictions

Cannot create bookings on behalf of tenants.

Cannot access tenant passwords.

---

# OWNER

Purpose

Business Owner

Highest authority inside tenant.

---

Access Scope

Own Tenant Only

---

Permissions

Venue Management

FULL ACCESS

---

Customer Management

FULL ACCESS

---

Lead Management

FULL ACCESS

---

Booking Management

FULL ACCESS

---

Payment Management

FULL ACCESS

---

Invoice Management

FULL ACCESS

---

Vendor Management

FULL ACCESS

---

Inventory Management

FULL ACCESS

---

Staff Management

FULL ACCESS

---

Task Management

FULL ACCESS

---

Reports

FULL ACCESS

---

Tenant Settings

FULL ACCESS

---

Restrictions

Cannot access other tenants.

Cannot modify subscription billing records.

---

# MANAGER

Purpose

Daily Operations

---

Venue Management

CREATE

READ

UPDATE

NO DELETE

---

Customer Management

FULL ACCESS

---

Lead Management

FULL ACCESS

---

Booking Management

CREATE

READ

UPDATE

CANCEL

NO DELETE

---

Vendor Management

CREATE

READ

UPDATE

NO DELETE

---

Inventory Management

READ

UPDATE

---

Task Management

FULL ACCESS

---

Reports

READ ONLY

---

Restrictions

Cannot access financial reports.

Cannot access subscription settings.

Cannot delete records.

---

# ACCOUNTANT

Purpose

Finance Operations

---

Payments

FULL ACCESS

---

Invoices

FULL ACCESS

---

Expenses

FULL ACCESS

---

Financial Reports

FULL ACCESS

---

Customers

READ ONLY

---

Bookings

READ ONLY

---

Restrictions

Cannot modify bookings.

Cannot modify venues.

Cannot manage staff.

Cannot manage inventory.

---

# STAFF

Purpose

Operational Employees

---

Bookings

READ ONLY

Assigned Events Only

---

Tasks

READ

UPDATE OWN TASKS

---

Vendors

READ ONLY

---

Inventory

READ ONLY

---

Restrictions

Cannot create bookings.

Cannot view financial information.

Cannot access reports.

Cannot access settings.

---

# CUSTOMER

Purpose

Booking Customer

---

Access Scope

Own Data Only

---

Permissions

View Booking

View Payments

Download Invoices

View Event Timeline

---

Restrictions

Cannot edit bookings.

Cannot access vendor details.

Cannot access internal reports.

Cannot access staff data.

---

# MODULE ACCESS MATRIX

MODULE

SUPER_ADMIN

OWNER

MANAGER

ACCOUNTANT

STAFF

CUSTOMER

---

Dashboard

YES

YES

YES

YES

LIMITED

LIMITED

---

Venues

FULL

FULL

CRUD (No Delete)

NO

READ

NO

---

Customers

FULL

FULL

FULL

READ

NO

SELF

---

Leads

FULL

FULL

FULL

READ

NO

NO

---

Bookings

READ

FULL

CRUD

READ

READ

SELF

---

Payments

READ

FULL

READ

FULL

NO

SELF

---

Invoices

READ

FULL

READ

FULL

NO

SELF

---

Inventory

READ

FULL

UPDATE

NO

READ

NO

---

Staff

READ

FULL

READ

NO

SELF

NO

---

Reports

FULL

FULL

READ

FINANCE ONLY

NO

NO

---

Settings

FULL

FULL

NO

NO

NO

NO

---

# DJANGO IMPLEMENTATION RULES

Authentication Method

JWT

---

Permission System

Custom Permission Classes

Examples

IsOwner

IsManager

IsAccountant

IsStaff

IsCustomer

IsSuperAdmin

---

Every API must validate:

1. User Authentication

2. Tenant Ownership

3. Module Permission

4. Action Permission

---

# TENANT SECURITY RULES

Critical Rule

Every query must include:

tenant_id

Example:

Booking.objects.filter(
tenant_id=request.user.tenant_id
)

---

Forbidden

Booking.objects.all()

Never allowed.

---

# FRONTEND ROUTE PROTECTION

Next.js Middleware Required

---

Protected Routes

/dashboard

/bookings

/customers

/vendors

/payments

/reports

/settings

---

Role Based Routing

Owner

Can access all tenant pages.

Manager

Cannot access finance routes.

Accountant

Cannot access operational routes.

Staff

Can access assigned tasks only.

Customer

Can access portal only.

---

# FLUTTER ACCESS CONTROL

BLoC State must contain:

user_role

permissions

tenant_id

---

Screen Visibility Rules

Owner

Show all menu items.

Manager

Hide finance menu.

Accountant

Hide operational menu.

Staff

Show task menu only.

Customer

Show customer portal only.

---

# AUDIT REQUIREMENTS

The following actions must be logged:

Booking Created

Booking Updated

Booking Cancelled

Payment Added

Invoice Generated

Vendor Assigned

User Created

Role Changed

Subscription Updated

---

# SECURITY RULES

Rule 1

Never trust frontend permissions.

Backend validation mandatory.

---

Rule 2

Tenant validation mandatory on every API.

---

Rule 3

Role validation mandatory on every write operation.

---

Rule 4

Every critical operation must create audit log.

---

Rule 5

Direct object access forbidden.

Example:

Tenant A user must never access Booking ID belonging to Tenant B.

END OF DOCUMENT 04
