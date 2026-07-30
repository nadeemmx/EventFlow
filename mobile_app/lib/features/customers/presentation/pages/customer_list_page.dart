import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:eventflow_app/core/theme/app_colors.dart';
import 'package:eventflow_app/core/theme/app_dimens.dart';
import 'package:eventflow_app/core/widgets/premium_animated_widgets.dart';
import 'package:eventflow_app/features/customers/presentation/bloc/customer_bloc.dart';
import 'package:eventflow_app/core/widgets/loading_widget.dart';
import 'package:eventflow_app/core/widgets/error_widget.dart';
import 'package:eventflow_app/core/widgets/empty_state_widget.dart';
import 'package:eventflow_app/core/widgets/demo_banner.dart';
import 'package:eventflow_app/core/widgets/login_required_sheet.dart';
import 'package:eventflow_app/core/widgets/premium_search_bar.dart';
import 'package:eventflow_app/core/widgets/premium_avatar.dart';
import 'package:eventflow_app/core/widgets/enhanced_search_sheet.dart';
import 'package:eventflow_app/features/authentication/presentation/bloc/auth_bloc.dart';

class CustomerListPage extends StatefulWidget {
  const CustomerListPage({super.key});
  @override
  State<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends State<CustomerListPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Map<String, dynamic> _activeFilters = {};

  @override
  void initState() {
    super.initState();
    context.read<CustomerBloc>().add(const LoadCustomers());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final state = context.read<CustomerBloc>().state;
      if (state is CustomersLoaded && state.hasMore) {
        context.read<CustomerBloc>().add(LoadCustomers(page: state.currentPage + 1, search: _searchController.text));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: AppDimens.lg),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppDimens.radiusSm),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.add_rounded, color: Colors.white, size: AppDimens.iconMd),
              onPressed: () {
                final authState = context.read<AuthBloc>().state;
                if (authState is AuthGuestAuthenticated) {
                  showLoginRequiredSheet(context);
                } else {
                  context.push('/customers/new');
                }
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const DemoBanner(),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppDimens.lg, AppDimens.sm, AppDimens.lg, AppDimens.md),
            child: Row(
              children: [
                Expanded(
                  child: PremiumSearchBar(
                    controller: _searchController,
                    hintText: 'Search customers...',
                    onSubmitted: (v) => context.read<CustomerBloc>().add(LoadCustomers(search: v, refresh: true)),
                    onClear: () => context.read<CustomerBloc>().add(const LoadCustomers(refresh: true)),
                  ),
                ),
                const SizedBox(width: AppDimens.sm),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.tune_rounded,
                          color: AppColors.textTertiary,
                          size: 20,
                        ),
                        onPressed: _openFilterSheet,
                      ),
                    ),
                    if (_activeFilters.isNotEmpty)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${_activeFilters.length}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<CustomerBloc, CustomerState>(
              builder: (context, state) {
                if (state is CustomersLoading || state is CustomerDetailLoaded || state is CustomerActionSuccess) {
                  if (state is CustomersLoading) {
                    return const ShimmerList();
                  }
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is CustomerError) {
                  return AppErrorWidget(message: state.message, onRetry: () => context.read<CustomerBloc>().add(const LoadCustomers()));
                }
                if (state is CustomersLoaded) {
                  if (state.customers.isEmpty) {
                    return EmptyStateWidget(
                      icon: Icons.people_outline_rounded,
                      title: 'No customers found',
                      subtitle: 'Add your first customer to get started',
                      tips: [
                        'Tap the + button to add a new customer',
                        'Use search to find specific customers',
                        'Pull down to refresh the list',
                      ],
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async => context.read<CustomerBloc>().add(const LoadCustomers(refresh: true)),
                    color: AppColors.primary,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(AppDimens.lg, 0, AppDimens.lg, AppDimens.xl),
                      itemCount: state.customers.length + (state.hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= state.customers.length) {
                          return const Padding(
                            padding: EdgeInsets.all(AppDimens.xl),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final c = state.customers[index];
                        final initials = c.fullName.isNotEmpty ? c.fullName[0].toUpperCase() : '?';
                        return StaggeredListItem(
                          index: index,
                          totalCount: state.customers.length,
                          child: _CustomerListTile(
                            initials: initials,
                            name: c.fullName,
                            phone: c.mobile,
                            onTap: () => context.push('/customers/${c.id}'),
                          ),
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

  void _openFilterSheet() {
    EnhancedSearchSheet.show(
      context,
      currentFilters: _activeFilters,
      onApply: (filters) {
        setState(() => _activeFilters = filters);
        context.read<CustomerBloc>().add(
          LoadCustomers(
            search: filters['search'] as String?,
            refresh: true,
          ),
        );
      },
      onClear: () {
        setState(() => _activeFilters = {});
        context.read<CustomerBloc>().add(const LoadCustomers(refresh: true));
      },
    );
  }
}

class _CustomerListTile extends StatelessWidget {
  final String initials;
  final String name;
  final String phone;
  final VoidCallback onTap;

  const _CustomerListTile({
    required this.initials,
    required this.name,
    required this.phone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.sm),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimens.cardRadius),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.lg, vertical: AppDimens.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDimens.cardRadius),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                GradientAvatar(
                  initials: initials,
                  radius: AppDimens.avatarMd / 2,
                ),
                const SizedBox(width: AppDimens.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: AppDimens.fontBase,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        phone,
                        style: const TextStyle(
                          fontSize: AppDimens.fontSm,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textTertiary,
                  size: AppDimens.iconMd,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
