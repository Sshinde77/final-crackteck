import 'delivery_order_model.dart';

class DeliveryOrderDetailModel {
  const DeliveryOrderDetailModel({
    required this.id,
    required this.date,
    required this.time,
    required this.from,
    required this.to,
    required this.customerFirstName,
    required this.customerLastName,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    required this.items,
    required this.accepted,
    required this.raw,
  });

  final String id;
  final String date;
  final String time;
  final String from;
  final String to;
  final String customerFirstName;
  final String customerLastName;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final List<DeliveryOrderItemModel> items;
  final bool accepted;
  final Map<String, dynamic> raw;

  factory DeliveryOrderDetailModel.fromJson(
    Map<String, dynamic> json, {
    String? fallbackOrderId,
  }) {
    final data = _asMap(json['data']);
    final payload = _extractOrderPayload(json);
    final serviceRequest =
        _asMap(payload['service_request']) ??
        _asMap(data?['service_request']) ??
        _asMap(json['service_request']);
    final customer =
        _asMap(payload['customer']) ??
        _asMap(payload['customer_details']) ??
        _asMap(serviceRequest?['customer']) ??
        _asMap(serviceRequest?['customer_details']) ??
        _asMap(json['customer']) ??
        _asMap(json['customer_details']);
    final shippingAddress =
        _asMap(payload['shipping_address']) ??
        _asMap(payload['customer_address']) ??
        _asMap(serviceRequest?['customer_address']) ??
        _asMap(json['customer_address']);
    final firstOrderItem = _firstMap(payload['order_items']);
    final productDetails = _asMap(firstOrderItem?['product_details']);
    final warehouseDetails =
        _asMap(firstOrderItem?['warehouse_details']) ??
        _asMap(productDetails?['warehouse']);
    final status = (payload['status'] ?? payload['order_status'] ?? '')
        .toString()
        .toLowerCase();
    final rawDate =
        (payload['created_at'] ??
                payload['confirmed_at'] ??
                payload['order_date'] ??
                payload['date'] ??
                '')
            .toString();
    final parsed = DateTime.tryParse(rawDate);
    final rawId = (payload['order_number'] ??
            payload['display_id'] ??
            payload['order_id'] ??
            payload['id'] ??
            payload['request_id'] ??
            fallbackOrderId ??
            'NA')
        .toString();
    final normalizedId = rawId.startsWith('#') ? rawId : '#$rawId';
    final normalizedRaw = Map<String, dynamic>.from(payload);
    if (customer != null) {
      normalizedRaw['customer'] = customer;
    }
    if (serviceRequest != null) {
      normalizedRaw['service_request'] = serviceRequest;
    }
    if (shippingAddress != null) {
      normalizedRaw['customer_address'] = shippingAddress;
    }
    if (payload['order_items'] is List) {
      normalizedRaw['order_items'] = List<dynamic>.from(
        payload['order_items'] as List,
      );
    }

    final customerFirstName = _readString(
      customer,
      const <String>['first_name', 'firstName', 'firstname'],
    );
    final customerLastName = _readString(
      customer,
      const <String>['last_name', 'lastName', 'lastname'],
    );

    return DeliveryOrderDetailModel(
      id: normalizedId,
      date: parsed == null
          ? (rawDate.isEmpty ? '--' : rawDate)
          : '${parsed.day}-${parsed.month}-${parsed.year}',
      time: parsed == null
          ? (payload['time'] ?? '--').toString()
          : DeliveryOrderModel.formatTime(parsed),
      from: _firstNonEmpty(<String>[
        _formatAddress(warehouseDetails),
        payload['from_address']?.toString() ?? '',
        payload['pickup_address']?.toString() ?? '',
        payload['warehouse_address']?.toString() ?? '',
      ], fallback: 'Vasai Warehouse'),
      to: _firstNonEmpty(<String>[
        _formatAddress(shippingAddress),
        payload['to_address']?.toString() ?? '',
        payload['delivery_address']?.toString() ?? '',
        payload['customer_address']?.toString() ?? '',
      ], fallback: 'Customer address not available'),
      customerFirstName: _valueOrPlaceholder(customerFirstName),
      customerLastName: _valueOrPlaceholder(customerLastName),
      customerName: _firstNonEmpty(<String>[
        _joinName(customerFirstName, customerLastName),
        _readString(customer, const <String>['name', 'full_name', 'customer_name']),
        payload['customer_name']?.toString() ?? '',
      ]),
      customerPhone: _firstNonEmpty(<String>[
        _readString(
          customer,
          const <String>['phone', 'phone_number', 'mobile', 'mobile_number', 'contact_number'],
        ),
        payload['customer_phone']?.toString() ?? '',
        payload['phone']?.toString() ?? '',
      ]),
      customerEmail: _firstNonEmpty(<String>[
        _readString(customer, const <String>['email', 'email_id']),
        payload['customer_email']?.toString() ?? '',
        payload['email']?.toString() ?? '',
      ]),
      items: _parseItems(payload['order_items']),
      accepted: status.contains('accept') ||
          status.contains('assigned') ||
          status.contains('picked'),
      raw: normalizedRaw,
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
      customerFirstName: '--',
      customerLastName: '--',
      customerName: '--',
      customerPhone: '--',
      customerEmail: '--',
      items: const <DeliveryOrderItemModel>[],
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
    String? customerFirstName,
    String? customerLastName,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    List<DeliveryOrderItemModel>? items,
    bool? accepted,
    Map<String, dynamic>? raw,
  }) {
    return DeliveryOrderDetailModel(
      id: id ?? this.id,
      date: date ?? this.date,
      time: time ?? this.time,
      from: from ?? this.from,
      to: to ?? this.to,
      customerFirstName: customerFirstName ?? this.customerFirstName,
      customerLastName: customerLastName ?? this.customerLastName,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
      items: items ?? this.items,
      accepted: accepted ?? this.accepted,
      raw: raw ?? this.raw,
    );
  }
}

