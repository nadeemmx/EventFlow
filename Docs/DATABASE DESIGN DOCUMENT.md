# DOCUMENT 03

# DATABASE DESIGN DOCUMENT (DDD)

Project: EventFlow

Database Engine: MySQL 8+

ORM: Django ORM

Architecture: Single Database Multi-Tenant

Version: 1.0

---

# DATABASE PRINCIPLES

## Multi Tenant Strategy

All business tables must contain:

tenant_id

Every query must be tenant filtered.

Example:

SELECT * FROM bookings
WHERE tenant_id = current_tenant

No cross-tenant access allowed.

---

# SOFT DELETE STRATEGY

Every business table must contain:

is_deleted
deleted_at
deleted_by

Records should never be physically deleted.

---

# AUDIT STRATEGY

Every business table must contain:

created_at
created_by

updated_at
updated_by

---

# TABLE 01

TENANTS

Purpose:

SaaS customer businesses

Fields

id BIGINT PK

business_name VARCHAR(255)

owner_name VARCHAR(255)

email VARCHAR(255)

mobile VARCHAR(30)

address TEXT

gst_number VARCHAR(50)

logo VARCHAR(500)

subscription_plan_id BIGINT

subscription_status VARCHAR(30)

status VARCHAR(30)

created_at DATETIME

updated_at DATETIME

Indexes

email

mobile

status

---

# TABLE 02

USERS

Purpose

System users

Fields

id BIGINT PK

tenant_id BIGINT FK

full_name VARCHAR(255)

email VARCHAR(255)

mobile VARCHAR(30)

password_hash VARCHAR(255)

role VARCHAR(50)

is_active BOOLEAN

last_login DATETIME

created_at DATETIME

updated_at DATETIME

Indexes

tenant_id

email

role

---

# TABLE 03

USER_SESSIONS

Purpose

Track active sessions

Fields

id BIGINT PK

user_id BIGINT FK

access_token TEXT

refresh_token TEXT

device_name VARCHAR(255)

ip_address VARCHAR(255)

created_at DATETIME

expires_at DATETIME

---

# TABLE 04

VENUES

Purpose

Venue master

Fields

id BIGINT PK

tenant_id BIGINT FK

name VARCHAR(255)

venue_type VARCHAR(50)

capacity INT

description TEXT

address TEXT

latitude DECIMAL(10,7)

longitude DECIMAL(10,7)

weekday_price DECIMAL(12,2)

weekend_price DECIMAL(12,2)

peak_price DECIMAL(12,2)

status VARCHAR(30)

created_at DATETIME

updated_at DATETIME

Indexes

tenant_id

status

venue_type

---

# TABLE 05

VENUE_IMAGES

Purpose

Venue gallery

Fields

id BIGINT PK

tenant_id BIGINT FK

venue_id BIGINT FK

image_url VARCHAR(500)

display_order INT

created_at DATETIME

---

# TABLE 06

CUSTOMERS

Purpose

Customer master

Fields

id BIGINT PK

tenant_id BIGINT FK

full_name VARCHAR(255)

mobile VARCHAR(30)

email VARCHAR(255)

address TEXT

remarks TEXT

created_at DATETIME

updated_at DATETIME

Indexes

tenant_id

mobile

email

---

# TABLE 07

LEADS

Purpose

CRM inquiries

Fields

id BIGINT PK

tenant_id BIGINT FK

customer_id BIGINT FK

lead_source VARCHAR(50)

event_type VARCHAR(50)

expected_event_date DATE

expected_guest_count INT

lead_status VARCHAR(50)

assigned_to BIGINT

created_at DATETIME

updated_at DATETIME

Indexes

tenant_id

lead_status

assigned_to

---

# TABLE 08

FOLLOWUPS

Purpose

Lead follow-ups

Fields

id BIGINT PK

tenant_id BIGINT FK

lead_id BIGINT FK

followup_date DATE

notes TEXT

next_action TEXT

created_by BIGINT

created_at DATETIME

---

# TABLE 09

PACKAGES

Purpose

Venue packages

Fields

id BIGINT PK

tenant_id BIGINT FK

name VARCHAR(255)

description TEXT

base_price DECIMAL(12,2)

status VARCHAR(30)

created_at DATETIME

updated_at DATETIME

---

# TABLE 10

PACKAGE_ITEMS

Purpose

Package components

Fields

id BIGINT PK

tenant_id BIGINT FK

package_id BIGINT FK

item_name VARCHAR(255)

quantity INT

unit_price DECIMAL(12,2)

created_at DATETIME

---

# TABLE 11

BOOKINGS

Purpose

Main booking table

Fields

id BIGINT PK

tenant_id BIGINT FK

booking_number VARCHAR(50)

venue_id BIGINT FK

customer_id BIGINT FK

package_id BIGINT FK

event_type VARCHAR(50)

event_date DATE

guest_count INT

total_amount DECIMAL(12,2)

advance_amount DECIMAL(12,2)

status VARCHAR(50)

remarks TEXT

created_at DATETIME

updated_at DATETIME

Indexes

tenant_id

event_date

venue_id

status

booking_number

---

# TABLE 12

BOOKING_HISTORY

Purpose

Track status changes

Fields

id BIGINT PK

tenant_id BIGINT FK

booking_id BIGINT FK

old_status VARCHAR(50)

new_status VARCHAR(50)

remarks TEXT

changed_by BIGINT

