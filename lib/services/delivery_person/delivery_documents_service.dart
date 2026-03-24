import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../constants/api_constants.dart';
import '../../model/api_response.dart';
import 'delivery_api_client.dart';

class DeliveryDocumentsService extends DeliveryApiClient {
  Future<Map<String, dynamic>> fetchAadharDetails() async {
    final response = await performAuthenticatedGet(
      buildUri(ApiConstants.deliveryManAadhar, await requiredQuery(roleId: 2)),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load Aadhaar details: ${response.statusCode}');
    }
    return extractPrimaryMap(decodeBody(response.body));
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

  Future<ApiResponse<Map<String, dynamic>>> saveAadharDetails({
    required String aadharNumber,
    XFile? frontFile,
    XFile? backFile,
    required bool isUpdate,
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

  Future<ApiResponse<Map<String, dynamic>>> savePanDetails({
    required String panNumber,
    XFile? frontFile,
    XFile? backFile,
    required bool isUpdate,
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
}
