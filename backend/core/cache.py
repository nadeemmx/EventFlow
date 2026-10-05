from django.core.cache import cache
import hashlib
import json
import threading


def build_cache_key(prefix, *args, **kwargs):
    key = f"{prefix}:"
    if args:
        key += ":".join(str(a) for a in args)
    if kwargs:
        sorted_kwargs = sorted(kwargs.items())
        key += ":" + hashlib.md5(json.dumps(sorted_kwargs, sort_keys=True).encode()).hexdigest()
    return key


class CacheService:
    DASHBOARD_TTL = 300
    REPORT_TTL = 600
    SETTINGS_TTL = 900
    LOOKUP_TTL = 3600

    # Best-effort registry of keys this service has written, used to
    # invalidate selectively on backends without pattern deletion
    # (e.g. LocMemCache). Bounded to avoid unbounded growth.
    _TRACKED_KEYS = set()
    _TRACKED_LIMIT = 5000
    _lock = threading.Lock()

    @classmethod
    def _track_key(cls, key):
        with cls._lock:
            if len(cls._TRACKED_KEYS) >= cls._TRACKED_LIMIT:
                cls._TRACKED_KEYS.clear()
            cls._TRACKED_KEYS.add(key)

    @staticmethod
    def get_or_set(key, get_func, ttl=300):
        cached = cache.get(key)
        if cached is not None:
            return cached
        value = get_func()
        cache.set(key, value, ttl)
        CacheService._track_key(key)
        return value

    @staticmethod
    def clear(prefix="settings"):
        """Invalidate only the cache keys written under ``prefix``.

        Never wipes the whole cache: the shared backend also holds
        brute-force lockout markers and DRF throttle counters, and
        clearing those would disable login rate limiting.

        Args:
            prefix: key prefix to invalidate (default ``settings``,
                matching the keys this service uses for settings data).

        Returns:
            Number of keys deleted (best effort).
        """
        pattern = f"{prefix}:"
        deleted = 0

        # 1) Backends that support pattern deletion (django-redis).
        try:
            cache.delete_pattern(pattern + "*")
        except Exception:
            pass

        # 2) Backends without pattern support (LocMemCache, local Redis
        #    fallback): delete the keys this service knows about.
        with CacheService._lock:
            keys = [k for k in CacheService._TRACKED_KEYS if k.startswith(pattern)]
            CacheService._TRACKED_KEYS.difference_update(keys)
        for key in keys:
            try:
                cache.delete(key)
                deleted += 1
            except Exception:
                pass

        return deleted
