import 'package:dio/dio.dart';
import 'package:eventflow_app/core/services/tenant_context_service.dart';

/// Scopes outgoing requests to the active tenant.
///
/// Mirrors `backend/core/tenant_resolution.py` exactly:
///
/// * `GET` / `DELETE` / `HEAD` / `OPTIONS` -> `?tenant=<id>` query parameter.
///   The server only accepts a digit string (`str(raw).isdigit()`), so the id
///   is sent as a string, never as JSON.
/// * `POST` / `PUT` / `PATCH` -> a `tenant` field in the JSON body.
/// * `multipart/form-data` is intentionally **left untouched**. The backend
///   skips multipart too (so invoice PDFs and venue image uploads are never
///   buffered into memory), and those endpoints are never tenant-resolving
///   writes.
///
/// Auth endpoints are skipped: no tenant context exists before login.
///
/// When no tenant is set (the normal case for OWNER/MANAGER/STAFF, whose
/// tenant the server derives from the JWT, and for SUPER_ADMIN before a
/// picker is built) this interceptor is a no-op.
class TenantInterceptor extends Interceptor {
  final TenantContextService _tenantContext;

  /// Endpoints that must never carry a tenant.
  static const List<String> _excludedPaths = [
    'auth/login/',
    'auth/register/',
    'auth/refresh/',
    'auth/logout/',
    'auth/forgot-password/',
    'auth/reset-password/',
    'auth/change-password/',
  ];

  static const Set<String> _writeMethods = {'POST', 'PUT', 'PATCH'};

  TenantInterceptor(this._tenantContext);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final tenantId = _tenantContext.tenantId;
    if (tenantId == null) {
      handler.next(options);
      return;
    }

    final path = options.path;
    if (_excludedPaths.any((p) => path.contains(p))) {
      handler.next(options);
      return;
    }

    final method = options.method.toUpperCase();
    if (_writeMethods.contains(method)) {
      final data = options.data;
      if (data == null) {
        options.data = <String, dynamic>{'tenant': tenantId};
      } else if (data is Map) {
        // Always copy into a fresh Map<String, dynamic> rather than mutating
        // in place. The caller's map may be a Map<String, String> at runtime
        // (e.g. a Dart map literal passed straight to Dio), and mutating that
        // with an int value throws a covariant-runtime TypeError.
        final copy = <String, dynamic>{...data};
        // putIfAbsent so an explicitly supplied tenant is never overridden.
        copy.putIfAbsent('tenant', () => tenantId);
        options.data = copy;
      }
      // FormData / other encodings: skipped, matching the backend.
    } else {
      options.queryParameters = <String, dynamic>{
        ...options.queryParameters,
        'tenant': '$tenantId',
      };
    }

    handler.next(options);
  }
}
