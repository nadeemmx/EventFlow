import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:eventflow_app/core/services/token_service.dart';
import 'package:eventflow_app/features/authentication/data/models/login_response_model.dart';
import 'package:eventflow_app/features/authentication/data/models/user_model.dart';
import 'package:eventflow_app/features/authentication/domain/repositories/auth_repository.dart';
import 'package:eventflow_app/features/authentication/presentation/bloc/auth_bloc.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockTokenService extends Mock implements TokenService {}

void main() {
  late MockAuthRepository mockRepository;
  late MockTokenService mockTokenService;
  late AuthBloc authBloc;

  final testUser = UserModel(
    id: 1,
    fullName: 'Test User',
    email: 'test@test.com',
    role: 'OWNER',
  );

  setUpAll(() {
    registerFallbackValue('');
    registerFallbackValue(false);
  });

  setUp(() {
    mockRepository = MockAuthRepository();
    mockTokenService = MockTokenService();
    authBloc = AuthBloc(authRepository: mockRepository, tokenService: mockTokenService);
  });

  tearDown(() {
    authBloc.close();
  });

  void stubRegister() {
    when(() => mockRepository.register(
          fullName: any(named: 'fullName'),
          email: any(named: 'email'),
          password: any(named: 'password'),
          confirmPassword: any(named: 'confirmPassword'),
          mobile: any(named: 'mobile'),
          termsAccepted: any(named: 'termsAccepted'),
          privacyAccepted: any(named: 'privacyAccepted'),
          ageConfirmed: any(named: 'ageConfirmed'),
          marketingOptIn: any(named: 'marketingOptIn'),
        )).thenAnswer((_) async => LoginResponseModel(
              accessToken: 'access',
              refreshToken: 'refresh',
              user: testUser,
            ));
  }

  blocTest<AuthBloc, AuthState>(
    'emits [AuthError] and never registers when consent is refused',
    build: () {
      stubRegister();
      return authBloc;
    },
    act: (bloc) => bloc.add(const RegisterRequested(
      fullName: 'Test User',
      email: 'test@test.com',
      password: 'Password1!',
      confirmPassword: 'Password1!',
      termsAccepted: false,
      privacyAccepted: true,
      ageConfirmed: true,
    )),
    expect: () => [
      isA<AuthError>().having(
        (e) => e.message,
        'message',
        contains('Terms of Service'),
      ),
    ],
    verify: (_) => verifyNever(() => mockRepository.register(
          fullName: any(named: 'fullName'),
          email: any(named: 'email'),
          password: any(named: 'password'),
          confirmPassword: any(named: 'confirmPassword'),
          mobile: any(named: 'mobile'),
          termsAccepted: any(named: 'termsAccepted'),
          privacyAccepted: any(named: 'privacyAccepted'),
          ageConfirmed: any(named: 'ageConfirmed'),
          marketingOptIn: any(named: 'marketingOptIn'),
        )),
  );

  blocTest<AuthBloc, AuthState>(
    'forwards consent and marketing flags to the repository',
    build: () {
      stubRegister();
      when(() => mockTokenService.saveUserData(any())).thenAnswer((_) async {});
      return authBloc;
    },
    act: (bloc) => bloc.add(const RegisterRequested(
      fullName: 'Test User',
      email: 'test@test.com',
      password: 'Password1!',
      confirmPassword: 'Password1!',
      termsAccepted: true,
      privacyAccepted: true,
      ageConfirmed: true,
      marketingOptIn: true,
    )),
    expect: () => [isA<AuthLoading>(), isA<AuthAuthenticated>()],
    verify: (_) => verify(() => mockRepository.register(
          fullName: 'Test User',
          email: 'test@test.com',
          password: 'Password1!',
          confirmPassword: 'Password1!',
          mobile: null,
          termsAccepted: true,
          privacyAccepted: true,
          ageConfirmed: true,
          marketingOptIn: true,
        )).called(1),
  );
}
