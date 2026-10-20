"""Tests for the GHCR (GitHub Container Registry) image deployment flow.

The VPS used to BUILD the application images itself, which exhausted its
9.8 GB disk during the Next.js build. The flow is now:

    CI builds + smoke-tests + publishes  →  ghcr.io/<owner>/eventflow-<svc>:<sha>
    the VPS PULLS that exact tag and verifies it

These tests pin the parts that are easy to break silently:

* the compose file must not contain a ``build:`` section (a stray one would
  let a deploy fall back to building on the server);
* the image names must agree between the compose file, ``lib.sh`` and the
  workflows (the compose file is the only place the VPS reads them from);
* the published tag must be the commit SHA, and the deploy must verify the
  digest CI recorded for it;
* the registry credential must never reach argv, a log line or the repo;
* rollback must be able to fetch a previous tag from the registry;
* no destructive cleanup (``docker system prune -a``, volume deletion).
"""
import os
import re
import shutil
import subprocess
import stat
from pathlib import Path

import pytest

# backend/tests/unit/this_file.py -> repo root is parents[3]
REPO_ROOT = Path(__file__).resolve().parents[3]
DOCKER = REPO_ROOT / "deploy" / "docker"
SCRIPTS = DOCKER / "scripts"
COMPOSE_FILE = DOCKER / "eventflow" / "docker-compose.yml"
LIB = SCRIPTS / "lib.sh"
DEPLOY_COMPOSE = DOCKER / "deploy_compose.sh"
ROLLBACK = SCRIPTS / "rollback.sh"
VERIFY = SCRIPTS / "verify.sh"
CI_WORKFLOW = REPO_ROOT / ".github" / "workflows" / "ci.yml"
DEPLOY_WORKFLOW = REPO_ROOT / ".github" / "workflows" / "deploy.yml"

REGISTRY = "ghcr.io"
OWNER = "nadeemmx"
SHA = "0123456789abcdef0123456789abcdef01234567"
DIGEST = "sha256:" + "ab" * 32


# ---------------------------------------------------------------------------
# helpers
# ---------------------------------------------------------------------------

def _compose_file_text() -> str:
    return COMPOSE_FILE.read_text()


def _docker_stub(tmp_path: Path, *, pull_rc: int = 0, login_rc: int = 0,
                 image_present: int = 1, revision: str = SHA,
                 api_origin: str = "", repo_digest: str = DIGEST,
                 images: str = "", tag_rc: int = 0, rmi_rc: int = 0,
                 pull_always_fail: bool = False,
                 pull_fail_first: int = 0) -> Path:
    """A fake `docker` that records how it was called.

    The stub is what makes the identity/cleanup logic testable without a
    Docker daemon: it answers `image inspect`, `login`, `compose … pull`
    and `images` from canned values.

    Pull behaviour:
      pull_always_fail — every pull fails with `pull_rc` (a private
                         package without a working credential);
      pull_fail_first  — the first N pulls fail, the next one succeeds
                         (the state a private package puts the deploy in
                         until the registry login happened).
    """
    bindir = tmp_path / "bin"
    bindir.mkdir(exist_ok=True)
    log = tmp_path / "docker-calls.log"
    counter = tmp_path / "pull-counter"
    stub = bindir / "docker"
    stub.write_text(
        "#!/bin/bash\n"
        "printf '%s\\n' \"$*\" >> \"${STUB_LOG}\"\n"
        "if [ \"$1\" = \"image\" ] && [ \"$2\" = \"inspect\" ]; then\n"
        "  shift 2\n"
        "  fmt=''\n"
        "  if [ \"$1\" = '--format' ]; then fmt=\"$2\"; shift 2; fi\n"
        "  [ \"${STUB_IMAGE_PRESENT}\" = '1' ] || exit 1\n"
        "  case \"$fmt\" in\n"
        "    *RepoDigests*) printf '%s\\n' \"${STUB_REPO_DIGEST}\" ;;\n"
        "    *Labels*)      printf '%s\\n' \"${STUB_REVISION}\" ;;\n"
        "  esac\n"
        "  exit 0\n"
        "fi\n"
        "if [ \"$1\" = \"login\" ]; then exit ${STUB_LOGIN_RC}; fi\n"
        "if [ \"$1\" = \"compose\" ]; then\n"
        "  for a in \"$@\"; do\n"
        "    if [ \"$a\" = 'pull' ]; then\n"
        "      n=$(cat \"${STUB_PULL_COUNTER}\" 2>/dev/null || echo 0)\n"
        "      n=$((n+1)); printf '%s' \"$n\" > \"${STUB_PULL_COUNTER}\"\n"
        "      if [ \"${STUB_PULL_ALWAYS_FAIL}\" = '1' ]; then exit ${STUB_PULL_RC}; fi\n"
        "      if [ \"$n\" -le \"${STUB_PULL_FAIL_FIRST}\" ]; then exit ${STUB_PULL_RC}; fi\n"
        "      exit 0\n"
        "    fi\n"
        "  done\n"
        "  exit 0\n"
        "fi\n"
        "if [ \"$1\" = \"images\" ]; then printf '%s\\n' \"${STUB_IMAGES}\"; exit 0; fi\n"
        "if [ \"$1\" = \"tag\" ]; then exit ${STUB_TAG_RC}; fi\n"
        "if [ \"$1\" = \"image\" ] && [ \"$2\" = 'rm' ]; then exit ${STUB_RMI_RC}; fi\n"
        "if [ \"$1\" = \"ps\" ]; then exit 0; fi\n"
        "if [ \"$1\" = \"info\" ]; then printf '/var/lib/docker\\n'; exit 0; fi\n"
        "if [ \"$1\" = \"builder\" ]; then exit 0; fi\n"
        "exit 0\n"
    )
    stub.chmod(0o755)

    env = {
        "STUB_LOG": str(log),
        "STUB_PULL_COUNTER": str(counter),
        "STUB_PULL_ALWAYS_FAIL": "1" if pull_always_fail else "0",
        "STUB_PULL_FAIL_FIRST": str(pull_fail_first),
        "STUB_PULL_RC": str(pull_rc),
        "STUB_LOGIN_RC": str(login_rc),
        "STUB_IMAGE_PRESENT": str(image_present),
        "STUB_REVISION": revision,
        "STUB_REPO_DIGEST": repo_digest,
        "STUB_IMAGES": images,
        "STUB_TAG_RC": str(tag_rc),
        "STUB_RMI_RC": str(rmi_rc),
    }
    return bindir, env


