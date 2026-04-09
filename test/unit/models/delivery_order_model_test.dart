import 'package:final_crackteck/model/Delivery_person/delivery_order_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('DeliveryOrderModel.fromJson normalizes id and category', () {
    final model = DeliveryOrderModel.fromJson(<String, dynamic>{
      'id': '101',
      'status': 'Pending',
      'request_type': 'pickup_request',
      'created_at': '2026-04-08T10:00:00Z',
      'pickup_address': 'Warehouse A',
      'customer_address': 'Customer B',
    });

    expect(model.id, '#101');
    expect(model.status, DeliveryOrderStatus.pending);
    expect(model.category, DeliveryOrderCategory.pickupDelivery);
    expect(model.from, contains('Warehouse'));
  });

  test('DeliveryOrderModel marks delivered/cancelled based on status text', () {
    final delivered = DeliveryOrderModel.fromJson(<String, dynamic>{
      'id': '102',
      'status': 'Delivered',
    });
    expect(delivered.status, DeliveryOrderStatus.delivered);

    final cancelled = DeliveryOrderModel.fromJson(<String, dynamic>{
      'id': '103',
      'status': 'Cancelled',
    });
    expect(cancelled.status, DeliveryOrderStatus.cancelled);
  });
}

