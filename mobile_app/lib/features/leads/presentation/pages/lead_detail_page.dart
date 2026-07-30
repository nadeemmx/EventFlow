import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:eventflow_app/core/theme/app_colors.dart';
import 'package:eventflow_app/core/theme/app_dimens.dart';
import 'package:eventflow_app/core/widgets/premium_card.dart';
import 'package:eventflow_app/core/widgets/premium_avatar.dart';
import 'package:eventflow_app/core/widgets/status_chip.dart';
import 'package:eventflow_app/core/widgets/section_header.dart';
import 'package:eventflow_app/core/widgets/error_widget.dart';
import 'package:eventflow_app/core/widgets/login_required_sheet.dart';
import 'package:eventflow_app/features/leads/presentation/bloc/lead_bloc.dart';
import 'package:eventflow_app/features/authentication/presentation/bloc/auth_bloc.dart';

class LeadDetailPage extends StatefulWidget {
  final int id;
  const LeadDetailPage({super.key, required this.id});

  @override
  State<LeadDetailPage> createState() => _LeadDetailPageState();
}

class _LeadDetailPageState extends State<LeadDetailPage> {
  @override
  void initState() {
    super.initState();
    context.read<LeadBloc>().add(LoadLeadDetail(id: widget.id));
  }

  Color _leadStatusColor(String status) {
    switch (status) {
      case 'NEW':
        return AppColors.leadNew;
      case 'CONTACTED':
        return AppColors.leadContacted;
      case 'SITE_VISIT':
        return AppColors.leadSiteVisit;
      case 'NEGOTIATION':
        return AppColors.leadNegotiation;
      case 'CONVERTED':
        return AppColors.leadConverted;
      case 'LOST':
        return AppColors.leadLost;
      default:
        return AppColors.textSecondary;
    }
  }

