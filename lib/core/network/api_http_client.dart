import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../constants/api_constants.dart';
import 'api_logger.dart';

class ApiHttpClient extends http.BaseClient {
  ApiHttpClient._({http.Client? inner}) : _inner = inner ?? http.Client();

  static final ApiHttpClient _productionInstance = ApiHttpClient._();

  @visibleForTesting
  static ApiHttpClient? testInstance;

  static ApiHttpClient get instance => testInstance ?? _productionInstance;

  @visibleForTesting
  static void overrideForTesting(http.Client inner) {
    testInstance = ApiHttpClient._(inner: inner);
  }

  @visibleForTesting
  static void resetOverride() {
    testInstance = null;
  }

  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    request.headers.putIfAbsent('Accept', () => 'application/json');

    ApiLogger.logRequest(
      url: request.url,
      method: request.method,
      headers: request.headers,
      body: _extractBody(request),
    );

    try {
      final streamedResponse = await _inner
          .send(request)
          .timeout(ApiConstants.requestTimeout);
      final responseBytes = await streamedResponse.stream.toBytes();
      final responseBody = utf8.decode(responseBytes, allowMalformed: true);

      ApiLogger.logResponse(
        url: request.url,
        method: request.method,
        statusCode: streamedResponse.statusCode,
        headers: streamedResponse.headers,
        responseBody: responseBody,
      );

      return http.StreamedResponse(
        Stream<List<int>>.fromIterable(<List<int>>[responseBytes]),
        streamedResponse.statusCode,
        contentLength: responseBytes.length,
        request: streamedResponse.request,
        headers: streamedResponse.headers,
        isRedirect: streamedResponse.isRedirect,
        persistentConnection: streamedResponse.persistentConnection,
        reasonPhrase: streamedResponse.reasonPhrase,
      );
    } catch (error, stackTrace) {
      ApiLogger.logError(
        url: request.url,
        method: request.method,
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<http.Response> sendMultipart(http.MultipartRequest request) async {
    final streamedResponse = await send(request);
    return http.Response.fromStream(streamedResponse);
  }

  Object? _extractBody(http.BaseRequest request) {
    if (request is http.MultipartRequest) {
      return request;
    }
    if (request is http.Request) {
      return request.body.isNotEmpty ? request.body : request.bodyBytes;
    }
    return null;
  }
}
