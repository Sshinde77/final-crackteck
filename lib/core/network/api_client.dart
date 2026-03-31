import 'dart:convert';

import 'api_http_client.dart';

class ApiClient {
  static final ApiHttpClient _httpClient = ApiHttpClient.instance;

  static Future<dynamic> get(String url, {String? token}) async {
    final response = await _httpClient.get(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("API Error ${response.statusCode}");
    }
  }
}
