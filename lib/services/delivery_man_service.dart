import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../constants/api_constants.dart';
import '../core/navigation_service.dart';
import '../core/secure_storage_service.dart';
import '../model/api_response.dart';
import 'api_service.dart';

class DeliveryManService {
  DeliveryManService._();

  static final DeliveryManService instance = DeliveryManService._();

  static const int _defaultRoleId = 2;
  static const int _maxAuthRetries = 1;

  Future<_DeliveryAuthState> _authState({bool forceReload = false}) async {
    return _DeliveryAuthState(
      userId: await SecureStorageService.getUserId(forceReload: forceReload),
      roleId: await SecureStorageService.getRoleId(forceReload: forceReload),
      accessToken: await SecureStorageService.getAccessToken(
        forceReload: forceReload,
      ),
    );
  }

  Future<ApiResponse?> _validateAuthState() async {
    final state = await _authState(forceReload: true);
    if (state.userId != null && state.roleId != null) {
      return null;
    }
    await SecureStorageService.clearTokens();
    await NavigationService.navigateToAuthRoot();
    return ApiResponse(
      success: false,
      message: 'Authentication error. Please log in again.',
    );
  }

  bool _looksLikeHtml(String body) {
    final trimmed = body.trimLeft().toLowerCase();
    return trimmed.startsWith('<!doctype html') || trimmed.startsWith('<html');
  }

  bool _isUnauthorized(http.Response response) {
    if (response.statusCode == 401 || response.statusCode == 403) {
      return true;
    }
    if (_looksLikeHtml(response.body)) {
      return true;
    }
    final body = response.body.toLowerCase();
    return body.contains('unauthorized') || body.contains('token not provided');
  }

  Future<bool> _refreshToken() async {
    final state = await _authState(forceReload: true);
    if (state.userId == null) return false;
    final response = await ApiService.instance.refreshToken(
      roleId: state.roleId ?? _defaultRoleId,
      userId: state.userId!,
    );
    return response.success;
  }

  Future<void> _handleAuthFailure() async {
    await SecureStorageService.clearTokens();
    await NavigationService.navigateToAuthRoot();
  }

  Map<String, String> _headers({String? token, bool json = false}) {
    return <String, String>{
      'Accept': 'application/json',
      if (json) 'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> _performAuthenticatedGet(Uri url) async {
    int retries = 0;
    while (true) {
      final token = await SecureStorageService.getAccessToken();
      final response = await http
          .get(url, headers: _headers(token: token))
          .timeout(ApiConstants.requestTimeout);
      if (!_isUnauthorized(response)) {
        return response;
      }
      if (retries >= _maxAuthRetries || !await _refreshToken()) {
        await _handleAuthFailure();
        return response;
      }
      retries++;
    }
  }

  Future<http.Response> _performAuthenticatedPost(
    Uri url, {
    Object? body,
    bool json = false,
  }) async {
    int retries = 0;
    while (true) {
      final token = await SecureStorageService.getAccessToken();
      final response = await http
          .post(
            url,
            headers: _headers(token: token, json: json),
            body: body,
          )
          .timeout(ApiConstants.requestTimeout);
      if (!_isUnauthorized(response)) {
        return response;
      }
      if (retries >= _maxAuthRetries || !await _refreshToken()) {
        await _handleAuthFailure();
        return response;
      }
      retries++;
    }
  }

  Future<http.Response> _performAuthenticatedPut(
    Uri url, {
    Object? body,
    bool json = false,
  }) async {
    int retries = 0;
    while (true) {
      final token = await SecureStorageService.getAccessToken();
      final response = await http
          .put(
            url,
            headers: _headers(token: token, json: json),
            body: body,
          )
          .timeout(ApiConstants.requestTimeout);
      if (!_isUnauthorized(response)) {
        return response;
      }
      if (retries >= _maxAuthRetries || !await _refreshToken()) {
        await _handleAuthFailure();
        return response;
      }
      retries++;
    }
  }

  Future<http.Response> _performAuthenticatedMultipart(
    http.MultipartRequest request,
  ) async {
    final token = await SecureStorageService.getAccessToken();
    request.headers['Accept'] = 'application/json';
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    } else {
      request.headers.remove('Authorization');
    }
    final streamed = await request.send().timeout(ApiConstants.requestTimeout);
    final response = await http.Response.fromStream(streamed);
    if (_isUnauthorized(response)) {
      await _handleAuthFailure();
    }
    return response;
  }

