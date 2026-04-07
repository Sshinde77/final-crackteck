import 'package:shared_preferences/shared_preferences.dart';

import '../core/secure_storage_service.dart';

class AttendanceState {
  const AttendanceState({
    required this.clockInAt,
    required this.clockOutAt,
  });

  final DateTime? clockInAt;
  final DateTime? clockOutAt;

  static const AttendanceState empty = AttendanceState(
    clockInAt: null,
    clockOutAt: null,
  );

  bool get hasClockIn => clockInAt != null;
  bool get hasClockOut => clockOutAt != null;
  DateTime? get latestTimestamp => clockOutAt ?? clockInAt;

  AttendanceState copyWith({
    DateTime? clockInAt,
    DateTime? clockOutAt,
    bool preserveClockIn = true,
    bool preserveClockOut = true,
  }) {
    return AttendanceState(
      clockInAt: clockInAt ?? (preserveClockIn ? this.clockInAt : null),
      clockOutAt: clockOutAt ?? (preserveClockOut ? this.clockOutAt : null),
    );
  }
}

class AttendanceService {
  static const Duration validityWindow = Duration(hours: 13);

  static const String _clockInTimeKey = 'clock_in_time';
  static const String _clockOutTimeKey = 'clock_out_time';
  static const String _clockInTimestampKey = 'clock_in_timestamp';
  static const String _clockOutTimestampKey = 'clock_out_timestamp';

  Future<AttendanceState> getAttendance({
    required int roleId,
    int? userId,
  }) async {
    final resolvedUserId = userId ?? await SecureStorageService.getUserId();
    if (resolvedUserId == null) {
      return AttendanceState.empty;
    }

    await clearExpiredAttendance(roleId: roleId, userId: resolvedUserId);

    final prefs = await SharedPreferences.getInstance();
    final scope = _scope(resolvedUserId, roleId);

    return AttendanceState(
      clockInAt: _parseStoredDateTime(
        prefs.getString(_scopedKey(scope, _clockInTimeKey)),
        prefs.getInt(_scopedKey(scope, _clockInTimestampKey)),
      ),
      clockOutAt: _parseStoredDateTime(
        prefs.getString(_scopedKey(scope, _clockOutTimeKey)),
        prefs.getInt(_scopedKey(scope, _clockOutTimestampKey)),
      ),
    );
  }

  Future<void> saveClockIn({
    required int roleId,
    required DateTime clockInTimestamp,
    int? userId,
  }) async {
    final resolvedUserId = userId ?? await SecureStorageService.getUserId();
    if (resolvedUserId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final scope = _scope(resolvedUserId, roleId);
    final normalized = clockInTimestamp.toLocal();

    await prefs.setString(
      _scopedKey(scope, _clockInTimeKey),
      normalized.toIso8601String(),
    );
    await prefs.setInt(
      _scopedKey(scope, _clockInTimestampKey),
      normalized.millisecondsSinceEpoch,
    );
    await prefs.remove(_scopedKey(scope, _clockOutTimeKey));
    await prefs.remove(_scopedKey(scope, _clockOutTimestampKey));
  }

  Future<void> saveClockOut({
    required int roleId,
    required DateTime clockOutTimestamp,
    int? userId,
  }) async {
    final resolvedUserId = userId ?? await SecureStorageService.getUserId();
    if (resolvedUserId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final scope = _scope(resolvedUserId, roleId);
    final normalized = clockOutTimestamp.toLocal();

    await prefs.setString(
      _scopedKey(scope, _clockOutTimeKey),
      normalized.toIso8601String(),
    );
    await prefs.setInt(
      _scopedKey(scope, _clockOutTimestampKey),
      normalized.millisecondsSinceEpoch,
    );
  }

  Future<void> clearExpiredAttendance({
    required int roleId,
    int? userId,
  }) async {
    final resolvedUserId = userId ?? await SecureStorageService.getUserId();
    if (resolvedUserId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final scope = _scope(resolvedUserId, roleId);

    final clockOutTimestamp = prefs.getInt(
      _scopedKey(scope, _clockOutTimestampKey),
    );
    final clockInTimestamp = prefs.getInt(
      _scopedKey(scope, _clockInTimestampKey),
    );
    final latestTimestamp = clockOutTimestamp ?? clockInTimestamp;

    if (latestTimestamp == null) {
      return;
    }

    final latestDate = DateTime.fromMillisecondsSinceEpoch(
      latestTimestamp,
      isUtc: false,
    );
    if (DateTime.now().difference(latestDate) <= validityWindow) {
      return;
    }

    await clearAttendance(roleId: roleId, userId: resolvedUserId);
  }

  Future<void> clearAttendance({
    required int roleId,
    int? userId,
  }) async {
    final resolvedUserId = userId ?? await SecureStorageService.getUserId();
    if (resolvedUserId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final scope = _scope(resolvedUserId, roleId);

    await prefs.remove(_scopedKey(scope, _clockInTimeKey));
    await prefs.remove(_scopedKey(scope, _clockOutTimeKey));
    await prefs.remove(_scopedKey(scope, _clockInTimestampKey));
    await prefs.remove(_scopedKey(scope, _clockOutTimestampKey));
  }

  static DateTime? _parseStoredDateTime(String? isoValue, int? timestamp) {
    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp, isUtc: false);
    }
    if (isoValue == null || isoValue.trim().isEmpty) {
      return null;
    }

    final parsed = DateTime.tryParse(isoValue.trim());
    if (parsed == null) {
      return null;
    }
    return parsed.isUtc ? parsed.toLocal() : parsed;
  }

  static String _scope(int userId, int roleId) => 'attendance_${userId}_$roleId';

  static String _scopedKey(String scope, String key) => '${scope}_$key';
}
