import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:eventflow_app/core/api/api_client.dart';
import 'package:eventflow_app/core/services/token_service.dart';
import 'package:eventflow_app/core/services/guest_session_service.dart';
import 'package:eventflow_app/core/services/notification_service.dart';
import 'package:eventflow_app/core/services/image_picker_service.dart';
import 'package:eventflow_app/core/storage/storage_service.dart';
import 'package:eventflow_app/core/network/network_info.dart';
import 'package:eventflow_app/core/routes/app_router.dart';

import 'package:eventflow_app/features/authentication/data/datasources/auth_remote_data_source.dart';
import 'package:eventflow_app/features/authentication/domain/repositories/auth_repository.dart';
import 'package:eventflow_app/features/authentication/presentation/bloc/auth_bloc.dart';

import 'package:eventflow_app/features/dashboard/data/datasources/dashboard_remote_data_source.dart';
import 'package:eventflow_app/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:eventflow_app/features/dashboard/presentation/bloc/dashboard_bloc.dart';

import 'package:eventflow_app/features/bookings/data/datasources/booking_remote_data_source.dart';
import 'package:eventflow_app/features/bookings/domain/repositories/booking_repository.dart';
import 'package:eventflow_app/features/bookings/presentation/bloc/booking_bloc.dart';

import 'package:eventflow_app/features/customers/data/datasources/customer_remote_data_source.dart';
import 'package:eventflow_app/features/customers/domain/repositories/customer_repository.dart';
import 'package:eventflow_app/features/customers/presentation/bloc/customer_bloc.dart';

import 'package:eventflow_app/features/leads/data/datasources/lead_remote_data_source.dart';
import 'package:eventflow_app/features/leads/domain/repositories/lead_repository.dart';
import 'package:eventflow_app/features/leads/presentation/bloc/lead_bloc.dart';

import 'package:eventflow_app/features/venues/data/datasources/venue_remote_data_source.dart';
import 'package:eventflow_app/features/venues/domain/repositories/venue_repository.dart';
import 'package:eventflow_app/features/venues/presentation/bloc/venue_bloc.dart';

import 'package:eventflow_app/features/payments/data/datasources/payment_remote_data_source.dart';
import 'package:eventflow_app/features/payments/domain/repositories/payment_repository.dart';
import 'package:eventflow_app/features/payments/presentation/bloc/payment_bloc.dart';

import 'package:eventflow_app/features/invoices/data/datasources/invoice_remote_data_source.dart';
import 'package:eventflow_app/features/invoices/domain/repositories/invoice_repository.dart';
import 'package:eventflow_app/features/invoices/presentation/bloc/invoice_bloc.dart';

import 'package:eventflow_app/features/notifications/data/datasources/notification_remote_data_source.dart';
import 'package:eventflow_app/features/notifications/domain/repositories/notification_repository.dart';
import 'package:eventflow_app/features/notifications/presentation/bloc/notification_bloc.dart';

final sl = GetIt.instance;

Future<void> initializeDependencies() async {
  // Core
  sl.registerLazySingleton<FlutterSecureStorage>(() => const FlutterSecureStorage());
  sl.registerLazySingleton<TokenService>(() => TokenService(storage: sl()));
  sl.registerLazySingleton<StorageService>(() => StorageService());
  sl.registerLazySingleton<GuestSessionService>(() => GuestSessionService());
  sl.registerLazySingleton<Connectivity>(() => Connectivity());
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfo(connectivity: sl()));
  sl.registerLazySingleton<ApiClient>(() => ApiClient(tokenService: sl()));
  sl.registerLazySingleton<AppRouter>(() => AppRouter(tokenService: sl()));
  sl.registerLazySingleton<NotificationService>(() => NotificationService(
    apiClient: sl(),
  ));
  sl.registerLazySingleton<ImagePickerService>(() => ImagePickerService());

  // Auth
  sl.registerLazySingleton<AuthRemoteDataSource>(() => AuthRemoteDataSource(apiClient: sl()));
  sl.registerLazySingleton<AuthRepository>(() => AuthRepository(
        remoteDataSource: sl(),
        tokenService: sl(),
        guestSessionService: sl(),
        storageService: sl(),
        notificationService: sl(),
      ));
  sl.registerFactory<AuthBloc>(() => AuthBloc(authRepository: sl(), tokenService: sl()));

  // Dashboard
  sl.registerLazySingleton<DashboardRemoteDataSource>(() => DashboardRemoteDataSource(apiClient: sl()));
  sl.registerLazySingleton<DashboardRepository>(() => DashboardRepository(
    remoteDataSource: sl(),
    storageService: sl(),
    networkInfo: sl(),
  ));
  sl.registerFactory<DashboardBloc>(() => DashboardBloc(repository: sl()));

  // Bookings
  sl.registerLazySingleton<BookingRemoteDataSource>(() => BookingRemoteDataSource(apiClient: sl()));
  sl.registerLazySingleton<BookingRepository>(() => BookingRepository(
    remoteDataSource: sl(),
    storageService: sl(),
    networkInfo: sl(),
  ));
  sl.registerFactory<BookingBloc>(() => BookingBloc(repository: sl()));

  // Customers
  sl.registerLazySingleton<CustomerRemoteDataSource>(() => CustomerRemoteDataSource(apiClient: sl()));
  sl.registerLazySingleton<CustomerRepository>(() => CustomerRepository(
    remoteDataSource: sl(),
    storageService: sl(),
    networkInfo: sl(),
  ));
  sl.registerFactory<CustomerBloc>(() => CustomerBloc(repository: sl()));

  // Leads
  sl.registerLazySingleton<LeadRemoteDataSource>(() => LeadRemoteDataSource(apiClient: sl()));
  sl.registerLazySingleton<LeadRepository>(() => LeadRepository(
    remoteDataSource: sl(),
    storageService: sl(),
    networkInfo: sl(),
  ));
  sl.registerFactory<LeadBloc>(() => LeadBloc(repository: sl()));

  // Venues
  sl.registerLazySingleton<VenueRemoteDataSource>(() => VenueRemoteDataSource(apiClient: sl()));
  sl.registerLazySingleton<VenueRepository>(() => VenueRepository(remoteDataSource: sl()));
  sl.registerFactory<VenueBloc>(() => VenueBloc(repository: sl()));

  // Payments
  sl.registerLazySingleton<PaymentRemoteDataSource>(() => PaymentRemoteDataSource(apiClient: sl()));
  sl.registerLazySingleton<PaymentRepository>(() => PaymentRepository(remoteDataSource: sl()));
  sl.registerFactory<PaymentBloc>(() => PaymentBloc(repository: sl()));

  // Invoices
  sl.registerLazySingleton<InvoiceRemoteDataSource>(() => InvoiceRemoteDataSource(apiClient: sl()));
  sl.registerLazySingleton<InvoiceRepository>(() => InvoiceRepository(remoteDataSource: sl()));
  sl.registerFactory<InvoiceBloc>(() => InvoiceBloc(repository: sl()));

  // Notifications
  sl.registerLazySingleton<NotificationRemoteDataSource>(() => NotificationRemoteDataSource(apiClient: sl()));
  sl.registerLazySingleton<NotificationRepository>(() => NotificationRepository(remoteDataSource: sl()));
  sl.registerFactory<NotificationBloc>(() => NotificationBloc(repository: sl()));
}