  Map<String, dynamic> _decodeBody(String body) {
    if (_looksLikeHtml(body)) {
      return <String, dynamic>{
        'success': false,
        'message': 'Server returned HTML instead of JSON',
        'isHtml': true,
      };
    }
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return <String, dynamic>{'success': true, 'data': decoded};
    } catch (_) {
      return <String, dynamic>{
        'success': false,
        'message': 'Server returned non-JSON response',
        'raw': body,
      };
    }
  }

  ApiResponse<Map<String, dynamic>> _mapResponse(
    http.Response response, {
    String? successMessage,
    String? failureMessage,
  }) {
    final decoded = _decodeBody(response.body);
    final success =
        !((decoded['isHtml'] == true)) &&
        (response.statusCode == 200 ||
            response.statusCode == 201 ||
            decoded['success'] == true);
    return ApiResponse<Map<String, dynamic>>(
      success: success,
      message:
          decoded['message']?.toString() ??
          (success ? successMessage : failureMessage),
      data: decoded['data'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(decoded['data'] as Map)
          : decoded,
      errors: decoded['errors'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(decoded['errors'] as Map)
          : null,
    );
  }

  Uri _uri(String endpoint, Map<String, String> query) {
    return Uri.parse(endpoint).replace(queryParameters: query);
  }

  Future<Map<String, String>> _requiredQuery({
    int? roleId,
    bool includeUserId = true,
  }) async {
    final state = await _authState();
    final resolvedRoleId = state.roleId ?? roleId ?? _defaultRoleId;
    final query = <String, String>{'role_id': resolvedRoleId.toString()};
    if (includeUserId) {
      if (state.userId == null) {
        throw Exception('Missing user_id. Please log in again.');
      }
      query['user_id'] = state.userId.toString();
    }
    return query;
  }

  String _replaceId(String template, String id) {
    final normalized = id.trim().replaceFirst(RegExp(r'^#'), '');
    if (normalized.isEmpty) {
      throw Exception('Invalid id: $id');
    }
    return template.replaceAll('{id}', normalized);
  }

  Map<String, dynamic> _extractPrimaryMap(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      if (decoded['data'] is Map<String, dynamic>) {
        return Map<String, dynamic>.from(decoded['data'] as Map);
      }
      if (decoded['profile'] is Map<String, dynamic>) {
        return Map<String, dynamic>.from(decoded['profile'] as Map);
      }
      return decoded;
    }
    return <String, dynamic>{'data': decoded};
  }

  List<Map<String, dynamic>> _extractList(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      final candidates = <dynamic>[
        decoded['data'],
        decoded['orders'],
        decoded['return_orders'],
        decoded['requests'],
        decoded['items'],
      ];
      for (final candidate in candidates) {
        if (candidate is List) {
          return candidate
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        }
      }
    }
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return const <Map<String, dynamic>>[];
  }

  Future<Map<String, dynamic>> fetchDashboard() async {
    final validation = await _validateAuthState();
    if (validation != null) {
      throw Exception(validation.message);
    }
    final query = await _requiredQuery(roleId: _defaultRoleId);
    final response =
        await _performAuthenticatedGet(_uri(ApiConstants.dashboard, query));
    if (response.statusCode != 200) {
      throw Exception('Failed to load dashboard: ${response.statusCode}');
    }
    return _extractPrimaryMap(_decodeBody(response.body));
  }

  Future<ApiResponse<Map<String, dynamic>>> signupDeliveryMan({
    required String name,
    required String phone,
    required String email,
    required String dob,
    required String gender,
    required String address1,
    required String address2,
    required String city,
    required String state,
    required String country,
    required String pincode,
    required String aadharNumber,
    required XFile aadharFrontFile,
    required XFile aadharBackFile,
    required String panNumber,
    required XFile panFrontFile,
    required XFile panBackFile,
    required String vehicleType,
    required String vehicleNumber,
    required String drivingLicenseNo,
    required XFile drivingLicenseFrontFile,
    required XFile drivingLicenseBackFile,
    int roleId = _defaultRoleId,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse(ApiConstants.signup));
    request.fields.addAll(<String, String>{
      'role_id': roleId.toString(),
      'name': name.trim(),
      'phone': phone.trim(),
      'email': email.trim(),
      'dob': dob.trim(),
      'gender': gender.trim(),
      'address1': address1.trim(),
      'address2': address2.trim(),
      'city': city.trim(),
      'state': state.trim(),
      'country': country.trim(),
      'pincode': pincode.trim(),
      'aadhar_number': aadharNumber.trim(),
      'pan_number': panNumber.trim(),
      'vehicle_type': vehicleType.trim(),
      'vehicle_number': vehicleNumber.trim(),
      'driving_license_no': drivingLicenseNo.trim(),
    });
    request.files.add(
      await http.MultipartFile.fromPath(
        'aadhar_front_path',
        aadharFrontFile.path,
      ),
    );
    request.files.add(
      await http.MultipartFile.fromPath(
        'aadhar_back_path',
        aadharBackFile.path,
      ),
    );
    request.files.add(
      await http.MultipartFile.fromPath('pan_card_front_path', panFrontFile.path),
    );
    request.files.add(
      await http.MultipartFile.fromPath('pan_card_back_path', panBackFile.path),
    );
    request.files.add(
      await http.MultipartFile.fromPath(
        'driving_license_front_path',
        drivingLicenseFrontFile.path,
      ),
    );
    request.files.add(
      await http.MultipartFile.fromPath(
        'driving_license_back_path',
        drivingLicenseBackFile.path,
      ),
    );
    final streamed = await request.send().timeout(ApiConstants.requestTimeout);
    final response = await http.Response.fromStream(streamed);
    return _mapResponse(
      response,
      successMessage: 'Signup successful.',
      failureMessage: 'Failed to complete signup.',
    );
  }

  Future<List<Map<String, dynamic>>> fetchOrders() async {
    final validation = await _validateAuthState();
    if (validation != null) {
      throw Exception(validation.message);
    }
    final response = await _performAuthenticatedGet(
      _uri(ApiConstants.deliveryManOrders, await _requiredQuery(roleId: 2)),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load orders: ${response.statusCode}');
    }
    return _extractList(_decodeBody(response.body));
  }

  Future<Map<String, dynamic>> fetchOrderDetail(String orderId) async {
    final response = await _performAuthenticatedGet(
      _uri(
        _replaceId(ApiConstants.deliveryManOrderDetail, orderId),
        await _requiredQuery(roleId: 2),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load order detail: ${response.statusCode}');
    }
    return _extractPrimaryMap(_decodeBody(response.body));
  }

  Future<List<Map<String, dynamic>>> fetchReturnOrders() async {
    final response = await _performAuthenticatedGet(
      _uri(ApiConstants.deliveryManReturnOrders, await _requiredQuery(roleId: 2)),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load return orders: ${response.statusCode}');
    }
    return _extractList(_decodeBody(response.body));
  }

  Future<Map<String, dynamic>> fetchReturnOrderDetail(String orderId) async {
    final response = await _performAuthenticatedGet(
      _uri(
        _replaceId(ApiConstants.deliveryManReturnOrderDetail, orderId),
        await _requiredQuery(roleId: 2),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load return order details: ${response.statusCode}',
      );
    }
    return _extractPrimaryMap(_decodeBody(response.body));
  }

  Future<ApiResponse<Map<String, dynamic>>> acceptReturnOrder(
    String orderId,
  ) async {
    final response = await _performAuthenticatedPost(
      _uri(
        _replaceId(ApiConstants.deliveryManAcceptReturnOrder, orderId),
        await _requiredQuery(roleId: 2),
      ),
    );
    return _mapResponse(
      response,
      successMessage: 'Return order accepted successfully.',
      failureMessage: 'Failed to accept return order.',
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> sendReturnOrderOtp(
    String orderId,
  ) async {
    final response = await _performAuthenticatedPost(
      _uri(
        _replaceId(ApiConstants.deliveryManSendReturnOrderOtp, orderId),
        await _requiredQuery(roleId: 2),
      ),
    );
    return _mapResponse(
      response,
      successMessage: 'OTP sent successfully.',
      failureMessage: 'Failed to send OTP.',
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> verifyReturnOrderOtp({
    required String orderId,
    required String otp,
  }) async {
    final query = await _requiredQuery(roleId: 2);
    query['otp'] = otp.trim();
    final response = await _performAuthenticatedPost(
      _uri(
        _replaceId(ApiConstants.deliveryManVerifyReturnOrderOtp, orderId),
        query,
      ),
    );
    return _mapResponse(
      response,
      successMessage: 'OTP verified successfully.',
      failureMessage: 'Failed to verify OTP.',
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> markReturnOrderPicked(
    String orderId,
  ) async {
    final response = await _performAuthenticatedGet(
      _uri(
        _replaceId(ApiConstants.deliveryManReturnOrderPicked, orderId),
        await _requiredQuery(roleId: 2),
      ),
    );
    return _mapResponse(
      response,
      successMessage: 'Return order picked successfully.',
      failureMessage: 'Failed to update return order.',
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> acceptOrder(String orderId) async {
    final response = await _performAuthenticatedGet(
      _uri(
        _replaceId(ApiConstants.deliveryManAcceptOrder, orderId),
        await _requiredQuery(roleId: 2),
      ),
    );
    return _mapResponse(
      response,
      successMessage: 'Order accepted successfully.',
      failureMessage: 'Failed to accept order.',
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> sendOrderOtp(String orderId) async {
    final response = await _performAuthenticatedPost(
      _uri(
        _replaceId(ApiConstants.deliveryManSendOrderOtp, orderId),
        await _requiredQuery(roleId: 2),
      ),
    );
    return _mapResponse(
      response,
      successMessage: 'OTP sent successfully.',
      failureMessage: 'Failed to send OTP.',
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> verifyOrderOtp({
    required String orderId,
    required String otp,
  }) async {
    final query = await _requiredQuery(roleId: 2)
      ..['otp'] = otp.trim();
    final response = await _performAuthenticatedPost(
      _uri(_replaceId(ApiConstants.deliveryManVerifyOrderOtp, orderId), query),
      json: true,
      body: jsonEncode(<String, String>{'otp': otp.trim()}),
    );
    return _mapResponse(
      response,
      successMessage: 'OTP verified successfully.',
      failureMessage: 'Failed to verify OTP.',
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> uploadOrderSelfie({
    required String orderId,
    required XFile profileImage,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      _uri(
        _replaceId(ApiConstants.deliveryManUploadSelfie, orderId),
        await _requiredQuery(roleId: 2),
      ),
    );
    request.files.add(
      await http.MultipartFile.fromPath('profile', profileImage.path),
    );
    final response = await _performAuthenticatedMultipart(request);
    return _mapResponse(
      response,
      successMessage: 'Selfie uploaded successfully.',
      failureMessage: 'Failed to upload selfie.',
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> markOrderDelivered(
    String orderId,
  ) async {
    final response = await _performAuthenticatedGet(
      _uri(
        _replaceId(ApiConstants.deliveryManDeliveredOrder, orderId),
        await _requiredQuery(roleId: 2),
      ),
    );
    return _mapResponse(
      response,
      successMessage: 'Order marked as delivered.',
      failureMessage: 'Failed to mark order delivered.',
    );
  }

  Future<Map<String, dynamic>> fetchProfile() async {
    final response = await _performAuthenticatedGet(
      _uri(ApiConstants.profile_page, await _requiredQuery(roleId: 2)),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load profile: ${response.statusCode}');
    }
    final profile = _extractPrimaryMap(_decodeBody(response.body));
    await SecureStorageService.saveUserProfile(profile);
    return profile;
  }

  Future<ApiResponse<Map<String, dynamic>>> updateProfile({
    required Map<String, dynamic> fields,
  }) async {
    final response = await _performAuthenticatedPut(
      _uri(ApiConstants.profile_page, await _requiredQuery(roleId: 2)),
      json: true,
      body: jsonEncode(fields),
    );
    final mapped = _mapResponse(
      response,
      successMessage: 'Profile updated successfully.',
      failureMessage: 'Failed to update profile.',
    );
    if (mapped.success && mapped.data != null) {
      await SecureStorageService.saveUserProfile(mapped.data!);
    }
    return mapped;
  }

  Future<Map<String, dynamic>> fetchKycStatus() async {
    final response = await _performAuthenticatedGet(
      _uri(ApiConstants.deliveryManKycStatus, await _requiredQuery(roleId: 2)),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load KYC status: ${response.statusCode}');
    }
    return _extractPrimaryMap(_decodeBody(response.body));
  }

  Future<ApiResponse<Map<String, dynamic>>> submitKyc({
    required String name,
    required String email,
    required String phone,
    required String dob,
    required String documentType,
    required String documentNo,
    required File documentFile,
  }) async {
    final query = await _requiredQuery(roleId: 2);
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(ApiConstants.deliveryManKycSubmit),
    );
    request.fields.addAll(<String, String>{
      'role_id': query['role_id']!,
      'user_id': query['user_id']!,
      'name': name.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'dob': dob.trim(),
      'document_type': documentType.trim(),
      'document_no': documentNo.trim(),
    });
    request.files.add(
      await http.MultipartFile.fromPath('document_file', documentFile.path),
    );
    final response = await _performAuthenticatedMultipart(request);
    return _mapResponse(
      response,
      successMessage: 'KYC submitted successfully.',
      failureMessage: 'Failed to submit KYC.',
    );
  }

  Future<Map<String, dynamic>> fetchVehicleDetails() async {
    final response = await _performAuthenticatedGet(
      _uri(ApiConstants.registervehicle, await _requiredQuery(roleId: 2)),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load vehicle details: ${response.statusCode}');
    }
    return _extractPrimaryMap(_decodeBody(response.body));
  }

  Future<ApiResponse<Map<String, dynamic>>> registerVehicleDetails({
    required String vehicleType,
    required String vehicleNumber,
    required String drivingLicenseNo,
    required XFile frontFile,
    required XFile backFile,
  }) async {
    final query = await _requiredQuery(roleId: 2);
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(ApiConstants.registervehicle),
    );
    request.fields.addAll(<String, String>{
      'role_id': query['role_id']!,
      'user_id': query['user_id']!,
      'vehicle_type': vehicleType.trim(),
      'vehicle_number': vehicleNumber.trim(),
      'driving_license_no': drivingLicenseNo.trim(),
    });
    request.files.add(
      await http.MultipartFile.fromPath(
        'driving_license_front_path',
        frontFile.path,
      ),
    );
    request.files.add(
      await http.MultipartFile.fromPath(
        'driving_license_back_path',
        backFile.path,
      ),
    );
    final response = await _performAuthenticatedMultipart(request);
    return _mapResponse(
      response,
      successMessage: 'Vehicle registered successfully.',
      failureMessage: 'Failed to register vehicle.',
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> updateVehicleDetails({
    required String vehicleType,
    required String vehicleNumber,
    required String drivingLicenseNo,
    XFile? frontFile,
    XFile? backFile,
  }) async {
    final query = await _requiredQuery(roleId: 2);
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(ApiConstants.deliveryManUpdateVehicle),
    );
    request.fields.addAll(<String, String>{
      'role_id': query['role_id']!,
      'user_id': query['user_id']!,
      'vehicle_type': vehicleType.trim(),
      'vehicle_number': vehicleNumber.trim(),
      'driving_license_no': drivingLicenseNo.trim(),
      '_method': 'PUT',
    });
    if (frontFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'driving_license_front_path',
          frontFile.path,
        ),
      );
    }
    if (backFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'driving_license_back_path',
          backFile.path,
        ),
      );
    }
    final response = await _performAuthenticatedMultipart(request);
    return _mapResponse(
      response,
      successMessage: 'Vehicle details updated successfully.',
      failureMessage: 'Failed to update vehicle details.',
    );
  }

  Future<Map<String, dynamic>> fetchAadharDetails() async {
    final response = await _performAuthenticatedGet(
      _uri(ApiConstants.deliveryManAadhar, await _requiredQuery(roleId: 2)),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load Aadhaar details: ${response.statusCode}');
    }
    return _extractPrimaryMap(_decodeBody(response.body));
  }

  Future<ApiResponse<Map<String, dynamic>>> saveAadharDetails({
    required String aadharNumber,
    XFile? frontFile,
    XFile? backFile,
    bool isUpdate = false,
  }) async {
    final query = await _requiredQuery(roleId: 2);
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(
        isUpdate
            ? ApiConstants.deliveryManUpdateAadhar
            : ApiConstants.deliveryManStoreAadhar,
      ),
    );
    request.fields.addAll(<String, String>{
      'role_id': query['role_id']!,
      'user_id': query['user_id']!,
      'aadhar_number': aadharNumber.trim(),
      if (isUpdate) '_method': 'PUT',
    });
    if (frontFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('aadhar_front_path', frontFile.path),
      );
    }
    if (backFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('aadhar_back_path', backFile.path),
      );
    }
    final response = await _performAuthenticatedMultipart(request);
    return _mapResponse(
      response,
      successMessage: isUpdate
          ? 'Aadhaar updated successfully.'
          : 'Aadhaar saved successfully.',
      failureMessage: isUpdate
          ? 'Failed to update Aadhaar.'
          : 'Failed to save Aadhaar.',
    );
  }

  Future<Map<String, dynamic>> fetchPanDetails() async {
    final response = await _performAuthenticatedGet(
      _uri(ApiConstants.deliveryManPanCard, await _requiredQuery(roleId: 2)),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load PAN details: ${response.statusCode}');
    }
    return _extractPrimaryMap(_decodeBody(response.body));
  }

  Future<ApiResponse<Map<String, dynamic>>> savePanDetails({
    required String panNumber,
    XFile? frontFile,
    XFile? backFile,
    bool isUpdate = false,
  }) async {
    if (isUpdate) {
      final query = await _requiredQuery(roleId: 2);
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConstants.deliveryManUpdatePanCard),
      );
      request.fields.addAll(<String, String>{
        'role_id': query['role_id']!,
        'user_id': query['user_id']!,
        'pan_number': panNumber.trim(),
        '_method': 'PUT',
      });
      if (frontFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'pan_card_front_path',
            frontFile.path,
          ),
        );
      }
      if (backFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'pan_card_back_path',
            backFile.path,
          ),
        );
      }
      final response = await _performAuthenticatedMultipart(request);
      return _mapResponse(
        response,
        successMessage: 'PAN updated successfully.',
        failureMessage: 'Failed to update PAN.',
      );
    }

    final query = await _requiredQuery(roleId: 2);
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(ApiConstants.deliveryManStorePanCard),
    );
    request.fields.addAll(<String, String>{
      'role_id': query['role_id']!,
      'user_id': query['user_id']!,
      'pan_number': panNumber.trim(),
    });
    if (frontFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'pan_card_front_path',
          frontFile.path,
        ),
      );
    }
    if (backFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'pan_card_back_path',
          backFile.path,
        ),
      );
    }
    final response = await _performAuthenticatedMultipart(request);
    return _mapResponse(
      response,
      successMessage: 'PAN saved successfully.',
      failureMessage: 'Failed to save PAN.',
    );
  }

  Future<Map<String, dynamic>> fetchAttendance() async {
    final response = await _performAuthenticatedGet(
      _uri(ApiConstants.deliveryManAttendance, await _requiredQuery(roleId: 2)),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load attendance: ${response.statusCode}');
    }
    return _extractPrimaryMap(_decodeBody(response.body));
  }

  Future<ApiResponse<Map<String, dynamic>>> attendanceLogin() async {
    final response = await _performAuthenticatedPost(
      _uri(
        ApiConstants.deliveryManAttendanceLogin,
        await _requiredQuery(roleId: 2),
      ),
    );
    return _mapResponse(
      response,
      successMessage: 'Check-in successful.',
      failureMessage: 'Failed to check in.',
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> attendanceLogout() async {
    final response = await _performAuthenticatedPost(
      _uri(
        ApiConstants.deliveryManAttendanceLogout,
        await _requiredQuery(roleId: 2),
      ),
    );
    return _mapResponse(
      response,
      successMessage: 'Check-out successful.',
      failureMessage: 'Failed to check out.',
    );
  }

  Future<List<Map<String, dynamic>>> fetchServiceRequests({
    required String requestType,
  }) {
    return ApiService.fetchDeliveryRequests(
      deliveryType: requestType,
      roleId: _defaultRoleId,
    );
  }

  Future<Map<String, dynamic>> fetchServiceRequestDetail({
    required String requestType,
    required String requestId,
  }) {
    return ApiService.fetchDeliveryRequestDetail(
      deliveryType: requestType,
      deliveryId: requestId,
      roleId: _defaultRoleId,
    );
  }

  Future<ApiResponse> acceptServiceRequest({
    required String requestType,
    required String requestId,
  }) {
    return ApiService.acceptDeliveryRequest(
      deliveryType: requestType,
      deliveryId: requestId,
      roleId: _defaultRoleId,
    );
  }

  Future<ApiResponse> sendServiceRequestOtp({
    required String requestType,
    required String requestId,
  }) {
    return ApiService.sendDeliveryRequestOtp(
      deliveryType: requestType,
      deliveryId: requestId,
      roleId: _defaultRoleId,
    );
  }

  Future<ApiResponse> verifyServiceRequestOtp({
    required String requestType,
    required String requestId,
    required String otp,
  }) {
    return ApiService.verifyDeliveryRequestOtp(
      deliveryType: requestType,
      deliveryId: requestId,
      otp: otp,
      roleId: _defaultRoleId,
    );
  }
}

class _DeliveryAuthState {
  final int? userId;
  final int? roleId;
  final String? accessToken;

  const _DeliveryAuthState({
    required this.userId,
    required this.roleId,
    required this.accessToken,
  });
}
