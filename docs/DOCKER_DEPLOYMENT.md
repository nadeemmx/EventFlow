# EventFlow — Docker Compose Production Deployment

Target: fresh Ubuntu VPS at `194.77.89.95`, no domain yet (temporary
HTTP/IP testing), GitHub Actions with a required-reviewer `production`
approval gate. This document covers the architecture, the fresh-VPS
deployment procedure, day-2 operations, and the security limits of the
HTTP-only test phase.

> **Images are built in CI and pulled by the VPS.** The application images
> are published to GitHub Container Registry (GHCR) by the `CI` workflow and
> the server only *pulls* them — no `docker build`, no `npm ci` on the
> 9.8 GB disk. See §2 (step 5, registry setup) and §6 (GHCR).

---

## 1. Architecture

```
                         GitHub Actions
      ┌──────────┐  push to master   ┌──────────┐  approval gate   ┌──────────┐
      │  CI      │ ────────────────► │  Deploy  │ ─(required──────►│ production│
      │ 5 jobs   │   must be green   │ workflow │   reviewer)      │ environment│
      └────┬─────┘                   └────┬─────┘                  └──────────┘
           │ docker job:                  │ SSH (host-key verified)
           │ compose config,              │ scp deploy_compose.sh + lib.sh
           │ hadolint, nginx -t,          ▼
           │ build + smoke images   VPS 194.77.89.95 (Ubuntu, root + deploy user)
           │ push to GHCR                    │  docker pull
           ▼                                 │  the exact SHA tag
   ┌───────────────────────┐                 │  (digest verified)
   │ GitHub Container      │ ◄───────────────┘
   │ Registry (GHCR)       │
   │ nadeemmx/eventflow-   │
   │ {backend,frontend}:<sha>
   └───────────────────────┘
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
- **Images are tagged with the commit SHA** and published to GHCR
  (`ghcr.io/nadeemmx/eventflow-backend:<sha>`,
  `ghcr.io/nadeemmx/eventflow-frontend:<sha>`), so rollback is "pull the
  previous SHA tag" — no rebuild on the server. The deploy verifies the
  pulled image against the digest CI recorded for that commit.
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
   - **No registry secret is needed in GitHub.** The CI workflow publishes
     with its own `GITHUB_TOKEN`; the VPS either pulls anonymously (public
     package) or uses a token file that never leaves the server (§6).

5. **Give the VPS read access to the images** (one of the two options in
   §6 — required before the first deployment, because the packages are
   private by default):

   ```bash
   # Option A (recommended): make the packages public — no credential on the server
   #   Settings → Packages → eventflow-backend → Change visibility → Public
   #   (repeat for eventflow-frontend)

   # Option B: a read-only PAT that lives ONLY on the VPS
   #   (create a classic PAT with the read:packages scope, then:)
   sudo install -m 0600 -o deploy -g deploy /dev/null /srv/baseify/eventflow/.ghcr-token
   sudo -u deploy tee /srv/baseify/eventflow/.ghcr-token >/dev/null   # paste the PAT
   ```

6. **Trigger the first deployment**: merge to `master` (CI must be green)
   → the `Deploy` workflow starts → it **waits for approval** in the
   `production` environment → reviewer approves → `deploy_compose.sh`
   **pulls** the images CI published for that SHA (and verifies their
   digest), migrates, switches the stack and health-gates; `verify.sh`
   re-checks on the VPS; the runner then tests
   `http://194.77.89.95` externally (frontend 200, `/health/` 200,
   `/ready/` 200, API 401).

7. **Post-deploy sanity on the VPS**:

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
| Rollback | `deploy/docker/scripts/rollback.sh` (previous SHA) or `rollback.sh <sha>` — it **pulls** the target images again |
| Backup | `deploy/docker/scripts/backup.sh` (cron daily 02:00, 14-day retention) → `/srv/baseify/eventflow/backups/` |
| Restore | `restore.sh db <dump.sql.gz> --yes` or `restore.sh media <tar> --yes` (takes a fresh pre-restore backup first) |
| Logs | `docker compose --env-file … logs -f backend` (json-file, 10m×3 rotated) |
| Cron jobs | `crontab -l -u deploy` — management commands + backup (marker `eventflow-docker-cron-v1`) |
| Health | Container healthchecks + `/health/` `/ready/` `/live/` endpoints |
| Disk space | `df -h /var/lib/docker` — the deploy reclaims the (unused) build cache when the disk is tight; superseded app images are removed automatically, volumes never are |

First deploy failure: there is no previous tag to roll back to — the
script leaves the failed stack in place and prints the inspection
commands; fix and re-approve.

---

## 4. CI/CD pipeline

- **CI** (`ci.yml`): Backend (Django check + pytest), Frontend (tsc +
  tests + production build + inlining check), Mobile (analyze + tests),
  Deploy scripts (`bash -n`, shellcheck, actionlint, legacy nginx/systemd
  validation), **Docker** (compose `config` against `.env.example`, the
  "no `build:` section" guard, hadolint, `nginx -t` on the container
  config, image builds from the sparse bundle tagged with the commit SHA,
  backend/frontend smoke tests, and — for a push to `master` — the publish
  to GHCR plus the digest artifact). PRs run CI only and never publish.
