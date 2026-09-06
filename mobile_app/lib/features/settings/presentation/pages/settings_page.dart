import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:eventflow_app/core/theme/app_colors.dart';
import 'package:eventflow_app/core/theme/app_dimens.dart';
import 'package:eventflow_app/core/theme/design_system.dart';
import 'package:eventflow_app/core/theme/theme_provider.dart';
import 'package:eventflow_app/core/widgets/demo_banner.dart';
import 'package:eventflow_app/core/widgets/login_required_sheet.dart';
import 'package:eventflow_app/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:eventflow_app/injector.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: AppColors.background,
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DemoBanner(),
          _buildSectionHeader('Appearance'),
          _AppearanceSection(),
          _buildSectionHeader('Profile'),
          _buildSettingsCard(
            children: [
              _SettingTile(
                icon: Icons.person_outline_rounded,
                iconColor: AppColors.primary,
                title: 'My Profile',
                onTap: () => context.push('/profile'),
              ),
              const Divider(height: 1, indent: 56),
              _SettingTile(
                icon: Icons.lock_outline_rounded,
                iconColor: AppColors.warning,
                title: 'Change Password',
                onTap: () {
                  final state = context.read<AuthBloc>().state;
                  if (state is AuthGuestAuthenticated) {
                    showLoginRequiredSheet(context);
                  }
                },
              ),
            ],
          ),
          _buildSectionHeader('Business'),
          _buildSettingsCard(
            children: [
              _SettingTile(
                icon: Icons.payments_outlined,
                iconColor: AppColors.success,
                title: 'Payment Gateway',
                onTap: () {},
              ),
              const Divider(height: 1, indent: 56),
              _SettingTile(
                icon: Icons.email_outlined,
                iconColor: AppColors.info,
                title: 'Email Settings',
                onTap: () {},
              ),
              const Divider(height: 1, indent: 56),
              _SettingTile(
                icon: Icons.receipt_outlined,
                iconColor: AppColors.accent,
                title: 'Invoice Settings',
                onTap: () {},
              ),
              const Divider(height: 1, indent: 56),
              _SettingTile(
                icon: Icons.event_outlined,
                iconColor: AppColors.secondary,
                title: 'Booking Settings',
                onTap: () {},
              ),
              const Divider(height: 1, indent: 56),
              _SettingTile(
                icon: Icons.palette_outlined,
                iconColor: AppColors.primaryLight,
                title: 'Branding',
                onTap: () {},
              ),
              const Divider(height: 1, indent: 56),
              _SettingTile(
                icon: Icons.business_outlined,
                iconColor: AppColors.textSecondary,
                title: 'Organization',
                onTap: () {},
              ),
            ],
          ),
          _buildSectionHeader('System'),
          _buildSettingsCard(
            children: [
              _SettingTile(
                icon: Icons.subscriptions_outlined,
                iconColor: AppColors.accent,
                title: 'Subscription',
                onTap: () {},
              ),
              const Divider(height: 1, indent: 56),
              _SettingTile(
                icon: Icons.group_outlined,
                iconColor: AppColors.info,
                title: 'Users',
                onTap: () {},
              ),
              const Divider(height: 1, indent: 56),
              _SettingTile(
                icon: Icons.verified_user_outlined,
                iconColor: AppColors.success,
                title: 'Roles & Permissions',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: AppDimens.xxl),
          Center(
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: AppColors.primarySurface,
                    shape: BoxShape.circle,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 24,
                      height: 24,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.event_available_rounded,
                          size: 18,
                          color: AppColors.primary.withValues(alpha: 0.6),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: AppDimens.sm),
                const Text(
                  'EventFlow',
                  style: TextStyle(
                    fontSize: AppDimens.fontSm,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    fontSize: AppDimens.fontXs,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.xxxl),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: DesignSystem.titleSmall.copyWith(
          color: AppColors.textTertiary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimens.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(children: children),
    );
  }
}

class _AppearanceSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = sl<ThemeProvider>();

    return ListenableBuilder(
      listenable: themeProvider,
      builder: (context, _) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: AppDimens.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimens.cardRadius),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            children: [
              _AppearanceOption(
                icon: Icons.light_mode_outlined,
                title: 'Light',
                isSelected: themeProvider.themeMode == ThemeMode.light,
                onTap: () => themeProvider.setThemeMode(ThemeMode.light),
              ),
              const Divider(height: 1, indent: 56),
              _AppearanceOption(
                icon: Icons.dark_mode_outlined,
                title: 'Dark',
                isSelected: themeProvider.themeMode == ThemeMode.dark,
                onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
              ),
              const Divider(height: 1, indent: 56),
              _AppearanceOption(
                icon: Icons.brightness_auto_outlined,
                title: 'System',
                isSelected: themeProvider.themeMode == ThemeMode.system,
                onTap: () => themeProvider.setThemeMode(ThemeMode.system),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AppearanceOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _AppearanceOption({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.lg,
          vertical: AppDimens.md,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
              ),
              child: Icon(icon, size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: AppDimens.md),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: AppDimens.fontBase,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;

  const _SettingTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.lg,
          vertical: AppDimens.md,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: AppDimens.md),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: AppDimens.fontBase,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textHint,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
