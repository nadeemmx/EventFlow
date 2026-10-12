import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Holds the tenant id that outgoing API requests should operate on.
///
/// ## Why this exists
///
/// Backend tenancy lives in `backend/core/tenant_resolution.py`:
///
/// * For OWNER / MANAGER / STAFF / ACCOUNTANT the JWT already carries a
///   tenant, so the server derives it and the client sends nothing extra.
/// * For `SUPER_ADMIN` the user row has `tenant = NULL` (platform role). The
///   server then reads the tenant **explicitly from the client**:
///     - reads  (GET/DELETE) -> `?tenant=<id>` query parameter (digits only)
///     - writes (POST/PUT/PATCH) -> a `tenant` field in the JSON body
///   If the client omits it, resolution fails **closed** and the request
///   behaves as if it had no tenant (empty queryset / NOT NULL rejection).
///
/// Before this service existed the mobile client never sent a tenant at all,
/// so a SUPER_ADMIN on mobile got empty lists on every tenant-scoped read.
///
/// ## Current state (Tier-1 scope)
///
/// This is **plumbing only**. The id is seeded from `UserModel.tenantId` on
/// login, which is non-null for ordinary tenant users and null for
/// SUPER_ADMIN. There is deliberately **no tenant picker UI yet**, so
/// SUPER_ADMIN remains fail-closed until one is built — this service is the
/// seam that UI will call (`setTenantId`).
class TenantContextService {
  static const String _storageKey = 'active_tenant_id';

  final FlutterSecureStorage _storage;
  int? _tenantId;

  /// The tenant id requests should be scoped to, or null for none.
  int? get tenantId => _tenantId;
  bool get hasTenant => _tenantId != null;

  TenantContextService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  /// Restore a previously selected tenant. Call once during app bootstrap.
  Future<void> load() async {
    try {
      final raw = await _storage.read(key: _storageKey);
      _tenantId = raw == null ? null : int.tryParse(raw);
    } catch (_) {
      // Secure storage unavailable (e.g. unit tests, web) -> no tenant.
      _tenantId = null;
    }
  }

  /// Set (or clear, with null) the active tenant.
  Future<void> setTenantId(int? id) async {
    _tenantId = id;
    try {
      if (id == null) {
        await _storage.delete(key: _storageKey);
      } else {
        await _storage.write(key: _storageKey, value: id.toString());
      }
    } catch (_) {
      // Persistence is best-effort; the in-memory value still applies.
    }
  }

  /// Drop the active tenant. Called on logout so no tenant data leaks across
  /// accounts on a shared device.
  Future<void> clear() => setTenantId(null);
}
