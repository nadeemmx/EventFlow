"""Regression guards for P0-2 (dependency EOL / known CVEs).

Before the fix the backend pinned Django 4.2.16 — an LTS branch that reached
end-of-life in April 2026 and carried 60 known CVEs — plus a PyJWT that
carried 21. These tests assert the *floor* for every package that the
pre-production vulnerability scan flagged, so a future `pip install` or a
revert cannot silently reintroduce an EOL or known-vulnerable version.

They intentionally check installed versions rather than requirements.txt:
the failure mode that matters is what actually runs.
"""
import re
from importlib import metadata

import django
import pytest

# package name -> (minimum version that clears the audited CVEs, reason)
FLOORS = {
    # 4.2 LTS is EOL (Apr 2026); 5.2 is the current LTS and the only LTS line
    # that supports the Python 3.14 interpreter used by this project.
    "Django": ("5.2.0", "4.2 LTS is EOL; 5.2 LTS supported to Apr 2028"),
    "djangorestframework": ("3.17.2", "PYSEC-2026-3827 / 3828"),
    "djangorestframework-simplejwt": ("5.5.1", "PYSEC-2026-1305"),
    "PyJWT": ("2.15.0", "PYSEC-2026-4183 and related"),
    "urllib3": ("2.8.0", "PYSEC-2026-4175 / 4176 / 4177"),
    "multidict": ("6.9.1", "CVE-2026-104874"),
}


def _parse(version: str):
    """Int-tuple version key, tolerant of suffixes like `.post1` / `rc1`."""
    return tuple(int(p) for p in re.findall(r"\d+", version)[:3])


def test_django_is_a_supported_lts():
    assert _parse(django.get_version()) >= (5, 2, 0), (
        f"Django {django.get_version()} is below the supported 5.2 LTS floor. "
        "4.2 LTS reached EOL in April 2026 and no longer receives security patches."
    )


@pytest.mark.parametrize("package", sorted(FLOORS))
def test_package_meets_minimum_fixed_version(package):
    minimum, reason = FLOORS[package]
    installed = metadata.version(package)
    assert _parse(installed) >= _parse(minimum), (
        f"{package}=={installed} is below the fixed version {minimum} ({reason})."
    )
