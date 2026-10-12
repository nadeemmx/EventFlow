import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';

import 'package:eventflow_app/core/services/guest_session_service.dart';
import 'package:eventflow_app/core/services/notification_service.dart';
import 'package:eventflow_app/core/services/tenant_context_service.dart';
import 'package:eventflow_app/core/services/token_service.dart';
import 'package:eventflow_app/core/storage/storage_service.dart';
import 'package:eventflow_app/features/authentication/data/datasources/auth_remote_data_source.dart';
import 'package:eventflow_app/features/authentication/domain/repositories/auth_repository.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class MockTokenService extends Mock implements TokenService {}

class MockNotificationService extends Mock implements NotificationService {}

class MockTenantContextService extends Mock implements TenantContextService {}

void main() {
  setUpAll(() {
    registerFallbackValue('');
  });

  group('AuthRepository.logout', () {
    late MockAuthRemoteDataSource remote;
    late MockTokenService tokenService;
    late MockNotificationService notificationService;
    late MockTenantContextService tenantContextService;
    late StorageService storageService;
    late GuestSessionService guestSessionService;
    late AuthRepository repository;
    late Directory tempDir;

    /// Records the order of the side effects logout() performs.
    late List<String> order;
    late String? revokedToken;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('logout_test_');
      Hive.init(tempDir.path);

      storageService = StorageService();
      await storageService.init();
      guestSessionService = GuestSessionService();
      await guestSessionService.init();

      remote = MockAuthRemoteDataSource();
      tokenService = MockTokenService();
      notificationService = MockNotificationService();
      tenantContextService = MockTenantContextService();

      order = <String>[];
      revokedToken = null;

      when(() => tokenService.getRefreshToken())
          .thenAnswer((_) async => 'refresh-token');
      when(() => tokenService.clearTokens()).thenAnswer((_) async {
        order.add('clearTokens');
      });
      when(() => tenantContextService.clear()).thenAnswer((_) async {});
      when(() => notificationService.deleteToken()).thenAnswer((_) async {
        order.add('deleteToken');
      });
      when(() => remote.logout(any())).thenAnswer((invocation) async {
        revokedToken = invocation.positionalArguments.first as String;
        order.add('remote.logout');
      });

      repository = AuthRepository(
        remoteDataSource: remote,
        tokenService: tokenService,
        tenantContext: tenantContextService,
        guestSessionService: guestSessionService,
        storageService: storageService,
        notificationService: notificationService,
      );
    });

    tearDown(() async {
      await Hive.close();
      await tempDir.delete(recursive: true);
    });

    test(
        'revokes the session on the server before clearing local state and '
        'purges the Hive cache', () async {
      await storageService.cacheJson(
        'cache_customers',
        {'customers': [
          {'full_name': 'Jane Doe', 'mobile': '9876543210'}
        ]},
      );
      await guestSessionService.startSession();
      await storageService.setOnboardingCompleted();

      await repository.logout();

      // API called with the refresh token, then local state cleared.
      expect(revokedToken, 'refresh-token');
      expect(order, ['remote.logout', 'clearTokens', 'deleteToken']);

      // Customer data cached in Hive is gone.
      expect(storageService.get('cache_customers'), isNull);
      // Guest session ended.
      expect(guestSessionService.isGuestSession(), isFalse);
      // Non-cache app preferences survive.
      expect(storageService.isOnboardingCompleted(), isTrue);
    });

    test('still clears local state when the server logout call fails',
        () async {
      when(() => remote.logout(any())).thenThrow(Exception('network down'));
      await storageService.cacheJson('cache_bookings', {'bookings': []});
      await guestSessionService.startSession();

      await repository.logout();

      expect(order, isNot(contains('remote.logout')));
      expect(order, contains('clearTokens'));
      expect(storageService.get('cache_bookings'), isNull);
      expect(guestSessionService.isGuestSession(), isFalse);
    });

    test('skips the API call when no refresh token is stored', () async {
      when(() => tokenService.getRefreshToken()).thenAnswer((_) async => null);
      await storageService.cacheJson('cache_leads', {'leads': []});

      await repository.logout();

      expect(order, isNot(contains('remote.logout')));
      expect(order, contains('clearTokens'));
      expect(storageService.get('cache_leads'), isNull);
    });
  });
}
