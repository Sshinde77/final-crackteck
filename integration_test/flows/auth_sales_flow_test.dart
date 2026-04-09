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
    testWidgets('Sales OTP login navigates to dashboard (mock HTTP)', (tester) async {
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
                  'access_token': 'token_sales',
                  'refresh_token': 'refresh_sales',
                  'user_id': 42,
                },
              }),
              200,
              headers: const <String, String>{'content-type': 'application/json'},
            );
          }

          if (path.endsWith('/dashboard')) {
            return http.Response(
              jsonEncode(<String, Object?>{
                'data': <String, Object?>{
                  'target': 0,
                  'achieved': 0,
                  'pending': 0,
                  'tasks': <Object?>[],
                  'meets': <Object?>[],
                  'followups': <Object?>[],
                  'lostLeads': 0,
                  'newLeads': 0,
                  'contactedLeads': 0,
                  'qualifiedLeads': 0,
                  'quotedLeads': 0,
                },
              }),
              200,
              headers: const <String, String>{'content-type': 'application/json'},
            );
          }

          if (path.endsWith('/sales-overview')) {
            return http.Response(
              jsonEncode(<String, Object?>{
                'data': <String, Object?>{
                  'target': 0,
                  'achieved': 0,
                  'pending': 0,
                  'lostLeads': 0,
                  'newLeads': 0,
                  'contactedLeads': 0,
                  'qualifiedLeads': 0,
                  'quotedLeads': 0,
                  'tasks': <Object?>[],
                  'meets': <Object?>[],
                  'followups': <Object?>[],
                },
              }),
              200,
              headers: const <String, String>{'content-type': 'application/json'},
            );
          }

          if (path.endsWith('/leads')) {
            return http.Response(
              jsonEncode(<String, Object?>{
                'data': <Object?>[],
                'meta': <String, Object?>{
                  'current_page': 1,
                  'last_page': 1,
                  'total': 0,
                  'per_page': 15,
                },
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

      // Role selection
      await tester.tap(find.text('Sales Person'));
      await tester.pumpAndSettle();

      // Login
      await tester.enterText(find.byType(TextField).first, '9999999999');
      await tester.tap(find.text('Login with OTP'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // OTP (hidden TextField inside OtpVerificationScreen)
      await tester.enterText(find.byType(TextField).last, '1234');
      await tester.pumpAndSettle(const Duration(seconds: 8));

      // Assert
      // Dashboard is complex; assert we left the auth screens.
      expect(find.textContaining('Select your'), findsNothing);
      expect(find.text('Login with OTP'), findsNothing);
    });
  });
}
