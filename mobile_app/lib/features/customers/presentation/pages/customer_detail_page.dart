import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:eventflow_app/core/theme/app_colors.dart';
import 'package:eventflow_app/core/theme/app_dimens.dart';
import 'package:eventflow_app/features/customers/presentation/bloc/customer_bloc.dart';
import 'package:eventflow_app/core/widgets/login_required_sheet.dart';
import 'package:eventflow_app/core/widgets/premium_card.dart';
import 'package:eventflow_app/core/widgets/premium_avatar.dart';
import 'package:eventflow_app/core/widgets/section_header.dart';
import 'package:eventflow_app/core/widgets/error_widget.dart';
import 'package:eventflow_app/features/authentication/presentation/bloc/auth_bloc.dart';

class CustomerDetailPage extends StatefulWidget {
  final int id;
  const CustomerDetailPage({super.key, required this.id});
  @override
  State<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends State<CustomerDetailPage> {
  @override
  void initState() {
    super.initState();
    context.read<CustomerBloc>().add(LoadCustomerDetail(id: widget.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Customer Detail'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: AppDimens.lg),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(AppDimens.radiusSm),
            ),
            child: IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: AppDimens.iconMd),
              onPressed: () {
                if (context.read<AuthBloc>().state is AuthGuestAuthenticated) {
                  showLoginRequiredSheet(context);
                } else {
                  context.push('/customers/${widget.id}/edit');
                }
              },
            ),
          ),
        ],
      ),
      body: BlocBuilder<CustomerBloc, CustomerState>(
        builder: (context, state) {
          if (state is CustomersLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is CustomerDetailLoaded) {
            final c = state.customer;
            final initials = c.fullName.isNotEmpty ? c.fullName[0].toUpperCase() : '?';
            return RefreshIndicator(
              onRefresh: () async => context.read<CustomerBloc>().add(LoadCustomerDetail(id: widget.id)),
              color: AppColors.primary,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppDimens.lg, 0, AppDimens.lg, AppDimens.xxxl),
                children: [
                  const SizedBox(height: AppDimens.xl),
                  Center(
                    child: Column(
                      children: [
                        GradientAvatar(
                          initials: initials,
                          radius: AppDimens.avatarXl / 2,
                        ),
                        const SizedBox(height: AppDimens.lg),
                        Text(
                          c.fullName,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppDimens.xs),
                        Text(
                          c.mobile,
                          style: const TextStyle(
                            fontSize: AppDimens.fontBase,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimens.xxxl),
                  const SectionHeader(title: 'Contact Information'),
                  PremiumCard(
                    margin: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _DetailRow(
                          icon: Icons.phone_rounded,
                          label: 'Mobile',
                          value: c.mobile,
                        ),
                        if (c.email != null && c.email!.isNotEmpty) ...[
                          const Divider(height: AppDimens.xxl, color: AppColors.borderLight),
                          _DetailRow(
                            icon: Icons.email_rounded,
                            label: 'Email',
                            value: c.email!,
                          ),
                        ],
                        if (c.address != null && c.address!.isNotEmpty) ...[
                          const Divider(height: AppDimens.xxl, color: AppColors.borderLight),
                          _DetailRow(
                            icon: Icons.location_on_rounded,
                            label: 'Address',
                            value: c.address!,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (c.remarks != null && c.remarks!.isNotEmpty) ...[
                    const SectionHeader(title: 'Notes'),
                    PremiumCard(
                      margin: EdgeInsets.zero,
                      child: Text(
                        c.remarks!,
                        style: const TextStyle(
                          fontSize: AppDimens.fontMd,
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                  if (c.createdAt != null && c.createdAt!.isNotEmpty) ...[
                    const SectionHeader(title: 'Details'),
                    PremiumCard(
                      margin: EdgeInsets.zero,
                      child: _DetailRow(
                        icon: Icons.calendar_today_rounded,
                        label: 'Added on',
                        value: c.createdAt!,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }
          if (state is CustomerError) {
            return AppErrorWidget(
              message: state.message,
              onRetry: () => context.read<CustomerBloc>().add(LoadCustomerDetail(id: widget.id)),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(AppDimens.radiusSm),
          ),
          child: Icon(icon, size: AppDimens.iconSm, color: AppColors.primary),
        ),
        const SizedBox(width: AppDimens.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: AppDimens.fontSm,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: AppDimens.fontBase,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
