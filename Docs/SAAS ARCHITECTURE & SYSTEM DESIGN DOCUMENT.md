# DOCUMENT 10

# SAAS ARCHITECTURE & SYSTEM DESIGN DOCUMENT

Project: EventFlow

Version: 1.0

Architecture Style:
Modular Monolith

Backend:
Django + DRF

Frontend:
Next.js

Mobile:
Flutter (BLoC)

Database:
MySQL

Hosting:
Shared Hosting (cPanel)

---

# SYSTEM ARCHITECTURE

Architecture Type

```text id="0v3j7m"
Next.js Web

↓

DRF API Layer

↓

Service Layer

↓

Repository Layer

↓

MySQL Database
```

---

Mobile Flow

```text id="q2ps5r"
Flutter

↓

REST APIs

↓

DRF

↓

MySQL
```

---

# WHY MODULAR MONOLITH

Reasons

1. Shared Hosting Friendly

2. Easier Deployment

3. Lower Cost

4. Faster Development

5. No DevOps Complexity

---

# PROJECT STRUCTURE

Backend

```text id="z4zq1j"
backend/

├── config/
├── apps/
├── core/
├── services/
├── repositories/
├── permissions/
├── middleware/
├── utils/
├── reports/
├── management/
├── media/
├── static/
└── requirements.txt
```

---

# DJANGO APPS

```text id="2b6bje"
apps/

authentication/

tenants/

users/

venues/

customers/

leads/

bookings/

payments/

invoices/

packages/

vendors/

inventory/

staff/

tasks/

reports/

subscriptions/

notifications/

audit_logs/
```

---

# CORE MODULE

Purpose

Shared utilities.

---

Contains

```text id="6kp16f"
base_models.py

constants.py

validators.py

exceptions.py

responses.py

pagination.py
```

---

# BASE MODEL STRATEGY

Every business model inherits:

BaseModel

Fields

```text id="4b90vb"
id

tenant_id

created_at

updated_at

created_by

updated_by

is_deleted
```

---

# API STRUCTURE

```text id="v21ulj"
/api/v1/
```

Versioning Required

---

# LAYERED ARCHITECTURE

Controller Layer

↓

Serializer Layer

↓

Service Layer

↓

Repository Layer

↓

Database

---

# VIEWSET RULES

ViewSets only handle:

* Request Parsing
* Permission Checks
* Response Formatting

Business logic prohibited.

---

# SERVICE LAYER

Purpose

Business Rules

---

Example

```text id="a0q5r2"
BookingService

PaymentService

InvoiceService

VendorService

InventoryService
```

---

Responsibilities

Validation

Workflow Execution

State Changes

Transactions

---

# REPOSITORY LAYER

Purpose

Database Access

---

Responsibilities

Queries

Filtering

Aggregations

Pagination

---

No Business Logic Allowed

---

# TENANT ISOLATION

Strategy

Single Database

Shared Schema

---

Implementation

Tenant Middleware

---

Flow

```text id="vvz29m"
Request

↓

Authenticated User

↓

Resolve Tenant

↓

Attach Tenant

↓

Apply Query Filters
```

---

Rule

Every query filtered by tenant_id.

Mandatory.

---

# AUTHENTICATION ARCHITECTURE

Method

JWT

---

Components

Access Token

Refresh Token

Token Rotation

---

Storage

Next.js

HttpOnly Cookie Preferred

---

Flutter

Secure Storage

---

# PERMISSION ARCHITECTURE

Custom DRF Permissions

---

Classes

```text id="pohx4d"
IsSuperAdmin

IsOwner

IsManager

IsAccountant

IsStaff

IsCustomer
```

---

# FILE STORAGE ARCHITECTURE

Storage Type

Local Storage

---

Shared Hosting Compatible

---

Structure

```text id="b6nwmx"
/media/

venues/

customers/

invoices/

receipts/

profiles/
```

---

Rules

Generate Unique Filenames

Prevent File Overwrite

---

# PDF GENERATION

Library

ReportLab

---

Documents

Invoices

Receipts

Reports

Quotations

---

Storage

/media/pdf/

---

# EMAIL ARCHITECTURE

Method

SMTP

---

Configurable Per Tenant

Optional

---

# WHATSAPP INTEGRATION

Architecture

Provider Based

