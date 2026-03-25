import 'package:flutter/foundation.dart';

import '../../model/Delivery_person/delivery_attendance_model.dart';
import '../../services/delivery_person/delivery_attendance_service.dart';

class DeliveryAttendanceProvider extends ChangeNotifier {
  DeliveryAttendanceProvider({DeliveryAttendanceService? service})
    : _service = service ?? DeliveryAttendanceService();

  final DeliveryAttendanceService _service;

  DeliveryAttendanceModel _attendance = DeliveryAttendanceModel.empty();
  List<Map<String, dynamic>> _logs = const <Map<String, dynamic>>[];
  bool _isLoading = false;
  bool _isUpdating = false;

  DeliveryAttendanceModel get attendance => _attendance;
  List<Map<String, dynamic>> get logs => _logs;
  bool get isLoading => _isLoading;
  bool get isUpdating => _isUpdating;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      final results = await Future.wait<dynamic>(<Future<dynamic>>[
        _service.fetchAttendance(),
        _service.fetchAttendanceLogs(),
      ]);
      final data = results[0] as Map<String, dynamic>;
      _attendance = DeliveryAttendanceModel.fromJson(data);
      _logs = (results[1] as List<Map<String, dynamic>>)
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
