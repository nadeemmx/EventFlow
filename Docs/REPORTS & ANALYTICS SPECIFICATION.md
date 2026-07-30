# DOCUMENT 09

# REPORTS & ANALYTICS SPECIFICATION

Project: EventFlow

Version: 1.0

Architecture:
Django + DRF + Next.js + Flutter

Database:
MySQL

---

# OBJECTIVE

Provide business intelligence and operational reporting for:

* Owners
* Managers
* Accountants
* Super Admin

---

# REPORT ACCESS MATRIX

Revenue Reports

OWNER
ACCOUNTANT

---

Financial Reports

OWNER
ACCOUNTANT

---

Operational Reports

OWNER
MANAGER

---

Subscription Reports

SUPER_ADMIN

---

# REPORT CATEGORIES

1. Dashboard Analytics

2. Revenue Analytics

3. Booking Analytics

4. CRM Analytics

5. Venue Analytics

6. Payment Analytics

7. Vendor Analytics

8. Inventory Analytics

9. Staff Analytics

10. Subscription Analytics

---

# REPORT 01

# DASHBOARD SUMMARY

Purpose

Quick business overview.

---

Metrics

Today's Events

Upcoming Events

Pending Payments

Active Leads

Monthly Revenue

Cancelled Bookings

Occupancy %

---

Filters

Date Range

Venue

Branch

---

Refresh

Real Time API Fetch

---

# REPORT 02

# REVENUE REPORT

Purpose

Revenue performance.

---

Metrics

Total Revenue

Advance Revenue

Final Settlements

Refunds

Net Revenue

---

Formula

```text id="5a4k1e"
Net Revenue

=

Total Payments

-

Refunds
```

---

Filters

Date Range

Venue

Branch

Event Type

---

Charts

Monthly Revenue Trend

Yearly Revenue Trend

Revenue By Venue

---

Exports

PDF

Excel

CSV

---

# REPORT 03

# PROFIT & LOSS REPORT

Purpose

Business profitability.

---

Metrics

Gross Revenue

Total Expenses

Vendor Payments

Refunds

Net Profit

---

Formula

```text id="yt6v2m"
Net Profit

=

Revenue

-

Expenses

-
Vendor Payments

-
Refunds
```

---

Charts

Monthly Profit Trend

Expense Breakdown

---

# REPORT 04

# BOOKING REPORT

Purpose

Booking analysis.

---

Metrics

Total Bookings

Confirmed Bookings

Cancelled Bookings

Completed Bookings

Average Booking Value

---

Formula

```text id="0kr6al"
Average Booking Value

=

Total Booking Revenue

/

Total Bookings
```

---

Filters

Date Range

Venue

Event Type

Status

---

Charts

Booking Trend

Booking Status Distribution

---

# REPORT 05

# OCCUPANCY REPORT

Purpose

Venue utilization.

---

Metrics

Available Days

Booked Days

Occupancy %

---

Formula

```text id="kq3t0r"
Occupancy %

=

Booked Days

/

Available Days

×100
```

---

Charts

Venue Occupancy Comparison

Monthly Occupancy Trend

---

# REPORT 06

# EVENT TYPE REPORT

Purpose

Identify most profitable event types.

---

Metrics

Wedding Count

Reception Count

Engagement Count

Corporate Count

Other Count

---

Revenue Per Event Type

---

Charts

Pie Chart

Bar Chart

---

# REPORT 07

# LEAD CONVERSION REPORT

Purpose

CRM effectiveness.

---

Metrics

Total Leads

Converted Leads

Lost Leads

Conversion Rate

---

Formula

```text id="6fshw1"
Conversion Rate

=

Converted Leads

/

Total Leads

×100
```

---

Filters

Lead Source

Date Range

Assigned User

---

Charts

Conversion Funnel

Source Performance

---

# REPORT 08

# LEAD SOURCE ANALYTICS

Purpose

Marketing performance.

---

Lead Sources

Google

Website

Facebook

Instagram

WhatsApp

Referral

Walk-In

---

Metrics

Lead Count

Conversion Count

Revenue Generated

---

Formula

```text id="fpkj9x"
Source ROI

=

Revenue Generated

/

Lead Count
```

---

Charts

Lead Source Comparison

Revenue By Source

---

# REPORT 09

# CUSTOMER ANALYTICS

Purpose

Customer insights.

---

Metrics

Total Customers

Repeat Customers

New Customers

Average Revenue Per Customer

---

Formula

```text id="tr5pnl"
Average Revenue Per Customer

=

Revenue

/

Customers
```

