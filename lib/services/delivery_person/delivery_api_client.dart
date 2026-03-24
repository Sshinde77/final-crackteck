import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../constants/api_constants.dart';
import '../../core/navigation_service.dart';
import '../../core/secure_storage_service.dart';
import '../../model/api_response.dart';
import '../api_service.dart';

class DeliveryApiClient {
  static const int defaultRoleId = 2;
  static const int maxAuthRetries = 1;

  Future<DeliveryAuthState> authState({bool forceReload = false}) async {
    return DeliveryAuthState(
      userId: await SecureStorageService.getUserId(forceReload: forceReload),
      roleId: await SecureStorageService.getRoleId(forceReload: forceReload),
      accessToken: await SecureStorageService.getAccessToken(
        forceReload: forceReload,
      ),
    );
  }

  Future<ApiResponse?> validateAuthState() async {
    final state = await authState(forceReload: true);
    if (state.userId != null && state.roleId != null) {
      return null;
    }
    await SecureStorageService.clearTokens();
    await NavigationService.navigateToAuthRoot();
    return ApiResponse(
      success: false,
      message: 'Authentication error. Please log in again.',
    );
  }

  bool looksLikeHtml(String body) {
    final trimmed = body.trimLeft().toLowerCase();
    return trimmed.startsWith('<!doctype html') || trimmed.startsWith('<html');
  }

  bool isUnauthorized(http.Response response) {
    if (response.statusCode == 401 || response.statusCode == 403) {
      return true;
    }
    if (looksLikeHtml(response.body)) {
      return true;
    }
    final body = response.body.toLowerCase();
    return body.contains('unauthorized') || body.contains('token not provided');
  }

  Future<bool> refreshToken() async {
    final state = await authState(forceReload: true);
    if (state.userId == null) return false;
    final response = await ApiService.instance.refreshToken(
      roleId: state.roleId ?? defaultRoleId,
      userId: state.userId!,
    );
    return response.success;
  }

  Future<void> handleAuthFailure() async {
    await SecureStorageService.clearTokens();
    await NavigationService.navigateToAuthRoot();
  }

  Map<String, String> headers({String? token, bool json = false}) {
    return <String, String>{
      'Accept': 'application/json',
      if (json) 'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> performAuthenticatedGet(Uri url) async {
    int retries = 0;
    while (true) {
      final token = await SecureStorageService.getAccessToken();
      final response = await http
          .get(url, headers: headers(token: token))
          .timeout(ApiConstants.requestTimeout);
      if (!isUnauthorized(response)) {
        return response;
      }
      if (retries >= maxAuthRetries || !await refreshToken()) {
        await handleAuthFailure();
        return response;
      }
      retries++;
    }
  }

  Future<http.Response> performAuthenticatedPost(
    Uri url, {
    Object? body,
    bool json = false,
  }) async {
    int retries = 0;
    while (true) {
      final token = await SecureStorageService.getAccessToken();
      final response = await http
          .post(
            url,
            headers: headers(token: token, json: json),
            body: body,
          )
          .timeout(ApiConstants.requestTimeout);
      if (!isUnauthorized(response)) {
        return response;
      }
      if (retries >= maxAuthRetries || !await refreshToken()) {
        await handleAuthFailure();
        return response;
      }
      retries++;
    }
  }

  Future<http.Response> performAuthenticatedPut(
    Uri url, {
    Object? body,
    bool json = false,
  }) async {
    int retries = 0;
    while (true) {
      final token = await SecureStorageService.getAccessToken();
      final response = await http
          .put(
            url,
            headers: headers(token: token, json: json),
            body: body,
          )
          .timeout(ApiConstants.requestTimeout);
      if (!isUnauthorized(response)) {
        return response;
      }
      if (retries >= maxAuthRetries || !await refreshToken()) {
        await handleAuthFailure();
        return response;
      }
      retries++;
    }
  }

  Future<http.Response> performAuthenticatedMultipart(
    http.MultipartRequest request,
  ) async {
    final token = await SecureStorageService.getAccessToken();
    request.headers['Accept'] = 'application/json';
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    } else {
      request.headers.remove('Authorization');
    }
    final streamed = await request.send().timeout(ApiConstants.requestTimeout);
    final response = await http.Response.fromStream(streamed);
    if (isUnauthorized(response)) {
      await handleAuthFailure();
    }
    return response;
  }

  Map<String, dynamic> decodeBody(String body) {
    if (looksLikeHtml(body)) {
      return <String, dynamic>{
        'success': false,
        'message': 'Server returned HTML instead of JSON',
        'isHtml': true,
      };
    }
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return <String, dynamic>{'success': true, 'data': decoded};
    } catch (_) {
      return <String, dynamic>{
        'success': false,
        'message': 'Server returned non-JSON response',
        'raw': body,
      };
    }
  }

  ApiResponse<Map<String, dynamic>> mapResponse(
    http.Response response, {
    String? successMessage,
    String? failureMessage,
  }) {
    final decoded = decodeBody(response.body);
    final success =
        !((decoded['isHtml'] == true)) &&
        (response.statusCode == 200 ||
            response.statusCode == 201 ||
            decoded['success'] == true);
    return ApiResponse<Map<String, dynamic>>(
      success: success,
      message:
          decoded['message']?.toString() ??
          (success ? successMessage : failureMessage),
      data: decoded['data'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(decoded['data'] as Map)
          : decoded,
      errors: decoded['errors'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(decoded['errors'] as Map)
          : null,
    );
  }

  Uri buildUri(String endpoint, Map<String, String> query) {
    return Uri.parse(endpoint).replace(queryParameters: query);
  }

  Future<Map<String, String>> requiredQuery({
    int? roleId,
    bool includeUserId = true,
  }) async {
    final state = await authState();
    final resolvedRoleId = state.roleId ?? roleId ?? defaultRoleId;
    final query = <String, String>{'role_id': resolvedRoleId.toString()};
    if (includeUserId) {
      if (state.userId == null) {
        throw Exception('Missing user_id. Please log in again.');
      }
      query['user_id'] = state.userId.toString();
    }
    return query;
  }

  String replaceId(String template, String id) {
    final normalized = id.trim().replaceFirst(RegExp(r'^#'), '');
    if (normalized.isEmpty) {
      throw Exception('Invalid id: $id');
    }
    return template.replaceAll('{id}', normalized);
  }

  Map<String, dynamic> extractPrimaryMap(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      if (decoded['data'] is Map<String, dynamic>) {
        return Map<String, dynamic>.from(decoded['data'] as Map);
      }
      if (decoded['profile'] is Map<String, dynamic>) {
        return Map<String, dynamic>.from(decoded['profile'] as Map);
      }
      return decoded;
    }
    return <String, dynamic>{'data': decoded};
  }

  List<Map<String, dynamic>> extractList(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      final candidates = <dynamic>[
        decoded['data'],
        decoded['orders'],
        decoded['return_orders'],
        decoded['requests'],
        decoded['items'],
      ];
      for (final candidate in candidates) {
        if (candidate is List) {
          return candidate
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        }
      }
    }
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return const <Map<String, dynamic>>[];
  }
}

class DeliveryAuthState {
  const DeliveryAuthState({
    required this.userId,
    required this.roleId,
    required this.accessToken,
  });

  final int? userId;
  final int? roleId;
  final String? accessToken;
}
