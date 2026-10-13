# EventFlow — Docker Compose Production Deployment

Target: fresh Ubuntu VPS at `194.77.89.95`, no domain yet (temporary
HTTP/IP testing), GitHub Actions with a required-reviewer `production`
approval gate. This document covers the architecture, the fresh-VPS
deployment procedure, day-2 operations, and the security limits of the
HTTP-only test phase.

---

## 1. Architecture

```
                         GitHub Actions
      ┌──────────┐  push to master   ┌──────────┐  approval gate   ┌──────────┐
      │  CI      │ ────────────────► │  Deploy  │ ─(required──────►│ production│
      │ 4 jobs   │   must be green   │ workflow │   reviewer)      │ environment│
      └────┬─────┘                   └────┬─────┘                  └──────────┘
           │ docker job:                  │ SSH (host-key verified)
           │ compose config,              │ scp deploy_compose.sh + lib.sh
           │ hadolint, nginx -t,          ▼
           │ build + smoke images   VPS 194.77.89.95 (Ubuntu, root + deploy user)
                                   ┌─────────────────────────────────────────────┐
                                   │ Docker Compose project: `eventflow`         │
                                   │ /srv/baseify/eventflow/                     │
                                   │   .env (0600, secrets)  repo/  media/       │
                                   │   backups/  logs/  .current_sha             │
                                   │                                             │
   Internet                         │  ┌───────────────────────────────────────┐ │
      │  :80  (app/API)             │  │ nginx:1.26-alpine      published      │ │
      ├────────────────────────────►│  │  conf.d/eventflow.conf  80, 8080      │ │
      │  :8080 (media allowlist)    │  └──────┬──────────────────┬─────────────┘ │
      │                             │    proxy│network          │                │
      │                             │  ┌──────▼──────┐   ┌──────▼───────┐        │
      │                             │  │ backend     │   │ frontend     │        │
      │                             │  │ gunicorn    │   │ next start   │        │
      │                             │  │ :8000       │   │ :3000        │        │
      │                             │  └──┬───────┬──┘   └──────────────┘        │
      │                             │     │       │ internal network (internal:  │
      │                             │     │       │ true → no ports, no egress)  │
      │                             │  ┌──▼───────▼──────────────┐               │
      │                             │  │ mariadb:11.4  redis:7.4 │               │
      │                             │  │ volume eventflow_db_data │               │
      │                             │  └─────────────────────────┘               │
      │                             │  media: bind /srv/baseify/eventflow/media  │
      │                             │      (backend rw, nginx ro, uid 10001)     │
                                   └─────────────────────────────────────────────┘
```

### Design rules

- **One Compose project per SaaS product** (`name: eventflow`). Future
  products get their own project, networks, env file and volumes — see
  `docs/SAAS_ONBOARDING.md`. No mega-compose file.
- **Single published surface**: only `nginx` publishes ports (80 app/API,
  8080 media). MariaDB and Redis are unreachable from outside; they live on
  an `internal: true` network with no egress.
- **Secrets never enter git or image layers.** The real env file lives at
  `/srv/baseify/eventflow/.env` (0600) and is passed with `--env-file`.
  Build-time settings in the Dockerfile use inline dummy values only.
- **Migrations are explicit**: `deploy_compose.sh` runs
  `manage.py migrate --noinput` and then `migrate --check` as one-off
  containers before the app stack starts. No migration-on-boot entrypoints.
- **Images are tagged with the commit SHA** (`eventflow-backend:<sha>`,
  `eventflow-frontend:<sha>`), so rollback restarts a previous tag without
  rebuilding.
- **Health gates everywhere**: per-container Docker healthchecks
  (MariaDB/Redis/backend/frontend/nginx), a post-deploy `verify.sh`, and a
  final external live test from the GitHub runner. `deploy_compose.sh`
  auto-rolls back to the previous known-good tag if its health gate fails.

### Image / base versions (pinned)

| Component | Image | Why |
|---|---|---|
| backend | `python:3.12-slim` multi-stage | matches CI Python 3.12; build toolchain stays in builder |
| frontend | `node:20-alpine` multi-stage | matches CI Node 20; `next build` + `next start` (not static export) |
| database | `mariadb:11.4` (LTS) | current MySQL-compatible line |
| cache | `redis:7.4-alpine` | required by `config.settings.production` (REDIS_URL) |
| proxy | `nginx:1.26-alpine` (stable) | same routing/rate-limits/media allowlist as the legacy host config |

