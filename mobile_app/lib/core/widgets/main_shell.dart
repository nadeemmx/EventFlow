import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:eventflow_app/core/theme/app_colors.dart';
import 'package:eventflow_app/core/theme/design_system.dart';

class MainShell extends StatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const _tabs = [
    '/dashboard',
    '/bookings',
    '/customers',
    '/leads',
    '/more',
  ];

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard_rounded),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.event_outlined),
      selectedIcon: Icon(Icons.event_rounded),
      label: 'Bookings',
    ),
    NavigationDestination(
      icon: Icon(Icons.people_outline_rounded),
      selectedIcon: Icon(Icons.people_rounded),
      label: 'Customers',
    ),
    NavigationDestination(
      icon: Icon(Icons.trending_up_outlined),
      selectedIcon: Icon(Icons.trending_up_rounded),
      label: 'Leads',
    ),
    NavigationDestination(
      icon: Icon(Icons.more_horiz_rounded),
      selectedIcon: Icon(Icons.more_horiz_rounded),
      label: 'More',
    ),
  ];

  static const _railDestinations = [
    NavigationRailDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard_rounded),
      label: Text('Home'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.event_outlined),
      selectedIcon: Icon(Icons.event_rounded),
      label: Text('Bookings'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.people_outline_rounded),
      selectedIcon: Icon(Icons.people_rounded),
      label: Text('Customers'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.trending_up_outlined),
      selectedIcon: Icon(Icons.trending_up_rounded),
      label: Text('Leads'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.more_horiz_rounded),
      selectedIcon: Icon(Icons.more_horiz_rounded),
      label: Text('More'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    _currentIndex = _calculateIndex(location);

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWideScreen = screenWidth >= 800;

    if (isWideScreen) {
      return _buildWideLayout(context);
    }

    return _buildNarrowLayout(context);
  }

  Widget _buildNarrowLayout(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: widget.child,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark
                  ? AppColors.dividerDark.withValues(alpha: 0.5)
                  : AppColors.border,
              width: 0.5,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: _onTap,
            animationDuration: DesignSystem.durationSlow,
            backgroundColor: Colors.transparent,
            indicatorColor: AppColors.primary.withValues(alpha: 0.12),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            height: 64,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final isSelected = states.contains(WidgetState.selected);
              return TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textTertiary,
              );
            }),
            destinations: _destinations,
          ),
        ),
      ),
    );
  }

  Widget _buildWideLayout(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _currentIndex,
            onDestinationSelected: _onTap,
            backgroundColor: Colors.white,
            indicatorColor: AppColors.primary.withValues(alpha: 0.12),
            elevation: 0,
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.only(
                top: DesignSystem.spacing4,
                bottom: DesignSystem.spacing6,
              ),
              child: Center(
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: DesignSystem.primaryGradient,
                    borderRadius: BorderRadius.circular(DesignSystem.radiusMd),
                  ),
                  child: const Icon(
                    Icons.event_available_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
            trailing: const Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(bottom: DesignSystem.spacing4),
                  child: Icon(
                    Icons.event_available_rounded,
                    size: 18,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            destinations: _railDestinations,
          ),
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          Expanded(
            child: SafeArea(
              right: false,
              bottom: false,
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }

  int _calculateIndex(String location) {
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/bookings')) return 1;
    if (location.startsWith('/customers')) return 2;
    if (location.startsWith('/leads')) return 3;
    return 4;
  }

  void _onTap(int index) {
    if (index == _currentIndex) return;
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
    context.go(_tabs[index]);
  }
}
