import 'dart:convert';

import 'package:final_crackteck/core/network/api_http_client.dart';
import 'package:final_crackteck/otp_screen.dart';
import 'package:final_crackteck/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../support/secure_storage_mock.dart';
import '../../support/test_bootstrap.dart';

Widget _app({required OtpArguments args}) {
  return MaterialApp(
    routes: <String, WidgetBuilder>{
      AppRoutes.salespersonDashboard: (_) =>
          const Scaffold(body: Text('Sales Dashboard')),
      AppRoutes.roleSelection: (_) => const Scaffold(body: Text('Role Selection')),
    },
    home: OtpVerificationScreen(args: args),
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

  group('OtpVerificationScreen', () {
    testWidgets('shows error when OTP is not 4 digits', (tester) async {
      // Arrange
      ApiHttpClient.overrideForTesting(
        MockClient((http.Request request) async {
          return http.Response('{"message":"unhandled"}', 500);
        }),
      );

      // Act
      await tester.pumpWidget(
        _app(
          args: OtpArguments(
            roleId: 3,
            roleName: 'Sales Person',
            phoneNumber: '9999999999',
          ),
        ),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField), '123');
      await tester.tap(find.text('Verify'));
      await tester.pump();

      // Assert
      expect(find.text('Please enter valid OTP'), findsOneWidget);
    });

    testWidgets('verifies OTP and navigates to dashboard on success',
        (tester) async {
      // Arrange
      ApiHttpClient.overrideForTesting(
        MockClient((http.Request request) async {
          final path = request.url.path;
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
          return http.Response('{"message":"unhandled"}', 500);
        }),
      );

      // Act
      await tester.pumpWidget(
        _app(
          args: OtpArguments(
            roleId: 3,
            roleName: 'Sales Person',
            phoneNumber: '9999999999',
          ),
        ),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField), '1234');
      await tester.pump(const Duration(milliseconds: 700));

      // Assert
      expect(find.text('Sales Dashboard'), findsOneWidget);
    });

    testWidgets('resend OTP is gated until timer expires', (tester) async {
      // Arrange
      int sendOtpCount = 0;
      ApiHttpClient.overrideForTesting(
        MockClient((http.Request request) async {
          final path = request.url.path;
          if (path.endsWith('/send-otp')) {
            sendOtpCount++;
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

      await tester.pumpWidget(
        _app(
          args: OtpArguments(
            roleId: 3,
            roleName: 'Sales Person',
            phoneNumber: '9999999999',
          ),
        ),
      );
      await tester.pump();

      // Act: tap before expiry (should no-op)
      await tester.tap(find.text('Resend code'));
      await tester.pump();

      // Assert
      expect(sendOtpCount, 0);

      // Act: advance time to expiry then tap
      await tester.pump(const Duration(seconds: 80));
      await tester.tap(find.text('Resend code'));
      await tester.pump();

      // Assert
      expect(sendOtpCount, 1);
      expect(find.text('OTP resent'), findsOneWidget);
    });
  });
}