Non-root everywhere: backend runs as uid `10001` (`app`), frontend as the
image's `node` user, MariaDB/Redis/nginx with their image defaults.

---

## 2. Fresh-VPS deployment guide (step by step)

> Prerequisites: a fresh Ubuntu server you can log into as **root**, the
> public IP `194.77.89.95`, and this repository pushed to `master` on
> GitHub (repository is public — the VPS clones it without credentials).

1. **Bootstrap the host** (idempotent — safe to re-run):

   ```bash
   # as root on the VPS
   git clone https://github.com/nadeemmx/EventFlow.git /root/bootstrap-src
   bash /root/bootstrap-src/deploy/bootstrap/bootstrap_vps.sh \
       --authorized-key "ssh-ed25519 AAAA… your@laptop"
   ```

   What it does: installs Docker Engine + Compose plugin (official repo),
   creates the `deploy` user (docker group only — **no sudoers rules**),
   installs your SSH key for `deploy` **and root** (additive; nothing is
   removed), stages + enables UFW (SSH/80/443/8080), creates
   `/srv/baseify/eventflow/{repo,media,backups,logs}`, **generates
   `.env` secrets on the server** (0600, never printed), enables Docker
   log rotation (10m × 3), adds 2G swap, clones the repo and installs the
   cron jobs.

2. **Verify SSH as the deploy user before anything else** (root stays
   reachable via key throughout):

   ```bash
   ssh -p 22 deploy@194.77.89.95 'docker version'
   ```

3. **Optionally harden SSH** (only after step 2 succeeds):

   ```bash
   bash /root/bootstrap-src/deploy/bootstrap/bootstrap_vps.sh --harden-ssh
   ```

   This disables password authentication via
   `/etc/ssh/sshd_config.d/99-baseify.conf` after confirming both
   `authorized_keys` files are non-empty. Run it from a session you
   will not lose.

4. **GitHub configuration** (already in place; do not weaken):

   - Secrets: `VPS_HOST` (= `194.77.89.95`), `VPS_USER` (= the deploy
     user, default `deploy`), `VPS_SSH_KEY` (unencrypted private key
     matching step 1), optional `VPS_PORT`, and ideally
     `VPS_SSH_FINGERPRINT`/`VPS_SSH_KNOWN_HOSTS` to pin the host key.
   - Variable: `NEXT_PUBLIC_API_URL=http://194.77.89.95/api/v1`
   - Environment `production` keeps its required reviewer
     (`Settings → Environments → production`).

5. **Trigger the first deployment**: merge to `master` (CI must be green)
   → the `Deploy` workflow starts → it **waits for approval** in the
   `production` environment → reviewer approves → `deploy_compose.sh`
   builds images tagged with the SHA, migrates, switches the stack and
   health-gates; `verify.sh` re-checks on the VPS; the runner then tests
   `http://194.77.89.95` externally (frontend 200, `/health/` 200,
   `/ready/` 200, API 401).

6. **Post-deploy sanity on the VPS**:

   ```bash
   docker compose --env-file /srv/baseify/eventflow/.env \
     -f /srv/baseify/eventflow/repo/deploy/docker/eventflow/docker-compose.yml ps
   ```

---

## 3. Day-2 operations

| Task | How |
|---|---|
| Deploy | Merge to `master` → approve the `production` gate (never from PRs) |
| Verify | `deploy/docker/scripts/verify.sh` (deploy user, on VPS) |
| Rollback | `deploy/docker/scripts/rollback.sh` (previous SHA) or `rollback.sh <sha>` |
| Backup | `deploy/docker/scripts/backup.sh` (cron daily 02:00, 14-day retention) → `/srv/baseify/eventflow/backups/` |
| Restore | `restore.sh db <dump.sql.gz> --yes` or `restore.sh media <tar> --yes` (takes a fresh pre-restore backup first) |
| Logs | `docker compose --env-file … logs -f backend` (json-file, 10m×3 rotated) |
| Cron jobs | `crontab -l -u deploy` — management commands + backup (marker `eventflow-docker-cron-v1`) |
| Health | Container healthchecks + `/health/` `/ready/` `/live/` endpoints |

