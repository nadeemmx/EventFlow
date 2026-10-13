"""Regression tests for the two Docker-migration defects found in review.

Both are static/behavioural checks that run without a Docker daemon (CI has
one, but these must also hold on a laptop and in the `deploy-scripts` job).

1. **``/app/logs`` ownership** — ``backend/Dockerfile`` runs ``collectstatic``
   as root, and production settings (``LOGS_DIR.mkdir`` +
   ``RotatingFileHandler``) create and open ``/app/logs/django.log`` during
   that step. The host ``logs/`` tree is dockerignored, so the directory only
   ever exists as a root-owned build artifact. Without an explicit ``chown``
   the runtime user (uid 10001) hits ``EACCES`` at ``django.setup()`` and
   gunicorn dies with ``Unable to configure handler 'file'``.

2. **``EVENTFLOW_TAG`` propagation** — the external ``.env`` ships
   ``EVENTFLOW_TAG=local``, an image ``deploy_compose.sh`` never builds.
   Cron jobs, ``verify.sh`` and ``restore.sh`` invoked ``docker compose``
   directly, so one-off containers resolved to ``local`` (missing image, or
   stale code after a later deploy). The tag must now be resolved by
   ``lib.sh`` from the recorded deploy SHA, while deploy/rollback keep
   exporting the tag they are switching to.
"""
import os
import re
import shutil
import sys
import subprocess
from pathlib import Path

import pytest

# backend/tests/unit/this_file.py -> repo root is parents[3]
REPO_ROOT = Path(__file__).resolve().parents[3]
BACKEND = REPO_ROOT / "backend"
FRONTEND = REPO_ROOT / "frontend"
DOCKER = REPO_ROOT / "deploy" / "docker"
SCRIPTS = DOCKER / "scripts"

DOCKERFILE = BACKEND / "Dockerfile"
FRONTEND_DOCKERFILE = FRONTEND / "Dockerfile"
DOCKERIGNORE = BACKEND / ".dockerignore"
LIB = SCRIPTS / "lib.sh"


def _context_copy_sources(dockerfile: Path):
    """Yield the sources of every COPY that reads from the build context.

    `COPY --from=<stage>` is skipped: those read another stage, not the
    checkout, so they do not depend on what git tracks.
    """
    for line in dockerfile.read_text().splitlines():
        line = line.strip()
        if not line.startswith("COPY ") or "--from=" in line:
            continue
        tokens = [t for t in line[len("COPY "):].split() if not t.startswith("--")]
        yield from tokens[:-1]  # the last token is the destination


# ---------------------------------------------------------------------------
# Fix 1 — /app/logs must be writable by the runtime user
# ---------------------------------------------------------------------------

def test_dockerfile_creates_and_chowns_app_logs_before_user_app():
    src = DOCKERFILE.read_text()
    mkdir = src.find("mkdir -p /app/logs")
    chown = src.find("chown -R app:app /app/logs")
    user = src.find("\nUSER app\n")
    assert mkdir != -1, "backend/Dockerfile must create /app/logs"
    assert chown != -1, "backend/Dockerfile must chown /app/logs to the app user"
    assert user != -1, "backend/Dockerfile must drop privileges with USER app"
    # The chown has to happen in the final stage, after COPY and after the
    # build-time collectstatic run — a chown before those would be undone.
    assert mkdir < chown < user, (
        "/app/logs must be created, chowned and only then USER app "
        f"(got mkdir@{mkdir}, chown@{chown}, USER@{user})"
    )


def test_dockerfile_chowns_logs_after_build_time_collectstatic():
    """collectstatic runs as root and opens django.log, so chown before it
    would leave a root-owned log file behind."""
    src = DOCKERFILE.read_text()
    collectstatic = src.find("python manage.py collectstatic")
    chown = src.find("chown -R app:app /app/logs")
    assert collectstatic != -1, "build-time collectstatic step is missing"
    assert chown != -1, "/app/logs chown is missing"
    assert collectstatic < chown, (
        "the /app/logs chown must follow the root collectstatic run, "
        "otherwise django.log stays root-owned"
    )


