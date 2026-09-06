import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:eventflow_app/core/theme/design_system.dart';
import 'package:eventflow_app/core/utils/validators.dart';
import 'package:eventflow_app/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:eventflow_app/features/authentication/presentation/widgets/auth_text_field.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _tokenFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _tokenFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            ResetPasswordRequested(
              token: _tokenController.text.trim(),
              password: _passwordController.text,
              confirmPassword: _confirmPasswordController.text,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthPasswordResetSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Password reset successfully'),
              backgroundColor: DesignSystem.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignSystem.radiusMd),
              ),
            ),
          );
          context.go('/login');
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
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: colorScheme.onSurface,
            ),
            onPressed: () => context.pop(),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spacing6),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: DesignSystem.spacing4),
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(DesignSystem.radiusXl),
                      ),
                      child: Icon(
                        Icons.vpn_key_rounded,
                        size: 40,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: DesignSystem.spacing8),
                  Text(
                    'Reset password',
                    style: DesignSystem.headlineMedium.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: DesignSystem.spacing2),
                  Text(
                    'Enter your reset token and new password',
                    style: DesignSystem.bodyMedium.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: DesignSystem.spacing8),
                  AuthTextField(
                    controller: _tokenController,
                    focusNode: _tokenFocus,
                    hint: 'Reset token',
                    prefixIcon: Icons.vpn_key_rounded,
                    textInputAction: TextInputAction.next,
                    validator: (v) => Validators.required(v, 'Token'),
                    onEditingComplete: () => _passwordFocus.requestFocus(),
                  ),
                  const SizedBox(height: DesignSystem.spacing4),
                  AuthTextField(
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    hint: 'New password',
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
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onSuffixTap: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  const SizedBox(height: DesignSystem.spacing4),
                  AuthTextField(
                    controller: _confirmPasswordController,
                    focusNode: _confirmPasswordFocus,
                    hint: 'Confirm password',
                    prefixIcon: Icons.lock_outlined,
                    obscureText: _obscureConfirmPassword,
                    textInputAction: TextInputAction.done,
                    onEditingComplete: _onSubmit,
                    validator: (v) => Validators.confirmPassword(
                      v,
                      _passwordController.text,
                    ),
                    suffixIcon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      size: 22,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onSuffixTap: () => setState(
                        () => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                  const SizedBox(height: DesignSystem.spacing6),
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final isLoading = state is AuthLoading;
                      return FilledButton(
                        onPressed: isLoading ? null : _onSubmit,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(double.infinity, 56),
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          disabledBackgroundColor: colorScheme.onSurface.withValues(alpha: 0.12),
                          disabledForegroundColor: colorScheme.onSurface.withValues(alpha: 0.38),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(DesignSystem.radiusMd),
                          ),
                          textStyle: DesignSystem.titleMedium.copyWith(
                            color: colorScheme.onPrimary,
                          ),
                        ),
                        child: isLoading
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: colorScheme.onPrimary,
                                ),
                              )
                            : const Text('Reset Password'),
                      );
                    },
                  ),
                  const SizedBox(height: DesignSystem.spacing6),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: Text(
                      'Back to Sign In',
                      style: DesignSystem.bodyMedium.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
