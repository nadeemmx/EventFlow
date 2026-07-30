import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:eventflow_app/core/theme/app_colors.dart';
import 'package:eventflow_app/core/theme/app_dimens.dart';

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

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    _currentIndex = _calculateIndex(location);

    return Scaffold(
      body: SafeArea(bottom: false, child: widget.child),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.borderLight, width: 1),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.dashboard_rounded,
                  activeIcon: Icons.dashboard_rounded,
                  label: 'Home',
                  isSelected: _currentIndex == 0,
                  onTap: () => _onTap(0, context),
                ),
                _NavItem(
                  icon: Icons.event_outlined,
                  activeIcon: Icons.event_rounded,
                  label: 'Bookings',
                  isSelected: _currentIndex == 1,
                  onTap: () => _onTap(1, context),
                ),
                _NavItem(
                  icon: Icons.people_outline_rounded,
                  activeIcon: Icons.people_rounded,
                  label: 'Customers',
                  isSelected: _currentIndex == 2,
                  onTap: () => _onTap(2, context),
                ),
                _NavItem(
                  icon: Icons.trending_up_rounded,
                  activeIcon: Icons.trending_up_rounded,
                  label: 'Leads',
                  isSelected: _currentIndex == 3,
                  onTap: () => _onTap(3, context),
                ),
                _NavItem(
                  icon: Icons.more_horiz_rounded,
                  activeIcon: Icons.more_horiz_rounded,
                  label: 'More',
                  isSelected: _currentIndex == 4,
                  onTap: () => _onTap(4, context),
                ),
              ],
            ),
          ),
        ),
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

  void _onTap(int index, BuildContext context) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    context.go(_tabs[index]);
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppDimens.animNormal,
        curve: AppDimens.curveDefault,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySurface : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimens.radiusFull),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 22,
              color: isSelected ? AppColors.primary : AppColors.textTertiary,
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
