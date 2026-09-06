import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:eventflow_app/core/theme/design_system.dart';
import 'package:eventflow_app/core/utils/validators.dart';
import 'package:eventflow_app/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:eventflow_app/features/authentication/presentation/widgets/auth_text_field.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _emailFocus = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            ForgotPasswordRequested(email: _emailController.text.trim()),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthPasswordResetSent) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Password reset link sent to your email'),
              backgroundColor: DesignSystem.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignSystem.radiusMd),
              ),
            ),
          );
          context.pop();
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
                        Icons.lock_reset_rounded,
                        size: 40,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: DesignSystem.spacing8),
                  Text(
                    'Forgot password?',
                    style: DesignSystem.headlineMedium.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: DesignSystem.spacing2),
                  Text(
                    "No worries, we'll send you reset instructions",
                    style: DesignSystem.bodyMedium.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: DesignSystem.spacing10),
                  AuthTextField(
                    controller: _emailController,
                    focusNode: _emailFocus,
                    hint: 'Email address',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    onEditingComplete: _onSubmit,
                    validator: Validators.email,
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
                            : const Text('Send Reset Link'),
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
