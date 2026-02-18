import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight token storage abstraction.
///
/// Values are cached in memory and persisted using SharedPreferences.
class SecureStorageService {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _roleIdKey = 'role_id';
  static const String _userIdKey = 'user_id';

  static String? _accessToken;
  static String? _refreshToken;
  static int? _roleId;
  static int? _userId;

  /// Tracks which userIds have completed vehicle registration during this
  /// app session. This lets us treat vehicle registration as a one-time
  /// step per user without adding new persistent storage.
  static final Set<int> _vehicleRegisteredUserIds = <int>{};
  static const String _vehicleRegisteredKeyPrefix =
      'vehicle_registered_user_';

  static String? _normalizeToken(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  /// Get the currently stored access token (if any).
  static Future<String?> getAccessToken({bool forceReload = false}) async {
    if (!forceReload && _accessToken != null && _accessToken!.isNotEmpty) {
      return _accessToken;
    }
    final prefs = await SharedPreferences.getInstance();
    _accessToken = _normalizeToken(prefs.getString(_accessTokenKey));
    return _accessToken;
  }

  /// Persist a new access token.
  static Future<void> saveAccessToken(String token) async {
    final normalizedToken = _normalizeToken(token);
    final prefs = await SharedPreferences.getInstance();
    if (normalizedToken == null) {
      _accessToken = null;
      await prefs.remove(_accessTokenKey);
      debugPrint(
        'WARNING: saveAccessToken received an empty token. Cleared access_token.',
      );
      return;
    }

    final saved = await prefs.setString(_accessTokenKey, normalizedToken);
    if (!saved) {
      debugPrint('WARNING: Failed to persist access_token to SharedPreferences.');
    }
    _accessToken = normalizedToken;
  }

  /// Get the currently stored refresh token (if any).
  static Future<String?> getRefreshToken({bool forceReload = false}) async {
    if (!forceReload && _refreshToken != null && _refreshToken!.isNotEmpty) {
      return _refreshToken;
    }
    final prefs = await SharedPreferences.getInstance();
    _refreshToken = _normalizeToken(prefs.getString(_refreshTokenKey));
    return _refreshToken;
  }

  /// Persist a new refresh token.
  static Future<void> saveRefreshToken(String token) async {
    final normalizedToken = _normalizeToken(token);
    final prefs = await SharedPreferences.getInstance();
    if (normalizedToken == null) {
      _refreshToken = null;
      await prefs.remove(_refreshTokenKey);
      return;
    }

    final saved = await prefs.setString(_refreshTokenKey, normalizedToken);
    if (!saved) {
      debugPrint(
        'WARNING: Failed to persist refresh_token to SharedPreferences.',
      );
    }
    _refreshToken = normalizedToken;
  }

  /// Get the currently stored role id (if any).
  static Future<int?> getRoleId({bool forceReload = false}) async {
    if (!forceReload && _roleId != null) return _roleId;
    final prefs = await SharedPreferences.getInstance();
    _roleId = prefs.getInt(_roleIdKey);
    return _roleId;
  }

  /// Persist the current role id.
  static Future<void> saveRoleId(int roleId) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setInt(_roleIdKey, roleId);
    if (!saved) {
      debugPrint('WARNING: Failed to persist role_id to SharedPreferences.');
    }
    _roleId = roleId;
  }

  /// Get the currently stored user id (if any).
  static Future<int?> getUserId({bool forceReload = false}) async {
    if (!forceReload && _userId != null) return _userId;
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt(_userIdKey);
    return _userId;
  }

  /// Persist the current user id.
  static Future<void> saveUserId(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setInt(_userIdKey, userId);
    if (!saved) {
      debugPrint('WARNING: Failed to persist user_id to SharedPreferences.');
    }
    _userId = userId;
  }

  /// Clear the current user id while keeping tokens unchanged.
  static Future<void> clearUserId() async {
    _userId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
  }

  /// Returns `true` if the in-memory current user has already completed the
  /// vehicle registration flow in this app session.
  static Future<bool> isVehicleRegisteredForCurrentUser() async {
    final id = await getUserId();
    if (id == null) return false;
    if (_vehicleRegisteredUserIds.contains(id)) return true;
    final prefs = await SharedPreferences.getInstance();
    final persisted = prefs.getBool('$_vehicleRegisteredKeyPrefix$id') ?? false;
    if (persisted) {
      _vehicleRegisteredUserIds.add(id);
    }
    return persisted;
  }

  /// Marks the in-memory current user as having completed vehicle
  /// registration so subsequent logins can skip the vehicle screen.
  static Future<void> markVehicleRegisteredForCurrentUser() async {
    final id = await getUserId();
    if (id == null) return;
    _vehicleRegisteredUserIds.add(id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_vehicleRegisteredKeyPrefix$id', true);
  }

  /// Clear all stored tokens and role metadata.
  static Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    _roleId = null;
    _userId = null;
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_accessTokenKey),
      prefs.remove(_refreshTokenKey),
      prefs.remove(_roleIdKey),
      prefs.remove(_userIdKey),
    ]);
  }
}
