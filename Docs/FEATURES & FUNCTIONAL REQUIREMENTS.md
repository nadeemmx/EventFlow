# DOCUMENT 02

# FEATURES & FUNCTIONAL REQUIREMENTS (FRS)

Project: EventFlow

Version: 1.0

---

# 1. AUTHENTICATION MODULE

## Purpose

Secure access to system resources.

---

## Features

### Login

Fields:

* Email
* Password

Validation:

* Email required
* Password required

Actions:

* Authenticate user
* Generate JWT Access Token
* Generate Refresh Token

---

### Logout

Actions:

* Invalidate token
* Clear active session

---

### Forgot Password

Fields:

* Email

Actions:

* Generate reset token
* Send reset link

---

### Change Password

Fields:

* Current Password
* New Password
* Confirm Password

Rules:

* Minimum 8 characters
* At least one uppercase
* At least one lowercase
* At least one number

---

# 2. TENANT MANAGEMENT MODULE

## Purpose

Manage SaaS customers.

---

## Create Tenant

Fields

* Business Name
* Owner Name
* Email
* Mobile Number
* Subscription Plan
* Business Address
* GST Number (Optional)

System Generated

* Tenant ID
* Created Date

---

## Tenant Status

Possible Values

```text
ACTIVE
INACTIVE
SUSPENDED
EXPIRED
TRIAL
```

---

## Tenant Settings

Configurable:

* Company Logo
* Company Name
* GST Details
* Invoice Prefix
* Currency
* Timezone

---

# 3. USER MANAGEMENT MODULE

## Create User

Fields

* Full Name
* Email
* Mobile
* Role
* Password

---

## User Roles

```text
SUPER_ADMIN

OWNER

MANAGER

ACCOUNTANT

STAFF

CUSTOMER
```

---

## Permissions Matrix

OWNER

* Full Access

MANAGER

* Booking Access
* Customer Access
* Vendor Access

ACCOUNTANT

* Payment Access
* Invoice Access

STAFF

* Task Access Only

CUSTOMER

* Self Portal Only

---

# 4. VENUE MANAGEMENT MODULE

## Create Venue

Fields

* Venue Name
* Venue Type
* Capacity
* Description
* Address
* Latitude
* Longitude
* Base Price

---

## Venue Types

```text
MARRIAGE_LAWN

BANQUET_HALL

CONVENTION_CENTER

PARTY_PLOT

RESORT
```

---

## Venue Status

```text
ACTIVE

INACTIVE

MAINTENANCE
```

---

## Venue Gallery

Features

* Upload Images
* Delete Images
* Reorder Images

Limit

20 Images Per Venue

---

## Venue Pricing

Fields

* Weekday Price
* Weekend Price
* Peak Season Price

---

# 5. CUSTOMER CRM MODULE

## Lead Creation

Fields

* Name
* Mobile
* Email
* Event Type
* Expected Date
* Expected Guests
* Source

---

## Lead Sources

```text
WEBSITE

GOOGLE

FACEBOOK

INSTAGRAM

WHATSAPP

WALK_IN

REFERRAL
```

---

## Lead Status

```text
NEW

CONTACTED

SITE_VISIT

NEGOTIATION

QUOTATION_SENT

ADVANCE_RECEIVED

CONVERTED

LOST
```

---

## Follow-up Tracking

Fields

* Follow-up Date
* Notes
* Next Action

---

# 6. BOOKING MANAGEMENT MODULE

## Create Booking

Fields

* Booking Number
* Customer
* Venue
* Event Date
* Event Type
* Guest Count
* Package
* Total Amount
* Advance Amount

---

## Booking Status

```text
DRAFT

TENTATIVE

CONFIRMED

COMPLETED

CANCELLED

REFUNDED
```

---

## Booking Rules

Rule 1

One venue cannot have two confirmed bookings on same date.

---

Rule 2

Tentative bookings expire after configurable duration.

Default:

48 Hours

---

Rule 3

Confirmed booking requires advance payment.

---

Rule 4

Cancelled booking releases venue inventory.

---

## Booking Calendar

Views

* Daily
* Weekly
* Monthly
* Yearly

Colors

Green

Confirmed

Yellow

Tentative

Red

Cancelled

Blue

Completed

---

