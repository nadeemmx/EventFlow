import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:eventflow_app/core/services/token_service.dart';
import 'package:eventflow_app/core/theme/page_transitions.dart';
import 'package:eventflow_app/core/widgets/main_shell.dart';
import 'package:eventflow_app/features/authentication/presentation/pages/splash_page.dart';
import 'package:eventflow_app/features/authentication/presentation/pages/onboarding_page.dart';
import 'package:eventflow_app/features/authentication/presentation/pages/login_page.dart';
import 'package:eventflow_app/features/authentication/presentation/pages/signup_page.dart';
import 'package:eventflow_app/features/authentication/presentation/pages/forgot_password_page.dart';
import 'package:eventflow_app/features/authentication/presentation/pages/reset_password_page.dart';
import 'package:eventflow_app/features/demo/presentation/pages/guest_demo_page.dart';
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
  final ValueNotifier<void> authNotifier = ValueNotifier<void>(null);
  late final GoRouter router;

  AppRouter({required this._tokenService}) {
    router = GoRouter(
      initialLocation: '/splash',
      debugLogDiagnostics: false,
      refreshListenable: authNotifier,
      redirect: _guardRoute,
      routes: [
        // ─── Auth routes (outside shell) ────────────────────────────
        GoRoute(
          path: '/splash',
          pageBuilder: (context, state) => CustomTransitionPage(
            child: const SplashPage(),
            transitionsBuilder: PageTransitions.fadeThrough,
          ),
        ),
        GoRoute(
          path: '/onboarding',
          pageBuilder: (context, state) => CustomTransitionPage(
            child: const OnboardingPage(),
            transitionsBuilder: PageTransitions.fadeThrough,
          ),
        ),
        GoRoute(
          path: '/login',
          pageBuilder: (context, state) => CustomTransitionPage(
            child: const LoginPage(),
            transitionsBuilder: PageTransitions.fadeThrough,
          ),
        ),
        GoRoute(
          path: '/signup',
          pageBuilder: (context, state) => CustomTransitionPage(
            child: const SignupPage(),
            transitionsBuilder: PageTransitions.slideFromRight,
          ),
        ),
        GoRoute(
          path: '/demo',
          pageBuilder: (context, state) => CustomTransitionPage(
            child: const GuestDemoPage(),
            transitionsBuilder: PageTransitions.fadeThrough,
          ),
        ),
        GoRoute(
          path: '/forgot-password',
          pageBuilder: (context, state) => CustomTransitionPage(
            child: const ForgotPasswordPage(),
            transitionsBuilder: PageTransitions.slideFromBottom,
          ),
        ),
        GoRoute(
          path: '/reset-password',
          pageBuilder: (context, state) => CustomTransitionPage(
            child: const ResetPasswordPage(),
            transitionsBuilder: PageTransitions.slideFromBottom,
          ),
        ),

        // ─── Shell route (bottom nav tabs) ──────────────────────────
        ShellRoute(
          builder: (context, state, child) => MainShell(child: child),
          routes: [
            GoRoute(
              path: '/dashboard',
              pageBuilder: (context, state) => CustomTransitionPage(
                child: const DashboardPage(),
                transitionsBuilder: PageTransitions.fadeThrough,
              ),
            ),
            GoRoute(
              path: '/bookings',
              pageBuilder: (context, state) => CustomTransitionPage(
                child: const BookingListPage(),
                transitionsBuilder: PageTransitions.sharedAxisHorizontal,
              ),
            ),
            GoRoute(
              path: '/customers',
              pageBuilder: (context, state) => CustomTransitionPage(
                child: const CustomerListPage(),
                transitionsBuilder: PageTransitions.sharedAxisHorizontal,
              ),
            ),
            GoRoute(
              path: '/leads',
              pageBuilder: (context, state) => CustomTransitionPage(
                child: const LeadListPage(),
                transitionsBuilder: PageTransitions.sharedAxisHorizontal,
              ),
            ),
            GoRoute(
              path: '/more',
              pageBuilder: (context, state) => CustomTransitionPage(
                child: const MorePage(),
                transitionsBuilder: PageTransitions.sharedAxisHorizontal,
              ),
            ),
          ],
        ),

        // ─── Detail/form routes (outside shell, full-screen) ────────
        GoRoute(
          path: '/bookings/new',
          pageBuilder: (context, state) => CustomTransitionPage(
            child: const BookingFormPage(),
            transitionsBuilder: PageTransitions.slideFromBottom,
          ),
        ),
        GoRoute(
          path: '/bookings/:id',
          pageBuilder: (context, state) => CustomTransitionPage(
            child: BookingDetailPage(
              id: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
            ),
            transitionsBuilder: PageTransitions.slideFromRight,
          ),
        ),
        GoRoute(
          path: '/bookings/:id/edit',
          pageBuilder: (context, state) => CustomTransitionPage(
            child: BookingFormPage(
              id: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
            ),
            transitionsBuilder: PageTransitions.slideFromBottom,
          ),
        ),
        GoRoute(
          path: '/customers/new',
          pageBuilder: (context, state) => CustomTransitionPage(
            child: const CustomerFormPage(),
            transitionsBuilder: PageTransitions.slideFromBottom,
          ),
        ),
        GoRoute(
          path: '/customers/:id',
          pageBuilder: (context, state) => CustomTransitionPage(
            child: CustomerDetailPage(
              id: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
            ),
            transitionsBuilder: PageTransitions.slideFromRight,
          ),
        ),
        GoRoute(
          path: '/customers/:id/edit',
          pageBuilder: (context, state) => CustomTransitionPage(
            child: CustomerFormPage(
              id: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
            ),
            transitionsBuilder: PageTransitions.slideFromBottom,
          ),
        ),
        GoRoute(
          path: '/leads/new',
          pageBuilder: (context, state) => CustomTransitionPage(
            child: const LeadFormPage(),
            transitionsBuilder: PageTransitions.slideFromBottom,
          ),
        ),
        GoRoute(
          path: '/leads/:id',
          pageBuilder: (context, state) => CustomTransitionPage(
            child: LeadDetailPage(
              id: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
            ),
            transitionsBuilder: PageTransitions.slideFromRight,
          ),
        ),
        GoRoute(
          path: '/leads/:id/edit',
          pageBuilder: (context, state) => CustomTransitionPage(
            child: LeadFormPage(
              id: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
            ),
            transitionsBuilder: PageTransitions.slideFromBottom,
          ),
        ),

        // ─── Sub-feature routes (outside shell) ─────────────────────
        GoRoute(
          path: '/venues',
          pageBuilder: (context, state) => CustomTransitionPage(
            child: const VenueListPage(),
            transitionsBuilder: PageTransitions.slideFromRight,
          ),
        ),
        GoRoute(
          path: '/venues/:id',
          pageBuilder: (context, state) => CustomTransitionPage(
            child: VenueDetailPage(
              id: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
            ),
            transitionsBuilder: PageTransitions.slideFromRight,
          ),
        ),
        GoRoute(
          path: '/payments',
          pageBuilder: (context, state) => CustomTransitionPage(
            child: const PaymentListPage(),
            transitionsBuilder: PageTransitions.slideFromRight,
          ),
        ),
        GoRoute(
          path: '/invoices',
          pageBuilder: (context, state) => CustomTransitionPage(
            child: const InvoiceListPage(),
            transitionsBuilder: PageTransitions.slideFromRight,
          ),
        ),
        GoRoute(
          path: '/invoices/:id',
          pageBuilder: (context, state) => CustomTransitionPage(
            child: InvoiceDetailPage(
              id: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
            ),
            transitionsBuilder: PageTransitions.slideFromRight,
          ),
        ),
        GoRoute(
          path: '/notifications',
          pageBuilder: (context, state) => CustomTransitionPage(
            child: const NotificationListPage(),
            transitionsBuilder: PageTransitions.slideFromRight,
          ),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => CustomTransitionPage(
            child: const SettingsPage(),
            transitionsBuilder: PageTransitions.slideFromRight,
          ),
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) => CustomTransitionPage(
            child: const ProfilePage(),
            transitionsBuilder: PageTransitions.slideFromRight,
          ),
        ),
      ],
    );
  }

  Future<String?> _guardRoute(BuildContext context, GoRouterState state) async {
    final isLoggedIn = await _tokenService.isLoggedIn();
    final location = state.matchedLocation;

    const authRoutes = ['/login', '/signup', '/demo', '/forgot-password', '/reset-password', '/splash', '/onboarding'];

    if (authRoutes.contains(location)) {
      if (isLoggedIn) {
        return location == '/splash' ? null : '/dashboard';
      }
      return null;
    }

    if (!isLoggedIn) {
      return '/login';
    }

    return null;
  }
}

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('More'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
      ),
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
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }
}
