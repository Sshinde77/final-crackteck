import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../constants/api_constants.dart';
import '../../model/api_response.dart';
import 'delivery_api_client.dart';

class DeliveryOrdersService extends DeliveryApiClient {
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

  Future<List<Map<String, dynamic>>> fetchPickupRequests() async {
    final validation = await validateAuthState();
    if (validation != null) {
      throw Exception(validation.message);
    }
    final response = await performAuthenticatedGet(
      buildUri(
        ApiConstants.deliverypickuprequestlist,
        await requiredQuery(roleId: 2),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load pickup requests: ${response.statusCode}',
      );
    }
    return extractList(decodeBody(response.body));
  }

  Future<List<Map<String, dynamic>>> fetchReturnRequests() async {
    final validation = await validateAuthState();
    if (validation != null) {
      throw Exception(validation.message);
    }
    final response = await performAuthenticatedGet(
      buildUri(
        ApiConstants.deliveryreturnrequestlist,
        await requiredQuery(roleId: 2),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load return requests: ${response.statusCode}',
      );
    }
    return extractList(decodeBody(response.body));
  }

  Future<List<Map<String, dynamic>>> fetchPartRequests() async {
    final validation = await validateAuthState();
    if (validation != null) {
      throw Exception(validation.message);
    }
    final response = await performAuthenticatedGet(
      buildUri(
        ApiConstants.deliverypartrequestlist,
        await requiredQuery(roleId: 2),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load part requests: ${response.statusCode}',
      );
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
    final query = await requiredQuery(roleId: 2)..['otp'] = otp.trim();
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

  Future<List<Map<String, dynamic>>> fetchReturnOrders() async {
    final response = await performAuthenticatedGet(
      buildUri(
        ApiConstants.deliveryManReturnOrders,
        await requiredQuery(roleId: 2),
      ),
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
    final query = await requiredQuery(roleId: 2)..['otp'] = otp.trim();
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
}
