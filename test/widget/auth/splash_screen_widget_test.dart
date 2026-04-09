import 'dart:convert';

import 'package:final_crackteck/routes/app_routes.dart';
import 'package:final_crackteck/screens/splash_screen.dart';
import 'package:final_crackteck/services/session_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/transparent_asset_bundle.dart';
import '../../support/secure_storage_mock.dart';
import '../../support/test_bootstrap.dart';

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

Widget _app() {
  return DefaultAssetBundle(
    bundle: TransparentAssetBundle(),
    child: MaterialApp(
      routes: <String, WidgetBuilder>{
        AppRoutes.roleSelection: (_) => const Scaffold(body: Text('Role Selection')),
        AppRoutes.salespersonDashboard: (_) => const Scaffold(body: Text('Sales Dashboard')),
      },
      home: const SplashScreen(),
    ),
  );
}

void main() {
  setUp(() async {
    await testBootstrap();
  });

  tearDown(() {
    SecureStorageMock.reset();
  });

  group('SplashScreen', () {
    testWidgets('navigates to role selection when logged out', (tester) async {
      // Arrange
      await SessionManager.clearSession();

      // Act
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Role Selection'), findsOneWidget);
    });

    testWidgets('navigates to role dashboard when logged in', (tester) async {
      // Arrange
      final token = _jwtWithExpiry(
        DateTime.now().toUtc().add(const Duration(hours: 1)),
      );
      await SessionManager.saveSession(accessToken: token, roleId: 3, userId: 99);

      // Act
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Sales Dashboard'), findsOneWidget);
    });
  });
}
