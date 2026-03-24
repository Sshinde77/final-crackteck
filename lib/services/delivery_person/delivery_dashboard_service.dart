import '../../constants/api_constants.dart';
import 'delivery_api_client.dart';

class DeliveryDashboardService extends DeliveryApiClient {
  Future<Map<String, dynamic>> fetchDashboard() async {
    final validation = await validateAuthState();
    if (validation != null) {
      throw Exception(validation.message);
    }
    final response = await performAuthenticatedGet(
      buildUri(ApiConstants.dashboard, await requiredQuery(roleId: 2)),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load dashboard: ${response.statusCode}');
    }
    return extractPrimaryMap(decodeBody(response.body));
  }
}
