import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../model/api_response.dart';
import '../model/field executive/field_executive_service_request_detail.dart';
import '../core/secure_storage_service.dart';
import '../core/navigation_service.dart';

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
  Future<void> _persistTokensFromData(
    dynamic data, {
    required int roleId,
  }) async {
    if (data == null) {
      return;
    }

    String? accessToken;
    String? refreshToken;
    int? userId;

    if (data is Map<String, dynamic>) {
      accessToken = _extractStringField(data, const [
        'access_token',
        'token',
        'accessToken',
      ]);
      refreshToken = _extractStringField(data, const [
        'refresh_token',
        'refreshToken',
      ]);

      // Try to capture the authenticated user's id from common shapes:
      // - { user_id: 1, ... }
      // - { id: 1, ... }
      // - { user: { id: 1 } }
      dynamic rawUserId = data['user_id'] ?? data['id'];
      if (rawUserId == null && data['user'] is Map<String, dynamic>) {
        final user = data['user'] as Map<String, dynamic>;
        rawUserId = user['user_id'] ?? user['id'];
      }
      userId = _tryParseInt(rawUserId);
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

  int? _tryParseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
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
        // Persist tokens (if present) for this role.
        await _persistTokensFromData(
          jsonResponse['data'] ?? jsonResponse,
          roleId: roleId,
        );
        return ApiResponse(
          success: jsonResponse['success'] ?? true,
          message: jsonResponse['message'] ?? 'OTP verified',
          data: jsonResponse['data'] ?? jsonResponse,
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

  /// Fetch service requests list for field executive
  /// GET /service-requests?user_id={userId}&role_id={roleId}
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
      baseEndpoint = '${ApiConstants.serviceRequest}/$numericId';
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

  /// Send OTP for a field-executive service request start flow.
  /// POST /service-request/{id}/send-otp?user_id={userId}&role_id={roleId}
  static Future<ApiResponse> sendServiceRequestOtp(
    String serviceRequestId, {
    int? roleId,
  }) async {
    final storedUserId = await SecureStorageService.getUserId();
    final storedRoleId = await SecureStorageService.getRoleId();

    if (storedUserId == null) {
      debugPrint(
        'Missing userId in secure storage when calling sendServiceRequestOtp',
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

    String baseEndpoint = ApiConstants.ServiceRequestsendotp
        .replaceFirst('{service-request_id}', numericId.toString())
        .replaceFirst('{service_request_id}', numericId.toString());
    if (baseEndpoint.contains('{service-request_id}') ||
        baseEndpoint.contains('{service_request_id}')) {
      baseEndpoint = '${ApiConstants.serviceRequest}/$numericId/send-otp';
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

  /// Verify OTP for a field-executive service request start flow.
  /// POST /service-request/{id}/verify-otp?otp={otp}&user_id={userId}&role_id={roleId}
  static Future<ApiResponse> verifyServiceRequestOtp(
    String serviceRequestId, {
    required String otp,
    int? roleId,
  }) async {
    final storedUserId = await SecureStorageService.getUserId();
    final storedRoleId = await SecureStorageService.getRoleId();

    if (storedUserId == null) {
      debugPrint(
        'Missing userId in secure storage when calling verifyServiceRequestOtp',
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

    final normalizedOtp = otp.trim();
    if (normalizedOtp.isEmpty) {
      return ApiResponse(
        success: false,
        message: 'OTP is required.',
      );
    }

    final effectiveRoleId = (storedRoleId ?? roleId ?? 1).toString();

    String baseEndpoint = ApiConstants.ServiceRequestverifyotp
        .replaceFirst('{service-request_id}', numericId.toString())
        .replaceFirst('{service_request_id}', numericId.toString());
    if (baseEndpoint.contains('{service-request_id}') ||
        baseEndpoint.contains('{service_request_id}')) {
      baseEndpoint = '${ApiConstants.serviceRequest}/$numericId/verify-otp';
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
      baseEndpoint = '${ApiConstants.serviceRequest}/$numericId/case-transfer';
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

      final attempts = <Uri>[
        Uri.parse('${ApiConstants.serviceRequest}/$numericId').replace(
          queryParameters: base,
        ),
        Uri.parse('${ApiConstants.serviceRequest}/$numericId'),
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
