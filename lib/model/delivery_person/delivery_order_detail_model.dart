import 'delivery_order_model.dart';

class DeliveryOrderDetailModel {
  const DeliveryOrderDetailModel({
    required this.id,
    required this.date,
    required this.time,
    required this.from,
    required this.to,
    required this.accepted,
    required this.raw,
  });

  final String id;
  final String date;
  final String time;
  final String from;
  final String to;
  final bool accepted;
  final Map<String, dynamic> raw;

  factory DeliveryOrderDetailModel.fromJson(
    Map<String, dynamic> json, {
    String? fallbackOrderId,
  }) {
    final status = (json['status'] ?? json['order_status'] ?? '')
        .toString()
        .toLowerCase();
    final rawDate = (json['order_date'] ?? json['date'] ?? '').toString();
    final parsed = DateTime.tryParse(rawDate);
    final rawId = (json['display_id'] ??
            json['order_id'] ??
            json['id'] ??
            json['request_id'] ??
            fallbackOrderId ??
            'NA')
        .toString();
    final normalizedId = rawId.startsWith('#') ? rawId : '#$rawId';

    return DeliveryOrderDetailModel(
      id: normalizedId,
      date: parsed == null
          ? (rawDate.isEmpty ? '--' : rawDate)
          : '${parsed.day}-${parsed.month}-${parsed.year}',
      time: parsed == null
          ? (json['time'] ?? '--').toString()
          : DeliveryOrderModel.formatTime(parsed),
      from: (json['from_address'] ??
              json['pickup_address'] ??
              json['warehouse_address'] ??
              'Vasai Warehouse')
          .toString(),
      to: (json['to_address'] ??
              json['delivery_address'] ??
              json['customer_address'] ??
              'Customer address not available')
          .toString(),
      accepted: status.contains('accept') ||
          status.contains('assigned') ||
          status.contains('picked'),
      raw: Map<String, dynamic>.from(json),
    );
  }

  factory DeliveryOrderDetailModel.placeholder(String orderId) {
    final normalizedId = orderId.startsWith('#') ? orderId : '#$orderId';
    return DeliveryOrderDetailModel(
      id: normalizedId,
      date: '--',
      time: '--',
      from: 'Vasai Warehouse',
      to: 'Customer address not available',
      accepted: false,
      raw: const <String, dynamic>{},
    );
  }

  DeliveryOrderDetailModel copyWith({
    String? id,
    String? date,
    String? time,
    String? from,
    String? to,
    bool? accepted,
    Map<String, dynamic>? raw,
  }) {
    return DeliveryOrderDetailModel(
      id: id ?? this.id,
      date: date ?? this.date,
      time: time ?? this.time,
      from: from ?? this.from,
      to: to ?? this.to,
      accepted: accepted ?? this.accepted,
      raw: raw ?? this.raw,
    );
  }
}
