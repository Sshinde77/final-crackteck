import 'dart:convert';

import 'package:final_crackteck/routes/app_routes.dart';
import 'package:final_crackteck/services/session_manager.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/secure_storage_mock.dart';
import 'support/test_bootstrap.dart';

String _jwtWithExpiry(DateTime expiryUtc) {
  final header = base64Url.encode(utf8.encode(jsonEncode(<String, Object>{
    'alg': 'HS256',
    'typ': 'JWT',
  })));
  final payload = base64Url.encode(utf8.encode(jsonEncode(<String, Object>{
    'exp': expiryUtc.millisecondsSinceEpoch ~/ 1000,
  })));
  return '$header.$payload.signature';
}

void main() {
  setUp(() async {
    await testBootstrap();
  });

  tearDown(() {
    SecureStorageMock.reset();
  });

  test('defaultRouteForRole maps roles to dashboards', () {
    expect(SessionManager.defaultRouteForRole(1), AppRoutes.FieldExecutiveDashboard);
    expect(SessionManager.defaultRouteForRole(2), AppRoutes.Deliverypersondashbord);
    expect(SessionManager.defaultRouteForRole(3), AppRoutes.salespersonDashboard);
    expect(SessionManager.defaultRouteForRole(999), AppRoutes.roleSelection);
  });

  test('isLoggedIn returns false when token missing', () async {
    final result = await SessionManager.isLoggedIn();
    expect(result, isFalse);
  });

  test('saveSession persists token and role for isLoggedIn', () async {
    final token = _jwtWithExpiry(DateTime.now().toUtc().add(const Duration(hours: 1)));
    await SessionManager.saveSession(accessToken: token, roleId: 1, userId: 42);

    expect(await SessionManager.isLoggedIn(expectedRoleId: 1), isTrue);
    expect(await SessionManager.isLoggedIn(expectedRoleId: 2), isFalse);
  });

  test('isLoggedIn(checkExpiry: true) returns false for expired tokens', () async {
    final token =
        _jwtWithExpiry(DateTime.now().toUtc().subtract(const Duration(hours: 1)));
    await SessionManager.saveSession(accessToken: token, roleId: 1);

    expect(
      await SessionManager.isLoggedIn(expectedRoleId: 1, checkExpiry: true),
      isFalse,
    );
  });

  test('clearSession removes token so isLoggedIn becomes false', () async {
    final token = _jwtWithExpiry(DateTime.now().toUtc().add(const Duration(hours: 1)));
    await SessionManager.saveSession(accessToken: token, roleId: 1);
    expect(await SessionManager.isLoggedIn(expectedRoleId: 1), isTrue);

    await SessionManager.clearSession();
    expect(await SessionManager.isLoggedIn(expectedRoleId: 1), isFalse);
  });
}

