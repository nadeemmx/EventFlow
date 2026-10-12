# EventFlow — Pre-VPS Deployment Audit

**Audit date:** 2026-10-12
**Audit type:** Read-only (no deploys, no commits, no pushes, no source changes; only this report was created)
**Repository:** `/home/builddastaan/EventFlow` → `https://github.com/nadeemmx/EventFlow.git`
**Auditor evidence basis:** local commands, clean-clone builds, live DNS/TLS/HTTP probes, GitHub Actions run logs (`gh`)

> Every claim below is tagged **[VERIFIED]** (observed directly in this audit),
> **[DOCUMENTED]** (exists in repo but not proven to work), or
> **[UNKNOWN]** (cannot be determined without access to the VPS/GitHub UI).

> **STATUS UPDATE (2026-10-12, same day, remediation pass):** Sections A–M describe the
> **pre-fix** state of the repository. Every repository-side P0/P1 blocker in §K has since been
> fixed in the working tree (staged via `git add`, **not committed, not pushed, nothing deployed**).
> The current state, exact fixes, full verification results, remaining blockers, required
> operator decisions and review commands are in **§N — Remediation Log** at the end of this
> document. The verdict in §L remains historically accurate for the pre-fix state; §N.7 has the
> updated verdict.

---

## A. Executive Summary

EventFlow is a **monorepo** with three applications (Django backend, Next.js frontend, Flutter mobile)
plus `deploy/` assets for a **non-Docker, systemd + Gunicorn + Nginx + MariaDB + Redis** VPS stack.

**Overall status: NOT READY FOR DEPLOYMENT.**

The backend is in good shape. The blockers are concentrated in **the frontend repository state**,
**the static-export assumption baked into the deploy pipeline**, and **domain/environment mismatch**.

### Top deployment blockers (detail in §K)

