#!/bin/bash
# EventFlow - cPanel Cron Job Configuration
# 
# Setup instructions:
# 1. Go to cPanel -> Cron Jobs
# 2. Add each of the following entries
# 3. Update /home/user/python/eventflow-api to your actual path
#
# Environment:
# DJANGO_SETTINGS_MODULE must be set in cPanel's "Environment Variables" for the Python app
# Or uncomment the export line below

# Export Django settings (uncomment if not set in cPanel environment)
# export DJANGO_SETTINGS_MODULE=config.settings.production

# Path to Django manage.py
APP_PATH="/home/user/python/eventflow-api"
MANAGE="$APP_PATH/manage.py"
PYTHON="/home/user/python/eventflow-api/venv/bin/python"

# ──────────────────────────────────────────────
# Cron Job 1: Expire Tentative Bookings (every hour)
# ──────────────────────────────────────────────
# 0 * * * * cd $APP_PATH && $PYTHON $MANAGE expire_tentative_bookings >> $APP_PATH/logs/cron.log 2>&1

# ──────────────────────────────────────────────
# Cron Job 2: Send Subscription Reminders (daily at 9 AM)
# ──────────────────────────────────────────────
# 0 9 * * * cd $APP_PATH && $PYTHON $MANAGE send_subscription_reminders >> $APP_PATH/logs/cron.log 2>&1

# ──────────────────────────────────────────────
# Cron Job 3: Send Event Reminders (daily at 8 AM)
# ──────────────────────────────────────────────
# 0 8 * * * cd $APP_PATH && $PYTHON $MANAGE send_event_reminders >> $APP_PATH/logs/cron.log 2>&1

# ──────────────────────────────────────────────
# Cron Job 4: Update Overdue Payments (daily at 2 AM)
# ──────────────────────────────────────────────
# 0 2 * * * cd $APP_PATH && $PYTHON $MANAGE update_overdue_payments >> $APP_PATH/logs/cron.log 2>&1

# ──────────────────────────────────────────────
# Cron Job 5: Cleanup Old Logs (weekly on Sunday at 3 AM)
# ──────────────────────────────────────────────
# 0 3 * * 0 cd $APP_PATH && $PYTHON $MANAGE cleanup_old_logs >> $APP_PATH/logs/cron.log 2>&1

echo "Cron jobs configured for EventFlow"
echo "Uncomment the lines above and paste into cPanel Cron Jobs"
