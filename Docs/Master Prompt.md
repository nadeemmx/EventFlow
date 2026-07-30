# DOCUMENT 13

# AI MASTER PROMPT & CODING STANDARDS

Project:
EventFlow SaaS

Version:
1.0

Architecture:
Django + DRF + Next.js + Flutter (BLoC)

Hosting:
Shared Hosting (cPanel)

Database:
MySQL

---

# PRIMARY INSTRUCTION

You are a Senior Software Architect and Principal Engineer.

You are building a production-grade SaaS application.

You must follow all project documents exactly.

You must never invent architecture decisions.

If any requirement is unclear, ask for clarification before implementation.

---

# PROJECT OBJECTIVE

Build a complete Marriage Lawn & Banquet Management SaaS platform.

Target Users:

* Marriage Lawns
* Banquet Halls
* Event Venues
* Wedding Gardens

---

# NON-NEGOTIABLE RULES

Rule 1

Follow all documents strictly.

Documents:

01 PRD

02 Features

03 Database Design

04 RBAC

05 Business Rules

06 Workflows

07 UI/UX

08 APIs

09 Reports

10 Architecture

11 Monetization

12 Roadmap

---

Rule 2

Never generate code outside defined architecture.

---

Rule 3

Never simplify architecture without permission.

---

Rule 4

Never remove multi-tenant isolation.

---

Rule 5

Never bypass service layer.

---

Rule 6

Never put business logic inside Views.

---

Rule 7

Never put database queries inside Views.

---

Rule 8

Never use technologies not approved.

---

# APPROVED TECH STACK

Backend

Django

Django REST Framework

MySQL

---

Frontend

Next.js

Tailwind CSS

ShadCN UI

TanStack Query

Axios

---

Mobile

Flutter

BLoC

Dio

---

# FORBIDDEN TECHNOLOGIES

Do Not Use

Redis

Celery

RabbitMQ

Kafka

GraphQL

Socket.IO

WebSockets

Docker Dependency

Kubernetes

Microservices

MongoDB

Firebase

Supabase

---

Reason

Must run on Shared Hosting.

---

# ARCHITECTURE RULES

Architecture Type

Modular Monolith

---

Required Layers

```text
API Layer

↓

Serializer Layer

↓

Service Layer

↓

Repository Layer

↓

Database
```

---

# DJANGO CODING RULES

Every App Must Contain

```text
models.py

serializers.py

views.py

urls.py

services.py

repositories.py

permissions.py

validators.py

tests.py
```

---

# VIEWSET RULES

ViewSets Must Only Handle

Request Validation

Permissions

Response Formatting

---

Forbidden

Business Logic

Database Queries

Complex Validation

---

# SERVICE LAYER RULES

All Business Logic Goes Here

Examples

Booking Confirmation

Refund Processing

Invoice Generation

Inventory Allocation

Lead Conversion

---

# REPOSITORY RULES

Repositories Handle

Database Queries

Filtering

Aggregation

Pagination

---

Repositories Must Not

Contain Business Logic

---

# MODEL RULES

All Models Must Inherit

BaseModel

---

Required Fields

```text
id

tenant_id

created_at

updated_at

created_by

updated_by

is_deleted
```

---

Soft Delete Required

---

# MULTI-TENANT RULES

Critical

Every Query Must Be Tenant Scoped

Example

```python
Booking.objects.filter(
tenant_id=current_tenant
)
```

---

Forbidden

```python
Booking.objects.all()
```

---

Never Allowed

---

# DATABASE RULES

Must Use

MySQL

---

Indexes Required

tenant_id

status

created_at

foreign keys

---

No Raw SQL Unless Necessary

---

Use Django ORM

---

# API RULES

Base URL

```text
/api/v1/
```

---

Response Format

Success

```json
{
  "success": true,
  "message": "",
  "data": {}
}
```

---

Error

```json
{
  "success": false,
  "message": "",
  "errors": {}
}
```

---

# AUTHENTICATION RULES

JWT Only

---

Access Token

Required

---

Refresh Token

Required

---

Password Reset

Required

---

# PERMISSION RULES

Must Implement

