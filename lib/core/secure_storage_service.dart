import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight token storage abstraction.
///
/// NOTE: This implementation currently keeps tokens in memory only.
/// You can later swap the internals to use `flutter_secure_storage` or
/// another secure persistence mechanism without changing call sites.
class SecureStorageService {
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

  /// Get the currently stored access token (if any).
  static Future<String?> getAccessToken() async {
    return _accessToken;
  }

  /// Persist a new access token.
  static Future<void> saveAccessToken(String token) async {
    _accessToken = token;
  }

  /// Get the currently stored refresh token (if any).
  static Future<String?> getRefreshToken() async {
    return _refreshToken;
  }

  /// Persist a new refresh token.
  static Future<void> saveRefreshToken(String token) async {
    _refreshToken = token;
  }

  /// Get the currently stored role id (if any).
  static Future<int?> getRoleId() async {
    return _roleId;
  }

  /// Persist the current role id.
  static Future<void> saveRoleId(int roleId) async {
    _roleId = roleId;
  }

  /// Get the currently stored user id (if any).
  static Future<int?> getUserId() async {
    return _userId;
  }

  /// Persist the current user id.
  static Future<void> saveUserId(int userId) async {
    _userId = userId;
  }

  /// Returns `true` if the in-memory current user has already completed the
  /// vehicle registration flow in this app session.
  static Future<bool> isVehicleRegisteredForCurrentUser() async {
    final id = _userId;
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
    final id = _userId;
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
  }
}
