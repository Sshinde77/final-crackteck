enum DeliveryOrderStatus { pending, cancelled }

class DeliveryOrderModel {
  DeliveryOrderModel({
    required this.id,
    required this.date,
    required this.time,
    required this.from,
    required this.to,
    required this.accepted,
    required this.status,
  });

  final String id;
  final String date;
  final String time;
  final String from;
  final String to;
  final bool accepted;
  final DeliveryOrderStatus status;

  factory DeliveryOrderModel.fromJson(Map<String, dynamic> json) {
    final statusText = (
      json['status'] ??
      json['order_status'] ??
      json['delivery_status'] ??
      json['state'] ??
      ''
    ).toString().toLowerCase();

    final from = (json['from_address'] ??
            json['pickup_address'] ??
            json['warehouse_address'] ??
            json['from'] ??
            json['source'] ??
            'Warehouse')
        .toString();
    final to = (json['to_address'] ??
            json['delivery_address'] ??
            json['customer_address'] ??
            json['address'] ??
            json['to'] ??
            'Customer address not available')
        .toString();
    final rawDate =
        json['date'] ??
        json['order_date'] ??
        json['created_at'] ??
        json['updated_at'] ??
        '';
    final parsed = DateTime.tryParse(rawDate.toString());
    final rawId = (json['display_id'] ??
            json['order_id'] ??
            json['id'] ??
            json['request_id'] ??
            'NA')
        .toString();
    final normalizedId = rawId.startsWith('#') ? rawId : '#$rawId';

    return DeliveryOrderModel(
      id: normalizedId,
      date: parsed == null
          ? (rawDate.toString().isEmpty ? '--' : rawDate.toString())
          : '${parsed.day}-${parsed.month}-${parsed.year}',
      time: parsed == null
          ? (json['time']?.toString() ?? '--')
          : formatTime(parsed),
      from: from,
      to: to,
      accepted:
          statusText.contains('accept') ||
          statusText.contains('assigned') ||
          statusText.contains('picked') ||
          statusText.contains('in_progress'),
      status: statusText.contains('cancel')
          ? DeliveryOrderStatus.cancelled
          : DeliveryOrderStatus.pending,
    );
  }

  DeliveryOrderModel copyWith({
    String? id,
    String? date,
    String? time,
    String? from,
    String? to,
    bool? accepted,
    DeliveryOrderStatus? status,
  }) {
    return DeliveryOrderModel(
      id: id ?? this.id,
      date: date ?? this.date,
      time: time ?? this.time,
      from: from ?? this.from,
      to: to ?? this.to,
      accepted: accepted ?? this.accepted,
      status: status ?? this.status,
    );
  }

  static String formatTime(DateTime dateTime) {
    int hour = dateTime.hour % 12;
    if (hour == 0) hour = 12;
    final suffix = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} $suffix';
  }
}
