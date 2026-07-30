import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:eventflow_app/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:eventflow_app/features/authentication/domain/repositories/auth_repository.dart';
import 'package:eventflow_app/features/authentication/data/models/user_model.dart';
import 'package:eventflow_app/features/authentication/data/models/login_response_model.dart';
import 'package:eventflow_app/core/services/token_service.dart';

class MockAuthRepository extends Mock implements AuthRepository {}
class MockTokenService extends Mock implements TokenService {}

void main() {
  late AuthBloc authBloc;
  late MockAuthRepository mockRepository;
  late MockTokenService mockTokenService;

  setUp(() {
    mockRepository = MockAuthRepository();
    mockTokenService = MockTokenService();
    authBloc = AuthBloc(authRepository: mockRepository, tokenService: mockTokenService);
  });

  tearDown(() {
    authBloc.close();
  });

  final testUser = UserModel(id: 1, fullName: 'Test', email: 'test@test.com', role: 'OWNER');

  group('AuthBloc', () {
    test('initial state is AuthInitial', () {
      expect(authBloc.state, isA<AuthInitial>());
    });

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] when login succeeds',
      build: () {
        when(() => mockRepository.login(any(), any())).thenAnswer((_) async =>
          LoginResponseModel(accessToken: 'token', refreshToken: 'refresh', user: testUser)
        );
        when(() => mockTokenService.saveUserData(any())).thenAnswer((_) async {});
        return authBloc;
      },
      act: (bloc) => bloc.add(const LoginRequested(email: 'test@test.com', password: 'password')),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthAuthenticated>(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] when login fails',
      build: () {
        when(() => mockRepository.login(any(), any())).thenThrow(Exception('Invalid credentials'));
        return authBloc;
      },
      act: (bloc) => bloc.add(const LoginRequested(email: 'test@test.com', password: 'wrong')),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthPasswordResetSent] when forgot password succeeds',
      build: () {
        when(() => mockRepository.forgotPassword(any())).thenAnswer((_) async {});
        return authBloc;
      },
      act: (bloc) => bloc.add(const ForgotPasswordRequested(email: 'test@test.com')),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthPasswordResetSent>(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthPasswordResetSuccess] when reset password succeeds',
      build: () {
        when(() => mockRepository.resetPassword(any(), any(), any())).thenAnswer((_) async {});
        return authBloc;
      },
      act: (bloc) => bloc.add(const ResetPasswordRequested(token: 'tok', password: 'newpass', confirmPassword: 'newpass')),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthPasswordResetSuccess>(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthPasswordChanged] when change password succeeds',
      build: () {
        when(() => mockRepository.changePassword(any(), any(), any())).thenAnswer((_) async {});
        return authBloc;
      },
      act: (bloc) => bloc.add(const ChangePasswordRequested(currentPassword: 'old', newPassword: 'new', confirmPassword: 'new')),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthPasswordChanged>(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthProfileLoaded] when load profile succeeds',
      build: () {
        when(() => mockRepository.getProfile()).thenAnswer((_) async => testUser);
        return authBloc;
      },
      act: (bloc) => bloc.add(LoadProfile()),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthProfileLoaded>(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthProfileUpdated] when update profile succeeds',
      build: () {
        when(() => mockRepository.updateProfile(any())).thenAnswer((_) async => testUser);
        return authBloc;
      },
      act: (bloc) => bloc.add(const UpdateProfileRequested(data: {'full_name': 'Test'})),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthProfileUpdated>(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthUnauthenticated] when logout',
      build: () {
        when(() => mockRepository.logout()).thenAnswer((_) async {});
        return authBloc;
      },
      act: (bloc) => bloc.add(LogoutRequested()),
      expect: () => [isA<AuthUnauthenticated>()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthProfileUpdated] when upload profile image succeeds',
      build: () {
        when(() => mockRepository.uploadProfileImage(any())).thenAnswer((_) async => testUser);
        return authBloc;
      },
      act: (bloc) => bloc.add(const UploadProfileImage(filePath: '/path/to/img.jpg')),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthProfileUpdated>(),
      ],
    );
  });
}
