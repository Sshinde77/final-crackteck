import 'dart:convert';

import 'package:final_crackteck/core/network/api_http_client.dart';
import 'package:final_crackteck/services/session_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:integration_test/integration_test.dart';

import 'package:final_crackteck/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    ApiHttpClient.resetOverride();
  });

  group('P0 Auth Flow', () {
    testWidgets('Delivery OTP login lands on delivery dashboard (mock HTTP)', (tester) async {
      // Arrange
      await SessionManager.clearSession();

      ApiHttpClient.overrideForTesting(
        MockClient((http.Request request) async {
          final path = request.url.path;

          if (path.endsWith('/send-otp')) {
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

          if (path.endsWith('/verify-otp')) {
            return http.Response(
              jsonEncode(<String, Object?>{
                'success': true,
                'message': 'OTP verified',
                'data': <String, Object?>{
                  'access_token': 'token_delivery',
                  'refresh_token': 'refresh_delivery',
                  'user_id': 77,
                  // Ensure OTP screen marks vehicle registration as completed.
                  'vehicle_no': 'MH12AB1234',
                  'vehicle_type': 'two_wheeler',
                },
              }),
              200,
              headers: const <String, String>{'content-type': 'application/json'},
            );
          }

          // Delivery home loads 4 lists.
          if (path.endsWith('/orders') ||
              path.endsWith('/pickup-requests') ||
              path.endsWith('/return-requests') ||
              path.endsWith('/part-requests')) {
            return http.Response(
              jsonEncode(<String, Object?>{
                'data': <Object?>[],
              }),
              200,
              headers: const <String, String>{'content-type': 'application/json'},
            );
          }

          return http.Response(
            jsonEncode(<String, Object?>{
              'success': false,
              'message': 'Unhandled request: ${request.method} $path',
            }),
            500,
            headers: const <String, String>{'content-type': 'application/json'},
          );
        }),
      );

      // Act
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Role selection -> Delivery Man
      await tester.tap(find.text('Delivery Man'));
      await tester.pumpAndSettle();

      // Login
      await tester.enterText(find.byType(TextField).first, '9999999999');
      await tester.tap(find.text('Login with OTP'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // OTP
      await tester.enterText(find.byType(TextField).last, '1234');
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // Assert
      // Delivery dashboard bottom nav is a stable signal.
      expect(find.text('Home'), findsWidgets);
      expect(find.text('Profile'), findsWidgets);
    });
  });
}

