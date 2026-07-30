# DOCUMENT 06

# USER FLOW & WORKFLOW DOCUMENT

Project: EventFlow

Version: 1.0

Architecture:
Django + DRF + Next.js + Flutter (BLoC)

Hosting:
Shared Hosting (cPanel Compatible)

---

# OBJECTIVE

Define all major business workflows.

Every workflow must be implemented consistently across:

* Web Panel
* Mobile App
* APIs
* Reports

---

# WORKFLOW 01

# TENANT ONBOARDING FLOW

Purpose

Create new SaaS customer.

---

FLOW

```text
Super Admin

↓

Create Tenant

↓

Create Owner User

↓

Assign Subscription Plan

↓

Send Credentials

↓

Owner Login

↓

Setup Business Profile

↓

Setup Venue

↓

Ready To Use
```

---

SYSTEM ACTIONS

1. Create Tenant Record

2. Create Owner User

3. Assign Trial Plan

4. Create Default Settings

5. Create Audit Log

---

# WORKFLOW 02

# CUSTOMER LEAD FLOW

Purpose

Track inquiries.

---

FLOW

```text
Lead Created

↓

Contacted

↓

Site Visit

↓

Negotiation

↓

Quotation Sent

↓

Advance Received

↓

Converted

↓

Booking Draft Created
```

---

ALTERNATIVE FLOW

```text
Lead Created

↓

Contacted

↓

Lost
```

---

SYSTEM ACTIONS

Create Follow-up Records

Track Conversion Source

Create Audit Logs

---

# WORKFLOW 03

# BOOKING CREATION FLOW

Purpose

Create new booking.

---

FLOW

```text
Select Customer

↓

Select Venue

↓

Select Date

↓

Capacity Validation

↓

Conflict Validation

↓

Select Package

↓

Calculate Price

↓

Create Draft Booking
```

---

VALIDATIONS

Venue Active

Venue Not Under Maintenance

Date Not Occupied

Guest Count <= Capacity

Customer Exists

---

RESULT

Booking Status

DRAFT

---

# WORKFLOW 04

# BOOKING CONFIRMATION FLOW

Purpose

Convert draft booking into confirmed booking.

---

FLOW

```text
Draft Booking

↓

Advance Payment Added

↓

Payment Validation

↓

Booking Confirmed

↓

Inventory Reserved

↓

Notifications Sent
```

---

SYSTEM ACTIONS

Update Status

Create Payment Record

Generate Receipt

Generate Audit Entry

---

RESULT

Status

CONFIRMED

---

# WORKFLOW 05

# TENTATIVE BOOKING FLOW

Purpose

Hold venue temporarily.

---

FLOW

```text
Booking Created

↓

Tentative Status

↓

Waiting Period

↓

Payment Received
      OR
Time Expired

↓

Confirmed
      OR
Cancelled
```

---

DEFAULT VALIDITY

48 Hours

---

CRON JOB

Check Every Hour

Expire Old Tentative Bookings

---

# WORKFLOW 06

# BOOKING CANCELLATION FLOW

Purpose

Cancel confirmed booking.

---

FLOW

```text
Confirmed Booking

↓

Cancellation Request

↓

Cancellation Reason

↓

Release Inventory

↓

Release Vendors

↓

Cancel Pending Tasks

↓

Booking Cancelled
```

---

SYSTEM ACTIONS

Audit Entry

Notification

Optional Refund Workflow

---

RESULT

Status

CANCELLED

---

# WORKFLOW 07

# REFUND FLOW

Purpose

Refund customer payment.

---

FLOW

```text
Cancelled Booking

↓

Calculate Refund Amount

↓

Create Refund Entry

↓

Generate Refund Invoice

↓

Send Notification
```

---

VALIDATION

Refund <= Received Amount

---

RESULT

Status

REFUNDED

---

# WORKFLOW 08

# INVENTORY ALLOCATION FLOW

Purpose

Reserve inventory.

---

FLOW

```text
Confirmed Booking

↓

Select Inventory

↓

Check Availability

↓

Allocate Inventory

↓

Reduce Available Quantity
```

---

VALIDATION

Available Stock Required

---

RESULT

Inventory Reserved

---

# WORKFLOW 09

# INVENTORY RELEASE FLOW

Purpose

Restore stock.

---

FLOW

```text
Booking Cancelled

↓

Release Inventory

↓

Restore Quantities

↓

Create Audit Entry
```

---

RESULT

Inventory Available Again

---

# WORKFLOW 10

# VENDOR ASSIGNMENT FLOW

Purpose

Assign vendors.

---

FLOW

