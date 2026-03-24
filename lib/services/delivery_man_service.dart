import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../constants/api_constants.dart';
import '../core/secure_storage_service.dart';
import '../model/api_response.dart';
import 'delivery_person/delivery_api_client.dart';
import 'api_service.dart';

class DeliveryManService extends DeliveryApiClient {
  DeliveryManService._();

  static final DeliveryManService instance = DeliveryManService._();

  static const int _defaultRoleId = 2;

  Future<Map<String, dynamic>> fetchDashboard() async {
    final validation = await validateAuthState();
    if (validation != null) {
      throw Exception(validation.message);
    }
    final query = await requiredQuery(roleId: _defaultRoleId);
    final response =
        await performAuthenticatedGet(buildUri(ApiConstants.dashboard, query));
    if (response.statusCode != 200) {
      throw Exception('Failed to load dashboard: ${response.statusCode}');
    }
    return extractPrimaryMap(decodeBody(response.body));
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
    return mapResponse(
      response,
      successMessage: 'Signup successful.',
      failureMessage: 'Failed to complete signup.',
    );
  }

  Future<List<Map<String, dynamic>>> fetchOrders() async {
    final validation = await validateAuthState();
    if (validation != null) {
      throw Exception(validation.message);
    }
    final response = await performAuthenticatedGet(
      buildUri(ApiConstants.deliveryManOrders, await requiredQuery(roleId: 2)),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load orders: ${response.statusCode}');
    }
    return extractList(decodeBody(response.body));
  }