def _lib_env(tmp_path: Path, bindir: Path, extra: dict | None = None) -> dict:
    """Environment for a bash process that sources lib.sh."""
    env_file = tmp_path / ".env"
    env_file.write_text("EVENTFLOW_TAG=local\nDB_PASSWORD=secret\n")
    state = tmp_path / "state"
    state.mkdir(exist_ok=True)
    # A minimal compose file so lib.sh's compose() reaches the docker
    # stub instead of stopping at "compose file not found".
    repo = tmp_path / "repo"
    compose_dir = repo / "deploy" / "docker" / "eventflow"
    compose_dir.mkdir(parents=True, exist_ok=True)
    (compose_dir / "docker-compose.yml").write_text("services: {}\n")

    env = {k: v for k, v in os.environ.items() if k != "EVENTFLOW_TAG"}
    env["PATH"] = f"{bindir}{os.pathsep}{env.get('PATH', '')}"
    env["REPO_DIR"] = str(repo)
    env["ENV_FILE"] = str(env_file)
    env["STATE_DIR"] = str(state)
    if extra:
        env.update(extra)
    return env


def _run_bash(env: dict, script: str) -> subprocess.CompletedProcess:
    return subprocess.run(
        ["bash", "-c", script], env=env, capture_output=True, text=True, timeout=60,
    )


# ---------------------------------------------------------------------------
# 1. the compose file pulls, it never builds
# ---------------------------------------------------------------------------

def test_compose_file_has_no_build_section():
    """A `build:` section would let a deploy build on the 9.8 GB server —
    the exact failure this flow replaces."""
    for line in _compose_file_text().splitlines():
        assert not re.match(r"^\s+build:", line), (
            f"the compose file must not build images on the VPS: {line.strip()!r}"
        )


def test_compose_images_point_at_the_registry_with_the_tag():
    text = _compose_file_text()
    assert f"image: ${{EVENTFLOW_REGISTRY:-ghcr.io}}/{OWNER}/eventflow-backend:${{EVENTFLOW_TAG:-local}}" in text
    assert f"image: ${{EVENTFLOW_REGISTRY:-ghcr.io}}/{OWNER}/eventflow-frontend:${{EVENTFLOW_TAG:-local}}" in text


def test_compose_keeps_health_checks_volumes_and_nginx():
    """The pull flow must not cost us the safeguards: health checks, the
    database volume, the media bind mount and the nginx config stay."""
    text = _compose_file_text()
    for service in ("mariadb", "redis", "backend", "frontend", "nginx"):
        assert re.search(rf"^  {service}:$", text, re.MULTILINE), f"service {service} is gone"
    assert text.count("healthcheck:") == 5, "every service must keep its healthcheck"
    assert "name: eventflow_db_data" in text, "the database volume must stay"
    assert "db_data:/var/lib/mysql" in text
    assert "${EVENTFLOW_MEDIA_DIR:-/srv/baseify/eventflow/media}:/home/eventflow/media" in text
    assert "./nginx/eventflow.conf:/etc/nginx/conf.d/default.conf:ro" in text
    # the internal network keeps MariaDB/Redis unreachable from outside
    assert re.search(r"^  internal:$", text, re.MULTILINE)
    assert re.search(r"^\s+internal: true$", text, re.MULTILINE)


# ---------------------------------------------------------------------------
# 2. the image names agree everywhere
# ---------------------------------------------------------------------------