# 7. EVENT MANAGEMENT MODULE

## Event Types

```text
WEDDING

RECEPTION

ENGAGEMENT

BIRTHDAY

CORPORATE

ANNIVERSARY

OTHER
```

---

## Event Workflow

```text
Booking Created

↓

Quotation Approved

↓

Advance Paid

↓

Vendor Assignment

↓

Task Assignment

↓

Event Day

↓

Settlement

↓

Completed
```

---

# 8. PAYMENT MANAGEMENT MODULE

## Payment Entry

Fields

* Booking
* Amount
* Method
* Date
* Notes

---

## Payment Methods

```text
CASH

UPI

BANK_TRANSFER

CHEQUE

CARD
```

---

## Payment Status

```text
PENDING

PARTIAL

PAID

OVERDUE
```

---

## Auto Calculations

System Calculates

* Total Paid
* Remaining Balance
* Due Amount

---

# 9. QUOTATION MODULE

## Create Quotation

Fields

* Customer
* Venue
* Package
* Items
* Valid Until

---

## Quotation Status

```text
DRAFT

SENT

ACCEPTED

REJECTED

EXPIRED
```

---

# 10. INVOICE MODULE

## Invoice Generation

Generate:

* GST Invoice
* Non GST Invoice

---

## Invoice Fields

* Invoice Number
* Booking Number
* Customer Name
* GST Details
* Tax Amount
* Total Amount

---

## Invoice Formats

* PDF Download
* Print Format

---

# 11. VENDOR MANAGEMENT MODULE

## Vendor Fields

* Vendor Name
* Vendor Type
* Mobile
* Email
* Address

---

## Vendor Types

```text
CATERER

DECORATOR

DJ

PHOTOGRAPHER

VIDEOGRAPHER

SECURITY

CLEANING

OTHER
```

---

## Vendor Assignment

Vendor can be assigned to:

* Booking
* Event
* Task

---

# 12. INVENTORY MANAGEMENT MODULE

## Inventory Item

Fields

* Item Name
* Category
* Quantity
* Available Quantity

---

## Categories

```text
CHAIRS

TABLES

STAGE

LIGHTS

GENERATOR

SOUND_SYSTEM

DECORATION
```

---

## Inventory Rules

Cannot allocate inventory exceeding available stock.

---

# 13. STAFF MANAGEMENT MODULE

## Staff Fields

* Name
* Mobile
* Email
* Designation

---

## Staff Status

```text
ACTIVE

INACTIVE

ON_LEAVE
```

---

# 14. TASK MANAGEMENT MODULE

## Create Task

Fields

* Title
* Description
* Assigned To
* Due Date
* Priority

---

## Priority Levels

```text
LOW

MEDIUM

HIGH

URGENT
```

---

## Task Status

```text
OPEN

IN_PROGRESS

COMPLETED

CANCELLED
```

---

# 15. REPORTING MODULE

Reports

### Revenue Report

Filters

* Date Range
* Venue
* Branch

---

### Booking Report

Filters

* Event Type
* Status

---

### Payment Report

Filters

* Paid
* Pending
* Overdue

---

### Occupancy Report

Shows

* Venue Utilization %
* Booking Trends

---

# 16. SUBSCRIPTION MODULE

## Plans

STARTER

PROFESSIONAL

ENTERPRISE

---

## Billing Cycle

```text
MONTHLY

QUARTERLY

YEARLY
```

---

## Subscription Status

```text
ACTIVE

EXPIRED

CANCELLED

TRIAL
```

---

# 17. NOTIFICATION MODULE

Supported Notifications

* Booking Confirmation
* Payment Reminder
* Subscription Reminder
* Event Reminder

Channels

* Email
* WhatsApp

---

# 18. CUSTOMER PORTAL

Customer Can

* View Booking
* View Payments
* Download Invoices
* View Event Timeline

Customer Cannot

* Edit Booking
* Access Internal Data

---

# EDGE CASES

1. Booking Date Already Occupied

System must reject booking.

---

2. Subscription Expired

Tenant login blocked except renewal screen.

---

3. Deleted Customer With Existing Booking

Deletion prohibited.

---

4. Venue Under Maintenance

Booking creation prohibited.

---

5. Invoice Already Generated

Invoice number immutable.

END OF DOCUMENT 02