  Future<Map<String, dynamic>> fetchOrderDetail(String orderId) async {
    final response = await performAuthenticatedGet(
      buildUri(
        replaceId(ApiConstants.deliveryManOrderDetail, orderId),
        await requiredQuery(roleId: 2),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load order detail: ${response.statusCode}');
    }
    return extractPrimaryMap(decodeBody(response.body));
  }

  Future<List<Map<String, dynamic>>> fetchReturnOrders() async {
    final response = await performAuthenticatedGet(
      buildUri(ApiConstants.deliveryManReturnOrders, await requiredQuery(roleId: 2)),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load return orders: ${response.statusCode}');
    }
    return extractList(decodeBody(response.body));
  }

  Future<Map<String, dynamic>> fetchReturnOrderDetail(String orderId) async {
    final response = await performAuthenticatedGet(
      buildUri(
        replaceId(ApiConstants.deliveryManReturnOrderDetail, orderId),
        await requiredQuery(roleId: 2),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load return order details: ${response.statusCode}',
      );
    }
    return extractPrimaryMap(decodeBody(response.body));
  }

  Future<ApiResponse<Map<String, dynamic>>> acceptReturnOrder(
    String orderId,
  ) async {
    final response = await performAuthenticatedPost(
      buildUri(
        replaceId(ApiConstants.deliveryManAcceptReturnOrder, orderId),
        await requiredQuery(roleId: 2),
      ),
    );
    return mapResponse(
      response,
      successMessage: 'Return order accepted successfully.',
      failureMessage: 'Failed to accept return order.',
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> sendReturnOrderOtp(
    String orderId,
  ) async {
    final response = await performAuthenticatedPost(
      buildUri(
        replaceId(ApiConstants.deliveryManSendReturnOrderOtp, orderId),
        await requiredQuery(roleId: 2),
      ),
    );
    return mapResponse(
      response,
      successMessage: 'OTP sent successfully.',
      failureMessage: 'Failed to send OTP.',
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> verifyReturnOrderOtp({
    required String orderId,
    required String otp,
  }) async {
    final query = await requiredQuery(roleId: 2);
    query['otp'] = otp.trim();
    final response = await performAuthenticatedPost(
      buildUri(
        replaceId(ApiConstants.deliveryManVerifyReturnOrderOtp, orderId),
        query,
      ),
    );
    return mapResponse(
      response,
      successMessage: 'OTP verified successfully.',
      failureMessage: 'Failed to verify OTP.',
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> markReturnOrderPicked(
    String orderId,
  ) async {
    final response = await performAuthenticatedGet(
      buildUri(
        replaceId(ApiConstants.deliveryManReturnOrderPicked, orderId),
        await requiredQuery(roleId: 2),
      ),
    );
    return mapResponse(
      response,
      successMessage: 'Return order picked successfully.',
      failureMessage: 'Failed to update return order.',
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> acceptOrder(String orderId) async {
    final response = await performAuthenticatedGet(
      buildUri(
        replaceId(ApiConstants.deliveryManAcceptOrder, orderId),
        await requiredQuery(roleId: 2),
      ),
    );
    return mapResponse(
      response,
      successMessage: 'Order accepted successfully.',
      failureMessage: 'Failed to accept order.',
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> sendOrderOtp(String orderId) async {
    final response = await performAuthenticatedPost(
      buildUri(
        replaceId(ApiConstants.deliveryManSendOrderOtp, orderId),
        await requiredQuery(roleId: 2),
      ),
    );
    return mapResponse(
      response,
      successMessage: 'OTP sent successfully.',
      failureMessage: 'Failed to send OTP.',
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> verifyOrderOtp({
    required String orderId,
    required String otp,
  }) async {
    final query = await requiredQuery(roleId: 2)
      ..['otp'] = otp.trim();
    final response = await performAuthenticatedPost(
      buildUri(replaceId(ApiConstants.deliveryManVerifyOrderOtp, orderId), query),
      json: true,
      body: jsonEncode(<String, String>{'otp': otp.trim()}),
    );
    return mapResponse(
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
      buildUri(
        replaceId(ApiConstants.deliveryManUploadSelfie, orderId),
        await requiredQuery(roleId: 2),
      ),
    );
    request.files.add(
      await http.MultipartFile.fromPath('profile', profileImage.path),
    );
    final response = await performAuthenticatedMultipart(request);
    return mapResponse(
      response,
      successMessage: 'Selfie uploaded successfully.',
      failureMessage: 'Failed to upload selfie.',
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> markOrderDelivered(
    String orderId,
  ) async {
    final response = await performAuthenticatedGet(
      buildUri(
        replaceId(ApiConstants.deliveryManDeliveredOrder, orderId),
        await requiredQuery(roleId: 2),
      ),
    );
    return mapResponse(
      response,
      successMessage: 'Order marked as delivered.',
      failureMessage: 'Failed to mark order delivered.',
    );
  }

  Future<Map<String, dynamic>> fetchProfile() async {
    final response = await performAuthenticatedGet(
      buildUri(ApiConstants.profile_page, await requiredQuery(roleId: 2)),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load profile: ${response.statusCode}');
    }
    final profile = extractPrimaryMap(decodeBody(response.body));
    await SecureStorageService.saveUserProfile(profile);
    return profile;
  }

  Future<ApiResponse<Map<String, dynamic>>> updateProfile({
    required Map<String, dynamic> fields,
  }) async {
    final response = await performAuthenticatedPut(
      buildUri(ApiConstants.profile_page, await requiredQuery(roleId: 2)),
      json: true,
      body: jsonEncode(fields),
    );
    final mapped = mapResponse(
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
    final response = await performAuthenticatedGet(
      buildUri(ApiConstants.deliveryManKycStatus, await requiredQuery(roleId: 2)),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load KYC status: ${response.statusCode}');
    }
    return extractPrimaryMap(decodeBody(response.body));
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
    final query = await requiredQuery(roleId: 2);
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
    final response = await performAuthenticatedMultipart(request);
    return mapResponse(
      response,
      successMessage: 'KYC submitted successfully.',
      failureMessage: 'Failed to submit KYC.',
    );
  }

  Future<Map<String, dynamic>> fetchVehicleDetails() async {
    final response = await performAuthenticatedGet(
      buildUri(ApiConstants.registervehicle, await requiredQuery(roleId: 2)),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load vehicle details: ${response.statusCode}');
    }
    return extractPrimaryMap(decodeBody(response.body));
  }

  Future<ApiResponse<Map<String, dynamic>>> registerVehicleDetails({
    required String vehicleType,
    required String vehicleNumber,
    required String drivingLicenseNo,
    required XFile frontFile,
    required XFile backFile,
  }) async {
    final query = await requiredQuery(roleId: 2);
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
    final response = await performAuthenticatedMultipart(request);
    return mapResponse(
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
    final query = await requiredQuery(roleId: 2);
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
    final response = await performAuthenticatedMultipart(request);
    return mapResponse(
      response,
      successMessage: 'Vehicle details updated successfully.',
      failureMessage: 'Failed to update vehicle details.',
    );
  }

  Future<Map<String, dynamic>> fetchAadharDetails() async {
    final response = await performAuthenticatedGet(
      buildUri(ApiConstants.deliveryManAadhar, await requiredQuery(roleId: 2)),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load Aadhaar details: ${response.statusCode}');
    }
    return extractPrimaryMap(decodeBody(response.body));
  }

  Future<ApiResponse<Map<String, dynamic>>> saveAadharDetails({
    required String aadharNumber,
    XFile? frontFile,
    XFile? backFile,
    bool isUpdate = false,
  }) async {
    final query = await requiredQuery(roleId: 2);
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
    final response = await performAuthenticatedMultipart(request);
    return mapResponse(
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
    final response = await performAuthenticatedGet(
      buildUri(ApiConstants.deliveryManPanCard, await requiredQuery(roleId: 2)),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load PAN details: ${response.statusCode}');
    }
    return extractPrimaryMap(decodeBody(response.body));
  }

  Future<ApiResponse<Map<String, dynamic>>> savePanDetails({
    required String panNumber,
    XFile? frontFile,
    XFile? backFile,
    bool isUpdate = false,
  }) async {
    if (isUpdate) {
      final query = await requiredQuery(roleId: 2);
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
      final response = await performAuthenticatedMultipart(request);
      return mapResponse(
        response,
        successMessage: 'PAN updated successfully.',
        failureMessage: 'Failed to update PAN.',
      );
    }

    final query = await requiredQuery(roleId: 2);
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
    final response = await performAuthenticatedMultipart(request);
    return mapResponse(
      response,
      successMessage: 'PAN saved successfully.',
      failureMessage: 'Failed to save PAN.',
    );
  }

  Future<Map<String, dynamic>> fetchAttendance() async {
    final response = await performAuthenticatedGet(
      buildUri(ApiConstants.deliveryManAttendance, await requiredQuery(roleId: 2)),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load attendance: ${response.statusCode}');
    }
    return extractPrimaryMap(decodeBody(response.body));
  }

  Future<ApiResponse<Map<String, dynamic>>> attendanceLogin() async {
    final response = await performAuthenticatedPost(
      buildUri(
        ApiConstants.deliveryManAttendanceLogin,
        await requiredQuery(roleId: 2),
      ),
    );
    return mapResponse(
      response,
      successMessage: 'Check-in successful.',
      failureMessage: 'Failed to check in.',
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> attendanceLogout() async {
    final response = await performAuthenticatedPost(
      buildUri(
        ApiConstants.deliveryManAttendanceLogout,
        await requiredQuery(roleId: 2),
      ),
    );
    return mapResponse(
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