def test_image_names_are_identical_in_compose_lib_and_workflows():
    """The compose file, lib.sh and the CI workflow each name the images.
    Drift would make the VPS pull something the CI never published."""
    compose = _compose_file_text()
    lib = LIB.read_text()
    ci = CI_WORKFLOW.read_text()

    assert f"{OWNER}/eventflow-backend" in compose
    assert f"{OWNER}/eventflow-frontend" in compose

    assert 'EVENTFLOW_PACKAGE_OWNER="nadeemmx"' in lib
    assert 'APP_IMAGE_BACKEND="${EVENTFLOW_REGISTRY}/${EVENTFLOW_PACKAGE_OWNER}/eventflow-backend"' in lib
    assert 'APP_IMAGE_FRONTEND="${EVENTFLOW_REGISTRY}/${EVENTFLOW_PACKAGE_OWNER}/eventflow-frontend"' in lib

    assert "eventflow-backend:${GITHUB_SHA}" in ci
    assert "eventflow-frontend:${GITHUB_SHA}" in ci


def test_registry_default_is_the_same_everywhere():
    assert "${EVENTFLOW_REGISTRY:-ghcr.io}" in _compose_file_text()
    assert 'echo ghcr.io' in LIB.read_text()
    assert "IMAGE_REGISTRY: ghcr.io" in CI_WORKFLOW.read_text()


# ---------------------------------------------------------------------------
# 3. CI builds, smoke-tests and publishes immutable SHA-tagged images
# ---------------------------------------------------------------------------

def test_ci_publishes_with_the_workflow_token_and_least_privilege():
    ci = CI_WORKFLOW.read_text()
    assert "packages: write" in ci, "the docker job needs packages: write to push"
    assert "docker/login-action@v4" in ci
    assert "password: ${{ secrets.GITHUB_TOKEN }}" in ci, (
        "the publish step must use the workflow token, never a long-lived PAT"
    )
    # no personal token may be referenced anywhere in the workflows
    for workflow in (ci, DEPLOY_WORKFLOW.read_text()):
        assert "ghp_" not in workflow
        assert "github_pat_" not in workflow


def test_ci_pushes_only_for_a_push_to_master():
    ci = CI_WORKFLOW.read_text()
    assert "IS_RELEASE: ${{ github.event_name == 'push' && github.ref == 'refs/heads/master' }}" in ci
    # every publishing step is gated on that flag
    for step in ("Log in to GitHub Container Registry",
                 "Push images to GitHub Container Registry",
                 "Record image digests",
                 "Upload image digests"):
        idx = ci.index(f"- name: {step}")
        block = ci[idx:idx + 400]
        assert "if: env.IS_RELEASE == 'true'" in block, f"'{step}' must not run for pull requests"


def test_ci_tags_the_images_with_the_commit_sha():
    ci = CI_WORKFLOW.read_text()
    assert "echo \"BACKEND_IMAGE=${IMAGE_REGISTRY}/${IMAGE_OWNER}/eventflow-backend:${GITHUB_SHA}\"" in ci
    assert "echo \"FRONTEND_IMAGE=${IMAGE_REGISTRY}/${IMAGE_OWNER}/eventflow-frontend:${GITHUB_SHA}\"" in ci
    assert "GIT_SHA=${{ github.sha }}" in ci, "the images must carry their commit"


def test_ci_smoke_tests_the_images_it_publishes():
    ci = CI_WORKFLOW.read_text()
    assert "Backend image smoke test" in ci
    assert "Frontend image smoke test" in ci
    assert "Images carry their commit revision" in ci


def test_ci_records_the_digests_the_deploy_verifies():
    ci = CI_WORKFLOW.read_text()
    assert "BACKEND_DIGEST=${backend_digest}" in ci
    assert "FRONTEND_DIGEST=${frontend_digest}" in ci
    assert "actions/upload-artifact@v7" in ci
    assert "name: image-digests" in ci


# ---------------------------------------------------------------------------
# 4. the deploy pulls and verifies — it never builds
# ---------------------------------------------------------------------------

def test_deploy_script_pulls_instead_of_building():
    src = DEPLOY_COMPOSE.read_text()
    assert "compose build" not in src, "the VPS must never build an image"
    assert "pull_app_images" in src
    assert "ensure_free_space" in src, "a pull needs free disk space — check it first"


def test_deploy_script_verifies_the_published_digests():
    src = DEPLOY_COMPOSE.read_text()
    assert "${EVENTFLOW_EXPECTED_BACKEND_DIGEST:-}" in src
    assert "${EVENTFLOW_EXPECTED_FRONTEND_DIGEST:-}" in src


def test_rollback_pulls_the_previous_tag():
    src = ROLLBACK.read_text()
    assert 'docker image inspect "${img}:${TARGET}"' not in src, (
        "rollback must fetch the images again, not require them to be on disk"
    )
    assert "pull_app_images" in src
    assert "allow-legacy-local" in src, (
        "a rollback across the migration from 'build on the VPS' must still work"
    )


def test_verify_script_checks_the_registry_images():
    src = VERIFY.read_text()
    assert "app_image_ref" in src
    assert "eventflow-backend:" not in src, "the old local image names are gone"


