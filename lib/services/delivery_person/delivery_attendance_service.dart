import '../../constants/api_constants.dart';
import '../../model/api_response.dart';
import 'delivery_api_client.dart';

class DeliveryAttendanceService extends DeliveryApiClient {
  Future<Map<String, dynamic>> fetchAttendance() async {
    final response = await performAuthenticatedGet(
      buildUri(
        ApiConstants.deliveryManAttendance,
        await requiredQuery(roleId: 2),
      ),
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
}
