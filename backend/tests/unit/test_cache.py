import pytest
from unittest.mock import patch, MagicMock, call
from core.cache import CacheService, build_cache_key


class TestCacheService:
    def test_build_cache_key_simple(self):
        key = build_cache_key("test", 1, 2)
        assert key.startswith("test:1:2")

    def test_get_or_set_calls_func_on_miss(self):
        func = MagicMock(return_value="computed")
        with patch("core.cache.cache.get", return_value=None), \
             patch("core.cache.cache.set") as mock_set:
            result = CacheService.get_or_set("test_key", func, 300)
            assert result == "computed"
            func.assert_called_once()
            mock_set.assert_called_once_with("test_key", "computed", 300)

    def test_get_or_set_returns_cached(self):
        func = MagicMock(return_value="computed")
        with patch("core.cache.cache.get", return_value="cached_value"):
            result = CacheService.get_or_set("test_key", func, 300)
            assert result == "cached_value"
            func.assert_not_called()

    def test_clear_uses_pattern_invalidation(self):
        with patch("core.cache.cache") as mock_cache:
            CacheService._TRACKED_KEYS.clear()
            CacheService.clear()
            mock_cache.delete_pattern.assert_called_once_with("settings:*")
            mock_cache.clear.assert_not_called()

    def test_clear_only_deletes_prefixed_keys(self):
        with patch("core.cache.cache") as mock_cache:
            # LocMemCache-style backend: no pattern deletion support.
            mock_cache.delete_pattern.side_effect = AttributeError("unsupported")
            CacheService._TRACKED_KEYS.clear()
            CacheService._TRACKED_KEYS.update({
                "settings:organization:1",
                "settings:profile:1",
                "dashboard:summary:1",
            })
            deleted = CacheService.clear()
            # Must never wipe the shared cache (throttle/lockout counters).
            mock_cache.clear.assert_not_called()
            assert deleted == 2
            mock_cache.delete.assert_has_calls(
                [call("settings:organization:1"), call("settings:profile:1")]
            )
            # Non-settings keys are left intact.
            assert "dashboard:summary:1" in CacheService._TRACKED_KEYS
            assert "settings:organization:1" not in CacheService._TRACKED_KEYS
        CacheService._TRACKED_KEYS.clear()

    def test_clear_respects_custom_prefix(self):
        with patch("core.cache.cache") as mock_cache:
            mock_cache.delete_pattern.side_effect = AttributeError("unsupported")
            CacheService._TRACKED_KEYS.clear()
            CacheService._TRACKED_KEYS.update({"dashboard:summary:1", "settings:profile:1"})
            deleted = CacheService.clear(prefix="dashboard")
            mock_cache.clear.assert_not_called()
            assert deleted == 1
            mock_cache.delete.assert_called_once_with("dashboard:summary:1")
            assert "settings:profile:1" in CacheService._TRACKED_KEYS
        CacheService._TRACKED_KEYS.clear()

    def test_clear_survives_backend_errors(self):
        with patch("core.cache.cache") as mock_cache:
            mock_cache.delete_pattern.side_effect = RuntimeError("backend down")
            mock_cache.delete.side_effect = RuntimeError("backend down")
            CacheService._TRACKED_KEYS.clear()
            CacheService._TRACKED_KEYS.add("settings:profile:1")
            assert CacheService.clear() == 0
            mock_cache.clear.assert_not_called()
        CacheService._TRACKED_KEYS.clear()
