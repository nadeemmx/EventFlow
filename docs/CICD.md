# EventFlow CI/CD Pipeline

> **Outdated for the production flow.** This file describes the *legacy*
> systemd/host deployment (Passenger, host-level `npm ci`, static export).
> The production deployment is the **Docker Compose stack on the VPS with
> images built in CI and pulled from GitHub Container Registry** — see
> [`docs/DOCKER_DEPLOYMENT.md`](DOCKER_DEPLOYMENT.md) (architecture, GHCR
> setup in §6, rollback, day-2 operations) and
> `.github/workflows/{ci,deploy}.yml`.
> The legacy scripts still in the repository (`deploy/deploy_production.sh`,
> `deploy/deploy_vps.sh`, `deploy/scripts/`) are **not** used by the
> production deploy.

## Architecture

```
GitHub → GitHub Actions → SSH → VPS (31.42.125.6)
                                    ├── Django/Gunicorn (eventflow.service)
                                    ├── Nginx
                                    ├── Next.js (static export)
                                    ├── MariaDB
                                    └── Redis
```

## Required GitHub Secrets

Configure these in **GitHub → Settings → Secrets and variables → Actions**:

| Secret | Description | Example |
|--------|-------------|---------|
| `VPS_HOST` | VPS public IP address | `31.42.125.6` |
| `VPS_USER` | SSH deployment user | `eventflow` |
| `VPS_SSH_KEY` | Private SSH key (ed25519 or RSA) | `-----BEGIN OPENSSH PRIVATE KEY-----...` |
| `VPS_PORT` | SSH port (optional, defaults to 22) | `22` |

### Generating an SSH key pair for deployment

```bash
# On your local machine
ssh-keygen -t ed25519 -C "github-actions-deploy" -f eventflow-deploy-key -N ""

# Copy the PRIVATE key content into GitHub Secrets → VPS_SSH_KEY
cat eventflow-deploy-key

# Copy the PUBLIC key to the VPS
ssh-copy-id -i eventflow-deploy-key.pub eventflow@31.42.125.6
```

## How It Works

### CI (`.github/workflows/ci.yml`)

Runs on every **push to master** and **pull request to master**.

| Job | What it does | Time |
|-----|-------------|------|
| Backend | Python 3.12, `pip install -r requirements/development.txt`, `django check`, `pytest` | ~2 min |
| Frontend | Node.js 20, `npm ci`, `npm run build` (Next.js static export) | ~2 min |
| Mobile | Flutter 3.27, `flutter pub get`, `flutter analyze`, `flutter test` | ~3 min |

CI uses **SQLite in-memory** for backend tests (via `config.settings.test`). No external database is needed.

**If any CI job fails, deployment does not proceed.**

### CD (`.github/workflows/deploy.yml`)

Runs after CI passes on master, or manually via `workflow_dispatch`.

1. CI workflow completes successfully on master
2. CD workflow triggers
3. SSHs into the VPS as `eventflow`
4. Runs `deploy/deploy_production.sh`
5. Performs health checks (`/live/`, `/ready/`, `/`)
6. Reports success or failure in GitHub Actions

### Deployment Script (`deploy/deploy_production.sh`)

Runs on the VPS. Steps:

1. Pre-flight checks (not root, repo exists, venv exists, .env exists)
2. `git fetch origin && git reset --hard origin/master`
3. Install/update Python dependencies
4. `manage.py check --deploy`
5. `manage.py migrate --noinput`
6. `manage.py collectstatic --noinput`
7. Build frontend (`npm ci && npm run build`)
8. Atomic frontend deploy (temp dir → swap)
9. Restart Gunicorn (`systemctl restart eventflow.service`)
10. Reload Nginx (`nginx -t && systemctl reload nginx`)
11. Verify services and health endpoints

### What the script does NOT do

- Does **not** create or modify `.env`
- Does **not** create or drop the database
- Does **not** recreate the virtual environment
- Does **not** regenerate Nginx config
- Does **not** modify systemd service files
- Does **not** touch media uploads
- Does **not** use root

## Rollback

If deployment fails:

```bash
# SSH into VPS
ssh eventflow@31.42.125.6

# Check what's deployed
cd /home/eventflow/eventflow
git log --oneline -5

# Rollback to previous commit
git checkout <previous-commit-sha>
git reset --hard HEAD

# Re-run deployment
bash /tmp/deploy_production.sh
```

**Important:** Database migrations are NOT automatically rolled back. If a migration fails during deployment, the script stops and reports the error. Do not run `migrate` with `--fake` unless you understand the consequences.

## Concurrency

Only one production deployment runs at a time. If a new push arrives while a deployment is in progress, it queues (does not cancel the in-progress deployment).

## Environment Variables

| Environment | Where they live | Managed by |
|------------|----------------|------------|
| CI (GitHub Actions) | Workflow env vars | GitHub |
| Production | `/home/eventflow/python/eventflow-api/.env` | VPS — never touched by CI/CD |

Production secrets (Django SECRET_KEY, DB_PASSWORD, ENCRYPTION_KEY, etc.) remain on the VPS. The deployment script verifies `.env` exists before proceeding.

## Service Management

| Service | Systemd unit | Managed by deployment |
|---------|-------------|----------------------|
| Gunicorn | `eventflow.service` | Restarted on every deploy |
| Nginx | `nginx` | Reloaded (never recreated) |
| MariaDB | `mariadb` | Not touched |
| Redis | `redis-server` | Not touched |

## Files

| File | Purpose |
|------|---------|
| `.github/workflows/ci.yml` | CI pipeline — runs tests on PRs and pushes |
| `.github/workflows/deploy.yml` | CD pipeline — deploys to VPS after CI passes |
| `deploy/deploy_production.sh` | Safe production deployment script (runs on VPS) |
| `deploy/deploy_vps.sh` | **Initial** VPS setup only (creates DB, .env, etc.) — do NOT use for deployments |
| `deploy/scripts/smoke_test.sh` | Post-deployment verification tests |
| `deploy/scripts/backup.sh` | Database and media backup (cron) |

## Troubleshooting

### Deployment fails at "Gunicorn failed to start"

```bash
ssh eventflow@31.42.125.6
journalctl -u eventflow.service --no-pager -n 50
```

Common causes: missing `.env`, invalid `DJANGO_SECRET_KEY`, syntax error in new code.

### Health check fails but services are running

```bash
curl -v http://127.0.0.1/live/
curl -v http://127.0.0.1/ready/
systemctl status eventflow.service
```

### CI fails but code works locally

- Check Python version (CI uses 3.12)
- Check Node.js version (CI uses 20)
- Check Flutter version (CI uses 3.27)
- Ensure `requirements/development.txt` is up to date
- Ensure `package-lock.json` is committed

### Manual deployment

```bash
ssh eventflow@31.42.125.6
cd /home/eventflow/eventflow
git fetch origin
git reset --hard origin/master
bash deploy/deploy_production.sh
```
