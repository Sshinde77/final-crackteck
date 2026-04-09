import 'package:flutter/foundation.dart';

import '../../model/Delivery_person/delivery_order_detail_model.dart';
import '../../services/delivery_person/delivery_orders_service.dart';

class DeliveryOrderDetailProvider extends ChangeNotifier {
  DeliveryOrderDetailProvider({
    required String orderId,
    DeliveryOrdersService? ordersService,
  })  : orderId = orderId.startsWith('#') ? orderId : '#$orderId',
        _ordersService = ordersService ?? DeliveryOrdersService(),
        _detail = DeliveryOrderDetailModel.placeholder(orderId);

  final String orderId;
  final DeliveryOrdersService _ordersService;

  DeliveryOrderDetailModel _detail;
  bool _isLoading = false;
  bool _isAccepting = false;
  String? _error;

  DeliveryOrderDetailModel get detail => _detail;
  bool get isLoading => _isLoading;
  bool get isAccepting => _isAccepting;
  String? get error => _error;
  bool get accepted => _detail.accepted;

  Future<void> loadDetail() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _ordersService.fetchOrderDetail(orderId);
      _detail = DeliveryOrderDetailModel.fromJson(
        response,
        fallbackOrderId: orderId,
      );
    } catch (error) {
      _error = error.toString().replaceFirst('Exception: ', '');
      debugPrint('DeliveryOrderDetailProvider.loadDetail failed: $error');
      _detail = DeliveryOrderDetailModel.placeholder(orderId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> acceptOrder() async {
    if (_detail.accepted || _isAccepting) return null;
    _isAccepting = true;
    notifyListeners();

    try {
      final response = await _ordersService.acceptOrder(orderId);
      if (!response.success) {
        return response.message ?? 'Failed to accept order';
      }
      _detail = _detail.copyWith(accepted: true);
      return response.message ?? 'Order accepted successfully';
    } catch (error) {
      return error.toString().replaceFirst('Exception: ', '');
    } finally {
      _isAccepting = false;
      notifyListeners();
    }
  }
}
