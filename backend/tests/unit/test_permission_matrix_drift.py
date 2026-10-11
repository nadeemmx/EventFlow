"""Regression tests for QA-TEST-REPORT-ROLES.md F-2 (P2).

``MODULE_PERMISSIONS["reports"]`` used to declare ``financial``,
``operational`` and ``subscription`` — actions ``ReportViewSet`` never
defined, so all three 404'd for every role including the OWNER they granted.
Fail-closed, so not a security hole, but matrix drift that would mislead an
access-control audit.

Writing the drift check surfaced a **second instance of the same defect**
that the report missed: ``tenants.settings`` pointed at
``TenantViewSet.tenant_settings``, a plain method with no ``@action`` and
therefore no route. Both are removed.

The check is deliberately general — it validates the whole matrix against the
live router — so the next dead entry fails here instead of quietly 404ing.
"""
from config.api_router import api_router
from permissions.module_access import MODULE_PERMISSIONS

# DRF's ModelViewSet always exposes these regardless of @action decorators.
STANDARD_ACTIONS = {"list", "retrieve", "create", "update", "partial_update", "destroy"}

# Modules in the matrix that are served by plain APIViews rather than router
# ViewSets, so they have no entry in api_router.registry to check against.
# Kept explicit (and asserted minimal) so this cannot become a blanket excuse.
NON_VIEWSET_MODULES = {"dashboard"}


def _real_actions_by_module():
    """Map ``module_name`` -> the set of action names it actually routes.

    Uses each extra action's method ``__name__`` (``mark_in_progress``), which
    is what ``view.action`` carries and what the matrix uses — NOT the router's
    ``url_name`` (``mark-in-progress``), which is hyphenated.
    """
    out = {}
    for _prefix, viewset, _basename in api_router.registry:
        module_name = getattr(viewset, "module_name", None)
        if not module_name:
            continue
        names = set(STANDARD_ACTIONS)
        names.update(action.__name__ for action in viewset.get_extra_actions())
        out[module_name] = names
    return out


def test_non_viewset_exception_list_is_still_accurate():
    real = _real_actions_by_module()
    stale = NON_VIEWSET_MODULES - set(MODULE_PERMISSIONS) | (
        NON_VIEWSET_MODULES & set(real))
    assert not stale, (
        f"NON_VIEWSET_MODULES is out of date: {sorted(stale)} now resolve to a "
        "ViewSet, or are no longer in the matrix")


def test_every_declared_permission_action_exists_on_its_viewset():
    real = _real_actions_by_module()
    problems = []
    for module, actions in MODULE_PERMISSIONS.items():
        if module in NON_VIEWSET_MODULES:
            continue
        if module not in real:
            problems.append(f"{module}: no viewset registers module_name={module!r}")
            continue
        for action in actions:
            if action not in real[module]:
                problems.append(
                    f"{module}.{action}: declared in MODULE_PERMISSIONS but "
                    f"not routed")
    assert not problems, "dead permission entries:\n  " + "\n  ".join(problems)


def test_the_three_dead_report_actions_are_gone():
    """The specific F-2 drift, pinned so it cannot come back."""
    for dead in ("financial", "operational", "subscription"):
        assert dead not in MODULE_PERMISSIONS["reports"], (
            f"reports.{dead} has no matching @action on ReportViewSet")


def test_other_dead_entries_found_by_this_check_are_gone():
    """Two more instances of the same defect, found when this test was written
    and deliberately removed with the report's three."""
    assert "settings" not in MODULE_PERMISSIONS["tenants"], (
        "TenantViewSet.tenant_settings has no @action, so it is not routed")
    assert "read" not in MODULE_PERMISSIONS["settings"], (
        "SettingsViewSet is a GenericViewSet with no list/retrieve and no "
        "@action named read")


def test_absent_matrix_keys_deny_by_default():
    """Documents the *opposite* drift direction, which is intentionally left
    alone here.

    ``ModuleAccessPermission`` does ``module_perms.get(action, [])`` and then
    ``role in allowed``, so an action missing from the matrix is denied for
    every non-SUPER_ADMIN role. That is fail-closed and therefore safe, unlike
    the dead entries above (which advertised access to routes that 404'd).
    A few extras are currently absent (``tenants.activate/disable/suspend``,
    ``payments.create_order/verify``); *granting* those is an access-control
    decision that belongs with a product owner, not a drift cleanup, so this
    test only pins the deny-by-default behaviour rather than the current set.
    """
    from permissions.module_access import ModuleAccessPermission
    from core.choices import UserRole

    class _View:
        module_name = "reports"
        action = "this_action_does_not_exist"

    class _User:
        is_authenticated = True
        role = UserRole.OWNER

    class _Req:
        user = _User()
        method = "GET"

    assert ModuleAccessPermission().has_permission(_Req(), _View()) is False
    # SUPER_ADMIN still short-circuits regardless of the matrix.
    _User.role = UserRole.SUPER_ADMIN
    assert ModuleAccessPermission().has_permission(_Req(), _View()) is True
