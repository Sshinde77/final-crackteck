import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:final_crackteck/core/navigation_service.dart';
import 'package:final_crackteck/core/secure_storage_service.dart';

import 'secure_storage_mock.dart';

Future<void> testBootstrap() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(<String, Object>{});
  NavigationService.resetForTesting();
  SecureStorageService.resetForTesting();
  SecureStorageMock.install();
}