  LinearGradient _leadStatusGradient(String status) {
    switch (status) {
      case 'NEW':
        return const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'CONTACTED':
        return const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'SITE_VISIT':
        return const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'NEGOTIATION':
        return const LinearGradient(
          colors: [Color(0xFFF97316), Color(0xFFEA580C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'CONVERTED':
        return AppColors.successGradient;
      case 'LOST':
        return const LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return AppColors.primaryGradient;
    }
  }

  String _leadStatusLabel(String status) {
    switch (status) {
      case 'NEW':
        return 'New';
      case 'CONTACTED':
        return 'Contacted';
      case 'SITE_VISIT':
        return 'Site Visit';
      case 'NEGOTIATION':
        return 'Negotiation';
      case 'CONVERTED':
        return 'Converted';
      case 'LOST':
        return 'Lost';
      default:
        return status;
    }
  }

  bool _isGuest(BuildContext context) {
    return context.read<AuthBloc>().state is AuthGuestAuthenticated;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LeadBloc, LeadState>(
      listener: (context, state) {
        if (state is LeadActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              ),
            ),
          );
          context.read<LeadBloc>().add(LoadLeadDetail(id: widget.id));
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          title: const Text(
            'Lead Detail',
            style: TextStyle(
              fontSize: AppDimens.fontXxl,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          actions: [
            PopupMenuButton<String>(
              icon: Container(
                padding: const EdgeInsets.all(AppDimens.sm),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: const Icon(
                  Icons.more_horiz_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              ),
              onSelected: (value) {
                if (_isGuest(context)) {
                  showLoginRequiredSheet(context);
                  return;
                }
                switch (value) {
                  case 'edit':
                    context.push('/leads/${widget.id}/edit');
                    break;
                  case 'convert':
                    _showConvertDialog(context);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                      SizedBox(width: 10),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'convert',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, size: 18, color: AppColors.success),
                      SizedBox(width: 10),
                      Text('Convert to Booking'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppDimens.sm),
          ],
        ),
        body: BlocBuilder<LeadBloc, LeadState>(
          builder: (context, state) {
            if (state is LeadsLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            if (state is LeadDetailLoaded) {
              final lead = state.lead;
              final statusColor = _leadStatusColor(lead.leadStatus);
              return RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.surface,
                onRefresh: () async {
                  context
                      .read<LeadBloc>()
                      .add(LoadLeadDetail(id: widget.id));
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusHeader(lead, statusColor),
                      const SizedBox(height: AppDimens.lg),
                      _buildCustomerSection(lead),
                      const SizedBox(height: AppDimens.md),
                      _buildLeadDetailsSection(lead),
                      const SizedBox(height: AppDimens.xxl),
                      _buildActionButtons(lead),
                      const SizedBox(height: AppDimens.huge),
                    ],
                  ),
                ),
              );
            }
            if (state is LeadError) {
              return AppErrorWidget(
                message: state.message,
                onRetry: () => context
                    .read<LeadBloc>()
                    .add(LoadLeadDetail(id: widget.id)),
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }

  Widget _buildStatusHeader(dynamic lead, Color statusColor) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(AppDimens.lg, 0, AppDimens.lg, 0),
      decoration: BoxDecoration(
        gradient: _leadStatusGradient(lead.leadStatus),
        borderRadius: BorderRadius.circular(AppDimens.radiusXl),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppDimens.xxl),
      child: Column(
        children: [
          StatusChip(
            label: _leadStatusLabel(lead.leadStatus),
            color: Colors.white,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            showDot: true,
          ),
          const SizedBox(height: AppDimens.md),
          Text(
            lead.customerName,
            style: const TextStyle(
              fontSize: AppDimens.fontXxl,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: AppDimens.xs),
          if (lead.leadSource != null)
            Text(
              lead.leadSource!,
              style: TextStyle(
                fontSize: AppDimens.fontMd,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCustomerSection(dynamic lead) {
    final initials = lead.customerName.isNotEmpty
        ? lead.customerName[0].toUpperCase()
        : '?';
    final statusColor = _leadStatusColor(lead.leadStatus);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.lg),
      child: PremiumCard(
        margin: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Customer', padding: EdgeInsets.zero),
            const SizedBox(height: AppDimens.sm),
            Row(
              children: [
                GradientAvatar(
                  initials: initials,
                  radius: AppDimens.avatarSm / 2,
                  gradient: _leadStatusGradient(lead.leadStatus),
                ),
                const SizedBox(width: AppDimens.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lead.customerName,
                        style: const TextStyle(
                          fontSize: AppDimens.fontBase,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ID: ${lead.customer}',
                        style: const TextStyle(
                          fontSize: AppDimens.fontSm,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusChip(
                  label: _leadStatusLabel(lead.leadStatus),
                  color: statusColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeadDetailsSection(dynamic lead) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.lg),
      child: PremiumCard(
        margin: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Lead Details', padding: EdgeInsets.zero),
            const SizedBox(height: AppDimens.sm),
            if (lead.eventType != null) ...[
              _detailRow('Event Type', lead.eventType!),
              const Divider(height: AppDimens.xxl, color: AppColors.borderLight),
            ],
            if (lead.expectedEventDate != null) ...[
              _detailRow('Expected Date', lead.expectedEventDate!),
              const Divider(height: AppDimens.xxl, color: AppColors.borderLight),
            ],
            if (lead.expectedGuestCount != null) ...[
              _detailRow('Expected Guests', lead.expectedGuestCount.toString()),
              const Divider(height: AppDimens.xxl, color: AppColors.borderLight),
            ],
            if (lead.leadSource != null)
              _detailRow('Lead Source', lead.leadSource!),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(dynamic lead) {
    final isGuest = _isGuest(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.lg),
      child: Column(
        children: [
          if (lead.leadStatus == 'NEW')
            _premiumButton(
              label: 'Mark Contacted',
              icon: Icons.phone_outlined,
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              onPressed: isGuest
                  ? () => showLoginRequiredSheet(context)
                  : () => context.read<LeadBloc>().add(UpdateLead(
                        id: widget.id,
                        data: {'lead_status': 'CONTACTED'},
                      )),
            ),
          if (lead.leadStatus == 'CONTACTED')
            _premiumButton(
              label: 'Mark Site Visit',
              icon: Icons.location_on_outlined,
              gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              onPressed: isGuest
                  ? () => showLoginRequiredSheet(context)
                  : () => context.read<LeadBloc>().add(UpdateLead(
                        id: widget.id,
                        data: {'lead_status': 'SITE_VISIT'},
                      )),
            ),
          if (lead.leadStatus == 'SITE_VISIT')
            _premiumButton(
              label: 'Mark Negotiation',
              icon: Icons.handshake_outlined,
              gradient: const LinearGradient(
                colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              onPressed: isGuest
                  ? () => showLoginRequiredSheet(context)
                  : () => context.read<LeadBloc>().add(UpdateLead(
                        id: widget.id,
                        data: {'lead_status': 'NEGOTIATION'},
                      )),
            ),
          if (lead.leadStatus == 'NEGOTIATION')
            _premiumButton(
              label: 'Convert to Booking',
              icon: Icons.check_circle_outline_rounded,
              gradient: AppColors.successGradient,
              onPressed: isGuest
                  ? () => showLoginRequiredSheet(context)
                  : () => _showConvertDialog(context),
            ),
          if (lead.leadStatus != 'CONVERTED' &&
              lead.leadStatus != 'LOST') ...[
            const SizedBox(height: AppDimens.md),
            SizedBox(
              width: double.infinity,
              height: AppDimens.buttonHeight,
              child: OutlinedButton.icon(
                onPressed: isGuest
                    ? () => showLoginRequiredSheet(context)
                    : () => context.read<LeadBloc>().add(UpdateLead(
                          id: widget.id,
                          data: {'lead_status': 'LOST'},
                        )),
                icon: const Icon(Icons.cancel_outlined, size: 20),
                label: const Text(
                  'Mark as Lost',
                  style: TextStyle(
                    fontSize: AppDimens.fontMd,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.leadLost,
                  side: const BorderSide(color: AppColors.leadLost, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _premiumButton({
    required String label,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: AppDimens.buttonHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 20),
          label: Text(
            label,
            style: const TextStyle(
              fontSize: AppDimens.fontMd,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: AppDimens.fontMd,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: AppDimens.fontMd,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _showConvertDialog(BuildContext context) {
    if (_isGuest(context)) {
      showLoginRequiredSheet(context);
      return;
    }
    final venueController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.dialogRadius),
        ),
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: AppColors.success, size: 24),
            SizedBox(width: AppDimens.sm),
            Text(
              'Convert to Booking',
              style: TextStyle(
                fontSize: AppDimens.fontLg,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: TextField(
          controller: venueController,
          decoration: InputDecoration(
            labelText: 'Venue ID',
            labelStyle: const TextStyle(color: AppColors.textSecondary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Go Back',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppColors.successGradient,
              borderRadius: BorderRadius.circular(AppDimens.radiusSm),
            ),
            child: TextButton(
              onPressed: () {
                final venueId = int.tryParse(venueController.text);
                if (venueId == null) return;
                Navigator.pop(ctx);
                context.read<LeadBloc>().add(ConvertLead(
                      id: widget.id,
                      venueId: venueId,
                    ));
              },
              child: const Text(
                'Convert',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