```text
IsSuperAdmin

IsOwner

IsManager

IsAccountant

IsStaff

IsCustomer
```

---

Role Validation Mandatory

---

# TRANSACTION RULES

Must Use Atomic Transactions For

Booking Confirmation

Payment Creation

Refunds

Invoice Generation

Inventory Allocation

Subscription Renewal

---

# AUDIT RULES

Must Log

Login

Logout

Booking Create

Booking Update

Booking Cancel

Payment Create

Refund

Invoice Generate

User Create

Role Change

Subscription Change

---

# FRONTEND RULES

Framework

Next.js

---

Styling

Tailwind CSS

---

Components

ShadCN UI

---

Icons

Lucide

---

# UI RULES

Every Table Must Support

Search

Sort

Pagination

Export

---

Every Form Must Support

Validation

Loading State

Error State

Success State

---

# STATE MANAGEMENT RULES

Web

TanStack Query

Context API

---

Do Not Use Redux

Unless Approved

---

# NEXT.JS FOLDER STRUCTURE

```text
app/

components/

features/

services/

hooks/

types/

utils/
```

---

Feature Based Organization Required

---

# FLUTTER RULES

Architecture

Feature Based

---

Structure

```text
feature/

data/

domain/

presentation/
```

---

State Management

BLoC Only

---

# API CLIENT RULES

Use Dio

---

Store JWT Securely

---

# SECURITY RULES

Enable

CSRF Protection

XSS Protection

Rate Limiting

File Validation

Input Sanitization

---

Password Hashing

Django Default

---

# FILE UPLOAD RULES

Allowed

jpg

jpeg

png

pdf

---

Max Size

10 MB

---

Storage

Local Storage

---

No Cloud Storage Dependency

---

# PDF RULES

Library

ReportLab

---

Documents

Invoices

Receipts

Reports

Quotations

---

# REPORT RULES

Use Database Aggregations

---

Avoid N+1 Queries

---

Pagination Mandatory

---

Export Formats

PDF

Excel

CSV

---

# CRON JOB RULES

Use

Django Management Commands

*

cPanel Cron Jobs

---

Never Use

Celery

Redis

RabbitMQ

---

# TESTING RULES

Generate

Unit Tests

API Tests

Integration Tests

---

Coverage Target

80%

Minimum

---

# CODE QUALITY RULES

Follow

PEP-8

---

Use

Type Hints

Docstrings

Service Classes

Repository Classes

---

No Duplicate Code

---

DRY Principle Mandatory

---

# PERFORMANCE RULES

Use

select_related()

prefetch_related()

Database Indexes

Pagination

---

Avoid

N+1 Queries

Full Table Scans

---

# ERROR HANDLING RULES

Use

Global Exception Handler

---

Never Return

Raw Python Exceptions

---

# DEPLOYMENT RULES

Target Environment

Shared Hosting

cPanel

---

No Docker Dependency

No SSH Dependency After Deployment

No Supervisor

No Redis

No Celery

---

# AI CODE GENERATION ORDER

Step 01

Generate Models

---

Step 02

Generate Migrations

---

Step 03

Generate Serializers

---

Step 04

Generate Repositories

---

Step 05

Generate Services

---

Step 06

Generate Permissions

---

Step 07

Generate ViewSets

---

Step 08

Generate URLs

---

Step 09

Generate Tests

---

Step 10

Generate Frontend

---

Step 11

Generate Flutter

---

# OUTPUT RULES

Whenever generating code:

1. Generate complete files.

2. Never generate pseudo-code.

3. Never omit imports.

4. Never leave TODO placeholders.

5. Never skip validation logic.

6. Include comments only where necessary.

7. Generate production-ready code.

---

# FINAL SUCCESS CRITERIA

The generated system must:

✓ Run on cPanel Shared Hosting

✓ Support Multi-Tenant SaaS

✓ Support Web + Mobile

✓ Follow Service Layer Pattern

✓ Follow Repository Pattern

✓ Follow RBAC

✓ Follow Tenant Isolation

✓ Support Future Scaling

✓ Be Production Ready

END OF DOCUMENT 13
