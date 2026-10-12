import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hive/hive.dart';

import 'package:eventflow_app/core/storage/storage_service.dart';
import 'package:eventflow_app/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:eventflow_app/features/authentication/domain/repositories/auth_repository.dart';
import 'package:eventflow_app/features/authentication/data/models/user_model.dart';
import 'package:eventflow_app/features/authentication/data/models/login_response_model.dart';
import 'package:eventflow_app/core/services/token_service.dart';
import 'package:dio/dio.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockTokenService extends Mock implements TokenService {}

void main() {
  group('StorageService - Onboarding', () {
    late StorageService storageService;
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('hive_test_');
      Hive.init(tempDir.path);
      storageService = StorageService();
      await storageService.init();
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('isOnboardingCompleted returns false by default', () {
      expect(storageService.isOnboardingCompleted(), false);
    });

    test('setOnboardingCompleted persists flag', () async {
      await storageService.setOnboardingCompleted();
      expect(storageService.isOnboardingCompleted(), true);
    });
  });

  group('AuthBloc - Signup Error Handling', () {
    late MockAuthRepository mockAuthRepository;
    late MockTokenService mockTokenService;
    late AuthBloc authBloc;

    final testUser = UserModel(
      id: 1,
      fullName: 'Test User',
      email: 'test@test.com',
      role: 'STAFF',
    );

    setUpAll(() {
      registerFallbackValue('');
      registerFallbackValue(UserModel(id: 0, fullName: '', email: '', role: 'STAFF'));
      registerFallbackValue(LoginResponseModel(
        accessToken: '',
        refreshToken: '',
        user: UserModel(id: 0, fullName: '', email: '', role: 'STAFF'),
      ));
    });

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      mockTokenService = MockTokenService();
      authBloc = AuthBloc(
        authRepository: mockAuthRepository,
        tokenService: mockTokenService,
      );
    });

    tearDown(() {
      authBloc.close();
    });

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] when RegisterRequested succeeds',
      build: () {
        when(() => mockAuthRepository.register(
          fullName: any(named: 'fullName'),
          email: any(named: 'email'),
          password: any(named: 'password'),
          confirmPassword: any(named: 'confirmPassword'),
          mobile: any(named: 'mobile'),
          termsAccepted: any(named: 'termsAccepted'),
          privacyAccepted: any(named: 'privacyAccepted'),
          ageConfirmed: any(named: 'ageConfirmed'),
          marketingOptIn: any(named: 'marketingOptIn'),
        )).thenAnswer(
          (_) async => LoginResponseModel(
            accessToken: 'access_token',
            refreshToken: 'refresh_token',
            user: testUser,
          ),
        );
        when(() => mockTokenService.saveUserData(any())).thenAnswer((_) async {});
        return authBloc;
      },
      act: (bloc) => bloc.add(RegisterRequested(
        fullName: 'Test User',
        email: 'test@test.com',
        password: 'password123',
        confirmPassword: 'password123',
        termsAccepted: true,
        privacyAccepted: true,
        ageConfirmed: true,
      )),
      expect: () => [
        AuthLoading(),
        AuthAuthenticated(user: testUser),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] when RegisterRequested fails with exception',
      build: () {
        when(() => mockAuthRepository.register(
          fullName: any(named: 'fullName'),
          email: any(named: 'email'),
          password: any(named: 'password'),
          confirmPassword: any(named: 'confirmPassword'),
          mobile: any(named: 'mobile'),
          termsAccepted: any(named: 'termsAccepted'),
          privacyAccepted: any(named: 'privacyAccepted'),
          ageConfirmed: any(named: 'ageConfirmed'),
          marketingOptIn: any(named: 'marketingOptIn'),
        )).thenThrow(Exception('Email already exists'));
        return authBloc;
      },
      act: (bloc) => bloc.add(RegisterRequested(
        fullName: 'Test User',
        email: 'existing@test.com',
        password: 'password123',
        confirmPassword: 'password123',
        termsAccepted: true,
        privacyAccepted: true,
        ageConfirmed: true,
      )),
      expect: () => [
        AuthLoading(),
        isA<AuthError>(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] with network error message on DioException connectionError',
      build: () {
        when(() => mockAuthRepository.register(
          fullName: any(named: 'fullName'),
          email: any(named: 'email'),
          password: any(named: 'password'),
          confirmPassword: any(named: 'confirmPassword'),
          mobile: any(named: 'mobile'),
          termsAccepted: any(named: 'termsAccepted'),
          privacyAccepted: any(named: 'privacyAccepted'),
          ageConfirmed: any(named: 'ageConfirmed'),
          marketingOptIn: any(named: 'marketingOptIn'),
        )).thenThrow(DioException(
          requestOptions: RequestOptions(path: 'auth/register/'),
          type: DioExceptionType.connectionError,
        ));
        return authBloc;
      },
      act: (bloc) => bloc.add(RegisterRequested(
        fullName: 'Test User',
        email: 'test@test.com',
        password: 'password123',
        confirmPassword: 'password123',
        termsAccepted: true,
        privacyAccepted: true,
        ageConfirmed: true,
      )),
      expect: () => [
        AuthLoading(),
        isA<AuthError>().having(
          (e) => e.message,
          'message',
          contains('Unable to connect'),
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] with email exists message on 409 status',
      build: () {
        when(() => mockAuthRepository.register(
          fullName: any(named: 'fullName'),
          email: any(named: 'email'),
          password: any(named: 'password'),
          confirmPassword: any(named: 'confirmPassword'),
          mobile: any(named: 'mobile'),
          termsAccepted: any(named: 'termsAccepted'),
          privacyAccepted: any(named: 'privacyAccepted'),
          ageConfirmed: any(named: 'ageConfirmed'),
          marketingOptIn: any(named: 'marketingOptIn'),
        )).thenThrow(DioException(
          requestOptions: RequestOptions(path: 'auth/register/'),
          response: Response(
            requestOptions: RequestOptions(path: 'auth/register/'),
            statusCode: 409,
            data: {'message': 'Email already exists'},
          ),
          type: DioExceptionType.badResponse,
        ));
        return authBloc;
      },
      act: (bloc) => bloc.add(RegisterRequested(
        fullName: 'Test User',
        email: 'existing@test.com',
        password: 'password123',
        confirmPassword: 'password123',
        termsAccepted: true,
        privacyAccepted: true,
        ageConfirmed: true,
      )),
      expect: () => [
        AuthLoading(),
        isA<AuthError>().having(
          (e) => e.message,
          'message',
          contains('account with this email already exists'),
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] with field validation error message',
      build: () {
        when(() => mockAuthRepository.register(
          fullName: any(named: 'fullName'),
          email: any(named: 'email'),
          password: any(named: 'password'),
          confirmPassword: any(named: 'confirmPassword'),
          mobile: any(named: 'mobile'),
          termsAccepted: any(named: 'termsAccepted'),
          privacyAccepted: any(named: 'privacyAccepted'),
          ageConfirmed: any(named: 'ageConfirmed'),
          marketingOptIn: any(named: 'marketingOptIn'),
        )).thenThrow(DioException(
          requestOptions: RequestOptions(path: 'auth/register/'),
          response: Response(
            requestOptions: RequestOptions(path: 'auth/register/'),
            statusCode: 400,
            data: {
              'success': false,
              'message': 'Validation error',
              'errors': {
                'email': ['This field must be a valid email address.'],
              },
            },
          ),
          type: DioExceptionType.badResponse,
        ));
        return authBloc;
      },
      act: (bloc) => bloc.add(RegisterRequested(
        fullName: 'Test User',
        email: 'invalid-email',
        password: 'password123',
        confirmPassword: 'password123',
        termsAccepted: true,
        privacyAccepted: true,
        ageConfirmed: true,
      )),
      expect: () => [
        AuthLoading(),
        isA<AuthError>().having(
          (e) => e.message,
          'message',
          contains('valid email'),
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] with timeout message on sendTimeout',
      build: () {
        when(() => mockAuthRepository.register(
          fullName: any(named: 'fullName'),
          email: any(named: 'email'),
          password: any(named: 'password'),
          confirmPassword: any(named: 'confirmPassword'),
          mobile: any(named: 'mobile'),
          termsAccepted: any(named: 'termsAccepted'),
          privacyAccepted: any(named: 'privacyAccepted'),
          ageConfirmed: any(named: 'ageConfirmed'),
          marketingOptIn: any(named: 'marketingOptIn'),
        )).thenThrow(DioException(
          requestOptions: RequestOptions(path: 'auth/register/'),
          type: DioExceptionType.sendTimeout,
        ));
        return authBloc;
      },
      act: (bloc) => bloc.add(RegisterRequested(
        fullName: 'Test User',
        email: 'test@test.com',
        password: 'password123',
        confirmPassword: 'password123',
        termsAccepted: true,
        privacyAccepted: true,
        ageConfirmed: true,
      )),
      expect: () => [
        AuthLoading(),
        isA<AuthError>().having(
          (e) => e.message,
          'message',
          contains('Unable to connect'),
        ),
      ],
    );
  });

  group('AuthBloc - Login Error Handling', () {
    late MockAuthRepository mockAuthRepository;
    late MockTokenService mockTokenService;
    late AuthBloc authBloc;

    setUpAll(() {
      registerFallbackValue('');
      registerFallbackValue(UserModel(id: 0, fullName: '', email: '', role: 'STAFF'));
    });

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      mockTokenService = MockTokenService();
      authBloc = AuthBloc(
        authRepository: mockAuthRepository,
        tokenService: mockTokenService,
      );
    });

    tearDown(() {
      authBloc.close();
    });

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] with network error on connectionError',
      build: () {
        when(() => mockAuthRepository.login(any(), any())).thenThrow(DioException(
          requestOptions: RequestOptions(path: 'auth/login/'),
          type: DioExceptionType.connectionError,
        ));
        return authBloc;
      },
      act: (bloc) => bloc.add(LoginRequested(email: 'test@test.com', password: 'password')),
      expect: () => [
        AuthLoading(),
        isA<AuthError>().having(
          (e) => e.message,
          'message',
          contains('Unable to connect'),
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] with server error message on 500',
      build: () {
        when(() => mockAuthRepository.login(any(), any())).thenThrow(DioException(
          requestOptions: RequestOptions(path: 'auth/login/'),
          response: Response(
            requestOptions: RequestOptions(path: 'auth/login/'),
            statusCode: 500,
            data: {'message': 'Internal server error'},
          ),
          type: DioExceptionType.badResponse,
        ));
        return authBloc;
      },
      act: (bloc) => bloc.add(LoginRequested(email: 'test@test.com', password: 'wrong')),
      expect: () => [
        AuthLoading(),
        isA<AuthError>().having(
          (e) => e.message,
          'message',
          contains('Internal server error'),
        ),
      ],
    );
  });

  group('AuthBloc - Guest Flow', () {
    late MockAuthRepository mockAuthRepository;
    late MockTokenService mockTokenService;
    late AuthBloc authBloc;

    final guestUser = UserModel(
      id: 0,
      fullName: 'Guest User',
      email: 'guest@eventflow.app',
      role: 'GUEST',
    );

    setUpAll(() {
      registerFallbackValue('');
      registerFallbackValue(UserModel(id: 0, fullName: '', email: '', role: 'STAFF'));
    });

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      mockTokenService = MockTokenService();
      authBloc = AuthBloc(
        authRepository: mockAuthRepository,
        tokenService: mockTokenService,
      );
    });

    tearDown(() {
      authBloc.close();
    });

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthGuestAuthenticated] when GuestLoginRequested succeeds',
      build: () {
        when(() => mockAuthRepository.guestLogin()).thenAnswer((_) async => guestUser);
        return authBloc;
      },
      act: (bloc) => bloc.add(GuestLoginRequested()),
      expect: () => [
        AuthLoading(),
        AuthGuestAuthenticated(user: guestUser),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'Guest does NOT become AuthAuthenticated',
      build: () {
        when(() => mockAuthRepository.guestLogin()).thenAnswer((_) async => guestUser);
        return authBloc;
      },
      act: (bloc) => bloc.add(GuestLoginRequested()),
      verify: (bloc) {
        expect(bloc.state, isA<AuthGuestAuthenticated>());
        expect(bloc.state, isNot(isA<AuthAuthenticated>()));
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthUnauthenticated] when GuestLogoutRequested',
      build: () {
        when(() => mockAuthRepository.guestLogout()).thenAnswer((_) async {});
        return authBloc;
      },
      act: (bloc) => bloc.add(GuestLogoutRequested()),
      expect: () => [AuthUnauthenticated()],
    );
  });
}