---

Examples

WhatsApp Business API

Third Party Providers

---

Integration Layer

```text id="3x45u6"
NotificationService
```

---

# NOTIFICATION ARCHITECTURE

Channels

Email

WhatsApp

In-App

---

Implementation

NotificationService

---

No Queue Dependency

---

# SEARCH ARCHITECTURE

Database Search

LIKE Queries

---

Future Upgrade

Full Text Search

---

Not Required Initially

---

# REPORTING ARCHITECTURE

Layer

```text id="08d5r2"
ReportService

↓

Repository

↓

Database
```

---

Export Formats

PDF

Excel

CSV

---

# AUDIT ARCHITECTURE

Every Critical Action Creates

AuditLog

---

Logged Events

Login

Logout

Booking Create

Booking Update

Booking Cancel

Payment Entry

Invoice Generation

User Creation

Role Change

---

# ERROR HANDLING

Global Exception Handler

---

Response Format

```json id="9kgqql"
{
  "success": false,
  "message": "",
  "errors": {}
}
```

---

# TRANSACTION STRATEGY

Use Django Transactions

For

Booking Confirmation

Payments

Refunds

Invoice Generation

Inventory Allocation

---

# CRON JOB ARCHITECTURE

Implementation

Django Management Commands

---

Examples

```text id="k0r27f"
expire_tentative_bookings

send_subscription_reminders

send_event_reminders

cleanup_logs
```

---

Execution

cPanel Cron Jobs

---

# CACHE STRATEGY

No Redis

---

Use

Database Queries

Application Memory Only

---

Future Upgrade

Optional

---

# NEXT.JS ARCHITECTURE

Folder Structure

```text id="ykj6hc"
frontend/

app/

components/

features/

hooks/

services/

types/

utils/

public/
```

---

# FEATURE MODULES

```text id="9qfll2"
dashboard

crm

bookings

venues

payments

vendors

inventory

reports

settings
```

---

# API CLIENT

Library

Axios

---

Centralized Client

```text id="4m8jya"
services/api.ts
```

---

# STATE MANAGEMENT

Web

TanStack Query

Context API

---

Global State

User

Permissions

Tenant

Theme

---

# FLUTTER ARCHITECTURE

Folder Structure

```text id="x1dcjv"
lib/

core/

features/

services/

blocs/

widgets/

routes/
```

---

# FEATURE STRUCTURE

```text id="vuzbfi"
feature/

data/

domain/

presentation/
```

---

# BLOC STRATEGY

One Bloc Per Module

---

Examples

```text id="kwqpxg"
BookingBloc

LeadBloc

PaymentBloc

VendorBloc
```

---

# API COMMUNICATION

Package

Dio

---

Authentication

JWT

---

Storage

flutter_secure_storage

---

# SECURITY ARCHITECTURE

Password Hashing

Django Default Hasher

---

CSRF

Enabled

---

XSS Protection

Enabled

---

SQL Injection Protection

ORM Only

---

Rate Limiting

Enabled

Login APIs

---

# DATABASE STRATEGY

Engine

MySQL

---

Connection Pooling

Hosting Provider Managed

---

Indexes

tenant_id

status

created_at

foreign keys

---

# DEPLOYMENT ARCHITECTURE

Backend

```text id="u7jyr7"
public_html/api/
```

---

Frontend

```text id="9f9j0k"
public_html/
```

---

Media

```text id="25xb7s"
public_html/media/
```

---

Database

MySQL

---

# CPANEL DEPLOYMENT RULES

No Docker

No Kubernetes

No Supervisor

No Redis

No Celery

No Nginx Dependency

No SSH Dependency After Deployment

---

# SCALABILITY TARGETS

Tenants

1000+

---

Bookings

50000+

---

Users

10000+

---

API Response

< 500ms Average

---

# MAINTAINABILITY RULES

1. Business Logic Only In Services

2. Database Logic Only In Repositories

3. No Fat Views

4. No Duplicate Queries

5. No Direct Database Access In Views

6. All Modules Independent

7. All Critical Operations Audited

---

# FUTURE UPGRADE PATH

Shared Hosting

↓

Managed VPS

↓

Load Balancer

↓

Microservices

---

Current Version Must Not Depend On Future Infrastructure.

END OF DOCUMENT 10
