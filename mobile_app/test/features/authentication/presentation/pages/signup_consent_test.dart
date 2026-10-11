import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:eventflow_app/core/services/token_service.dart';
import 'package:eventflow_app/features/authentication/domain/repositories/auth_repository.dart';
import 'package:eventflow_app/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:eventflow_app/features/authentication/presentation/pages/signup_page.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockTokenService extends Mock implements TokenService {}

const _consentError =
    'Please accept the Terms of Service and Privacy Policy and confirm you are at least 18 years old.';

void main() {
  late MockAuthRepository repository;
  late MockTokenService tokenService;
  late AuthBloc authBloc;

  setUpAll(() {
    registerFallbackValue('');
    registerFallbackValue(false);
  });

  setUp(() {
    repository = MockAuthRepository();
    tokenService = MockTokenService();
    when(() => tokenService.saveUserData(any())).thenAnswer((_) async {});
    authBloc = AuthBloc(authRepository: repository, tokenService: tokenService);
  });

  tearDown(() {
    authBloc.close();
  });

  Future<void> pumpSignup(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: const SignupPage(),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> fillForm(WidgetTester tester) async {
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Test User');
    await tester.enterText(fields.at(1), 'test@example.com');
    await tester.enterText(fields.at(2), '9876543210');
    await tester.enterText(fields.at(3), 'Password1!');
    await tester.enterText(fields.at(4), 'Password1!');
  }

  Finder consentCheckbox() => find.byType(Checkbox).at(0);
  Finder marketingCheckbox() => find.byType(Checkbox).at(1);
  Finder submitButton() => find.widgetWithText(ElevatedButton, 'Create Account');

  void stubRegister() {
    when(() => repository.register(
          fullName: any(named: 'fullName'),
          email: any(named: 'email'),
          password: any(named: 'password'),
          confirmPassword: any(named: 'confirmPassword'),
          mobile: any(named: 'mobile'),
          termsAccepted: any(named: 'termsAccepted'),
          privacyAccepted: any(named: 'privacyAccepted'),
          ageConfirmed: any(named: 'ageConfirmed'),
          marketingOptIn: any(named: 'marketingOptIn'),
        )).thenThrow(Exception('Registration failed'));
  }

  group('SignupPage consent', () {
    testWidgets('required consent and marketing checkboxes start unchecked',
        (tester) async {
      await pumpSignup(tester);

      final boxes = tester.widgetList<Checkbox>(find.byType(Checkbox)).toList();
      expect(boxes, hasLength(2));
      expect(boxes[0].value, isFalse);
      expect(boxes[1].value, isFalse);
    });

    testWidgets('consent text links Terms of Service and Privacy Policy',
        (tester) async {
      await pumpSignup(tester);

      final consent = tester
          .widgetList<Text>(find.byType(Text))
          .firstWhere((t) => t.textSpan?.toPlainText().contains('I agree to the') ?? false);
      final plain = consent.textSpan!.toPlainText();
      expect(plain, contains('Terms of Service'));
      expect(plain, contains('Privacy Policy'));
      expect(plain, contains('at least 18 years old'));

      expect(find.text('Email me product updates'), findsOneWidget);
    });

    testWidgets(
        'blocks submission with an inline error when consent is missing',
        (tester) async {
      await pumpSignup(tester);
      await fillForm(tester);

      await tester.tap(submitButton());
      await tester.pump();

      expect(find.text(_consentError), findsOneWidget);
      verifyNever(() => repository.register(
            fullName: any(named: 'fullName'),
            email: any(named: 'email'),
            password: any(named: 'password'),
            confirmPassword: any(named: 'confirmPassword'),
            mobile: any(named: 'mobile'),
            termsAccepted: any(named: 'termsAccepted'),
            privacyAccepted: any(named: 'privacyAccepted'),
            ageConfirmed: any(named: 'ageConfirmed'),
            marketingOptIn: any(named: 'marketingOptIn'),
          ));
    });

    testWidgets('inline consent error clears once the box is ticked',
        (tester) async {
      await pumpSignup(tester);
      await fillForm(tester);

      await tester.tap(submitButton());
      await tester.pump();
      expect(find.text(_consentError), findsOneWidget);

      await tester.tap(consentCheckbox());
      await tester.pump();
      expect(find.text(_consentError), findsNothing);
    });

    testWidgets(
        'sends terms/privacy/age flags when consented (marketing unchecked)',
        (tester) async {
      stubRegister();
      await pumpSignup(tester);
      await fillForm(tester);

      await tester.tap(consentCheckbox());
      await tester.pump();
      await tester.tap(submitButton());
      await tester.pumpAndSettle();

      verify(() => repository.register(
            fullName: 'Test User',
            email: 'test@example.com',
            password: 'Password1!',
            confirmPassword: 'Password1!',
            mobile: '9876543210',
            termsAccepted: true,
            privacyAccepted: true,
            ageConfirmed: true,
            marketingOptIn: false,
          )).called(1);
    });

    testWidgets('marketing opt-in maps to marketingOptIn: true',
        (tester) async {
      stubRegister();
      await pumpSignup(tester);
      await fillForm(tester);

      await tester.tap(consentCheckbox());
      await tester.pump();
      await tester.tap(marketingCheckbox());
      await tester.pump();
      expect(tester.widget<Checkbox>(marketingCheckbox()).value, isTrue);

      await tester.tap(submitButton());
      await tester.pumpAndSettle();

      verify(() => repository.register(
            fullName: 'Test User',
            email: 'test@example.com',
            password: 'Password1!',
            confirmPassword: 'Password1!',
            mobile: '9876543210',
            termsAccepted: true,
            privacyAccepted: true,
            ageConfirmed: true,
            marketingOptIn: true,
          )).called(1);
    });
  });
}