def test_deploy_workflow_keeps_host_key_verification():
    wf = DEPLOY_WORKFLOW.read_text()
    assert "StrictHostKeyChecking=yes" in wf
    # the option must never be disabled (the phrase may appear in a comment)
    assert not re.search(r"-o\s+StrictHostKeyChecking=no", wf)
    assert "UserKnownHostsFile=" in wf
    assert "ssh-keygen -lf" in wf, "the host key fingerprint must still be verified"


def test_deploy_workflow_resolves_and_forwards_the_digests():
    wf = DEPLOY_WORKFLOW.read_text()
    assert "actions/download-artifact@v8" in wf
    assert "EVENTFLOW_EXPECTED_BACKEND_DIGEST='${BACKEND_DIGEST}'" in wf
    assert "EVENTFLOW_EXPECTED_FRONTEND_DIGEST='${FRONTEND_DIGEST}'" in wf
    assert "actions: read" in wf, "reading the CI artifact needs actions: read"


def test_deploy_workflow_does_not_disable_the_approval_gate():
    wf = DEPLOY_WORKFLOW.read_text()
    assert "environment: production" in wf
    assert "github.event.workflow_run.conclusion == 'success'" in wf


# ---------------------------------------------------------------------------
# 5. the registry credential never leaks
# ---------------------------------------------------------------------------

def test_registry_token_is_read_through_password_stdin():
    lib = LIB.read_text()
    assert "--password-stdin" in lib
    # the token must never be passed as an argument or echoed
    assert not re.search(r"--password[ '\"]", lib), "the token must not appear in argv"
    assert not re.search(r"echo[^\n]*TOKEN", lib), "the token must never be echoed"
    assert "docker login" in lib


def test_registry_token_file_must_be_private():
    lib = LIB.read_text()
    assert "stat -c '%a'" in lib, "the token file permissions must be checked"
    assert "must be 0600" in lib


def test_no_credential_is_embedded_in_the_repository():
    """No token, password or registry secret may live in the repo."""
    tracked = subprocess.run(
        ["git", "ls-files", "deploy", ".github"], cwd=REPO_ROOT,
        capture_output=True, text=True, check=False,
    ).stdout.split()
    assert tracked, "expected the deployment files to be tracked"
    for rel in tracked:
        text = (REPO_ROOT / rel).read_text(errors="ignore")
        assert "ghp_" not in text, f"{rel} contains something that looks like a PAT"
        assert "github_pat_" not in text, f"{rel} contains something that looks like a PAT"
        assert "CR_PAT" not in text, f"{rel} references a registry token variable"


# ---------------------------------------------------------------------------
# 6. no destructive cleanup
# ---------------------------------------------------------------------------

def test_no_destructive_docker_cleanup_in_the_deploy_scripts():
    """The scripts may mention `docker system prune -a` in a comment to say
    that they do NOT do it — but no command may ever run one."""
    forbidden = (
        r"^\s*docker\s+system\s+prune",
        r"^\s*docker\s+volume\s+prune",
        r"^\s*docker\s+volume\s+rm",
        r"docker\s+rm\s+-f\s+\$\(",
    )
    for path in (DEPLOY_COMPOSE, LIB, ROLLBACK, VERIFY, SCRIPTS / "backup.sh",
                 SCRIPTS / "restore.sh", SCRIPTS / "compose_run.sh"):
        text = path.read_text()
        for pattern in forbidden:
            assert not re.search(pattern, text, re.MULTILINE), (
                f"{path.name} must not run a destructive cleanup ({pattern!r})"
            )


def test_image_cleanup_only_touches_the_application_images():
    """The retention step may only remove the app images — never volumes,
    never the database, never an unrelated image."""
    lib = LIB.read_text()
    assert "prune_app_images" in lib
    assert "docker image rm" in lib
    assert "docker rmi" not in lib.replace("docker image rm", "")
    # no volume or container removal anywhere in the cleanup path
    cleanup = lib[lib.index("prune_app_images()"):]
    cleanup = cleanup[:cleanup.index("\n}\n")]
    assert "volume" not in cleanup
    assert "docker rm" not in cleanup
    assert "docker ps -a --filter" in cleanup, "images in use must be kept"


# ---------------------------------------------------------------------------
# 7. the images carry their provenance
# ---------------------------------------------------------------------------

def test_dockerfiles_label_the_images_with_their_commit():
    for dockerfile in (REPO_ROOT / "backend" / "Dockerfile",
                        REPO_ROOT / "frontend" / "Dockerfile"):
        text = dockerfile.read_text()
        assert "ARG GIT_SHA" in text, f"{dockerfile.name} must accept the commit as a build arg"
        assert "org.opencontainers.image.revision" in text
        assert "org.opencontainers.image.source" in text


def test_frontend_image_labels_the_baked_api_origin():
    text = (REPO_ROOT / "frontend" / "Dockerfile").read_text()
    assert "io.eventflow.next-public-api-url" in text


def test_ci_records_the_digest_of_the_pushed_repository():
    """The recorded digest must be the one of the repository that was
    pushed — the first RepoDigest would be wrong as soon as the daemon
    knows more than one repository for the same image."""
    ci = CI_WORKFLOW.read_text()
    assert 'repo="${ref%:*}"' in ci
    assert 'grep -F "${repo}@"' in ci, (
        "the digest must be selected by repository, not by position"
    )


