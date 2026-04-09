import 'package:final_crackteck/core/secure_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/secure_storage_mock.dart';
import '../../support/test_bootstrap.dart';

void main() {
  setUp(() async {
    await testBootstrap();
  });

  tearDown(() {
    SecureStorageMock.reset();
  });

  group('SecureStorageService', () {
    test('saveAccessToken trims and persists; empty clears token', () async {
      // Arrange
      const rawToken = '  token_123  ';

      // Act
      await SecureStorageService.saveAccessToken(rawToken);

      // Assert
      expect(
        await SecureStorageService.getAccessToken(forceReload: true),
        'token_123',
      );

      // Act
      await SecureStorageService.saveAccessToken('   ');

      // Assert
      expect(await SecureStorageService.getAccessToken(forceReload: true), isNull);
    });

    test('markVehicleRegisteredForCurrentUser persists per user', () async {
      // Arrange
      await SecureStorageService.saveUserData(userId: 42, roleId: 2);

      // Act / Assert
      expect(
        await SecureStorageService.isVehicleRegisteredForCurrentUser(),
        isFalse,
      );
      await SecureStorageService.markVehicleRegisteredForCurrentUser();
      expect(await SecureStorageService.isVehicleRegisteredForCurrentUser(), isTrue);
    });

    test('getOrCreateDeviceId is stable once created', () async {
      // Act
      final first = await SecureStorageService.getOrCreateDeviceId();
      final second = await SecureStorageService.getOrCreateDeviceId();

      // Assert
      expect(first, isNotEmpty);
      expect(second, first);
    });
  });
}
