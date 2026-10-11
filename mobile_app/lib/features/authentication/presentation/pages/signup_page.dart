import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:eventflow_app/core/config/app_config.dart';
import 'package:eventflow_app/core/theme/app_colors.dart';
import 'package:eventflow_app/core/theme/design_system.dart';
import 'package:eventflow_app/core/utils/external_links.dart';
import 'package:eventflow_app/core/utils/validators.dart';
import 'package:eventflow_app/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:eventflow_app/features/authentication/presentation/widgets/auth_text_field.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  static const String _consentError =
      'Please accept the Terms of Service and Privacy Policy and confirm you are at least 18 years old.';

  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _mobileFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  bool _consentAccepted = false;
  bool _marketingOptIn = false;
  bool _showConsentError = false;

  late final TapGestureRecognizer _termsRecognizer = TapGestureRecognizer()
    ..onTap = () => openExternalUrl(AppConfig.termsUrl);
  late final TapGestureRecognizer _privacyRecognizer = TapGestureRecognizer()
    ..onTap = () => openExternalUrl(AppConfig.privacyPolicyUrl);

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameFocus.dispose();
    _emailFocus.dispose();
    _mobileFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  void _onSignup() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (!_consentAccepted) {
      setState(() => _showConsentError = true);
      return;
    }

    context.read<AuthBloc>().add(
          RegisterRequested(
            fullName: _fullNameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            confirmPassword: _confirmPasswordController.text,
            mobile: _mobileController.text.trim().isEmpty
                ? null
                : _mobileController.text.trim(),
            termsAccepted: true,
            privacyAccepted: true,
            ageConfirmed: true,
            marketingOptIn: _marketingOptIn,
          ),
        );
  }

  void _onConsentChanged(bool? value) {
    setState(() {
      _consentAccepted = value ?? false;
      if (_consentAccepted) _showConsentError = false;
    });
  }

  void _onMarketingChanged(bool? value) {
    setState(() => _marketingOptIn = value ?? false);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go('/dashboard');
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: colorScheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignSystem.radiusMd),
              ),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spacing6),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: DesignSystem.spacing10),
                  // Logo
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(DesignSystem.radiusXl),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(DesignSystem.radiusXl),
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 60,
                          height: 60,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.event_available_rounded,
                              size: 40,
                              color: AppColors.primary,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: DesignSystem.spacing8),
                  // Title
                  Text(
                    'Create Account',
                    style: DesignSystem.headlineLarge.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: DesignSystem.spacing2),
                  Text(
                    'Start managing your events',
                    style: DesignSystem.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: DesignSystem.spacing8),
                  // Full name
                  AuthTextField(
                    controller: _fullNameController,
                    focusNode: _fullNameFocus,
                    hint: 'Full name',
                    prefixIcon: Icons.person_outline_rounded,
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    validator: (value) => Validators.required(value, 'Full name'),
                    onEditingComplete: () => _emailFocus.requestFocus(),
                  ),
                  const SizedBox(height: DesignSystem.spacing4),
                  // Email
                  AuthTextField(
                    controller: _emailController,
                    focusNode: _emailFocus,
                    hint: 'Email address',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: Validators.email,
                    onEditingComplete: () => _mobileFocus.requestFocus(),
                  ),
                  const SizedBox(height: DesignSystem.spacing4),
                  // Mobile
                  AuthTextField(
                    controller: _mobileController,
                    focusNode: _mobileFocus,
                    hint: 'Mobile (optional)',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value != null && value.trim().isNotEmpty) {
                        return Validators.mobile(value);
                      }
                      return null;
                    },
                    onEditingComplete: () => _passwordFocus.requestFocus(),
                  ),
                  const SizedBox(height: DesignSystem.spacing4),
                  // Password
                  AuthTextField(
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    hint: 'Password',
                    prefixIcon: Icons.lock_outlined,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    validator: Validators.password,
                    onEditingComplete: () => _confirmPasswordFocus.requestFocus(),
                    suffixIcon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      size: 22,
                      color: AppColors.textTertiary,
                    ),
                    onSuffixTap: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  const SizedBox(height: DesignSystem.spacing4),
                  // Confirm password
                  AuthTextField(
                    controller: _confirmPasswordController,
                    focusNode: _confirmPasswordFocus,
                    hint: 'Confirm password',
                    prefixIcon: Icons.lock_outlined,
                    obscureText: _obscureConfirmPassword,
                    textInputAction: TextInputAction.done,
                    onEditingComplete: _onSignup,
                    validator: (value) => Validators.confirmPassword(
                      value,
                      _passwordController.text,
                    ),
                    suffixIcon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      size: 22,
                      color: AppColors.textTertiary,
                    ),
                    onSuffixTap: () => setState(
                        () => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                  const SizedBox(height: DesignSystem.spacing4),
                  // Consent: terms + privacy + age confirmation (required)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: Checkbox(
                          value: _consentAccepted,
                          activeColor: AppColors.primary,
                          onChanged: _onConsentChanged,
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: DesignSystem.spacing3),
                          child: Text.rich(
                            TextSpan(
                              text: 'I agree to the ',
                              style: DesignSystem.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.5,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Terms of Service',
                                  recognizer: _termsRecognizer,
                                  style: DesignSystem.bodySmall.copyWith(
                                    color: AppColors.primary,
                                    height: 1.5,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                const TextSpan(text: ' and '),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  recognizer: _privacyRecognizer,
                                  style: DesignSystem.bodySmall.copyWith(
                                    color: AppColors.primary,
                                    height: 1.5,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                const TextSpan(
                                  text:
                                      ', and confirm I am at least 18 years old.',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_showConsentError)
                    Padding(
                      padding: const EdgeInsets.only(
                        left: DesignSystem.spacing6,
                        top: DesignSystem.spacing1,
                      ),
                      child: Text(
                        _consentError,
                        style: DesignSystem.bodySmall.copyWith(
                          color: AppColors.error,
                          height: 1.4,
                        ),
                      ),
                    ),
                  // Marketing opt-in (optional, unchecked by default)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: Checkbox(
                          value: _marketingOptIn,
                          activeColor: AppColors.primary,
                          onChanged: _onMarketingChanged,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Email me product updates',
                          style: DesignSystem.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignSystem.spacing6),
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final isLoading = state is AuthLoading;
                      return SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _onSignup,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                            disabledForegroundColor: Colors.white70,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(DesignSystem.radiusMd),
                            ),
                            elevation: 0,
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Create Account'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: DesignSystem.spacing6),
                  // Sign in link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: DesignSystem.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.go('/login'),
                        child: Text(
                          'Sign In',
                          style: DesignSystem.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignSystem.spacing8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