def test_host_logs_are_dockerignored_so_the_image_chown_is_load_bearing():
    """Pins both halves of the fix: if `logs` ever stops being dockerignored
    the COPY would bring host logs in (app-owned, fine), and if the chown
    disappears the build artifact stays root-owned (fatal)."""
    ignored = DOCKERIGNORE.read_text().splitlines()
    patterns = {line.strip() for line in ignored if line.strip() and not line.startswith("#")}
    assert "logs" in patterns, "backend/.dockerignore must exclude the host logs/ tree"
    assert "**/logs" in patterns
    assert "chown -R app:app /app/logs" in DOCKERFILE.read_text()


def test_dockerfile_context_copy_sources_are_tracked_in_git():
    """A COPY source that exists only on a developer's disk breaks the image
    build on a fresh checkout. Git does not track empty directories, so
    `COPY public ./public` silently relied on an uncommitted `public/`."""
    for dockerfile in (DOCKERFILE, FRONTEND_DOCKERFILE):
        base = dockerfile.parent
        for source in _context_copy_sources(dockerfile):
            if source in {".", "./"}:
                continue
            rel = (base / source).resolve().relative_to(REPO_ROOT)
            tracked = subprocess.run(
                ["git", "ls-files", "--", str(rel)],
                cwd=REPO_ROOT, capture_output=True, text=True, check=False,
            ).stdout.strip()
            assert tracked, (
                f"{dockerfile.relative_to(REPO_ROOT)}: COPY source {source!r} "
                f"({rel}) is not tracked by git, so a CI checkout would not "
                "contain it and the image build would fail"
            )


def test_frontend_image_bakes_the_api_origin_next_start_revalidates():
    """`next.config.mjs` runs validateApiUrl() at config-load time, so
    `next start` in the runner image needs NEXT_PUBLIC_API_URL present even
    though the browser bundle already has it inlined. A build-arg alone is
    not enough: the runner stage must ENV it, or the container dies on boot."""
    runner = FRONTEND_DOCKERFILE.read_text().split("AS runner", 1)[-1]
    arg = runner.find("ARG NEXT_PUBLIC_API_URL")
    env = runner.find("ENV NEXT_PUBLIC_API_URL=${NEXT_PUBLIC_API_URL}")
    assert arg != -1, "frontend/Dockerfile runner stage must declare the ARG"
    assert env != -1, (
        "frontend/Dockerfile runner stage must ENV NEXT_PUBLIC_API_URL — "
        "`next start` re-validates it and would refuse to boot without it"
    )
    assert arg < env, "the ARG must precede the ENV that consumes it"
    assert "validateApiUrl();" in (FRONTEND / "next.config.mjs").read_text(), (
        "if next.config.mjs ever stops validating at load time, the ENV in "
        "the runner stage can be dropped — update this test with it"
    )


def test_production_settings_write_into_the_chowned_log_directory():
    """The Dockerfile fix is only correct because production settings write
    exactly there — pin the coupling so a LOGS_DIR change fails here first."""
    src = (BACKEND / "config" / "settings" / "production.py").read_text()
    assert 'LOGS_DIR = BASE_DIR / "logs"' in src
    assert "LOGS_DIR.mkdir(exist_ok=True)" in src
    assert 'BASE_DIR / "logs" / "django.log"' in src


@pytest.mark.skipif(shutil.which("bash") is None, reason="bash not available")
def test_production_settings_boot_when_the_logs_directory_is_writable():
    """Positive path for the runtime the Dockerfile must provide: with a
    writable logs directory production settings import cleanly (this is the
    step that raises `Unable to configure handler 'file'` when it is not)."""
    env = {
        **os.environ,
        "DJANGO_SETTINGS_MODULE": "config.settings.production",
        "DJANGO_SECRET_KEY": "unit-test-dummy-secret-key-0123456789abcdef",
        "ENCRYPTION_KEY": "unit-test-dummy-encryption-key",
        "DJANGO_ALLOWED_HOSTS": "testserver",
        "REDIS_URL": "redis://build.invalid:6379/0",
        "DB_PASSWORD": "unit-test-dummy",
    }
    proc = subprocess.run(
        [sys.executable, "manage.py", "check"],
        cwd=BACKEND, env=env, capture_output=True, text=True, timeout=180,
    )
    assert proc.returncode == 0, f"{proc.stdout}\n{proc.stderr}"
    assert "Unable to configure handler" not in proc.stderr


