import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:eventflow_app/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:eventflow_app/features/authentication/domain/repositories/auth_repository.dart';
import 'package:eventflow_app/features/authentication/data/models/user_model.dart';
import 'package:eventflow_app/features/authentication/data/models/login_response_model.dart';
import 'package:eventflow_app/core/services/token_service.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockTokenService extends Mock implements TokenService {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late MockTokenService mockTokenService;
  late AuthBloc authBloc;

  final testUser = UserModel(
    id: 1,
    fullName: 'Test User',
    email: 'test@test.com',
    role: 'ADMIN',
  );

  final testGuestUser = UserModel(
    id: 2,
    fullName: 'Guest User',
    email: 'guest@test.com',
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

  group('AuthBloc', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] when LoginRequested succeeds',
      build: () {
        when(() => mockAuthRepository.login(any(), any())).thenAnswer(
          (_) async => LoginResponseModel(
            accessToken: 'access_token',
            refreshToken: 'refresh_token',
            user: testUser,
          ),
        );
        when(() => mockTokenService.saveUserData(any())).thenAnswer((_) async {});
        return AuthBloc(
          authRepository: mockAuthRepository,
          tokenService: mockTokenService,
        );
      },
      act: (bloc) => bloc.add(LoginRequested(email: 'test@test.com', password: 'password')),
      expect: () => [
        AuthLoading(),
        AuthAuthenticated(user: testUser),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] when LoginRequested fails',
      build: () {
        when(() => mockAuthRepository.login(any(), any())).thenThrow(
          Exception('Invalid credentials'),
        );
        return AuthBloc(
          authRepository: mockAuthRepository,
          tokenService: mockTokenService,
        );
      },
      act: (bloc) => bloc.add(LoginRequested(email: 'test@test.com', password: 'wrong')),
      expect: () => [
        AuthLoading(),
        isA<AuthError>(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthGuestAuthenticated] when GuestLoginRequested succeeds',
      build: () {
        when(() => mockAuthRepository.guestLogin()).thenAnswer(
          (_) async => testGuestUser,
        );
        return AuthBloc(
          authRepository: mockAuthRepository,
          tokenService: mockTokenService,
        );
      },
      act: (bloc) => bloc.add(GuestLoginRequested()),
      expect: () => [
        AuthLoading(),
        AuthGuestAuthenticated(user: testGuestUser),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'Guest does NOT become AuthAuthenticated',
      build: () {
        when(() => mockAuthRepository.guestLogin()).thenAnswer(
          (_) async => testGuestUser,
        );
        return AuthBloc(
          authRepository: mockAuthRepository,
          tokenService: mockTokenService,
        );
      },
      act: (bloc) => bloc.add(GuestLoginRequested()),
      expect: () => [
        AuthLoading(),
        isA<AuthGuestAuthenticated>(),
      ],
      verify: (bloc) {
        expect(bloc.state, isA<AuthGuestAuthenticated>());
        expect(bloc.state, isNot(isA<AuthAuthenticated>()));
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] when RegisterRequested succeeds',
      build: () {
        when(() => mockAuthRepository.register(
          fullName: any(named: 'fullName'),
          email: any(named: 'email'),
          password: any(named: 'password'),
          confirmPassword: any(named: 'confirmPassword'),
          mobile: any(named: 'mobile'),
        )).thenAnswer(
          (_) async => LoginResponseModel(
            accessToken: 'access_token',
            refreshToken: 'refresh_token',
            user: testUser,
          ),
        );
        when(() => mockTokenService.saveUserData(any())).thenAnswer((_) async {});
        return AuthBloc(
          authRepository: mockAuthRepository,
          tokenService: mockTokenService,
        );
      },
      act: (bloc) => bloc.add(RegisterRequested(
        fullName: 'Test User',
        email: 'test@test.com',
        password: 'password123',
        confirmPassword: 'password123',
      )),
      expect: () => [
        AuthLoading(),
        AuthAuthenticated(user: testUser),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] when RegisterRequested fails',
      build: () {
        when(() => mockAuthRepository.register(
          fullName: any(named: 'fullName'),
          email: any(named: 'email'),
          password: any(named: 'password'),
          confirmPassword: any(named: 'confirmPassword'),
          mobile: any(named: 'mobile'),
        )).thenThrow(Exception('Email already exists'));
        return AuthBloc(
          authRepository: mockAuthRepository,
          tokenService: mockTokenService,
        );
      },
      act: (bloc) => bloc.add(RegisterRequested(
        fullName: 'Test User',
        email: 'existing@test.com',
        password: 'password123',
        confirmPassword: 'password123',
      )),
      expect: () => [
        AuthLoading(),
        isA<AuthError>(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits AuthUnauthenticated when LogoutRequested',
      build: () {
        when(() => mockAuthRepository.logout()).thenAnswer((_) async {});
        when(() => mockTokenService.clearTokens()).thenAnswer((_) async {});
        return AuthBloc(
          authRepository: mockAuthRepository,
          tokenService: mockTokenService,
        );
      },
      act: (bloc) => bloc.add(LogoutRequested()),
      expect: () => [
        AuthUnauthenticated(),
      ],
    );
  });
}
