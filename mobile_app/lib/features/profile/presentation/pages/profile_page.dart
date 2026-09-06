import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:eventflow_app/core/theme/app_colors.dart';
import 'package:eventflow_app/core/theme/app_dimens.dart';
import 'package:eventflow_app/core/theme/design_system.dart';
import 'package:eventflow_app/core/utils/formatters.dart';
import 'package:eventflow_app/core/services/image_picker_service.dart';
import 'package:eventflow_app/core/widgets/login_required_sheet.dart';
import 'package:eventflow_app/features/authentication/presentation/bloc/auth_bloc.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _imagePickerService = ImagePickerService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: AppColors.background,
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is AuthAuthenticated || state is AuthProfileLoaded || state is AuthProfileUpdated) {
            final user = state is AuthAuthenticated
                ? state.user
                : state is AuthProfileLoaded
                    ? state.user
                    : (state as AuthProfileUpdated).user;
            return ListView(
              padding: EdgeInsets.zero,
              children: [
                // Profile header
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: DesignSystem.primaryGradient,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(AppDimens.radiusXxl),
                      bottomRight: Radius.circular(AppDimens.radiusXxl),
                    ),
                  ),
                  padding: const EdgeInsets.only(
                    top: AppDimens.xxl,
                    bottom: AppDimens.xxxl,
                    left: AppDimens.xl,
                    right: AppDimens.xl,
                  ),
                  child: Column(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 104,
                            height: 104,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 3,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                (user.fullName.isNotEmpty ? user.fullName[0] : 'U').toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: GestureDetector(
                              onTap: () => _showImagePickerOptions(context, user),
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  shape: BoxShape.circle,
                                  boxShadow: AppColors.cardShadow,
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimens.lg),
                      Text(
                        user.fullName,
                        style: const TextStyle(
                          fontSize: AppDimens.fontXxl,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppDimens.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          Formatters.statusLabel(user.role),
                          style: const TextStyle(
                            fontSize: AppDimens.fontSm,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimens.xl),
                // Personal info
                _buildSectionHeader('Personal Information'),
                _buildInfoCard(
                  icon: Icons.email_outlined,
                  iconColor: AppColors.info,
                  label: 'Email',
                  value: user.email,
                ),
                _buildInfoCard(
                  icon: Icons.phone_outlined,
                  iconColor: AppColors.success,
                  label: 'Mobile',
                  value: Formatters.phone(user.mobile),
                ),
                _buildInfoCard(
                  icon: Icons.badge_outlined,
                  iconColor: AppColors.accent,
                  label: 'Role',
                  value: Formatters.statusLabel(user.role),
                ),
                if (user.tenantId != null)
                  _buildInfoCard(
                    icon: Icons.business_outlined,
                    iconColor: AppColors.secondary,
                    label: 'Tenant ID',
                    value: user.tenantId.toString(),
                  ),
                const SizedBox(height: AppDimens.lg),
                // Actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimens.lg),
                  child: SizedBox(
                    width: double.infinity,
                    height: AppDimens.buttonHeight,
                    child: ElevatedButton.icon(
                      onPressed: () => _showEditDialog(context, user),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit Profile'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimens.sm),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimens.lg),
                  child: SizedBox(
                    width: double.infinity,
                    height: AppDimens.buttonHeight,
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/settings'),
                      icon: const Icon(Icons.settings_outlined, size: 18),
                      label: const Text('Settings'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimens.sm),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimens.lg),
                  child: SizedBox(
                    width: double.infinity,
                    height: AppDimens.buttonHeight,
                    child: TextButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppDimens.dialogRadius),
                            ),
                            title: const Text('Logout'),
                            content: const Text('Are you sure you want to logout?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  context.read<AuthBloc>().add(LogoutRequested());
                                },
                                child: const Text(
                                  'Logout',
                                  style: TextStyle(color: AppColors.error),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.logout_rounded, size: 18, color: AppColors.error),
                      label: const Text(
                        'Logout',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimens.xxl),
              ],
            );
          }
          return const Center(child: Text('Please login'));
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.lg, vertical: AppDimens.sm),
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

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.lg, vertical: AppDimens.xs),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.lg, vertical: AppDimens.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.cardRadius),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
              ),
              child: Icon(icon, color: iconColor, size: AppDimens.iconMd),
            ),
            const SizedBox(width: AppDimens.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: AppDimens.fontXs,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textTertiary,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: AppDimens.fontBase,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, dynamic user) {
    final nameController = TextEditingController(text: user.fullName);
    final mobileController = TextEditingController(text: user.mobile ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.dialogRadius),
        ),
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: AppDimens.md),
            TextField(
              controller: mobileController,
              decoration: InputDecoration(
                labelText: 'Mobile',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (user.id == 0) {
                Navigator.pop(ctx);
                showLoginRequiredSheet(context);
                return;
              }
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(
                    UpdateProfileRequested(data: {
                      'full_name': nameController.text.trim(),
                      'mobile': mobileController.text.trim(),
                    }),
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showImagePickerOptions(BuildContext context, dynamic user) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimens.bottomSheetRadius),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: AppDimens.md),
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppDimens.lg),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                ),
                child: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
              ),
              title: const Text('Take Photo'),
              subtitle: const Text(
                'Use camera to take a photo',
                style: TextStyle(fontSize: AppDimens.fontSm, color: AppColors.textTertiary),
              ),
              onTap: () async {
                if (user.id == 0) {
                  Navigator.pop(ctx);
                  showLoginRequiredSheet(context);
                  return;
                }
                Navigator.pop(ctx);
                final file = await _imagePickerService.pickFromCamera();
                if (file != null) {
                  if (context.mounted) {
                    context.read<AuthBloc>().add(UploadProfileImage(filePath: file.path));
                  }
                }
              },
            ),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                ),
                child: const Icon(Icons.photo_library_rounded, color: AppColors.success),
              ),
              title: const Text('Choose from Gallery'),
              subtitle: const Text(
                'Pick from your photo library',
                style: TextStyle(fontSize: AppDimens.fontSm, color: AppColors.textTertiary),
              ),
              onTap: () async {
                if (user.id == 0) {
                  Navigator.pop(ctx);
                  showLoginRequiredSheet(context);
                  return;
                }
                Navigator.pop(ctx);
                final file = await _imagePickerService.pickFromGallery();
                if (file != null) {
                  if (context.mounted) {
                    context.read<AuthBloc>().add(UploadProfileImage(filePath: file.path));
                  }
                }
              },
            ),
            const SizedBox(height: AppDimens.md),
          ],
        ),
      ),
    );
  }
}