# ---------------------------------------------------------------------------
# Fix 2 — EVENTFLOW_TAG must never silently fall back to "local"
# ---------------------------------------------------------------------------

def _compose_env(tmp_path: Path, *, tag: str | None = None, state_sha: str | None = None):
    """Minimal lib.sh sandbox: compose file + env file (with the poisoned
    EVENTFLOW_TAG=local default) + a stub `docker` that reports the tag it
    was launched with. Shell environment beats --env-file in Compose
    interpolation, so echoing $EVENTFLOW_TAG models real precedence."""
    repo = tmp_path / "repo"
    compose_dir = repo / "deploy" / "docker" / "eventflow"
    compose_dir.mkdir(parents=True)
    (compose_dir / "docker-compose.yml").write_text("services: {}\n")

    env_file = tmp_path / ".env"
    env_file.write_text("EVENTFLOW_TAG=local\n")

    state = tmp_path / "state"
    state.mkdir()
    if state_sha is not None:
        (state / ".current_sha").write_text(f"{state_sha}\n")

    bindir = tmp_path / "bin"
    bindir.mkdir()
    docker = bindir / "docker"
    docker.write_text(
        "#!/bin/bash\n"
        "printf 'TAG=%s\\n' \"${EVENTFLOW_TAG:-<unset>}\"\n"
        "printf 'ARGS=%s\\n' \"$*\"\n"
    )
    docker.chmod(0o755)

    env = {k: v for k, v in os.environ.items() if k != "EVENTFLOW_TAG"}
    env["PATH"] = f"{bindir}{os.pathsep}{env.get('PATH', '')}"
    env["REPO_DIR"] = str(repo)
    env["ENV_FILE"] = str(env_file)
    env["STATE_DIR"] = str(state)
    if tag is not None:
        env["EVENTFLOW_TAG"] = tag
    return env


def _run_compose(env):
    return subprocess.run(
        ["bash", "-c", 'source "$1" && compose run --rm backend true', "_", str(LIB)],
        env=env, capture_output=True, text=True, timeout=30,
    )


def test_compose_resolves_the_tag_from_the_recorded_deploy_sha(tmp_path):
    """The silent `local` fallback: .env says local, state says a real SHA."""
    env = _compose_env(tmp_path, state_sha="abc123def456")
    proc = _run_compose(env)
    assert proc.returncode == 0, proc.stderr
    assert "TAG=abc123def456" in proc.stdout, (
        "compose must use the deployed SHA, not the .env default "
        f"(got: {proc.stdout.strip()})"
    )
    # the compose invocation itself is unchanged: env file + pinned file path
    assert "--env-file" in proc.stdout and "-f" in proc.stdout
    assert "run --rm backend true" in proc.stdout


def test_compose_honours_a_caller_exported_tag(tmp_path):
    """deploy_compose.sh / rollback.sh export the tag they are switching to;
    lib.sh must never override it (even when a SHA is recorded)."""
    env = _compose_env(tmp_path, tag="feedface", state_sha="abc123def456")
    proc = _run_compose(env)
    assert proc.returncode == 0, proc.stderr
    assert "TAG=feedface" in proc.stdout


def test_compose_falls_back_to_local_only_when_nothing_was_deployed(tmp_path):
    """`local` stays the first-boot value — it is never a valid tag for a
    host that has a recorded deployment."""
    env = _compose_env(tmp_path)  # no .current_sha at all
    proc = _run_compose(env)
    assert proc.returncode == 0, proc.stderr
    assert "TAG=local" in proc.stdout

    # a blank state file means "nothing ever deployed" too
    (tmp_path / "state" / ".current_sha").write_text("\n")
    proc = _run_compose(env)
    assert proc.returncode == 0, proc.stderr
    assert "TAG=local" in proc.stdout


