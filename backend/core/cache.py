from django.core.cache import cache
import hashlib
import json


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

    @staticmethod
    def get_or_set(key, get_func, ttl=300):
        cached = cache.get(key)
        if cached is not None:
            return cached
        value = get_func()
        cache.set(key, value, ttl)
        return value

    @staticmethod
    def clear():
        cache.clear()
