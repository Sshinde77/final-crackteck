import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight token storage abstraction.
///
/// Values are cached in memory and persisted using FlutterSecureStorage.
class SecureStorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _roleIdKey = 'role_id';
  static const String _userIdKey = 'user_id';
  static const String _userProfileKey = 'user_profile';

  static String? _accessToken;
  static String? _refreshToken;
  static int? _roleId;
  static int? _userId;
  static Map<String, dynamic>? _userProfile;

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
    _accessToken = _normalizeToken(await _storage.read(key: _accessTokenKey));
    return _accessToken;
  }

  /// Persist a new access token.
  static Future<void> saveAccessToken(String token) async {
    final normalizedToken = _normalizeToken(token);
    if (normalizedToken == null) {
      _accessToken = null;
      await _storage.delete(key: _accessTokenKey);
      debugPrint(
        'WARNING: saveAccessToken received an empty token. Cleared access_token.',
      );
      return;
    }

    await _storage.write(key: _accessTokenKey, value: normalizedToken);
    _accessToken = normalizedToken;
  }

  /// Get the currently stored refresh token (if any).
  static Future<String?> getRefreshToken({bool forceReload = false}) async {
    if (!forceReload && _refreshToken != null && _refreshToken!.isNotEmpty) {
      return _refreshToken;
    }
    _refreshToken = _normalizeToken(await _storage.read(key: _refreshTokenKey));
    return _refreshToken;
  }

  /// Persist a new refresh token.
  static Future<void> saveRefreshToken(String token) async {
    final normalizedToken = _normalizeToken(token);
    if (normalizedToken == null) {
      _refreshToken = null;
      await _storage.delete(key: _refreshTokenKey);
      return;
    }

    await _storage.write(key: _refreshTokenKey, value: normalizedToken);
    _refreshToken = normalizedToken;
  }

  /// Get the currently stored role id (if any).
  static Future<int?> getRoleId({bool forceReload = false}) async {
    if (!forceReload && _roleId != null) return _roleId;
    final String? raw = await _storage.read(key: _roleIdKey);
    _roleId = raw == null ? null : int.tryParse(raw);
    return _roleId;
  }

  /// Persist the current role id.
  static Future<void> saveRoleId(int roleId) async {
    await _storage.write(key: _roleIdKey, value: roleId.toString());
    _roleId = roleId;
  }

  /// Get the currently stored user id (if any).
  static Future<int?> getUserId({bool forceReload = false}) async {
    if (!forceReload && _userId != null) return _userId;
    final String? raw = await _storage.read(key: _userIdKey);
    _userId = raw == null ? null : int.tryParse(raw);
    return _userId;
  }

  /// Persist the current user id.
  static Future<void> saveUserId(int userId) async {
    await _storage.write(key: _userIdKey, value: userId.toString());
    _userId = userId;
  }

  /// Clear the current user id while keeping tokens unchanged.
  static Future<void> clearUserId() async {
    _userId = null;
    await _storage.delete(key: _userIdKey);
  }

  /// Get the currently stored user profile (if any).
  static Future<Map<String, dynamic>?> getUserProfile({
    bool forceReload = false,
  }) async {
    if (!forceReload && _userProfile != null) {
      return _userProfile;
    }

    final String? raw = await _storage.read(key: _userProfileKey);
    if (raw == null || raw.trim().isEmpty) {
      _userProfile = null;
      return null;
    }

    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        _userProfile = decoded;
        return _userProfile;
      }
    } catch (error) {
      debugPrint('WARNING: Failed to decode stored user profile: $error');
    }

    _userProfile = null;
    return null;
  }

  /// Persist the current user profile.
  static Future<void> saveUserProfile(Map<String, dynamic> profile) async {
    await _storage.write(key: _userProfileKey, value: jsonEncode(profile));
    _userProfile = Map<String, dynamic>.from(profile);
  }

  /// Clear the stored user profile.
  static Future<void> clearUserProfile() async {
    _userProfile = null;
    await _storage.delete(key: _userProfileKey);
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
    _userProfile = null;
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _roleIdKey),
      _storage.delete(key: _userIdKey),
      _storage.delete(key: _userProfileKey),
    ]);
  }
}
