"""Regression tests for QA-TEST-REPORT.md P1-3 (P1) — backup recoverability.

The report listed three gaps. Two were real and are now fixed:

1. **No restore script** — "a backup nobody has rehearsed restoring is not a
   recovery plan." Added ``deploy/scripts/restore.sh``.
2. **Backups not copied off the host** — a host loss took the backups with it.
   ``backup.sh`` now optionally rsyncs to ``OFFSITE_REMOTE`` and fails loudly
   when the copy fails or is unconfigured.

The third sub-claim was **inaccurate** and is asserted as such here rather
than "fixed": the report said ``cron-jobs.sh`` schedules no backup job, but no
such file exists — the real file, ``deploy/scripts/crontab.txt``, *does*
schedule ``backup.sh`` daily at 02:00 (line 29). Pinning that so it cannot
silently regress either way.
"""
import shutil
import subprocess
from pathlib import Path

import pytest

# backend/tests/unit/this_file.py -> repo root is parents[3]
REPO_ROOT = Path(__file__).resolve().parents[3]
DEPLOY = REPO_ROOT / "deploy" / "scripts"


@pytest.mark.skipif(shutil.which("bash") is None, reason="bash not available")
def test_scripts_have_valid_bash_syntax():
    for name in ("backup.sh", "restore.sh"):
        proc = subprocess.run(
            ["bash", "-n", str(DEPLOY / name)],
            capture_output=True, text=True,
        )
        assert proc.returncode == 0, f"{name}: {proc.stderr.strip()}"


def test_restore_script_exists_and_is_executable():
    restore = DEPLOY / "restore.sh"
    assert restore.is_file(), "restore.sh is missing"
    assert restore.stat().st_mode & 0o111, "restore.sh is not executable"


def test_restore_script_refuses_a_live_restore_without_explicit_confirmation():
    """The destructive path must require --yes, so a mistyped command cannot
    overwrite production."""
    src = (DEPLOY / "restore.sh").read_text()
    assert "ASSUME_YES" in src
    assert "--yes" in src
    assert "REFUSED" in src
    # verification must happen before anything is written
    assert src.index("verify_archive \"$src\"") < src.index("OVERWRITE")


def test_restore_script_verifies_integrity_before_restoring():
    src = (DEPLOY / "restore.sh").read_text()
    assert "gzip -t" in src
    assert "integrity check FAILED" in src


def test_backup_script_copies_off_site():
    src = (DEPLOY / "backup.sh").read_text()
    assert "OFFSITE_REMOTE" in src
    assert "rsync" in src
    # a failed off-site copy must not be silent
    assert "off-site copy FAILED" in src


def test_backup_cron_job_is_scheduled():
    """Pins the scheduling the report claimed was missing (it was not: the
    report cited a non-existent cron-jobs.sh)."""
    cron = (DEPLOY / "crontab.txt").read_text()
    assert "backup.sh" in cron
    # daily at 02:00
    assert any(
        line.startswith("0 2 * * *") and "backup.sh" in line
        for line in cron.splitlines()
    ), "daily 02:00 backup job is not scheduled"