---

Charts

Customer Growth

Repeat Customer Trend

---

# REPORT 10

# PAYMENT REPORT

Purpose

Track collections.

---

Metrics

Total Collected

Pending Amount

Overdue Amount

Refund Amount

---

Filters

Date Range

Payment Method

Venue

---

Charts

Collection Trend

Payment Method Distribution

---

# REPORT 11

# OUTSTANDING DUES REPORT

Purpose

Track pending collections.

---

Metrics

Customer Name

Booking Number

Outstanding Amount

Due Date

Days Overdue

---

Sorting

Highest Due First

---

Exports

PDF

Excel

---

# REPORT 12

# REFUND REPORT

Purpose

Track refunds.

---

Metrics

Total Refunds

Refund Count

Refund Reasons

Refund Trend

---

Charts

Monthly Refund Trend

---

# REPORT 13

# VENDOR PERFORMANCE REPORT

Purpose

Vendor evaluation.

---

Metrics

Vendor Assignments

Vendor Revenue

Vendor Completion Rate

Vendor Rating

---

Formula

```text id="utp2xa"
Completion Rate

=

Completed Assignments

/

Assigned Jobs

×100
```

---

Charts

Top Vendors

Vendor Revenue Ranking

---

# REPORT 14

# INVENTORY UTILIZATION REPORT

Purpose

Track inventory usage.

---

Metrics

Allocated Quantity

Available Quantity

Utilization %

---

Formula

```text id="lq7sdr"
Utilization %

=

Allocated Quantity

/

Total Quantity

×100
```

---

Charts

Inventory Category Usage

---

# REPORT 15

# DAMAGE REPORT

Purpose

Track damaged assets.

---

Metrics

Damaged Quantity

Repair Cost

Replacement Cost

---

Filters

Date Range

Category

---

# REPORT 16

# STAFF PERFORMANCE REPORT

Purpose

Operational performance.

---

Metrics

Assigned Tasks

Completed Tasks

Overdue Tasks

Completion Rate

---

Formula

```text id="3nsmc0"
Completion Rate

=

Completed Tasks

/

Assigned Tasks

×100
```

---

Charts

Top Performers

Task Completion Trend

---

# REPORT 17

# TASK ANALYTICS

Purpose

Task management effectiveness.

---

Metrics

Open Tasks

In Progress

Completed

Cancelled

Overdue

---

Charts

Task Status Distribution

---

# REPORT 18

# BRANCH PERFORMANCE REPORT

Purpose

Multi-branch comparison.

---

Metrics

Bookings

Revenue

Profit

Occupancy

Customers

---

Charts

Branch Comparison

Revenue Ranking

---

# REPORT 19

# SUBSCRIPTION REPORT

Purpose

SaaS business monitoring.

Role

SUPER_ADMIN ONLY

---

Metrics

Active Tenants

Expired Tenants

Trial Tenants

MRR

ARR

---

Formula

```text id="mpbshf"
MRR

=

Monthly Recurring Revenue
```

---

Formula

```text id="w6l9e7"
ARR

=

MRR × 12
```

---

Charts

Tenant Growth

Subscription Revenue Trend

---

# REPORT 20

# AUDIT REPORT

Purpose

Security monitoring.

---

Metrics

User Actions

Login History

Booking Changes

Payment Changes

Role Changes

---

Filters

User

Date Range

Module

---

# EXPORT ENGINE

Supported Formats

PDF

Excel (XLSX)

CSV

---

Export Rules

Apply Current Filters

Include Generated Date

Include Tenant Name

Include User Name

---

# PDF STANDARDS

Header

Company Logo

Company Name

Report Name

Date Range

---

Footer

Page Number

Generated By

Generated At

---

# EXCEL STANDARDS

Worksheet Name

Report Name

---

Frozen Header Row

Enabled

---

Auto Column Width

Enabled

---

# CHART STANDARDS

Supported Types

Line Chart

Bar Chart

Pie Chart

Area Chart

---

Libraries

Next.js

Recharts

---

Flutter

fl_chart

---

# REPORT PERFORMANCE RULES

1. Pagination Mandatory

2. Export Jobs Must Be Optimized

3. Maximum Export Range

5 Years

4. No N+1 Queries

5. Use Database Aggregations

6. Reports Must Respect Tenant Isolation

---

# SHARED HOSTING RULES

No Background Queue Dependency

No Redis

No Celery

Large Exports Processed Through:

Django Management Commands

*

cPanel Cron

END OF DOCUMENT 09
