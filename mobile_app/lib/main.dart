import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:eventflow_app/injector.dart';
import 'package:eventflow_app/core/routes/app_router.dart';
import 'package:eventflow_app/core/services/guest_session_service.dart';
import 'package:eventflow_app/core/services/notification_service.dart';
import 'package:eventflow_app/core/storage/storage_service.dart';
import 'package:eventflow_app/core/theme/app_theme.dart';
import 'package:eventflow_app/core/theme/theme_provider.dart';
import 'package:eventflow_app/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:eventflow_app/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:eventflow_app/features/bookings/presentation/bloc/booking_bloc.dart';
import 'package:eventflow_app/features/customers/presentation/bloc/customer_bloc.dart';
import 'package:eventflow_app/features/leads/presentation/bloc/lead_bloc.dart';
import 'package:eventflow_app/features/venues/presentation/bloc/venue_bloc.dart';
import 'package:eventflow_app/features/payments/presentation/bloc/payment_bloc.dart';
import 'package:eventflow_app/features/invoices/presentation/bloc/invoice_bloc.dart';
import 'package:eventflow_app/features/notifications/presentation/bloc/notification_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('settings');
  await initializeDependencies();
  await sl<StorageService>().init();
  await sl<GuestSessionService>().init();

  try {
    await sl<NotificationService>().initialize();
  } catch (_) {}

  sl.registerLazySingleton<ThemeProvider>(() => ThemeProvider());

  runApp(const EventFlowApp());
}

class EventFlowApp extends StatefulWidget {
  const EventFlowApp({super.key});

  @override
  State<EventFlowApp> createState() => _EventFlowAppState();
}

class _EventFlowAppState extends State<EventFlowApp> {
  final _themeProvider = sl<ThemeProvider>();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _themeProvider,
      builder: (context, _) {
        return MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>(create: (_) => sl<AuthBloc>()),
            BlocProvider<DashboardBloc>(create: (_) => sl<DashboardBloc>()),
            BlocProvider<BookingBloc>(create: (_) => sl<BookingBloc>()),
            BlocProvider<CustomerBloc>(create: (_) => sl<CustomerBloc>()),
            BlocProvider<LeadBloc>(create: (_) => sl<LeadBloc>()),
            BlocProvider<VenueBloc>(create: (_) => sl<VenueBloc>()),
            BlocProvider<PaymentBloc>(create: (_) => sl<PaymentBloc>()),
            BlocProvider<InvoiceBloc>(create: (_) => sl<InvoiceBloc>()),
            BlocProvider<NotificationBloc>(create: (_) => sl<NotificationBloc>()),
          ],
          child: MaterialApp.router(
            title: 'EventFlow',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: _themeProvider.themeMode,
            routerConfig: sl<AppRouter>().router,
          ),
        );
      },
    );
  }
}