def test_cron_backend_jobs_go_through_the_tag_aware_wrapper():
    cron = (DOCKER / "crontab.txt").read_text()
    wrapper = SCRIPTS / "compose_run.sh"
    assert wrapper.is_file(), "compose_run.sh (cron entry point) is missing"
    assert wrapper.stat().st_mode & 0o111, "compose_run.sh must be executable for cron"
    assert 'COMPOSE="/srv/baseify/eventflow/repo/deploy/docker/scripts/compose_run.sh"' in cron

    backend_jobs = [l for l in cron.splitlines() if "run --rm backend" in l]
    assert backend_jobs, "no scheduled backend jobs found"
    for line in backend_jobs:
        assert line.split()[5].startswith("$COMPOSE"), (
            f"cron backend job bypasses the tag-aware wrapper: {line}"
        )
        assert "docker compose" not in line
    # the backup job talks to mariadb only, no image tag involved
    assert any("backup.sh" in l for l in cron.splitlines())


def test_compose_run_wrapper_sources_the_shared_library():
    src = (SCRIPTS / "compose_run.sh").read_text()
    assert "source \"${SCRIPT_DIR}/lib.sh\"" in src
    assert src.rstrip().endswith('compose "$@"')


def test_deploy_pins_its_tag_before_the_first_compose_call():
    src = (DOCKER / "deploy_compose.sh").read_text()
    export = src.find('export EVENTFLOW_TAG="$TAG"')
    first_call = re.search(r"^\s*compose\s", src, re.MULTILINE)
    assert export != -1, "deploy_compose.sh must export the tag it deploys"
    assert first_call is not None, "deploy_compose.sh must call compose()"
    assert export < first_call.start(), (
        "deploy_compose.sh must export EVENTFLOW_TAG before its first compose "
        "call (compose config must validate the tag being deployed)"
    )
    # the auto-rollback branch re-pins to the previous known-good tag
    assert 'export EVENTFLOW_TAG="$LAST_GOOD"' in src


def test_rollback_pins_its_tag_before_the_first_compose_call():
    src = (SCRIPTS / "rollback.sh").read_text()
    export = src.find('export EVENTFLOW_TAG="$TARGET"')
    first_call = re.search(r"^\s*compose\s", src, re.MULTILINE)
    assert export != -1, "rollback.sh must export the rollback target"
    assert first_call is not None
    assert export < first_call.start(), (
        "rollback.sh must export EVENTFLOW_TAG before its first compose call"
    )
    # recorded state still follows the running stack
    assert 'printf \'%s\\n\' "$TARGET" > "${STATE_DIR}/.current_sha"' in src


def test_verify_and_restore_never_pin_the_local_tag():
    for name in ("verify.sh", "restore.sh"):
        src = (SCRIPTS / name).read_text()
        assert "source \"${SCRIPT_DIR}/../lib.sh\"" in src, f"{name} must source lib.sh"
        assert not re.search(r"^\s*(?:export\s+)?EVENTFLOW_TAG=", src, re.MULTILINE), (
            f"{name} must not assign EVENTFLOW_TAG itself — that is lib.sh's job"
        )
    # verify.sh actively asserts the resolved tag matches the deployed SHA
    verify = (SCRIPTS / "verify.sh").read_text()
    assert "eventflow_tag" in verify
    assert "does not match the deployed SHA" in verify


@pytest.mark.skipif(shutil.which("bash") is None, reason="bash not available")
@pytest.mark.parametrize("path", [
    DOCKER / "deploy_compose.sh",
    *(SCRIPTS / n for n in ("lib.sh", "compose_run.sh", "verify.sh",
                            "restore.sh", "rollback.sh", "backup.sh")),
], ids=lambda p: p.name)
def test_changed_shell_files_have_valid_bash_syntax(path):
    proc = subprocess.run(
        ["bash", "-n", str(path)], capture_output=True, text=True,
    )
    assert proc.returncode == 0, f"{path.name}: {proc.stderr.strip()}"
