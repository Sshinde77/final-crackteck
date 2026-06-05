import 'package:flutter/foundation.dart';

import '../../model/Delivery_person/delivery_order_model.dart';
import '../../services/delivery_person/delivery_orders_service.dart';

class DeliveryHomeProvider extends ChangeNotifier {
  DeliveryHomeProvider({DeliveryOrdersService? ordersService})
    : _ordersService = ordersService ?? DeliveryOrdersService();

  final DeliveryOrdersService _ordersService;

  List<DeliveryOrderModel> _orders = <DeliveryOrderModel>[];
  bool _isLoading = false;
  String? _error;

  List<DeliveryOrderModel> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get totalCount => _orders.length;
  int get pendingCount => _orders
      .where((order) => order.status == DeliveryOrderStatus.pending && !order.accepted)
      .length;
  int get cancelledCount => _orders
      .where((order) => order.status == DeliveryOrderStatus.cancelled)
      .length;
  int countByCategory(DeliveryOrderCategory category) => _orders
      .where(
        (order) =>
            order.category == category &&
            order.rawStatus.trim().toLowerCase() != 'delivered',
      )
      .length;

  Future<void> loadHomeData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait<List<Map<String, dynamic>>>([
        _ordersService.fetchOrders(),
        _ordersService.fetchPickupRequests(),
        _ordersService.fetchReturnRequests(),
        _ordersService.fetchPartRequests(),
        _ordersService.fetchReturnOrders(),
      ]);

      final mergedOrders = <DeliveryOrderModel>[
        ...results[0]
            .map(DeliveryOrderModel.fromJson)
            .map(
              (order) => order.copyWith(
                category: DeliveryOrderCategory.productDelivery,
              ),
            ),
        ...results[1]
            .map(DeliveryOrderModel.fromJson)
            .map(
              (order) => order.copyWith(
                category: DeliveryOrderCategory.pickupDelivery,
              ),
            ),
        ...results[2]
            .map(DeliveryOrderModel.fromJson)
            .map(
              (order) => order.copyWith(
                category: DeliveryOrderCategory.returnRequest,
              ),
            ),
        ...results[3]
            .map(DeliveryOrderModel.fromJson)
            .map(
              (order) => order.copyWith(
                category: DeliveryOrderCategory.requestPart,
              ),
            ),
        ...results[4]
            .map(DeliveryOrderModel.fromJson)
            .map(
              (order) => order.copyWith(
                category: DeliveryOrderCategory.returnProduct,
              ),
            ),
      ];

      mergedOrders.sort((a, b) {
        final aDate = DateTime.tryParse(a.date.split('-').reversed.join('-'));
        final bDate = DateTime.tryParse(b.date.split('-').reversed.join('-'));
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });

      _orders = mergedOrders;
    } catch (error) {
      _error = error.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
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
