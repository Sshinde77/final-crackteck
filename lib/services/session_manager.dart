import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/navigation_service.dart';
import '../core/secure_storage_service.dart';
import '../routes/app_routes.dart';

class SessionManager {
  SessionManager._();

  static const String _isLoggedInKey = 'is_logged_in';
  static const String _lastRoleIdKey = 'last_role_id';
  static const String _lastUserIdKey = 'last_user_id';
  static const String _tokenExpiryEpochKey = 'token_expiry_epoch_ms';
  static const Duration _authCheckDelay = Duration(milliseconds: 250);
  static const Duration _tokenRetryDelay = Duration(milliseconds: 150);
  static const int _tokenReadAttempts = 3;

  static Completer<void>? _sessionWriteCompleter;

  static Completer<void> _beginSessionWrite() {
    final completer = Completer<void>();
    _sessionWriteCompleter = completer;
    return completer;
  }

  static void _endSessionWrite(Completer<void> completer) {
    if (!completer.isCompleted) {
      completer.complete();
    }
    if (identical(_sessionWriteCompleter, completer)) {
      _sessionWriteCompleter = null;
    }
  }

  static Future<void> _awaitPendingSessionWrite() async {
    final pendingWrite = _sessionWriteCompleter;
    if (pendingWrite != null && !pendingWrite.isCompleted) {
      await pendingWrite.future;
    }
  }

  static String _tokenForLog(String? token) {
    final trimmed = token?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return 'null';
    }