```text
Confirmed Booking

↓

Select Vendor

↓

Define Service

↓

Define Cost

↓

Assign Vendor

↓

Notify Vendor
```

---

VALIDATION

Vendor Active

Booking Confirmed

---

RESULT

Vendor Linked To Booking

---

# WORKFLOW 11

# STAFF ASSIGNMENT FLOW

Purpose

Assign event responsibilities.

---

FLOW

```text
Booking Confirmed

↓

Create Task

↓

Assign Staff

↓

Track Progress

↓

Task Completed
```

---

VALIDATION

Staff Active

---

RESULT

Task Assigned

---

# WORKFLOW 12

# EVENT EXECUTION FLOW

Purpose

Manage event day operations.

---

FLOW

```text
Event Day

↓

Verify Setup

↓

Verify Vendors

↓

Verify Staff

↓

Execute Event

↓

Close Event
```

---

CHECKLIST

Venue Ready

Inventory Ready

Staff Ready

Vendor Ready

Payments Reviewed

---

RESULT

Event Completed

---

# WORKFLOW 13

# EVENT COMPLETION FLOW

Purpose

Close booking lifecycle.

---

FLOW

```text
Event Completed

↓

Final Settlement

↓

Generate Final Invoice

↓

Close Outstanding Balance

↓

Mark Completed
```

---

RESULT

Status

COMPLETED

---

# WORKFLOW 14

# PAYMENT FLOW

Purpose

Record customer payments.

---

FLOW

```text
Select Booking

↓

Enter Amount

↓

Select Payment Method

↓

Save Payment

↓

Update Outstanding Balance

↓

Generate Receipt
```

---

AUTO CALCULATIONS

Total Paid

Remaining Balance

Payment Status

---

RESULT

Payment Stored

---

# WORKFLOW 15

# INVOICE FLOW

Purpose

Generate invoice.

---

FLOW

```text
Select Booking

↓

Calculate Charges

↓

Calculate GST

↓

Generate Invoice Number

↓

Generate PDF

↓

Store Invoice
```

---

RESULT

Invoice Created

---

# WORKFLOW 16

# CUSTOMER PORTAL FLOW

Purpose

Allow customer self-service.

---

FLOW

```text
Customer Login

↓

Dashboard

↓

View Booking

↓

View Payments

↓

Download Invoices

↓

View Timeline
```

---

CUSTOMER CANNOT

Edit Booking

Modify Payments

Access Internal Data

---

# WORKFLOW 17

# SUBSCRIPTION RENEWAL FLOW

Purpose

Maintain active SaaS account.

---

FLOW

```text
Subscription Near Expiry

↓

Reminder Sent

↓

Payment Received

↓

Renew Subscription

↓

Extend End Date
```

---

ALTERNATIVE

```text
Subscription Expired

↓

Tenant Restricted

↓

Renewal Payment

↓

Access Restored
```

---

# WORKFLOW 18

# USER CREATION FLOW

Purpose

Create tenant users.

---

FLOW

```text
Owner

↓

Create User

↓

Assign Role

↓

Send Credentials

↓

User Login
```

---

VALIDATION

Plan User Limit Not Exceeded

---

# WORKFLOW 19

# REPORT GENERATION FLOW

Purpose

Generate business reports.

---

FLOW

```text
Select Report

↓

Select Filters

↓

Fetch Data

↓

Generate Report

↓

Export PDF/Excel
```

---

REPORT TYPES

Revenue

Bookings

Payments

Inventory

Vendors

Branches

---

# WORKFLOW 20

# DAILY CRON WORKFLOW

Purpose

Scheduled operations.

---

CRON TASKS

```text
Expire Tentative Bookings

↓

Send Subscription Reminders

↓

Send Event Reminders

↓

Update Overdue Payments

↓

Generate Scheduled Reports
```

---

IMPLEMENTATION RULE

Must Use

Django Management Commands

*

cPanel Cron Jobs

---

# STATE MACHINE

# BOOKING LIFECYCLE

```text
DRAFT

↓

TENTATIVE

↓

CONFIRMED

↓

COMPLETED
```

Alternative

```text
DRAFT

↓

CANCELLED
```

Alternative

```text
CONFIRMED

↓

CANCELLED

↓

REFUNDED
```

---

# STATE MACHINE

# LEAD LIFECYCLE

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

Alternative

```text
ANY STATE

↓

LOST
```

---

# STATE MACHINE

# PAYMENT LIFECYCLE

```text
PENDING

↓

PARTIAL

↓

PAID
```

Alternative

```text
PENDING

↓

OVERDUE
```

END OF DOCUMENT 06
