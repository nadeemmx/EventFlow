import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eventflow_app/core/api/tenant_interceptor.dart';
import 'package:eventflow_app/core/services/tenant_context_service.dart';

/// Regression tests for fix M-5 (tenant context injection).
///
/// Mirrors `backend/core/tenant_resolution.py`, which resolves SUPER_ADMIN's
/// tenant explicitly from the request and otherwise fails closed:
///
///   * reads  (GET/DELETE) -> `?tenant=<digits>` query parameter
///   * writes (POST/PUT/PATCH) -> a `tenant` field in the JSON body
///   * multipart is skipped so file uploads are never buffered
class _CapturingAdapter implements HttpClientAdapter {
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromString(
      jsonEncode({'success': true, 'data': <String, dynamic>{}}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _CapturingAdapter adapter;
  late Dio dio;

  /// Builds a Dio wired exactly like ApiClient is: baseUrl + the interceptor
  /// under test. Auth is deliberately omitted — these tests are about tenant
  /// scoping only.
  Dio buildDio(TenantContextService tenantContext) {
    adapter = _CapturingAdapter();
    final d = Dio(BaseOptions(
      baseUrl: 'https://api.example.com/api/v1/',
      headers: {'Accept': 'application/json'},
    ));
    d.httpClientAdapter = adapter;
    d.interceptors.add(TenantInterceptor(tenantContext));
    return d;
  }

  Future<TenantContextService> serviceWith(int? tenantId) async {
    final service = TenantContextService();
    await service.setTenantId(tenantId);
    return service;
  }

  group('M-5: reads append ?tenant=<digits>', () {
    test('GET adds the tenant query parameter as a digit string', () async {
      dio = buildDio(await serviceWith(2));
      await dio.get('bookings/');

      final q = adapter.lastRequest!.queryParameters;
      expect(q['tenant'], '2');
      expect(q['tenant'], matches(RegExp(r'^\d+$')));
    });

    test('DELETE also carries the tenant (a read as far as tenancy goes)',
        () async {
      dio = buildDio(await serviceWith(7));
      await dio.delete('customers/1/');

      expect(adapter.lastRequest!.queryParameters['tenant'], '7');
    });

    test('an existing query parameter is preserved', () async {
      dio = buildDio(await serviceWith(2));
      await dio.get('bookings/calendar/', queryParameters: {'month': '10'});

      final q = adapter.lastRequest!.queryParameters;
      expect(q['tenant'], '2');
      expect(q['month'], '10');
    });
  });

  group('M-5: writes put tenant in the JSON body', () {
    test('POST adds a tenant field without disturbing the payload', () async {
      dio = buildDio(await serviceWith(3));
      await dio.post('customers/', data: {'full_name': 'Jane Doe'});

      final body = adapter.lastRequest!.data as Map<String, dynamic>;
      expect(body['tenant'], 3);
      expect(body['full_name'], 'Jane Doe');
    });

    test('PUT adds a tenant field', () async {
      dio = buildDio(await serviceWith(3));
      await dio.put('customers/9/', data: {'full_name': 'Jane'});

      final body = adapter.lastRequest!.data as Map<String, dynamic>;
      expect(body['tenant'], 3);
    });

    test('an explicit tenant in the payload is not overwritten', () async {
      dio = buildDio(await serviceWith(3));
      await dio.post('customers/', data: {'tenant': 99});

      final body = adapter.lastRequest!.data as Map<String, dynamic>;
      expect(body['tenant'], 99, reason: 'caller-supplied tenant must win');
    });

    test('a body-less POST still gets the tenant field', () async {
      dio = buildDio(await serviceWith(4));
      await dio.post('bookings/1/confirm/');

      final body = adapter.lastRequest!.data as Map<String, dynamic>;
      expect(body['tenant'], 4);
    });
  });

  group('M-5: no tenant -> request untouched (backend fails closed)', () {
    test('GET is unscoped when no tenant is set', () async {
      dio = buildDio(await serviceWith(null));
      await dio.get('bookings/');

      expect(adapter.lastRequest!.queryParameters.containsKey('tenant'), isFalse);
    });

    test('POST body is unscoped when no tenant is set', () async {
      dio = buildDio(await serviceWith(null));
      await dio.post('customers/', data: {'full_name': 'No Tenant'});

      final body = adapter.lastRequest!.data as Map<String, dynamic>;
      expect(body.containsKey('tenant'), isFalse);
      expect(body['full_name'], 'No Tenant');
    });
  });

  group('M-5: excluded paths', () {
    test('auth endpoints never carry a tenant', () async {
      dio = buildDio(await serviceWith(2));
      await dio.post('auth/login/', data: {'email': 'a@b.com'});

      final body = adapter.lastRequest!.data as Map<String, dynamic>;
      expect(body.containsKey('tenant'), isFalse);
      expect(adapter.lastRequest!.queryParameters.containsKey('tenant'), isFalse);
    });

    test('token refresh is unscoped', () async {
      dio = buildDio(await serviceWith(2));
      await dio.post('auth/refresh/', data: {'refresh_token': 'r'});

      final body = adapter.lastRequest!.data as Map<String, dynamic>;
      expect(body.containsKey('tenant'), isFalse);
    });
  });

  group('M-5: multipart is left untouched', () {
    test('FormData bodies are not mutated (matches backend behaviour)',
        () async {
      dio = buildDio(await serviceWith(5));
      await dio.post(
        'invoices/1/download/',
        data: FormData.fromMap({'file': 'x'}),
      );

      expect(adapter.lastRequest!.data, isA<FormData>());
    });
  });

  group('M-5: TenantContextService persistence', () {
    test('setTenantId updates the in-memory value even when storage is '
        'unavailable (unit-test environment)', () async {
      final service = TenantContextService();
      expect(service.tenantId, isNull);

      await service.setTenantId(11);
      expect(service.tenantId, 11);
      expect(service.hasTenant, isTrue);

      await service.clear();
      expect(service.tenantId, isNull);
      expect(service.hasTenant, isFalse);
    });
  });
}