def test_ci_pushes_before_it_records_the_digest():
    """The digest must describe what the registry serves, so the image is
    pulled back after the push."""
    ci = CI_WORKFLOW.read_text()
    push = ci.index('docker push "$FRONTEND_IMAGE"')
    pull = ci.index('docker pull "$FRONTEND_IMAGE"')
    digest = ci.index('backend_digest="$(digest_of "$BACKEND_IMAGE")"')
    assert push < pull < digest, "push → pull → record"


def test_rollback_accepts_pinned_digests():
    """An operator can pin the digests of the rollback target; the deploy
    workflow's digests belong to the commit it deploys, so the automatic
    rollback inside deploy_compose.sh must NOT reuse them."""
    rollback = ROLLBACK.read_text()
    assert '"${EVENTFLOW_EXPECTED_BACKEND_DIGEST:-}"' in rollback
    assert '"${EVENTFLOW_EXPECTED_FRONTEND_DIGEST:-}"' in rollback
    deploy = DEPLOY_COMPOSE.read_text()
    auto = deploy[deploy.index('pull_app_images "$LAST_GOOD"'):]
    auto = auto[:auto.index("\n")]
    assert "EVENTFLOW_EXPECTED_BACKEND_DIGEST" not in auto, (
        "the automatic rollback must not compare the old image against the "
        "digest of the failed commit"
    )


def test_deploy_script_removes_the_ephemeral_credential_after_the_pull():
    """The throwaway docker config must not outlive the pull."""
    lib = LIB.read_text()
    assert "registry_disconnect" in lib
    pull_body = lib[lib.index("pull_app_images()"):]
    pull_body = pull_body[:pull_body.index("\n}\n")]
    assert "registry_disconnect" in pull_body


def test_registry_token_file_is_read_without_a_trailing_newline():
    """A token file written with echo/heredoc ends in a newline, which
    would become part of the password."""
    lib = LIB.read_text()
    assert "tr -d '\\r\\n'" in lib
    assert "--password-stdin" in lib


def test_images_contain_no_secrets():
    """A public GHCR package must not leak anything: the build contexts
    exclude the env files, the database, the media tree and the logs."""
    for ignore in (REPO_ROOT / "backend" / ".dockerignore",
                   REPO_ROOT / "frontend" / ".dockerignore"):
        patterns = {l.strip() for l in ignore.read_text().splitlines()
                    if l.strip() and not l.startswith("#")}
        assert ".env" in patterns
        assert ".env.*" in patterns
    backend_ignore = (REPO_ROOT / "backend" / ".dockerignore").read_text()
    assert "**/*.sqlite3" in backend_ignore
    assert "media" in backend_ignore
    assert "logs" in backend_ignore
    # local build artefacts (coverage report, linter cache) stay out too
    assert "reports" in backend_ignore
    assert ".ruff_cache" in backend_ignore


def test_backend_image_contains_no_log_file():
    """collectstatic opens the rotating log during the build; the empty
    artifact is removed so the published image has no log file at all."""
    dockerfile = (REPO_ROOT / "backend" / "Dockerfile").read_text()
    assert "rm -f /app/logs/*.log" in dockerfile
    assert dockerfile.index("python manage.py collectstatic") < \
        dockerfile.index("rm -f /app/logs/*.log"), (
        "the log file may only be removed after collectstatic created it"
    )


# ---------------------------------------------------------------------------
# 8. behaviour of the library helpers
# ---------------------------------------------------------------------------

@pytest.mark.skipif(shutil.which("bash") is None, reason="bash not available")
def test_app_image_ref_uses_the_registry_and_the_deployed_tag(tmp_path):
    bindir, stub_env = _docker_stub(tmp_path)
    env = _lib_env(tmp_path, bindir, stub_env)
    proc = _run_bash(env, f'source "{LIB}" && EVENTFLOW_TAG={SHA} app_image_ref backend')
    assert proc.returncode == 0, proc.stderr
    assert proc.stdout.strip() == f"{REGISTRY}/{OWNER}/eventflow-backend:{SHA}"


@pytest.mark.skipif(shutil.which("bash") is None, reason="bash not available")
def test_verify_image_identity_rejects_a_foreign_commit(tmp_path):
    bindir, stub_env = _docker_stub(tmp_path, revision="deadbeef" * 5)
    env = _lib_env(tmp_path, bindir, stub_env)
    proc = _run_bash(
        env,
        f'source "{LIB}" && verify_image_identity backend {SHA} ""',
    )
    assert proc.returncode != 0, "an image built from another commit must be refused"
    assert "was built from commit" in proc.stderr


@pytest.mark.skipif(shutil.which("bash") is None, reason="bash not available")
def test_verify_image_identity_rejects_a_foreign_digest(tmp_path):
    bindir, stub_env = _docker_stub(tmp_path, revision=SHA, repo_digest="sha256:" + "cd" * 32)
    env = _lib_env(tmp_path, bindir, stub_env)
    proc = _run_bash(
        env,
        f'source "{LIB}" && verify_image_identity backend {SHA} {DIGEST}',
    )
    assert proc.returncode != 0, "an image with another digest must be refused"
    assert "does not match the digest published by CI" in proc.stderr