| # | Blocker | Evidence |
|---|---|---|
| 1 | **The current branch does not build from a clean checkout.** Tracked frontend files import files that were never committed. | `git clone` + `npm run build` on `audit/fixes` → `Module not found: Can't resolve '@/lib/contact'` (exit 1) **[VERIFIED]** |
| 2 | **Static export was removed but the deploy pipeline still requires `out/`.** `output: "export"` was deleted in `9103586`; `deploy/deploy_production.sh:116-125` hard-fails if `out/` is missing. | Build in temp copy produced **no `out/`**; `deploy_production.sh:125` → `fail "Frontend build produced no output"` **[VERIFIED]** |
| 3 | **`frontend/.env.production` is gitignored**, so a fresh VPS clone has no `NEXT_PUBLIC_API_URL` and falls back to `http://localhost:8000/api/v1`. | `git check-ignore -v frontend/.env.production` → `.gitignore:3:.env.*`; fallback at `frontend/lib/api-client.ts:4` **[VERIFIED]** |
| 4 | **Health checks fail because `127.0.0.1` is not in `ALLOWED_HOSTS`.** Both real Deploy runs died here. | GH run `34033996700` job log: `[FAIL] /live/ → 400`, `[FAIL] /ready/ → 400`, `exit code 1` **[VERIFIED]** |
| 5 | **The documented VPS is unreachable and the live domain runs a different stack.** | `31.42.125.6` ports 22/80/443 closed/filtered; `eventflow.baseify.in` → `5.9.147.93` running nginx + **Phusion Passenger 6.2.0** with `/health` → **500** **[VERIFIED]** |
| 6 | **`api.` and `media.` subdomains do not exist in DNS.** | `dig +short api.eventflow.baseify.in` → empty; same for `media.` **[VERIFIED]** |
| 7 | **Media uploads will 404 in production.** `MEDIA_URL=/media/`, `DEBUG=False` (Django won't serve media) and **no `/media/` location exists in any Nginx config**. | `backend/config/settings/base.py:110`; `grep -n "location /media" deploy/nginx/*.conf` → no match **[VERIFIED]** |

Also: **CI/CD has never produced a successful deployment.** Deploy ran twice (2026-09-06), failed twice.
The current branch has **3 unpushed commits + 37 uncommitted changes**, so CI has never evaluated it —
and it would fail (frontend build error + 6 failing Flutter tests).

---

## B. Verified Architecture

### B.1 Repository layout

```
EventFlow/                       (git root)
├── backend/                     Django 5.2.18 REST API        [source of truth]
├── backend-build/               358 tracked files = duplicate backend copy  [VERIFIED, committed artifact]
├── frontend/                    Next.js 16 App Router          [source of truth]
├── frontend-build/              static export artifact (gitignored, 0 tracked files)
├── mobile_app/                  Flutter 3.47.2 app
├── deploy/                      deployment assets (sh, nginx, systemd, cron, backup)
├── .github/workflows/           ci.yml, deploy.yml
├── docs/, Docs/                 documentation
├── *.md (root)                  many QA/audit reports (untracked or tracked)
└── .env.example                 backend env template (tracked)
```

### B.2 Target runtime architecture (as designed by `deploy/`)

```
                          ┌──────────────────────────────────────────────┐
  Flutter APK  ──HTTPS──► │  Nginx  :80/:443  (vhost routing)            │
  (real device)           │                                              │
                          │  ┌────────────────────────────────────────┐  │
  Browser ────HTTPS──►    │  │ /            → static Next.js export   │  │
  (eventflow.baseify.in)  │  │ /api/v1/*    → proxy 127.0.0.1:8000     │  │
                          │  │ /admin/      → proxy 127.0.0.1:8000     │  │
                          │  │ /health|ready|live → proxy              │  │
                          │  └───────────────┬────────────────────────┘  │
                          │                  ▼                            │
                          │        Gunicorn (eventflow.service)          │
                          │        config.wsgi:application              │
                          │        127.0.0.1:8000, gthread,              │
                          │        workers=2*CPU+1, threads=4            │
                          │                  │                            │
                          │      ┌───────────┼──────────────┐            │
                          │      ▼           ▼              ▼            │
                          │  MariaDB     Redis          local disk       │
                          │  :3306       :6379          MEDIA_ROOT       │
                          │  eventflow   cache+throttle  /home/eventflow/ │
                          │                              media            │
                          └──────────────────────────────────────────────┘
                                  ▲
                                  │ cron: 6 management commands + backup.sh
                                  ▼
                            logs/ + /home/eventflow/backups
```

*Media serving (designed):* `media.eventflow.com` → Nginx `root /home/eventflow/media`.
**No `/media/` mapping exists on the API host** — see §H.4.

*Not used:* Celery, Docker, S3/object storage, WebSocket/ASGI runtime (ASGI file exists but Gunicorn runs WSGI).

### B.3 What is actually live today **[VERIFIED, 2026-10-12 probes]**

| Hostname | DNS | TLS | Server | Response |
|---|---|---|---|---|
| `eventflow.baseify.in` | `5.9.147.93` | LE cert `CN=www.eventflow.baseify.in`, valid 2026-08-28 → 2026-11-26 | `nginx` + `Phusion Passenger 6.2.0` | `/` → **404**; `/health`, `/live`, `/ready`, unknown paths → **500**; trailing-slash URLs → 301 |
| `api.eventflow.baseify.in` | **no record** | — | — | connection fails |
| `media.eventflow.baseify.in` | **no record** | — | — | connection fails |
| `eventflow.com` | `72.246.2.76`, `96.6.114.83` | — | — | resolves (purpose unknown **[UNKNOWN]**) |
| `api.eventflow.com` / `app.eventflow.com` | **no record** | — | — | connection fails |
| `31.42.125.6` (in `docs/CICD.md`, `deploy/deploy_vps.sh`) | — | — | — | ports 22/80/443 **closed/filtered** |

**Conclusion:** the host the mobile app points at is running the **cPanel/Passenger** layout described in
`DEPLOYMENT.md` (matching `backend/config/passenger_wsgi.py` and the root `.htaccess` files) — **not** the
systemd/Gunicorn architecture in `deploy/` — and its Django app is currently **500-ing**.

---

## C. Docker Status

| Question | Answer | Evidence |
|---|---|---|
| 1. Is Docker configured? | **No** | `git ls-files \| grep -i docker` → **empty**. The only `Dockerfile`-ish hits are inside `backend/venv/.../stubs/docker`. |
| 2. Is Docker Compose configured? | **No** | No `docker-compose*`, `compose.y*ml`, or `.dockerignore` anywhere in tracked files. |
| 3. Which services can run in containers? | None configured. All services are designed as host processes (systemd unit + apt packages). | `deploy/systemd/eventflow.service`, `deploy/deploy_vps.sh` steps 1–2 |
| 4. Does the configuration build? | **Not tested — Docker is not installed on this machine.** `docker --version` → `command not found`. | — |
| 5. Are persistent data/uploads protected by volumes? | N/A. Host paths used instead: `/home/eventflow/media`, `/home/eventflow/backups`, `/home/eventflow/python/eventflow-api/logs`. | `deploy/deploy_vps.sh:33-41` |
| 6. Are secrets handled safely? | N/A for Docker. Host-side: `.env` created with `chmod 600`, owned by deploy user; never committed. | `deploy/deploy_vps.sh:150-156` |
| 7. Suitable for production? | N/A. | — |
| 8. What is missing/broken? | Everything Docker-related — **by design**, not by accident. README even says: `### Docker (Future)` → `# Dockerfile planned for containerized deployment`. | `README.md` §Production Deployment |
| 9. Can the app run without Docker? | **Yes.** That is the only supported path today. | whole `deploy/` tree |
| 10. Recommended deployment method? | **Non-Docker: systemd + Gunicorn + Nginx + MariaDB + Redis**, via `deploy/deploy_production.sh` after the §K blockers are fixed. This matches every artifact in the repo (`eventflow.service`, nginx vhosts, apt package list, backup cron). | §C evidence |

**No Docker files were created during this audit.**

---

## D. Database Status

### D.1 Engine

| Item | Value | Evidence |
|---|---|---|
| Engine (all non-test settings) | **MySQL/MariaDB** — `django.db.backends.mysql` | `backend/config/settings/base.py:82-95` |
| Driver | `mysqlclient==2.2.4` (needs `python3-dev`, `default-libmysqlclient-dev`, `build-essential` to compile) | `backend/requirements/base.txt:5` |
| Charset / SQL mode | `utf8mb4`, `SET sql_mode='STRICT_TRANS_TABLES'` | `base.py:90-93` |
| Connection tuning | `CONN_MAX_AGE=600` in production | `production.py:54` |
| Host/port defaults | `127.0.0.1:3306` | `base.py:88-89` |

### D.2 Environment matrix **[VERIFIED]**

| Environment | Settings module | Database | Verified how |
|---|---|---|---|
| Dev (default `manage.py`) | `config.settings.development` | **MySQL** `root@localhost`, empty password | `manage.py:4`; live attempt → `OperationalError: (1698, "Access denied for user 'root'@'localhost'")` — **the documented local dev command does not work out of the box** |
| Local (actual, **untracked file**) | `config.settings.local` | **SQLite** `backend/db.sqlite3` (2.5 MB file present) | `backend/config/settings/local.py` exists on disk, `git ls-files` → not tracked |
| Test / CI | `config.settings.test` | **SQLite `:memory:`** | `backend/config/settings/test.py:5-9`; `backend/pytest.ini` sets `DJANGO_SETTINGS_MODULE = config.settings.test` |
| Production | `config.settings.production` | **MySQL/MariaDB** from `.env` | `backend/config/wsgi.py:4` |

**Answers:**
1. **Development:** MySQL by default (broken with stock credentials); the working local setup uses the **untracked** `config.settings.local` → SQLite.
2. **Production:** MySQL/MariaDB (MariaDB in `deploy_vps.sh` apt list).
3. **SQLite for testing:** **Yes** — in-memory.
4. **MySQL/MariaDB required on VPS?** **Yes (required).** PostgreSQL is not used anywhere.
5. **Are all migrations present?** **Yes** — 62 migration files across 20 apps. `apps/dashboard` and `apps/reports` have **no models**, so 0 migrations is correct (not a gap).
6. **Migration risks:**
   - QA record shows **92 applied / 0 pending** after applying `token_blacklist.0013_alter_blacklistedtoken_options_and_more` (metadata-only `AlterModelOptions`) — `QA-FINAL-REPORT.md` §Phase 1. **[DOCUMENTED]**
   - `EncryptedTextField` (AES-256-GCM) has **legacy Django-signed values** that need `manage.py reencrypt_fields` — the command exists (`backend/core/management/commands/reencrypt_fields.py`) and `deploy/deploy.sh:87` runs it with `--dry-run`, but **`deploy_production.sh` does not run it**. Risk if old rows exist.
   - Migrations are applied by `deploy_production.sh:91` **on every deploy, non-interactively** — safe as long as the DB is reachable; there is no pre-deploy DB backup step in the CD path.
7. **What must be prepared:** database `eventflow`, user `eventflow`, `GRANT ALL` on that DB, host `127.0.0.1:3306`, `utf8mb4`. Credentials via `DB_NAME`, `DB_USER`, `DB_PASSWORD`, `DB_HOST`, `DB_PORT` (values never printed in this report).
8. **Backup/restore:** `deploy/scripts/backup.sh` (mysqldump + gzip, 7 daily / 4 weekly, gzip integrity check, optional `OFFSITE_REMOTE`) and `deploy/scripts/restore.sh` (verify → `--yes` gate → restore, with `--dry-run`). **Both exist and are structurally sound [VERIFIED by reading].** Not executed (destructive).
9. **Can migrations run safely at deploy?** Mechanically yes; **not verified against a real production DB** (out of scope). Recommendation: take a `backup.sh` snapshot before the first deploy and again before any migration-bearing release.

### D.3 Answers not to guess

No migration was executed against any non-local database during this audit.

---

## E. CI/CD Status

### E.1 Workflow inventory **[VERIFIED]**

| File | Trigger | Jobs | Target branch | Secrets used (NAME only) | Automated? |
|---|---|---|---|---|---|
| `.github/workflows/ci.yml` | `push`, `pull_request` → `master` | `backend` (Py 3.12, `manage.py check`, `pytest`), `frontend` (Node 20, `npm ci`, `npm run build`), `mobile` (Flutter **3.47.2**, `pub get`, `analyze`, `test`) | `master` | none | auto |
| `.github/workflows/deploy.yml` | `workflow_run` of **CI** on `master` (success + push) or `workflow_dispatch` | `deploy`: SSH → copy `deploy/deploy_production.sh` → run on VPS → `smoke_test.sh` | `master` | `VPS_HOST`, `VPS_USER`, `VPS_SSH_KEY`, `VPS_PORT` (optional, defaults 22) | auto (env `production`) |

Configured GitHub secrets **[VERIFIED via `gh secret list`]**: `VPS_HOST`, `VPS_SSH_KEY`, `VPS_USER`.
`VPS_PORT` is **not** set (workflow falls back to 22). Environment `production` exists.

Deployment directory implied by scripts: repo `/home/eventflow/eventflow`,
backend `/home/eventflow/python/eventflow-api`,
frontend `/home/eventflow/frontend/public_html`,
media `/home/eventflow/media`.
No deployment target is declared inside the YAML itself (it is inside the shell script).

### E.2 The five statuses — evidence-based

| Status | Verdict | Evidence |
|---|---|---|
| Workflow file exists | **YES** | `ci.yml`, `deploy.yml` present |
| Workflow configuration appears valid | **MOSTLY YES** — but `deploy.yml` depends on `out/` and health checks that cannot pass as configured | §K-2, §K-4 |
| Workflow runs successfully | **PARTIAL.** CI: succeeded on 2026-09-06 (`afd0af5`). Deploy: **ran twice, failed twice** | `gh run list` → `completed failure Deploy … 34033996700`, `34032961877`; CI `success 34033904954` |
| Deployment succeeds on the VPS | **NO** | job `101494374319` step *"Deploy backend and frontend"* = failure; log: `[FAIL] /live/ → 400`, `[FAIL] /ready/ → 400`, `DEPLOYMENT COMPLETED WITH WARNINGS`, `Process completed with exit code 1` |
| Application verified live | **NO** | live probes today: `/` 404, `/health` 500 (§B.3) |

### E.3 What the failed deploy actually did

From job log `101494374319` (2026-09-06, commit `afd0af5`):
- steps 1–9 succeeded: repo updated, deps installed, `migrate`, `collectstatic`, frontend built (**Next.js 14.2.35 → produced `out/`**), Gunicorn restarted, Nginx reloaded, services `[OK]`
- step 10 health checks: `/live/` and `/ready/` returned **400**, `/` returned **200** → script exits 1.

**Root cause [VERIFIED by code reading]:** `deploy_production.sh` curls `http://127.0.0.1/live/`, Nginx
forwards `Host: 127.0.0.1`, and `DJANGO_ALLOWED_HOSTS` in the VPS `.env` is set to the public IP/hostname
(`deploy/deploy_vps.sh:124`, `deploy.sh:69`) which does **not** include `127.0.0.1` → Django `DisallowedHost` → **400**.
`production.py` also overrides the `localhost,127.0.0.1` default from `base.py:9`.

### E.4 What has never been proven

- **Never run for the current branch:** `audit/fixes` = **3 commits ahead of `origin/master`**, unpushed (`db65e27`, `9103586`, `7a36b6e`).
- **Would fail if pushed:** `npm run build` on a clean checkout of `7a36b6e` exits **1** (§A blocker 1); `flutter test` = **6 failures** (§I).
- No APK/AAB build job exists in any workflow.
- No workflow runs migrations/collectstatic separately (they are inside the shell script).
- No rollback job exists; rollback is a **manual** instruction printed by the script (`deploy_production.sh:230-233`).

---

## F. VPS Requirements

### F.1 Software checklist

| Requirement | Status | Notes |
|---|---|---|
| Ubuntu 22.04/24.04 LTS (or Debian) | **Required** | `apt-get`, `systemd`, `ufw`, `certbot` assumed by scripts |
| Nginx | **Required** | reverse proxy + static frontend + media |
| MariaDB server | **Required** | DB engine |
| Redis server | **Required** | `production.py:36-42` raises if `REDIS_URL` empty (throttle + brute-force shared across Gunicorn workers) |
| Python 3.11–3.13 + `venv` | **Required** | CI uses **3.12**; local venv is 3.14. Use 3.12 on the VPS to match CI |
| `python3-dev`, `default-libmysqlclient-dev`, `build-essential` | **Required (build-time)** | `mysqlclient` compiles from source |
| Gunicorn + Uvicorn | **Required: Gunicorn only** | `production.txt` installs both; systemd runs **gunicorn** with `gunicorn.conf.py`. Uvicorn is unused (optional) |
| Node.js 20+ + npm | **Required (build-time**, and **runtime** if you serve the app with `next start`) | Next.js **16.4.0**; CI uses Node 20. Local build ran on Node 24 |
| Flutter SDK | **Not needed on the VPS** | APK/AAB built locally — release APK build verified here (§I). Only needed if you want CI/CD-built APKs |
| Celery | **Not needed** | no `celery` in requirements; background work = cron management commands |
| Systemd unit | **Required** | `deploy/systemd/eventflow.service` |
| Cron | **Required** | 6 app jobs + daily backup (`deploy/scripts/crontab.txt`) — **not installed by `deploy_production.sh`** |
| Docker / Docker Compose | **Not needed** | §C |
| SSL/TLS (certbot) | **Required** for your `*.baseify.in` hostnames | `deploy.sh:145` only *prints* the certbot command; `deploy_vps.sh` installs certbot but never runs it |
| Firewall (ufw) | **Required — with a fix** | `deploy_vps.sh:391-393` allows only `ssh`, `80`, `8080`. **`443/tcp` is missing** → HTTPS would be blocked if that script configures the firewall |
| Log directory | **Required** | `<backend>/logs/` (gitignored, created by `production.py:97-98`) — rotated `django.log` 10 MB × 5 |
| Persistent media directory | **Required** | `/home/eventflow/media` (hardcoded `production.py:88`) |
| Backup storage | **Required** | `/home/eventflow/backups/{daily,weekly}`; `OFFSITE_REMOTE` **unset by default** → script prints a loud warning |
| Monitoring/health checks | **Optional but present** | `/health/` `/ready/` `/live/` endpoints + `deploy/scripts/smoke_test.sh` |
| Sentry | **Optional / not wired** | `SENTRY_DSN` appears in `.env.example:37` and `README.md:730` but **no code reads it** |

### F.2 Ports

| Port | Direction | Purpose |
|---|---|---|
| 22/tcp | inbound | SSH (change/disable password auth **[recommended]**) |
| 80/tcp | inbound | HTTP + ACME challenge |
| 443/tcp | inbound | HTTPS — **must be opened (missing from `deploy_vps.sh`)** |
| 8080/tcp | inbound (optional) | media server in the IP-only config; **prefer a `media.` vhost on 443 instead** |
| 8000/tcp | localhost only | Gunicorn bind (`gunicorn.conf.py:4`) |
| 3306/tcp | localhost only | MariaDB |
| 6379/tcp | localhost only | Redis |

### F.3 Directories

```
/home/eventflow/
├── eventflow/                     git clone
├── python/eventflow-api/          backend + venv + .env (600) + logs/ + staticfiles/
├── frontend/public_html/          frontend output
├── media/                         uploads (must persist across deploys)
└── backups/{daily,weekly}
```

### F.4 Resource estimate **[ESTIMATE — labelled as such]**

| Tier | vCPU | RAM | Disk | When |
|---|---|---|---|---|
| Minimum practical | 2 | **4 GB** | 40 GB SSD | MariaDB (~300–500 MB) + Redis (~100 MB) + Gunicorn `2*CPU+1` workers × ~150 MB + Nginx + OS |
| Comfortable | 4 | 8 GB | 60–80 GB SSD | if you run `next start` (Node ~300–500 MB) alongside, plus headroom for report/PDF generation |
| Absolute floor (not recommended) | 2 | 2 GB | 30 GB | Gunicorn worker count must be pinned low via `GUNICORN_WORKERS`; OOM risk under concurrent report/export jobs |

**Assumptions:** single-tenant-load VPS, no external DB, local media storage, ~100 concurrent users,
daily backups retained 7+4 weeks. **Not measured on a real VPS — label as an estimate.**

**Build-time vs runtime:** Node/npm and Python build tooling are needed **on the VPS** because
`deploy_production.sh:106-125` builds the frontend and installs Python deps *on the server*.
Flutter/Android SDK, Java, Gradle: **build-time only on your machine — not required on the VPS.**

---

## G. Frontend and Backend Runbook

### G.1 Local development (as it actually works today) **[VERIFIED]**

Backend:
```bash
cd backend
python3 -m venv venv && source venv/bin/activate
pip install -r requirements/development.txt

# tests / CI parity  → SQLite in-memory (no DB needed)
DJANGO_SETTINGS_MODULE=config.settings.test python manage.py check     # PASS (0 issues)
DJANGO_SETTINGS_MODULE=config.settings.test pytest tests/ -q           # 454 passed, 1 skipped, 7 xfailed  [VERIFIED]

# local API server → currently BROKEN with stock settings (MySQL root auth denied);
# the team's working setup is the UNTRACKED config.settings.local (SQLite):
DJANGO_SETTINGS_MODULE=config.settings.local python manage.py runserver
```

Frontend:
```bash
cd frontend
npm ci
npm run dev        # Next dev server
npm test           # 10/10 pass  [VERIFIED]
npm run build      # succeeds ONLY with the current working tree  [VERIFIED]
npm start          # BROKEN: `npx serve@latest out` but no `out/` is produced  [VERIFIED]
npm run export     # BROKEN: `next export` was removed in Next 15+  [VERIFIED]
```

Mobile:
```bash
cd mobile_app
flutter pub get
flutter analyze    # No issues found  [VERIFIED]
flutter test       # 191 passed, 6 FAILED  [VERIFIED]
```

### G.2 Production runtime commands (designed) **[DOCUMENTED, not verified on a real VPS]**

```bash
# service
sudo systemctl start|restart|status eventflow
sudo systemctl reload nginx

# application (as defined by deploy/systemd/eventflow.service)
cd /home/eventflow/python/eventflow-api
venv/bin/gunicorn config.wsgi:application -c gunicorn.conf.py
#   bind 127.0.0.1:8000 · worker_class gthread · threads 4
#   workers = 2*CPU+1 · timeout 120 · max_requests 2000 (recycling)

# one-shot
DJANGO_SETTINGS_MODULE=config.settings.production python manage.py check --deploy
DJANGO_SETTINGS_MODULE=config.settings.production python manage.py migrate --noinput
DJANGO_SETTINGS_MODULE=config.settings.production python manage.py collectstatic --noinput
DJANGO_SETTINGS_MODULE=config.settings.production python manage.py validate_deployment

# full CD entrypoint (run as the `eventflow` user, never root)
bash deploy/deploy_production.sh <commit_sha>

# post-deploy verification
bash deploy/scripts/smoke_test.sh https://api.example.com https://app.example.com https://media.example.com
```

**Expected production health-check output:** `/health/` → 200, `/ready/` → 200 with
`"database": true`, `"migrations": true`, `"redis": true`, `/live/` → 200
(`backend/core/health.py:17-70`).

### G.3 Frontend serving decision **[critical]**

| Option | Feasible? | Evidence |
|---|---|---|
| Static export (`out/` + Nginx `root`) | **NO, not with the current code** | With `output: "export"` added, build fails: `Page "/bookings/[id]" is missing "generateStaticParams()" so it cannot be used with "output: export"` **[VERIFIED]**. Also `app/(dashboard)/layout.tsx:10` sets `export const dynamic = 'force-dynamic'`, which export forbids. |
| Node server (`next build` + `next start`) | **YES** | Verified in a temp copy: `next start -p 3112` → `/` 200, `/login` 200, `/bookings/12` 200 **[VERIFIED]** |
| Hybrid (static marketing + Node) | Would require refactor | not attempted |

**Consequence:** the repo must choose — either (a) add `output: "export"` **and** remove dynamic-route/
`force-dynamic` blockers (large refactor), or (b) **switch the frontend to a Node service** and update
`deploy_production.sh`, Nginx and the systemd unit accordingly. As written, the CD script assumes (a)
which the code no longer supports.

---

## H. Domain and Environment Configuration

### H.1 Which domains are configured in code **[VERIFIED]**

| Location | Value |
|---|---|
| `backend/config/settings/production.py:14-18` (ALLOWED_HOSTS default) | `.eventflow.com`, `api.eventflow.com` |
| `production.py:29-33` (CORS default) | `https://app.eventflow.com` |
| `production.py:22-26` (CSRF trusted origins default) | `https://app.eventflow.com`, `https://api.eventflow.com` |
| `deploy/nginx/eventflow.conf` server_names | `app.eventflow.com`, `api.eventflow.com`, `media.eventflow.com` (+ `letsencrypt/live/eventflow.com/`) |
| `frontend/.env.production` (**gitignored, local only**) | `NEXT_PUBLIC_API_URL=https://api.eventflow.com/api/v1` |
| `mobile_app/lib/core/config/app_config.dart:26` (**tracked**) | `https://eventflow.baseify.in/api/v1/` |
| `mobile_app/lib/core/config/app_config.dart:30` | `webBaseUrl = https://app.eventflow.com` |
| `docs/CICD.md`, `deploy/deploy_vps.sh:8` | VPS `31.42.125.6` |
| Live DNS (probed) | `eventflow.baseify.in` → `5.9.147.93` |

**There are three mutually inconsistent domain sets in the repo** (`*.eventflow.com`,
`*.baseify.in`, raw IP) **plus two different VPS IPs.** This must be unified before deployment.

### H.2 Required environment variables (NAMES only — no values)

Backend (`backend/.env`, `chmod 600`, read by systemd `EnvironmentFile=` and by `python-decouple`):

| Name | Required? | Purpose |
|---|---|---|
| `DJANGO_SETTINGS_MODULE` | **Required** | `config.settings.production` |
| `DJANGO_SECRET_KEY` | **Required** (prod hard-fails, `production.py:8-12`) | signing |
| `DJANGO_ALLOWED_HOSTS` | **Required** | comma-separated; **must include `127.0.0.1`** for local health checks |
| `DJANGO_DEBUG` | Required (`False`) | — |
| `DB_NAME`, `DB_USER`, `DB_PASSWORD`, `DB_HOST`, `DB_PORT` | **Required** | MySQL |
| `REDIS_URL` | **Required** (prod hard-fails, `production.py:36-42`) | cache/throttle |
| `ENCRYPTION_KEY` | **Required** (prod hard-fails, `production.py:45-51`) | AES-256-GCM for `EncryptedTextField` |
| `CORS_ALLOWED_ORIGINS` | **Required** | frontend origin(s) |
| `CSRF_TRUSTED_ORIGINS` | **Required** | full origins |
| `EMAIL_HOST`, `EMAIL_PORT`, `EMAIL_HOST_USER`, `EMAIL_HOST_PASSWORD`, `EMAIL_USE_TLS`, `DEFAULT_FROM_EMAIL` | Optional (console fallback if `EMAIL_HOST` empty) | SMTP |
| `CONTACT_INBOX_EMAIL`, `PRIVACY_INBOX_EMAIL` | Optional | contact/privacy inboxes |
| `JWT_ACCESS_TOKEN_LIFETIME`, `JWT_REFRESH_TOKEN_LIFETIME` | Optional | minutes |
| `GUNICORN_BIND`, `GUNICORN_WORKERS`, `GUNICORN_THREADS`, `GUNICORN_ACCESS_LOG`, `GUNICORN_ERROR_LOG`, `GUNICORN_LOG_LEVEL` | Optional | gunicorn tuning |
| `SENTRY_DSN` | **Declared but unused** | no code reads it |

Example placeholder block (never real values):

```bash
DJANGO_SETTINGS_MODULE=config.settings.production
DJANGO_SECRET_KEY=<generate: python3 -c "import secrets;print(secrets.token_urlsafe(50))">
DJANGO_ALLOWED_HOSTS=127.0.0.1,<api-hostname>,<frontend-hostname>
DJANGO_DEBUG=False
DB_NAME=eventflow
DB_USER=eventflow
DB_PASSWORD=<generated>
DB_HOST=127.0.0.1
DB_PORT=3306
REDIS_URL=redis://127.0.0.1:6379/0
ENCRYPTION_KEY=<generate: python3 -c "import secrets,base64;print(base64.b64encode(secrets.token_bytes(32)).decode())">
CORS_ALLOWED_ORIGINS=https://<frontend-hostname>
CSRF_TRUSTED_ORIGINS=https://<frontend-hostname>,https://<api-hostname>
DEFAULT_FROM_EMAIL=noreply@<domain>
```

Frontend (baked at **build time**):

| Name | Required? | Purpose |
|---|---|---|
| `NEXT_PUBLIC_API_URL` | **Mandatory** | axios `baseURL`; fallback `http://localhost:8000/api/v1` (`frontend/lib/api-client.ts:4`) |
| `NEXT_PUBLIC_APP_URL` | Present in `.env.example` but **read nowhere** | dead config |

Mobile (all `--dart-define`, compile-time):

| Name | Required? | Purpose |
|---|---|---|
| `API_BASE_URL` | Optional (default `https://eventflow.baseify.in/api/v1/`) | single source of truth (`app_config.dart:24-27`) |
| `APP_ENV` | Optional (default `production`) | `development|staging|production` |
| `RAZORPAY_KEY_ID` | Optional | declared, **unused** (Razorpay SDK never initialised) |
| `FIREBASE_*` | Informational only | Firebase reads native config files, not dart-defines |

GitHub Actions secrets (names): `VPS_HOST`, `VPS_USER`, `VPS_SSH_KEY`, `VPS_PORT` (optional).

### H.3 CORS / Allowed-hosts changes needed

- `ALLOWED_HOSTS` must contain: the API hostname, the frontend hostname **and `127.0.0.1`** (fixes the 400 health checks).
- `CORS_ALLOWED_ORIGINS` must contain the exact frontend origin (scheme+host, no trailing slash).
- `CSRF_TRUSTED_ORIGINS` must contain the API + frontend origins (needed for `/admin/` and any cookie-auth POSTs).
- Nginx `Content-Security-Policy` in `deploy/nginx/eventflow.conf` pins `connect-src 'self' https://api.eventflow.com` — **must be updated to the real API host** or the browser will block API calls from the frontend.

### H.4 Media URLs — currently broken

1. `MEDIA_URL = "/media/"` (`base.py:110`) → DRF returns relative `/media/venues/…`.
2. Production `DEBUG=False` → Django does **not** serve media (`config/urls.py:18` only adds `static()` when `DEBUG`).
3. **No `location /media/` exists in any Nginx config** (verified by grep).
4. `media.eventflow.baseify.in` has **no DNS record**.

**Result:** every uploaded image/PDF URL will 404 after deployment unless an Nginx `location /media/ { alias /home/eventflow/media/; }` (or equivalent rewrite) is added to the API vhost.

### H.5 HTTPS

- `eventflow.baseify.in` already has a valid LE cert (but issued for `www.eventflow.baseify.in`).
- `deploy.sh:145` only *prints* the certbot command; no automated issuance exists.
- `production.py:57-67` sets `SECURE_PROXY_SSL_HEADER`, secure cookies, `SECURE_HSTS_SECONDS=31536000` with `INCLUDE_SUBDOMAINS` + `PRELOAD` — correct **only** once every subdomain you control is HTTPS-only. **HSTS preload is hard to undo**; consider starting without `SECURE_HSTS_PRELOAD` until domains are final.
- `SECURE_SSL_REDIRECT=False` (delegated to Nginx) → `check --deploy` warns `security.W008` **[VERIFIED]**.

### H.6 What must be configured before mobile live testing

1. Working API behind HTTPS at a hostname the phone can resolve (either fix the existing `eventflow.baseify.in` Passenger deployment **or** stand up the systemd stack and point DNS there).
2. `api.` subdomain (or a path on the same host) with **no** trailing-slash redirects breaking POSTs.
3. CORS origin = the origin the mobile app uses? (Mobile is not subject to CORS; only the web app is.)
4. `DJANGO_ALLOWED_HOSTS` covering the exact Host the phone sends.
5. A reachable `/health/` returning 200 (currently 500).
6. Media path fix (§H.4) if you want to test uploads.
7. Razorpay test keys stored in **Settings → Payment Gateway** (DB), plus `RAZORPAY_KEY_ID` dart-define only if in-app checkout is implemented (it is not).

---

## I. Flutter Live Testing Readiness

### I.1 Toolchain & identity **[VERIFIED]**

| Item | Value |
|---|---|
| Flutter | **3.47.2 stable** (matches CI `subosito/flutter-action` `flutter-version: "3.47.2"`) |
| Dart SDK constraint | `^3.12.2` (`mobile_app/pubspec.yaml`) |
| Android `applicationId` / namespace | `com.eventflow.eventflow_app` |
| `minSdk` | `flutter.minSdkVersion` (launcher-icons config notes 23) |
| `compileSdk` / `targetSdk` | **36** |
| Java / Kotlin target | 17 |
| iOS deployment target | 13.0 (`ios/Podfile`, **file is untracked**) |
| Version | `1.0.0+1`, `versionCode 1` |

### I.2 Build results **[VERIFIED in this audit]**

```
$ flutter analyze        → No issues found!
$ flutter test           → 191 passed, 6 failed
$ flutter build apk --release
                         → ✓ Built build/app/outputs/flutter-apk/app-release.apk (62.1MB)
                           (Gradle assembleRelease took 843.6 s)
```

**APK/AAB commands:**
```bash
cd mobile_app
flutter build apk --release                 # APK  (verified)
flutter build appbundle --release           # AAB for Play Store (not attempted)
# API override at build time:
flutter build apk --release --dart-define=API_BASE_URL=https://<api-host>/api/v1/ --dart-define=APP_ENV=production
```

### I.3 The 6 failing tests **[VERIFIED]**

All in `mobile_app/test/features/authentication/presentation/pages/signup_consent_test.dart`
(tracked and unmodified — they fail **at HEAD**, not because of local edits):

```
A RenderFlex overflowed by 104 pixels on the right.
creator: Row ← Column ← _FormScope ← … ← Form
file:///…/lib/features/authentication/presentation/pages/signup_page.dart:392:19
constraints: BoxConstraints(w=352.0, …)   size: Size(352.0, 20.0)
```

The consent/links `Row` at `signup_page.dart:392` overflows at a **352 px** test surface.
`mobile-fix-progress.md:50-55` already documents these as pre-existing at HEAD.
**Effect:** the CI `mobile` job would fail, which blocks `deploy.yml` (it requires CI success).

### I.4 API / auth / tenancy readiness

| Area | Status | Evidence |
|---|---|---|
| API base URL | Default `https://eventflow.baseify.in/api/v1/` (**that host's `/health` currently 500**) | `app_config.dart:26` |
| Token persistence | `flutter_secure_storage` (injector + `token_service.dart`) | `mobile_app/lib/injector.dart:55` |
| Token refresh | Single-flight refresh with `Completer`, posts `refresh_token` to `auth/refresh/` | `api_client.dart:132-253` |
| Logout revocation | Backend uses `BlacklistCheckingAccessToken` so revoked access tokens 401 | `backend/core/authentication.py:9-27` |
| Tenant scoping | `TenantInterceptor` (query param for reads, body field for writes, multipart skipped) + `TenantContextService` | **both files are untracked** — mobile compiles without them (verified on clean clone), but the tenancy work is **not committed** |
| SUPER_ADMIN | `tenant == null` → interceptor is a no-op; **no tenant-picker UI yet → fail-closed (empty lists)** | `tenant_context_service.dart:19-26` |
| Firebase / FCM | **Not configured**: no `com.google.gms.google-services` plugin, no `google-services.json`, no `GoogleService-Info.plist`. Service is deliberately stubbed → push is a silent no-op (no crash). | grep of `mobile_app/android` + `find` for config files |
| Razorpay | `razorpay_flutter ^1.3.7` builds, **but the SDK is never initialised and no checkout page exists** → in-app payments are display-only (documented in `mobile_app/.env.example`) | pubspec + `.env.example` KNOWN GAP |
| Image uploads / permissions | `image_picker`, `permission_handler` present; **only `INTERNET` is declared** in `AndroidManifest.xml` (sufficient for gallery on API 33+; may need `READ_MEDIA_IMAGES` for older devices / camera capture) | `AndroidManifest.xml:1-11` |
| Internet permission | **Yes, explicitly declared** | `AndroidManifest.xml` |
| iOS | `Podfile` present but **untracked** → iOS build not reproducible from a clean clone; no `GoogleService-Info.plist` | `git ls-files mobile_app/ios/Podfile` → empty |
| Release signing | `eventflow.jks` (**gitignored, present locally**); `build.gradle.kts:29,31` falls back to **literal `eventflow`** for `keyPassword`/`storePassword` when env vars are unset | `mobile_app/android/.gitignore:14` (`**/*.jks`) |
| CI APK/AAB build | **None** — CI only runs `analyze` + `test` | `ci.yml` |

### I.5 Blockers to real-device testing

1. **Backend must actually work at the configured host** — today `/health` → 500 on `eventflow.baseify.in`.
2. CORS/`ALLOWED_HOSTS`/HTTPS on the API host.
3. Fix or accept the 6 failing widget tests (CI gate).
4. Decide hostnames: mobile default (`eventflow.baseify.in`) vs frontend `.env.production` (`api.eventflow.com`) — they must agree on the API origin.
5. Optional for full feature testing: Firebase config files (push), Razorpay test keys in DB + in-app checkout implementation (payments).

**What is NOT a blocker:** Flutter SDK, Android SDK, keystore file, and release-build toolchain —
all verified working on this machine.

---

## J. Security and Recovery

### J.1 Production security posture **[VERIFIED by code reading]**

| Control | State | Ref |
|---|---|---|
| `DEBUG=False` in production | ✅ hard-set | `production.py:5` |
| Fail-closed secret checks (SECRET_KEY, REDIS_URL, ENCRYPTION_KEY) | ✅ raises `ValueError` | `production.py:8-51` |
| Secure cookies / HSTS / nosniff / `X_FRAME_OPTIONS=DENY` | ✅ | `production.py:56-70` |
| `SECURE_SSL_REDIRECT` | ⚠️ `False` (relies on Nginx) → `W008` | `production.py:64` |
| HSTS preload | ⚠️ enabled before domains finalised | `production.py:66-67` |
| CORS restricted | ⚠️ defaults to `eventflow.com`; **must be set for baseify.in** | `base.py:209-214` |
| CSRF trusted origins | ⚠️ same | `production.py:22-26` |
| Password validators | ✅ min-length, common, numeric (no upper-length/complexity — acceptable) | `base.py:97-101` |
| JWT rotation + blacklist | ✅ `ROTATE_REFRESH_TOKENS`, `BLACKLIST_AFTER_ROTATION`, custom blacklist-checking access token | `base.py:193-203`, `core/authentication.py` |
| RBAC + tenant isolation | ✅ `TenantMiddleware`, `TenantJWTAuthentication` → `resolve_tenant_for_request`, `SubscriptionGateMiddleware` | `middleware/tenant.py`, `middleware/subscription.py` |
| Rate limiting | ✅ DRF scopes (`login 5/min`, `forgot_password 3/min`, …) + Nginx `limit_req` zones | `base.py:152-167`, nginx conf |
| Structured logging with request id, no secrets | ✅ `X-Request-ID`, user id only | `core/logging_middleware.py` |
| PII masking in logs | ✅ email masked (`ab***@do***.com`) | `gateway/messaging/email_provider.py:9-19` |
| Secrets in repo | ✅ **none found** — `git grep` for `rzp_live_`, `AKIA…`, `AIza…`, private-key blocks, `sk_live_` → no matches in tracked source | — |
| `.env` files | ✅ all `.env*` gitignored except `.env.example` | `.gitignore:1-3` |
| **Android keystore default password** | 🔴 literal `"eventflow"` fallback committed in `build.gradle.kts:29,31` | see §K-12 |
| **Seeded demo credentials** | 🔴 `seed_demo_data` creates `owner@eventflow.com` / `Password123`, and `README.md`/`DEPLOYMENT.md` publish it | `core/management/commands/seed_demo_data.py:46-61` |
| Dependency vulnerabilities | ⚠️ `QA-FINAL-REPORT.md` claims `pip-audit` 0 and `npm audit` 0 — **pip-audit is not installed here, so only the frontend claim was re-verified**: `npm test` includes a dependency-audit test → **10/10 pass** **[VERIFIED]** | — |
| Django `check --deploy` | ✅ only 2 warnings with a placeholder key (`W008`, `W009`) **[VERIFIED]** | — |

### J.2 Backup & recovery

| Item | Status |
|---|---|
| `deploy/scripts/backup.sh` | ✅ exists: mysqldump+gzip, media tar, config tar (`.env` deliberately excluded), gzip integrity verify, 7 daily / 4 weekly retention, optional `OFFSITE_REMOTE` |
| `deploy/scripts/restore.sh` | ✅ exists: `--list`, `--verify`, `--restore-to <db> --yes`, `--restore-media --yes`, `--dry-run`; refuses without `--yes`; exit codes documented |
| Cron wiring | ⚠️ `deploy/scripts/crontab.txt` defines the daily 02:00 backup — installed by `deploy.sh:63` **but not by `deploy_production.sh`** |
| Off-site copy | ⚠️ `OFFSITE_REMOTE` unset by default → script warns loudly; **backups live only on the VPS** |
| Rehearsal | ❌ never performed (correctly not attempted in a read-only audit) |
| Rollback | ⚠️ manual only: `deploy_production.sh:230-233` prints `git checkout <previous_sha> && git reset --hard HEAD` + re-run script. No automated rollback, no DB rollback step. |

### J.3 Critical production risks (ranked)

1. **Deployable tree is not reproducible** (§K-1) — deploying "the working tree" via git gives a broken frontend.
2. **CD pipeline can never go green** with current health checks (§K-4) → real failures will be masked by chronic red builds.
3. **Media 404s** (§H.4) → all uploaded content invisible in production.
4. **Domain/architecture split-brain**: docs say VPS `31.42.125.6` + systemd; DNS says `5.9.147.93` + Passenger; mobile says `eventflow.baseify.in`; frontend build says `api.eventflow.com` (§B.3, §H.1).
5. **Demo credentials** published in README/DEPLOYMENT could be seeded into production.
6. **Weak default Android signing password** in source (§K-12).
7. **HSTS preload** before domain finalisation (§H.5).
8. **No off-site backups** by default (§J.2).
9. **`deploy_vps.sh` ufw rules omit 443** (§F.1) → HTTPS blocked if that script is used.

---

## K. Blocker Matrix

| Priority | Issue | Evidence | Required action | Blocks deployment? |
|---|---|---|---|---|
| **P0** | Current branch does not build from a clean checkout: tracked files import uncommitted files | `git clone` of `7a36b6e` + `npm run build` → `Module not found: Can't resolve '@/lib/contact'` (exit 1). Missing: `frontend/lib/{business,contact,consent}.ts`, `frontend/components/legal/*`, `frontend/components/marketing/{ContactForm,CareersApplyForm}.tsx`, `frontend/app/(admin)/*` imported by `frontend/app/layout.tsx:6` and `Footer.tsx:6` | **Commit the missing files** (and the 3 unpushed commits) so the tree is self-consistent | **YES** |
| **P0** | Static export removed but the deploy script still requires `out/` | `output: "export"` deleted in `9103586`; `deploy/deploy_production.sh:116-125` `fail "Frontend build produced no output"`; build produced no `out/` | Choose: (a) serve frontend via `next start` (systemd + Nginx proxy) and rewrite step 6, **or** (b) restore `output: "export"` and fix dynamic routes/`force-dynamic` | **YES** |
| **P0** | `frontend/.env.production` is gitignored → VPS build bakes `http://localhost:8000/api/v1` | `git check-ignore -v frontend/.env.production` → `.gitignore:3:.env.*`; fallback `frontend/lib/api-client.ts:4` | Provide `NEXT_PUBLIC_API_URL` in the deploy environment (or commit a non-secret `.env.production` / pass `--env` at build) | **YES** |
| **P0** | Health checks return 400 because `127.0.0.1` ∉ `ALLOWED_HOSTS` | GH run `34033996700` job `101494374319`: `/live/ → 400`, `/ready/ → 400`, exit 1; `production.py:14-18` overrides `base.py:9` default | Add `127.0.0.1` (and `localhost`) to `DJANGO_ALLOWED_HOSTS` in the VPS `.env`, **or** make the script curl the public hostname | **YES** (CI/CD always fails without it) |
| **P0** | Documented VPS `31.42.125.6` is unreachable; live domain runs a different stack | TCP probe 22/80/443 → closed/filtered; `eventflow.baseify.in` → `5.9.147.93`, `X-Powered-By: Phusion Passenger 6.2.0`, `/` 404, `/health` 500 | Confirm the real VPS + IP, and which architecture (Passenger vs systemd) you are standardising on | **YES** |
| **P1** | `api.` and `media.` subdomains have no DNS | `dig +short api.eventflow.baseify.in` → empty (same for `media.`) | Create A records (or restructure to one host + paths) | **YES** for separate-host design |
| **P1** | Media URLs will 404 in production | `MEDIA_URL="/media/"` (`base.py:110`), `DEBUG=False` → no Django media serving, **no `location /media/` in any Nginx config**, `media.` has no DNS | Add `location /media/ { alias <MEDIA_ROOT>/; }` to the API vhost (or set `MEDIA_URL` to the media vhost) | **YES** for upload testing |
| **P1** | Domain set inconsistent across code (`eventflow.com` vs `baseify.in` vs IP) | `production.py:14-33`, nginx server_names, `app_config.dart:26`, `frontend/.env.production`, `docs/CICD.md` | Pick one domain scheme; update ALLOWED_HOSTS, CORS, CSRF, Nginx server_names, certbot, CSP `connect-src`, mobile `API_BASE_URL` | **YES** |
| **P1** | Nothing has ever deployed successfully | `gh run list`: Deploy `failure` ×2 (2026-09-06), CI `success` only for `afd0af5` | Fix P0s, re-run CD, verify with `smoke_test.sh` | **YES** |
| **P1** | Current state unpushed: 3 commits + 37 working-tree changes (10 of them source) | `git status --porcelain` (37 lines), `git rev-list --count origin/master..HEAD` = 3 | Commit/push deliberately (user decision; **not done in this audit**) | **YES** for CI coverage |
| **P2** | CI `mobile` job would fail: 6 widget tests | `flutter test` → 191 passed / 6 failed, `signup_page.dart:392` RenderFlex overflow @352 px | Fix the consent `Row` (wrap/`Flexible`) or widen the test surface | **YES** (CI gate blocks Deploy) |
| **P2** | Cron jobs never installed by the CD path | `deploy_production.sh` has no crontab step; `deploy.sh:63` does | Add crontab install (or document a one-time manual step) | No (functional gap, not deploy-blocking) |
| **P2** | Android release signing falls back to literal `"eventflow"` password | `mobile_app/android/app/build.gradle.kts:29,31` | Require env vars (fail the build if unset); rotate the keystore password | No for backend deploy; **yes for Play/App distribution** |
| **P2** | Demo credentials published & seedable | `seed_demo_data.py:46-61`, `README.md`, `DEPLOYMENT.md:104` | Never run `seed_demo_data` in production; if needed, rotate immediately | No |
| **P2** | `deploy_vps.sh` ufw allows 80/8080 but **not 443** | `deploy/deploy_vps.sh:391-393` | Add `ufw allow 443/tcp` | **YES** if that script configures the firewall |
| **P3** | `npm start` / `npm run export` are broken | `package.json:8-9` (`next export` removed in Next 15+; no `out/`) | Replace with `next start` or remove the scripts | No |
| **P3** | Type checking disabled in production builds | `next.config.mjs` `typescript.ignoreBuildErrors: true` | Re-enable once the tree is clean | No |
| **P3** | `SENTRY_DSN` declared but never read | `.env.example:37`, `README.md:730`; no code reference | Wire `sentry_sdk` or drop the variable | No |
| **P3** | `backend-build/` (358 files) committed duplicate of the backend | `git ls-files backend-build \| wc -l` = 358 | Remove from version control (separate cleanup) | No |
| **P3** | README documents commands that don't exist (`npm run lint`) | `README.md:816`; `package.json` has no `lint` script | Correct the docs | No |
| **P3** | Firebase push not configured; Razorpay in-app checkout not implemented | no `google-services.json`/plugin; `.env.example` KNOWN GAP | Optional per feature need | No |
| **P3** | SUPER_ADMIN has no tenant picker on mobile → fail-closed | `tenant_context_service.dart:19-26` | Build picker UI or restrict SUPER_ADMIN login on mobile | No |

---

## L. Final Verdict

### **NOT READY FOR DEPLOYMENT**

Reasoning (all evidence in this document):

1. **The repository as committed does not build.** A clean `git clone` of the current branch fails
   `npm run build` with unresolved imports (§A-1, §K-1). Anything deployed *from git* will be broken.
2. **The CD pipeline cannot succeed as configured.** The frontend step requires an `out/` directory that
   Next 16 no longer produces (§A-2), and the health-check step returns 400 because of `ALLOWED_HOSTS`
   (§A-4) — both proven: one locally, one from the actual GitHub Actions logs.
3. **There is no verified, reachable target.** The documented VPS is unreachable, the live hostname runs a
   different (currently 500-ing) stack, and two of the three intended hostnames have no DNS (§B.3).
4. **CI has never evaluated the current code** (3 unpushed commits + uncommitted source), and it would
   fail on both the frontend build and 6 Flutter tests (§E.4, §I.3).

The backend itself is healthy: **454 tests pass on a clean checkout**, `manage.py check` is clean,
`check --deploy` shows only 2 expected warnings, and production settings fail closed on missing secrets.
So this is a **preparedness problem, not a rewrite problem**.

> Once the P0 items in §K are fixed and a real VPS + hostname set is confirmed, this moves to
> **READY AFTER SPECIFIC PREPARATION** — the remaining work is mechanical (env files, Nginx media
> location, DNS records, certbot, crontab).

---

## M. Recommended Next Steps (ordered)

### 0. Make the repository deployable (do this first — nothing else works until it's done)
1. **Commit the missing frontend files** so a clean clone builds:
   `frontend/lib/{business,contact,consent}.ts`, `frontend/components/legal/*`,
   `frontend/components/marketing/{ContactForm,CareersApplyForm}.tsx`, `frontend/app/(admin)/*`
   (plus the other 9 untracked source paths in `git status`).
2. **Verify on a clean clone:** `git clone <repo> /tmp/verify && cd /tmp/verify/frontend && npm ci && npm run build`.
3. **Decide the frontend serving model** (§G.3): Node `next start` (recommended) **or** restore static export.
   Update `deploy/deploy_production.sh` step 6, `package.json` `start`, and Nginx accordingly.
4. **Fix the 6 Flutter tests** (`signup_page.dart:392` overflow) so the CI mobile job passes.
5. Commit + push `audit/fixes` → `master` and confirm **CI is green**.

### 1. Prepare the VPS
6. Confirm the real VPS (IP, provider, SSH port, OS). `31.42.125.6` does not respond; `5.9.147.93` is
   currently serving something else — decide whether to **reuse or replace** it.
7. Provision Ubuntu 24.04, ≥ 2 vCPU / 4 GB / 40 GB (§F.4).
8. Create the `eventflow` user with **targeted** NOPASSWD sudo (`systemctl` for `eventflow.service`/`nginx`, `nginx -t`) —
   `deploy_production.sh:51-54` refuses to run without it.
9. Install packages: `nginx mariadb-server redis-server python3 python3-venv python3-dev
   default-libmysqlclient-dev build-essential certbot curl git ufw rsync nodejs/npm (Node 20+)`.
10. Create directory skeleton + permissions (§F.3), `chmod 600` on `.env`.
11. Firewall: allow **22, 80, 443** (add 443 — it is missing from `deploy_vps.sh`); keep 3306/6379 local-only.

### 2. Upload the project
12. Clone onto the VPS: `git clone https://github.com/nadeemmx/EventFlow.git /home/eventflow/eventflow`
    (after step 5 — never deploy an unpushed branch).
13. Or, for a one-off: `rsync -a --exclude .git --exclude node_modules --exclude venv --exclude build <local>/ /tmp/eventflow-deploy/`
    then run `deploy/deploy_vps.sh` (IP-based bootstrap) — **note its ufw and domain assumptions**.

### 3. Configure environment + database
14. Create DB/user; set `DB_*`, `DJANGO_SECRET_KEY`, `ENCRYPTION_KEY`, `REDIS_URL`,
    `DJANGO_ALLOWED_HOSTS` (**include `127.0.0.1`**), `CORS_ALLOWED_ORIGINS`, `CSRF_TRUSTED_ORIGINS`
    in `/home/eventflow/python/eventflow-api/.env` (names/values per §H.2).
15. Provide `NEXT_PUBLIC_API_URL` for the frontend build (§H.2).
16. `venv/bin/python manage.py check --deploy` → expect only `W008` (and `W009` if the key is short).
17. `migrate --noinput` → then `collectstatic --noinput` → `validate_deployment`.
18. **Take a `backup.sh` snapshot before the first public traffic.**

### 4. Start backend and frontend
19. Install + start the systemd unit (`deploy/systemd/eventflow.service`), confirm
    `curl -i http://127.0.0.1:8000/health/` → 200 **before** Nginx is involved.
20. Start the frontend per §G.3 decision (`next start` behind Nginx, or static `out/` if you restored export).
21. Install the crontab (`deploy/scripts/crontab.txt`) — including the 02:00 backup — and set `OFFSITE_REMOTE`.

### 5. Configure domains and HTTPS
22. Create DNS A records for the chosen API/frontend/media hostnames (both `api.` and `media.` are missing today).
23. Install the Nginx vhost (adapt `deploy/nginx/eventflow.conf` server_names, cert paths, and the
    `connect-src` CSP to your real API host), add **`location /media/`** (§H.4), `nginx -t`, reload.
24. `certbot --nginx -d <frontend> -d <api> -d <media>`; verify HTTP→HTTPS redirect.
25. Re-check `DJANGO_ALLOWED_HOSTS` / `CORS_ALLOWED_ORIGINS` / `CSRF_TRUSTED_ORIGINS` against the final hostnames.

### 6. Verify live API health
26. `curl -s https://<api>/health/` → 200; `/ready/` → 200 with `database/migrations/redis` all `true`; `/live/` → 200.
27. `bash deploy/scripts/smoke_test.sh https://<api> https://<app> https://<media>` → `ALL TESTS PASSED`.
28. `curl -X POST https://<api>/api/v1/auth/login/` with bad creds → 400/401 (proves the API path, not just static files).
29. Trigger the GitHub CD workflow once and confirm a **green** run (first time ever, per §E.2).

### 7. Build / install the Flutter APK
30. `cd mobile_app && flutter build apk --release` (**verified working here**, 62.1 MB).
31. Override the API if the hostname changed:
    `flutter build apk --release --dart-define=API_BASE_URL=https://<api>/api/v1/`.
32. Install: `adb install -r build/app/outputs/flutter-apk/app-release.apk`.

### 8. Real-device test script
33. **Login** (fresh install → token persisted in secure storage → kill/relaunch → still logged in → refresh works).
34. **Tenant isolation**: create two tenants, confirm no cross-tenant reads; log in as `SUPER_ADMIN`
    and confirm fail-closed behaviour until a tenant picker exists.
35. **Bookings**: create/confirm/cancel a booking; check the tenant is auto-injected on reads and writes.
36. **Uploads**: venue image + invoice/contract PDF — verify URLs resolve (this is where §H.4 must be fixed).
37. **Payments**: with Razorpay in *test* mode configured in DB Settings, exercise order creation/verification.
    **Expectation:** in-app checkout is not implemented (§I.4) — test the web flow instead.
38. **Push notifications**: only after Firebase config files are installed; otherwise expect a silent no-op.
39. Capture evidence (screens + `adb logcat` + backend `logs/django.log`) for each of the above.

---

## N. Remediation Log — 2026-10-12 (post-audit fixes)

**Scope of this pass:** fix the repository-side blockers identified in §K. All changes are in the
working tree and **staged** (`git add`) only — nothing was committed, pushed, or deployed. No
domain was chosen and none was hard-coded; domain-dependent values are env-configurable. No
secrets are present in any file.

**Rules followed:** business logic/auth/RBAC/tenant isolation untouched; no rewrites of working
modules; no Docker; every claim below is backed by a command that was actually run (outputs
quoted); generated files, secrets, and build output were not staged.

### N.1 Fixes completed

#### P0 — clean checkout builds (was §K-1)

| Fix | Files | Evidence |
|---|---|---|
| Staged all required previously-untracked frontend + mobile sources (34 files: `frontend/lib/{business,contact,consent}.ts`, `frontend/components/legal/*`, `frontend/components/marketing/{ContactForm,CareersApplyForm}.tsx`, `frontend/app/(admin)/*`, `frontend/app/icon.svg`, legal/marketing pages, mobile tenant interceptor + tests, …) | `git add` | clean-index export builds **[VERIFIED]** (§N.2) |
| `.gitignore`: keep useful untracked files reachable (`!.env.production.example`, `backend/config/settings/local.py`), ignore junk (`.agentic-qe/`, `.claude/`, `.mcp.json`, `backend/reports/*`, stray reports) | `.gitignore` | `git status --porcelain` clean **[VERIFIED]** |
| New tracked frontend env template | `frontend/.env.production.example` | staged **[VERIFIED]** |
| Runbooks no longer document the broken static-export/`public_html`/`out/` flow | `README.md` (topology, tree, deploy section), `DEPLOYMENT.md` (topology, §3, §4, troubleshooting) | `grep -rn "out/\|static export" README.md DEPLOYMENT.md` → only "no static out/ exists" wording remains **[VERIFIED]** |

#### P0 — frontend serving model (was §K-2, §K-3)

| Fix | Files | Evidence |
|---|---|---|
| `npm start` → `next start`; removed the broken `npm run export` script | `frontend/package.json:8` | **[VERIFIED]** |
| Build gate: `next build` **fails** unless `NEXT_PUBLIC_API_URL` is an absolute non-localhost http(s) URL (escape hatch `NEXT_PUBLIC_ALLOW_LOCALHOST=true` for local preview only) | `frontend/next.config.mjs:11-49` | no/localhost env → build **exit 1** with explicit error; valid https URL → build **exit 0** **[VERIFIED]** (§N.2) |
| API client: localhost fallback now **dev-only**; in production a missing base URL throws instead of silently pointing browsers at the server's own localhost | `frontend/lib/api-client.ts` | reviewed + tsc **[VERIFIED]** |
| New systemd unit for the frontend: `node next start`, `127.0.0.1:3000`, `EnvironmentFile=…/frontend/.env.production`, `ProtectHome=read-only` + `ReadWritePaths=…/.next` | `deploy/systemd/eventflow-frontend.service` (new, staged) | **[DOCUMENTED]** (unit file reviewed; not executed locally) |
| Nginx converted to a **template**: `eventflow_frontend` upstream (127.0.0.1:3000) replaces the static root; `/` and `/_next/` proxied; tokens `@API_HOST@`/`@APP_HOST@`/`@MEDIA_HOST@`/`@CERT_NAME@` | `deploy/nginx/eventflow.conf:25,110,119` | render-tested **[VERIFIED]** (§N.2) |
| New renderer with validation (hostname charset, unresolved-token check, `-o` flag, defaults = historical eventflow.com values) | `deploy/scripts/render_nginx_config.sh` (new, staged) | `api.example.com` render correct; `'bad host; evil'` rejected **[VERIFIED]** |
| `deploy_production.sh` rewritten (11 steps): Node ≥20 preflight, backend `rsync --delete` (never touches `.env`/`venv`/`media`), `NEXT_PUBLIC_API_URL` resolution (`frontend/.env.production` → backend `.env` → **fail**, never guesses a domain), `npm ci` + build + `BUILD_ID` check, both units installed, cron install (marker-guarded), health checks against `127.0.0.1:8000` + `127.0.0.1:3000` | `deploy/deploy_production.sh` | `bash -n` **[VERIFIED]** |
| `deploy.sh` bootstrap rewritten: copies project to `REPO_DIR`, builds `.next`, installs both units, renders nginx via the render script, installs cron + backup/restore | `deploy/deploy.sh` | `bash -n` **[VERIFIED]** |
| `deploy_vps.sh` rewritten: **`VPS_IP` required** (no silent default), Node 20 install, repo units, `eventflow-ip.conf`, **`ufw allow 443/tcp` added**, DB password never echoed | `deploy/deploy_vps.sh:15-16` | `VPS_IP= bash` fails; `grep 31.42.125.6 deploy/` → none **[VERIFIED]** |

#### P0 — health checks / backend config (was §K-4)

| Fix | Files | Evidence |
|---|---|---|
| `ALLOWED_HOSTS` always unions `127.0.0.1`, `localhost`, `::1` (loopback only — public hosts still exclusively from env) | `backend/config/settings/production.py:19-27` | runtime printout: `['api.example.com','app.example.com','127.0.0.1','localhost','::1']` **[VERIFIED]** |
| CI frontend build gets a `NEXT_PUBLIC_API_URL` (repo var, placeholder fallback — never used for real deploys; VPS builds on-box) | `.github/workflows/ci.yml:72` | **[VERIFIED]** (workflow text; CI itself runs only after push) |
| CD health check now hits `http://127.0.0.1:8000` / `:3000` directly (immune to nginx `server_name`/Host) | `.github/workflows/deploy.yml:62` | **[VERIFIED]** (workflow text) |
| `Type=notify` → `Type=simple` (gunicorn never writes NOTIFY_SOCKET); `Requires=redis.service mysql.service` → `Wants=redis-server.service mariadb.service` (Ubuntu names) | `deploy/systemd/eventflow.service:6,12` | **[VERIFIED]** (diff review) |

#### P1 — media privacy + backups (was §K-7, §J.2)

| Fix | Files | Evidence |
|---|---|---|
| `/media/` is now served **only** for allowlisted prefixes — `tenants/logos/`, `tenants/settings/`, `venues/`, `invoices/logos/`, `branding/` — on the app, api, and media vhosts; everything else (incl. `contracts/pdf/`, `invoices/pdf/`, `contact/resumes/`) → **404** (those stay behind authenticated Django `FileResponse` endpoints); sensitive-extension regex runs before the allowlist; no `.js`-blocking rules in app/api vhosts (they would break Next chunks + Django admin) | `deploy/nginx/eventflow.conf:100,179,288`, `deploy/nginx/eventflow-ip.conf` (+ port-8080 media server with same allowlist) | **[DOCUMENTED]** (config reviewed; `nginx -t` not run — see §N.4) |
| `MEDIA_URL` kept relative (`/media/`) so browser paths work on every origin that proxies/serves it | `backend/config/settings/base.py:110` (unchanged) | **[VERIFIED]** |
| DB dumps: credentials via temp `--defaults-extra-file` (mode 600, trap-cleaned) parsed from backend `.env` — password never on argv, never echoed | `deploy/scripts/backup.sh:62`, `deploy/scripts/restore.sh:31-58` | end-to-end stub test (§N.2) **[VERIFIED]** |
| Fixed `restore.sh verify_archive` SIGPIPE false-failure (`gunzip \| head \| grep` under `pipefail`) and `set -e` trap/cnf bugs | `deploy/scripts/restore.sh:76,108` | good archive exit 0 / empty archive exit 3 **[VERIFIED]** (§N.2) |
| Crontab install is idempotent via `# eventflow-cron-v1` marker (script appends if absent, skips if present) | `deploy/scripts/crontab.txt:4`, `deploy/deploy_production.sh` | **[VERIFIED]** |

#### P2 — CI-mobile blocker (was §I.3)

| Fix | Files | Evidence |
|---|---|---|
| Signup page overflow: the "Already have an account? / Sign In" `Row` → `Wrap` (centered), so narrow screens wrap instead of overflowing | `mobile_app/lib/features/authentication/presentation/pages/signup_page.dart:394` | **all 6 previously-failing tests pass; full suite 197/197** **[VERIFIED]** (§N.2) |

### N.2 Verification results (all commands actually run; real output)

**Backend** (worktree and clean-index export — identical results):

```
pytest tests/ -q  →  454 passed, 1 skipped, 7 xfailed, 71 subtests passed in ~85s   [VERIFIED both trees]
manage.py check (development settings)  →  System check identified no issues (0 silenced)   [VERIFIED]
manage.py check --deploy (production settings, secrets provided via env)  →
    only security.W008 (SECURE_SSL_REDIRECT — nginx terminates TLS) and
        security.W021 (HSTS preload — deliberately off, §N.1-P0-3)
    exit 0   [VERIFIED]
ALLOWED_HOSTS runtime printout → ['api.example.com', 'app.example.com', '127.0.0.1', 'localhost', '::1']   [VERIFIED]
```

**Frontend** (worktree and clean-index export — identical results):

```
npm ci → 0 · npx tsc --noEmit → 0 · npm test → 10/10 pass   [VERIFIED both trees]
NEXT_PUBLIC_API_URL=https://api.example.com/api/v1 npm run build →
    ✓ Compiled successfully · .next/BUILD_ID=gymDnaW97QJeph8I8duS3 · exit 0   [VERIFIED, clean export]
build with localhost/missing env → exit 1, error:
    "NEXT_PUBLIC_API_URL points at localhost, which is not reachable from a browser
     in production. Set the real API origin, or NEXT_PUBLIC_ALLOW_LOCALHOST=true
     for a local preview only."   [VERIFIED]
```

**Flutter** (worktree and clean-index export — identical results):

```
flutter analyze → No issues found! (0 issues)   [VERIFIED both trees]
flutter test → 197/197 All tests passed!   (was 191 passed / 6 failed before the Wrap fix)   [VERIFIED both trees]
```

**Deploy scripts:**

```
bash -n on all 7 scripts (deploy_production.sh, deploy.sh, deploy_vps.sh,
    backup.sh, restore.sh, render_nginx_config.sh, smoke_test.sh) → OK, 0 errors   [VERIFIED]
render_nginx_config.sh api.example.com →
    upstream/listen/server_name/CSP connect-src all substituted; nginx $host/$uri intact;
    no unresolved @TOKEN@; default (no-arg) render keeps eventflow.com values   [VERIFIED]
render_nginx_config.sh 'bad host; evil' → rejected (hostname charset validation)   [VERIFIED]
backup.sh end-to-end with stubbed mysqldump + fake .env:
    mysqldump argv: --defaults-extra-file=/tmp/tmp.XXXX (password NOT on argv)
    artifacts: db_*.sql.gz + media_*.tar.gz + config_*.tar.gz created; gzip verified
    temp cnf file removed on exit; no secret strings in artifacts; exit 0   [VERIFIED]
restore.sh --verify on real gzipped dump → "passed integrity checks" exit 0
restore.sh --verify on empty/corrupt archive → exit 3 (correctly fails)
restore.sh --dry-run --restore-to eventflow_staging → shows would-execute, exit 0   [VERIFIED]
deploy_vps.sh with VPS_IP unset → fails immediately with usage message   [VERIFIED]
grep -rn "31.42.125.6" deploy/ → no matches   [VERIFIED]
```

**Not run locally (be honest about it):** `nginx -t` (no nginx binary on this machine);
`systemctl restart` of real units; certbot; any VPS or GitHub push. CI/CD workflows were edited
but their behaviour is only proven after the branch is pushed.

### N.3 Complete list of files changed in this pass

```
.github/workflows/ci.yml                     # NEXT_PUBLIC_API_URL env on frontend build
.github/workflows/deploy.yml                 # health/smoke args → 127.0.0.1:8000/:3000
.gitignore                                   # junk ignored; .env.production.example + local.py tracked
DEPLOYMENT.md                                # topology, frontend §3, media §4, journalctl hint
README.md                                    # topology, tree, deploy section (no more out//public_html)
backend/config/settings/production.py        # loopback ALLOWED_HOSTS union; HSTS preload off (env)
deploy/deploy.sh                             # bootstrap rewritten (project copy, .next build, units)
deploy/deploy_production.sh                  # rewritten (sync, build, units, cron, port health checks)
deploy/deploy_vps.sh                         # rewritten (required VPS_IP, Node 20, ufw 443, no secrets)
deploy/nginx/eventflow.conf                  # token template: frontend proxy + media allowlist
deploy/nginx/eventflow-ip.conf               # proxy model + media allowlist + :8080 media server
deploy/scripts/backup.sh                     # defaults-extra-file creds; env-overridable dirs
deploy/scripts/crontab.txt                   # idempotency marker
deploy/scripts/restore.sh                    # lazy setup_client; SIGPIPE fix; if-block traps
deploy/scripts/render_nginx_config.sh        # NEW — validated token renderer
deploy/systemd/eventflow.service             # Type=simple; distro-neutral Wants=
deploy/systemd/eventflow-frontend.service    # NEW — next start on 127.0.0.1:3000
frontend/.env.production.example             # NEW — tracked template
frontend/lib/api-client.ts                   # dev-only localhost fallback
frontend/next.config.mjs                     # validateApiUrl() build gate
frontend/package.json                        # start → next start; export removed
mobile_app/lib/…/signup_page.dart            # Row → Wrap overflow fix
```

(Plus the 34 previously-untracked source/test files staged in §N.1-P0-1 and this report.)

### N.4 Remaining blockers (post-fix)

| # | Blocker | Why it remains | What closes it |
|---|---|---|---|
| 1 | **No verified VPS + no chosen domain set** | Audit found three inconsistent sets (`*.eventflow.com`, `*.baseify.in`, raw IP) and a live host (`5.9.147.93`) running a different, 500-ing stack. Choosing one is an operator decision, not an engineering default. | §N.5 answers → then `render_nginx_config.sh` + `.env` |
| 2 | **Nginx configs never syntax-checked** | No `nginx` binary on the audit machine | On VPS: `sudo nginx -t` after render; fix any error before `reload` |
| 3 | **CI/CD unproven on this branch** | Nothing pushed since the fixes; GitHub has never seen this tree | User approves commit+push → confirm green CI (`frontend` 10/10, `mobile` 197/197, backend 454) |
| 4 | **GitHub repo variable `NEXT_PUBLIC_API_URL` not set** (CI uses placeholder) | Agent cannot set repo variables | Set it in GitHub → UI or `gh variable set` (§N.6) |
| 5 | **Secrets/creds must be generated on the VPS** (never in git) | By design | `DJANGO_SECRET_KEY`, `ENCRYPTION_KEY`, DB password, `REDIS_URL`, `NEXT_PUBLIC_API_URL` in `.env` files (§N.5/§H.2) |
| 6 | **DNS still missing** for api./media. (whatever domain set is chosen) | §B.3, §K-6 | A records + certbot |
| 7 | **`SECURE_SSL_REDIRECT` intentionally not enabled** (`check --deploy` W008) | nginx terminates TLS and redirects HTTP→HTTPS; enabling Django-level redirect would fight the proxy on `Host`/proto edge cases | Leave as-is, or set the env after confirming `X-Forwarded-Proto` handling |
| 8 | **Offsite backup target unset** | Requires the operator's rsync destination | Set `OFFSITE_REMOTE` |
| 9 | **Mobile APK still defaults to its compiled-in API base** | Domain not chosen yet | Build with `--dart-define=API_BASE_URL=https://<api>/api/v1/` once decided |
| 10 | **Everything is staged, not committed** | Per rules — no commit without explicit approval | §N.6 |

### N.5 Decisions required from you (will not be guessed)

1. **VPS:** real IP/hostname, SSH port, provider, OS image. Reuse `5.9.147.93` (currently serving
   Passenger + a 500-ing app) or provision fresh?
2. **Domain set:** one coherent triple — frontend host, API host, media host. Options include the
   historical `app.` / `api.` / `media.eventflow.com`, the live `eventflow.baseify.in` family, or
   something else. Also the cert name (`--cert-name`).
3. **DNS:** who creates the A/AAAA records, and for which names.
4. **Secrets:** generate `DJANGO_SECRET_KEY` + `ENCRYPTION_KEY` on the VPS; choose DB password;
   decide `REDIS_URL`.
5. **Backup:** `OFFSITE_REMOTE` rsync target (or confirm single-host backups are accepted risk).
6. **GitHub:** set repo variable `NEXT_PUBLIC_API_URL`; confirm deploy secrets
   (`VPS_HOST`, `VPS_USER`, `VPS_PORT`, `VPS_KEY`) still valid.
7. **Go-ahead:** approve commit + push of the staged tree (branch `audit/fixes` or into `master`).

### N.6 Exact commands for your review (nothing below has been run by the auditor beyond the read-only parts marked so)

```bash
# --- 1. Review what changed (read-only, safe now) ---
git status                            # everything staged, nothing untracked/junk
git diff --cached --stat              # 34 source files + 22 modified/added (incl. this report)
git diff --cached backend/config/settings/production.py frontend/next.config.mjs frontend/package.json
git diff --cached deploy/ .github/workflows/
git diff --cached mobile_app/lib/features/authentication/presentation/pages/signup_page.dart
# sensitive-file spot checks (must show NO secrets):
git diff --cached | grep -iE "password|secret|token" | grep -vE "DB_PASSWORD|SECRET_KEY|password=|passwordfile|no password|secrets are|secret values|token in|password never|password on|password file|SECRET"

# --- 2. Re-run verification yourself (read-only) ---
cd frontend && npm ci && npx tsc --noEmit && npm test
NEXT_PUBLIC_API_URL=https://api.example.com/api/v1 npm run build   # expect exit 0
cd ../backend && ./venv/bin/python3 -m pytest tests/ -q           # expect 454 passed
cd ../mobile_app && flutter analyze && flutter test               # expect 0 issues, 197/197

# --- 3. Commit + push (ONLY after you approve; not run by auditor) ---
# git commit -m "fix(deploy): make repo deployable — next start model, media allowlist,
#   loopback health checks, VPS script hardening, build gate for NEXT_PUBLIC_API_URL,
#   Flutter signup overflow fix"
# git push origin audit/fixes
# then: gh variable set NEXT_PUBLIC_API_URL --body "https://api.YOUR-DOMAIN/api/v1"
# then: watch CI — gh run watch

# --- 4. After VPS + domain decisions (on the VPS, as the eventflow user) ---
# Render nginx for YOUR hostnames (defaults to legacy eventflow.com only if you omit args):
bash deploy/scripts/render_nginx_config.sh api.YOUR-DOMAIN app.YOUR-DOMAIN media.YOUR-DOMAIN \
    -o /tmp/eventflow.conf
# Bootstrap (first time; creates user dirs, venv, .env prompts — review script first):
#   VPS_IP=<your.ip> bash deploy/deploy_vps.sh
# Ongoing CD-style deploy (from repo on the VPS):
#   bash deploy/deploy_production.sh          # installs both units, builds .next, health-checks ports
# Verify:
#   curl -i http://127.0.0.1:8000/live/        # 200 (loopback now in ALLOWED_HOSTS)
#   curl -i http://127.0.0.1:3000/            # 200 (next start)
#   curl -I https://media.YOUR-DOMAIN/tenants/logos/x.png   # allowlisted → 200/403 per file
#   curl -I https://media.YOUR-DOMAIN/contracts/pdf/x.pdf   # must be 404
#   sudo nginx -t && sudo systemctl reload nginx             # -t is mandatory first
#   bash deploy/scripts/smoke_test.sh https://api.YOUR-DOMAIN https://app.YOUR-DOMAIN
# Mobile:
#   cd mobile_app && flutter build apk --release \
#       --dart-define=API_BASE_URL=https://api.YOUR-DOMAIN/api/v1/
```

### N.7 Updated verdict (post-remediation)

**NOT READY FOR DEPLOYMENT — but for environmental reasons only, not code reasons.**

- Repository-side P0/P1 blockers: **fixed and verified** (§N.1–N.2). Clean checkout builds and
  tests green across all three apps; deploy pipeline no longer depends on `out/`; health checks
  no longer depend on Host headers; media is allowlisted, not public; secrets never on argv or
  in git; the 6 failing Flutter tests are fixed (197/197).
- Still blocking: **§N.4 items** — real VPS + coherent domain set + DNS + TLS + on-VPS
  `nginx -t` + generated secrets + your approval to commit/push.
- No domain was chosen, nothing was deployed, pushed, or committed.

---

### Appendix — Commands used for the original audit (re-runnable)

```bash
# repo state
git status --porcelain -b; git log --oneline -5; git rev-list --count origin/master..HEAD

# backend
cd backend && DJANGO_SETTINGS_MODULE=config.settings.test ./venv/bin/python manage.py check
cd backend && DJANGO_SETTINGS_MODULE=config.settings.test ./venv/bin/python -m pytest tests/ -q
DJANGO_SETTINGS_MODULE=config.settings.production DJANGO_SECRET_KEY=... ENCRYPTION_KEY=... \
  REDIS_URL=redis://127.0.0.1:6379/0 ./venv/bin/python manage.py check --deploy

# frontend — working tree (passes) vs clean clone (fails)
cp -r frontend /tmp/fe && (cd /tmp/fe && npm ci && npm run build)          # exit 0, no out/
git clone <repo> /tmp/clean && cd /tmp/clean/frontend && npm ci && npm run build   # exit 1
# static-export feasibility
(output:"export" added) npm run build   # → generateStaticParams error
npx next start -p 3112                   # → 200 on /, /login, /bookings/12

# mobile
cd mobile_app && flutter analyze && flutter test && flutter build apk --release

# CI/CD evidence
gh run list --limit 15
gh api repos/nadeemmx/EventFlow/actions/jobs/101494374319/logs
gh secret list

# live probes
dig +short eventflow.baseify.in; dig +short api.eventflow.baseify.in
curl -sI https://eventflow.baseify.in/health; curl -s https://eventflow.baseify.in/health
```

*Nothing was deployed, committed, pushed, tagged, or deleted during this audit. No secret values were printed.*
