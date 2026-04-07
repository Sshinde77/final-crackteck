import 'package:flutter/foundation.dart';

import '../../services/delivery_person/delivery_attendance_service.dart';

class DeliveryAttendanceProvider extends ChangeNotifier {
  DeliveryAttendanceProvider({DeliveryAttendanceService? service})
    : _service = service ?? DeliveryAttendanceService();

  final DeliveryAttendanceService _service;

  List<Map<String, dynamic>> _logs = const <Map<String, dynamic>>[];
  bool _isLoading = false;
  bool _isUpdating = false;

  List<Map<String, dynamic>> get logs => _logs;
  bool get isLoading => _isLoading;
  bool get isUpdating => _isUpdating;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      _logs = (await _service.fetchAttendanceLogs())
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } finally {
      _isLoading = false;
      _isUpdating = false;
      notifyListeners();
    }
  }

  Future<String> update(bool login) async {
    _isUpdating = true;
    notifyListeners();
    try {
      final response = login
          ? await _service.attendanceLogin()
          : await _service.attendanceLogout();
      if (response.success) {
        await load();
      } else {
        _isUpdating = false;
        notifyListeners();
      }
      return response.message ?? 'Attendance updated';
    } catch (error) {
      _isUpdating = false;
      notifyListeners();
      return error.toString().replaceFirst('Exception: ', '');
    }
  }
}
