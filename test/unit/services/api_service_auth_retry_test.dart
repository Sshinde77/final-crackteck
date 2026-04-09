import 'dart:convert';

import 'package:final_crackteck/core/network/api_http_client.dart';
import 'package:final_crackteck/core/secure_storage_service.dart';
import 'package:final_crackteck/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../support/secure_storage_mock.dart';
import '../../support/test_bootstrap.dart';

void main() {
  setUp(() async {
    await testBootstrap();
  });

  tearDown(() async {
    ApiHttpClient.resetOverride();
    SecureStorageMock.reset();
  });

  group('ApiService authenticated retry', () {
    test('fetchLeads retries after 401 by refreshing token', () async {
      // Arrange
      await SecureStorageService.saveUserData(userId: 42, roleId: 3);
      await SecureStorageService.saveAccessToken('old_token');

      int leadsGetCount = 0;
      int refreshCount = 0;

      ApiHttpClient.overrideForTesting(
        MockClient((http.Request request) async {
          final path = request.url.path;

          if (path.endsWith('/refresh-token')) {
            refreshCount++;
            return http.Response(
              jsonEncode(<String, Object?>{
                'success': true,
                'message': 'refreshed',
                'data': <String, Object?>{
                  'access_token': 'new_token',
                  'refresh_token': 'new_refresh',
                  'user_id': 42,
                },
              }),
              200,
              headers: const <String, String>{'content-type': 'application/json'},
            );
          }

          if (path.endsWith('/leads')) {
            leadsGetCount++;
            if (leadsGetCount == 1) {
              expect(request.headers['Authorization'], 'Bearer old_token');
              return http.Response('{"message":"unauthorized"}', 401);
            }

            // The retry should use the refreshed token.
            expect(request.headers['Authorization'], 'Bearer new_token');
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
            '{"message":"unhandled"}',
            500,
          );
        }),
      );

      // Act
      final response = await ApiService.fetchLeads('42', 3, page: 1);

      // Assert
      expect(refreshCount, 1);
      expect(leadsGetCount, 2);
      expect(response['data'], isA<List<dynamic>>());
    });

    test('fetchLeads treats HTML response as authentication failure', () async {
      // Arrange
      await SecureStorageService.saveUserData(userId: 42, roleId: 3);
      await SecureStorageService.saveAccessToken('token');

      ApiHttpClient.overrideForTesting(
        MockClient((http.Request request) async {
          if (request.url.path.endsWith('/leads')) {
            return http.Response('<html>login</html>', 200);
          }
          return http.Response('{"message":"unhandled"}', 500);
        }),
      );

      // Act / Assert
      expect(
        () => ApiService.fetchLeads('42', 3, page: 1),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Authentication error'),
          ),
        ),
      );
    });
  });
}
