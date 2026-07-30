import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eventflow_app/core/theme/app_colors.dart';
import 'package:eventflow_app/core/theme/app_dimens.dart';
import 'package:eventflow_app/core/utils/formatters.dart';
import 'package:eventflow_app/features/payments/presentation/bloc/payment_bloc.dart';
import 'package:eventflow_app/core/widgets/loading_widget.dart';
import 'package:eventflow_app/core/widgets/error_widget.dart';
import 'package:eventflow_app/core/widgets/empty_state_widget.dart';
import 'package:eventflow_app/core/widgets/premium_card.dart';
import 'package:eventflow_app/core/widgets/status_chip.dart';
import 'package:eventflow_app/core/widgets/demo_banner.dart';
import 'package:eventflow_app/core/widgets/section_header.dart';

class PaymentListPage extends StatefulWidget {
  const PaymentListPage({super.key});

  @override
  State<PaymentListPage> createState() => _PaymentListPageState();
}

class _PaymentListPageState extends State<PaymentListPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<PaymentBloc>().add(const LoadPayments());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final state = context.read<PaymentBloc>().state;
      if (state is PaymentListLoaded && state.hasMore) {
        context.read<PaymentBloc>().add(LoadPayments(page: state.currentPage + 1));
      }
    }
  }

  Color _methodColor(String method) {
    switch (method.toUpperCase()) {
      case 'CASH':
        return AppColors.success;
      case 'CARD':
        return AppColors.info;
      case 'UPI':
        return AppColors.primary;
      case 'BANK_TRANSFER':
        return AppColors.warning;
      case 'CHEQUE':
        return AppColors.secondary;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _methodIcon(String method) {
    switch (method.toUpperCase()) {
      case 'CASH':
        return Icons.payments_rounded;
      case 'CARD':
        return Icons.credit_card_rounded;
      case 'UPI':
        return Icons.qr_code_rounded;
      case 'BANK_TRANSFER':
        return Icons.account_balance_rounded;
      case 'CHEQUE':
        return Icons.receipt_rounded;
      default:
        return Icons.payments_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Payments',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          const DemoBanner(),
          Expanded(
            child: BlocBuilder<PaymentBloc, PaymentState>(
              builder: (context, state) {
                if (state is PaymentLoading || state is PaymentOrderCreated || state is PaymentVerificationSuccess) {
                  if (state is PaymentLoading) {
                    return const ShimmerList();
                  }
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is PaymentError) {
                  return AppErrorWidget(
                    message: state.message,
                    onRetry: () => context.read<PaymentBloc>().add(const LoadPayments()),
                  );
                }
                if (state is PaymentListLoaded) {
                  if (state.payments.isEmpty) {
                    return const EmptyStateWidget(
                      icon: Icons.payments_outlined,
                      title: 'No payments found',
                      subtitle: 'Payments will appear here once recorded',
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<PaymentBloc>().add(const LoadPayments(refresh: true));
                    },
                    child: CustomScrollView(
                      controller: _scrollController,
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(AppDimens.lg, AppDimens.md, AppDimens.lg, AppDimens.xs),
                          sliver: SliverToBoxAdapter(
                            child: SectionHeader(
                              title: '${state.payments.length} payment${state.payments.length == 1 ? '' : 's'}',
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: AppDimens.lg),
                          sliver: SliverList.builder(
                            itemCount: state.payments.length + (state.hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index >= state.payments.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(AppDimens.lg),
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              }
                              final payment = state.payments[index];
                              final methodColor = _methodColor(payment.paymentMethod);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: AppDimens.sm),
                                child: PremiumCard(
                                  margin: EdgeInsets.zero,
                                  padding: const EdgeInsets.all(AppDimens.lg),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: AppDimens.avatarLg,
                                        height: AppDimens.avatarLg,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              methodColor,
                                              methodColor.withValues(alpha: 0.7),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                                        ),
                                        child: Icon(
                                          _methodIcon(payment.paymentMethod),
                                          color: Colors.white,
                                          size: AppDimens.iconLg,
                                        ),
                                      ),
                                      const SizedBox(width: AppDimens.md),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              Formatters.currency(payment.amount),
                                              style: const TextStyle(
                                                fontSize: AppDimens.fontLg,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textPrimary,
                                                letterSpacing: -0.3,
                                              ),
                                            ),
                                            const SizedBox(height: AppDimens.xs),
                                            Text(
                                              payment.bookingNumber,
                                              style: const TextStyle(
                                                fontSize: AppDimens.fontMd,
                                                color: AppColors.textSecondary,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              payment.paymentDate,
                                              style: const TextStyle(
                                                fontSize: AppDimens.fontSm,
                                                color: AppColors.textTertiary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: AppDimens.sm),
                                      StatusChip(
                                        label: Formatters.statusLabel(payment.paymentMethod),
                                        color: methodColor,
                                        small: true,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SliverPadding(
                          padding: EdgeInsets.only(bottom: AppDimens.xxxl),
                        ),
                      ],
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
}
