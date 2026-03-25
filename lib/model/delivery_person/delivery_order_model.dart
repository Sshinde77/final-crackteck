enum DeliveryOrderStatus { pending, cancelled }

enum DeliveryOrderCategory {
  productDelivery,
  pickupDelivery,
  requestPart,
  returnRequest,
}

class DeliveryOrderModel {
  DeliveryOrderModel({
    required this.id,
    required this.date,
    required this.time,
    required this.from,
    required this.to,
    required this.accepted,
    required this.status,
    required this.category,
  });

  final String id;
  final String date;
  final String time;
  final String from;
  final String to;
  final bool accepted;
  final DeliveryOrderStatus status;
  final DeliveryOrderCategory category;

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
    final category = _parseCategory(json);

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
      category: category,
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
    DeliveryOrderCategory? category,
  }) {
    return DeliveryOrderModel(
      id: id ?? this.id,
      date: date ?? this.date,
      time: time ?? this.time,
      from: from ?? this.from,
      to: to ?? this.to,
      accepted: accepted ?? this.accepted,
      status: status ?? this.status,
      category: category ?? this.category,
    );
  }

  static DeliveryOrderCategory _parseCategory(Map<String, dynamic> json) {
    final rawCategory = <dynamic>[
      json['request_type'],
      json['delivery_type'],
      json['type'],
      json['order_type'],
      json['request_category'],
      json['category'],
      json['service_type'],
    ].firstWhere(
      (value) => value != null && value.toString().trim().isNotEmpty,
      orElse: () => '',
    ).toString().toLowerCase();

    final compact = rawCategory.replaceAll(RegExp(r'[^a-z]'), '');

    if (compact.contains('pickup')) {
      return DeliveryOrderCategory.pickupDelivery;
    }
    if (compact.contains('requestpart') || compact.contains('partrequest')) {
      return DeliveryOrderCategory.requestPart;
    }
    if (compact.contains('return')) {
      return DeliveryOrderCategory.returnRequest;
    }
    return DeliveryOrderCategory.productDelivery;
  }

  static String formatTime(DateTime dateTime) {
    int hour = dateTime.hour % 12;
    if (hour == 0) hour = 12;
    final suffix = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} $suffix';
  }
}