    final visibleLength = trimmed.length < 16 ? trimmed.length : 16;
    final prefix = trimmed.substring(0, visibleLength);
    if (visibleLength == trimmed.length) {
      return '$prefix (len=${trimmed.length})';
    }
    return '$prefix... (len=${trimmed.length})';
  }

  static Future<void> saveSession({
    required String accessToken,
    required int roleId,
    String? refreshToken,
    int? userId,
    Map<String, dynamic>? userProfile,
  }) async {
    final completer = _beginSessionWrite();
    try {
      final prefs = await SharedPreferences.getInstance();

      await SecureStorageService.saveToken(accessToken);

      if (refreshToken != null && refreshToken.trim().isNotEmpty) {
        await SecureStorageService.saveRefreshToken(refreshToken);
      }
      if (userId != null) {
        await SecureStorageService.saveUserData(userId: userId, roleId: roleId);
      } else {
        await SecureStorageService.saveRoleId(roleId);
      }
      if (userProfile != null) {
        await SecureStorageService.saveUserProfile(userProfile);
      }

      await prefs.setBool(_isLoggedInKey, true);
      await prefs.setInt(_lastRoleIdKey, roleId);
      if (userId != null) {
        await prefs.setInt(_lastUserIdKey, userId);
      } else {
        await prefs.remove(_lastUserIdKey);
      }

      final expiry = _readJwtExpiry(accessToken);
      if (expiry != null) {
        await prefs.setInt(_tokenExpiryEpochKey, expiry.millisecondsSinceEpoch);
      } else {
        await prefs.remove(_tokenExpiryEpochKey);
      }

      debugPrint(
        'SessionManager.saveSession roleId=$roleId userId=$userId '
        'hasToken=${accessToken.trim().isNotEmpty} hasExpiry=${expiry != null}',
      );
    } finally {
      _endSessionWrite(completer);
    }

    final persistedToken = await SecureStorageService.getAccessToken(
      forceReload: true,
    );
    debugPrint(
      'SessionManager.saveSession persistedToken=${_tokenForLog(persistedToken)}',
    );
    await logSessionState('saveSession');
  }

  static Future<void> saveToken(String token) async {
    final completer = _beginSessionWrite();
    try {
      final normalizedToken = token.trim();
      final prefs = await SharedPreferences.getInstance();

      if (normalizedToken.isEmpty) {
        await SecureStorageService.saveToken('');
        await prefs.remove(_tokenExpiryEpochKey);
        debugPrint('SessionManager.saveToken cleared empty token');
        return;
      }

      await SecureStorageService.saveToken(normalizedToken);

      final expiry = _readJwtExpiry(normalizedToken);
      if (expiry != null) {
        await prefs.setInt(_tokenExpiryEpochKey, expiry.millisecondsSinceEpoch);
      } else {
        await prefs.remove(_tokenExpiryEpochKey);
      }

      debugPrint(
        'SessionManager.saveToken stored token hasExpiry=${expiry != null}',
      );
    } finally {
      _endSessionWrite(completer);
    }

    final persistedToken = await SecureStorageService.getAccessToken(
      forceReload: true,
    );
    debugPrint(
      'SessionManager.saveToken persistedToken=${_tokenForLog(persistedToken)}',
    );
    await logSessionState('saveToken');
  }

  static Future<String?> getToken({bool forceReload = false}) async {
    await _awaitPendingSessionWrite();

    for (int attempt = 1; attempt <= _tokenReadAttempts; attempt++) {
      final token = await SecureStorageService.getAccessToken(forceReload: true);
      if (token != null && token.trim().isNotEmpty) {
        final trimmedToken = token.trim();
        debugPrint(
          'SessionManager.getToken attempt=$attempt token=${_tokenForLog(trimmedToken)}',
        );
        return trimmedToken;
      }

      if (attempt < _tokenReadAttempts) {
        debugPrint(
          'SessionManager.getToken attempt=$attempt returned null. Retrying fresh read.',
        );
        await Future<void>.delayed(_tokenRetryDelay);
      }
    }

    debugPrint('SessionManager.getToken -> null');
    return null;
  }

  static Future<int?> getStoredRoleId({bool forceReload = false}) async {
    final roleId = await SecureStorageService.getRoleId(
      forceReload: forceReload,
    );
    debugPrint('SessionManager.getStoredRoleId -> $roleId');
    return roleId;
  }

  static Future<int?> getStoredUserId({bool forceReload = false}) async {
    final userId = await SecureStorageService.getUserId(
      forceReload: forceReload,
    );
    debugPrint('SessionManager.getStoredUserId -> $userId');
    return userId;
  }

  static Future<bool> isLoggedIn({
    int? expectedRoleId,
    bool checkExpiry = false,
  }) async {
    await _awaitPendingSessionWrite();
    await Future<void>.delayed(_authCheckDelay);

    final token = await getToken(forceReload: true);
    debugPrint('SessionManager.isLoggedIn token=${_tokenForLog(token)}');
    await logSessionState('isLoggedIn');
    if (token == null || token.trim().isEmpty) {
      debugPrint('SessionManager.isLoggedIn -> false (missing token)');
      return false;
    }

    if (checkExpiry && isTokenExpired(token)) {
      debugPrint('SessionManager.isLoggedIn -> false (expired token)');
      return false;
    }

    final storedRoleId = await getStoredRoleId(forceReload: true);
    if (expectedRoleId != null &&
        storedRoleId != null &&
        storedRoleId != expectedRoleId) {
      debugPrint(
        'SessionManager.isLoggedIn -> false '
        '(role mismatch stored=$storedRoleId expected=$expectedRoleId)',
      );
      return false;
    }

    debugPrint(
      'SessionManager.isLoggedIn -> true roleId=$storedRoleId '
      'expectedRoleId=$expectedRoleId',
    );
    return true;
  }

  static Future<Map<String, dynamic>> getSessionDebugState() async {
    await _awaitPendingSessionWrite();
    final prefs = await SharedPreferences.getInstance();
    final token = await SecureStorageService.getAccessToken(forceReload: true);
    final roleId = await SecureStorageService.getRoleId(forceReload: true);
    final userId = await SecureStorageService.getUserId(forceReload: true);
    final expiryEpoch = prefs.getInt(_tokenExpiryEpochKey);
    final expiry = expiryEpoch == null
        ? _readJwtExpiry(token ?? '')
        : DateTime.fromMillisecondsSinceEpoch(expiryEpoch);

    return <String, dynamic>{
      'hasToken': token != null && token.trim().isNotEmpty,
      'roleId': roleId,
      'userId': userId,
      'isLoggedIn': token != null && token.trim().isNotEmpty,
      'isExpired': token == null ? false : isTokenExpired(token),
      'expiry': expiry?.toIso8601String(),
    };
  }

  static Future<void> logSessionState(String source) async {
    final state = await getSessionDebugState();
    debugPrint(
      'SessionManager.logSessionState[$source] '
      'hasToken=${state['hasToken']} '
      'roleId=${state['roleId']} '
      'userId=${state['userId']} '
      'isExpired=${state['isExpired']} '
      'expiry=${state['expiry']}',
    );
  }

  static Future<void> clearSession() async {
    final completer = _beginSessionWrite();
    try {
      final prefs = await SharedPreferences.getInstance();
      await SecureStorageService.clearTokens();
      await prefs.remove(_isLoggedInKey);
      await prefs.remove(_lastRoleIdKey);
      await prefs.remove(_lastUserIdKey);
      await prefs.remove(_tokenExpiryEpochKey);
      debugPrint('SessionManager.clearSession completed');
    } finally {
      _endSessionWrite(completer);
    }

    await logSessionState('clearSession');
  }

  static Future<void> logoutAndNavigate({int? roleId}) async {
    await clearSession();
    await NavigationService.navigateToAuthRoot(roleId: roleId);
  }

  static bool isTokenExpired(
    String token, {
    Duration clockSkew = const Duration(seconds: 30),
  }) {
    final expiry = _readJwtExpiry(token);
    if (expiry == null) return false;
    return DateTime.now().isAfter(expiry.subtract(clockSkew));
  }

  static String defaultRouteForRole(int roleId) {
    switch (roleId) {
      case 1:
        return AppRoutes.FieldExecutiveDashboard;
      case 2:
        return AppRoutes.Deliverypersondashbord;
      case 3:
        return AppRoutes.salespersonDashboard;
      default:
        return AppRoutes.roleSelection;
    }
  }

  static Object? defaultArgumentsForRole(int roleId, String roleName) {
    switch (roleId) {
      case 1:
        return fieldexecutivedashboardArguments(
          roleId: roleId,
          roleName: roleName,
        );
      default:
        return null;
    }
  }

  static Future<void> openProtectedRouteForRole(
    BuildContext context, {
    required int roleId,
    required String roleName,
    String? routeName,
    Object? arguments,
  }) async {
    final targetRoute = routeName ?? defaultRouteForRole(roleId);
    final targetArguments =
        arguments ?? defaultArgumentsForRole(roleId, roleName);

    await logSessionState('openProtectedRouteForRole.precheck');
    bool isAuthenticated = await isLoggedIn(expectedRoleId: roleId);
    if (!isAuthenticated) {
      debugPrint(
        'SessionManager.openProtectedRouteForRole initial auth check failed '
        'for roleId=$roleId. Rechecking before redirect.',
      );
      await Future<void>.delayed(const Duration(milliseconds: 200));
      isAuthenticated = await isLoggedIn(expectedRoleId: roleId);
    }
    if (!context.mounted) return;

    if (isAuthenticated) {
      Navigator.pushNamed(context, targetRoute, arguments: targetArguments);
      return;
    }

    final tokenBeforeRedirect = await getToken(forceReload: true);
    debugPrint(
      'SessionManager.openProtectedRouteForRole redirectingToLogin '
      'token=${_tokenForLog(tokenBeforeRedirect)} roleId=$roleId',
    );
    await logSessionState('openProtectedRouteForRole.redirectToLogin');
    Navigator.pushNamed(
      context,
      AppRoutes.login,
      arguments: LoginArguments(
        roleId: roleId,
        roleName: roleName,
        redirectRoute: targetRoute,
        redirectArguments: targetArguments,
      ),
    );
  }

  static Future<void> navigateAfterAuthentication(
    BuildContext context, {
    required int roleId,
    required String roleName,
    String? redirectRoute,
    Object? redirectArguments,
  }) async {
    final targetRoute = redirectRoute ?? defaultRouteForRole(roleId);
    final targetArguments =
        redirectArguments ?? defaultArgumentsForRole(roleId, roleName);

    final tokenBeforeNavigation = await getToken(forceReload: true);
    debugPrint(
      'SessionManager.navigateAfterAuthentication roleId=$roleId '
      'targetRoute=$targetRoute token=${_tokenForLog(tokenBeforeNavigation)}',
    );
    await logSessionState('navigateAfterAuthentication');

    if (!context.mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      targetRoute,
      (route) => false,
      arguments: targetArguments,
    );
  }

  static DateTime? _readJwtExpiry(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final json = jsonDecode(decoded);

      if (json is! Map<String, dynamic>) return null;
      final rawExp = json['exp'];
      if (rawExp is int) {
        return DateTime.fromMillisecondsSinceEpoch(rawExp * 1000);
      }
      if (rawExp is num) {
        return DateTime.fromMillisecondsSinceEpoch(rawExp.toInt() * 1000);
      }
      if (rawExp is String) {
        final parsed = int.tryParse(rawExp);
        if (parsed != null) {
          return DateTime.fromMillisecondsSinceEpoch(parsed * 1000);
        }
      }
    } catch (error) {
      debugPrint('SessionManager._readJwtExpiry failed: $error');
    }
    return null;
  }
}
