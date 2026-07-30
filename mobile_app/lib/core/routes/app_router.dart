import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:eventflow_app/core/services/token_service.dart';
import 'package:eventflow_app/core/services/guest_session_service.dart';
import 'package:eventflow_app/core/widgets/main_shell.dart';
import 'package:eventflow_app/injector.dart';
import 'package:eventflow_app/features/authentication/presentation/pages/splash_page.dart';
import 'package:eventflow_app/features/authentication/presentation/pages/login_page.dart';
import 'package:eventflow_app/features/authentication/presentation/pages/forgot_password_page.dart';
import 'package:eventflow_app/features/authentication/presentation/pages/reset_password_page.dart';
import 'package:eventflow_app/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:eventflow_app/features/bookings/presentation/pages/booking_list_page.dart';
import 'package:eventflow_app/features/bookings/presentation/pages/booking_detail_page.dart';
import 'package:eventflow_app/features/bookings/presentation/pages/booking_form_page.dart';
import 'package:eventflow_app/features/customers/presentation/pages/customer_list_page.dart';
import 'package:eventflow_app/features/customers/presentation/pages/customer_detail_page.dart';
import 'package:eventflow_app/features/customers/presentation/pages/customer_form_page.dart';
import 'package:eventflow_app/features/leads/presentation/pages/lead_list_page.dart';
import 'package:eventflow_app/features/leads/presentation/pages/lead_detail_page.dart';
import 'package:eventflow_app/features/leads/presentation/pages/lead_form_page.dart';
import 'package:eventflow_app/features/venues/presentation/pages/venue_list_page.dart';
import 'package:eventflow_app/features/venues/presentation/pages/venue_detail_page.dart';
import 'package:eventflow_app/features/payments/presentation/pages/payment_list_page.dart';
import 'package:eventflow_app/features/invoices/presentation/pages/invoice_list_page.dart';
import 'package:eventflow_app/features/invoices/presentation/pages/invoice_detail_page.dart';
import 'package:eventflow_app/features/settings/presentation/pages/settings_page.dart';
import 'package:eventflow_app/features/profile/presentation/pages/profile_page.dart';
import 'package:eventflow_app/features/notifications/presentation/pages/notification_list_page.dart';

class AppRouter {
  final TokenService _tokenService;
  late final GoRouter router;

