# EventFlow Deployment Guide (cPanel Shared Hosting)

## Architecture

```
yourdomain.com          → Next.js static export (public_html/)
api.yourdomain.com      → Django DRF API (Passenger WSGI)
media.yourdomain.com    → Media files (public_html/media/)
```

## Prerequisites

- cPanel with Python App support (Passenger WSGI)
- MySQL 8+ (via phpMyAdmin)
- Node.js 18+ (for building frontend locally)
- Python 3.10+ (via cPanel Setup Python App)

## Step 1: Database Setup

1. Open phpMyAdmin in cPanel
2. Create a new database: `eventflow`
3. Create a database user and grant all privileges
4. Note the database name, user, password, and host

## Step 2: Backend Deployment

### 2.1 Upload Backend Files

1. In cPanel, go to "Setup Python App"
2. Create a new Python app:
   - Python version: 3.10+
   - Application root: `/home/user/python/eventflow-api`
   - Application URL: `api.yourdomain.com`
   - Application startup file: `passenger_wsgi.py`
3. Upload all files from `backend/` to the application root
4. In "Setup Python App", click "Install requirements" (uses `requirements.txt`)

### 2.2 Environment Variables

In cPanel's "Setup Python App" → "Environment Variables", add:

| Variable | Value |
|----------|-------|
| `DJANGO_SETTINGS_MODULE` | `config.settings.production` |
| `DJANGO_SECRET_KEY` | (generate a random 50-char key) |
| `DJANGO_ALLOWED_HOSTS` | `localhost,.yourdomain.com,api.yourdomain.com` |
| `DB_NAME` | `eventflow` |
| `DB_USER` | (your database user) |
| `DB_PASSWORD` | (your database password) |
| `DB_HOST` | `127.0.0.1` |
| `DB_PORT` | `3306` |
| `CORS_ALLOWED_ORIGINS` | `https://app.yourdomain.com` |
| `DJANGO_DEBUG` | `False` |

### 2.3 Run Migrations

In "Setup Python App", click "Run Django Migrations"
OR run via SSH if available:
```
cd ~/python/eventflow-api && python manage.py migrate --settings=config.settings.production
```

### 2.4 Collect Static Files

```
python manage.py collectstatic --noinput --settings=config.settings.production
```

### 2.5 Create Super Admin

```
python manage.py seed_demo_data --settings=config.settings.production
```

## Step 3: Frontend Deployment

### 3.1 Build Static Export

On your local machine:
```bash
cd frontend
npm install
npm run build
```

This generates the `out/` directory with static files.

### 3.2 Upload to cPanel

1. Upload all files from `out/` to `public_html/`
2. Upload `.htaccess` from the project root to `public_html/`

## Step 4: Media Files

1. Create directory: `public_html/media/`
2. Create subdirectories: `venues/`, `customers/`, `invoices/`, `receipts/`, `pdf/`, `profiles/`
3. Add `.htaccess` with:
```
Options -Indexes
```

## Step 5: Cron Jobs

In cPanel → "Cron Jobs", add:

```
# Every hour: Expire tentative bookings
0 * * * * cd /home/user/python/eventflow-api && /home/user/python/eventflow-api/venv/bin/python manage.py expire_tentative_bookings

# Daily at 9 AM: Subscription reminders
0 9 * * * cd /home/user/python/eventflow-api && /home/user/python/eventflow-api/venv/bin/python manage.py send_subscription_reminders

# Daily at 8 AM: Event reminders
0 8 * * * cd /home/user/python/eventflow-api && /home/user/python/eventflow-api/venv/bin/python manage.py send_event_reminders

# Daily at 2 AM: Update overdue payments
0 2 * * * cd /home/user/python/eventflow-api && /home/user/python/eventflow-api/venv/bin/python manage.py update_overdue_payments
```

## Step 6: Verify Deployment

- Frontend: https://app.yourdomain.com
- API: https://api.yourdomain.com/api/v1/
- Admin: https://api.yourdomain.com/admin/
- Login: `owner@eventflow.com` / `Password123`

## Troubleshooting

### 500 Internal Server Error
- Check `logs/django.log` in the backend directory
- Verify Passenger WSGI configuration in cPanel
- Ensure all environment variables are set

### Media Files Not Loading
- Verify `MEDIA_URL` and `MEDIA_ROOT` in settings
- Check directory permissions (755 for directories, 644 for files)

### Database Connection Error
- Verify MySQL credentials in environment variables
- Ensure database user has proper permissions
- Check MySQL host (use `127.0.0.1` for local MySQL)
