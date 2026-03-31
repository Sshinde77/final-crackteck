import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../constants/api_constants.dart';
import '../../core/network/api_http_client.dart';
import '../../model/api_response.dart';
import '../../model/signup/common_signup_request.dart';
import '../../model/signup/delivery_signup_request.dart';
import '../api_service.dart';
import 'delivery_api_client.dart';

class DeliverySignupService extends DeliveryApiClient {
  DeliverySignupService({ApiService? apiService})
    : _apiService = apiService ?? ApiService.instance;

  final ApiService _apiService;
  static final ApiHttpClient _httpClient = ApiHttpClient.instance;

  String _normalizeVehicleType(String value) {
    switch (value.trim().toLowerCase()) {
      case 'two wheeler':
      case '2 wheeler':
      case '2-wheeler':
      case 'bike':
      case 'two_wheeler':
        return 'two_wheeler';
      case 'four wheeler':
      case '4 wheeler':
      case '4-wheeler':
      case 'car':
      case 'four_wheeler':
        return 'four_wheeler';
      default:
        return value.trim();
    }
  }

  Future<ApiResponse> submitCommon(CommonSignupRequest request) {
    return _apiService.signup(
      roleId: request.roleId,
      name: request.name,
      phone: request.phone,
      email: request.email,
      dob: request.dob,
      gender: request.gender,
      address: request.address,
      aadhar: request.aadhar,
      pan: request.pan,
      aadharFile: request.aadharFile,
      panFile: request.panFile,
      firstName: request.firstName,
      lastName: request.lastName,
      addressLine1: request.addressLine1,
      addressLine2: request.addressLine2,
      country: request.country,
      state: request.state,
      city: request.city,
      pincode: request.pincode,
      aadharBackFile: request.aadharBackFile,
      panBackFile: request.panBackFile,
      drivingLicenceNumber: null,
      licenceFrontFile: null,
      licenceBackFile: null,
      education: request.education,
      resultFile: request.resultFile,
      addressProofFile: request.addressProofFile,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> submitDelivery(
    DeliverySignupRequest request,
  ) async {
    final vehicleType = _normalizeVehicleType(request.vehicleType);
    final signupRequest = http.MultipartRequest(
      'POST',
      Uri.parse(ApiConstants.signup),
    );
    signupRequest.fields.addAll(<String, String>{
      'role_id': request.roleId.toString(),
      'name': request.name.trim(),
      'phone': request.phone.trim(),
      'email': request.email.trim(),
      'dob': request.dob.trim(),
      'gender': request.gender.trim(),
      'address1': request.address1.trim(),
      'address2': request.address2.trim(),
      'city': request.city.trim(),
      'state': request.state.trim(),
      'country': request.country.trim(),
      'pincode': request.pincode.trim(),
      'aadhar_number': request.aadharNumber.trim(),
      'pan_number': request.panNumber.trim(),
      'vehicle_type': vehicleType,
      'vehicle_number': request.vehicleNumber.trim(),
      'driving_license_no': request.drivingLicenseNo.trim(),
      'education': request.education.trim(),
    });
    debugPrint('Delivery signup request fields: ${signupRequest.fields}');
    signupRequest.files.add(
      await http.MultipartFile.fromPath(
        'aadhar_front_path',
        request.aadharFrontFile.path,
      ),
    );
    signupRequest.files.add(
      await http.MultipartFile.fromPath(
        'aadhar_back_path',
        request.aadharBackFile.path,
      ),
    );
    signupRequest.files.add(
      await http.MultipartFile.fromPath(
        'pan_card_front_path',
        request.panFrontFile.path,
      ),
    );
    signupRequest.files.add(
      await http.MultipartFile.fromPath(
        'pan_card_back_path',
        request.panBackFile.path,
      ),
    );
    signupRequest.files.add(
      await http.MultipartFile.fromPath(
        'driving_license_front_path',
        request.drivingLicenseFrontFile.path,
      ),
    );
    signupRequest.files.add(
      await http.MultipartFile.fromPath(
        'driving_license_back_path',
        request.drivingLicenseBackFile.path,
      ),
    );
    signupRequest.files.add(
      await http.MultipartFile.fromPath('result_file', request.resultFile.path),
    );
    debugPrint(
      'Delivery signup files: ${signupRequest.files.map((file) => '${file.field}=${file.filename}').join(', ')}',
    );
    final response = await _httpClient.sendMultipart(signupRequest);
    debugPrint('Delivery signup status: ${response.statusCode}');
    debugPrint('Delivery signup raw response: ${response.body}');
    return mapResponse(
      response,
      successMessage: 'Signup successful.',
      failureMessage: 'Failed to complete signup.',
    );
  }
}
