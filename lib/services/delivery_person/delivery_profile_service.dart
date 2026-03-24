import 'dart:convert';

import '../../constants/api_constants.dart';
import '../../core/secure_storage_service.dart';
import '../../model/api_response.dart';
import 'delivery_api_client.dart';

class DeliveryProfileService extends DeliveryApiClient {
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
}
