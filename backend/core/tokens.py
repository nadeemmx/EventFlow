"""A blacklist-aware access token.

simplejwt only mixes ``BlacklistMixin`` into ``RefreshToken``
(``tokens.py:376``), so ``AccessToken`` never consults the blacklist table.
That meant logout blacklisted the refresh token but the access token kept
authenticating until it expired — QA-TEST-REPORT-ROLES.md F-3.

Blacklisting alone would have been a no-op: the check lives in
``BlacklistMixin.verify``, which ``AccessToken`` never calls. So revoking an
access token needs both halves — write the jti to the blacklist on logout, and
validate against it here.
"""
from rest_framework_simplejwt.tokens import AccessToken, BlacklistMixin


class BlacklistCheckingAccessToken(BlacklistMixin["BlacklistCheckingAccessToken"],  # noqa: E501
                                   AccessToken):
    """``AccessToken`` that rejects tokens present in the blacklist table."""

    pass
