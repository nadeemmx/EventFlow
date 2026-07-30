import 'package:flutter/material.dart';
import 'package:eventflow_app/core/theme/app_colors.dart';
import 'package:eventflow_app/core/widgets/loading_widget.dart';
import 'package:eventflow_app/core/widgets/error_widget.dart';
import 'package:eventflow_app/core/widgets/offline_banner.dart';

class AppScaffold extends StatelessWidget {
  final String? title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? drawer;
  final Widget? bottomNavigationBar;
  final bool isLoading;
  final String? loadingMessage;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final bool showBack;
  final Color? backgroundColor;
  final Widget? floatingActionButton;
  final PreferredSizeWidget? bottom;
  final bool extendBody;

  const AppScaffold({
    super.key,
    this.title,
    required this.body,
    this.actions,
    this.drawer,
    this.bottomNavigationBar,
    this.isLoading = false,
    this.loadingMessage,
    this.errorMessage,
    this.onRetry,
    this.showBack = false,
    this.backgroundColor,
    this.floatingActionButton,
    this.bottom,
    this.extendBody = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? AppColors.background,
      appBar: title != null
          ? AppBar(
              title: Text(title!),
              leading: showBack
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                      onPressed: () => Navigator.pop(context),
                    )
                  : null,
              actions: actions,
              bottom: bottom,
            )
          : null,
      drawer: drawer,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      extendBody: extendBody,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return LoadingWidget(message: loadingMessage);
    }
    if (errorMessage != null) {
      return AppErrorWidget(message: errorMessage!, onRetry: onRetry);
    }
    return Column(
      children: [
        const OfflineBanner(),
        Expanded(child: body),
      ],
    );
  }
}