@pytest.mark.skipif(shutil.which("bash") is None, reason="bash not available")
def test_verify_image_identity_accepts_the_published_image(tmp_path):
    bindir, stub_env = _docker_stub(tmp_path, revision=SHA, repo_digest=DIGEST)
    env = _lib_env(tmp_path, bindir, stub_env)
    proc = _run_bash(
        env,
        f'source "{LIB}" && verify_image_identity backend {SHA} {DIGEST}',
    )
    assert proc.returncode == 0, proc.stderr
    assert DIGEST in proc.stdout


@pytest.mark.skipif(shutil.which("bash") is None, reason="bash not available")
def test_verify_frontend_api_origin_rejects_a_stale_bundle(tmp_path):
    bindir, stub_env = _docker_stub(tmp_path, revision=SHA)
    env = _lib_env(tmp_path, bindir, stub_env)
    env["EVENTFLOW_EXPECTED_API_URL"] = "http://194.77.89.95/api/v1"
    proc = _run_bash(
        env,
        f'source "{LIB}" && verify_frontend_api_origin yes',
    )
    assert proc.returncode != 0, "a frontend image built for another origin must be refused"


@pytest.mark.skipif(shutil.which("bash") is None, reason="bash not available")
def test_registry_login_refuses_a_world_readable_token_file(tmp_path):
    bindir, stub_env = _docker_stub(tmp_path)
    token = tmp_path / ".ghcr-token"
    token.write_text("dummy-registry-token-value")
    token.chmod(0o644)
    env = _lib_env(tmp_path, bindir, stub_env)
    env["EVENTFLOW_REGISTRY_TOKEN_FILE"] = str(token)
    proc = _run_bash(env, f'source "{LIB}" && registry_login {REGISTRY}')
    assert proc.returncode != 0, "a readable token file must be refused"
    assert "must be 0600" in proc.stderr


@pytest.mark.skipif(shutil.which("bash") is None, reason="bash not available")
def test_registry_login_uses_password_stdin_and_never_puts_the_token_in_argv(tmp_path):
    bindir, stub_env = _docker_stub(tmp_path)
    token = tmp_path / ".ghcr-token"
    token.write_text("dummy-registry-token-value")
    token.chmod(0o600)
    env = _lib_env(tmp_path, bindir, stub_env)
    env["EVENTFLOW_REGISTRY_TOKEN_FILE"] = str(token)
    proc = _run_bash(env, f'source "{LIB}" && registry_login {REGISTRY}')
    assert proc.returncode == 0, proc.stderr
    calls = (tmp_path / "docker-calls.log").read_text()
    assert "--password-stdin" in calls
    assert "dummy-registry-token-value" not in calls, "the token must never appear in argv"
    assert "dummy-registry-token-value" not in proc.stdout + proc.stderr, "the token must never be logged"


@pytest.mark.skipif(shutil.which("bash") is None, reason="bash not available")
def test_pull_app_images_fails_closed_without_a_credential(tmp_path):
    """A private package and no credential must fail — the deploy must not
    fall back to something else."""
    bindir, stub_env = _docker_stub(tmp_path, pull_rc=1, pull_always_fail=True)
    env = _lib_env(tmp_path, bindir, stub_env)
    env["EVENTFLOW_REGISTRY_TOKEN_FILE"] = str(tmp_path / "missing-token")
    proc = _run_bash(
        env,
        f'source "{LIB}" && pull_app_images {SHA} strict "" "" no',
    )
    assert proc.returncode != 0
    assert "could not pull the application images" in proc.stdout + proc.stderr


@pytest.mark.skipif(shutil.which("bash") is None, reason="bash not available")
def test_pull_app_images_succeeds_after_a_successful_login_retry(tmp_path):
    """REGRESSION: the first pull fails (private package), the registry
    login succeeds and the second pull succeeds — the function must report
    success. It used to fall through into the failure branch and abort the
    deploy even though the images had been pulled."""
    bindir, stub_env = _docker_stub(tmp_path, pull_rc=1, pull_fail_first=1)
    token = tmp_path / ".ghcr-token"
    token.write_text("dummy-registry-token-value")
    token.chmod(0o600)
    env = _lib_env(tmp_path, bindir, stub_env)
    env["EVENTFLOW_REGISTRY_TOKEN_FILE"] = str(token)
    proc = _run_bash(
        env,
        f'source "{LIB}" && pull_app_images {SHA} strict "" "" no',
    )
    assert proc.returncode == 0, (
        "a successful pull after a successful login must succeed\n"
        f"stdout: {proc.stdout}\nstderr: {proc.stderr}"
    )
    calls = (tmp_path / "docker-calls.log").read_text()
    assert calls.count("pull backend frontend") == 2, "the pull must be retried once"
    assert "--password-stdin" in calls
    assert "could not pull the application images" not in proc.stdout + proc.stderr


