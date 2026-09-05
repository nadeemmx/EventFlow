import os
import multiprocessing

# Server socket
bind = os.environ.get("GUNICORN_BIND", "127.0.0.1:8000")
backlog = 2048

# Worker processes
workers = int(os.environ.get("GUNICORN_WORKERS", multiprocessing.cpu_count() * 2 + 1))
worker_class = "gthread"
threads = int(os.environ.get("GUNICORN_THREADS", "4"))
worker_connections = 1000
timeout = 120
keepalive = 5
graceful_timeout = 30

# Restart workers after this many requests to prevent memory leaks
max_requests = 2000
max_requests_jitter = 200

# Logging
accesslog = os.environ.get("GUNICORN_ACCESS_LOG", "-")
errorlog = os.environ.get("GUNICORN_ERROR_LOG", "-")
loglevel = os.environ.get("GUNICORN_LOG_LEVEL", "warning")
access_log_format = '%(h)s %(l)s %(u)s %(t)s "%(r)s" %(s)s %(b)s "%(f)s" "%(a)s" %(D)s'

# Security
limit_request_line = 8190
limit_request_fields = 100
limit_request_field_size = 8190

# Process naming
proc_name = "eventflow"

# Server mechanics
preload_app = True
daemon = False
tmp_upload_dir = None

# SSL (uncomment if not using Nginx for TLS termination)
# certfile = "/etc/ssl/certs/eventflow.crt"
# keyfile = "/etc/ssl/private/eventflow.key"
