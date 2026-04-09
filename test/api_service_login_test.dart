import 'dart:convert';

import 'package:final_crackteck/core/network/api_http_client.dart';
import 'package:final_crackteck/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'support/secure_storage_mock.dart';
import 'support/test_bootstrap.dart';

void main() {
  setUp(() async {
    await testBootstrap();
  });

  tearDown(() {
    ApiHttpClient.resetOverride();
    SecureStorageMock.reset();
  });

  test('login returns success on 200 JSON', () async {
    ApiHttpClient.overrideForTesting(
      MockClient((http.Request request) async {
        expect(request.method, 'POST');
        expect(request.headers['content-type'] ?? request.headers['Content-Type'],
            isNotNull);

        return http.Response(
          jsonEncode(<String, Object?>{
            'success': true,
            'message': 'OTP sent',
            'data': <String, Object?>{'ok': true},
          }),
          200,
          headers: const <String, String>{'content-type': 'application/json'},
        );
      }),
    );

    final response = await ApiService.instance.login(
      roleId: 1,
      phoneNumber: '9999999999',
    );

    expect(response.success, isTrue);
    expect(response.message, contains('OTP'));
  });

  test('login returns error on HTML body', () async {
    ApiHttpClient.overrideForTesting(
      MockClient((http.Request request) async {
        return http.Response('<html>login</html>', 200);
      }),
    );

    final response = await ApiService.instance.login(
      roleId: 1,
      phoneNumber: '9999999999',
    );

    expect(response.success, isFalse);
    expect(response.message?.toLowerCase(), contains('html'));
  });
}