- **Deploy** (`deploy.yml`): triggers only on a **successful CI run that
  came from a push to `master`** (or manual `workflow_dispatch`), binds to
  the `production` environment (required reviewer), uses SSH with
  host-key verification (pinned known_hosts/fingerprint → keyscan
  fallback with a pin-it notice; `StrictHostKeyChecking=yes` always),
  least-privilege `permissions: contents: read` + `actions: read`, a
  concurrency lock that queues (never cancels) deployments, and runs:
  resolve digests → `deploy_compose.sh` → `verify.sh` → external live test.

Images are **built and published by CI** (GitHub Container Registry,
`ghcr.io/nadeemmx/eventflow-{backend,frontend}:<commit-sha>`) and
**pulled by the VPS** during the approved deploy. The server never runs
`docker build` and never runs `npm ci` — that is what exhausted its
9.8 GB disk.

### How the "immutable tag" is enforced

A registry tag is technically mutable, so the deploy does not trust the
tag alone:

1. CI publishes `…:<commit-sha>` and records the **registry manifest
   digest** of both images (artifact `image-digests`).
2. The deploy workflow downloads that artifact, checks that it belongs to
   the commit being deployed, and hands the digests to the VPS.
3. The VPS compares the digest of the image it pulled with the recorded
   one and **refuses to start** on a mismatch. It also checks the image's
   `org.opencontainers.image.revision` label against the deployed commit,
   and (for the frontend) the API origin baked into the bundle.

A rollback to an earlier SHA pulls that SHA's images again; the revision
label is still verified, the digest of an older commit is not re-checked
(its artifact belongs to an older CI run).

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

## 6. Container registry (GHCR)

### What lives where

| Item | Where it lives | Who can read it |
|---|---|---|
| Image source | this repository (public) | everyone |
| Published image | `ghcr.io/nadeemmx/eventflow-{backend,frontend}:<sha>` | per the package visibility below |
| Publish credential | the CI workflow's own `GITHUB_TOKEN` (`packages: write`, only for a push to `master`) | GitHub only — never stored |
| Pull credential (option B) | `/srv/baseify/eventflow/.ghcr-token` on the VPS (mode 0600) | the deploy user on that one host |

**No credential is stored in the repository, in a GitHub secret, in a log
line or in the process list.** The publish step uses the workflow token;
the pull step uses either anonymous access (public package) or a token
file that is read through `docker login --password-stdin` into a
throwaway `DOCKER_CONFIG` that is deleted when the script exits.

### Do the images have to be public?

**No — both work, and the deploy supports either without a code change.**

GHCR packages are **private by default** (GitHub's default for a first
publish), so out of the box the VPS needs a read credential. Two options:

| | Option A — public package | Option B — private package + PAT |
|---|---|---|
| Setup | `Settings → Packages → eventflow-backend → Change visibility → Public` (same for `eventflow-frontend`) | classic PAT with `read:packages`, stored at `/srv/baseify/eventflow/.ghcr-token` (0600) |
| Credential on the VPS | none | one read-only token, on one host |
| Risk | anyone can pull the image | a token on the server must be protected (and rotated) |
| Recommendation | **preferred here** — the repository is public and the images contain no secrets (no `.env`, no keys, no database, no media) | use when the image must not be public |

Deciding factors, in order:

1. **Does the image contain anything secret?** No. `backend/.dockerignore`
   and `frontend/.dockerignore` exclude every `.env*`, the SQLite file,
   the media tree and the logs; the build-time secrets are inline dummies.
   The source is public, so a public image reveals nothing new.
2. **Container registry storage is free.** GitHub's package quota does not
   apply to the container registry (storage and bandwidth for container
   images are currently free), so keeping the packages private does not
   cost storage.
3. **Authentication still works with a public package.** If a package is
   later switched back to private, the token file is picked up
   automatically — the pull fails, the script logs in, and the pull is
   retried. No configuration change is needed in either direction.

### Verifying the setup by hand

```bash
# On the VPS (as the deploy user) — should print the digest, no credentials needed
docker pull ghcr.io/nadeemmx/eventflow-backend:<sha>
docker image inspect --format '{{join .RepoDigests " "}}' ghcr.io/nadeemmx/eventflow-backend:<sha>

# With a private package and the token file in place
sudo -u deploy test -f /srv/baseify/eventflow/.ghcr-token && echo "token file present"
```

### Operating the packages

- **Rollback**: `deploy/docker/scripts/rollback.sh <sha>` pulls that
  commit's images again — the packages must therefore not be deleted
  while a rollback may still be needed.
- **Retention**: a successful deploy removes the *superseded* application
  images from the VPS (the current and the previous tag are kept). The
  images in the registry are kept; delete old versions there only when
  you no longer need to roll back to them.
- **Renaming the account**: the image names contain the owner
  (`nadeemmx/`). They are defined in
  `deploy/docker/eventflow/docker-compose.yml`, `deploy/docker/scripts/lib.sh`
  and `.github/workflows/ci.yml` — a unit test fails if the three drift
  apart.

---

## 7. Validation status

Run locally during implementation (see the delivery report for raw
results): `docker compose config` (static Compose binary), `bash -n` +
shellcheck on all scripts, actionlint on workflows, hadolint on both
Dockerfiles, `nginx -t` on the container config. **Image builds and
container smoke tests run in the CI `docker` job** (no Docker daemon on
the implementation machine — no image build was claimed locally).
