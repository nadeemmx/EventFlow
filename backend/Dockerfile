# syntax=docker/dockerfile:1
# EventFlow backend — Django + Gunicorn production image.
#
# Multi-stage: build dependencies (compiler, MariaDB client headers) stay in
# the builder; the runtime only carries the venv and shared libraries.
# Base image pinned to the same Python minor as .github/workflows/ci.yml.
# Static files are collected at build time with BUILD-ONLY dummy settings —
# no real secrets ever enter a layer (inline `VAR=... cmd` env is not stored
# in the image config).

FROM python:3.12-slim AS builder

ENV PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# mysqlclient compiles a C extension and needs the MariaDB/MySQL client
# toolchain at build time only.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        pkg-config \
        default-libmysqlclient-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
COPY requirements/ ./requirements/

RUN python -m venv /opt/venv \
    && /opt/venv/bin/pip install --upgrade pip \
    && /opt/venv/bin/pip install \
        -r requirements/base.txt \
        gunicorn==23.0.0


FROM python:3.12-slim AS runtime

# Provenance: the commit this image was built from. CI passes it as a build
# argument; the VPS verifies the pulled image carries the SHA it is
# deploying (and the deploy workflow verifies the registry digest).
ARG GIT_SHA=""
LABEL org.opencontainers.image.source="https://github.com/nadeemmx/EventFlow" \
      org.opencontainers.image.description="EventFlow backend (Django + Gunicorn)" \
      org.opencontainers.image.revision="${GIT_SHA}"

# Runtime-only shared libraries: libmariadb3 (mysqlclient), libmagic1
# (python-magic), tzdata (Django timezone handling).
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libmariadb3 \
        libmagic1 \
        tzdata \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --gid 10001 app \
    && useradd --uid 10001 --gid app --create-home --shell /usr/sbin/nologin app \
    # production.py hardcodes MEDIA_ROOT=/home/eventflow/media; the compose
    # file bind-mounts the host media directory here. The directory must
    # exist and be writable by the non-root app user before the mount.
    && mkdir -p /home/eventflow/media \
    && chown app:app /home/eventflow/media

COPY --from=builder /opt/venv /opt/venv
ENV PATH=/opt/venv/bin:$PATH \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    # Gunicorn must listen on all interfaces inside the container; the
    # compose file never publishes this port — nginx proxies to it on the
    # internal Docker network.
    GUNICORN_BIND=0.0.0.0:8000 \
    GUNICORN_WORKERS=3 \
    DJANGO_SETTINGS_MODULE=config.settings.production

WORKDIR /app
COPY --chown=app:app . .

# Collect static files into /app/staticfiles (STATIC_ROOT) at build time so
# every container of this image ships identical, content-hashed assets for
# WhiteNoise to serve. Dummy values satisfy production settings import;
# no DB, Redis or network access is needed for collectstatic.
RUN DJANGO_SECRET_KEY=build-time-dummy-secret-key-not-used-at-runtime \
    ENCRYPTION_KEY=build-time-dummy-encryption-key-not-used \
    REDIS_URL=redis://build.invalid:6379/0 \
    DJANGO_ALLOWED_HOSTS=build.invalid \
    python manage.py collectstatic --noinput \
    && if [ ! -f staticfiles/admin/css/base.css ]; then \
         echo "collectstatic did not produce admin assets"; exit 1; \
       fi

# collectstatic ran as root and imported production settings, which create
# /app/logs (LOGS_DIR.mkdir) and open the rotating django.log through the
# root-owned build user. The host logs/ tree is dockerignored, so this
# directory only ever exists as a build artifact — hand it (and anything
# collectstatic wrote) to the runtime user, or gunicorn dies at django.setup()
# with `Unable to configure handler 'file'` (EACCES on uid 10001).
# The log file itself is an empty artifact, not data: remove it so the
# published image provably contains no log file (the runtime creates its own).
RUN mkdir -p /app/logs \
    && chown -R app:app /app/logs \
    && rm -f /app/logs/*.log

# Run as the unprivileged app user (never root at runtime).
USER app

EXPOSE 8000

CMD ["gunicorn", "config.wsgi:application", "-c", "gunicorn.conf.py"]