created_at DATETIME

---

# TABLE 13

PAYMENTS

Purpose

Payment records

Fields

id BIGINT PK

tenant_id BIGINT FK

booking_id BIGINT FK

amount DECIMAL(12,2)

payment_method VARCHAR(50)

transaction_reference VARCHAR(255)

payment_date DATETIME

notes TEXT

created_at DATETIME

Indexes

tenant_id

booking_id

payment_date

---

# TABLE 14

INVOICES

Purpose

Invoice master

Fields

id BIGINT PK

tenant_id BIGINT FK

booking_id BIGINT FK

invoice_number VARCHAR(100)

invoice_date DATE

subtotal DECIMAL(12,2)

tax_amount DECIMAL(12,2)

total_amount DECIMAL(12,2)

pdf_file VARCHAR(500)

created_at DATETIME

Indexes

invoice_number

booking_id

---

# TABLE 15

VENDORS

Purpose

Vendor master

Fields

id BIGINT PK

tenant_id BIGINT FK

name VARCHAR(255)

vendor_type VARCHAR(100)

mobile VARCHAR(30)

email VARCHAR(255)

address TEXT

status VARCHAR(30)

created_at DATETIME

updated_at DATETIME

---

# TABLE 16

BOOKING_VENDORS

Purpose

Vendor assignment

Fields

id BIGINT PK

tenant_id BIGINT FK

booking_id BIGINT FK

vendor_id BIGINT FK

agreed_amount DECIMAL(12,2)

status VARCHAR(30)

created_at DATETIME

---

# TABLE 17

INVENTORY_ITEMS

Purpose

Inventory master

Fields

id BIGINT PK

tenant_id BIGINT FK

item_name VARCHAR(255)

category VARCHAR(100)

total_quantity INT

available_quantity INT

status VARCHAR(30)

created_at DATETIME

updated_at DATETIME

---

# TABLE 18

INVENTORY_ALLOCATIONS

Purpose

Inventory reservation

Fields

id BIGINT PK

tenant_id BIGINT FK

booking_id BIGINT FK

inventory_item_id BIGINT FK

allocated_quantity INT

created_at DATETIME

---

# TABLE 19

STAFF

Purpose

Employee records

Fields

id BIGINT PK

tenant_id BIGINT FK

name VARCHAR(255)

mobile VARCHAR(30)

email VARCHAR(255)

designation VARCHAR(255)

joining_date DATE

status VARCHAR(30)

created_at DATETIME

updated_at DATETIME

---

# TABLE 20

TASKS

Purpose

Task management

Fields

id BIGINT PK

tenant_id BIGINT FK

booking_id BIGINT FK

assigned_to BIGINT FK

title VARCHAR(255)

description TEXT

priority VARCHAR(30)

status VARCHAR(30)

due_date DATETIME

created_at DATETIME

updated_at DATETIME

---

# TABLE 21

EXPENSES

Purpose

Expense tracking

Fields

id BIGINT PK

tenant_id BIGINT FK

expense_category VARCHAR(255)

amount DECIMAL(12,2)

expense_date DATE

remarks TEXT

created_at DATETIME

Indexes

expense_date

tenant_id

---

# TABLE 22

NOTIFICATIONS

Purpose

System notifications

Fields

id BIGINT PK

tenant_id BIGINT FK

user_id BIGINT FK

title VARCHAR(255)

message TEXT

channel VARCHAR(30)

status VARCHAR(30)

created_at DATETIME

---

# TABLE 23

SUBSCRIPTION_PLANS

Purpose

SaaS plans

Fields

id BIGINT PK

plan_name VARCHAR(255)

monthly_price DECIMAL(12,2)

yearly_price DECIMAL(12,2)

max_users INT

max_venues INT

status VARCHAR(30)

---

# TABLE 24

SUBSCRIPTIONS

Purpose

Tenant subscriptions

Fields

id BIGINT PK

tenant_id BIGINT FK

plan_id BIGINT FK

start_date DATE

end_date DATE

billing_cycle VARCHAR(30)

status VARCHAR(30)

created_at DATETIME

---

# TABLE 25

AUDIT_LOGS

Purpose

System auditing

Fields

id BIGINT PK

tenant_id BIGINT FK

user_id BIGINT FK

module VARCHAR(255)

action VARCHAR(255)

record_id BIGINT

old_data LONGTEXT

new_data LONGTEXT

created_at DATETIME

Indexes

tenant_id

module

---

# FOREIGN KEY RELATIONSHIPS

TENANT
|
|---- USERS
|---- VENUES
|---- CUSTOMERS
|---- LEADS
|---- BOOKINGS
|---- PAYMENTS
|---- INVOICES
|---- VENDORS
|---- INVENTORY
|---- STAFF
|---- TASKS

---

# DATABASE PERFORMANCE RULES

1. Every business table must have tenant_id index.

2. Every foreign key must be indexed.

3. Avoid N+1 queries.

4. Use pagination on all list APIs.

5. Never load more than 100 records per API request.

6. Use select_related and prefetch_related in Django ORM.

---

# SHARED HOSTING COMPATIBILITY RULES

1. No PostgreSQL-specific features.

2. No Redis.

3. No Celery.

4. No WebSockets.

5. Use MySQL only.

6. Use cPanel Cron Jobs for scheduled tasks.

7. File uploads stored in public_html/uploads.

END OF DOCUMENT 03
