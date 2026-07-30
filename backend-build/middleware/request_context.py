from django.utils.functional import SimpleLazyObject


def get_current_request():
    import warnings
    warnings.warn("Use request.tenant directly instead of get_current_tenant()", DeprecationWarning)
    return None


def get_current_user():
    import warnings
    warnings.warn("Access request.user directly", DeprecationWarning)
    return None


def get_current_tenant():
    import warnings
    warnings.warn("Use request.tenant instead of get_current_tenant()", DeprecationWarning)
    return None