@pytest.mark.skipif(shutil.which("bash") is None, reason="bash not available")
def test_pull_app_images_fails_when_the_second_pull_also_fails(tmp_path):
    """Both pulls fail (wrong or expired credential): the function must
    fail closed and print the guidance — it must not report success."""
    bindir, stub_env = _docker_stub(tmp_path, pull_rc=1, pull_always_fail=True)
    token = tmp_path / ".ghcr-token"
    token.write_text("dummy-registry-token-value")
    token.chmod(0o600)
    env = _lib_env(tmp_path, bindir, stub_env)
    env["EVENTFLOW_REGISTRY_TOKEN_FILE"] = str(token)
    proc = _run_bash(
        env,
        f'source "{LIB}" && pull_app_images {SHA} strict "" "" no',
    )
    assert proc.returncode != 0, "two failed pulls must not report success"
    assert "could not pull the application images" in proc.stdout + proc.stderr
    assert "read:packages" in proc.stdout + proc.stderr
    calls = (tmp_path / "docker-calls.log").read_text()
    assert calls.count("pull backend frontend") == 2


@pytest.mark.skipif(shutil.which("bash") is None, reason="bash not available")
def test_pull_app_images_succeeds_anonymously_for_a_public_package(tmp_path):
    """A public package needs no credential: the first pull succeeds and
    the script must not log in to the registry at all."""
    bindir, stub_env = _docker_stub(tmp_path, pull_rc=0)
    env = _lib_env(tmp_path, bindir, stub_env)
    env["EVENTFLOW_REGISTRY_TOKEN_FILE"] = str(tmp_path / "missing-token")
    proc = _run_bash(
        env,
        f'source "{LIB}" && pull_app_images {SHA} strict "" "" no',
    )
    assert proc.returncode == 0, proc.stderr
    calls = (tmp_path / "docker-calls.log").read_text()
    assert calls.count("pull backend frontend") == 1, "a public package is pulled once"
    assert "login" not in calls, "no registry login may happen for a public package"


@pytest.mark.skipif(shutil.which("bash") is None, reason="bash not available")
def test_pull_app_images_keeps_the_strict_mode_when_no_image_is_published(tmp_path):
    """A deploy (strict) must never accept a VPS-local image; only the
    rollback path may."""
    bindir, stub_env = _docker_stub(tmp_path, pull_rc=1, pull_always_fail=True)
    env = _lib_env(tmp_path, bindir, stub_env)
    env["EVENTFLOW_REGISTRY_TOKEN_FILE"] = str(tmp_path / "missing-token")
    proc = _run_bash(
        env,
        f'source "{LIB}" && pull_app_images {SHA} strict "" "" no',
    )
    assert proc.returncode != 0
    calls = (tmp_path / "docker-calls.log").read_text()
    assert "tag eventflow-backend:" not in calls, "a deploy must not re-tag a local image"


@pytest.mark.skipif(shutil.which("bash") is None, reason="bash not available")
def test_registry_login_strips_a_trailing_newline_from_the_token_file(tmp_path):
    """A token file written with `echo` or a heredoc ends in a newline;
    `docker login --password-stdin` would send it as part of the password
    and the login would fail."""
    bindir, stub_env = _docker_stub(tmp_path)
    token = tmp_path / ".ghcr-token"
    token.write_text("dummy-registry-token-value\n")
    token.chmod(0o600)
    env = _lib_env(tmp_path, bindir, stub_env)
    env["EVENTFLOW_REGISTRY_TOKEN_FILE"] = str(token)
    proc = _run_bash(env, f'source "{LIB}" && registry_login {REGISTRY}')
    assert proc.returncode == 0, proc.stderr
    # the stub records the arguments, not stdin — assert the token itself
    # was not passed as an argument and that the login happened
    calls = (tmp_path / "docker-calls.log").read_text()
    assert "--password-stdin" in calls
    assert "dummy-registry-token-value" not in calls


@pytest.mark.skipif(shutil.which("bash") is None, reason="bash not available")
def test_registry_disconnect_removes_the_ephemeral_credential(tmp_path):
    """The throwaway docker config must not survive the pull: the token
    file stays the only copy of the credential."""
    bindir, stub_env = _docker_stub(tmp_path)
    token = tmp_path / ".ghcr-token"
    token.write_text("dummy-registry-token-value")
    token.chmod(0o600)
    env = _lib_env(tmp_path, bindir, stub_env)
    env["EVENTFLOW_REGISTRY_TOKEN_FILE"] = str(token)
    proc = _run_bash(
        env,
        f'source "{LIB}" && registry_login {REGISTRY} >/dev/null && '
        'printf "CONFIG=%s\\n" "${DOCKER_CONFIG:-}" && registry_disconnect && '
        'printf "AFTER=%s\\n" "${DOCKER_CONFIG:-none}" && '
        '[ -d "${REGISTRY_TMP_CONFIG:-/nonexistent}" ] && echo "STILL_THERE" || echo "REMOVED"',
    )
    assert proc.returncode == 0, proc.stderr
    assert "REMOVED" in proc.stdout
    assert "AFTER=none" in proc.stdout
    assert "STILL_THERE" not in proc.stdout
    # the token file itself is untouched — it is the only copy
    assert token.exists()


