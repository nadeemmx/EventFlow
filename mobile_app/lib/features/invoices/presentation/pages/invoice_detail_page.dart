import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:eventflow_app/core/services/token_service.dart';
import 'package:eventflow_app/core/theme/app_colors.dart';
import 'package:eventflow_app/core/theme/app_dimens.dart';
import 'package:eventflow_app/core/utils/formatters.dart';
import 'package:eventflow_app/features/invoices/presentation/bloc/invoice_bloc.dart';
import 'package:eventflow_app/core/widgets/loading_widget.dart';
import 'package:eventflow_app/core/widgets/error_widget.dart';
import 'package:eventflow_app/core/widgets/premium_card.dart';
import 'package:eventflow_app/core/widgets/demo_banner.dart';

class InvoiceDetailPage extends StatefulWidget {
  final int id;
  const InvoiceDetailPage({super.key, required this.id});

  @override
  State<InvoiceDetailPage> createState() => _InvoiceDetailPageState();
}

class _InvoiceDetailPageState extends State<InvoiceDetailPage> {
  @override
  void initState() {
    super.initState();
    context.read<InvoiceBloc>().add(LoadInvoiceDetail(id: widget.id));
  }

  Future<void> _openPdf(String pdfUrl) async {
    final uri = Uri.tryParse(pdfUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open PDF')),
        );
      }
    }
  }

  Future<void> _downloadPdf(String pdfUrl) async {
    final tokenService = context.read<TokenService>();
    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/invoice_${widget.id}.pdf';
      final token = await tokenService.getAccessToken();
      final headers = <String, dynamic>{};
      if (token != null) headers['Authorization'] = 'Bearer $token';
      final dio = Dio(BaseOptions(headers: headers));
      await dio.download(pdfUrl, filePath);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Downloaded to $filePath')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Download failed')),
        );
      }
    }
  }

  Future<void> _sharePdf(String pdfUrl) async {
    final tokenService = context.read<TokenService>();
    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/invoice_${widget.id}_share.pdf';
      final token = await tokenService.getAccessToken();
      final headers = <String, dynamic>{};
      if (token != null) headers['Authorization'] = 'Bearer $token';
      final dio = Dio(BaseOptions(headers: headers));
      await dio.download(pdfUrl, filePath);
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Invoice #${widget.id}',
      );
    } catch (e) {
      await Share.share('Download invoice at: $pdfUrl');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Invoice Detail',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new_rounded),
            tooltip: 'Open PDF',
            onPressed: () {
              final state = context.read<InvoiceBloc>().state;
              if (state is InvoiceDetailLoaded && state.invoice.pdfFile != null) {
                _openPdf(state.invoice.pdfFile!);
              }
            },
          ),
        ],
      ),
      body: BlocBuilder<InvoiceBloc, InvoiceState>(
        builder: (context, state) {
          if (state is InvoiceLoading) {
            return const LoadingWidget();
          }
          if (state is InvoiceError) {
            return AppErrorWidget(
              message: state.message,
              onRetry: () => context.read<InvoiceBloc>().add(LoadInvoiceDetail(id: widget.id)),
            );
          }
          if (state is InvoiceDetailLoaded) {
            final invoice = state.invoice;
            return Column(
              children: [
                const DemoBanner(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppDimens.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppDimens.xxl),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primaryDark,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(AppDimens.cardRadius),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: AppDimens.avatarXl,
                                height: AppDimens.avatarXl,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(AppDimens.radiusXl),
                                ),
                                child: const Icon(
                                  Icons.receipt_long_rounded,
                                  size: AppDimens.iconXxl,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: AppDimens.lg),
                              Text(
                                invoice.invoiceNumber,
                                style: const TextStyle(
                                  fontSize: AppDimens.fontXxl,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: AppDimens.xs),
                              Text(
                                invoice.invoiceDate,
                                style: TextStyle(
                                  fontSize: AppDimens.fontMd,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppDimens.lg),
                        PremiumCard(
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimens.lg,
                              vertical: AppDimens.xl,
                            ),
                            child: Column(
                              children: [
                                _buildAmountRow(
                                  'Subtotal',
                                  Formatters.currency(invoice.subtotal),
                                  AppColors.textSecondary,
                                  AppDimens.fontMd,
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: AppDimens.md),
                                  child: Divider(
                                    height: 1,
                                    color: AppColors.divider,
                                  ),
                                ),
                                _buildAmountRow(
                                  'Tax',
                                  Formatters.currency(invoice.taxAmount),
                                  AppColors.textSecondary,
                                  AppDimens.fontMd,
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: AppDimens.md),
                                  child: Divider(
                                    height: 1,
                                    color: AppColors.divider,
                                  ),
                                ),
                                _buildAmountRow(
                                  'Total',
                                  Formatters.currency(invoice.totalAmount),
                                  AppColors.primary,
                                  AppDimens.fontXl,
                                  isBold: true,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (invoice.pdfFile != null) ...[
                          const SizedBox(height: AppDimens.lg),
                          PremiumCard(
                            margin: EdgeInsets.zero,
                            child: Padding(
                              padding: const EdgeInsets.all(AppDimens.lg),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'PDF Actions',
                                    style: TextStyle(
                                      fontSize: AppDimens.fontMd,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const SizedBox(height: AppDimens.md),
                                  _buildActionTile(
                                    icon: Icons.open_in_new_rounded,
                                    iconColor: AppColors.error,
                                    iconBg: AppColors.errorLight,
                                    title: 'View Invoice PDF',
                                    subtitle: 'Open in external viewer',
                                    onTap: () => _openPdf(invoice.pdfFile!),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 2),
                                    child: Divider(height: 1),
                                  ),
                                  _buildActionTile(
                                    icon: Icons.download_rounded,
                                    iconColor: AppColors.primary,
                                    iconBg: AppColors.primarySurface,
                                    title: 'Download PDF',
                                    subtitle: 'Save to device',
                                    onTap: () => _downloadPdf(invoice.pdfFile!),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 2),
                                    child: Divider(height: 1),
                                  ),
                                  _buildActionTile(
                                    icon: Icons.share_rounded,
                                    iconColor: AppColors.info,
                                    iconBg: AppColors.infoLight,
                                    title: 'Share Invoice',
                                    subtitle: 'Send via any app',
                                    onTap: () => _sharePdf(invoice.pdfFile!),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildAmountRow(
    String label,
    String value,
    Color valueColor,
    double fontSize, {
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: valueColor,
            letterSpacing: isBold ? -0.5 : -0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppDimens.md,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: AppDimens.iconMd,
              ),
            ),
            const SizedBox(width: AppDimens.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: AppDimens.fontMd,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: AppDimens.fontSm,
                      color: AppColors.textTertiary,
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
    );
  }
}