First deploy failure: there is no previous tag to roll back to — the
script leaves the failed stack in place and prints the inspection
commands; fix and re-approve.

---

## 4. CI/CD pipeline

- **CI** (`ci.yml`): Backend (Django check + pytest), Frontend (tsc +
  tests + production build + inlining check), Mobile (analyze + tests),
  Deploy scripts (`bash -n`, shellcheck, actionlint, legacy nginx/systemd
  validation), **Docker** (compose `config` against `.env.example`,
  hadolint, `nginx -t` on the container config, full image builds tagged
  with the SHA, backend/frontend smoke tests). PRs run CI only.
- **Deploy** (`deploy.yml`): triggers only on a **successful CI run that
  came from a push to `master`** (or manual `workflow_dispatch`), binds to
  the `production` environment (required reviewer), uses SSH with
  host-key verification (pinned known_hosts/fingerprint → keyscan
  fallback with a pin-it notice; `StrictHostKeyChecking=yes` always),
  least-privilege `permissions: contents: read`, a concurrency lock that
  queues (never cancels) deployments, and runs: `deploy_compose.sh` →
  `verify.sh` → external live test.

Images are built **on the VPS** during the approved deploy (fresh clone,
tagged with the SHA). A GHCR publish path is deliberately not wired yet —
it would need a new image-pull credential on the VPS; see Unresolved
issues.

---

## 5. Security and HTTP limitations (Phase 6)

**No HTTPS exists.** `http://194.77.89.95` is cleartext.

Temporary, deliberately-HTTP-only settings — all of them live in the
server-side `.env` (never in git):

| Setting | HTTP test value | Value after HTTPS |
|---|---|---|
| `SESSION_COOKIE_SECURE` | `false` | `true` |
| `CSRF_COOKIE_SECURE` | `false` | `true` |
| `SECURE_HSTS_PRELOAD` | `false` | `true` |
| `DJANGO_ALLOWED_HOSTS` | `194.77.89.95,localhost,127.0.0.1` | real hostnames |
| `CSRF_TRUSTED_ORIGINS` / `CORS_ALLOWED_ORIGINS` | `http://194.77.89.95` | `https://…` |
| `NEXT_PUBLIC_API_URL` | `http://194.77.89.95/api/v1` | `https://api.<domain>/api/v1` |

Everything else in Django's production settings stays at its secure
default (no broad disabling of security settings).

**Payment callbacks (Razorpay webhooks) and any other HTTPS-dependent
integration are UNAVAILABLE until a domain + certificate exist** — the
provider will not call an `http://` endpoint. Marked in the nginx config
too (`/api/v1/payments/webhook/` is routed but unreachable by providers).

**Restore secure settings when a domain exists:**

1. Point DNS (A record) at `194.77.89.95`; add `443` already allowed by
   UFW.
2. Obtain a certificate (e.g. certbot `--webroot` or `certbot --standalone`),
   add an HTTPS `server` block + `443:443` port mapping to the nginx
   service (or terminate TLS at a front proxy).
3. In `/srv/baseify/eventflow/.env`: real hosts/origins (https),
   `NEXT_PUBLIC_API_URL=https://…`, and flip `SESSION_COOKIE_SECURE`,
   `CSRF_COOKIE_SECURE`, `SECURE_HSTS_PRELOAD` to `true`.
4. `docker compose --env-file … up -d backend nginx` + `verify.sh`.

Django container-image notes: run processes as non-root; build deps stay
in the builder stage; `.env*`, git history and local databases are
excluded via `.dockerignore`; no secrets in image layers (inline
build-time dummies only); production secrets are not part of any GitHub
artifact.

---

## 6. Validation status

Run locally during implementation (see the delivery report for raw
results): `docker compose config` (static Compose binary), `bash -n` +
shellcheck on all scripts, actionlint on workflows, hadolint on both
Dockerfiles, `nginx -t` on the container config. **Image builds and
container smoke tests run in the CI `docker` job** (no Docker daemon on
the implementation machine — no image build was claimed locally).
