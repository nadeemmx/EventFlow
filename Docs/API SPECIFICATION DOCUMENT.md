# DOCUMENT 08

# API SPECIFICATION DOCUMENT

Project: EventFlow

Version: 1.0

Backend:
Django REST Framework

API Version:
v1

Base URL:

/api/v1/

Authentication:
JWT

Response Format:
JSON

---

# API STANDARDS

All APIs must return:

Success Response

```json
{
  "success": true,
  "message": "Operation successful",
  "data": {}
}
```

---

Error Response

```json
{
  "success": false,
  "message": "Validation failed",
  "errors": {}
}
```

---

Pagination Response

```json
{
  "success": true,
  "data": [],
  "pagination": {
    "page": 1,
    "page_size": 20,
    "total_records": 100,
    "total_pages": 5
  }
}
```

---

# AUTHENTICATION

## Login

POST

/api/v1/auth/login/

Request

```json
{
  "email": "owner@example.com",
  "password": "Password123"
}
```

Response

```json
{
  "access_token": "",
  "refresh_token": "",
  "user": {}
}
```

---

## Refresh Token

POST

/api/v1/auth/refresh/

---

## Logout

POST

/api/v1/auth/logout/

---

## Forgot Password

POST

/api/v1/auth/forgot-password/

---

## Reset Password

POST

/api/v1/auth/reset-password/

---

## Change Password

POST

/api/v1/auth/change-password/

---

# PROFILE

## Current User

GET

/api/v1/profile/

---

## Update Profile

PUT

/api/v1/profile/

---

# TENANTS

## Tenant Detail

GET

/api/v1/tenant/

---

## Update Tenant

PUT

/api/v1/tenant/

---

# USERS

## List Users

GET

/api/v1/users/

---

Filters

role

status

search

---

## Create User

POST

/api/v1/users/

---

## User Detail

GET

/api/v1/users/{id}/

---

## Update User

PUT

/api/v1/users/{id}/

---

## Activate User

POST

/api/v1/users/{id}/activate/

---

## Deactivate User

POST

/api/v1/users/{id}/deactivate/

---

# VENUES

## List Venues

GET

/api/v1/venues/

---

Filters

status

venue_type

search

---

## Create Venue

POST

/api/v1/venues/

---

## Venue Detail

GET

/api/v1/venues/{id}/

---

## Update Venue

PUT

/api/v1/venues/{id}/

---

## Delete Venue

DELETE

/api/v1/venues/{id}/

Soft Delete Only

---

## Venue Gallery Upload

POST

/api/v1/venues/{id}/images/

Multipart Form Data

---

# CUSTOMERS

## List Customers

GET

/api/v1/customers/

---

Filters

search

mobile

email

---

## Create Customer

POST

/api/v1/customers/

---

## Customer Detail

GET

/api/v1/customers/{id}/

---

## Update Customer

PUT

/api/v1/customers/{id}/

---

## Merge Customers

POST

/api/v1/customers/merge/

---

# LEADS

## List Leads

GET

/api/v1/leads/

---

Filters

status

source

assigned_to

---

## Create Lead

POST

/api/v1/leads/

---

## Lead Detail

GET

/api/v1/leads/{id}/

---

## Update Lead

PUT

/api/v1/leads/{id}/

---

## Convert Lead

POST

/api/v1/leads/{id}/convert/

---

## Add Follow-up

POST

/api/v1/leads/{id}/followups/

---

# BOOKINGS

## List Bookings

GET

/api/v1/bookings/

---

Filters

status

venue

event_type

date_range

---

## Create Booking

POST

/api/v1/bookings/

---

## Booking Detail

GET

/api/v1/bookings/{id}/

---

## Update Booking

PUT

/api/v1/bookings/{id}/

---

## Cancel Booking

POST

/api/v1/bookings/{id}/cancel/

---

## Confirm Booking

POST

/api/v1/bookings/{id}/confirm/

---

## Booking Timeline

GET

/api/v1/bookings/{id}/timeline/

---

## Booking Calendar

GET

/api/v1/bookings/calendar/

Parameters

month

year

venue

---

# PAYMENTS

## List Payments

GET

/api/v1/payments/

---

Filters

booking

date_range

method

---

## Create Payment

POST

/api/v1/payments/

