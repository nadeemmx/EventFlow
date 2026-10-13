# Baseify — Hosting Additional SaaS Products on the Same VPS

How to add RentFlow, Lawnify, or any new Baseify product to the existing
`194.77.89.95` host **without touching EventFlow**.

## The pattern

Each product = one isolated Compose project:

```
/srv/baseify/
├── eventflow/                 # existing — never modified by onboarding
│   ├── .env                   # secrets, 0600
│   ├── repo/                  # its git checkout
│   ├── media/                 # uid 10001, bind-mounted
│   ├── backups/  logs/
│   └── .current_sha  .previous_sha
├── rentflow/                  # same shape, fully independent
└── lawnify/
```

Isolation guarantees (structural, not conventional):

| Boundary | How it is enforced |
|---|---|
| Compose project | separate `name:` in each `docker-compose.yml` (`eventflow`, `rentflow`, …) — containers, networks and volumes are prefixed by project |
| Network | each product owns its own default + `internal` network; products cannot see each other's containers |
| Data | per-product named volumes (`<product>_db_data`) and per-product `media/` directories |
| Secrets | per-product `.env` (0600), per-product backup dirs |
| Ports | only each product's proxy publishes host ports (see port policy below) |
| CI/CD | one GitHub repo + one `Deploy` workflow per product, each with its own `production` environment approval gate |
| Failure | a broken product never starts/stops another product's containers (`docker compose -p <project>` scope) |

Shared on purpose (host-level, set up once by `bootstrap_vps.sh`):
Docker Engine + log rotation, UFW rules, swap, the `deploy` user (docker
group), the `/srv/baseify` layout and the cron infrastructure.

## Port policy (single IP, no domain yet)

- **EventFlow** owns host ports **80** (app/API) and **8080** (media).
- While there is only one IP and no hostname routing, each additional
  product gets its own **testing ports**, e.g. RentFlow `8081/8082`,
  Lawnify `8083/8084` (compose `ports:` mapping inside that product's
  stack). Its `.env`/`NEXT_PUBLIC_API_URL` and nginx `server_name` use
  `http://194.77.89.95:<port>`.
- **Preferred once a domain exists**: introduce one shared edge proxy
  (nginx) with Host-based routing on `:80/:443`, move per-product
  proxies to internal-only upstream duty, and drop the alternate ports.
  This is the only sanctioned way to give two products port 80.

## Onboarding checklist (example: RentFlow)

1. **Repo**: separate GitHub repository with its own `master`, its own
   `ci.yml` (same job shapes: backend/frontend/mobile/docker) and its own
   `deploy.yml` bound to its own `production` environment + required
   reviewer. Copy the workflow structure from EventFlow; change only
   project names, paths and concurrency groups.
2. **Docker assets**: `<product>/Dockerfile` (+ `.dockerignore`),
   `deploy/docker/<product>/docker-compose.yml` with `name: rentflow`,
   `nginx/` config, `.env.example` — clone the EventFlow layout in
   `deploy/docker/eventflow/` and adjust service names/ports/paths.
3. **Bootstrap the product space on the VPS** (host already prepared):
   ```bash
   sudo install -d -m 755 -o deploy -g deploy /srv/baseify/rentflow/{repo,backups,logs}
   sudo install -d -m 755 -o 10001 -g 10001 /srv/baseify/rentflow/media
   # generate /srv/baseify/rentflow/.env on the server (0600) — same
   # pattern as bootstrap_vps.sh: openssl rand, never print, never commit
   ```
   If the product needs its own cron jobs, add a marker-guarded crontab
   file for the `deploy` user (different marker than
   `eventflow-docker-cron-v1` so installs never collide).
4. **Firewall**: `ufw allow <ports>/tcp` for the product's testing ports
   (root; existing rules for 22/80/443/8080 stay untouched).
5. **GitHub secrets/vars** for the product's workflow: its own
   `VPS_HOST/VPS_USER/VPS_SSH_KEY` (same VPS, same deploy user is fine),
   `NEXT_PUBLIC_API_URL=http://194.77.89.95:<port>/api/v1`.
6. **First deploy**: push to its `master`, wait for green CI, approve
   its `production` gate. Verify with its own `verify.sh`.
7. **EventFlow regression check**: `curl -fsS http://194.77.89.95/health/`
   and `deploy/docker/scripts/verify.sh` in the eventflow repo — nothing
   about the onboarding should have touched the `eventflow` project.

## What NOT to do

- Do not merge products into one compose file or one project.
- Do not share a database container across products (backup and access
  boundaries collapse).
- Do not reuse `.env` files between products.
- Do not publish database/redis ports; keep the `internal` network.
- Do not give a second product host port 80 while EventFlow is on it —
  use alternate ports or wait for the shared edge proxy (above).
- Do not disable the per-product approval gate.
