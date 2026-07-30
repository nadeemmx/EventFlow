import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:eventflow_app/core/theme/app_colors.dart';
import 'package:eventflow_app/core/theme/app_dimens.dart';
import 'package:eventflow_app/core/widgets/premium_search_bar.dart';
import 'package:eventflow_app/core/widgets/premium_card.dart';
import 'package:eventflow_app/core/widgets/premium_avatar.dart';
import 'package:eventflow_app/core/widgets/premium_animated_widgets.dart';
import 'package:eventflow_app/core/widgets/status_chip.dart';
import 'package:eventflow_app/core/widgets/empty_state_widget.dart';
import 'package:eventflow_app/core/widgets/error_widget.dart';
import 'package:eventflow_app/core/widgets/loading_widget.dart';
import 'package:eventflow_app/core/widgets/demo_banner.dart';
import 'package:eventflow_app/core/widgets/login_required_sheet.dart';
import 'package:eventflow_app/features/leads/presentation/bloc/lead_bloc.dart';
import 'package:eventflow_app/features/authentication/presentation/bloc/auth_bloc.dart';

class LeadListPage extends StatefulWidget {
  const LeadListPage({super.key});

  @override
  State<LeadListPage> createState() => _LeadListPageState();
}

class _LeadListPageState extends State<LeadListPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<LeadBloc>().add(const LoadLeads());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final state = context.read<LeadBloc>().state;
      if (state is LeadsLoaded && state.hasMore) {
        context.read<LeadBloc>().add(LoadLeads(
              page: state.currentPage + 1,
              search: _searchController.text,
            ));
      }
    }
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

  Color _leadStatusBgColor(String status) {
    switch (status) {
      case 'NEW':
        return AppColors.leadNewBg;
      case 'CONTACTED':
        return AppColors.leadContactedBg;
      case 'SITE_VISIT':
        return AppColors.leadSiteVisitBg;
      case 'NEGOTIATION':
        return AppColors.leadNegotiationBg;
      case 'CONVERTED':
        return AppColors.leadConvertedBg;
      case 'LOST':
        return AppColors.leadLostBg;
      default:
        return AppColors.surface;
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

  LinearGradient _avatarGradient(String status) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Leads',
          style: TextStyle(
            fontSize: AppDimens.fontXxl,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppDimens.md),
            child: Container(
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                onPressed: () {
                  final authState = context.read<AuthBloc>().state;
                  if (authState is AuthGuestAuthenticated) {
                    showLoginRequiredSheet(context);
                  } else {
                    context.push('/leads/new');
                  }
                },
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const DemoBanner(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimens.lg, AppDimens.sm, AppDimens.lg, AppDimens.sm,
            ),
            child: PremiumSearchBar(
              controller: _searchController,
              hintText: 'Search leads...',
              onSubmitted: (v) => context
                  .read<LeadBloc>()
                  .add(LoadLeads(search: v, refresh: true)),
              onClear: () => context
                  .read<LeadBloc>()
                  .add(const LoadLeads(refresh: true)),
            ),
          ),
          Expanded(
            child: BlocBuilder<LeadBloc, LeadState>(
              builder: (context, state) {
                if (state is LeadsLoading) {
                  return const ShimmerList();
                }
                if (state is LeadDetailLoaded || state is LeadActionSuccess) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }
                if (state is LeadError) {
                  return AppErrorWidget(
                    message: state.message,
                    onRetry: () =>
                        context.read<LeadBloc>().add(const LoadLeads()),
                  );
                }
                if (state is LeadsLoaded) {
                  if (state.leads.isEmpty) {
                    return const EmptyStateWidget(
                      icon: Icons.trending_up_rounded,
                      title: 'No leads found',
                      subtitle: 'Create your first lead to get started',
                    );
                  }
                  return RefreshIndicator(
                    color: AppColors.primary,
                    backgroundColor: AppColors.surface,
                    onRefresh: () async {
                      context
                          .read<LeadBloc>()
                          .add(const LoadLeads(refresh: true));
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.lg,
                        vertical: AppDimens.sm,
                      ),
                      itemCount:
                          state.leads.length + (state.hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= state.leads.length) {
                          return const Padding(
                            padding: EdgeInsets.all(AppDimens.lg),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                                strokeWidth: 2.5,
                              ),
                            ),
                          );
                        }
                        final lead = state.leads[index];
                        return StaggeredListItem(
                          index: index,
                          totalCount: state.leads.length,
                          child: _buildLeadItem(lead),
                        );
                      },
                    ),
                  );
                }
                return const ShimmerList();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeadItem(dynamic lead) {
    final statusColor = _leadStatusColor(lead.leadStatus);
    final bgColor = _leadStatusBgColor(lead.leadStatus);
    final initials = lead.customerName.isNotEmpty
        ? lead.customerName[0].toUpperCase()
        : '?';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.sm),
      child: PremiumCard(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(AppDimens.lg),
        onTap: () => context.push('/leads/${lead.id}'),
        child: Row(
          children: [
            StatusAvatar(
              initials: initials,
              statusColor: statusColor,
              radius: AppDimens.avatarMd / 2,
              gradient: _avatarGradient(lead.leadStatus),
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
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppDimens.xs),
                  Row(
                    children: [
                      if (lead.leadSource != null) ...[
                        Flexible(
                          child: Text(
                            lead.leadSource!,
                            style: const TextStyle(
                              fontSize: AppDimens.fontSm,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (lead.eventType != null)
                          const Text(
                            ' · ',
                            style: TextStyle(
                              fontSize: AppDimens.fontSm,
                              color: AppColors.textTertiary,
                            ),
                          ),
                      ],
                      if (lead.eventType != null)
                        Flexible(
                          child: Text(
                            lead.eventType!,
                            style: const TextStyle(
                              fontSize: AppDimens.fontSm,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDimens.sm),
            StatusChip(
              label: _leadStatusLabel(lead.leadStatus),
              color: statusColor,
              backgroundColor: bgColor,
              small: true,
            ),
          ],
        ),
      ),
    );
  }
}