  AppRouter({required this._tokenService}) {
    router = GoRouter(
      initialLocation: '/splash',
      debugLogDiagnostics: false,
      redirect: _guardRoute,
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashPage(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordPage(),
        ),
        GoRoute(
          path: '/reset-password',
          builder: (context, state) => const ResetPasswordPage(),
        ),
        ShellRoute(
          builder: (context, state, child) => MainShell(child: child),
          routes: [
            GoRoute(
              path: '/dashboard',
              pageBuilder: (context, state) => CustomTransitionPage(
                child: const DashboardPage(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.02),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                      child: child,
                    ),
                  );
                },
              ),
            ),
            GoRoute(
              path: '/bookings',
              pageBuilder: (context, state) => CustomTransitionPage(
                child: const BookingListPage(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1.0, 0.0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                    child: FadeTransition(
                      opacity: CurvedAnimation(parent: animation, curve: const Interval(0.3, 1.0, curve: Curves.easeOut)),
                      child: child,
                    ),
                  );
                },
              ),
            ),
            GoRoute(
              path: '/customers',
              pageBuilder: (context, state) => CustomTransitionPage(
                child: const CustomerListPage(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1.0, 0.0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                    child: FadeTransition(
                      opacity: CurvedAnimation(parent: animation, curve: const Interval(0.3, 1.0, curve: Curves.easeOut)),
                      child: child,
                    ),
                  );
                },
              ),
            ),
            GoRoute(
              path: '/leads',
              pageBuilder: (context, state) => CustomTransitionPage(
                child: const LeadListPage(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1.0, 0.0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                    child: FadeTransition(
                      opacity: CurvedAnimation(parent: animation, curve: const Interval(0.3, 1.0, curve: Curves.easeOut)),
                      child: child,
                    ),
                  );
                },
              ),
            ),
            GoRoute(
              path: '/more',
              builder: (context, state) => const _MorePage(),
            ),
          ],
        ),
        GoRoute(
          path: '/bookings/new',
          pageBuilder: (context, state) => CustomTransitionPage(
            child: const BookingFormPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 1.0);
              const end = Offset.zero;
              final tween = Tween<Offset>(begin: begin, end: end).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              );
              return SlideTransition(position: tween, child: child);
            },
          ),
        ),
        GoRoute(
          path: '/bookings/:id',
          pageBuilder: (context, state) => CustomTransitionPage(
            child: BookingDetailPage(
              id: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                child: FadeTransition(
                  opacity: CurvedAnimation(parent: animation, curve: const Interval(0.3, 1.0, curve: Curves.easeOut)),
                  child: child,
                ),
              );
            },
          ),
        ),
        GoRoute(
          path: '/bookings/:id/edit',
          pageBuilder: (context, state) => CustomTransitionPage(
            child: BookingFormPage(
              id: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 1.0);
              const end = Offset.zero;
              final tween = Tween<Offset>(begin: begin, end: end).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              );
              return SlideTransition(position: tween, child: child);
            },
          ),
        ),
        GoRoute(
          path: '/customers/new',
          pageBuilder: (context, state) => CustomTransitionPage(
            child: const CustomerFormPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 1.0);
              const end = Offset.zero;
              final tween = Tween<Offset>(begin: begin, end: end).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              );
              return SlideTransition(position: tween, child: child);
            },
          ),
        ),
        GoRoute(
          path: '/customers/:id',
          pageBuilder: (context, state) => CustomTransitionPage(
            child: CustomerDetailPage(
              id: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                child: FadeTransition(
                  opacity: CurvedAnimation(parent: animation, curve: const Interval(0.3, 1.0, curve: Curves.easeOut)),
                  child: child,
                ),
              );
            },
          ),
        ),
        GoRoute(
          path: '/customers/:id/edit',
          pageBuilder: (context, state) => CustomTransitionPage(
            child: CustomerFormPage(
              id: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 1.0);
              const end = Offset.zero;
              final tween = Tween<Offset>(begin: begin, end: end).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              );
              return SlideTransition(position: tween, child: child);
            },
          ),
        ),
        GoRoute(
          path: '/leads/new',
          pageBuilder: (context, state) => CustomTransitionPage(
            child: const LeadFormPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 1.0);
              const end = Offset.zero;
              final tween = Tween<Offset>(begin: begin, end: end).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              );
              return SlideTransition(position: tween, child: child);
            },
          ),
        ),
        GoRoute(
          path: '/leads/:id',
          pageBuilder: (context, state) => CustomTransitionPage(
            child: LeadDetailPage(
              id: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                child: FadeTransition(
                  opacity: CurvedAnimation(parent: animation, curve: const Interval(0.3, 1.0, curve: Curves.easeOut)),
                  child: child,
                ),
              );
            },
          ),
        ),
        GoRoute(
          path: '/leads/:id/edit',
          pageBuilder: (context, state) => CustomTransitionPage(
            child: LeadFormPage(
              id: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 1.0);
              const end = Offset.zero;
              final tween = Tween<Offset>(begin: begin, end: end).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              );
              return SlideTransition(position: tween, child: child);
            },
          ),
        ),
        GoRoute(
          path: '/venues',
          builder: (context, state) => const VenueListPage(),
        ),
        GoRoute(
          path: '/venues/:id',
          builder: (context, state) => VenueDetailPage(
            id: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
          ),
        ),
        GoRoute(
          path: '/payments',
          builder: (context, state) => const PaymentListPage(),
        ),
        GoRoute(
          path: '/invoices',
          builder: (context, state) => const InvoiceListPage(),
        ),
        GoRoute(
          path: '/invoices/:id',
          builder: (context, state) => InvoiceDetailPage(
            id: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
          ),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationListPage(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsPage(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfilePage(),
        ),
      ],
    );
  }

  Future<String?> _guardRoute(BuildContext context, GoRouterState state) async {
    final isLoggedIn = await _tokenService.isLoggedIn();
    final isGuest = sl<GuestSessionService>().isGuestSession();
    final isAuthRoute = state.matchedLocation == '/login' ||
        state.matchedLocation == '/forgot-password' ||
        state.matchedLocation == '/reset-password' ||
        state.matchedLocation == '/splash';

    if (isAuthRoute) {
      if (isLoggedIn || isGuest) {
        return state.matchedLocation == '/splash' ? null : '/dashboard';
      }
      return null;
    }

    if (!isLoggedIn && !isGuest) {
      return '/login';
    }

    return null;
  }
}

class _MorePage extends StatelessWidget {
  const _MorePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _MoreItem(
            icon: Icons.location_city_rounded,
            title: 'Venues',
            onTap: () => context.push('/venues'),
          ),
          _MoreItem(
            icon: Icons.payments_rounded,
            title: 'Payments',
            onTap: () => context.push('/payments'),
          ),
          _MoreItem(
            icon: Icons.receipt_long_rounded,
            title: 'Invoices',
            onTap: () => context.push('/invoices'),
          ),
          _MoreItem(
            icon: Icons.notifications_rounded,
            title: 'Notifications',
            onTap: () => context.push('/notifications'),
          ),
          _MoreItem(
            icon: Icons.person_rounded,
            title: 'Profile',
            onTap: () => context.push('/profile'),
          ),
          _MoreItem(
            icon: Icons.settings_rounded,
            title: 'Settings',
            onTap: () => context.push('/settings'),
          ),
        ],
      ),
    );
  }
}

class _MoreItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _MoreItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      onTap: onTap,
    );
  }
}
