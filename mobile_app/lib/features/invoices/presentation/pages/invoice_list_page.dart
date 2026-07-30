import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:eventflow_app/core/theme/app_colors.dart';
import 'package:eventflow_app/core/theme/app_dimens.dart';
import 'package:eventflow_app/core/utils/formatters.dart';
import 'package:eventflow_app/features/invoices/presentation/bloc/invoice_bloc.dart';
import 'package:eventflow_app/core/widgets/loading_widget.dart';
import 'package:eventflow_app/core/widgets/error_widget.dart';
import 'package:eventflow_app/core/widgets/empty_state_widget.dart';
import 'package:eventflow_app/core/widgets/premium_card.dart';
import 'package:eventflow_app/core/widgets/demo_banner.dart';
import 'package:eventflow_app/core/widgets/section_header.dart';

class InvoiceListPage extends StatefulWidget {
  const InvoiceListPage({super.key});

  @override
  State<InvoiceListPage> createState() => _InvoiceListPageState();
}

class _InvoiceListPageState extends State<InvoiceListPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<InvoiceBloc>().add(const LoadInvoices());
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
      final state = context.read<InvoiceBloc>().state;
      if (state is InvoiceListLoaded && state.hasMore) {
        context.read<InvoiceBloc>().add(LoadInvoices(page: state.currentPage + 1));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Invoices',
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
            child: BlocBuilder<InvoiceBloc, InvoiceState>(
              builder: (context, state) {
                if (state is InvoiceLoading || state is InvoiceDetailLoaded) {
                  if (state is InvoiceLoading) {
                    return const ShimmerList();
                  }
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is InvoiceError) {
                  return AppErrorWidget(
                    message: state.message,
                    onRetry: () => context.read<InvoiceBloc>().add(const LoadInvoices()),
                  );
                }
                if (state is InvoiceListLoaded) {
                  if (state.invoices.isEmpty) {
                    return const EmptyStateWidget(
                      icon: Icons.receipt_long_rounded,
                      title: 'No invoices found',
                      subtitle: 'Invoices will appear here once generated',
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<InvoiceBloc>().add(const LoadInvoices(refresh: true));
                    },
                    child: CustomScrollView(
                      controller: _scrollController,
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(AppDimens.lg, AppDimens.md, AppDimens.lg, AppDimens.xs),
                          sliver: SliverToBoxAdapter(
                            child: SectionHeader(
                              title: '${state.invoices.length} invoice${state.invoices.length == 1 ? '' : 's'}',
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: AppDimens.lg),
                          sliver: SliverList.builder(
                            itemCount: state.invoices.length + (state.hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index >= state.invoices.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(AppDimens.lg),
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              }
                              final invoice = state.invoices[index];
                              final hasPdf = invoice.pdfFile != null && invoice.pdfFile!.isNotEmpty;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: AppDimens.sm),
                                child: PremiumCard(
                                  margin: EdgeInsets.zero,
                                  padding: const EdgeInsets.all(AppDimens.lg),
                                  onTap: () => context.push('/invoices/${invoice.id}'),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: AppDimens.avatarLg,
                                        height: AppDimens.avatarLg,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              AppColors.primary,
                                              AppColors.primaryDark,
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                                        ),
                                        child: const Icon(
                                          Icons.receipt_rounded,
                                          color: Colors.white,
                                          size: AppDimens.iconLg,
                                        ),
                                      ),
                                      const SizedBox(width: AppDimens.md),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    invoice.invoiceNumber,
                                                    style: const TextStyle(
                                                      fontSize: AppDimens.fontMd,
                                                      fontWeight: FontWeight.w600,
                                                      color: AppColors.textPrimary,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (hasPdf) ...[
                                                  const SizedBox(width: AppDimens.xs),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: AppDimens.xs,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.infoLight,
                                                      borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                                                    ),
                                                    child: const Text(
                                                      'PDF',
                                                      style: TextStyle(
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.w700,
                                                        color: AppColors.info,
                                                        letterSpacing: 0.5,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: AppDimens.xs),
                                            Text(
                                              invoice.invoiceDate,
                                              style: const TextStyle(
                                                fontSize: AppDimens.fontSm,
                                                color: AppColors.textTertiary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: AppDimens.sm),
                                      Text(
                                        Formatters.currency(invoice.totalAmount),
                                        style: const TextStyle(
                                          fontSize: AppDimens.fontMd,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                          letterSpacing: -0.2,
                                        ),
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
