import '../../constants/api_constants.dart';
import 'delivery_api_client.dart';

class DeliveryTrackWorkService extends DeliveryApiClient {
  Future<Map<String, dynamic>> fetchTrackYourWork() async {
    final validation = await validateAuthState();
    if (validation != null) {
      throw Exception(validation.message);
    }
    final response = await performAuthenticatedGet(
      buildUri(ApiConstants.trackyourwork, await requiredQuery(roleId: 2)),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load track your work: ${response.statusCode}');
    }
    return decodeBody(response.body);
  }
}