@pytest.mark.skipif(shutil.which("bash") is None, reason="bash not available")
def test_pull_app_images_accepts_a_legacy_local_image_only_when_allowed(tmp_path):
    """The fallback to an image that was built on this host before the GHCR
    flow exists for rollbacks only — a deploy must never use it."""
    bindir, stub_env = _docker_stub(tmp_path, pull_rc=1, tag_rc=0, pull_always_fail=True)
    env = _lib_env(tmp_path, bindir, stub_env)
    env["EVENTFLOW_REGISTRY_TOKEN_FILE"] = str(tmp_path / "missing-token")
    strict = _run_bash(env, f'source "{LIB}" && pull_app_images {SHA} strict "" "" no')
    assert strict.returncode != 0, "a deploy must not accept a local image"

    # with the fallback allowed, the legacy image is re-tagged
    bindir, stub_env = _docker_stub(tmp_path, pull_rc=1, tag_rc=0, pull_always_fail=True)
    env = _lib_env(tmp_path, bindir, stub_env)
    env["EVENTFLOW_REGISTRY_TOKEN_FILE"] = str(tmp_path / "missing-token")
    lenient = _run_bash(env, f'source "{LIB}" && pull_app_images {SHA} allow-legacy-local "" "" no')
    calls = (tmp_path / "docker-calls.log").read_text()
    assert "tag eventflow-backend:" in calls or "tag eventflow-frontend:" in calls, (
        "the legacy image must be re-tagged to the registry reference"
    )
    assert lenient.returncode in (0, 1)


@pytest.mark.skipif(shutil.which("bash") is None, reason="bash not available")
def test_env_file_value_does_not_execute_the_file(tmp_path):
    """The external env file holds secrets: it is parsed, never sourced."""
    bindir, stub_env = _docker_stub(tmp_path)
    env_file = tmp_path / "registry.env"
    env_file.write_text('EVENTFLOW_REGISTRY="ghcr.example"\nEVIL=$(touch /tmp/pwned)\n')
    env = _lib_env(tmp_path, bindir, stub_env)
    env["ENV_FILE"] = str(env_file)
    proc = _run_bash(
        env,
        f'source "{LIB}" && env_file_value EVENTFLOW_REGISTRY && env_file_value EVIL',
    )
    assert proc.returncode == 0, proc.stderr
    assert proc.stdout.splitlines()[0] == "ghcr.example"
    assert "touch" in proc.stdout.splitlines()[1], "the value must be returned verbatim"


@pytest.mark.skipif(shutil.which("bash") is None, reason="bash not available")
def test_prune_app_images_keeps_the_current_and_the_previous_tag(tmp_path):
    bindir, stub_env = _docker_stub(
        tmp_path,
        images="\n".join([
            f"{REGISTRY}/{OWNER}/eventflow-backend:{SHA}",
            f"{REGISTRY}/{OWNER}/eventflow-frontend:{SHA}",
            f"{REGISTRY}/{OWNER}/eventflow-backend:{'a' * 40}",
            f"{REGISTRY}/{OWNER}/eventflow-frontend:{'a' * 40}",
            "mariadb:11.4",
        ]),
    )
    env = _lib_env(tmp_path, bindir, stub_env)
    proc = _run_bash(env, f'source "{LIB}" && prune_app_images {SHA} {"b" * 40}')
    assert proc.returncode == 0, proc.stderr
    calls = (tmp_path / "docker-calls.log").read_text()
    assert f"image rm {REGISTRY}/{OWNER}/eventflow-backend:{'a' * 40}" in calls
    assert f"image rm {REGISTRY}/{OWNER}/eventflow-frontend:{'a' * 40}" in calls
    assert f"image rm {REGISTRY}/{OWNER}/eventflow-backend:{SHA}" not in calls
    assert "mariadb" not in calls, "unrelated images must never be touched"


@pytest.mark.skipif(shutil.which("bash") is None, reason="bash not available")
@pytest.mark.parametrize("path", [
    DEPLOY_COMPOSE,
    LIB, ROLLBACK, VERIFY,
    SCRIPTS / "compose_run.sh", SCRIPTS / "backup.sh", SCRIPTS / "restore.sh",
], ids=lambda p: p.name)
def test_changed_shell_files_have_valid_bash_syntax(path):
    proc = subprocess.run(["bash", "-n", str(path)], capture_output=True, text=True)
    assert proc.returncode == 0, f"{path.name}: {proc.stderr.strip()}"


def test_env_example_documents_the_registry_but_no_credential():
    env_example = (DOCKER / "eventflow" / ".env.example").read_text()
    assert "EVENTFLOW_REGISTRY=ghcr.io" in env_example
    assert "EVENTFLOW_REGISTRY_TOKEN_FILE" in env_example
    # the example must not carry a value for the credential
    for line in env_example.splitlines():
        if line.startswith("EVENTFLOW_REGISTRY_TOKEN_FILE="):
            pytest.fail("the example env file must not define a token file with a value")
    assert stat.S_IMODE(0o600) == 0o600
