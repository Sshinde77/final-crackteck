import 'package:flutter/foundation.dart';

import '../../constants/api_constants.dart';
import '../../model/api_response.dart';
import 'delivery_api_client.dart';

class DeliveryAttendanceService extends DeliveryApiClient {
  Future<Map<String, dynamic>> fetchAttendance() async {
    final uri = buildUri(
      ApiConstants.deliveryManAttendance,
      await requiredQuery(roleId: 2),
    );
    debugPrint('DeliveryAttendance API Request: GET $uri');
    final response = await performAuthenticatedGet(
      uri,
    );
    debugPrint(
      'DeliveryAttendance API Response: ${response.statusCode} ${response.body}',
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load attendance: ${response.statusCode}');
    }
    return extractPrimaryMap(decodeBody(response.body));
  }

  Future<List<Map<String, dynamic>>> fetchAttendanceLogs() async {
    final uri = buildUri(
      ApiConstants.deliveryManAttendance,
      await requiredQuery(roleId: 2),
    );
    debugPrint('DeliveryAttendance Logs API Request: GET $uri');
    final response = await performAuthenticatedGet(
      uri,
    );
    debugPrint(
      'DeliveryAttendance Logs API Response: ${response.statusCode} ${response.body}',
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load attendance: ${response.statusCode}');
    }

    final decoded = decodeBody(response.body);
    final extracted = extractList(decoded);
    if (extracted.isNotEmpty) {
      return extracted;
    }

    final primary = extractPrimaryMap(decoded);
    if (primary.isEmpty) {
      return const <Map<String, dynamic>>[];
    }

    if (primary['auth_log'] is Map<String, dynamic>) {
      return <Map<String, dynamic>>[
        Map<String, dynamic>.from(primary['auth_log'] as Map<String, dynamic>),
      ];
    }

    return <Map<String, dynamic>>[primary];
  }

  Future<ApiResponse<Map<String, dynamic>>> attendanceLogin() async {
    final uri = buildUri(
      ApiConstants.deliveryManAttendanceLogin,
      await requiredQuery(roleId: 2),
    );
    debugPrint('DeliveryAttendance Login API Request: POST $uri');
    final response = await performAuthenticatedPost(
      uri,
    );
    debugPrint(
      'DeliveryAttendance Login API Response: ${response.statusCode} ${response.body}',
    );
    return mapResponse(
      response,
      successMessage: 'Check-in successful.',
      failureMessage: 'Failed to check in.',
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> attendanceLogout() async {
    final uri = buildUri(
      ApiConstants.deliveryManAttendanceLogout,
      await requiredQuery(roleId: 2),
    );
    debugPrint('DeliveryAttendance Logout API Request: POST $uri');
    final response = await performAuthenticatedPost(
      uri,
    );
    debugPrint(
      'DeliveryAttendance Logout API Response: ${response.statusCode} ${response.body}',
    );
    return mapResponse(
      response,
      successMessage: 'Check-out successful.',
      failureMessage: 'Failed to check out.',
    );
  }
}
