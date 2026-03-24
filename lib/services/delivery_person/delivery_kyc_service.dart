import 'dart:io';

import 'package:http/http.dart' as http;

import '../../constants/api_constants.dart';
import '../../core/secure_storage_service.dart';
import '../../model/api_response.dart';
import 'delivery_api_client.dart';

class DeliveryKycService extends DeliveryApiClient {
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
}
