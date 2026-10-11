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

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _onLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            LoginRequested(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go('/dashboard');
        } else if (state is AuthGuestAuthenticated) {
          context.go('/demo');
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
                  const SizedBox(height: DesignSystem.spacing12),
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
                    'Welcome Back',
                    style: DesignSystem.headlineLarge.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: DesignSystem.spacing2),
                  Text(
                    'Sign in to your account',
                    style: DesignSystem.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: DesignSystem.spacing10),
                  // Email
                  AuthTextField(
                    controller: _emailController,
                    focusNode: _emailFocus,
                    hint: 'Email address',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: Validators.email,
                    onEditingComplete: () => _passwordFocus.requestFocus(),
                    autofillHint: 'email',
                  ),
                  const SizedBox(height: DesignSystem.spacing4),
                  // Password
                  AuthTextField(
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    hint: 'Password',
                    prefixIcon: Icons.lock_outlined,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onEditingComplete: _onLogin,
                    validator: Validators.password,
                    suffixIcon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      size: 22,
                      color: AppColors.textTertiary,
                    ),
                    onSuffixTap: () => setState(() => _obscurePassword = !_obscurePassword),
                    autofillHint: 'password',
                  ),
                  const SizedBox(height: DesignSystem.spacing2),
                  // Forgot password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.push('/forgot-password'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: DesignSystem.spacing2,
                          vertical: DesignSystem.spacing1,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Forgot Password?',
                        style: DesignSystem.labelLarge.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: DesignSystem.spacing6),
                  // Sign In button
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final isLoading = state is AuthLoading;
                      return SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _onLogin,
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
                              : const Text('Sign In'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: DesignSystem.spacing6),
                  // Divider
                  Row(
                    children: [
                      Expanded(
                        child: Divider(color: AppColors.border),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spacing4),
                        child: Text(
                          'OR',
                          style: DesignSystem.labelSmall.copyWith(
                            color: AppColors.textTertiary,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(color: AppColors.border),
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignSystem.spacing6),
                  // Guest button
                  OutlinedButton.icon(
                    onPressed: () {
                      context.read<AuthBloc>().add(GuestLoginRequested());
                    },
                    icon: const Icon(
                      Icons.person_outline_rounded,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    label: Text(
                      'Continue as Guest',
                      style: DesignSystem.titleSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(DesignSystem.radiusMd),
                      ),
                    ),
                  ),
                  const SizedBox(height: DesignSystem.spacing10),
                  // Sign up link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: DesignSystem.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.go('/signup'),
                        child: Text(
                          'Sign Up',
                          style: DesignSystem.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignSystem.spacing6),
                  // Legal links
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _LegalLink(
                        label: 'Privacy Policy',
                        url: AppConfig.privacyPolicyUrl,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: DesignSystem.spacing3,
                        ),
                        child: Text(
                          '•',
                          style: DesignSystem.bodySmall.copyWith(
                            color: AppColors.textHint,
                          ),
                        ),
                      ),
                      _LegalLink(
                        label: 'Terms',
                        url: AppConfig.termsUrl,
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignSystem.spacing6),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LegalLink extends StatelessWidget {
  final String label;
  final String url;

  const _LegalLink({required this.label, required this.url});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => openExternalUrl(url),
      child: Text(
        label,
        style: DesignSystem.bodySmall.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
