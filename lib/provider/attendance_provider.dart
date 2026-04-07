import 'package:flutter/foundation.dart';

import '../core/secure_storage_service.dart';
import '../model/api_response.dart';
import '../services/attendance_service.dart';

class AttendanceProvider extends ChangeNotifier {
  AttendanceProvider({AttendanceService? service})
    : _service = service ?? AttendanceService();

  final AttendanceService _service;

  AttendanceState _attendance = AttendanceState.empty;
  bool _isLoading = false;
  bool _isUpdating = false;
  int? _activeRoleId;
  int? _activeUserId;

  AttendanceState get attendance => _attendance;
  bool get isLoading => _isLoading;
  bool get isUpdating => _isUpdating;
  bool get hasClockIn => _attendance.hasClockIn;
  bool get hasClockOut => _attendance.hasClockOut;
  bool get canClockIn => !isLoading && !isUpdating && !hasClockIn;
  bool get canClockOut => !isLoading && !isUpdating && hasClockIn && !hasClockOut;

  Future<void> initialize({
    required int roleId,
    bool forceRefresh = false,
  }) async {
    final currentUserId = await SecureStorageService.getUserId();
    final shouldReuseState =
        !forceRefresh &&
        _activeRoleId == roleId &&
        _activeUserId == currentUserId &&
        !_isLoading &&
        !_isCurrentStateExpired();

    if (shouldReuseState) {
      return;
    }

    _activeRoleId = roleId;
    _activeUserId = currentUserId;
    _isLoading = true;
    notifyListeners();

    try {
      _attendance = await _service.getAttendance(roleId: roleId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool _isCurrentStateExpired() {
    final latest = _attendance.latestTimestamp;
    if (latest == null) {
      return false;
    }
    return DateTime.now().difference(latest) > AttendanceService.validityWindow;
  }

  Future<String> clockIn({
    required int roleId,
    required Future<ApiResponse<dynamic>> Function() apiCall,
  }) async {
    await initialize(roleId: roleId);

    if (hasClockIn) {
      return 'Already clocked in.';
    }

    _isUpdating = true;
    notifyListeners();

    try {
      final response = await apiCall();
      if (!response.success) {
        return response.message ?? 'Clock-in failed.';
      }

      final clockInAt =
          _extractAttendanceDateTime(
            response.data,
            const ['login_at', 'check_in_at', 'clock_in_at', 'check_in', 'clock_in'],
          ) ??
          DateTime.now();

      await _service.saveClockIn(
        roleId: roleId,
        clockInTimestamp: clockInAt,
      );

      _attendance = _attendance.copyWith(
        clockInAt: clockInAt,
        preserveClockOut: false,
      );

      return response.message ?? 'Clock-in successful.';
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  Future<String> clockOut({
    required int roleId,
    required Future<ApiResponse<dynamic>> Function() apiCall,
  }) async {
    await initialize(roleId: roleId);

    if (!hasClockIn) {
      return 'Clock in first.';
    }
    if (hasClockOut) {
      return 'Already clocked out.';
    }

    _isUpdating = true;
    notifyListeners();

    try {
      final response = await apiCall();
      if (!response.success) {
        return response.message ?? 'Clock-out failed.';
      }

      final clockOutAt =
          _extractAttendanceDateTime(
            response.data,
            const ['logout_at', 'check_out_at', 'clock_out_at', 'check_out', 'clock_out'],
          ) ??
          DateTime.now();

      await _service.saveClockOut(
        roleId: roleId,
        clockOutTimestamp: clockOutAt,
      );

      _attendance = _attendance.copyWith(clockOutAt: clockOutAt);
      return response.message ?? 'Clock-out successful.';
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  static DateTime? _extractAttendanceDateTime(
    dynamic source,
    List<String> keys, {
    int depth = 0,
  }) {
    if (source == null || depth > 4) return null;

    if (source is Map<String, dynamic>) {
      for (final key in keys) {
        final parsed = _parseDateTime(source[key]);
        if (parsed != null) {
          return parsed;
        }
      }

      final nested = source['auth_log'];
      final nestedParsed = _extractAttendanceDateTime(
        nested,
        keys,
        depth: depth + 1,
      );
      if (nestedParsed != null) {
        return nestedParsed;
      }

      for (final value in source.values) {
        final parsed = _extractAttendanceDateTime(value, keys, depth: depth + 1);
        if (parsed != null) {
          return parsed;
        }
      }
      return null;
    }

    if (source is List) {
      for (final value in source) {
        final parsed = _extractAttendanceDateTime(value, keys, depth: depth + 1);
        if (parsed != null) {
          return parsed;
        }
      }
    }

    return null;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value.toLocal();

    final text = value.toString().trim();
    if (text.isEmpty) return null;

    final parsed = DateTime.tryParse(text);
    if (parsed == null) return null;
    return parsed.isUtc ? parsed.toLocal() : parsed;
  }
}