class DeliveryOrderItemModel {
  const DeliveryOrderItemModel({
    required this.title,
    required this.price,
    required this.qty,
  });

  final String title;
  final String price;
  final int qty;

  factory DeliveryOrderItemModel.fromJson(Map<String, dynamic> json) {
    return DeliveryOrderItemModel(
      title: _firstNonEmpty(<String>[
        json['product_name']?.toString() ?? '',
        _asMap(json['product_details'])?['product_name']?.toString() ?? '',
      ], fallback: 'Product'),
      price: _firstNonEmpty(<String>[
        json['unit_price']?.toString() ?? '',
        json['line_total']?.toString() ?? '',
        _asMap(json['product_details'])?['final_price']?.toString() ?? '',
      ], fallback: '0'),
      qty: _parseInt(json['quantity']),
    );
  }
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map(
      (dynamic key, dynamic entryValue) =>
          MapEntry(key.toString(), entryValue),
    );
  }
  return null;
}

Map<String, dynamic>? _firstMap(dynamic value) {
  if (value is List) {
    for (final item in value) {
      final mapped = _asMap(item);
      if (mapped != null) return mapped;
    }
  }
  return _asMap(value);
}

String _joinName(String? firstName, String? lastName) {
  return <String>[firstName ?? '', lastName ?? '']
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .join(' ');
}

Map<String, dynamic> _extractOrderPayload(Map<String, dynamic> json) {
  final data = _asMap(json['data']);
  return _asMap(json['order']) ??
      _asMap(data?['order']) ??
      data ??
      _asMap(json['details']) ??
      json;
}

String _readString(Map<String, dynamic>? map, List<String> keys) {
  if (map == null) return '';
  for (final key in keys) {
    final value = map[key]?.toString().trim() ?? '';
    if (value.isNotEmpty) return value;
  }
  return '';
}

String _firstNonEmpty(List<String> values, {String fallback = '--'}) {
  for (final value in values) {
    final trimmed = value.trim();
    if (trimmed.isNotEmpty) return trimmed;
  }
  return fallback;
}

String _valueOrPlaceholder(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? '--' : trimmed;
}

List<DeliveryOrderItemModel> _parseItems(dynamic rawItems) {
  if (rawItems is! List) return const <DeliveryOrderItemModel>[];
  return rawItems
      .map(_asMap)
      .whereType<Map<String, dynamic>>()
      .map(DeliveryOrderItemModel.fromJson)
      .toList();
}

int _parseInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _formatAddress(Map<String, dynamic>? address) {
  if (address == null) return '';
  return <String>[
    address['name']?.toString() ?? '',
    address['branch_name']?.toString() ?? '',
    address['address1']?.toString() ?? '',
    address['address2']?.toString() ?? '',
    address['city']?.toString() ?? '',
    address['state']?.toString() ?? '',
    address['country']?.toString() ?? '',
    address['pincode']?.toString() ?? '',
  ].map((part) => part.trim()).where((part) => part.isNotEmpty).join(', ');
}
