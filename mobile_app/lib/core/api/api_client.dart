import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:eventflow_app/core/api/api_endpoints.dart';
import 'package:eventflow_app/core/api/tenant_interceptor.dart';
import 'package:eventflow_app/core/services/tenant_context_service.dart';
import 'package:eventflow_app/core/services/token_service.dart';

class ApiClient {
  late final Dio _dio;
  final TokenService _tokenService;
  final TenantContextService? _tenantContext;
  final StreamController<void> _authFailureController = StreamController<void>.broadcast();

  Stream<void> get authFailure => _authFailureController.stream;

  ApiClient({
    required this._tokenService,
    this._tenantContext,
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    final tenantContext = _tenantContext;
    _dio.interceptors.addAll([
      // Registered first so the tenant is attached before the request is
      // dispatched; both interceptors mutate the request independently.
      if (tenantContext != null) TenantInterceptor(tenantContext),
      _AuthInterceptor(_tokenService, _authFailureController),
      _ErrorInterceptor(),
      if (kDebugMode) LogInterceptor(
        request: true,
        requestHeader: true,
        responseHeader: false,
        responseBody: true,
        error: true,
      ),
    ]);
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }
}

class _AuthInterceptor extends Interceptor {
  final TokenService _tokenService;
  final StreamController<void> _authFailureController;
  Completer<void>? _refreshCompleter;
  bool _isRefreshing = false;

  static const _authPaths = [
    'auth/login/',
    'auth/register/',
    'auth/refresh/',
    'auth/forgot-password/',
    'auth/reset-password/',
    'auth/change-password/',
  ];

  _AuthInterceptor(this._tokenService, this._authFailureController);

  bool _isAuthEndpoint(String path) {
    return _authPaths.any((p) => path.contains(p));
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final token = await _tokenService.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (_) {
      // Token read failed — proceed without Authorization header
    }
    handler.next(options);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    try {
      if (err.response?.statusCode != 401) {
        handler.next(err);
        return;
      }

      if (_isAuthEndpoint(err.requestOptions.path)) {
        handler.next(err);
        return;
      }

      if (_isRefreshing) {
        await _refreshCompleter?.future;
        final newToken = await _tokenService.getAccessToken();
        if (newToken != null && newToken.isNotEmpty) {
          err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
          final retryResponse = await Dio(BaseOptions(
            baseUrl: ApiEndpoints.baseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
          )).fetch(err.requestOptions);
          handler.resolve(retryResponse);
          return;
        }
        handler.next(err);
        return;
      }

      _isRefreshing = true;
      _refreshCompleter = Completer<void>();
      try {
        final refreshToken = await _tokenService.getRefreshToken();
        if (refreshToken == null || refreshToken.isEmpty) {
          await _tokenService.clearTokens();
          _authFailureController.add(null);
          handler.next(err);
          return;
        }

        final refreshDio = Dio(BaseOptions(
          baseUrl: ApiEndpoints.baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
        ));
        final response = await refreshDio.post(
          ApiEndpoints.refresh,
          data: {'refresh_token': refreshToken},
        );

        if (response.data is Map<String, dynamic> &&
            response.data['success'] == true &&
            response.data['data'] is Map<String, dynamic>) {
          final newAccessToken = response.data['data']['access_token'] as String?;
          if (newAccessToken == null || newAccessToken.isEmpty) {
            throw Exception('No access token in response');
          }

          await _tokenService.saveAccessToken(newAccessToken);
          err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
          _refreshCompleter!.complete();

          final retryResponse = await Dio(BaseOptions(
            baseUrl: ApiEndpoints.baseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
          )).fetch(err.requestOptions);
          handler.resolve(retryResponse);
          return;
        } else {
          throw Exception('Invalid refresh response');
        }
      } catch (e) {
        if (_refreshCompleter != null && !_refreshCompleter!.isCompleted) {
          _refreshCompleter!.completeError(e);
        }
        await _tokenService.clearTokens();
        _authFailureController.add(null);
        handler.next(err);
      } finally {
        _refreshCompleter = null;
        _isRefreshing = false;
      }
    } catch (_) {
      handler.next(err);
    }
  }
}

class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          error: 'Connection timed out. Please try again.',
          type: DioExceptionType.unknown,
        ),
      );
      return;
    }
    if (err.type == DioExceptionType.connectionError) {
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          error: 'No internet connection.',
          type: DioExceptionType.unknown,
        ),
      );
      return;
    }
    handler.next(err);
  }
}
