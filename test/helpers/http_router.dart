import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

typedef RequestHandler = Future<http.Response> Function(http.Request request);

/// Build a [MockClient] that routes requests by `"$METHOD $path"`.
///
/// Example key: `"GET /api/v1/leads"`.
MockClient buildMockClient(Map<String, RequestHandler> routes) {
  return MockClient((http.Request request) async {
    final key = '${request.method.toUpperCase()} ${request.url.path}';
    final handler = routes[key];
    if (handler == null) {
      return http.Response(
        jsonEncode(<String, Object?>{
          'success': false,
          'message': 'Unhandled request in tests: $key',
        }),
        500,
        headers: const <String, String>{'content-type': 'application/json'},
      );
    }
    return handler(request);
  });
}