---

## Payment Detail

GET

/api/v1/payments/{id}/

---

## Refund Payment

POST

/api/v1/payments/{id}/refund/

---

## Payment Receipt

GET

/api/v1/payments/{id}/receipt/

---

# INVOICES

## List Invoices

GET

/api/v1/invoices/

---

## Generate Invoice

POST

/api/v1/invoices/generate/

---

## Invoice Detail

GET

/api/v1/invoices/{id}/

---

## Download Invoice PDF

GET

/api/v1/invoices/{id}/pdf/

---

# PACKAGES

## List Packages

GET

/api/v1/packages/

---

## Create Package

POST

/api/v1/packages/

---

## Package Detail

GET

/api/v1/packages/{id}/

---

## Update Package

PUT

/api/v1/packages/{id}/

---

# VENDORS

## List Vendors

GET

/api/v1/vendors/

---

Filters

vendor_type

status

---

## Create Vendor

POST

/api/v1/vendors/

---

## Vendor Detail

GET

/api/v1/vendors/{id}/

---

## Update Vendor

PUT

/api/v1/vendors/{id}/

---

## Assign Vendor

POST

/api/v1/vendors/assign/

---

# INVENTORY

## List Inventory

GET

/api/v1/inventory/

---

## Create Inventory Item

POST

/api/v1/inventory/

---

## Inventory Detail

GET

/api/v1/inventory/{id}/

---

## Allocate Inventory

POST

/api/v1/inventory/allocate/

---

## Release Inventory

POST

/api/v1/inventory/release/

---

# STAFF

## List Staff

GET

/api/v1/staff/

---

## Create Staff

POST

/api/v1/staff/

---

## Staff Detail

GET

/api/v1/staff/{id}/

---

## Update Staff

PUT

/api/v1/staff/{id}/

---

# TASKS

## List Tasks

GET

/api/v1/tasks/

---

Filters

status

priority

assigned_to

---

## Create Task

POST

/api/v1/tasks/

---

## Task Detail

GET

/api/v1/tasks/{id}/

---

## Update Task

PUT

/api/v1/tasks/{id}/

---

## Change Task Status

POST

/api/v1/tasks/{id}/status/

---

# REPORTS

## Revenue Report

GET

/api/v1/reports/revenue/

---

## Booking Report

GET

/api/v1/reports/bookings/

---

## Payment Report

GET

/api/v1/reports/payments/

---

## Occupancy Report

GET

/api/v1/reports/occupancy/

---

## Vendor Report

GET

/api/v1/reports/vendors/

---

## Inventory Report

GET

/api/v1/reports/inventory/

---

# SUBSCRIPTIONS

## Current Subscription

GET

/api/v1/subscription/

---

## Subscription History

GET

/api/v1/subscription/history/

---

## Renew Subscription

POST

/api/v1/subscription/renew/

---

# NOTIFICATIONS

## List Notifications

GET

/api/v1/notifications/

---

## Mark Read

POST

/api/v1/notifications/{id}/read/

---

# DASHBOARD

## Dashboard Summary

GET

/api/v1/dashboard/summary/

Response

```json
{
  "today_events": 0,
  "upcoming_bookings": 0,
  "pending_payments": 0,
  "active_leads": 0,
  "monthly_revenue": 0
}
```

---

# FILE UPLOAD RULES

Allowed Types

jpg

jpeg

png

pdf

---

Max File Size

10 MB

---

Storage Path

/media/

---

# SEARCH STANDARD

Supported Query

?search=value

---

Applies To

Customers

Bookings

Leads

Vendors

Users

---

# SORTING STANDARD

Example

?ordering=name

?ordering=-created_at

---

# PAGINATION STANDARD

Default

20 Records

---

Maximum

100 Records

---

# SECURITY REQUIREMENTS

Every API Must Validate

1. Authentication

2. Tenant Ownership

3. Role Permission

4. Business Rules

---

# VERSIONING STRATEGY

Current

/api/v1/

Future

/api/v2/

---

Old versions remain active during migration.

---

# SHARED HOSTING RULES

No WebSocket Endpoints

No Redis Dependency

No Celery Dependency

All background actions handled through:

Django Management Commands

*

cPanel Cron Jobs

END OF DOCUMENT 08
