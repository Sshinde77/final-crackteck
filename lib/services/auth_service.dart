import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../core/secure_storage_service.dart';

class AuthService {
  AuthService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<Map<String, dynamic>> loginWithGoogle(
    String accessToken, {
    required int roleId,
  }) async {
    try {
      debugPrint('Calling google-login API');
      final response = await _client
          .post(
            Uri.parse(ApiConstants.googlelogin),
            headers: const <String, String>{
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(<String, dynamic>{
              'accessToken': accessToken,
              'role_id': roleId,
            }),
          )
          .timeout(ApiConstants.requestTimeout);

      final Map<String, dynamic> jsonResponse = _decodeJson(response.body);
      debugPrint('API Response: ${response.body}');
      final bool apiSuccess = _readSuccess(jsonResponse);
      final bool isSuccess =
          response.statusCode >= 200 &&
          response.statusCode < 300 &&
          apiSuccess;

      if (!isSuccess) {
        return <String, dynamic>{
          'success': false,
          'message':
              jsonResponse['message'] ??
              'Google login failed with status ${response.statusCode}.',
          'data': jsonResponse,
        };
      }

      final String? token = _readString(jsonResponse, const <String>[
        'token',
        'access_token',
      ]);
      if (token == null) {
        return <String, dynamic>{
          'success': false,
          'message': 'Google login succeeded but no token was returned.',
          'data': jsonResponse,
        };
      }

      final String? refreshToken = _readString(jsonResponse, const <String>[
        'refresh_token',
        'refreshToken',
      ]);
      final Map<String, dynamic>? user = _extractUser(jsonResponse);
      final int? userId = _extractUserId(jsonResponse, user);

      await SecureStorageService.saveAccessToken(token);
      if (refreshToken != null) {
        await SecureStorageService.saveRefreshToken(refreshToken);
      }
      if (userId != null) {
        await SecureStorageService.saveUserId(userId);
      }
      if (user != null) {
        await SecureStorageService.saveUserProfile(user);
      }

        return <String, dynamic>{
          'success': true,
          'message': jsonResponse['message'] ?? 'Google login successful.',
        'token': token,
        'user': user,
        'data': jsonResponse,
      };
    } on SocketException {
      return <String, dynamic>{
        'success': false,
        'message': 'No internet connection. Please check your network.',
      };
    } on TimeoutException {
      return <String, dynamic>{
        'success': false,
        'message': 'The request timed out. Please try again.',
      };
    } on http.ClientException catch (error) {
      return <String, dynamic>{
        'success': false,
        'message': 'Request failed: ${error.message}',
      };
    } catch (error) {
      debugPrint('Google backend login error: $error');
      return <String, dynamic>{
        'success': false,
        'message': 'Something went wrong during Google login.',
      };
    }
  }

  bool _readSuccess(Map<String, dynamic> source) {
    final dynamic directSuccess = source['success'] ?? source['status'];
    if (directSuccess is bool) {
      return directSuccess;
    }
    if (directSuccess is num) {
      return directSuccess != 0;
    }
    if (directSuccess is String) {
      final String normalized = directSuccess.trim().toLowerCase();
      return normalized == 'true' || normalized == '1' || normalized == 'success';
    }

    final dynamic data = source['data'];
    if (data is Map<String, dynamic>) {
      final dynamic nestedSuccess = data['success'] ?? data['status'];
      if (nestedSuccess is bool) {
        return nestedSuccess;
      }
      if (nestedSuccess is num) {
        return nestedSuccess != 0;
      }
      if (nestedSuccess is String) {
        final String normalized = nestedSuccess.trim().toLowerCase();
        return normalized == 'true' || normalized == '1' || normalized == 'success';
      }
    }

    return false;
  }

  Map<String, dynamic> _decodeJson(String body) {
    if (body.trim().isEmpty) {
      return <String, dynamic>{};
    }

    final dynamic decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return <String, dynamic>{'data': decoded};
  }

  String? _readString(Map<String, dynamic> source, List<String> keys) {
    for (final String key in keys) {
      final dynamic value = source[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    final dynamic nestedData = source['data'];
    if (nestedData is Map<String, dynamic>) {
      for (final String key in keys) {
        final dynamic value = nestedData[key];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
    }
    return null;
  }

  Map<String, dynamic>? _extractUser(Map<String, dynamic> response) {
    final dynamic directUser = response['user'];
    if (directUser is Map<String, dynamic>) {
      return Map<String, dynamic>.from(directUser);
    }

    final dynamic data = response['data'];
    if (data is Map<String, dynamic>) {
      final dynamic nestedUser = data['user'];
      if (nestedUser is Map<String, dynamic>) {
        return Map<String, dynamic>.from(nestedUser);
      }

      if (data.isNotEmpty) {
        return Map<String, dynamic>.from(data);
      }
    }

    return null;
  }

  int? _extractUserId(
    Map<String, dynamic> response,
    Map<String, dynamic>? user,
  ) {
    final List<dynamic> candidates = <dynamic>[
      response['user_id'],
      response['id'],
      if (user != null) user['user_id'],
      if (user != null) user['id'],
      if (response['data'] is Map<String, dynamic>)
        (response['data'] as Map<String, dynamic>)['user_id'],
      if (response['data'] is Map<String, dynamic>)
        (response['data'] as Map<String, dynamic>)['id'],
    ];

    for (final dynamic candidate in candidates) {
      if (candidate is int) {
        return candidate;
      }
      if (candidate is String) {
        final int? parsed = int.tryParse(candidate.trim());
        if (parsed != null) {
          return parsed;
        }
      }
    }

    return null;
  }
}
