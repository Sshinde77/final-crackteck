import 'dart:convert';
import 'package:final_crackteck/core/network/api_http_client.dart';
import 'package:final_crackteck/login_screen.dart';
import 'package:final_crackteck/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../helpers/transparent_asset_bundle.dart';
import '../../support/secure_storage_mock.dart';
import '../../support/test_bootstrap.dart';

Widget _testApp() {
  return DefaultAssetBundle(
    bundle: TransparentAssetBundle(),
    child: MaterialApp(
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.otpVerification) {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const Scaffold(body: Text('OTP Screen')),
          );
        }
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const LoginScreen(
            roleId: 3,
            roleName: 'Sales Person',
          ),
        );
      },
    ),
  );
}

void main() {
  setUp(() async {
    await testBootstrap();
  });

  tearDown(() {
    ApiHttpClient.resetOverride();
    SecureStorageMock.reset();
  });

  group('LoginScreen (phone OTP)', () {
    testWidgets('success navigates to OTP route', (tester) async {
      // Arrange
      ApiHttpClient.overrideForTesting(
        MockClient((http.Request request) async {
          if (request.url.path.endsWith('/send-otp')) {
            return http.Response(
              jsonEncode(<String, Object?>{
                'success': true,
                'message': 'OTP sent',
                'data': <String, Object?>{'ok': true},
              }),
              200,
              headers: const <String, String>{'content-type': 'application/json'},
            );
          }
          return http.Response('{"message":"unhandled"}', 500);
        }),
      );

      // Act
      await tester.pumpWidget(_testApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '9999999999');
      await tester.tap(find.text('Login with OTP'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('OTP Screen'), findsOneWidget);
    });
  });
}
