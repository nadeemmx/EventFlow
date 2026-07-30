# PROJECT REQUIREMENTS DOCUMENT (PRD)

## Project Name

EventFlow

## Product Type

Multi-Tenant SaaS Platform for Marriage Lawns, Banquet Halls, Wedding Venues and Event Centers.

---

# Vision

EventFlow will serve as a complete Venue Business Management Platform enabling venue owners to manage bookings, customers, payments, vendors, staff, inventory and reporting from a centralized dashboard.

The system must eliminate manual registers, spreadsheets and fragmented management processes.

The platform is designed specifically for Indian Marriage Lawn and Banquet Hall businesses.

---

# Primary Objectives

1. Prevent double bookings.
2. Centralize customer records.
3. Track payments and dues.
4. Manage venue resources.
5. Manage staff and vendors.
6. Generate reports and invoices.
7. Support multiple branches.
8. Support SaaS subscription model.
9. Work efficiently on Shared Hosting infrastructure.

---

# Target Audience

## Primary Users

### Venue Owner

Business owner operating one or more marriage lawns.

### Venue Manager

Operational manager responsible for bookings and customer coordination.

### Staff Member

Operational employees responsible for event execution.

### Accountant

Handles payments, expenses and invoicing.

### Customer

Bride/Groom family or event organizer.

### Super Admin

Platform owner managing SaaS subscriptions and tenants.

---

# Industry Scope

Supported Businesses:

* Marriage Lawns
* Banquet Halls
* Event Grounds
* Convention Centers
* Party Plots
* Wedding Resorts
* Community Halls

---

# Core Business Problems

Current Market Problems:

* Paper registers
* Double bookings
* Missing payments
* Lost customer records
* Vendor mismanagement
* No reporting
* No branch control
* Manual invoice generation

EventFlow must solve all above problems.

---

# Product Modules

## Module 1

Authentication & Access Management

Functions:

* Login
* Logout
* Password Reset
* Role Based Access Control
* Session Management

---

## Module 2

Tenant Management

Functions:

* Tenant Creation
* Tenant Configuration
* Subscription Tracking
* Tenant Isolation

---

## Module 3

Venue Management

Functions:

* Create Venue
* Edit Venue
* Venue Status
* Capacity Management
* Pricing Management
* Amenities Management

---

## Module 4

Booking Management

Functions:

* Create Booking
* Update Booking
* Cancel Booking
* Confirm Booking
* Booking Status Tracking
* Booking Calendar

---

## Module 5

Customer CRM

Functions:

* Lead Creation
* Customer Profile
* Interaction History
* Follow-up Tracking
* Conversion Tracking

---

## Module 6

Payment Management

Functions:

* Advance Collection
* Due Tracking
* Payment History
* Payment Receipts

---

## Module 7

Invoice Management

Functions:

* Quotation Generation
* Invoice Generation
* Receipt Generation
* PDF Export

---

## Module 8

Vendor Management

Functions:

* Vendor Database
* Vendor Assignment
* Vendor Payments
* Vendor Performance History

---

## Module 9

Inventory Management

Functions:

* Inventory Tracking
* Stock Allocation
* Stock Availability
* Damage Reporting

---

## Module 10

Staff Management

Functions:

* Employee Records
* Attendance
* Task Assignment
* Role Allocation

---

## Module 11

Task Management

Functions:

* Event Checklist
* Task Assignment
* Progress Tracking

---

## Module 12

Reports & Analytics

Functions:

* Revenue Reports
* Booking Reports
* Payment Reports
* Occupancy Reports
* Branch Reports

---

## Module 13

Subscription Management

Functions:

* Plan Assignment
* Billing History
* Renewal Tracking
* Expiry Notifications

---

# Non Functional Requirements

## Performance

Page Load:

< 3 Seconds

API Response:

< 500ms Average

---

## Security

* JWT Authentication
* Password Hashing
* CSRF Protection
* XSS Protection
* SQL Injection Protection

---

## Scalability

Target:

1000+ Tenants

50,000+ Bookings

Single Database Architecture

---

## Availability

99% Uptime Target

Shared Hosting Compatible

---

# Supported Platforms

Web Panel

* Next.js Frontend

Backend

* Django REST Framework

Database

* MySQL

Mobile

* Flutter BLoC

Hosting

* Shared Hosting cPanel

---

# Excluded Features

The following are intentionally excluded:

* AI Chatbot
* AI Assistant
* Voice Assistant
* Dynamic AI Pricing
* Machine Learning Features
* Real-time Socket Architecture
* Redis Based Features

---

# Success Metrics

* Double Booking Rate = 0%
* Customer Record Loss = 0%
* Payment Tracking Accuracy = 100%
* Tenant Data Leakage = 0%
* Average Daily Active Venue Users Growth
* Monthly Subscription Revenue Growth

END OF DOCUMENT 01
