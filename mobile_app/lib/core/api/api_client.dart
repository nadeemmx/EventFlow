import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:eventflow_app/core/api/api_endpoints.dart';
import 'package:eventflow_app/core/services/token_service.dart';

class ApiClient {
  late final Dio _dio;
  final TokenService _tokenService;

  ApiClient({required this._tokenService}) {
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

    _dio.interceptors.addAll([
      _AuthInterceptor(_tokenService),
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
  Completer<void>? _refreshCompleter;

  static const _authPaths = [
    'auth/login/',
    'auth/refresh/',
    'auth/forgot-password/',
    'auth/reset-password/',
    'auth/change-password/',
  ];

  _AuthInterceptor(this._tokenService);

  bool _isAuthEndpoint(String path) {
    return _authPaths.any((p) => path.contains(p));
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenService.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    if (_isAuthEndpoint(err.requestOptions.path)) {
      handler.next(err);
      return;
    }

    if (_refreshCompleter != null) {
      await _refreshCompleter!.future;
      final newToken = await _tokenService.getAccessToken();
      if (newToken != null) {
        err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
        final retryResponse = await Dio(BaseOptions(
          baseUrl: ApiEndpoints.baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
        )).fetch(err.requestOptions);
        return handler.resolve(retryResponse);
      }
      handler.next(err);
      return;
    }

    _refreshCompleter = Completer<void>();
    try {
      final refreshToken = await _tokenService.getRefreshToken();
      if (refreshToken == null) {
        await _tokenService.clearTokens();
        _refreshCompleter!.complete();
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
        if (newAccessToken == null) throw Exception('No access token in response');

        await _tokenService.saveAccessToken(newAccessToken);
        err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
        _refreshCompleter!.complete();

        final retryDio = Dio(BaseOptions(
          baseUrl: ApiEndpoints.baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
        ));
        final retryResponse = await retryDio.fetch(err.requestOptions);
        return handler.resolve(retryResponse);
      } else {
        throw Exception('Invalid refresh response');
      }
    } catch (e) {
      if (!_refreshCompleter!.isCompleted) {
        _refreshCompleter!.completeError(e);
      }
      await _tokenService.clearTokens();
    } finally {
      _refreshCompleter = null;
    }
    handler.next(err);
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
