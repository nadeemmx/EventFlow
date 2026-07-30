DOCUMENT 11
SUBSCRIPTION PLANS & SAAS MONETIZATION STRATEGY

Project: EventFlow

Version: 1.0

Business Model:
B2B SaaS

Industry:
Marriage Lawn / Banquet / Event Venue Management

Revenue Model:
Recurring Subscription

BUSINESS OBJECTIVE

Generate predictable recurring revenue through:

Monthly Plans
Yearly Plans
Add-On Services
White Label Upgrades
SMS / WhatsApp Credits
SUBSCRIPTION ARCHITECTURE

Tenant

↓

Subscription Plan

↓

Feature Access

↓

Usage Limits

↓

Billing

PLAN TYPES
PLAN 01
STARTER

Target

Small Marriage Lawn

Single Venue Operators

Limits

Venues: 1

Users: 3

Bookings: 100/month

Customers: Unlimited

Leads: Unlimited

Inventory: Basic

Reports: Basic

Mobile App: Yes

Customer Portal: Yes

Features

CRM

Bookings

Payments

Invoices

Calendar

Basic Reports

Support

Email Support

PLAN 02
PROFESSIONAL

Target

Growing Businesses

Multiple Venues

Limits

Venues: 5

Users: 15

Bookings: Unlimited

Customers: Unlimited

Leads: Unlimited

Inventory: Advanced

Reports: Advanced

Mobile App: Yes

Customer Portal: Yes

Features

Everything In Starter

Vendor Management

Inventory Management

Task Management

Advanced Reports

WhatsApp Integration

Support

Priority Support

PLAN 03
ENTERPRISE

Target

Venue Chains

Multi-Branch Businesses

Limits

Venues: Unlimited

Users: Unlimited

Bookings: Unlimited

Branches: Unlimited

Reports: Unlimited

Features

Everything In Professional

Multi Branch Management

White Label

Custom Branding

Advanced Analytics

Dedicated Account Manager

API Access

Support

Priority Support

Phone Support

Dedicated Manager

BILLING CYCLE

Supported Billing

Monthly

Quarterly

Yearly

Recommended Discounts

Monthly

0%

Quarterly

10%

Yearly

20%

TRIAL STRATEGY

Trial Period

14 Days

Access

All Professional Features

Restrictions

No White Label

No API Access

SUBSCRIPTION STATUS

States

TRIAL

↓

ACTIVE

↓

EXPIRED

↓

SUSPENDED

↓

CANCELLED
FEATURE LIMIT SYSTEM

Architecture

Feature Based

Usage Based

Examples

Maximum Users

Maximum Venues

Maximum Branches

Maximum Storage

Maximum Monthly Bookings

Validation Flow

User Action

↓

Check Plan

↓

Check Limit

↓

Allow / Reject
USER LIMIT RULE

Example

Plan Limit

15 Users

Current Users

15

Attempt

Create User

Result

Reject

Message

User Limit Reached

VENUE LIMIT RULE

Example

Plan Limit

5 Venues

Current Venues

5

Attempt

Create Venue

Result

Reject

Message

Venue Limit Reached

STORAGE LIMITS

Starter

2 GB

Professional

10 GB

Enterprise

50 GB

Storage Includes

Venue Images

Invoices

Receipts

Documents

WHATSAPP CREDIT SYSTEM

Optional Add-On

Purchase Credits

100

500

1000

5000

Deduct On

Booking Confirmation

Invoice Sending

Payment Receipt

Reminder Messages

SMS CREDIT SYSTEM

Optional Add-On

Purchase Packs

100

500

1000

5000

Usage Tracking Required

WHITE LABEL MODULE

Enterprise Only

Custom Logo

Custom Colors

Custom Domain

Custom Login Screen

Custom Email Templates

CUSTOM DOMAIN SUPPORT

Enterprise Only

Example

clientdomain.com

↓

EventFlow System

API ACCESS

Enterprise Only

Benefits

ERP Integration

Accounting Integration

Custom Mobile Apps

ADD-ON MODULES

Module

Customer Feedback

Module

Advanced Analytics

Module

Multi Branch

Module

Extra Storage

Module

Additional Users

BILLING ENGINE

Entities

Subscription

Invoice

Payment

Renewal

Add-On

Credit Packs

SUBSCRIPTION RENEWAL FLOW
Expiry Approaching

↓

Reminder Sent

↓

Payment Received

↓

Renew

↓

New Expiry Date
EXPIRY NOTIFICATION RULES

30 Days Before

15 Days Before

7 Days Before

3 Days Before

1 Day Before

Expiry Day

EXPIRED ACCOUNT BEHAVIOR

Allowed

Profile

Billing

Renewal

Blocked

Bookings

Payments

Customers

Reports

Inventory

Staff

GRACE PERIOD

Recommended

7 Days

Flow

Expired

↓

Grace Period

↓

Restricted

↓

Suspended
SUPER ADMIN BILLING DASHBOARD

Metrics

Active Tenants

Trial Tenants

Expired Tenants

Monthly Revenue

Yearly Revenue

MRR

ARR

Renewal Rate

Churn Rate

SAAS KPIs

MRR

Monthly Recurring Revenue

ARR

Annual Recurring Revenue

Churn Rate

Cancelled Customers

/

Total Customers

×100

Renewal Rate

Renewed Customers

/

Expiring Customers

×100

LTV

Lifetime Value

CAC

Customer Acquisition Cost

PAYMENT GATEWAYS

Phase 1

Manual Payments

Phase 2

Online Payments

Supported

Razorpay

Cashfree

PhonePe Payment Gateway

RECOMMENDED LAUNCH STRATEGY

Phase 1

Single Plan

Professional

Reason

Faster Development

Faster Sales

Less Complexity

Phase 2

Starter + Professional

Phase 3

Enterprise

ARCHITECTURE CORRECTION NOTE

Because project must run on Shared Hosting:

Frontend

Next.js Static Export

next build
next export

Deploy Generated Static Files

Backend

Django + DRF

Separate API Subdomain

Example

api.yourdomain.com

Flutter

Environment Config

Development API

Production API

Recommended Structure

Frontend
app.yourdomain.com

Backend API
api.yourdomain.com

Media
media.yourdomain.com

This architecture is fully compatible with cPanel shared hosting.

END OF DOCUMENT 11