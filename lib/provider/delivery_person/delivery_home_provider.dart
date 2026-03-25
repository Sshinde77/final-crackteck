import 'package:flutter/foundation.dart';

import '../../model/Delivery_person/delivery_attendance_model.dart';
import '../../model/Delivery_person/delivery_order_model.dart';
import '../../services/delivery_person/delivery_attendance_service.dart';
import '../../services/delivery_person/delivery_orders_service.dart';

class DeliveryHomeProvider extends ChangeNotifier {
  DeliveryHomeProvider({
    DeliveryOrdersService? ordersService,
    DeliveryAttendanceService? attendanceService,
  })  : _ordersService = ordersService ?? DeliveryOrdersService(),
        _attendanceService = attendanceService ?? DeliveryAttendanceService();

  final DeliveryOrdersService _ordersService;
  final DeliveryAttendanceService _attendanceService;

  List<DeliveryOrderModel> _orders = <DeliveryOrderModel>[];
  DeliveryAttendanceModel _attendance = DeliveryAttendanceModel.empty();
  bool _isLoading = false;
  bool _isAttendanceLoading = false;
  String? _error;

  List<DeliveryOrderModel> get orders => _orders;
  DeliveryAttendanceModel get attendance => _attendance;
  bool get isLoading => _isLoading;
  bool get isAttendanceLoading => _isAttendanceLoading;
  String? get error => _error;

  int get totalCount => _orders.length;
  int get pendingCount => _orders
      .where((order) => order.status == DeliveryOrderStatus.pending && !order.accepted)
      .length;
  int get cancelledCount => _orders
      .where((order) => order.status == DeliveryOrderStatus.cancelled)
      .length;
  int countByCategory(DeliveryOrderCategory category) => _orders
      .where((order) => order.category == category)
      .length;

  Future<void> loadHomeData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait<dynamic>(<Future<dynamic>>[
        _ordersService.fetchOrders(),
        _attendanceService.fetchAttendance(),
      ]);

      final orderMaps = results[0] as List<Map<String, dynamic>>;
      final attendanceMap = results[1] as Map<String, dynamic>;

      _orders = orderMaps.map(DeliveryOrderModel.fromJson).toList();
      _attendance = DeliveryAttendanceModel.fromJson(attendanceMap);
    } catch (error) {
      _error = error.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> updateAttendance({required bool login}) async {
    _isAttendanceLoading = true;
    notifyListeners();

    try {
      final response = login
          ? await _attendanceService.attendanceLogin()
          : await _attendanceService.attendanceLogout();

      if (!response.success) {
        return response.message ?? 'Attendance action failed';
      }

      final data = response.data ?? <String, dynamic>{};
      final parsed = DeliveryAttendanceModel.fromJson(data);
      _attendance = login
          ? _attendance.copyWith(
              loginAt: parsed.loginAt ?? DateTime.now(),
              preserveLogout: true,
            )
          : _attendance.copyWith(
              logoutAt: parsed.logoutAt ?? DateTime.now(),
              preserveLogin: true,
            );
      return response.message ?? (login ? 'Checked in' : 'Checked out');
    } catch (error) {
      return error.toString().replaceFirst('Exception: ', '');
    } finally {
      _isAttendanceLoading = false;
      notifyListeners();
    }
  }

  void markOrderAccepted(String orderId) {
    _orders = _orders
        .map(
          (order) => order.id == orderId
              ? order.copyWith(accepted: true)
              : order,
        )
        .toList();
    notifyListeners();
  }
}
