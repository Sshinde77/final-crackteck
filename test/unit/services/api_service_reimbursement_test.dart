import 'package:final_crackteck/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import '../../support/secure_storage_mock.dart';
import '../../support/test_bootstrap.dart';

void main() {
  setUp(() async {
    await testBootstrap();
  });

  tearDown(() {
    SecureStorageMock.reset();
  });

  group('ApiService.addStaffReimbursement', () {
    test('returns auth error when session context is missing', () async {
      // Arrange
      final receipt = XFile('does_not_exist.png');

      // Act
      final response = await ApiService.addStaffReimbursement(
        amount: '100',
        reason: 'Fuel',
        receipt: receipt,
      );

      // Assert
      expect(response.success, isFalse);
      expect(response.message?.toLowerCase(), contains('authentication'));
    });
  });
}

