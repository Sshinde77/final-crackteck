import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../model/api_response.dart';
import '../model/field executive/diagnosis_item.dart';
import '../model/field executive/field_executive_service_request_detail.dart';
import '../core/secure_storage_service.dart';
import '../core/navigation_service.dart';
import 'mock_product_delivery_service.dart';

class _ServiceRequestAuthState {
  final int? userId;
  final int? roleId;
  final String? accessToken;

  const _ServiceRequestAuthState({
    required this.userId,
    required this.roleId,
    required this.accessToken,
  });

  bool get hasAccessToken => accessToken?.trim().isNotEmpty == true;

  List<String> get missingFields {
    return [
      if (userId == null) 'user_id',
      if (roleId == null) 'role_id',
      if (!hasAccessToken) 'access_token',
    ];
  }

  bool get isValid => missingFields.isEmpty;
}

/// API Service for handling HTTP requests
class ApiService {
  ApiService._(); // Private constructor for singleton

  static final ApiService instance = ApiService._();

  // ---------------------------
  // Helper: safe JSON decode
  // ---------------------------
  Map<String, dynamic> _safeJsonDecode(String body) {
    final trimmed = body.trimLeft();

    // Detect HTML responses (e.g. when the backend redirects to a login page)
    if (_looksLikeHtml(trimmed)) {
      debugPrint(
        '🔴 HTML response detected instead of JSON. Body preview: '
        '${trimmed.length > 120 ? trimmed.substring(0, 120) : trimmed}',
      );
      return {
        'message': 'Server returned HTML instead of JSON',
        'raw': body,
        'isHtml': true,
      };
    }

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {
        'message': 'Serve r returned unexpected JSON format',
        'data': decoded,
      };
    } catch (_) {
      return {'message': 'Server returned non-JSON response', 'raw': body};
    }
  }

  // ---------------------------
  // Helper: common headers
  // ---------------------------
  Map<String, String> get _headers => const {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // ---------------------------
  // Helper: token persistence
  // ---------------------------
  Future<int?> _persistTokensFromData(
    dynamic data, {
    required int roleId,
  }) async {
    if (data == null) {
      return null;
    }

    String? accessToken;
    String? refreshToken;
    int? userId;

    if (data is Map<String, dynamic>) {
      accessToken = _extractStringFieldDeep(data, const [
        'access_token',
        'token',
        'accessToken',
      ]);
      refreshToken = _extractStringFieldDeep(data, const [
        'refresh_token',
        'refreshToken',
      ]);

      userId = _extractUserIdFromMap(data);
    } else if (data is String) {
      // Some APIs may return the token directly as a string.
      accessToken = data;
    }

    if (accessToken != null && accessToken.isNotEmpty) {
      await SecureStorageService.saveAccessToken(accessToken);
    }
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await SecureStorageService.saveRefreshToken(refreshToken);
    }

    // Persist role so that refresh-token calls know which role_id to send.
    await SecureStorageService.saveRoleId(roleId);

    // Persist user id when available so dashboard/refresh calls can send it.
    if (userId != null) {
      await SecureStorageService.saveUserId(userId);
    }
    return userId;
  }

  String? _extractStringField(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value is String && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  String? _extractStringFieldDeep(
    dynamic source,
    List<String> keys, {
    int depth = 0,
  }) {
    if (depth > 4 || source == null) return null;

    if (source is Map<String, dynamic>) {
      final direct = _extractStringField(source, keys);
      if (direct != null) return direct;

      for (final value in source.values) {
        final nested = _extractStringFieldDeep(value, keys, depth: depth + 1);
        if (nested != null) return nested;
      }
      return null;
    }

    if (source is List) {
      for (final item in source) {
        final nested = _extractStringFieldDeep(item, keys, depth: depth + 1);
        if (nested != null) return nested;
      }
    }

    return null;
  }

  int? _tryParseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  int? _extractUserIdFromMap(Map<String, dynamic> data) {
    dynamic rawUserId = data['user_id'] ?? data['id'];
    if (rawUserId == null && data['user'] is Map<String, dynamic>) {
      final user = data['user'] as Map<String, dynamic>;
      rawUserId = user['user_id'] ?? user['id'];
    }
    if (rawUserId == null && data['data'] is Map<String, dynamic>) {
      final nested = data['data'] as Map<String, dynamic>;
      rawUserId = nested['user_id'] ?? nested['id'];
      if (rawUserId == null && nested['user'] is Map<String, dynamic>) {
        final nestedUser = nested['user'] as Map<String, dynamic>;
        rawUserId = nestedUser['user_id'] ?? nestedUser['id'];
      }
    }
    return _tryParseInt(rawUserId);
  }

  /// Login - Send OTP
  Future<ApiResponse> login({
    required int roleId,
    required String phoneNumber,
  }) async {
    try {
      debugPrint('🔵 API Request: POST ${ApiConstants.login}');
      debugPrint(
        '🔵 Request Body: {"role_id": $roleId, "phone_number": "$phoneNumber"}',
      );

      final response = await http
          .post(
            Uri.parse(ApiConstants.login),
            headers: _headers,
            body: jsonEncode({'role_id': roleId, 'phone_number': phoneNumber}),
          )
          .timeout(ApiConstants.requestTimeout);

      debugPrint('🟡 API Response Status: ${response.statusCode}');
      debugPrint('🟡 API Response Body: ${response.body}');

      final jsonResponse = _safeJsonDecode(response.body);
      final bool isHtml = jsonResponse['isHtml'] == true;

      // Success
      if (!isHtml &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        return ApiResponse(
          success: jsonResponse['success'] ?? true,
          message: jsonResponse['message'] ?? 'OTP sent',
          data: jsonResponse['data'],
          errors: jsonResponse['errors'],
        );
      }

      // Common "user not found / invalid" status codes
      if (!isHtml &&
          (response.statusCode == 404 || response.statusCode == 422)) {
        return ApiResponse(
          success: false,
          message: jsonResponse['message'] ?? 'User not found',
          errors: jsonResponse['errors'],
        );
      }

      // Other server errors
      return ApiResponse(
        success: false,
        message:
            jsonResponse['message'] ??
            (isHtml
                ? 'Server returned HTML instead of JSON'
                : 'Server error: ${response.statusCode}'),
        errors: jsonResponse['errors'],
      );
    } on HandshakeException catch (e) {
      debugPrint('🔴 SSL Handshake Error: $e');
      return ApiResponse(success: false, message: 'SSL error: ${e.message}');
    } on SocketException catch (e) {
      debugPrint('🔴 No Internet / DNS Error: $e');
      return ApiResponse(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } on http.ClientException catch (e) {
      debugPrint('🔴 ClientException: $e');
      return ApiResponse(
        success: false,
        message: 'Request failed: ${e.message}',
      );
    } on TimeoutException catch (e) {
      debugPrint('🔴 Timeout: $e');
      return ApiResponse(
        success: false,
        message: 'Request timeout. Please try again.',
      );
    } catch (e) {
      debugPrint('🔴 Unexpected Error: $e');
      return ApiResponse(success: false, message: 'Unexpected error: $e');
    }
  }

  /// Verify OTP
  Future<ApiResponse> verifyOtp({
    required int roleId,
    required String phoneNumber,
    required String otp,
  }) async {
    try {
      debugPrint('🔵 API Request: POST ${ApiConstants.verifyOtp}');
      debugPrint(
        '🔵 Request Body: {"role_id": $roleId, "phone_number": "$phoneNumber", "otp": "$otp"}',
      );

      final response = await http
          .post(
            Uri.parse(ApiConstants.verifyOtp),
            headers: _headers,
            body: jsonEncode({
              'role_id': roleId,
              'phone_number': phoneNumber,
              'otp': otp,
            }),
          )
          .timeout(ApiConstants.requestTimeout);

      debugPrint('🟡 API Response Status: ${response.statusCode}');
      debugPrint('🟡 API Response Body: ${response.body}');

      final jsonResponse = _safeJsonDecode(response.body);
      final bool isHtml = jsonResponse['isHtml'] == true;

      if (!isHtml &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        // Always persist role_id for authenticated flows.
        await SecureStorageService.saveRoleId(roleId);
        final authPayload = jsonResponse['data'] ?? jsonResponse;

        // Persist tokens/user details from both common payload shapes.
        int? persistedUserId = await _persistTokensFromData(
          authPayload,
          roleId: roleId,
        );
        persistedUserId ??=
            await _persistTokensFromData(jsonResponse, roleId: roleId);

        if (persistedUserId == null) {
          // Prevent stale user_id from previous sessions from being reused.
          await SecureStorageService.clearUserId();
          debugPrint(
            'WARNING: verifyOtp response did not contain user_id for role_id=$roleId. '
            'Blocking authenticated flows.',
          );
          return ApiResponse(
            success: false,
            message:
                'Login verified, but account session is incomplete. Please login again.',
            data: authPayload,
            errors: jsonResponse['errors'],
          );
        }

        final persistedAuthState = await _readServiceRequestAuthState(
          forceReload: true,
        );
        _logServiceRequestOtpAuthState(
          'verifyOtp.postPersist',
          persistedAuthState,
        );

        return ApiResponse(
          success: jsonResponse['success'] ?? true,
          message: jsonResponse['message'] ?? 'OTP verified',
          data: authPayload,
          errors: jsonResponse['errors'],
        );
      }

      if (!isHtml &&
          (response.statusCode == 404 || response.statusCode == 422)) {
        return ApiResponse(
          success: false,
          message: jsonResponse['message'] ?? 'Invalid OTP / user not found',
          errors: jsonResponse['errors'],
        );
      }

      return ApiResponse(
        success: false,
        message:
            jsonResponse['message'] ??
            (isHtml
                ? 'Server returned HTML instead of JSON'
                : 'Server error: ${response.statusCode}'),
        errors: jsonResponse['errors'],
      );
    } on HandshakeException catch (e) {
      debugPrint('🔴 SSL Handshake Error: $e');
      return ApiResponse(success: false, message: 'SSL error: ${e.message}');
    } on SocketException catch (e) {
      debugPrint('🔴 No Internet / DNS Error: $e');
      return ApiResponse(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } on http.ClientException catch (e) {
      debugPrint('🔴 ClientException: $e');
      return ApiResponse(
        success: false,
        message: 'Request failed: ${e.message}',
      );
    } on TimeoutException catch (e) {
      debugPrint('🔴 Timeout: $e');
      return ApiResponse(
        success: false,
        message: 'Request timeout. Please try again.',
      );
    } catch (e) {
      debugPrint('🔴 Unexpected Error: $e');
      return ApiResponse(success: false, message: 'Unexpected error: $e');
    }
  }

  /// Refresh Token
  Future<ApiResponse> refreshToken({
    required int roleId,
    required int userId,
  }) async {
    try {
      debugPrint('🔵 API Request: POST ${ApiConstants.refreshToken}');
      debugPrint('🔵 Request Query: {"user_id": $userId, "role_id": $roleId}');

      final currentAccessToken = await SecureStorageService.getAccessToken();
      final headers = Map<String, String>.from(_headers)
        ..addAll({
          if (currentAccessToken != null && currentAccessToken.isNotEmpty)
            'Authorization': 'Bearer $currentAccessToken',
        });

      final uri = Uri.parse(ApiConstants.refreshToken).replace(
        queryParameters: {
          'user_id': userId.toString(),
          'role_id': roleId.toString(),
        },
      );

      final response = await http
          .post(
            uri,
            headers: headers,
            // Keep body for backward compatibility; backend primarily reads query.
            body: jsonEncode({'role_id': roleId}),
          )
          .timeout(ApiConstants.requestTimeout);

      debugPrint('🟡 API Response Status: ${response.statusCode}');
      debugPrint('🟡 API Response Body: ${response.body}');

      final jsonResponse = _safeJsonDecode(response.body);
      final bool isHtml = jsonResponse['isHtml'] == true;

      if (!isHtml &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        // Persist any tokens contained in the refresh response.
        await _persistTokensFromData(jsonResponse['data'], roleId: roleId);
        return ApiResponse(
          success: jsonResponse['success'] ?? true,
          message: jsonResponse['message'] ?? 'Token refreshed',
          data: jsonResponse['data'],
          errors: jsonResponse['errors'],
        );
      }

      return ApiResponse(
        success: false,
        message:
            jsonResponse['message'] ??
            (isHtml
                ? 'Server returned HTML instead of JSON'
                : 'Token refresh failed'),
        errors: jsonResponse['errors'],
      );
    } on HandshakeException catch (e) {
      debugPrint('🔴 SSL Handshake Error: $e');
      return ApiResponse(success: false, message: 'SSL error: ${e.message}');
    } on SocketException {
      return ApiResponse(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } on TimeoutException {
      return ApiResponse(
        success: false,
        message: 'Request timeout. Please try again.',
      );
    } catch (e) {
      debugPrint('🔴 Unexpected Error: $e');
      return ApiResponse(success: false, message: 'Unexpected error: $e');
    }
  }

  Future<ApiResponse> signup({
    required String name,
    required String phone,
    required String email,
    required String address,
    required String aadhar,
    required String pan,
    required File aadharFile,
    required File panFile,
    String? firstName,
    String? lastName,
    String? addressLine1,
    String? addressLine2,
    String? country,
    String? state,
    String? city,
    String? pincode,
    File? aadharBackFile,
    File? panBackFile,
    String? drivingLicenceNumber,
    File? licenceFrontFile,
    File? licenceBackFile,
  }) async {
    try {
      final uri = Uri.parse(ApiConstants.signup);

      final fields = <String, String>{
        "name": name,
        "phone": phone,
        "email": email,
        "address": address,
        "aadhar_no": aadhar,
        "pan_no": pan,
      };

      if (firstName != null && firstName.trim().isNotEmpty) {
        fields["first_name"] = firstName.trim();
      }
      if (lastName != null && lastName.trim().isNotEmpty) {
        fields["last_name"] = lastName.trim();
      }
      if (addressLine1 != null && addressLine1.trim().isNotEmpty) {
        fields["address_line_1"] = addressLine1.trim();
      }
      if (addressLine2 != null && addressLine2.trim().isNotEmpty) {
        fields["address_line_2"] = addressLine2.trim();
      }
      if (country != null && country.trim().isNotEmpty) {
        fields["country"] = country.trim();
      }
      if (state != null && state.trim().isNotEmpty) {
        fields["state"] = state.trim();
      }
      if (city != null && city.trim().isNotEmpty) {
        fields["city"] = city.trim();
      }
      if (pincode != null && pincode.trim().isNotEmpty) {
        fields["pincode"] = pincode.trim();
      }

      if (drivingLicenceNumber != null && drivingLicenceNumber.isNotEmpty) {
        fields["driving_licence_no"] = drivingLicenceNumber;
      }

      final request = http.MultipartRequest("POST", uri)
        ..fields.addAll(fields)
        ..files.add(
          await http.MultipartFile.fromPath("aadhar_document", aadharFile.path),
        )
        ..files.add(
          await http.MultipartFile.fromPath("pan_document", panFile.path),
        );

      if (aadharBackFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            "aadhar_back_document",
            aadharBackFile.path,
          ),
        );
      }

      if (panBackFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            "pan_back_document",
            panBackFile.path,
          ),
        );
      }

      if (licenceFrontFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            "licence_front_image",
            licenceFrontFile.path,
          ),
        );
      }

      if (licenceBackFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            "licence_back_image",
            licenceBackFile.path,
          ),
        );
      }

      final response = await request.send();
      final resBody = await response.stream.bytesToString();

      if (_looksLikeHtml(resBody)) {
        debugPrint(
          'HTML response detected for ${ApiConstants.signup}. Treating as failure.',
        );
        return ApiResponse(
          success: false,
          message: 'Server returned HTML instead of JSON',
          data: null,
          errors: const {},
        );
      }

      final json = jsonDecode(resBody);
      return ApiResponse.fromJson(json, (data) => data);
    } catch (e, stackTrace) {
      debugPrint('Signup error: $e');
      debugPrint('$stackTrace');
      return ApiResponse(
        success: false,
        message: 'Unexpected signup error: $e',
        data: null,
        errors: const {},
      );
    }
  }

  /// Logout
  Future<ApiResponse> logout({required int roleId}) async {
    try {
      debugPrint('🔵 API Request: POST ${ApiConstants.logout}');
      debugPrint('🔵 Request Body: {"role_id": $roleId}');

      final storedUserId = await SecureStorageService.getUserId();
      final currentAccessToken = await SecureStorageService.getAccessToken();

      final headers = Map<String, String>.from(_headers)
        ..addAll({
          if (currentAccessToken != null && currentAccessToken.isNotEmpty)
            'Authorization': 'Bearer $currentAccessToken',
        });

      final queryParameters = <String, String>{
        'role_id': roleId.toString(),
        if (storedUserId != null) 'user_id': storedUserId.toString(),
      };

      final requestBody = <String, dynamic>{
        'role_id': roleId,
        if (storedUserId != null) 'user_id': storedUserId,
      };

      final uri = Uri.parse(ApiConstants.logout).replace(
        queryParameters: queryParameters,
      );

      debugPrint('API Request: POST $uri');
      debugPrint('Request Query: $queryParameters');
      debugPrint('Request Body: $requestBody');

      final response = await http
          .post(
            uri,
            headers: headers,
            body: jsonEncode(requestBody),
          )
          .timeout(ApiConstants.requestTimeout);

      debugPrint('🟡 API Response Status: ${response.statusCode}');
      debugPrint('🟡 API Response Body: ${response.body}');

      final jsonResponse = _safeJsonDecode(response.body);
      final bool isHtml = jsonResponse['isHtml'] == true;

      if (!isHtml &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        return ApiResponse(
          success: jsonResponse['success'] ?? true,
          message: jsonResponse['message'] ?? 'Logged out',
          data: jsonResponse['data'],
          errors: jsonResponse['errors'],
        );
      }

      return ApiResponse(
        success: false,
        message:
            jsonResponse['message'] ??
            (isHtml ? 'Server returned HTML instead of JSON' : 'Logout failed'),
        errors: jsonResponse['errors'],
      );
    } on HandshakeException catch (e) {
      debugPrint('🔴 SSL Handshake Error: $e');
      return ApiResponse(success: false, message: 'SSL error: ${e.message}');
    } on SocketException {
      return ApiResponse(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } on TimeoutException {
      return ApiResponse(
        success: false,
        message: 'Request timeout. Please try again.',
      );
    } catch (e) {
      debugPrint('🔴 Unexpected Error: $e');
      return ApiResponse(success: false, message: 'Unexpected error: $e');
    }
  }

  /// Field Executive Clock-In
  ///
  /// POST /check-in?user_id={userId}&role_id={roleId}
  Future<ApiResponse> clockIn({required int roleId}) async {
    try {
      final storedUserId = await SecureStorageService.getUserId();
      final storedRoleId = await SecureStorageService.getRoleId();
      final effectiveRoleId = storedRoleId ?? (roleId > 0 ? roleId : null);

      if (storedUserId == null || effectiveRoleId == null) {
        return ApiResponse(
          success: false,
          message: 'Missing user/role information. Please log in again.',
        );
      }

      final uri = Uri.parse(ApiConstants.fieldexecutiveclockin).replace(
        queryParameters: {
          'user_id': storedUserId.toString(),
          'role_id': effectiveRoleId.toString(),
        },
      );

      debugPrint('API Request: POST $uri');
      final response = await _performAuthenticatedPost(uri);
      debugPrint('API Response Status: ${response.statusCode}');
      debugPrint('API Response Body: ${response.body}');

      final jsonResponse = ApiService.instance._safeJsonDecode(response.body);
      final bool isHtml = jsonResponse['isHtml'] == true;

      if (isHtml) {
        await _handleAuthFailure();
        return ApiResponse(
          success: false,
          message: 'Authentication error. Please log in again.',
        );
      }

      final bool success =
          response.statusCode == 200 ||
          response.statusCode == 201 ||
          jsonResponse['success'] == true;

      return ApiResponse(
        success: success,
        message: jsonResponse['message'] ??
            (success ? 'Clock-in successful' : 'Clock-in failed'),
        // Keep the full response when "data" is not present
        // so screens can still read fields like auth_log.login_at.
        data: jsonResponse['data'] ?? jsonResponse,
        errors: jsonResponse['errors'],
      );
    } on SocketException {
      return ApiResponse(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } on TimeoutException {
      return ApiResponse(
        success: false,
        message: 'Request timeout. Please try again.',
      );
    } catch (e) {
      debugPrint('Clock-in error: $e');
      return ApiResponse(
        success: false,
        message: 'Unexpected error during clock-in: $e',
      );
    }
  }

  /// Field Executive Clock-Out
  ///
  /// POST /check-out?user_id={userId}&role_id={roleId}
  Future<ApiResponse> clockOut({required int roleId}) async {
    try {
      final storedUserId = await SecureStorageService.getUserId();
      final storedRoleId = await SecureStorageService.getRoleId();
      final effectiveRoleId = storedRoleId ?? (roleId > 0 ? roleId : null);

      if (storedUserId == null || effectiveRoleId == null) {
        return ApiResponse(
          success: false,
          message: 'Missing user/role information. Please log in again.',
        );
      }

      final uri = Uri.parse(ApiConstants.fieldexecutiveclockout).replace(
        queryParameters: {
          'user_id': storedUserId.toString(),
          'role_id': effectiveRoleId.toString(),
        },
      );

      debugPrint('API Request: POST $uri');
      final response = await _performAuthenticatedPost(uri);
      debugPrint('API Response Status: ${response.statusCode}');
      debugPrint('API Response Body: ${response.body}');

      final jsonResponse = ApiService.instance._safeJsonDecode(response.body);
      final bool isHtml = jsonResponse['isHtml'] == true;

      if (isHtml) {
        await _handleAuthFailure();
        return ApiResponse(
          success: false,
          message: 'Authentication error. Please log in again.',
        );
      }

      final bool success =
          response.statusCode == 200 ||
          response.statusCode == 201 ||
          jsonResponse['success'] == true;

      return ApiResponse(
        success: success,
        message: jsonResponse['message'] ??
            (success ? 'Clock-out successful' : 'Clock-out failed'),
        // Keep the full response when "data" is not present
        // so screens can still read fields like auth_log.logout_at.
        data: jsonResponse['data'] ?? jsonResponse,
        errors: jsonResponse['errors'],
      );
    } on SocketException {
      return ApiResponse(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } on TimeoutException {
      return ApiResponse(
        success: false,
        message: 'Request timeout. Please try again.',
      );
    } catch (e) {
      debugPrint('Clock-out error: $e');
      return ApiResponse(
        success: false,
        message: 'Unexpected error during clock-out: $e',
      );
    }
  }

  /// Register vehicle for Delivery Person
  ///
  /// POST /vehicle-registration?role_id={roleId}&brand={brand}&model={model}
  ///      &vehicle_number={registrationNumber}&fuel_type={fuelType}
  Future<ApiResponse> registerVehicle({
    required int roleId,
    required String brand,
    required String model,
    required String registrationNumber,
    required String fuelType,
  }) async {
    try {
      debugPrint('🔵 API Request: POST ${ApiConstants.registervehicle}');
      debugPrint(
        '🔵 Request Query: {"role_id": $roleId, "brand": "$brand", "model": "$model", "vehicle_number": "$registrationNumber", "fuel_type": "$fuelType"}',
      );

      // We perform vehicle registration only after OTP verification, so the
      // authenticated user id should already be stored in SecureStorage.
      final storedUserId = await SecureStorageService.getUserId();
      if (storedUserId == null) {
        debugPrint(
          '🔴 Vehicle registration failed: missing stored user_id after OTP verification',
        );
        return ApiResponse(
          success: false,
          message: 'Missing user id. Please log in again.',
          errors: const {
            'user_id': ['Missing user id in client storage'],
          },
        );
      }

      final currentAccessToken = await SecureStorageService.getAccessToken();
      final headers = Map<String, String>.from(_headers)
        ..addAll({
          if (currentAccessToken != null && currentAccessToken.isNotEmpty)
            'Authorization': 'Bearer $currentAccessToken',
        });

      final uri = Uri.parse(ApiConstants.registervehicle).replace(
        queryParameters: {
          'role_id': roleId.toString(),
          'user_id': storedUserId.toString(),
          'brand': brand,
          'model': model,
          'vehicle_number': registrationNumber,
          'fuel_type': fuelType,
        },
      );

      final response = await http
          .post(uri, headers: headers)
          .timeout(ApiConstants.requestTimeout);

      debugPrint('🟡 API Response Status: ${response.statusCode}');
      debugPrint('🟡 API Response Body: ${response.body}');

      final jsonResponse = _safeJsonDecode(response.body);
      final bool isHtml = jsonResponse['isHtml'] == true;

      if (!isHtml &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        return ApiResponse(
          success: jsonResponse['success'] ?? true,
          message: jsonResponse['message'] ?? 'Vehicle registered',
          data: jsonResponse['data'],
          errors: jsonResponse['errors'],
        );
      }

      if (!isHtml &&
          (response.statusCode == 400 ||
              response.statusCode == 404 ||
              response.statusCode == 422)) {
        return ApiResponse(
          success: false,
          message: jsonResponse['message'] ?? 'Vehicle registration failed',
          errors: jsonResponse['errors'],
        );
      }

      return ApiResponse(
        success: false,
        message:
            jsonResponse['message'] ??
            (isHtml
                ? 'Server returned HTML instead of JSON'
                : 'Server error: ${response.statusCode}'),
        errors: jsonResponse['errors'],
      );
    } on HandshakeException catch (e) {
      debugPrint('🔴 SSL Handshake Error (vehicle registration): $e');
      return ApiResponse(success: false, message: 'SSL error: ${e.message}');
    } on SocketException catch (e) {
      debugPrint('🔴 No Internet / DNS Error (vehicle registration): $e');
      return ApiResponse(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } on http.ClientException catch (e) {
      debugPrint('🔴 ClientException (vehicle registration): $e');
      return ApiResponse(
        success: false,
        message: 'Request failed: ${e.message}',
      );
    } on TimeoutException catch (e) {
      debugPrint('🔴 Timeout (vehicle registration): $e');
      return ApiResponse(
        success: false,
        message: 'Request timeout. Please try again.',
      );
    } catch (e) {
      debugPrint('🔴 Unexpected Error (vehicle registration): $e');
      return ApiResponse(success: false, message: 'Unexpected error: $e');
    }
  }

  // ========================================
  // Sales Dashboard API Methods
  // ========================================

  static const int _fallbackRoleIdForRefresh = 3; // Salesperson role id
  static const int _maxAuthRetries = 1;

  /// Heuristic check for HTML content (e.g. redirected login page).
  static bool _looksLikeHtml(String body) {
    final trimmed = body.trimLeft();
    if (trimmed.isEmpty) return false;
    final lower = trimmed.toLowerCase();
    return lower.startsWith('<!doctype html') || lower.startsWith('<html');
  }

  static bool _isUnauthorizedResponse(http.Response response) {
    if (response.statusCode == 401 || response.statusCode == 403) {
      return true;
    }

    // Some backends redirect unauthorized requests to an HTML login page
    // while still returning 200. Detect that and treat as unauthorized so we
    // trigger refresh-token/logout instead of trying to parse HTML as JSON.
    if (_looksLikeHtml(response.body)) {
      debugPrint(
        '🔴 HTML login page detected from ${response.request?.url}. '
        'Treating as unauthorized.',
      );
      return true;
    }

    final bodyLower = response.body.toLowerCase();
    return bodyLower.contains('401') ||
        bodyLower.contains('unauthorized') ||
        bodyLower.contains('token not provided');
  }

  static Future<bool> _attemptTokenRefresh() async {
    final storedRoleId = await SecureStorageService.getRoleId();
    final storedUserId = await SecureStorageService.getUserId();
    if (storedUserId == null) {
      debugPrint('🔴 Cannot refresh token: missing stored user_id');
      return false;
    }

    final roleId = storedRoleId ?? _fallbackRoleIdForRefresh;
    final api = ApiService.instance;
    final response = await api.refreshToken(
      roleId: roleId,
      userId: storedUserId,
    );
    return response.success;
  }

  static Future<void> _handleAuthFailure() async {
    await SecureStorageService.clearTokens();
    await NavigationService.navigateToAuthRoot();
  }

  static Future<_ServiceRequestAuthState> _readServiceRequestAuthState({
    bool forceReload = false,
  }) async {
    return _ServiceRequestAuthState(
      userId: await SecureStorageService.getUserId(forceReload: forceReload),
      roleId: await SecureStorageService.getRoleId(forceReload: forceReload),
      accessToken: await SecureStorageService.getAccessToken(
        forceReload: forceReload,
      ),
    );
  }

  static void _logServiceRequestOtpAuthState(
    String flow,
    _ServiceRequestAuthState state,
  ) {
    debugPrint(
      '[ServiceRequestOtp][$flow] auth state: '
      'user_id=${state.userId ?? 'missing'}, '
      'role_id=${state.roleId ?? 'missing'}, '
      'has_access_token=${state.hasAccessToken}',
    );
  }

  static String _buildMissingServiceRequestAuthMessage(
    List<String> missingFields,
  ) {
    return 'Authentication session is incomplete (missing: ${missingFields.join(', ')}). '
        'Please login again.';
  }

  static Future<ApiResponse?> _ensureServiceRequestOtpAuthState({
    required String flow,
    bool redirectOnFailure = true,
  }) async {
    final state = await _readServiceRequestAuthState(forceReload: true);
    _logServiceRequestOtpAuthState(flow, state);

    if (state.isValid) {
      return null;
    }

    final message = _buildMissingServiceRequestAuthMessage(state.missingFields);
    debugPrint('[ServiceRequestOtp][$flow] $message');

    if (redirectOnFailure) {
      await NavigationService.navigateToAuthRoot();
    }

    return ApiResponse(success: false, message: message);
  }

  static Future<ApiResponse> validateServiceRequestOtpAuthState({
    String flow = 'service-request-otp',
    bool redirectOnFailure = false,
  }) async {
    final validation = await _ensureServiceRequestOtpAuthState(
      flow: flow,
      redirectOnFailure: redirectOnFailure,
    );
    return validation ?? ApiResponse(success: true, message: 'Authentication validated.');
  }

  static Future<http.Response> _performAuthenticatedGet(Uri url) async {
    int retryCount = 0;
    while (true) {
      final accessToken = await SecureStorageService.getAccessToken();
      final headers = <String, String>{
        'Accept': 'application/json',
        if (accessToken != null && accessToken.isNotEmpty)
          'Authorization': 'Bearer $accessToken',
      };

      final response = await http
          .get(url, headers: headers)
          .timeout(ApiConstants.requestTimeout);

      if (!_isUnauthorizedResponse(response)) {
        return response;
      }

      // Unauthorized
      if (retryCount >= _maxAuthRetries) {
        await _handleAuthFailure();
        return response;
      }

      retryCount++;
      final refreshed = await _attemptTokenRefresh();
      if (!refreshed) {
        await _handleAuthFailure();
        return response;
      }
      // Token refreshed successfully, loop will retry with new token.
    }
  }

  static Future<http.Response> _performAuthenticatedDelete(Uri url) async {
    int retryCount = 0;
    while (true) {
      final accessToken = await SecureStorageService.getAccessToken();
      final headers = <String, String>{
        'Accept': 'application/json',
        if (accessToken != null && accessToken.isNotEmpty)
          'Authorization': 'Bearer $accessToken',
      };

      final response = await http
          .delete(url, headers: headers)
          .timeout(ApiConstants.requestTimeout);

      if (!_isUnauthorizedResponse(response)) {
        return response;
      }

      if (retryCount >= _maxAuthRetries) {
        await _handleAuthFailure();
        return response;
      }

      retryCount++;
      final refreshed = await _attemptTokenRefresh();
      if (!refreshed) {
        await _handleAuthFailure();
        return response;
      }
    }
  }

  static Future<http.Response> _performAuthenticatedPost(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    int retryCount = 0;
    while (true) {
      final accessToken = await SecureStorageService.getAccessToken();
      final mergedHeaders = <String, String>{
        'Accept': 'application/json',
        if (headers != null) ...headers,
        if (accessToken != null && accessToken.isNotEmpty)
          'Authorization': 'Bearer $accessToken',
      };

      final response = await http
          .post(url, headers: mergedHeaders, body: body)
          .timeout(ApiConstants.requestTimeout);

      if (!_isUnauthorizedResponse(response)) {
        return response;
      }

      if (retryCount >= _maxAuthRetries) {
        await _handleAuthFailure();
        return response;
      }

      retryCount++;
      final refreshed = await _attemptTokenRefresh();
      if (!refreshed) {
        await _handleAuthFailure();
        return response;
      }
    }
  }

  static Future<http.Response> _performAuthenticatedPut(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    int retryCount = 0;
    while (true) {
      final accessToken = await SecureStorageService.getAccessToken();
      final mergedHeaders = <String, String>{
        'Accept': 'application/json',
        if (headers != null) ...headers,
        if (accessToken != null && accessToken.isNotEmpty)
          'Authorization': 'Bearer $accessToken',
      };

      final response = await http
          .put(url, headers: mergedHeaders, body: body)
          .timeout(ApiConstants.requestTimeout);

      if (!_isUnauthorizedResponse(response)) {
        return response;
      }

      if (retryCount >= _maxAuthRetries) {
        await _handleAuthFailure();
        return response;
      }

      retryCount++;
      final refreshed = await _attemptTokenRefresh();
      if (!refreshed) {
        await _handleAuthFailure();
        return response;
      }
    }
  }

  static String? _extractFirstErrorMessage(dynamic errors) {
    if (errors is Map<String, dynamic>) {
      for (final value in errors.values) {
        if (value is List && value.isNotEmpty) {
          final first = value.first?.toString().trim();
          if (first != null && first.isNotEmpty) return first;
        }
        final text = value?.toString().trim();
        if (text != null && text.isNotEmpty) return text;
      }
    }
    if (errors is List && errors.isNotEmpty) {
      final first = errors.first?.toString().trim();
      if (first != null && first.isNotEmpty) return first;
    }
    return null;
  }

  /// Fetch dashboard data for a specific user
  /// GET /dashboard?user_id={userId}&role_id={roleId}
  static Future<Map<String, dynamic>> fetchDashboard(String userId) async {
    final storedUserId = await SecureStorageService.getUserId();
    final storedRoleId = await SecureStorageService.getRoleId();

    final effectiveUserId = storedUserId?.toString() ?? userId;
    final effectiveRoleId =
        storedRoleId?.toString() ?? _fallbackRoleIdForRefresh.toString();

    final url = Uri.parse(ApiConstants.dashboard).replace(
      queryParameters: {'user_id': effectiveUserId, 'role_id': effectiveRoleId},
    );

    try {
      debugPrint('🔵 API Request: GET $url');

      final response = await _performAuthenticatedGet(url);

      debugPrint('🟡 API Response Status: ${response.statusCode}');
      debugPrint('🟡 API Response Body: ${response.body}');

      if (_looksLikeHtml(response.body)) {
        debugPrint(
          '🔴 HTML response detected for $url. Treating as authentication failure.',
        );
        await _handleAuthFailure();
        throw Exception('Authentication error. Please log in again.');
      }

      if (response.statusCode == 200) {
        dynamic decoded;
        try {
          decoded = jsonDecode(response.body);
        } catch (_) {
          decoded = {
            'message': 'Server returned non-JSON',
            'raw': response.body,
          };
        }

        // Handle different response structures
        if (decoded is Map<String, dynamic> &&
            decoded.containsKey('data') &&
            decoded['data'] is Map<String, dynamic>) {
          return decoded['data'] as Map<String, dynamic>;
        }
        if (decoded is Map<String, dynamic>) return decoded;
        return {'data': decoded};
      } else {
        throw Exception(
          'Failed to load dashboard data: ${response.statusCode}',
        );
      }
    } on TimeoutException catch (e) {
      debugPrint('🔴 Timeout: $e');
      throw Exception('Request timeout. Please try again.');
    } on SocketException catch (e) {
      debugPrint('🔴 No Internet: $e');
      throw Exception('No internet connection. Please check your network.');
    } catch (e) {
      debugPrint('🔴 Error fetching dashboard: $e');
      throw Exception('Failed to load dashboard data: $e');
    }
  }

  /// Fetch sales overview data
  /// GET /sales-overview?user_id={userId}
  static Future<Map<String, dynamic>> fetchSalesOverview() async {
    final storedUserId = await SecureStorageService.getUserId();
    final url = storedUserId != null
        ? Uri.parse(
            ApiConstants.salesOverview,
          ).replace(queryParameters: {'user_id': storedUserId.toString()})
        : Uri.parse(ApiConstants.salesOverview);

    try {
      debugPrint('🔵 API Request: GET $url');

      final response = await _performAuthenticatedGet(url);

      debugPrint('🟡 API Response Status: ${response.statusCode}');
      debugPrint('🟡 API Response Body: ${response.body}');

      if (_looksLikeHtml(response.body)) {
        debugPrint(
          '🔴 HTML response detected for $url. Treating as authentication failure.',
        );
        await _handleAuthFailure();
        throw Exception('Authentication error. Please log in again.');
      }

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        // Handle different response structures
        if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
          return decoded['data'] is Map<String, dynamic>
              ? decoded['data']
              : {'data': decoded['data']};
        }
        if (decoded is Map<String, dynamic>) return decoded;
        return {'data': decoded};
      } else {
        throw Exception(
          'Failed to load sales overview: ${response.statusCode}',
        );
      }
    } on TimeoutException catch (e) {
      debugPrint('🔴 Timeout: $e');
      throw Exception('Request timeout. Please try again.');
    } on SocketException catch (e) {
      debugPrint('🔴 No Internet: $e');
      throw Exception('No internet connection. Please check your network.');
    } catch (e) {
      debugPrint('🔴 Error fetching sales overview: $e');
      throw Exception('Failed to load sales overview: $e');
    }
  }

  /// Fetch tasks list
  /// GET /task?user_id={userId}
  static Future<List<dynamic>> fetchTasks() async {
    final storedUserId = await SecureStorageService.getUserId();
    final url = storedUserId != null
        ? Uri.parse(
            ApiConstants.task,
          ).replace(queryParameters: {'user_id': storedUserId.toString()})
        : Uri.parse(ApiConstants.task);

    try {
      debugPrint('🔵 API Request: GET $url');

      final response = await _performAuthenticatedGet(url);

      debugPrint('🟡 API Response Status: ${response.statusCode}');
      debugPrint('🟡 API Response Body: ${response.body}');

      if (_looksLikeHtml(response.body)) {
        debugPrint(
          '🔴 HTML response detected for $url. Treating as authentication failure.',
        );
        await _handleAuthFailure();
        throw Exception('Authentication error. Please log in again.');
      }

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        // Handle different response structures
        if (decoded is Map<String, dynamic>) {
          // Common pattern: { "data": [ ... ] }
          if (decoded.containsKey('data')) {
            return decoded['data'] is List ? decoded['data'] : [];
          }

          // Newer pattern (as per backend schema):
          // { "meets": [ ... ], "followup": [ ... ] }
          final List<dynamic> combined = [];
          final meets = decoded['meets'];
          final followups = decoded['followup'];
          if (meets is List) combined.addAll(meets);
          if (followups is List) combined.addAll(followups);
          if (combined.isNotEmpty) return combined;
        }
        if (decoded is List) return decoded;
        return [];
      } else {
        throw Exception('Failed to load tasks: ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      debugPrint('🔴 Timeout: $e');
      throw Exception('Request timeout. Please try again.');
    } on SocketException catch (e) {
      debugPrint('🔴 No Internet: $e');
      throw Exception('No internet connection. Please check your network.');
    } catch (e) {
      debugPrint('🔴 Error fetching tasks: $e');
      throw Exception('Failed to load tasks: $e');
    }
  }

  /// Fetch notifications list
  /// GET /notifications (optionally with user_id)
  static Future<List<dynamic>> fetchNotifications() async {
    final storedUserId = await SecureStorageService.getUserId();
    final url = storedUserId != null
        ? Uri.parse(
            ApiConstants.notifications,
          ).replace(queryParameters: {'user_id': storedUserId.toString()})
        : Uri.parse(ApiConstants.notifications);

    try {
      debugPrint('🔵 API Request: GET $url');

      final response = await _performAuthenticatedGet(url);

      debugPrint('🟡 API Response Status: ${response.statusCode}');
      debugPrint('🟡 API Response Body: ${response.body}');

      if (_looksLikeHtml(response.body)) {
        debugPrint(
          '🔴 HTML response detected for $url. Treating as authentication failure.',
        );
        await _handleAuthFailure();
        throw Exception('Authentication error. Please log in again.');
      }

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        // Handle different response structures
        if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
          return decoded['data'] is List ? decoded['data'] : [];
        }
        if (decoded is List) return decoded;
        return [];
      } else {
        throw Exception('Failed to load notifications: ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      debugPrint('🔴 Timeout: $e');
      throw Exception('Request timeout. Please try again.');
    } on SocketException catch (e) {
      debugPrint('🔴 No Internet: $e');
      throw Exception('No internet connection. Please check your network.');
    } catch (e) {
      debugPrint('🔴 Error fetching notifications: $e');
      throw Exception('Failed to load notifications: $e');
    }
  }

  /// Fetch delivery requests list based on one delivery type only.
  /// GET /pickup-requests OR /return-requests OR /part-requests
  static Future<List<Map<String, dynamic>>> fetchDeliveryRequests({
    required String deliveryType,
    int roleId = 1,
  }) async {
    final normalizedType = DeliveryRequestTypes.normalize(deliveryType);
    if (normalizedType == DeliveryRequestTypes.productDelivery) {
      return MockProductDeliveryService.fetchRequests();
    }

    final storedUserId = await SecureStorageService.getUserId();
    final storedRoleId = await SecureStorageService.getRoleId();

    if (storedUserId == null) {
      debugPrint(
        'Missing userId in secure storage when calling fetchDeliveryRequests',
      );
      await _handleAuthFailure();
      throw Exception('Authentication error. Please log in again.');
    }

    final endpoint = DeliveryRequestTypes.endpointFor(normalizedType);
    final effectiveRoleId = (storedRoleId ?? roleId).toString();

    final url = Uri.parse(endpoint).replace(
      queryParameters: {
        'user_id': storedUserId.toString(),
        'role_id': effectiveRoleId,
      },
    );

    try {
      debugPrint('API Request: GET $url');

      final response = await _performAuthenticatedGet(url);

      debugPrint('API Response Status: ${response.statusCode}');
      debugPrint('API Response Body: ${response.body}');

      if (_looksLikeHtml(response.body)) {
        debugPrint(
          'HTML response detected for $url. Treating as authentication failure.',
        );
        await _handleAuthFailure();
        throw Exception('Authentication error. Please log in again.');
      }

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to load delivery requests: ${response.statusCode}',
        );
      }

      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        throw Exception('Server returned non-JSON delivery request response');
      }

      List<dynamic> rawList = const [];
      if (decoded is List) {
        rawList = decoded;
      } else if (decoded is Map<String, dynamic>) {
        rawList = _extractDeliveryRequestList(decoded, normalizedType);
      }

      return rawList
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } on TimeoutException catch (e) {
      debugPrint('Timeout: $e');
      throw Exception('Request timeout. Please try again.');
    } on SocketException catch (e) {
      debugPrint('No Internet: $e');
      throw Exception('No internet connection. Please check your network.');
    } on ArgumentError catch (e) {
      debugPrint('Invalid delivery type: $e');
      throw Exception('Invalid delivery type: $deliveryType');
    } catch (e) {
      debugPrint('Error fetching delivery requests: $e');
      rethrow;
    }
  }

  /// Fetch single delivery request detail based on one delivery type only.
  /// GET /pickup-request/{id} OR /return-request/{id} OR /part-request/{id}
  static Future<Map<String, dynamic>> fetchDeliveryRequestDetail({
    required String deliveryType,
    required String deliveryId,
    int roleId = 1,
  }) async {
    final normalizedType = DeliveryRequestTypes.normalize(deliveryType);
    if (normalizedType == DeliveryRequestTypes.productDelivery) {
      return MockProductDeliveryService.fetchRequestDetail(deliveryId);
    }

    final storedUserId = await SecureStorageService.getUserId();
    final storedRoleId = await SecureStorageService.getRoleId();

    if (storedUserId == null) {
      debugPrint(
        'Missing userId in secure storage when calling fetchDeliveryRequestDetail',
      );
      await _handleAuthFailure();
      throw Exception('Authentication error. Please log in again.');
    }

    final sanitizedDeliveryId = deliveryId.trim().replaceFirst(RegExp(r'^#'), '');
    if (sanitizedDeliveryId.isEmpty) {
      throw Exception('Invalid delivery id: $deliveryId');
    }

    final endpoint = DeliveryRequestTypes.detailEndpointFor(deliveryType);
    final effectiveRoleId = (storedRoleId ?? roleId).toString();
    final url = Uri.parse('$endpoint/$sanitizedDeliveryId').replace(
      queryParameters: {
        'role_id': effectiveRoleId,
        'user_id': storedUserId.toString(),
      },
    );

    try {
      debugPrint('API Request: GET $url');

      final response = await _performAuthenticatedGet(url);

      debugPrint('API Response Status: ${response.statusCode}');
      debugPrint('API Response Body: ${response.body}');

      if (_looksLikeHtml(response.body)) {
        debugPrint(
          'HTML response detected for $url. Treating as authentication failure.',
        );
        await _handleAuthFailure();
        throw Exception('Authentication error. Please log in again.');
      }

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to load delivery request details: ${response.statusCode}',
        );
      }

      final dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        throw Exception('Server returned non-JSON delivery request response');
      }

      final detail = _extractDeliveryRequestDetail(decoded, sanitizedDeliveryId);
      return detail ?? const <String, dynamic>{};
    } on TimeoutException catch (e) {
      debugPrint('Timeout: $e');
      throw Exception('Request timeout. Please try again.');
    } on SocketException catch (e) {
      debugPrint('No Internet: $e');
      throw Exception('No internet connection. Please check your network.');
    } on ArgumentError catch (e) {
      debugPrint('Invalid delivery detail params: $e');
      throw Exception(e.message ?? 'Invalid delivery request detail input');
    } catch (e) {
      debugPrint('Error fetching delivery request detail: $e');
      rethrow;
    }
  }

  static Map<String, dynamic>? _extractDeliveryRequestDetail(
    dynamic response,
    String deliveryId,
  ) {
    final normalizedDeliveryId = deliveryId.trim().replaceFirst(RegExp(r'^#'), '');
    final numericDeliveryId = int.tryParse(normalizedDeliveryId);

    bool matchesRequest(Map<String, dynamic> item) {
      bool matchesValue(dynamic value) {
        if (value == null) return false;
        final asText = value.toString().trim();
        if (asText.isEmpty) return false;
        if (asText == normalizedDeliveryId) return true;
        if (numericDeliveryId != null) {
          final asNum = int.tryParse(asText);
          return asNum != null && asNum == numericDeliveryId;
        }
        return false;
      }

      return matchesValue(item['id']) || matchesValue(item['request_id']);
    }

    Map<String, dynamic>? fromMap(dynamic value) {
      if (value is Map<String, dynamic>) {
        return Map<String, dynamic>.from(value);
      }
      if (value is Map) {
        return Map<String, dynamic>.from(value as Map);
      }
      return null;
    }

    List<Map<String, dynamic>> fromList(dynamic value) {
      if (value is! List) return const <Map<String, dynamic>>[];
      return value
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }

    if (response is Map<String, dynamic>) {
      const mapKeys = <String>[
        'data',
        'pickup_request',
        'return_request',
        'part_request',
        'request',
      ];
      for (final key in mapKeys) {
        final single = fromMap(response[key]);
        if (single != null) return single;
      }

      const listKeys = <String>[
        'data',
        'pickup_requests',
        'return_requests',
        'part_requests',
        'requests',
        'items',
      ];
      for (final key in listKeys) {
        final items = fromList(response[key]);
        if (items.isEmpty) continue;
        for (final item in items) {
          if (matchesRequest(item)) return item;
        }
        return items.first;
      }
      return null;
    }

    if (response is List) {
      final items = response
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      if (items.isEmpty) return null;
      for (final item in items) {
        if (matchesRequest(item)) return item;
      }
      return items.first;
    }

    return null;
  }

  static List<dynamic> _extractDeliveryRequestList(
    Map<String, dynamic> response,
    String deliveryType,
  ) {
    List<dynamic> readListFromKeys(Map<String, dynamic> source, List<String> keys) {
      for (final key in keys) {
        final value = source[key];
        if (value is List) {
          return value;
        }
      }
      return const <dynamic>[];
    }

    final typeSpecificKeys = <String, List<String>>{
      DeliveryRequestTypes.pickup: const ['pickup_requests', 'pickupRequests'],
      DeliveryRequestTypes.returnRequest: const [
        'return_requests',
        'returnRequests',
      ],
      DeliveryRequestTypes.part: const ['part_requests', 'partRequests'],
    };

    final genericKeys = <String>[
      'data',
      'requests',
      'delivery_requests',
      'deliveryRequests',
      'items',
    ];

    final fromTopLevel = readListFromKeys(
      response,
      <String>[
        ...?typeSpecificKeys[deliveryType],
        ...genericKeys,
      ],
    );
    if (fromTopLevel.isNotEmpty) {
      return fromTopLevel;
    }

    final nestedData = response['data'];
    if (nestedData is Map<String, dynamic>) {
      return readListFromKeys(
        nestedData,
        <String>[
          ...?typeSpecificKeys[deliveryType],
          ...genericKeys,
        ],
      );
    }

    return const <dynamic>[];
  }

  static Future<List<Map<String, dynamic>>> fetchServiceRequests({
    int roleId = 1,
  }) async {
    final storedUserId = await SecureStorageService.getUserId();
    final storedRoleId = await SecureStorageService.getRoleId();

    if (storedUserId == null) {
      debugPrint(
        'ðŸ”´ Missing userId in secure storage when calling fetchServiceRequests',
      );
      await _handleAuthFailure();
      throw Exception('Authentication error. Please log in again.');
    }

    final effectiveRoleId = (storedRoleId ?? roleId).toString();
    final url = Uri.parse(ApiConstants.serviceRequests).replace(
      queryParameters: {
        'user_id': storedUserId.toString(),
        'role_id': effectiveRoleId,
      },
    );

    try {
      debugPrint('ðŸ”µ API Request: GET $url');

      final response = await _performAuthenticatedGet(url);

      debugPrint('ðŸŸ¡ API Response Status: ${response.statusCode}');
      debugPrint('ðŸŸ¡ API Response Body: ${response.body}');

      if (_looksLikeHtml(response.body)) {
        debugPrint(
          'ðŸ”´ HTML response detected for $url. Treating as authentication failure.',
        );
        await _handleAuthFailure();
        throw Exception('Authentication error. Please log in again.');
      }

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to load service requests: ${response.statusCode}',
        );
      }

      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        throw Exception('Server returned non-JSON service requests response');
      }

      List<dynamic> rawList = const [];

      if (decoded is List) {
        rawList = decoded;
      } else if (decoded is Map<String, dynamic>) {
        if (decoded['serviceRequests'] is List) {
          rawList = decoded['serviceRequests'] as List;
        } else if (decoded['service_requests'] is List) {
          rawList = decoded['service_requests'] as List;
        } else if (decoded['data'] is List) {
          rawList = decoded['data'] as List;
        }
      }

      return rawList
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } on TimeoutException catch (e) {
      debugPrint('ðŸ”´ Timeout: $e');
      throw Exception('Request timeout. Please try again.');
    } on SocketException catch (e) {
      debugPrint('ðŸ”´ No Internet: $e');
      throw Exception('No internet connection. Please check your network.');
    } catch (e) {
      debugPrint('ðŸ”´ Error fetching service requests: $e');
      rethrow;
    }
  }

  /// Fetch stock in hand list for field executive.
  /// GET /stock-in-hand/list?user_id={userId}&role_id={roleId}
  static Future<List<Map<String, dynamic>>> fetchStockInHand({
    int roleId = 1,
  }) async {
    final storedUserId = await SecureStorageService.getUserId();
    final storedRoleId = await SecureStorageService.getRoleId();

    if (storedUserId == null) {
      debugPrint(
        'Missing userId in secure storage when calling fetchStockInHand',
      );
      await _handleAuthFailure();
      throw Exception('Authentication error. Please log in again.');
    }

    final effectiveRoleId = (storedRoleId ?? roleId).toString();
    final url = Uri.parse(ApiConstants.stockinhand).replace(
      queryParameters: {
        'user_id': storedUserId.toString(),
        'role_id': effectiveRoleId,
      },
    );

    try {
      debugPrint('API Request: GET $url');

      final response = await _performAuthenticatedGet(url);

      debugPrint('API Response Status: ${response.statusCode}');
      debugPrint('API Response Body: ${response.body}');

      if (_looksLikeHtml(response.body)) {
        debugPrint(
          'HTML response detected for $url. Treating as authentication failure.',
        );
        await _handleAuthFailure();
        throw Exception('Authentication error. Please log in again.');
      }

      if (response.statusCode != 200) {
        throw Exception('Failed to load stock in hand: ${response.statusCode}');
      }

      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        throw Exception('Server returned non-JSON stock response');
      }

      List<dynamic> rawList = const [];

      if (decoded is List) {
        rawList = decoded;
      } else if (decoded is Map<String, dynamic>) {
        if (decoded['stock_in_hand_items'] is List) {
          rawList = decoded['stock_in_hand_items'] as List;
        } else if (decoded['stock_in_hand'] is List) {
          rawList = decoded['stock_in_hand'] as List;
        } else if (decoded['stockInHand'] is List) {
          rawList = decoded['stockInHand'] as List;
        } else if (decoded['items'] is List) {
          rawList = decoded['items'] as List;
        } else if (decoded['data'] is List) {
          rawList = decoded['data'] as List;
        } else if (decoded['data'] is Map<String, dynamic>) {
          final nested = decoded['data'] as Map<String, dynamic>;
          if (nested['stock_in_hand_items'] is List) {
            rawList = nested['stock_in_hand_items'] as List;
          } else if (nested['stock_in_hand'] is List) {
            rawList = nested['stock_in_hand'] as List;
          } else if (nested['stockInHand'] is List) {
            rawList = nested['stockInHand'] as List;
          } else if (nested['items'] is List) {
            rawList = nested['items'] as List;
          }
        }
      }

      return rawList
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } on TimeoutException catch (e) {
      debugPrint('Timeout: $e');
      throw Exception('Request timeout. Please try again.');
    } on SocketException catch (e) {
      debugPrint('No Internet: $e');
      throw Exception('No internet connection. Please check your network.');
    } catch (e) {
      debugPrint('Error fetching stock in hand: $e');
      rethrow;
    }
  }

  /// Fetch one stock-in-hand item by product id (or stock item id as fallback).
  static Future<Map<String, dynamic>> fetchStockInHandProductById(
    String productId, {
    int roleId = 1,
  }) async {
    final normalizedTarget = productId.trim().replaceFirst(RegExp(r'^#'), '');
    final items = await fetchStockInHand(roleId: roleId);

    if (items.isEmpty) {
      throw Exception('No stock in hand data available.');
    }

    if (normalizedTarget.isEmpty) {
      return items.first;
    }

    String normalize(dynamic value) {
      if (value == null) return '';
      return value.toString().trim().replaceFirst(RegExp(r'^#'), '');
    }

    bool matchesItem(Map<String, dynamic> item) {
      final productMap = item['products'] is Map
          ? Map<String, dynamic>.from(item['products'] as Map)
          : <String, dynamic>{};

      final candidates = <dynamic>[
        productMap['product_id'],
        productMap['productId'],
        productMap['id'],
        item['product_id'],
        item['productId'],
        item['stock_in_hand_id'],
        item['stockInHandId'],
        item['id'],
      ];

      for (final candidate in candidates) {
        if (normalize(candidate) == normalizedTarget) {
          return true;
        }
      }
      return false;
    }

    for (final item in items) {
      if (matchesItem(item)) {
        return item;
      }
    }

    throw Exception('Product not found for id: $normalizedTarget');
  }

  /// Fetch products list for field executive add-product flow.
  /// GET /products?user_id={userId}&role_id={roleId}
  static Future<List<Map<String, dynamic>>> fetchFieldExecutiveProducts({
    int roleId = 1,
  }) async {
    final storedUserId = await SecureStorageService.getUserId();
    final storedRoleId = await SecureStorageService.getRoleId();

    if (storedUserId == null) {
      debugPrint(
        'Missing userId in secure storage when calling fetchFieldExecutiveProducts',
      );
      await _handleAuthFailure();
      throw Exception('Authentication error. Please log in again.');
    }

    final effectiveRoleId = (storedRoleId ?? roleId).toString();
    final url = Uri.parse(ApiConstants.productlistFE).replace(
      queryParameters: {
        'user_id': storedUserId.toString(),
        'role_id': effectiveRoleId,
      },
    );

    try {
      debugPrint('API Request: GET $url');

      final response = await _performAuthenticatedGet(url);

      debugPrint('API Response Status: ${response.statusCode}');
      debugPrint('API Response Body: ${response.body}');

      if (_looksLikeHtml(response.body)) {
        debugPrint(
          'HTML response detected for $url. Treating as authentication failure.',
        );
        await _handleAuthFailure();
        throw Exception('Authentication error. Please log in again.');
      }

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to load field executive products: ${response.statusCode}',
        );
      }

      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        throw Exception('Server returned non-JSON products response');
      }

      List<dynamic> rawList = const [];

      if (decoded is List) {
        rawList = decoded;
      } else if (decoded is Map<String, dynamic>) {
        if (decoded['products'] is List) {
          rawList = decoded['products'] as List;
        } else if (decoded['product_list'] is List) {
          rawList = decoded['product_list'] as List;
        } else if (decoded['items'] is List) {
          rawList = decoded['items'] as List;
        } else if (decoded['data'] is List) {
          rawList = decoded['data'] as List;
        } else if (decoded['data'] is Map<String, dynamic>) {
          final nested = decoded['data'] as Map<String, dynamic>;
          if (nested['products'] is List) {
            rawList = nested['products'] as List;
          } else if (nested['product_list'] is List) {
            rawList = nested['product_list'] as List;
          } else if (nested['items'] is List) {
            rawList = nested['items'] as List;
          }
        }
      }

      return rawList
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } on TimeoutException catch (e) {
      debugPrint('Timeout: $e');
      throw Exception('Request timeout. Please try again.');
    } on SocketException catch (e) {
      debugPrint('No Internet: $e');
      throw Exception('No internet connection. Please check your network.');
    } catch (e) {
      debugPrint('Error fetching field executive products: $e');
      rethrow;
    }
  }

  /// Fetch one product detail for field executive.
  /// GET /products/{product_id}?user_id={userId}&role_id={roleId}
  static Future<Map<String, dynamic>> fetchFieldExecutiveProductDetail(
    String productId, {
    int roleId = 1,
  }) async {
    final storedUserId = await SecureStorageService.getUserId();
    final storedRoleId = await SecureStorageService.getRoleId();

    if (storedUserId == null) {
      debugPrint(
        'Missing userId in secure storage when calling fetchFieldExecutiveProductDetail',
      );
      await _handleAuthFailure();
      throw Exception('Authentication error. Please log in again.');
    }

    final normalizedId = productId.trim().replaceFirst(RegExp(r'^#'), '');
    if (normalizedId.isEmpty) {
      throw Exception('Product id is required to load product detail.');
    }

    final effectiveRoleId = (storedRoleId ?? roleId).toString();

    String endpoint = ApiConstants.productlistdetailFE
        .replaceFirst('{product_id}', normalizedId)
        .replaceFirst('{product-id}', normalizedId);
    if (endpoint.contains('{product_id}') || endpoint.contains('{product-id}')) {
      endpoint = '${ApiConstants.productlistFE}/$normalizedId';
    }

    final url = Uri.parse(endpoint).replace(
      queryParameters: {
        'user_id': storedUserId.toString(),
        'role_id': effectiveRoleId,
      },
    );

    try {
      debugPrint('API Request: GET $url');

      final response = await _performAuthenticatedGet(url);

      debugPrint('API Response Status: ${response.statusCode}');
      debugPrint('API Response Body: ${response.body}');

      if (_looksLikeHtml(response.body)) {
        debugPrint(
          'HTML response detected for $url. Treating as authentication failure.',
        );
        await _handleAuthFailure();
        throw Exception('Authentication error. Please log in again.');
      }

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to load field executive product detail: ${response.statusCode}',
        );
      }

      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        throw Exception('Server returned non-JSON product detail response');
      }

      Map<String, dynamic>? mapFromDynamic(dynamic value) {
        if (value is Map<String, dynamic>) return value;
        if (value is Map) return Map<String, dynamic>.from(value);
        return null;
      }

      Map<String, dynamic>? detail;

      if (decoded is Map<String, dynamic>) {
        detail = mapFromDynamic(decoded['data']) ??
            mapFromDynamic(decoded['product']) ??
            mapFromDynamic(decoded['products']) ??
            mapFromDynamic(decoded);

        if (detail != null && detail == decoded) {
          final hasLeafField =
              detail.containsKey('product_name') ||
              detail.containsKey('name') ||
              detail.containsKey('final_price') ||
              detail.containsKey('id');
          if (!hasLeafField) {
            detail = null;
          }
        }

        final dataList = decoded['data'];
        if (detail == null && dataList is List && dataList.isNotEmpty) {
          detail = mapFromDynamic(dataList.first);
        }
      } else if (decoded is List && decoded.isNotEmpty) {
        detail = mapFromDynamic(decoded.first);
      }

      if (detail == null) {
        throw Exception('Product detail payload is empty or invalid.');
      }

      return detail;
    } on TimeoutException catch (e) {
      debugPrint('Timeout: $e');
      throw Exception('Request timeout. Please try again.');
    } on SocketException catch (e) {
      debugPrint('No Internet: $e');
      throw Exception('No internet connection. Please check your network.');
    } catch (e) {
      debugPrint('Error fetching field executive product detail: $e');
      rethrow;
    }
  }

  /// Request a new product/part for field executive stock.
  /// POST /stock-in-hand/request?role_id={roleId}&user_id={userId}&part_id={partId}&requested_quantity={qty}
  static Future<ApiResponse> requestNewProduct({
    required String partId,
    required int requestedQuantity,
    int roleId = 1,
  }) async {
    final storedUserId = await SecureStorageService.getUserId();
    final storedRoleId = await SecureStorageService.getRoleId();

    if (storedUserId == null) {
      debugPrint(
        'Missing userId in secure storage when calling requestNewProduct',
      );
      await _handleAuthFailure();
      return ApiResponse(
        success: false,
        message: 'Authentication error. Please log in again.',
      );
    }

    final normalizedPartId = partId.trim().replaceFirst(RegExp(r'^#'), '');
    if (normalizedPartId.isEmpty || int.tryParse(normalizedPartId) == null) {
      return ApiResponse(
        success: false,
        message: 'Invalid part id "$partId". Expected numeric product id.',
      );
    }

    final safeQty = requestedQuantity < 1 ? 1 : requestedQuantity;
    final effectiveRoleId = (storedRoleId ?? roleId).toString();

    final url = Uri.parse(ApiConstants.Requestnewproduct).replace(
      queryParameters: {
        'role_id': effectiveRoleId,
        'user_id': storedUserId.toString(),
        'part_id': normalizedPartId,
        'requested_quantity': safeQty.toString(),
      },
    );

    try {
      debugPrint('API Request: POST $url');
      final response = await _performAuthenticatedPost(url);
      debugPrint('API Response Status: ${response.statusCode}');
      debugPrint('API Response Body: ${response.body}');

      if (_looksLikeHtml(response.body)) {
        await _handleAuthFailure();
        return ApiResponse(
          success: false,
          message: 'Authentication error. Please log in again.',
        );
      }

      Map<String, dynamic>? decoded;
      try {
        final dynamic json = jsonDecode(response.body);
        if (json is Map<String, dynamic>) {
          decoded = json;
        } else if (json is Map) {
          decoded = Map<String, dynamic>.from(json);
        }
      } catch (_) {
        decoded = null;
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse(
          success: decoded?['success'] ?? true,
          message: decoded?['message'] ?? 'Product request submitted',
          data: decoded?['data'],
          errors: decoded?['errors'],
        );
      }

      return ApiResponse(
        success: false,
        message:
            decoded?['message'] ??
            'Failed to request product: ${response.statusCode}',
        data: decoded?['data'],
        errors: decoded?['errors'],
      );
    } on TimeoutException catch (e) {
      debugPrint('Timeout: $e');
      return ApiResponse(
        success: false,
        message: 'Request timeout. Please try again.',
      );
    } on SocketException catch (e) {
      debugPrint('No Internet: $e');
      return ApiResponse(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } catch (e) {
      debugPrint('Error requesting new product: $e');
      return ApiResponse(
        success: false,
        message: 'Failed to request product: $e',
      );
    }
  }

  /// Accept a service request for field executive.
  /// POST /service-request/{id}/accept?user_id={userId}&role_id={roleId}
  static Future<ApiResponse> acceptServiceRequest(
    String serviceRequestId, {
    int? roleId,
  }) async {
    final storedUserId = await SecureStorageService.getUserId();
    final storedRoleId = await SecureStorageService.getRoleId();

    if (storedUserId == null) {
      debugPrint(
        'Missing userId in secure storage when calling acceptServiceRequest',
      );
      await _handleAuthFailure();
      return ApiResponse(
        success: false,
        message: 'Authentication error. Please log in again.',
      );
    }

    final normalizedId = serviceRequestId
        .trim()
        .replaceFirst(RegExp(r'^#'), '');
    final numericId = int.tryParse(normalizedId);
    if (numericId == null) {
      return ApiResponse(
        success: false,
        message:
            'Invalid service request id "$serviceRequestId". Expected numeric id.',
      );
    }

    final effectiveRoleId = (storedRoleId ?? roleId ?? 1).toString();

    String baseEndpoint = ApiConstants.ServiceRequestAccept
        .replaceFirst('{service-request_id}', numericId.toString())
        .replaceFirst('{service_request_id}', numericId.toString());
    if (baseEndpoint.contains('{service-request_id}') ||
        baseEndpoint.contains('{service_request_id}')) {
      baseEndpoint = '${ApiConstants.serviceRequestdetails}/$numericId';
    }
    if (!baseEndpoint.endsWith('/accept')) {
      baseEndpoint = '$baseEndpoint/accept';
    }

    final url = Uri.parse(baseEndpoint).replace(
      queryParameters: {
        'user_id': storedUserId.toString(),
        'role_id': effectiveRoleId,
      },
    );
    final body = <String, String>{
      'user_id': storedUserId.toString(),
      'role_id': effectiveRoleId,
    };

    try {
      debugPrint('API Request: POST $url');
      debugPrint('API Request Body: $body');
      final response = await _performAuthenticatedPost(url, body: body);
      debugPrint('API Response Status: ${response.statusCode}');
      debugPrint('API Response Body: ${response.body}');

      if (_looksLikeHtml(response.body)) {
        await _handleAuthFailure();
        return ApiResponse(
          success: false,
          message: 'Authentication error. Please log in again.',
        );
      }

      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        decoded = <String, dynamic>{};
      }

      final map = decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{'data': decoded};

      final bool success =
          response.statusCode == 200 ||
          response.statusCode == 201 ||
          map['success'] == true;

      return ApiResponse(
        success: success,
        message: (map['message']?.toString().trim().isNotEmpty ?? false)
            ? map['message'].toString()
            : (success ? 'Service request accepted' : 'Failed to accept request'),
        data: map['data'],
        errors: map['errors'],
      );
    } on TimeoutException {
      return ApiResponse(
        success: false,
        message: 'Request timeout. Please try again.',
      );
    } on SocketException {
      return ApiResponse(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to accept request: $e',
      );
    }
  }

  /// Accept a delivery request for part / pickup / return.
  /// POST /part-request/{id}/accept?role_id={roleId}&user_id={userId}
  /// POST /pickup-request/{id}/accept?role_id={roleId}&user_id={userId}
  /// POST /return-request/{id}/accept?role_id={roleId}&user_id={userId}
  static Future<ApiResponse> acceptDeliveryRequest({
    required String deliveryType,
    required String deliveryId,
    int? roleId,
  }) async {
    final normalizedType = DeliveryRequestTypes.normalize(deliveryType);
    if (normalizedType == DeliveryRequestTypes.productDelivery) {
      return ApiResponse(
        success: true,
        message: 'Product delivery accepted successfully',
        data: <String, dynamic>{
          'delivery_id': deliveryId.trim().replaceFirst(RegExp(r'^#'), ''),
        },
      );
    }

    final storedUserId = await SecureStorageService.getUserId();
    final storedRoleId = await SecureStorageService.getRoleId();

    if (storedUserId == null) {
      debugPrint(
        'Missing userId in secure storage when calling acceptDeliveryRequest',
      );
      await _handleAuthFailure();
      return ApiResponse(
        success: false,
        message: 'Authentication error. Please log in again.',
      );
    }

    final normalizedId = deliveryId.trim().replaceFirst(RegExp(r'^#'), '');
    final numericId = int.tryParse(normalizedId);
    if (numericId == null) {
      return ApiResponse(
        success: false,
        message: 'Invalid delivery id "$deliveryId". Expected numeric id.',
      );
    }

    final effectiveRoleId = (storedRoleId ?? roleId ?? 1).toString();

    String endpoint = DeliveryRequestTypes.acceptEndpointTemplateFor(deliveryType)
        .replaceFirst('{id}', numericId.toString());

    if (endpoint.contains('{id}')) {
      endpoint = endpoint.replaceAll('{id}', numericId.toString());
    } else if (!endpoint.contains('/$numericId/accept')) {
      var base = endpoint.trim();
      if (base.endsWith('/')) {
        base = base.substring(0, base.length - 1);
      }
      if (base.endsWith('/accept')) {
        base = base.substring(0, base.length - '/accept'.length);
      }
      endpoint = '$base/$numericId/accept';
    }

    final url = Uri.parse(endpoint).replace(
      queryParameters: {
        'role_id': effectiveRoleId,
        'user_id': storedUserId.toString(),
      },
    );

    try {
      debugPrint('API Request: POST $url');
      final response = await _performAuthenticatedPost(url);
      debugPrint('API Response Status: ${response.statusCode}');
      debugPrint('API Response Body: ${response.body}');

      if (_looksLikeHtml(response.body)) {
        await _handleAuthFailure();
        return ApiResponse(
          success: false,
          message: 'Authentication error. Please log in again.',
        );
      }

      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        decoded = <String, dynamic>{};
      }

      final map = decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{'data': decoded};

      final success =
          response.statusCode == 200 ||
          response.statusCode == 201 ||
          map['success'] == true;

      return ApiResponse(
        success: success,
        message: (map['message']?.toString().trim().isNotEmpty ?? false)
            ? map['message'].toString()
            : (success
                ? 'Delivery request accepted successfully'
                : 'Failed to accept delivery request'),
        data: map['data'],
        errors: map['errors'],
      );
    } on TimeoutException {
      return ApiResponse(
        success: false,
        message: 'Request timeout. Please try again.',
      );
    } on SocketException {
      return ApiResponse(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } on ArgumentError catch (e) {
      return ApiResponse(
        success: false,
        message: e.message?.toString() ?? 'Invalid delivery type',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to accept delivery request: $e',
      );
    }
  }

  /// Send OTP for a delivery request for part / pickup / return.
  /// POST /part-request/{id}/send-otp?role_id={roleId}&user_id={userId}
  /// POST /pickup-request/{id}/send-otp?role_id={roleId}&user_id={userId}
  /// POST /return-request/{id}/send-otp?role_id={roleId}&user_id={userId}
  static Future<ApiResponse> sendDeliveryRequestOtp({
    required String deliveryType,
    required String deliveryId,
    int? roleId,
  }) async {
    final normalizedType = DeliveryRequestTypes.normalize(deliveryType);
    if (normalizedType == DeliveryRequestTypes.productDelivery) {
      return ApiResponse(
        success: true,
        message: 'OTP sent successfully. Use 1234 for product delivery.',
        data: <String, dynamic>{
          'delivery_id': deliveryId.trim().replaceFirst(RegExp(r'^#'), ''),
          'otp': '1234',
        },
      );
    }

    final storedUserId = await SecureStorageService.getUserId();
    final storedRoleId = await SecureStorageService.getRoleId();

    if (storedUserId == null) {
      debugPrint(
        'Missing userId in secure storage when calling sendDeliveryRequestOtp',
      );
      await _handleAuthFailure();
      return ApiResponse(
        success: false,
        message: 'Authentication error. Please log in again.',
      );
    }

    final normalizedId = deliveryId.trim().replaceFirst(RegExp(r'^#'), '');
    final numericId = int.tryParse(normalizedId);
    if (numericId == null) {
      return ApiResponse(
        success: false,
        message: 'Invalid delivery id "$deliveryId". Expected numeric id.',
      );
    }

    String endpoint;
    try {
      endpoint = DeliveryRequestTypes.sendOtpEndpointTemplateFor(deliveryType)
          .replaceFirst('{id}', numericId.toString());
    } on ArgumentError catch (e) {
      return ApiResponse(
        success: false,
        message: e.message?.toString() ?? 'Invalid delivery type',
      );
    }

    if (endpoint.contains('{id}')) {
      endpoint = endpoint.replaceAll('{id}', numericId.toString());
    } else if (!endpoint.contains('/$numericId/send-otp')) {
      var base = endpoint.trim();
      if (base.endsWith('/')) {
        base = base.substring(0, base.length - 1);
      }
      if (base.endsWith('/send-otp')) {
        base = base.substring(0, base.length - '/send-otp'.length);
      }
      endpoint = '$base/$numericId/send-otp';
    }

    final effectiveRoleId = (storedRoleId ?? roleId ?? 1).toString();
    final url = Uri.parse(endpoint).replace(
      queryParameters: {
        'role_id': effectiveRoleId,
        'user_id': storedUserId.toString(),
      },
    );

    try {
      debugPrint('API Request: POST $url');
      final response = await _performAuthenticatedPost(url);
      debugPrint('API Response Status: ${response.statusCode}');
      debugPrint('API Response Body: ${response.body}');

      if (_looksLikeHtml(response.body)) {
        await _handleAuthFailure();
        return ApiResponse(
          success: false,
          message: 'Authentication error. Please log in again.',
        );
      }

      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        decoded = <String, dynamic>{};
      }

      final map = decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{'data': decoded};

      final success =
          response.statusCode == 200 ||
          response.statusCode == 201 ||
          map['success'] == true;

      return ApiResponse(
        success: success,
        message: (map['message']?.toString().trim().isNotEmpty ?? false)
            ? map['message'].toString()
            : (success ? 'OTP sent successfully' : 'Failed to send OTP'),
        data: map['data'],
        errors: map['errors'],
      );
    } on TimeoutException {
      return ApiResponse(
        success: false,
        message: 'Request timeout. Please try again.',
      );
    } on SocketException {
      return ApiResponse(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to send OTP: $e',
      );
    }
  }

  /// Send OTP for a field-executive service request start flow.
  /// POST /service-request/{id}/send-otp?user_id={userId}&role_id={roleId}
  static Future<ApiResponse> sendServiceRequestOtp(
    String serviceRequestId, {
    int? roleId,
  }) async {
    final authValidation = await _ensureServiceRequestOtpAuthState(
      flow: 'sendServiceRequestOtp',
      redirectOnFailure: false,
    );
    if (authValidation != null) {
      return authValidation;
    }

    final storedUserId = await SecureStorageService.getUserId(forceReload: true);
    final storedRoleId = await SecureStorageService.getRoleId(forceReload: true);
    final storedAccessToken = await SecureStorageService.getAccessToken(
      forceReload: true,
    );
    final missingFields = <String>[
      if (storedUserId == null) 'user_id',
      if (storedRoleId == null) 'role_id',
      if (storedAccessToken == null || storedAccessToken.trim().isEmpty)
        'access_token',
    ];
    if (missingFields.isNotEmpty) {
      final message = _buildMissingServiceRequestAuthMessage(missingFields);
      debugPrint('[ServiceRequestOtp][sendServiceRequestOtp] $message');
      return ApiResponse(
        success: false,
        message: message,
      );
    }
    if (roleId != null && roleId != storedRoleId) {
      debugPrint(
        '[ServiceRequestOtp][sendServiceRequestOtp] route role_id=$roleId does not match stored role_id=$storedRoleId. Using stored role_id.',
      );
    }

    final normalizedId = serviceRequestId
        .trim()
        .replaceFirst(RegExp(r'^#'), '');
    final numericId = int.tryParse(normalizedId);
    if (numericId == null) {
      return ApiResponse(
        success: false,
        message:
            'Invalid service request id "$serviceRequestId". Expected numeric id.',
      );
    }

    final effectiveRoleId = storedRoleId.toString();

    String baseEndpoint = ApiConstants.ServiceRequestsendotp
        .replaceFirst('{service-request_id}', numericId.toString())
        .replaceFirst('{service_request_id}', numericId.toString());
    if (baseEndpoint.contains('{service-request_id}') ||
        baseEndpoint.contains('{service_request_id}')) {
      baseEndpoint = '${ApiConstants.serviceRequestdetails}/$numericId/send-otp';
    }
    if (!baseEndpoint.endsWith('/send-otp')) {
      baseEndpoint = '$baseEndpoint/send-otp';
    }

    final url = Uri.parse(baseEndpoint).replace(
      queryParameters: {
        'user_id': storedUserId.toString(),
        'role_id': effectiveRoleId,
      },
    );

    try {
      debugPrint('API Request: POST $url');
      final response = await _performAuthenticatedPost(url);
      debugPrint('API Response Status: ${response.statusCode}');
      debugPrint('API Response Body: ${response.body}');

      if (_looksLikeHtml(response.body)) {
        await NavigationService.navigateToAuthRoot();
        return ApiResponse(
          success: false,
          message: 'Authentication error. Please log in again.',
        );
      }

      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        decoded = <String, dynamic>{};
      }

      final map = decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{'data': decoded};

      final bool success =
          response.statusCode == 200 ||
          response.statusCode == 201 ||
          map['success'] == true;

      return ApiResponse(
        success: success,
        message: (map['message']?.toString().trim().isNotEmpty ?? false)
            ? map['message'].toString()
            : (success ? 'OTP sent successfully' : 'Failed to send OTP'),
        data: map['data'],
        errors: map['errors'],
      );
    } on TimeoutException {
      return ApiResponse(
        success: false,
        message: 'Request timeout. Please try again.',
      );
    } on SocketException {
      return ApiResponse(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to send OTP: $e',
      );
    }
  }

  /// Verify OTP for a delivery request for part / pickup / return.
  /// POST /part-request/{id}/verify-otp?role_id={roleId}&user_id={userId}
  /// POST /pickup-request/{id}/verify-otp?role_id={roleId}&user_id={userId}
  /// POST /return-request/{id}/verify-otp?role_id={roleId}&user_id={userId}
  static Future<ApiResponse> verifyDeliveryRequestOtp({
    required String deliveryType,
    required String deliveryId,
    required String otp,
    int? roleId,
  }) async {
    final normalizedType = DeliveryRequestTypes.normalize(deliveryType);
    if (normalizedType == DeliveryRequestTypes.productDelivery) {
      final normalizedOtp = otp.trim();
      final isValidOtp = normalizedOtp == '1234';
      return ApiResponse(
        success: isValidOtp,
        message: isValidOtp
            ? 'Product delivery confirmed successfully'
            : 'Invalid OTP. Use 1234 for product delivery.',
      );
    }

    final storedUserId = await SecureStorageService.getUserId();
    final storedRoleId = await SecureStorageService.getRoleId();

    if (storedUserId == null) {
      debugPrint(
        'Missing userId in secure storage when calling verifyDeliveryRequestOtp',
      );
      await _handleAuthFailure();
      return ApiResponse(
        success: false,
        message: 'Authentication error. Please log in again.',
      );
    }

    final normalizedId = deliveryId.trim().replaceFirst(RegExp(r'^#'), '');
    final numericId = int.tryParse(normalizedId);
    if (numericId == null) {
      return ApiResponse(
        success: false,
        message: 'Invalid delivery id "$deliveryId". Expected numeric id.',
      );
    }

    final normalizedOtp = otp.trim();
    if (normalizedOtp.isEmpty) {
      return ApiResponse(
        success: false,
        message: 'OTP is required.',
      );
    }

    String endpoint;
    try {
      endpoint = DeliveryRequestTypes.verifyOtpEndpointTemplateFor(deliveryType)
          .replaceFirst('{id}', numericId.toString());
    } on ArgumentError catch (e) {
      return ApiResponse(
        success: false,
        message: e.message?.toString() ?? 'Invalid delivery type',
      );
    }

    if (endpoint.contains('{id}')) {
      endpoint = endpoint.replaceAll('{id}', numericId.toString());
    } else if (!endpoint.contains('/$numericId/verify-otp')) {
      var base = endpoint.trim();
      if (base.endsWith('/')) {
        base = base.substring(0, base.length - 1);
      }
      if (base.endsWith('/verify-otp')) {
        base = base.substring(0, base.length - '/verify-otp'.length);
      }
      endpoint = '$base/$numericId/verify-otp';
    }

    final effectiveRoleId = (storedRoleId ?? roleId ?? 1).toString();
    final url = Uri.parse(endpoint).replace(
      queryParameters: {
        'role_id': effectiveRoleId,
        'user_id': storedUserId.toString(),
      },
    );

    final body = <String, String>{
      'otp': normalizedOtp,
    };

    try {
      debugPrint('API Request: POST $url');
      debugPrint('API Request Body: $body');
      final response = await _performAuthenticatedPost(url, body: body);
      debugPrint('API Response Status: ${response.statusCode}');
      debugPrint('API Response Body: ${response.body}');

      if (_looksLikeHtml(response.body)) {
        await _handleAuthFailure();
        return ApiResponse(
          success: false,
          message: 'Authentication error. Please log in again.',
        );
      }

      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        decoded = <String, dynamic>{};
      }

      final map = decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{'data': decoded};

      final success =
          response.statusCode == 200 ||
          response.statusCode == 201 ||
          map['success'] == true;

      return ApiResponse(
        success: success,
        message: (map['message']?.toString().trim().isNotEmpty ?? false)
            ? map['message'].toString()
            : (success ? 'OTP verified successfully' : 'Invalid or expired OTP'),
        data: map['data'],
        errors: map['errors'],
      );
    } on TimeoutException {
      return ApiResponse(
        success: false,
        message: 'Request timeout. Please try again.',
      );
    } on SocketException {
      return ApiResponse(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to verify OTP: $e',
      );
    }
  }

  /// Verify OTP for a field-executive service request start flow.
  /// POST /service-request/{id}/verify-otp?otp={otp}&user_id={userId}&role_id={roleId}
  static Future<ApiResponse> verifyServiceRequestOtp(
    String serviceRequestId, {
    required String otp,
    int? roleId,
  }) async {
    final authValidation = await _ensureServiceRequestOtpAuthState(
      flow: 'verifyServiceRequestOtp',
      redirectOnFailure: false,
    );
    if (authValidation != null) {
      return authValidation;
    }

    final storedUserId = await SecureStorageService.getUserId(forceReload: true);
    final storedRoleId = await SecureStorageService.getRoleId(forceReload: true);
    final storedAccessToken = await SecureStorageService.getAccessToken(
      forceReload: true,
    );
    final missingFields = <String>[
      if (storedUserId == null) 'user_id',
      if (storedRoleId == null) 'role_id',
      if (storedAccessToken == null || storedAccessToken.trim().isEmpty)
        'access_token',
    ];
    if (missingFields.isNotEmpty) {
      final message = _buildMissingServiceRequestAuthMessage(missingFields);
      debugPrint('[ServiceRequestOtp][verifyServiceRequestOtp] $message');
      return ApiResponse(
        success: false,
        message: message,
      );
    }
    if (roleId != null && roleId != storedRoleId) {
      debugPrint(
        '[ServiceRequestOtp][verifyServiceRequestOtp] route role_id=$roleId does not match stored role_id=$storedRoleId. Using stored role_id.',
      );
    }

    final normalizedId = serviceRequestId.trim().replaceFirst(RegExp(r'^#'), '');
    final numericId = int.tryParse(normalizedId);
    if (numericId == null) {
      return ApiResponse(
        success: false,
        message:
            'Invalid service request id "$serviceRequestId". Expected numeric id.',
      );
    }

    final normalizedOtp = otp.trim();
    if (normalizedOtp.isEmpty) {
      return ApiResponse(
        success: false,
        message: 'OTP is required.',
      );
    }

    final effectiveRoleId = storedRoleId.toString();

    String baseEndpoint = ApiConstants.ServiceRequestverifyotp
        .replaceFirst('{service-request_id}', numericId.toString())
        .replaceFirst('{service_request_id}', numericId.toString());
    if (baseEndpoint.contains('{service-request_id}') ||
        baseEndpoint.contains('{service_request_id}')) {
      baseEndpoint = '${ApiConstants.serviceRequestdetails}/$numericId/verify-otp';
    }
    if (!baseEndpoint.endsWith('/verify-otp')) {
      baseEndpoint = '$baseEndpoint/verify-otp';
    }

    final url = Uri.parse(baseEndpoint).replace(
      queryParameters: {
        'otp': normalizedOtp,
        'user_id': storedUserId.toString(),
        'role_id': effectiveRoleId,
      },
    );
    final body = <String, String>{
      'otp': normalizedOtp,
      'user_id': storedUserId.toString(),
      'role_id': effectiveRoleId,
    };

    try {
      debugPrint('API Request: POST $url');
      debugPrint('API Request Body: $body');
      final response = await _performAuthenticatedPost(url, body: body);
      debugPrint('API Response Status: ${response.statusCode}');
      debugPrint('API Response Body: ${response.body}');

      if (_looksLikeHtml(response.body)) {
        await NavigationService.navigateToAuthRoot();
        return ApiResponse(
          success: false,
          message: 'Authentication error. Please log in again.',
        );
      }

      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        decoded = <String, dynamic>{};
      }

      final map = decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{'data': decoded};

      final bool success =
          response.statusCode == 200 ||
          response.statusCode == 201 ||
          map['success'] == true;

      return ApiResponse(
        success: success,
        message: (map['message']?.toString().trim().isNotEmpty ?? false)
            ? map['message'].toString()
            : (success ? 'OTP verified successfully' : 'Invalid OTP'),
        data: map['data'],
        errors: map['errors'],
      );
    } on TimeoutException {
      return ApiResponse(
        success: false,
        message: 'Request timeout. Please try again.',
      );
    } on SocketException {
      return ApiResponse(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to verify OTP: $e',
      );
    }
  }

  /// Raise case transfer request for a field-executive service request.
  /// POST /service-request/{id}/case-transfer?user_id={userId}&role_id={roleId}&engineer_reason={reason}
  static Future<ApiResponse> transferServiceRequestCase(
    String serviceRequestId, {
    required String engineerReason,
    int? roleId,
  }) async {
    final storedUserId = await SecureStorageService.getUserId();
    final storedRoleId = await SecureStorageService.getRoleId();

    if (storedUserId == null) {
      debugPrint(
        'Missing userId in secure storage when calling transferServiceRequestCase',
      );
      await _handleAuthFailure();
      return ApiResponse(
        success: false,
        message: 'Authentication error. Please log in again.',
      );
    }

    final normalizedId = serviceRequestId.trim().replaceFirst(RegExp(r'^#'), '');
    final numericId = int.tryParse(normalizedId);
    if (numericId == null) {
      return ApiResponse(
        success: false,
        message:
            'Invalid service request id "$serviceRequestId". Expected numeric id.',
      );
    }

    final normalizedReason = engineerReason.trim();
    if (normalizedReason.isEmpty) {
      return ApiResponse(
        success: false,
        message: 'Engineer reason is required.',
      );
    }

    final effectiveRoleId = (storedRoleId ?? roleId ?? 1).toString();

    String baseEndpoint = ApiConstants.ServiceRequestcasetransfer
        .replaceFirst('{service-request_id}', numericId.toString())
        .replaceFirst('{service_request_id}', numericId.toString());
    if (baseEndpoint.contains('{service-request_id}') ||
        baseEndpoint.contains('{service_request_id}')) {
      baseEndpoint = '${ApiConstants.serviceRequestdetails}/$numericId/case-transfer';
    }
    if (!baseEndpoint.endsWith('/case-transfer')) {
      baseEndpoint = '$baseEndpoint/case-transfer';
    }

    final url = Uri.parse(baseEndpoint).replace(
      queryParameters: {
        'user_id': storedUserId.toString(),
        'role_id': effectiveRoleId,
        'engineer_reason': normalizedReason,
      },
    );
    final body = <String, String>{
      'user_id': storedUserId.toString(),
      'role_id': effectiveRoleId,
      'engineer_reason': normalizedReason,
    };

    try {
      debugPrint('API Request: POST $url');
      debugPrint('API Request Body: $body');
      final response = await _performAuthenticatedPost(url, body: body);
      debugPrint('API Response Status: ${response.statusCode}');
      debugPrint('API Response Body: ${response.body}');

      if (_looksLikeHtml(response.body)) {
        await _handleAuthFailure();
        return ApiResponse(
          success: false,
          message: 'Authentication error. Please log in again.',
        );
      }

      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        decoded = <String, dynamic>{};
      }

      final map = decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{'data': decoded};

      final bool success =
          response.statusCode == 200 ||
          response.statusCode == 201 ||
          map['success'] == true;

      return ApiResponse(
        success: success,
        message: (map['message']?.toString().trim().isNotEmpty ?? false)
            ? map['message'].toString()
            : (success
                ? 'Case transfer request created successfully.'
                : 'Failed to create case transfer request'),
        data: map['data'],
        errors: map['errors'],
      );
    } on TimeoutException {
      return ApiResponse(
        success: false,
        message: 'Request timeout. Please try again.',
      );
    } on SocketException {
      return ApiResponse(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to create case transfer request: $e',
      );
    }
  }

  /// Reschedule a field-executive service request.
  /// POST /service-request/{id}/reschedule?user_id={userId}&role_id={roleId}&engineer_reason={reason}&reschedule_date={date}
  static Future<ApiResponse> rescheduleServiceRequest(
    String serviceRequestId, {
    required String engineerReason,
    required String rescheduleDate,
    int? roleId,
  }) async {
    final storedUserId = await SecureStorageService.getUserId();
    final storedRoleId = await SecureStorageService.getRoleId();

    if (storedUserId == null) {
      debugPrint(
        'Missing userId in secure storage when calling rescheduleServiceRequest',
      );
      await _handleAuthFailure();
      return ApiResponse(
        success: false,
        message: 'Authentication error. Please log in again.',
      );
    }

    final normalizedId = serviceRequestId.trim().replaceFirst(RegExp(r'^#'), '');
    final numericId = int.tryParse(normalizedId);
    if (numericId == null) {
      return ApiResponse(
        success: false,
        message:
            'Invalid service request id "$serviceRequestId". Expected numeric id.',
      );
    }

    final normalizedReason = engineerReason.trim();
    if (normalizedReason.isEmpty) {
      return ApiResponse(
        success: false,
        message: 'Engineer reason is required.',
      );
    }

    final normalizedDate = rescheduleDate.trim();
    if (normalizedDate.isEmpty) {
      return ApiResponse(
        success: false,
        message: 'Reschedule date is required.',
      );
    }

    final effectiveRoleId = (storedRoleId ?? roleId ?? 1).toString();

    String baseEndpoint = ApiConstants.ServiceRequestreschedule
        .replaceFirst('{service-request_id}', numericId.toString())
        .replaceFirst('{service_request_id}', numericId.toString());
    if (baseEndpoint.contains('{service-request_id}') ||
        baseEndpoint.contains('{service_request_id}')) {
      baseEndpoint = '${ApiConstants.serviceRequestdetails}/$numericId/reschedule';
    }
    if (!baseEndpoint.endsWith('/reschedule')) {
      baseEndpoint = '$baseEndpoint/reschedule';
    }

    final url = Uri.parse(baseEndpoint).replace(
      queryParameters: {
        'user_id': storedUserId.toString(),
        'role_id': effectiveRoleId,
        'engineer_reason': normalizedReason,
        'reschedule_date': normalizedDate,
      },
    );
    final body = <String, String>{
      'user_id': storedUserId.toString(),
      'role_id': effectiveRoleId,
      'engineer_reason': normalizedReason,
      'reschedule_date': normalizedDate,
    };

    try {
      debugPrint('API Request: POST $url');
      debugPrint('API Request Body: $body');
      final response = await _performAuthenticatedPost(url, body: body);
      debugPrint('API Response Status: ${response.statusCode}');
      debugPrint('API Response Body: ${response.body}');

      if (_looksLikeHtml(response.body)) {
        await _handleAuthFailure();
        return ApiResponse(
          success: false,
          message: 'Authentication error. Please log in again.',
        );
      }

      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        decoded = <String, dynamic>{};
      }

      final map = decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{'data': decoded};

      final bool success =
          response.statusCode == 200 ||
          response.statusCode == 201 ||
          map['success'] == true;

      return ApiResponse(
        success: success,
        message: (map['message']?.toString().trim().isNotEmpty ?? false)
            ? map['message'].toString()
            : (success
                ? 'Service request rescheduled successfully.'
                : 'Failed to reschedule request'),
        data: map['data'],
        errors: map['errors'],
      );
    } on TimeoutException {
      return ApiResponse(
        success: false,
        message: 'Request timeout. Please try again.',
      );
    } on SocketException {
      return ApiResponse(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to reschedule request: $e',
      );
    }
  }

  /// Fetch a single service request detail for field executive.
  ///
  /// Uses numeric database id:
  /// GET /service-request/{id}
  /// (with and without auth query params for backend compatibility).
  /// If detail endpoint fails, falls back to list endpoint lookup by id.
  static Future<Map<String, dynamic>> fetchServiceRequestDetail(
    String serviceId, {
    int roleId = 1,
  }) async {
    final storedUserId = await SecureStorageService.getUserId();
    final storedRoleId = await SecureStorageService.getRoleId();

    if (storedUserId == null) {
      debugPrint(
        'Missing userId in secure storage when calling fetchServiceRequestDetail',
      );
      await _handleAuthFailure();
      throw Exception('Authentication error. Please log in again.');
    }

    final effectiveRoleId = (storedRoleId ?? roleId).toString();
    final rawId = serviceId.trim().replaceFirst(RegExp(r'^#'), '');
    final numericId = int.tryParse(rawId);

    if (numericId == null) {
      throw Exception(
        'Invalid service request id "$serviceId". Expected numeric database id.',
      );
    }

    bool matchesNumericId(Map<String, dynamic> item) {
      int? parseInt(dynamic value) {
        if (value == null) return null;
        if (value is int) return value;
        if (value is num) return value.toInt();
        return int.tryParse(value.toString().trim());
      }

      final candidates = <dynamic>[item['id'], item['service_request_id']];
      for (final candidate in candidates) {
        final parsed = parseInt(candidate);
        if (parsed != null && parsed == numericId) return true;
      }
      return false;
    }

    Map<String, dynamic> normalizeDetailMap(Map<String, dynamic> source) {
      final model = FieldExecutiveServiceRequestDetail.fromJson(source);
      return model.toJson();
    }

    Map<String, dynamic>? parseSingle(dynamic decoded) {
      List<dynamic> listCandidate = const [];

      if (decoded is Map<String, dynamic>) {
        if (decoded['data'] is Map<String, dynamic>) {
          return normalizeDetailMap(
            Map<String, dynamic>.from(decoded['data'] as Map),
          );
        }
        if (decoded['serviceRequest'] is Map<String, dynamic>) {
          return normalizeDetailMap(
            Map<String, dynamic>.from(decoded['serviceRequest'] as Map),
          );
        }
        if (decoded['service_request'] is Map<String, dynamic>) {
          return normalizeDetailMap(
            Map<String, dynamic>.from(decoded['service_request'] as Map),
          );
        }
        if (decoded['request'] is Map<String, dynamic>) {
          return normalizeDetailMap(
            Map<String, dynamic>.from(decoded['request'] as Map),
          );
        }
        if (decoded['serviceRequest'] is List) {
          listCandidate = decoded['serviceRequest'] as List;
        } else if (decoded['service_requests'] is List) {
          listCandidate = decoded['service_requests'] as List;
        } else if (decoded['data'] is List) {
          listCandidate = decoded['data'] as List;
        }
      } else if (decoded is List) {
        listCandidate = decoded;
      }

      if (listCandidate.isEmpty) return null;

      final mapped = listCandidate
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      for (final item in mapped) {
        if (matchesNumericId(item)) {
          return normalizeDetailMap(item);
        }
      }

      if (mapped.isNotEmpty) {
        return normalizeDetailMap(mapped.first);
      }

      return null;
    }

    Future<Map<String, dynamic>?> tryFetch(Uri url) async {
      debugPrint('API Request: GET $url');
      final response = await _performAuthenticatedGet(url);
      debugPrint('API Response Status: ${response.statusCode}');
      debugPrint('API Response Body: ${response.body}');

      if (_looksLikeHtml(response.body)) {
        await _handleAuthFailure();
        throw Exception('Authentication error. Please log in again.');
      }

      if (response.statusCode != 200) {
        return null;
      }

      final dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        return null;
      }

      final parsed = parseSingle(decoded);
      if (parsed != null) {
        debugPrint(
          'Service detail customer_address_id=${parsed['customer_address_id']} '
          'customer_address=${parsed['customer_address']}',
        );
      }
      return parsed;
    }

    try {
      final base = <String, String>{
        'user_id': storedUserId.toString(),
        'role_id': effectiveRoleId,
      };

      String detailEndpoint = ApiConstants.serviceRequestdetails
          .replaceFirst('{service-request_id}', numericId.toString())
          .replaceFirst('{service_request_id}', numericId.toString());
      if (detailEndpoint.contains('{service-request_id}') ||
          detailEndpoint.contains('{service_request_id}')) {
        detailEndpoint = '${ApiConstants.baseUrl}/service-request/$numericId';
      }

      final attempts = <Uri>[
        Uri.parse(detailEndpoint).replace(
          queryParameters: base,
        ),
        Uri.parse(detailEndpoint),
      ];

      for (final uri in attempts) {
        final found = await tryFetch(uri);
        if (found != null) {
          return found;
        }
      }

      // Fallback to list endpoint in case detail endpoint is unavailable.
      final list = await fetchServiceRequests(roleId: roleId);
      for (final item in list) {
        if (matchesNumericId(item)) {
          return normalizeDetailMap(item);
        }
      }

      throw Exception('Service request details not found for $serviceId');
    } on TimeoutException catch (e) {
      debugPrint('Timeout: $e');
      throw Exception('Request timeout. Please try again.');
    } on SocketException catch (e) {
      debugPrint('No Internet: $e');
      throw Exception('No internet connection. Please check your network.');
    } catch (e) {
      debugPrint('Error fetching service request detail: $e');
      rethrow;
    }
  }

  /// Fetch diagnosis list for a product under a service request.
  ///
  /// GET /service-request/{service-request_id}/{product_id}/diagnosis-list
  static Future<List<DiagnosisItem>> fetchServiceRequestDiagnosisList({
    required String serviceRequestId,
    required String productId,
    int? roleId,
  }) async {
    final storedUserId = await SecureStorageService.getUserId();
    final storedRoleId = await SecureStorageService.getRoleId();

    if (storedUserId == null) {
      debugPrint(
        'Missing userId in secure storage when calling fetchServiceRequestDiagnosisList',
      );
      await _handleAuthFailure();
      throw Exception('Authentication error. Please log in again.');
    }

    final normalizedServiceRequestId = serviceRequestId
        .trim()
        .replaceFirst(RegExp(r'^#'), '');
    final normalizedProductId = productId.trim().replaceFirst(RegExp(r'^#'), '');

    if (int.tryParse(normalizedServiceRequestId) == null) {
      throw Exception(
        'Invalid service request id "$serviceRequestId". Expected numeric id.',
      );
    }
    if (int.tryParse(normalizedProductId) == null) {
      throw Exception('Invalid product id "$productId". Expected numeric id.');
    }

    final effectiveRoleId = (storedRoleId ?? roleId ?? 1).toString();

    String endpoint = ApiConstants.ServiceRequestdiagnosis
        .replaceFirst('{service-request_id}', normalizedServiceRequestId)
        .replaceFirst('{service_request_id}', normalizedServiceRequestId)
        .replaceFirst('{product_id}', normalizedProductId)
        .replaceFirst('{product-id}', normalizedProductId);
    if (endpoint.contains('{service-request_id}') ||
        endpoint.contains('{service_request_id}') ||
        endpoint.contains('{product_id}') ||
        endpoint.contains('{product-id}')) {
      endpoint =
          '${ApiConstants.baseUrl}/service-request/$normalizedServiceRequestId/$normalizedProductId/diagnosis-list';
    }

    final url = Uri.parse(endpoint).replace(
      queryParameters: {
        'role_id': effectiveRoleId,
        'user_id': storedUserId.toString(),
      },
    );

    try {
      debugPrint('API Request: GET $url');
      final response = await _performAuthenticatedGet(url);
      debugPrint('API Response Status: ${response.statusCode}');
      debugPrint('API Response Body: ${response.body}');

      if (_looksLikeHtml(response.body)) {
        await _handleAuthFailure();
        throw Exception('Authentication error. Please log in again.');
      }

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to load diagnosis list: ${response.statusCode}',
        );
      }

      final dynamic decoded = jsonDecode(response.body);

      List<dynamic> rawList = const <dynamic>[];

      if (decoded is Map<String, dynamic>) {
        dynamic source =
            decoded['diagnosis'] ??
            decoded['diagnosisList'] ??
            decoded['diagnosis_list'];

        if (source == null) {
          final data = decoded['data'];
          if (data is List) {
            source = data;
          } else if (data is Map<String, dynamic>) {
            source =
                data['diagnosis'] ??
                data['diagnosisList'] ??
                data['diagnosis_list'];
          }
        }

        if (source is List) {
          rawList = source;
        } else if (source != null) {
          rawList = <dynamic>[source];
        }
      } else if (decoded is List) {
        rawList = decoded;
      }

      String normalizeComparableId(dynamic value) {
        if (value == null) return '';
        final text = value.toString().trim();
        if (text.isEmpty || text.toLowerCase() == 'null') return '';
        return text.replaceFirst(RegExp(r'^#'), '');
      }

      const serviceRequestIdKeys = <String>[
        'service_request_id',
        'serviceRequestId',
        'service_requests_id',
        'serviceRequestsId',
        'request_id',
        'requestId',
      ];
      const productIdKeys = <String>[
        'product_id',
        'productId',
        'item_code_id',
        'itemCodeId',
        'service_product_id',
        'serviceProductId',
      ];

      String readIdFromMap(Map<String, dynamic> source, List<String> keys) {
        for (final key in keys) {
          if (!source.containsKey(key)) continue;
          final value = normalizeComparableId(source[key]);
          if (value.isNotEmpty) return value;
        }
        return '';
      }

      bool containsAnyScopeKey(Map<String, dynamic> source, List<String> keys) {
        for (final key in keys) {
          if (source.containsKey(key)) return true;
        }
        return false;
      }

      final scopedRawList = <dynamic>[];
      var scopedItemsInResponse = 0;
      var scopedMatches = 0;

      for (final item in rawList) {
        if (item is! Map) {
          scopedRawList.add(item);
          continue;
        }

        final itemMap = Map<String, dynamic>.from(item as Map);
        final hasServiceScope = containsAnyScopeKey(itemMap, serviceRequestIdKeys);
        final hasProductScope = containsAnyScopeKey(itemMap, productIdKeys);

        if (!hasServiceScope && !hasProductScope) {
          scopedRawList.add(itemMap);
          continue;
        }

        scopedItemsInResponse++;

        final itemServiceRequestId = readIdFromMap(itemMap, serviceRequestIdKeys);
        final itemProductId = readIdFromMap(itemMap, productIdKeys);

        final serviceMatches = !hasServiceScope ||
            itemServiceRequestId.isEmpty ||
            itemServiceRequestId == normalizedServiceRequestId;
        final productMatches = !hasProductScope ||
            itemProductId.isEmpty ||
            itemProductId == normalizedProductId;

        if (serviceMatches && productMatches) {
          scopedMatches++;
          scopedRawList.add(itemMap);
        }
      }

      if (scopedItemsInResponse > 0 &&
          scopedMatches == 0 &&
          rawList.isNotEmpty) {
        throw Exception(
          'Diagnosis list does not belong to this selected service request/product.',
        );
      }

      bool hasDiagnosisNameKey(Map<String, dynamic> source) {
        for (final key in const [
          'name',
          'diagnosis_name',
          'diagnosisName',
          'diagnosis',
          'title',
          'label',
        ]) {
          if (source.containsKey(key)) return true;
        }
        return false;
      }

      List<dynamic> normalizeToList(dynamic source) {
        if (source == null) return const <dynamic>[];
        if (source is List) return source;
        return <dynamic>[source];
      }

      Iterable<dynamic> extractDiagnosisNodes(dynamic raw) sync* {
        if (raw == null) return;

        if (raw is List) {
          for (final entry in raw) {
            yield* extractDiagnosisNodes(entry);
          }
          return;
        }

        if (raw is Map) {
          final map = Map<String, dynamic>.from(raw as Map);
          final hasNameKey = hasDiagnosisNameKey(map);

          final nestedDiagnosisList =
              map['diagnosis_list'] ?? map['diagnosisList'];
          if (!hasNameKey && nestedDiagnosisList != null) {
            for (final nested in normalizeToList(nestedDiagnosisList)) {
              yield* extractDiagnosisNodes(nested);
            }
            return;
          }

          final nestedDiagnosis = map['diagnosis'];
          if (!hasNameKey && (nestedDiagnosis is List || nestedDiagnosis is Map)) {
            for (final nested in normalizeToList(nestedDiagnosis)) {
              yield* extractDiagnosisNodes(nested);
            }
            return;
          }

          yield map;
          return;
        }

        yield raw;
      }

      DiagnosisItem? parseDiagnosisItem(dynamic raw) {
        if (raw == null) return null;

        if (raw is Map) {
          final item = DiagnosisItem.fromJson(Map<String, dynamic>.from(raw as Map));
          if (item.name.trim().isEmpty) return null;
          return item;
        }

        final text = raw.toString().trim();
        if (text.isEmpty || text.toLowerCase() == 'null') {
          return null;
        }
        return DiagnosisItem(name: text);
      }

      final parsedItems = <DiagnosisItem>[];
      for (final raw in scopedRawList) {
        for (final node in extractDiagnosisNodes(raw)) {
          final parsed = parseDiagnosisItem(node);
          if (parsed != null) {
            parsedItems.add(parsed);
          }
        }
      }

      final uniqueByName = <String, DiagnosisItem>{};
      for (final item in parsedItems) {
        final key = item.name.trim();
        if (key.isEmpty) continue;

        if (!uniqueByName.containsKey(key)) {
          uniqueByName[key] = item;
          continue;
        }

        final existing = uniqueByName[key]!;
        uniqueByName[key] = DiagnosisItem(
          name: existing.name,
          statusLabel: existing.statusLabel.isNotEmpty
              ? existing.statusLabel
              : item.statusLabel,
          partStatus: existing.partStatus.isNotEmpty
              ? existing.partStatus
              : item.partStatus,
          partId: existing.partId.isNotEmpty ? existing.partId : item.partId,
          quantity: existing.quantity.isNotEmpty
              ? existing.quantity
              : item.quantity,
          productIdFromApi: existing.productIdFromApi.isNotEmpty
              ? existing.productIdFromApi
              : item.productIdFromApi,
          quantityFromApi: existing.quantityFromApi.isNotEmpty
              ? existing.quantityFromApi
              : item.quantityFromApi,
          report: (existing.report?.trim().isNotEmpty ?? false)
              ? existing.report
              : item.report,
        );
      }

      return uniqueByName.values.toList();
    } on TimeoutException catch (e) {
      debugPrint('Timeout: $e');
      throw Exception('Request timeout. Please try again.');
    } on SocketException catch (e) {
      debugPrint('No Internet: $e');
      throw Exception('No internet connection. Please check your network.');
    } catch (e) {
      debugPrint('Error fetching diagnosis list: $e');
      rethrow;
    }
  }

  /// Submit diagnosis report for a product under a service request.
  ///
  /// POST /service-request/{service-request_id}/{product_id}/submit-diagnosis
  /// multipart/form-data
  static Future<ApiResponse> submitServiceRequestDiagnosis({
    required String serviceRequestId,
    required String productId,
    required int roleId,
    required List<Map<String, dynamic>> diagnosisList,
    String defaultReport = '',
    File? beforePhoto,
    File? afterPhoto,
  }) async {
    final storedUserId = await SecureStorageService.getUserId();
    final storedRoleId = await SecureStorageService.getRoleId();

    if (storedUserId == null) {
      debugPrint(
        'Missing userId in secure storage when calling submitServiceRequestDiagnosis',
      );
      await _handleAuthFailure();
      return ApiResponse(
        success: false,
        message: 'Authentication error. Please log in again.',
      );
    }

    final normalizedServiceRequestId = serviceRequestId
        .trim()
        .replaceFirst(RegExp(r'^#'), '');
    final normalizedProductId = productId.trim().replaceFirst(RegExp(r'^#'), '');

    if (int.tryParse(normalizedServiceRequestId) == null) {
      return ApiResponse(
        success: false,
        message:
            'Invalid service request id "$serviceRequestId". Expected numeric id.',
      );
    }
    if (int.tryParse(normalizedProductId) == null) {
      return ApiResponse(
        success: false,
        message: 'Invalid product id "$productId". Expected numeric id.',
      );
    }

    final effectiveRoleId = (storedRoleId ?? roleId).toString();

    String endpoint = ApiConstants.ServiceRequestsubmitdiagnosis
        .replaceFirst('{service-request_id}', normalizedServiceRequestId)
        .replaceFirst('{service_request_id}', normalizedServiceRequestId)
        .replaceFirst('{product_id}', normalizedProductId)
        .replaceFirst('{product-id}', normalizedProductId);
    if (endpoint.contains('{service-request_id}') ||
        endpoint.contains('{service_request_id}') ||
        endpoint.contains('{product_id}') ||
        endpoint.contains('{product-id}')) {
      endpoint =
          '${ApiConstants.baseUrl}/service-request/$normalizedServiceRequestId/$normalizedProductId/submit-diagnosis';
    }

    final uri = Uri.parse(endpoint);

    Future<http.Response> sendOnce() async {
      final accessToken = await SecureStorageService.getAccessToken();
      final request = http.MultipartRequest('POST', uri)
        ..headers.addAll({
          'Accept': 'application/json',
          if (accessToken != null && accessToken.isNotEmpty)
            'Authorization': 'Bearer $accessToken',
        })
        ..fields['user_id'] = storedUserId.toString()
        ..fields['role_id'] = effectiveRoleId;

      const photoAngles = <String>[
        'top',
        'bottom',
        'left',
        'right',
        'screen',
        'keyboard',
      ];

      if (beforePhoto != null) {
        for (final angle in photoAngles) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'before_photos[$angle]',
              beforePhoto.path,
            ),
          );
        }
      }
      if (afterPhoto != null) {
        for (final angle in photoAngles) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'after_photos[$angle]',
              afterPhoto.path,
            ),
          );
        }
      }

      for (var index = 0; index < diagnosisList.length; index++) {
        final item = diagnosisList[index];
        final name = (item['name'] ?? '').toString().trim();
        final status = (item['status'] ?? '').toString().trim();
        final partStatus = (item['part_status'] ?? '').toString().trim();
        final report = (item['report'] ?? '').toString().trim();
        final partIdRaw = item['part_id'];
        final quantityRaw = item['quantity'];
        final reportToSend = report.isNotEmpty ? report : defaultReport.trim();

        if (name.isNotEmpty) {
          request.fields['diagnosis_list[$index][name]'] = name;
        }
        if (status.isNotEmpty) {
          request.fields['diagnosis_list[$index][status]'] = status;
        }
        if (partStatus.isNotEmpty) {
          request.fields['diagnosis_list[$index][part_status]'] = partStatus;
        }
        if (reportToSend.isNotEmpty) {
          request.fields['diagnosis_list[$index][report]'] = reportToSend;
        }

        final int? normalizedPartId = int.tryParse(
          (partIdRaw ?? '').toString().trim(),
        );
        final int? normalizedQuantity = int.tryParse(
          (quantityRaw ?? '').toString().trim(),
        );

        if (normalizedPartId != null) {
          request.fields['diagnosis_list[$index][part_id]'] =
              normalizedPartId.toString();
        }
        if (normalizedQuantity != null && normalizedQuantity > 0) {
          request.fields['diagnosis_list[$index][quantity]'] =
              normalizedQuantity.toString();
        }
        if (status == 'stock_in_hand' &&
            (normalizedPartId == null ||
                normalizedQuantity == null ||
                normalizedQuantity <= 0)) {
          debugPrint(
            'Skipping invalid stock_in_hand part payload at index=$index '
            '(part_id=$partIdRaw, quantity=$quantityRaw)',
          );
        }

        final images = item['images'];
        if (images is List) {
          for (final image in images.whereType<File>()) {
            if (await image.exists()) {
              request.files.add(
                await http.MultipartFile.fromPath(
                  'diagnosis_list[$index][images][]',
                  image.path,
                ),
              );
            }
          }
        } else if (images is File && await images.exists()) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'diagnosis_list[$index][images][]',
              images.path,
            ),
          );
        }
      }

      debugPrint(
        'Sending multipart request to $uri with fields: ${request.fields} and ${request.files.length} files',
      );

      final streamed = await request.send().timeout(ApiConstants.requestTimeout);
      return http.Response.fromStream(streamed);
    }

    try {
      debugPrint('API Request: POST $uri');
      debugPrint(
        'API Request Fields: user_id=$storedUserId, role_id=$effectiveRoleId, '
        'diagnosis_items=${diagnosisList.length}',
      );

      var response = await sendOnce();

      if (_isUnauthorizedResponse(response)) {
        final refreshed = await _attemptTokenRefresh();
        if (!refreshed) {
          await _handleAuthFailure();
          return ApiResponse(
            success: false,
            message: 'Authentication error. Please log in again.',
          );
        }
        response = await sendOnce();
      }

      debugPrint('API Response Status: ${response.statusCode}');
      debugPrint('API Response Body: ${response.body}');

      if (_isUnauthorizedResponse(response) || _looksLikeHtml(response.body)) {
        await _handleAuthFailure();
        return ApiResponse(
          success: false,
          message: 'Authentication error. Please log in again.',
        );
      }

      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        decoded = <String, dynamic>{};
      }

      final map = decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{'data': decoded};
      final success =
          response.statusCode == 200 ||
          response.statusCode == 201 ||
          map['success'] == true;

      return ApiResponse(
        success: success,
        message: (map['message']?.toString().trim().isNotEmpty ?? false)
            ? map['message'].toString()
            : (success
                ? 'Diagnosis submitted successfully'
                : 'Failed to submit diagnosis'),
        data: map['data'],
        errors: map['errors'],
      );
    } on TimeoutException {
      return ApiResponse(
        success: false,
        message: 'Request timeout. Please try again.',
      );
    } on SocketException {
      return ApiResponse(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to submit diagnosis: $e',
      );
    }
  }

  /// Create a lead.
  /// POST /lead
  static Future<ApiResponse<Map<String, dynamic>>> createLead(
    Map<String, dynamic> body, {
    int? roleId,
  }) async {
    final storedUserId = await SecureStorageService.getUserId();
    final storedRoleId = await SecureStorageService.getRoleId();
    final effectiveRoleId = storedRoleId ?? roleId;

    if (storedUserId == null || effectiveRoleId == null) {
      await _handleAuthFailure();
      return ApiResponse(
        success: false,
        message: 'Authentication error. Please log in again.',
      );
    }

    final payload = <String, dynamic>{...body, 'user_id': storedUserId};
    final url = Uri.parse(ApiConstants.new_lead);

    try {
      debugPrint('CREATE LEAD API Request: POST $url');
      debugPrint('CREATE LEAD Request Body: ${jsonEncode(payload)}');

      final response = await _performAuthenticatedPost(
        url,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      debugPrint('CREATE LEAD API Response Status: ${response.statusCode}');
      debugPrint('CREATE LEAD API Response Body: ${response.body}');

      final jsonResponse = ApiService.instance._safeJsonDecode(response.body);
      final bool isHtml = jsonResponse['isHtml'] == true;
      final message =
          jsonResponse['message'] ??
          _extractFirstErrorMessage(jsonResponse['errors']) ??
          (isHtml
              ? 'Authentication error. Please log in again.'
              : response.statusCode == 200 || response.statusCode == 201
              ? 'Lead submitted'
              : 'Failed to submit lead');

      if (isHtml) {
        await _handleAuthFailure();
        return ApiResponse(success: false, message: message);
      }

      final success =
          response.statusCode == 200 ||
          response.statusCode == 201 ||
          jsonResponse['success'] == true;

      return ApiResponse(
        success: success,
        message: message,
        data: jsonResponse['data'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(jsonResponse['data'] as Map)
            : jsonResponse,
        errors: jsonResponse['errors'],
      );
    } on TimeoutException {
      return ApiResponse(
        success: false,
        message: 'Request timeout. Please try again.',
      );
    } on SocketException {
      return ApiResponse(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } catch (e) {
      debugPrint('CREATE LEAD Error: $e');
      return ApiResponse(success: false, message: 'Failed to submit lead: $e');
    }
  }

  /// Update a lead.
  /// PUT /lead/{lead_id}?user_id={userId}
  static Future<ApiResponse<Map<String, dynamic>>> updateLead(
    String leadId,
    Map<String, dynamic> body, {
    int? roleId,
  }) async {
    final storedUserId = await SecureStorageService.getUserId();
    final storedRoleId = await SecureStorageService.getRoleId();
    final effectiveRoleId = storedRoleId ?? roleId;

    if (storedUserId == null || effectiveRoleId == null) {
      await _handleAuthFailure();
      return ApiResponse(
        success: false,
        message: 'Authentication error. Please log in again.',
      );
    }

    final payload = <String, dynamic>{...body, 'user_id': storedUserId};
    final endpoint = ApiConstants.edit_lead.replaceFirst('{lead_id}', leadId);
    final url = Uri.parse(endpoint).replace(
      queryParameters: {'user_id': storedUserId.toString()},
    );

    try {
      debugPrint('UPDATE LEAD API Request: PUT $url');
      debugPrint('UPDATE LEAD Request Body: ${jsonEncode(payload)}');

      final response = await _performAuthenticatedPut(
        url,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      debugPrint('UPDATE LEAD API Response Status: ${response.statusCode}');
      debugPrint('UPDATE LEAD API Response Body: ${response.body}');

      final jsonResponse = ApiService.instance._safeJsonDecode(response.body);
      final bool isHtml = jsonResponse['isHtml'] == true;
      final message =
          jsonResponse['message'] ??
          _extractFirstErrorMessage(jsonResponse['errors']) ??
          (isHtml
              ? 'Authentication error. Please log in again.'
              : response.statusCode == 200 || response.statusCode == 201
              ? 'Lead updated successfully'
              : 'Failed to update lead');

      if (isHtml) {
        await _handleAuthFailure();
        return ApiResponse(success: false, message: message);
      }

      final success =
          response.statusCode == 200 ||
          response.statusCode == 201 ||
          jsonResponse['success'] == true;

      return ApiResponse(
        success: success,
        message: message,
        data: jsonResponse['data'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(jsonResponse['data'] as Map)
            : jsonResponse,
        errors: jsonResponse['errors'],
      );
    } on TimeoutException {
      return ApiResponse(
        success: false,
        message: 'Request timeout. Please try again.',
      );
    } on SocketException {
      return ApiResponse(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } catch (e) {
      debugPrint('UPDATE LEAD Error: $e');
      return ApiResponse(success: false, message: 'Failed to update lead: $e');
    }
  }

  /// Fetch leads list
  /// GET /leads?user_id={userId}&role_id={roleId}&page={page}
  static Future<Map<String, dynamic>> fetchLeads(
    String userId,
    int roleId, {
    int page = 1,
  }) async {
    final storedUserId = await SecureStorageService.getUserId();
    final storedRoleId = await SecureStorageService.getRoleId();

    final effectiveUserId = storedUserId?.toString() ?? userId;
    final effectiveRoleId = (storedRoleId ?? roleId).toString();

    final url = Uri.parse(ApiConstants.lead_page).replace(
      queryParameters: {
        'user_id': effectiveUserId,
        'role_id': effectiveRoleId,
        'page': page.toString(),
      },
    );

    try {
      debugPrint('🔵 API Request: GET $url');

      final response = await _performAuthenticatedGet(url);

      debugPrint('🟡 API Response Status: ${response.statusCode}');
      debugPrint('🟡 API Response Body: ${response.body}');

      if (_looksLikeHtml(response.body)) {
        debugPrint(
          '🔴 HTML response detected for $url. Treating as authentication failure.',
        );
        await _handleAuthFailure();
        throw Exception('Authentication error. Please log in again.');
      }

      if (response.statusCode == 200) {
        dynamic decoded;
        try {
          decoded = jsonDecode(response.body);
        } catch (_) {
          decoded = {
            'message': 'Server returned non-JSON',
            'raw': response.body,
          };
        }

        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        if (decoded is List) {
          return {'data': decoded};
        }
        return {'data': decoded};
      } else {
        throw Exception('Failed to load leads: ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      debugPrint('🔴 Timeout: $e');
      throw Exception('Request timeout. Please try again.');
    } on SocketException catch (e) {
      debugPrint('🔴 No Internet: $e');
      throw Exception('No internet connection. Please check your network.');
    } catch (e) {
      debugPrint('🔴 Error fetching leads: $e');
      throw Exception('Failed to load leads: $e');
    }
  }

  /// Fetch single lead details
  /// GET /lead/{lead_id}?user_id={userId}&role_id={roleId}
  static Future<Map<String, dynamic>> fetchLeadDetail(
    String leadId, {
    int? roleId,
  }) async {
    final storedUserId = await SecureStorageService.getUserId();
    final storedRoleId = await SecureStorageService.getRoleId();
    final effectiveRoleId = (storedRoleId ?? roleId)?.toString();

    final endpoint = ApiConstants.view_detail_lead.replaceFirst(
      '{lead_id}',
      leadId,
    );

    final url = Uri.parse(endpoint).replace(
      queryParameters: {
        if (storedUserId != null) 'user_id': storedUserId.toString(),
        if (effectiveRoleId != null && effectiveRoleId.isNotEmpty)
          'role_id': effectiveRoleId,
      },
    );

    try {
      debugPrint('ðŸ”µ API Request: GET $url');

      final response = await _performAuthenticatedGet(url);

      debugPrint('ðŸŸ¡ API Response Status: ${response.statusCode}');
      debugPrint('ðŸŸ¡ API Response Body: ${response.body}');

      if (_looksLikeHtml(response.body)) {
        debugPrint(
          'ðŸ”´ HTML response detected for $url. Treating as authentication failure.',
        );
        await _handleAuthFailure();
        throw Exception('Authentication error. Please log in again.');
      }

      if (response.statusCode == 200) {
        dynamic decoded;
        try {
          decoded = jsonDecode(response.body);
        } catch (_) {
          decoded = {
            'message': 'Server returned non-JSON',
            'raw': response.body,
          };
        }

        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        if (decoded is List && decoded.isNotEmpty) {
          return {'data': decoded.first};
        }
        return {'data': decoded};
      }

      throw Exception('Failed to load lead details: ${response.statusCode}');
    } on TimeoutException catch (e) {
      debugPrint('ðŸ”´ Timeout: $e');
      throw Exception('Request timeout. Please try again.');
    } on SocketException catch (e) {
      debugPrint('ðŸ”´ No Internet: $e');
      throw Exception('No internet connection. Please check your network.');
    } catch (e) {
      debugPrint('ðŸ”´ Error fetching lead details: $e');
      throw Exception('Failed to load lead details: $e');
    }
  }

  /// Delete a lead
  /// DELETE /lead/{lead_id}?user_id={userId}&role_id={roleId}
  static Future<Map<String, dynamic>> deleteLead(
    String leadId, {
    int? roleId,
  }) async {
    final storedUserId = await SecureStorageService.getUserId();
    final storedRoleId = await SecureStorageService.getRoleId();
    final effectiveRoleId = (storedRoleId ?? roleId)?.toString();

    if (storedUserId == null) {
      await _handleAuthFailure();
      throw Exception('Authentication error. Please log in again.');
    }

    final endpoint = ApiConstants.delete_lead.replaceFirst('{lead_id}', leadId);
    final url = Uri.parse(endpoint).replace(
      queryParameters: {
        'user_id': storedUserId.toString(),
        if (effectiveRoleId != null && effectiveRoleId.isNotEmpty)
          'role_id': effectiveRoleId,
      },
    );

    try {
      debugPrint('DELETE API Request: $url');

      final response = await _performAuthenticatedDelete(url);

      debugPrint('DELETE API Response Status: ${response.statusCode}');
      debugPrint('DELETE API Response Body: ${response.body}');

      if (_looksLikeHtml(response.body)) {
        debugPrint(
          'HTML response detected for $url. Treating as authentication failure.',
        );
        await _handleAuthFailure();
        throw Exception('Authentication error. Please log in again.');
      }

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204) {
        if (response.body.trim().isEmpty) {
          return {'success': true, 'message': 'Lead deleted successfully'};
        }

        dynamic decoded;
        try {
          decoded = jsonDecode(response.body);
        } catch (_) {
          return {
            'success': true,
            'message': 'Lead deleted successfully',
            'raw': response.body,
          };
        }

        if (decoded is Map<String, dynamic>) {
          if (decoded['success'] == false) {
            throw Exception(
              (decoded['message'] ?? 'Failed to delete lead').toString(),
            );
          }
          return decoded;
        }

        return {'success': true, 'data': decoded};
      }

      String message = 'Failed to delete lead: ${response.statusCode}';
      if (response.body.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) {
            final dynamic apiMessage = decoded['message'] ?? decoded['error'];
            if (apiMessage != null && apiMessage.toString().trim().isNotEmpty) {
              message = apiMessage.toString().trim();
            }
          }
        } catch (_) {}
      }
      throw Exception(message);
    } on TimeoutException catch (e) {
      debugPrint('Timeout deleting lead: $e');
      throw Exception('Request timeout. Please try again.');
    } on SocketException catch (e) {
      debugPrint('No Internet while deleting lead: $e');
      throw Exception('No internet connection. Please check your network.');
    } catch (e) {
      debugPrint('Error deleting lead: $e');
      rethrow;
    }
  }

  /// Delete a follow-up
  /// DELETE /follow-up/{follow_up_id}?user_id={userId}
  static Future<Map<String, dynamic>> deleteFollowUp(String followUpId) async {
    final storedUserId = await SecureStorageService.getUserId();

    if (storedUserId == null) {
      await _handleAuthFailure();
      throw Exception('Authentication error. Please log in again.');
    }

    final endpoint = ApiConstants.delete_follow_up.replaceFirst(
      '{follow_up_id}',
      followUpId,
    );
    final url = Uri.parse(endpoint).replace(
      queryParameters: {'user_id': storedUserId.toString()},
    );

    try {
      debugPrint('DELETE Follow-up API Request: $url');

      final response = await _performAuthenticatedDelete(url);

      debugPrint('DELETE Follow-up API Response Status: ${response.statusCode}');
      debugPrint('DELETE Follow-up API Response Body: ${response.body}');

      if (_looksLikeHtml(response.body)) {
        debugPrint(
          'HTML response detected for $url. Treating as authentication failure.',
        );
        await _handleAuthFailure();
        throw Exception('Authentication error. Please log in again.');
      }

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204) {
        if (response.body.trim().isEmpty) {
          return {'success': true, 'message': 'Follow-up deleted successfully'};
        }

        dynamic decoded;
        try {
          decoded = jsonDecode(response.body);
        } catch (_) {
          return {
            'success': true,
            'message': 'Follow-up deleted successfully',
            'raw': response.body,
          };
        }

        if (decoded is Map<String, dynamic>) {
          if (decoded['success'] == false) {
            throw Exception(
              (decoded['message'] ?? 'Failed to delete follow-up').toString(),
            );
          }
          return decoded;
        }

        return {'success': true, 'data': decoded};
      }

      String message = 'Failed to delete follow-up: ${response.statusCode}';
      if (response.body.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) {
            final dynamic apiMessage = decoded['message'] ?? decoded['error'];
            if (apiMessage != null && apiMessage.toString().trim().isNotEmpty) {
              message = apiMessage.toString().trim();
            }
          }
        } catch (_) {}
      }
      throw Exception(message);
    } on TimeoutException catch (e) {
      debugPrint('Timeout deleting follow-up: $e');
      throw Exception('Request timeout. Please try again.');
    } on SocketException catch (e) {
      debugPrint('No Internet while deleting follow-up: $e');
      throw Exception('No internet connection. Please check your network.');
    } catch (e) {
      debugPrint('Error deleting follow-up: $e');
      rethrow;
    }
  }

  /// Delete a meeting
  /// DELETE /meet/{meet_id}?user_id={userId}
  static Future<Map<String, dynamic>> deleteMeeting(String meetingId) async {
    final storedUserId = await SecureStorageService.getUserId();

    if (storedUserId == null) {
      await _handleAuthFailure();
      throw Exception('Authentication error. Please log in again.');
    }

    final endpoint = ApiConstants.delete_meet.replaceFirst(
      '{meet_id}',
      meetingId,
    );
    final url = Uri.parse(endpoint).replace(
      queryParameters: {'user_id': storedUserId.toString()},
    );

    try {
      debugPrint('DELETE Meeting API Request: $url');

      final response = await _performAuthenticatedDelete(url);

      debugPrint('DELETE Meeting API Response Status: ${response.statusCode}');
      debugPrint('DELETE Meeting API Response Body: ${response.body}');

      if (_looksLikeHtml(response.body)) {
        debugPrint(
          'HTML response detected for $url. Treating as authentication failure.',
        );
        await _handleAuthFailure();
        throw Exception('Authentication error. Please log in again.');
      }

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204) {
        if (response.body.trim().isEmpty) {
          return {'success': true, 'message': 'Meeting deleted successfully'};
        }

        dynamic decoded;
        try {
          decoded = jsonDecode(response.body);
        } catch (_) {
          return {
            'success': true,
            'message': 'Meeting deleted successfully',
            'raw': response.body,
          };
        }

        if (decoded is Map<String, dynamic>) {
          if (decoded['success'] == false) {
            throw Exception(
              (decoded['message'] ?? 'Failed to delete meeting').toString(),
            );
          }
          return decoded;
        }

        return {'success': true, 'data': decoded};
      }

      String message = 'Failed to delete meeting: ${response.statusCode}';
      if (response.body.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) {
            final dynamic apiMessage = decoded['message'] ?? decoded['error'];
            if (apiMessage != null && apiMessage.toString().trim().isNotEmpty) {
              message = apiMessage.toString().trim();
            }
          }
        } catch (_) {}
      }
      throw Exception(message);
    } on TimeoutException catch (e) {
      debugPrint('Timeout deleting meeting: $e');
      throw Exception('Request timeout. Please try again.');
    } on SocketException catch (e) {
      debugPrint('No Internet while deleting meeting: $e');
      throw Exception('No internet connection. Please check your network.');
    } catch (e) {
      debugPrint('Error deleting meeting: $e');
      rethrow;
    }
  }

  /// Create a follow-up.
  /// POST /follow-up?user_id={userId}
  static Future<ApiResponse<Map<String, dynamic>>> createFollowUp(
    Map<String, dynamic> body,
  ) async {
    final storedUserId = await SecureStorageService.getUserId();

    if (storedUserId == null) {
      await _handleAuthFailure();
      return ApiResponse(
        success: false,
        message: 'Authentication error. Please log in again.',
      );
    }

    final payload = <String, dynamic>{...body, 'user_id': storedUserId};
    final url = Uri.parse(ApiConstants.new_follow_up).replace(
      queryParameters: {'user_id': storedUserId.toString()},
    );

    try {
      debugPrint('CREATE Follow-up API Request: POST $url');
      debugPrint('CREATE Follow-up Request Body: ${jsonEncode(payload)}');

      final response = await _performAuthenticatedPost(
        url,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      debugPrint('CREATE Follow-up API Response Status: ${response.statusCode}');
      debugPrint('CREATE Follow-up API Response Body: ${response.body}');

      final jsonResponse = ApiService.instance._safeJsonDecode(response.body);
      final bool isHtml = jsonResponse['isHtml'] == true;
      final message =
          jsonResponse['message'] ??
          _extractFirstErrorMessage(jsonResponse['errors']) ??
          (isHtml
              ? 'Authentication error. Please log in again.'
              : response.statusCode == 200 || response.statusCode == 201
              ? 'Follow-up submitted'
              : 'Failed to submit follow-up');

      if (isHtml) {
        await _handleAuthFailure();
        return ApiResponse(success: false, message: message);
      }

      final success =
          response.statusCode == 200 ||
          response.statusCode == 201 ||
          jsonResponse['success'] == true;

      return ApiResponse(
        success: success,
        message: message,
        data: jsonResponse['data'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(jsonResponse['data'] as Map)
            : jsonResponse,
        errors: jsonResponse['errors'],
      );
    } on TimeoutException {
      return ApiResponse(
        success: false,
        message: 'Request timeout. Please try again.',
      );
    } on SocketException {
      return ApiResponse(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } catch (e) {
      debugPrint('CREATE Follow-up Error: $e');
      return ApiResponse(
        success: false,
        message: 'Failed to submit follow-up: $e',
      );
    }
  }

  /// Update a follow-up.
  /// PUT /follow-up/{follow_up_id}?user_id={userId}
  static Future<ApiResponse<Map<String, dynamic>>> updateFollowUp(
    String followUpId,
    Map<String, dynamic> body,
  ) async {
    final storedUserId = await SecureStorageService.getUserId();

    if (storedUserId == null) {
      await _handleAuthFailure();
      return ApiResponse(
        success: false,
        message: 'Authentication error. Please log in again.',
      );
    }

    final payload = <String, dynamic>{...body, 'user_id': storedUserId};
    final endpoint = ApiConstants.edit_follow_up.replaceFirst(
      '{follow_up_id}',
      followUpId,
    );
    final url = Uri.parse(endpoint).replace(
      queryParameters: {'user_id': storedUserId.toString()},
    );

    try {
      debugPrint('UPDATE Follow-up API Request: PUT $url');
      debugPrint('UPDATE Follow-up Request Body: ${jsonEncode(payload)}');

      final response = await _performAuthenticatedPut(
        url,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      debugPrint('UPDATE Follow-up API Response Status: ${response.statusCode}');
      debugPrint('UPDATE Follow-up API Response Body: ${response.body}');

      final jsonResponse = ApiService.instance._safeJsonDecode(response.body);
      final bool isHtml = jsonResponse['isHtml'] == true;
      final message =
          jsonResponse['message'] ??
          _extractFirstErrorMessage(jsonResponse['errors']) ??
          (isHtml
              ? 'Authentication error. Please log in again.'
              : response.statusCode == 200 || response.statusCode == 201
              ? 'Follow-up updated successfully'
              : 'Failed to update follow-up');

      if (isHtml) {
        await _handleAuthFailure();
        return ApiResponse(success: false, message: message);
      }

      final success =
          response.statusCode == 200 ||
          response.statusCode == 201 ||
          jsonResponse['success'] == true;

      return ApiResponse(
        success: success,
        message: message,
        data: jsonResponse['data'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(jsonResponse['data'] as Map)
            : jsonResponse,
        errors: jsonResponse['errors'],
      );
    } on TimeoutException {
      return ApiResponse(
        success: false,
        message: 'Request timeout. Please try again.',
      );
    } on SocketException {
      return ApiResponse(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } catch (e) {
      debugPrint('UPDATE Follow-up Error: $e');
      return ApiResponse(
        success: false,
        message: 'Failed to update follow-up: $e',
      );
    }
  }

  /// Create a meeting.
  /// POST /meet
  static Future<ApiResponse<Map<String, dynamic>>> createMeeting(
    Map<String, dynamic> body,
  ) async {
    final storedUserId = await SecureStorageService.getUserId();

    if (storedUserId == null) {
      await _handleAuthFailure();
      return ApiResponse(
        success: false,
        message: 'Authentication error. Please log in again.',
      );
    }

    final payload = <String, dynamic>{...body, 'user_id': storedUserId};
    final url = Uri.parse(ApiConstants.new_meet);

    try {
      debugPrint('CREATE Meeting API Request: POST $url');
      debugPrint('CREATE Meeting Request Body: ${jsonEncode(payload)}');

      final response = await _performAuthenticatedPost(
        url,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      debugPrint('CREATE Meeting API Response Status: ${response.statusCode}');
      debugPrint('CREATE Meeting API Response Body: ${response.body}');

      final jsonResponse = ApiService.instance._safeJsonDecode(response.body);
      final bool isHtml = jsonResponse['isHtml'] == true;
      final message =
          jsonResponse['message'] ??
          _extractFirstErrorMessage(jsonResponse['errors']) ??
          (isHtml
              ? 'Authentication error. Please log in again.'
              : response.statusCode == 200 || response.statusCode == 201
              ? 'Meeting submitted'
              : 'Failed to submit meeting');

      if (isHtml) {
        await _handleAuthFailure();
        return ApiResponse(success: false, message: message);
      }

      final success =
          response.statusCode == 200 ||
          response.statusCode == 201 ||
          jsonResponse['success'] == true;

      return ApiResponse(
        success: success,
        message: message,
        data: jsonResponse['data'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(jsonResponse['data'] as Map)
            : jsonResponse,
        errors: jsonResponse['errors'],
      );
    } on TimeoutException {
      return ApiResponse(
        success: false,
        message: 'Request timeout. Please try again.',
      );
    } on SocketException {
      return ApiResponse(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } catch (e) {
      debugPrint('CREATE Meeting Error: $e');
      return ApiResponse(
        success: false,
        message: 'Failed to submit meeting: $e',
      );
    }
  }

  /// Update a meeting.
  /// PUT /meet/{meet_id}?user_id={userId}
  static Future<ApiResponse<Map<String, dynamic>>> updateMeeting(
    String meetingId,
    Map<String, dynamic> body,
  ) async {
    final storedUserId = await SecureStorageService.getUserId();

    if (storedUserId == null) {
      await _handleAuthFailure();
      return ApiResponse(
        success: false,
        message: 'Authentication error. Please log in again.',
      );
    }

    final payload = <String, dynamic>{...body, 'user_id': storedUserId};
    final endpoint = ApiConstants.edit_meet.replaceFirst('{meet_id}', meetingId);
    final url = Uri.parse(endpoint).replace(
      queryParameters: {'user_id': storedUserId.toString()},
    );

    try {
      debugPrint('UPDATE Meeting API Request: PUT $url');
      debugPrint('UPDATE Meeting Request Body: ${jsonEncode(payload)}');

      final response = await _performAuthenticatedPut(
        url,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      debugPrint('UPDATE Meeting API Response Status: ${response.statusCode}');
      debugPrint('UPDATE Meeting API Response Body: ${response.body}');

      final jsonResponse = ApiService.instance._safeJsonDecode(response.body);
      final bool isHtml = jsonResponse['isHtml'] == true;
      final message =
          jsonResponse['message'] ??
          _extractFirstErrorMessage(jsonResponse['errors']) ??
          (isHtml
              ? 'Authentication error. Please log in again.'
              : response.statusCode == 200 || response.statusCode == 201
              ? 'Meeting updated successfully'
              : 'Failed to update meeting');

      if (isHtml) {
        await _handleAuthFailure();
        return ApiResponse(success: false, message: message);
      }

      final success =
          response.statusCode == 200 ||
          response.statusCode == 201 ||
          jsonResponse['success'] == true;

      return ApiResponse(
        success: success,
        message: message,
        data: jsonResponse['data'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(jsonResponse['data'] as Map)
            : jsonResponse,
        errors: jsonResponse['errors'],
      );
    } on TimeoutException {
      return ApiResponse(
        success: false,
        message: 'Request timeout. Please try again.',
      );
    } on SocketException {
      return ApiResponse(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } catch (e) {
      debugPrint('UPDATE Meeting Error: $e');
      return ApiResponse(
        success: false,
        message: 'Failed to update meeting: $e',
      );
    }
  }

  /// Fetch follow-up list for salesperson
  /// GET /follow-up?user_id={userId}&role_id={roleId}&page={page}
  static Map<String, dynamic> _normalizeFollowUpResponse(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      // Most list endpoints already return {"data": [...], "meta": {...}}
      if (decoded['data'] is List) {
        return decoded;
      }

      // Some endpoints return {"followup": [...], "meets": [...]}
      final followupList = decoded['followup'];
      if (followupList is List) {
        final normalized = Map<String, dynamic>.from(decoded);
        normalized['data'] = followupList;
        return normalized;
      }

      // Sometimes "data" may be a nested map carrying followup list.
      final nestedData = decoded['data'];
      if (nestedData is Map<String, dynamic>) {
        final nestedFollowup = nestedData['followup'];
        if (nestedFollowup is List) {
          final normalized = Map<String, dynamic>.from(decoded);
          normalized['data'] = nestedFollowup;
          final nestedMeta = nestedData['meta'];
          if (nestedMeta is Map<String, dynamic> &&
              normalized['meta'] is! Map<String, dynamic>) {
            normalized['meta'] = nestedMeta;
          }
          return normalized;
        }
      }

      return decoded;
    }

    if (decoded is List) {
      return {'data': decoded};
    }

    return {'data': const <dynamic>[]};
  }

  static bool _isFollowUpLikeItem(dynamic item) {
    if (item is! Map<String, dynamic>) return false;
    return item.containsKey('followup_id') ||
        item.containsKey('followup_date') ||
        item.containsKey('followup_time');
  }

  static List<dynamic> _extractFollowUpList(dynamic decoded) {
    if (decoded is List) {
      return decoded.where(_isFollowUpLikeItem).toList();
    }
    if (decoded is! Map<String, dynamic>) {
      return const <dynamic>[];
    }

    final directFollowup = decoded['followup'];
    if (directFollowup is List) {
      return directFollowup;
    }

    final directData = decoded['data'];
    if (directData is List) {
      return directData.where(_isFollowUpLikeItem).toList();
    }

    if (directData is Map<String, dynamic>) {
      final nestedFollowup = directData['followup'];
      if (nestedFollowup is List) {
        return nestedFollowup;
      }
      final nestedData = directData['data'];
      if (nestedData is List) {
        return nestedData.where(_isFollowUpLikeItem).toList();
      }
    }

    return const <dynamic>[];
  }

  static Future<Map<String, dynamic>> _fetchFollowUpsFromTaskFallback({
    required int userId,
    required int roleId,
    required int page,
  }) async {
    final fallbackUrl = Uri.parse(ApiConstants.task).replace(
      queryParameters: {
        'user_id': userId.toString(),
        'role_id': roleId.toString(),
        'page': page.toString(),
      },
    );

    debugPrint('🟠 Fallback API Request: GET $fallbackUrl');
    final fallbackResponse = await _performAuthenticatedGet(fallbackUrl);
    debugPrint('🟠 Fallback API Response Status: ${fallbackResponse.statusCode}');
    debugPrint('🟠 Fallback API Response Body: ${fallbackResponse.body}');

    if (_looksLikeHtml(fallbackResponse.body)) {
      debugPrint(
        '🔴 HTML response detected for fallback $fallbackUrl. '
        'Treating as authentication failure.',
      );
      await _handleAuthFailure();
      throw Exception('Authentication error. Please log in again.');
    }

    if (fallbackResponse.statusCode != 200) {
      throw Exception(
        'Failed to load follow-ups: ${fallbackResponse.statusCode}',
      );
    }

    final dynamic fallbackDecoded;
    try {
      fallbackDecoded = jsonDecode(fallbackResponse.body);
    } catch (_) {
      return {'data': const <dynamic>[]};
    }

    final normalized = _normalizeFollowUpResponse(fallbackDecoded);
    if (normalized['data'] is List) {
      return normalized;
    }

    return {'data': _extractFollowUpList(fallbackDecoded)};
  }

  static Future<Map<String, dynamic>> fetchFollowUps({int page = 1}) async {
    final storedUserId = await SecureStorageService.getUserId();
    final storedRoleId = await SecureStorageService.getRoleId();

    if (storedUserId == null || storedRoleId == null) {
      debugPrint(
        '🔴 Missing userId/roleId in secure storage when calling fetchFollowUps',
      );
      await _handleAuthFailure();
      throw Exception('Authentication error. Please log in again.');
    }

    final url = Uri.parse(ApiConstants.follow_up_page).replace(
      queryParameters: {
        'user_id': storedUserId.toString(),
        'role_id': storedRoleId.toString(),
        'page': page.toString(),
      },
    );

    try {
      debugPrint('🔵 API Request: GET $url');

      final response = await _performAuthenticatedGet(url);

      debugPrint('🟡 API Response Status: ${response.statusCode}');
      debugPrint('🟡 API Response Body: ${response.body}');

      if (_looksLikeHtml(response.body)) {
        debugPrint(
          '🔴 HTML response detected for $url. Treating as authentication failure.',
        );
        await _handleAuthFailure();
        throw Exception('Authentication error. Please log in again.');
      }

      if (response.statusCode == 200) {
        dynamic decoded;
        try {
          decoded = jsonDecode(response.body);
        } catch (_) {
          decoded = {
            'message': 'Server returned non-JSON',
            'raw': response.body,
          };
        }

        return _normalizeFollowUpResponse(decoded);
      }

      if (response.statusCode == 404) {
        debugPrint(
          '🟠 /follow-up returned 404. Falling back to /task for follow-up data.',
        );
        return _fetchFollowUpsFromTaskFallback(
          userId: storedUserId,
          roleId: storedRoleId,
          page: page,
        );
      }

      throw Exception('Failed to load follow-ups: ${response.statusCode}');
    } on TimeoutException catch (e) {
      debugPrint('🔴 Timeout: $e');
      throw Exception('Request timeout. Please try again.');
    } on SocketException catch (e) {
      debugPrint('🔴 No Internet: $e');
      throw Exception('No internet connection. Please check your network.');
    } on Exception catch (e) {
      debugPrint('🔴 Error fetching follow-ups: $e');
      rethrow;
    }
  }

  static Map<String, dynamic> _normalizeMeetingsResponse(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      if (decoded['data'] is List) {
        return decoded;
      }

      final meetingsList = decoded['meets'] ?? decoded['meetings'];
      if (meetingsList is List) {
        final normalized = Map<String, dynamic>.from(decoded);
        normalized['data'] = meetingsList;
        return normalized;
      }

      final nestedData = decoded['data'];
      if (nestedData is Map<String, dynamic>) {
        // Laravel-style paginator shape:
        // { data: { data: [...], current_page, last_page, ... } }
        final nestedDataList = nestedData['data'];
        if (nestedDataList is List) {
          final normalized = Map<String, dynamic>.from(decoded);
          normalized['data'] = nestedDataList;
          if (normalized['meta'] is! Map<String, dynamic>) {
            final meta = <String, dynamic>{
              if (nestedData['current_page'] != null)
                'current_page': nestedData['current_page'],
              if (nestedData['last_page'] != null)
                'last_page': nestedData['last_page'],
              if (nestedData['per_page'] != null)
                'per_page': nestedData['per_page'],
              if (nestedData['total'] != null) 'total': nestedData['total'],
            };
            if (meta.isNotEmpty) {
              normalized['meta'] = meta;
            }
          }
          return normalized;
        }

        final nestedMeetings = nestedData['meets'] ?? nestedData['meetings'];
        if (nestedMeetings is List) {
          final normalized = Map<String, dynamic>.from(decoded);
          normalized['data'] = nestedMeetings;
          final nestedMeta = nestedData['meta'];
          if (nestedMeta is Map<String, dynamic> &&
              normalized['meta'] is! Map<String, dynamic>) {
            normalized['meta'] = nestedMeta;
          }
          return normalized;
        }
      }

      return decoded;
    }

    if (decoded is List) {
      return {'data': decoded};
    }

    return {'data': const <dynamic>[]};
  }

  static bool _isMeetingLikeItem(dynamic item) {
    if (item is! Map<String, dynamic>) return false;
    return item.containsKey('meet_title') ||
        item.containsKey('meeting_type') ||
        item.containsKey('meet_id');
  }

  static List<dynamic> _extractMeetingsList(dynamic decoded) {
    if (decoded is List) {
      return decoded.where(_isMeetingLikeItem).toList();
    }
    if (decoded is! Map<String, dynamic>) {
      return const <dynamic>[];
    }

    final directMeets = decoded['meets'] ?? decoded['meetings'];
    if (directMeets is List) {
      return directMeets;
    }

    final directData = decoded['data'];
    if (directData is List) {
      return directData.where(_isMeetingLikeItem).toList();
    }

    if (directData is Map<String, dynamic>) {
      final nestedMeets = directData['meets'] ?? directData['meetings'];
      if (nestedMeets is List) {
        return nestedMeets;
      }
      final nestedData = directData['data'];
      if (nestedData is List) {
        return nestedData.where(_isMeetingLikeItem).toList();
      }
    }

    return const <dynamic>[];
  }

  static Future<Map<String, dynamic>> _fetchMeetingsFromTaskFallback({
    required String userId,
    required String roleId,
    required int page,
  }) async {
    final fallbackUrl = Uri.parse(ApiConstants.task).replace(
      queryParameters: {
        'user_id': userId,
        'role_id': roleId,
        'page': page.toString(),
      },
    );

    debugPrint('🟠 Fallback API Request: GET $fallbackUrl');
    final fallbackResponse = await _performAuthenticatedGet(fallbackUrl);
    debugPrint('🟠 Fallback API Response Status: ${fallbackResponse.statusCode}');
    debugPrint('🟠 Fallback API Response Body: ${fallbackResponse.body}');

    if (_looksLikeHtml(fallbackResponse.body)) {
      debugPrint(
        '🔴 HTML response detected for fallback $fallbackUrl. '
        'Treating as authentication failure.',
      );
      await _handleAuthFailure();
      throw Exception('Authentication error. Please log in again.');
    }

    if (fallbackResponse.statusCode != 200) {
      throw Exception(
        'Failed to load meetings: ${fallbackResponse.statusCode}',
      );
    }

    final dynamic fallbackDecoded;
    try {
      fallbackDecoded = jsonDecode(fallbackResponse.body);
    } catch (_) {
      return {'data': const <dynamic>[]};
    }

    final normalized = _normalizeMeetingsResponse(fallbackDecoded);
    if (normalized['data'] is List) {
      return normalized;
    }

    return {'data': _extractMeetingsList(fallbackDecoded)};
  }

  /// Fetch meetings list for salesperson
  /// GET /meets?user_id={userId}&role_id={roleId}&page={page}
  static Future<Map<String, dynamic>> fetchMeetings(
    String userId,
    int roleId, {
    int page = 1,
  }) async {
    // Prefer the IDs stored in SecureStorage (set at login/refresh),
    // but fall back to the method arguments if needed (same pattern as fetchLeads).
    final storedUserId = await SecureStorageService.getUserId();
    final storedRoleId = await SecureStorageService.getRoleId();

    final effectiveUserId = storedUserId?.toString() ?? userId;
    final effectiveRoleId = (storedRoleId ?? roleId).toString();

    final query = <String, String>{
      'user_id': effectiveUserId,
      'page': page.toString(),
    };
    if (effectiveRoleId.trim().isNotEmpty && effectiveRoleId != '0') {
      query['role_id'] = effectiveRoleId;
    }

    final url = Uri.parse(ApiConstants.meets_page).replace(queryParameters: query);

    try {
      debugPrint('🔵 API Request: GET $url');

      final response = await _performAuthenticatedGet(url);

      debugPrint('🟡 API Response Status: ${response.statusCode}');
      debugPrint('🟡 API Response Body: ${response.body}');

      if (_looksLikeHtml(response.body)) {
        debugPrint(
          '🔴 HTML response detected for $url. Treating as authentication failure.',
        );
        await _handleAuthFailure();
        throw Exception('Authentication error. Please log in again.');
      }

      if (response.statusCode == 200) {
        dynamic decoded;
        try {
          decoded = jsonDecode(response.body);
        } catch (_) {
          decoded = {
            'message': 'Server returned non-JSON',
            'raw': response.body,
          };
        }

        final normalized = _normalizeMeetingsResponse(decoded);
        if (normalized['data'] is List) {
          return normalized;
        }

        return {
          'data': _extractMeetingsList(decoded),
          if (normalized['meta'] is Map<String, dynamic>)
            'meta': normalized['meta'],
        };
      }

      if (response.statusCode == 404) {
        debugPrint(
          '🟠 /meets returned 404. Falling back to /task for meetings data.',
        );
        return _fetchMeetingsFromTaskFallback(
          userId: effectiveUserId,
          roleId: effectiveRoleId,
          page: page,
        );
      }

      throw Exception('Failed to load meetings: ${response.statusCode}');
    } on TimeoutException catch (e) {
      debugPrint('🔴 Timeout: $e');
      throw Exception('Request timeout. Please try again.');
    } on SocketException catch (e) {
      debugPrint('🔴 No Internet: $e');
      throw Exception('No internet connection. Please check your network.');
    } on Exception catch (e) {
      debugPrint('🔴 Error fetching meetings: $e');
      rethrow;
    }
  }

  static Map<String, dynamic> _normalizeQuotationsResponse(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      if (decoded['data'] is List) {
        return decoded;
      }

      final quotationList =
          decoded['quotations'] ?? decoded['quotation'] ?? decoded['quotes'];
      if (quotationList is List) {
        final normalized = Map<String, dynamic>.from(decoded);
        normalized['data'] = quotationList;
        return normalized;
      }

      final nestedData = decoded['data'];
      if (nestedData is Map<String, dynamic>) {
        final nestedQuotationList =
            nestedData['quotations'] ??
            nestedData['quotation'] ??
            nestedData['quotes'];
        if (nestedQuotationList is List) {
          final normalized = Map<String, dynamic>.from(decoded);
          normalized['data'] = nestedQuotationList;
          final nestedMeta = nestedData['meta'];
          if (nestedMeta is Map<String, dynamic> &&
              normalized['meta'] is! Map<String, dynamic>) {
            normalized['meta'] = nestedMeta;
          }
          return normalized;
        }
      }

      return decoded;
    }

    if (decoded is List) {
      return {'data': decoded};
    }

    return {'data': const <dynamic>[]};
  }

  static bool _isQuotationLikeItem(dynamic item) {
    if (item is! Map<String, dynamic>) return false;
    return item.containsKey('quotation_no') ||
        item.containsKey('quotation_number') ||
        item.containsKey('quote_number') ||
        item.containsKey('quotation_id');
  }

  static Future<Map<String, dynamic>> _tryFetchQuotationsFromUrl(Uri url) async {
    debugPrint('🟠 Fallback API Request: GET $url');
    final response = await _performAuthenticatedGet(url);
    debugPrint('🟠 Fallback API Response Status: ${response.statusCode}');
    debugPrint('🟠 Fallback API Response Body: ${response.body}');

    if (_looksLikeHtml(response.body)) {
      debugPrint(
        '🔴 HTML response detected for fallback $url. '
        'Treating as authentication failure.',
      );
      await _handleAuthFailure();
      throw Exception('Authentication error. Please log in again.');
    }

    if (response.statusCode != 200) {
      throw Exception('Failed to load quotations: ${response.statusCode}');
    }

    final dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      return {'data': const <dynamic>[]};
    }

    final normalized = _normalizeQuotationsResponse(decoded);
    final data = normalized['data'];
    if (data is List) {
      return {'data': data.where(_isQuotationLikeItem).toList(), 'meta': normalized['meta']};
    }
    return {'data': const <dynamic>[]};
  }

  static String _replaceTrailingPathSegment(
    String path,
    String fromSegment,
    String toSegment,
  ) {
    final from = '/$fromSegment';
    if (!path.endsWith(from)) {
      return path;
    }
    return '${path.substring(0, path.length - from.length)}/$toSegment';
  }

  /// Fetch quotations list for salesperson
  /// GET /quotation?user_id={userId}&role_id={roleId}&page={page}
  static Future<Map<String, dynamic>> fetchQuotations({int page = 1}) async {
    final storedUserId = await SecureStorageService.getUserId();
    final storedRoleId = await SecureStorageService.getRoleId();

    if (storedUserId == null || storedRoleId == null) {
      debugPrint(
        '🔴 Missing userId/roleId in secure storage when calling fetchQuotations',
      );
      await _handleAuthFailure();
      throw Exception('Authentication error. Please log in again.');
    }

    final url = Uri.parse(ApiConstants.quotation_page).replace(
      queryParameters: {
        'user_id': storedUserId.toString(),
        'role_id': storedRoleId.toString(),
        'page': page.toString(),
      },
    );

    try {
      debugPrint('🔵 API Request: GET $url');

      final response = await _performAuthenticatedGet(url);

      debugPrint('🟡 API Response Status: ${response.statusCode}');
      debugPrint('🟡 API Response Body: ${response.body}');

      if (_looksLikeHtml(response.body)) {
        debugPrint(
          '🔴 HTML response detected for $url. Treating as authentication failure.',
        );
        await _handleAuthFailure();
        throw Exception('Authentication error. Please log in again.');
      }

      if (response.statusCode == 200) {
        dynamic decoded;
        try {
          decoded = jsonDecode(response.body);
        } catch (_) {
          decoded = {
            'message': 'Server returned non-JSON',
            'raw': response.body,
          };
        }

        return _normalizeQuotationsResponse(decoded);
      }

      if (response.statusCode == 404) {
        final fallbackUrls = <Uri>[
          url.replace(
            path: _replaceTrailingPathSegment(
              url.path,
              'quotation',
              'quotations',
            ),
          ),
          url.replace(
            path: _replaceTrailingPathSegment(
              url.path,
              'quotation',
              'quote',
            ),
          ),
        ];

        final seen = <String>{url.toString()};
        for (final fallbackUrl in fallbackUrls) {
          if (!seen.add(fallbackUrl.toString())) {
            continue;
          }

          try {
            return _tryFetchQuotationsFromUrl(fallbackUrl);
          } on Exception catch (e) {
            final msg = e.toString();
            if (msg.contains('404')) {
              continue;
            }
            rethrow;
          }
        }
      }

      throw Exception('Failed to load quotations: ${response.statusCode}');
    } on TimeoutException catch (e) {
      debugPrint('🔴 Timeout: $e');
      throw Exception('Request timeout. Please try again.');
    } on SocketException catch (e) {
      debugPrint('🔴 No Internet: $e');
      throw Exception('No internet connection. Please check your network.');
    } on Exception catch (e) {
      debugPrint('🔴 Error fetching quotations: $e');
      rethrow;
    }
  }

  /// Fetch AMC plans for quotation form.
  /// GET /amc-plans?user_id={userId}&role_id={roleId}
  static Future<List<Map<String, dynamic>>> fetchAmcPlans() async {
    final storedUserId = await SecureStorageService.getUserId();
    final storedRoleId = await SecureStorageService.getRoleId();

    if (storedUserId == null || storedRoleId == null) {
      await _handleAuthFailure();
      throw Exception('Authentication error. Please log in again.');
    }

    final url = Uri.parse(ApiConstants.amcplanslist).replace(
      queryParameters: {
        'user_id': storedUserId.toString(),
        'role_id': storedRoleId.toString(),
      },
    );

    try {
      debugPrint('AMC Plans API Request: GET $url');
      final response = await _performAuthenticatedGet(url);
      debugPrint('AMC Plans API Response Status: ${response.statusCode}');
      debugPrint('AMC Plans API Response Body: ${response.body}');

      if (_looksLikeHtml(response.body)) {
        await _handleAuthFailure();
        throw Exception('Authentication error. Please log in again.');
      }

      if (response.statusCode != 200) {
        throw Exception('Failed to load AMC plans: ${response.statusCode}');
      }

      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        decoded = const <dynamic>[];
      }

      List<dynamic> rawList = const <dynamic>[];
      if (decoded is List) {
        rawList = decoded;
      } else if (decoded is Map<String, dynamic>) {
        if (decoded['data'] is List) {
          rawList = decoded['data'] as List<dynamic>;
        } else if (decoded['plans'] is List) {
          rawList = decoded['plans'] as List<dynamic>;
        } else if (decoded['amc_plans'] is List) {
          rawList = decoded['amc_plans'] as List<dynamic>;
        } else if (decoded['data'] is Map<String, dynamic>) {
          final dataMap = decoded['data'] as Map<String, dynamic>;
          if (dataMap['plans'] is List) {
            rawList = dataMap['plans'] as List<dynamic>;
          } else if (dataMap['amc_plans'] is List) {
            rawList = dataMap['amc_plans'] as List<dynamic>;
          }
        }
      }

      return rawList
          .whereType<Map>()
          .map((item) {
            final map = Map<String, dynamic>.from(item as Map);
            final nestedPlan = map['plan'];

            if (nestedPlan is Map) {
              return <String, dynamic>{
                ...Map<String, dynamic>.from(nestedPlan),
                if (map['covered_items'] != null) 'covered_items_meta': map['covered_items'],
              };
            }

            return map;
          })
          .toList();
    } on TimeoutException {
      throw Exception('Request timeout. Please try again.');
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } catch (e) {
      debugPrint('AMC Plans Error: $e');
      rethrow;
    }
  }

  /// Create quotation with one product payload and image file.
  static Future<ApiResponse<Map<String, dynamic>>> createQuotation({
    required Map<String, String> fields,
    File? productImage,
  }) async {
    final storedUserId = await SecureStorageService.getUserId();
    final accessToken = await SecureStorageService.getAccessToken();

    if (storedUserId == null || accessToken == null || accessToken.isEmpty) {
      await _handleAuthFailure();
      return ApiResponse(
        success: false,
        message: 'Authentication error. Please log in again.',
      );
    }

    final request = http.MultipartRequest('POST', Uri.parse(ApiConstants.new_quotation))
      ..headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $accessToken',
      })
      ..fields.addAll({
        ...fields,
        'user_id': storedUserId.toString(),
      });

    try {
      if (productImage != null && productImage.path.trim().isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'products[0][images]',
            productImage.path,
          ),
        );
      }

      debugPrint('CREATE Quotation API Request: POST ${request.url}');
      debugPrint('CREATE Quotation Request Fields: ${request.fields}');

      final streamedResponse = await request.send().timeout(ApiConstants.requestTimeout);
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('CREATE Quotation API Response Status: ${response.statusCode}');
      debugPrint('CREATE Quotation API Response Body: ${response.body}');

      final jsonResponse = ApiService.instance._safeJsonDecode(response.body);
      final bool isHtml = jsonResponse['isHtml'] == true;
      final message =
          jsonResponse['message'] ??
          _extractFirstErrorMessage(jsonResponse['errors']) ??
          (isHtml
              ? 'Authentication error. Please log in again.'
              : response.statusCode == 200 || response.statusCode == 201
              ? 'Quotation submitted'
              : 'Failed to submit quotation');

      if (isHtml) {
        await _handleAuthFailure();
        return ApiResponse(success: false, message: message);
      }

      final success =
          response.statusCode == 200 ||
          response.statusCode == 201 ||
          jsonResponse['success'] == true;

      return ApiResponse(
        success: success,
        message: message,
        data: jsonResponse['data'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(jsonResponse['data'] as Map)
            : jsonResponse,
        errors: jsonResponse['errors'],
      );
    } on TimeoutException {
      return ApiResponse(
        success: false,
        message: 'Request timeout. Please try again.',
      );
    } on SocketException {
      return ApiResponse(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } catch (e) {
      debugPrint('CREATE Quotation Error: $e');
      return ApiResponse(
        success: false,
        message: 'Failed to submit quotation: $e',
      );
    }
  }

  /// Fetch profile for the currently authenticated salesperson
  /// GET /profile?user_id={userId}&role_id={roleId}
  static Future<Map<String, dynamic>> fetchProfile() async {
    final storedUserId = await SecureStorageService.getUserId();
    final storedRoleId = await SecureStorageService.getRoleId();

    if (storedUserId == null || storedRoleId == null) {
      debugPrint(
        '🔴 Missing userId/roleId in secure storage when calling fetchProfile',
      );
      await _handleAuthFailure();
      throw Exception('Authentication error. Please log in again.');
    }

    final url = Uri.parse(ApiConstants.profile_page).replace(
      queryParameters: {
        'user_id': storedUserId.toString(),
        'role_id': storedRoleId.toString(),
      },
    );

    try {
      debugPrint('🔵 API Request: GET $url');

      final response = await _performAuthenticatedGet(url);

      debugPrint('🟡 API Response Status: ${response.statusCode}');
      debugPrint('🟡 API Response Body: ${response.body}');

      if (_looksLikeHtml(response.body)) {
        debugPrint(
          '🔴 HTML response detected for $url. Treating as authentication failure.',
        );
        await _handleAuthFailure();
        throw Exception('Authentication error. Please log in again.');
      }

      if (response.statusCode == 200) {
        dynamic decoded;
        try {
          decoded = jsonDecode(response.body);
        } catch (_) {
          decoded = {
            'message': 'Server returned non-JSON',
            'raw': response.body,
          };
        }

        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        if (decoded is List) {
          // In case the API returns a bare list, wrap it for consistency.
          return {'data': decoded};
        }
        return {'data': decoded};
      } else {
        throw Exception('Failed to load profile: ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      debugPrint('🔴 Timeout: $e');
      throw Exception('Request timeout. Please try again.');
    } on SocketException catch (e) {
      debugPrint('🔴 No Internet: $e');
      throw Exception('No internet connection. Please check your network.');
    } catch (e) {
      debugPrint('🔴 Error fetching profile: $e');
      throw Exception('Failed to load profile: $e');
    }
  }

  /// Fetch feedback list for the currently authenticated field executive.
  /// GET /get-all-feedback?user_id={userId}&role_id={roleId}
  static Future<List<Map<String, dynamic>>> fetchFieldExecutiveFeedbackList({
    int? roleId,
  }) async {
    final storedUserId = await SecureStorageService.getUserId();
    final storedRoleId = await SecureStorageService.getRoleId();
    final effectiveRoleId =
        storedRoleId ?? (roleId != null && roleId > 0 ? roleId : null);

    if (storedUserId == null || effectiveRoleId == null) {
      debugPrint(
        'Missing userId/roleId in secure storage when calling fetchFieldExecutiveFeedbackList',
      );
      await _handleAuthFailure();
      throw Exception('Authentication error. Please log in again.');
    }

    final url = Uri.parse(ApiConstants.fieldexecutivefeedback).replace(
      queryParameters: {
        'user_id': storedUserId.toString(),
        'role_id': effectiveRoleId.toString(),
      },
    );

    try {
      debugPrint('API Request: GET $url');
      final response = await _performAuthenticatedGet(url);
      debugPrint('API Response Status: ${response.statusCode}');
      debugPrint('API Response Body: ${response.body}');

      if (_looksLikeHtml(response.body)) {
        await _handleAuthFailure();
        throw Exception('Authentication error. Please log in again.');
      }

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to load field executive feedback list: ${response.statusCode}',
        );
      }

      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        decoded = const <String, dynamic>{};
      }

      return _extractFieldExecutiveFeedbackList(decoded);
    } on TimeoutException catch (e) {
      debugPrint('Timeout: $e');
      throw Exception('Request timeout. Please try again.');
    } on SocketException catch (e) {
      debugPrint('No Internet: $e');
      throw Exception('No internet connection. Please check your network.');
    } catch (e) {
      debugPrint('Error fetching field executive feedback list: $e');
      throw Exception('Failed to load feedback list: $e');
    }
  }

  static List<Map<String, dynamic>> _extractFieldExecutiveFeedbackList(
    dynamic decoded,
  ) {
    List<dynamic> rawList = const <dynamic>[];

    if (decoded is List) {
      rawList = decoded;
    } else if (decoded is Map<String, dynamic>) {
      if (decoded['feedbacks'] is List) {
        rawList = decoded['feedbacks'] as List<dynamic>;
      } else if (decoded['feedback'] is List) {
        rawList = decoded['feedback'] as List<dynamic>;
      } else if (decoded['items'] is List) {
        rawList = decoded['items'] as List<dynamic>;
      } else if (decoded['data'] is List) {
        rawList = decoded['data'] as List<dynamic>;
      } else if (decoded['data'] is Map<String, dynamic>) {
        final dataMap = decoded['data'] as Map<String, dynamic>;
        if (dataMap['feedbacks'] is List) {
          rawList = dataMap['feedbacks'] as List<dynamic>;
        } else if (dataMap['feedback'] is List) {
          rawList = dataMap['feedback'] as List<dynamic>;
        } else if (dataMap['items'] is List) {
          rawList = dataMap['items'] as List<dynamic>;
        } else if (dataMap['data'] is List) {
          rawList = dataMap['data'] as List<dynamic>;
        }
      }
    }

    return rawList
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  /// Fetch one feedback detail for the currently authenticated field executive.
  /// GET /get-feedback?feedback_id={feedbackId}&user_id={userId}&role_id={roleId}
  static Future<Map<String, dynamic>> fetchFieldExecutiveFeedbackDetail({
    required String feedbackId,
    int? roleId,
  }) async {
    final storedUserId = await SecureStorageService.getUserId();
    final storedRoleId = await SecureStorageService.getRoleId();
    final effectiveRoleId =
        storedRoleId ?? (roleId != null && roleId > 0 ? roleId : null);
    final sanitizedFeedbackId = feedbackId.trim().replaceFirst(RegExp(r'^#'), '');

    if (storedUserId == null || effectiveRoleId == null) {
      debugPrint(
        'Missing userId/roleId in secure storage when calling fetchFieldExecutiveFeedbackDetail',
      );
      await _handleAuthFailure();
      throw Exception('Authentication error. Please log in again.');
    }

    if (sanitizedFeedbackId.isEmpty) {
      throw Exception('Invalid feedback id: $feedbackId');
    }

    Future<http.Response> performDetailRequest(Uri url) async {
      debugPrint('API Request: GET $url');
      final response = await _performAuthenticatedGet(url);
      debugPrint('API Response Status: ${response.statusCode}');
      debugPrint('API Response Body: ${response.body}');

      if (_looksLikeHtml(response.body)) {
        await _handleAuthFailure();
        throw Exception('Authentication error. Please log in again.');
      }
      return response;
    }

    final baseDetailEndpoint =
        ApiConstants.fieldexecutivefeedbackdetail.replaceFirst(RegExp(r'/$'), '');
    final primaryUrl = Uri.parse(baseDetailEndpoint).replace(
      queryParameters: {
        'feedback_id': sanitizedFeedbackId,
        'id': sanitizedFeedbackId,
        'user_id': storedUserId.toString(),
        'role_id': effectiveRoleId.toString(),
      },
    );
    final fallbackUrl = Uri.parse('$baseDetailEndpoint/$sanitizedFeedbackId').replace(
      queryParameters: {
        'user_id': storedUserId.toString(),
        'role_id': effectiveRoleId.toString(),
      },
    );

    try {
      var response = await performDetailRequest(primaryUrl);

      if (response.statusCode != 200) {
        response = await performDetailRequest(fallbackUrl);
      }

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to load field executive feedback detail: ${response.statusCode}',
        );
      }

      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        decoded = const <String, dynamic>{};
      }

      final detail = _extractFieldExecutiveFeedbackDetail(
        decoded,
        sanitizedFeedbackId,
      );
      return detail ?? const <String, dynamic>{};
    } on TimeoutException catch (e) {
      debugPrint('Timeout: $e');
      throw Exception('Request timeout. Please try again.');
    } on SocketException catch (e) {
      debugPrint('No Internet: $e');
      throw Exception('No internet connection. Please check your network.');
    } catch (e) {
      debugPrint('Error fetching field executive feedback detail: $e');
      throw Exception('Failed to load feedback detail: $e');
    }
  }

  static Map<String, dynamic>? _extractFieldExecutiveFeedbackDetail(
    dynamic decoded,
    String feedbackId,
  ) {
    final normalizedFeedbackId = feedbackId.trim().replaceFirst(RegExp(r'^#'), '');
    final numericFeedbackId = int.tryParse(normalizedFeedbackId);

    bool matchesFeedback(Map<String, dynamic> map) {
      bool matchesValue(dynamic value) {
        if (value == null) return false;
        final text = value.toString().trim();
        if (text.isEmpty) return false;
        if (text == normalizedFeedbackId) return true;
        if (numericFeedbackId != null) {
          final parsed = int.tryParse(text);
          return parsed != null && parsed == numericFeedbackId;
        }
        return false;
      }

      return matchesValue(map['id']) ||
          matchesValue(map['feedback_id']) ||
          matchesValue(map['request_id']);
    }

    Map<String, dynamic>? asMap(dynamic value) {
      if (value is Map<String, dynamic>) {
        return Map<String, dynamic>.from(value);
      }
      if (value is Map) {
        return Map<String, dynamic>.from(value as Map);
      }
      return null;
    }

    List<Map<String, dynamic>> asList(dynamic value) {
      if (value is! List) return const <Map<String, dynamic>>[];
      return value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }

    if (decoded is Map<String, dynamic>) {
      const directMapKeys = <String>[
        'feedback',
        'item',
        'details',
        'data',
      ];
      for (final key in directMapKeys) {
        final map = asMap(decoded[key]);
        if (map != null && map.isNotEmpty) {
          return map;
        }
      }

      const directListKeys = <String>[
        'feedbacks',
        'feedback',
        'items',
        'data',
        'results',
      ];
      for (final key in directListKeys) {
        final items = asList(decoded[key]);
        if (items.isEmpty) continue;
        for (final item in items) {
          if (matchesFeedback(item)) return item;
        }
        return items.first;
      }

      final nestedData = decoded['data'];
      if (nestedData is Map<String, dynamic>) {
        final nestedFeedback = asMap(nestedData['feedback']);
        if (nestedFeedback != null && nestedFeedback.isNotEmpty) {
          return nestedFeedback;
        }
        final nestedItems = asList(nestedData['items']);
        if (nestedItems.isNotEmpty) {
          for (final item in nestedItems) {
            if (matchesFeedback(item)) return item;
          }
          return nestedItems.first;
        }
      }

      final looksLikeFeedbackDetail =
          decoded.containsKey('rating') ||
          decoded.containsKey('message') ||
          decoded.containsKey('comment') ||
          decoded.containsKey('feedback');
      if (looksLikeFeedbackDetail) {
        return Map<String, dynamic>.from(decoded);
      }

      return null;
    }

    if (decoded is List) {
      final items = decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      if (items.isEmpty) return null;
      for (final item in items) {
        if (matchesFeedback(item)) return item;
      }
      return items.first;
    }

    return null;
  }

  /// Fetch profile data for the currently authenticated field executive.
  /// GET /profile?user_id={userId}&role_id={roleId}
  static Future<Map<String, dynamic>> fetchFieldExecutivePersonalInfo({
    int? roleId,
  }) async {
    final storedUserId = await SecureStorageService.getUserId();
    final storedRoleId = await SecureStorageService.getRoleId();
    final effectiveRoleId = storedRoleId ?? (roleId != null && roleId > 0 ? roleId : null);

    if (storedUserId == null || effectiveRoleId == null) {
      debugPrint(
        'Missing userId/roleId in secure storage when calling fetchFieldExecutivePersonalInfo',
      );
      await _handleAuthFailure();
      throw Exception('Authentication error. Please log in again.');
    }

    final url = Uri.parse(ApiConstants.fieldexecutivepersonalinfo).replace(
      queryParameters: {
        'user_id': storedUserId.toString(),
        'role_id': effectiveRoleId.toString(),
      },
    );

    try {
      debugPrint('API Request: GET $url');
      final response = await _performAuthenticatedGet(url);
      debugPrint('API Response Status: ${response.statusCode}');
      debugPrint('API Response Body: ${response.body}');

      if (_looksLikeHtml(response.body)) {
        await _handleAuthFailure();
        throw Exception('Authentication error. Please log in again.');
      }

      if (response.statusCode != 200) {
        throw Exception('Failed to load field executive profile: ${response.statusCode}');
      }

      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        decoded = <String, dynamic>{};
      }

      if (decoded is! Map<String, dynamic>) {
        return <String, dynamic>{};
      }

      final candidateMaps = <Map<String, dynamic>>[decoded];
      if (decoded['data'] is Map<String, dynamic>) {
        final dataMap = decoded['data'] as Map<String, dynamic>;
        candidateMaps.add(dataMap);
        if (dataMap['user'] is Map<String, dynamic>) {
          candidateMaps.add(dataMap['user'] as Map<String, dynamic>);
        }
        if (dataMap['staff'] is Map<String, dynamic>) {
          candidateMaps.add(dataMap['staff'] as Map<String, dynamic>);
        }
        if (dataMap['profile'] is Map<String, dynamic>) {
          candidateMaps.add(dataMap['profile'] as Map<String, dynamic>);
        }
      }
      if (decoded['user'] is Map<String, dynamic>) {
        candidateMaps.add(decoded['user'] as Map<String, dynamic>);
      }
      if (decoded['staff'] is Map<String, dynamic>) {
        candidateMaps.add(decoded['staff'] as Map<String, dynamic>);
      }
      if (decoded['profile'] is Map<String, dynamic>) {
        candidateMaps.add(decoded['profile'] as Map<String, dynamic>);
      }

      for (final map in candidateMaps) {
        if (map.containsKey('first_name') ||
            map.containsKey('last_name') ||
            map.containsKey('phone') ||
            map.containsKey('email') ||
            map.containsKey('dob')) {
          return Map<String, dynamic>.from(map);
        }
      }

      return decoded;
    } on TimeoutException catch (e) {
      debugPrint('Timeout: $e');
      throw Exception('Request timeout. Please try again.');
    } on SocketException catch (e) {
      debugPrint('No Internet: $e');
      throw Exception('No internet connection. Please check your network.');
    } catch (e) {
      debugPrint('Error fetching field executive profile: $e');
      throw Exception('Failed to load profile: $e');
    }
  }

  /// Fetch attendance logs for the currently authenticated field executive.
  /// GET /attendance?user_id={userId}&role_id={roleId}
  static Future<List<Map<String, dynamic>>> fetchFieldExecutiveAttendance({
    int? roleId,
  }) async {
    final storedUserId = await SecureStorageService.getUserId();
    final storedRoleId = await SecureStorageService.getRoleId();
    final effectiveRoleId =
        storedRoleId ?? (roleId != null && roleId > 0 ? roleId : null);

    if (storedUserId == null || effectiveRoleId == null) {
      debugPrint(
        'Missing userId/roleId in secure storage when calling fetchFieldExecutiveAttendance',
      );
      await _handleAuthFailure();
      throw Exception('Authentication error. Please log in again.');
    }

    final url = Uri.parse(ApiConstants.fieldexecutiveattendance).replace(
      queryParameters: {
        'user_id': storedUserId.toString(),
        'role_id': effectiveRoleId.toString(),
      },
    );

    try {
      debugPrint('API Request: GET $url');
      final response = await _performAuthenticatedGet(url);
      debugPrint('API Response Status: ${response.statusCode}');
      debugPrint('API Response Body: ${response.body}');

      if (_looksLikeHtml(response.body)) {
        await _handleAuthFailure();
        throw Exception('Authentication error. Please log in again.');
      }

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to load field executive attendance: ${response.statusCode}',
        );
      }

      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        decoded = <String, dynamic>{};
      }

      List<dynamic> rawLogs = const <dynamic>[];
      if (decoded is List) {
        rawLogs = decoded;
      } else if (decoded is Map<String, dynamic>) {
        if (decoded['logs'] is List) {
          rawLogs = decoded['logs'] as List<dynamic>;
        } else if (decoded['data'] is List) {
          rawLogs = decoded['data'] as List<dynamic>;
        } else if (decoded['data'] is Map<String, dynamic>) {
          final dataMap = decoded['data'] as Map<String, dynamic>;
          if (dataMap['logs'] is List) {
            rawLogs = dataMap['logs'] as List<dynamic>;
          } else if (dataMap['data'] is List) {
            rawLogs = dataMap['data'] as List<dynamic>;
          }
        }
      }

      return rawLogs
          .whereType<Map>()
          .map((log) => Map<String, dynamic>.from(log))
          .toList();
    } on TimeoutException catch (e) {
      debugPrint('Timeout: $e');
      throw Exception('Request timeout. Please try again.');
    } on SocketException catch (e) {
      debugPrint('No Internet: $e');
      throw Exception('No internet connection. Please check your network.');
    } catch (e) {
      debugPrint('Error fetching field executive attendance: $e');
      throw Exception('Failed to load attendance: $e');
    }
  }

  // ========================================
  // Generic HTTP Methods
  // ========================================

  /// Generic GET request
  static Future<dynamic> get(String url, {String? token}) async {
    try {
      final res = await http
          .get(
            Uri.parse(url),
            headers: {
              'Accept': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
          )
          .timeout(ApiConstants.requestTimeout);
      return jsonDecode(res.body);
    } catch (e) {
      debugPrint('🔴 GET Error: $e');
      rethrow;
    }
  }

  /// Generic POST request
  static Future<dynamic> post(String url, Map body, {String? token}) async {
    try {
      final headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final res = await http
          .post(Uri.parse(url), headers: headers, body: jsonEncode(body))
          .timeout(ApiConstants.requestTimeout);

      return jsonDecode(res.body);
    } catch (e) {
      debugPrint('🔴 POST Error: $e');
      rethrow;
    }
  }

  /// Generic PUT request
  static Future<dynamic> put(String url, Map body, {String? token}) async {
    try {
      final headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final res = await http
          .put(Uri.parse(url), headers: headers, body: jsonEncode(body))
          .timeout(ApiConstants.requestTimeout);

      return jsonDecode(res.body);
    } catch (e) {
      debugPrint('ðŸ”´ PUT Error: $e');
      rethrow;
    }
  }

  // Update Task View
  Future<ApiResponse> updateTaskStatus({
    required String taskId,
    required String status,
  }) async {
    final accessToken = await SecureStorageService.getAccessToken();
    final headers = <String, String>{
      ..._headers,
      if (accessToken != null && accessToken.isNotEmpty)
        'Authorization': 'Bearer $accessToken',
    };

    final res = await http
        .post(
          Uri.parse("${ApiConstants.updateTaskStatus}/$taskId"),
          headers: headers,
          // Keep form-style body to avoid changing backend expectations.
          body: {"status": status},
        )
        .timeout(ApiConstants.requestTimeout);

    final json = _safeJsonDecode(res.body);
    return ApiResponse.fromJson(json, (data) => data);
  }
}
