import pytest
from unittest.mock import patch, MagicMock
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

    def test_clear_called(self):
        with patch("core.cache.cache.clear") as mock_clear:
            CacheService.clear()
            mock_clear.assert_called_once()
