import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiLogger {
  ApiLogger._();

  static const JsonEncoder _prettyEncoder = JsonEncoder.withIndent('  ');

  static void logRequest({
    required Uri url,
    required String method,
    Map<String, String>? headers,
    Object? body,
  }) {
    _writeBlock(<String>[
      '========== API REQUEST ==========',
      'URL: $url',
      'METHOD: ${method.toUpperCase()}',
      'HEADERS:',
      _formatJson(headers ?? const <String, String>{}),
      'BODY:',
      _formatBody(body),
      '=================================',
    ]);
  }

  static void logResponse({
    required Uri url,
    required String method,
    required int statusCode,
    Map<String, String>? headers,
    String? responseBody,
  }) {
    _writeBlock(<String>[
      '========== API RESPONSE =========',
      'URL: $url',
      'METHOD: ${method.toUpperCase()}',
      'STATUS CODE: $statusCode',
      'HEADERS:',
      _formatJson(headers ?? const <String, String>{}),
      'BODY:',
      _formatResponseBody(responseBody),
      '=================================',
    ]);
  }

  static void logError({
    Uri? url,
    String? method,
    required Object error,
    StackTrace? stackTrace,
  }) {
    _writeBlock(<String>[
      '=========== API ERROR ===========',
      if (url != null) 'URL: $url',
      if (method != null) 'METHOD: ${method.toUpperCase()}',
      'EXCEPTION:',
      error.toString(),
      if (stackTrace != null) 'STACK TRACE:',
      if (stackTrace != null) stackTrace.toString(),
      '=================================',
    ]);
  }

  static String describeMultipartRequest(http.MultipartRequest request) {
    final files = request.files
        .map(
          (file) => <String, dynamic>{
            'field': file.field,
            'filename': file.filename,
            'length': file.length,
            'contentType': file.contentType?.toString(),
          },
        )
        .toList();

    return _formatJson(<String, dynamic>{
      'fields': request.fields,
      'files': files,
    });
  }

  static String _formatBody(Object? body) {
    if (body == null) {
      return 'No body';
    }
    if (body is http.MultipartRequest) {
      return describeMultipartRequest(body);
    }
    if (body is String) {
      return _formatResponseBody(body);
    }
    return _formatJson(body);
  }

  static String _formatResponseBody(String? body) {
    if (body == null || body.trim().isEmpty) {
      return 'Empty response body';
    }

    final normalizedBody = body.trim();
    final lowerCasedBody = normalizedBody.toLowerCase();
    if (lowerCasedBody.startsWith('<!doctype html') ||
        lowerCasedBody.startsWith('<html')) {
      return 'HTML response detected. Ensure Laravel honors the Accept: application/json header.\n$normalizedBody';
    }

    try {
      final decoded = jsonDecode(normalizedBody);
      return _formatJson(decoded);
    } catch (_) {
      return normalizedBody;
    }
  }

  static String _formatJson(Object? data) {
    try {
      return _prettyEncoder.convert(data);
    } catch (_) {
      return data?.toString() ?? 'null';
    }
  }

  static void _writeBlock(List<String> lines) {
    for (final line in lines) {
      final chunks = line.split('\n');
      for (final chunk in chunks) {
        debugPrint(chunk);
      }
    }
  }
}
