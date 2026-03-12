class FieldExecutiveDeliveryTypes {
  FieldExecutiveDeliveryTypes._();

  static const String returnRequest = 'return_request';
  static const String pickupRequest = 'pickup_request';
  static const String requestPart = 'request_part';

  static String normalize(String raw) {
    final value = raw.trim().toLowerCase();
    if (value.isEmpty) return '';

    if (value.contains('return')) return returnRequest;
    if (value.contains('pickup')) return pickupRequest;
    if (value.contains('part')) return requestPart;

    if (value == '1') return returnRequest;
    if (value == '2') return pickupRequest;
    if (value == '3') return requestPart;

    return value.replaceAll(' ', '_').replaceAll('-', '_');
  }

  static String label(String type) {
    switch (normalize(type)) {
      case returnRequest:
        return 'Return Request';
      case pickupRequest:
        return 'Pickup Request';
      case requestPart:
        return 'Request Part';
      default:
        return 'Delivery Request';
    }
  }
}

class FieldExecutiveDeliveryRequest {
  final Map<String, dynamic> raw;
  final int? id;
  final String requestId;
  final String displayRequestId;
  final String deliveryType;
  final String title;
  final String description;
  final String location;
  final String priority;
  final String status;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final String productName;
  final String imageUrl;

  const FieldExecutiveDeliveryRequest({
    required this.raw,
    required this.id,
    required this.requestId,
    required this.displayRequestId,
    required this.deliveryType,
    required this.title,
    required this.description,
    required this.location,
    required this.priority,
    required this.status,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    required this.productName,
    required this.imageUrl,
  });

  factory FieldExecutiveDeliveryRequest.fromApi(
    Map<String, dynamic> json, {
    String fallbackType = '',
  }) {
    final customer = _asMap(json['customer']) ??
        _asMap(json['customer_details']) ??
        _asMap(json['user']) ??
        <String, dynamic>{};
    final product = _asMap(json['product']) ??
        _asMap(json['product_detail']) ??
        _asMap(json['service_request_product']) ??
        _asMap(json['service']) ??
        <String, dynamic>{};

    final id = _readInt(
      json,
      const ['id', 'request_id', 'return_request_id', 'pickup_request_id', 'part_request_id'],
    );
    final normalizedFallbackType = FieldExecutiveDeliveryTypes.normalize(
      fallbackType,
    );
    final requestType = FieldExecutiveDeliveryTypes.normalize(
      _readString(
        json,
        const ['delivery_type', 'request_type', 'type', 'service_type'],
        fallback: normalizedFallbackType,
      ),
    );
    final requestIdKeys = _requestIdKeysForType(requestType);
    final rawRequestId = _readString(
      json,
      requestIdKeys,
      fallback: id?.toString() ?? '',
    );
    final requestId = _normalizeId(rawRequestId);
    final displayRequestId = requestId.isEmpty ? '-' : '#$requestId';

    final customerName = _fullName(customer);
    final fallbackCustomerName = _fullName(json);
    final resolvedCustomerName =
        customerName.isEmpty ? fallbackCustomerName : customerName;

    final customerAddress = _readAddress(json, customer);

    final title = _readString(
      json,
      const ['title', 'service_name', 'service_title', 'name', 'issue', 'problem'],
      fallback: _readString(product, const ['product_name', 'name']),
    );

    final description = _readString(
      json,
      const ['description', 'details', 'notes', 'remark', 'remarks'],
    );

    final location = _readString(
      json,
      const ['location', 'city', 'area'],
      fallback: _readString(customer, const ['city', 'area'], fallback: '-'),
    );

    final priority = _normalizePriority(
      _readString(json, const ['priority', 'priority_level', 'urgency'], fallback: 'Medium'),
    );

    final status = _readString(
      json,
      const ['delivery_status', 'request_status', 'service_status', 'status'],
    );

    final customerPhone = _readString(
      customer,
      const ['phone', 'mobile', 'phone_number', 'contact_number', 'customer_phone'],
      fallback: _readString(
        json,
        const ['customer_phone', 'customer_number', 'phone', 'mobile', 'phone_number'],
      ),
    );

    final productName = _readString(
      product,
      const ['product_name', 'name', 'title'],
    );

    final imageUrl = _readString(
      product,
      const ['product_image', 'image_url', 'image', 'thumbnail'],
      fallback: _readString(json, const ['image_url', 'image', 'service_image'], fallback: ''),
    );

    return FieldExecutiveDeliveryRequest(
      raw: Map<String, dynamic>.from(json),
      id: id,
      requestId: requestId,
      displayRequestId: displayRequestId,
      deliveryType: requestType,
      title: title,
      description: description,
      location: location,
      priority: priority,
      status: status,
      customerName: resolvedCustomerName,
      customerPhone: customerPhone,
      customerAddress: customerAddress,
      productName: productName,
      imageUrl: imageUrl,
    );
  }

  FieldExecutiveDeliveryRequest merge(FieldExecutiveDeliveryRequest other) {
    return FieldExecutiveDeliveryRequest(
      raw: raw.isNotEmpty ? raw : other.raw,
      id: id ?? other.id,
      requestId: requestId.isNotEmpty ? requestId : other.requestId,
      displayRequestId:
          displayRequestId != '-' ? displayRequestId : other.displayRequestId,
      deliveryType: deliveryType.isNotEmpty ? deliveryType : other.deliveryType,
      title: title.isNotEmpty ? title : other.title,
      description: description.isNotEmpty ? description : other.description,
      location: location.isNotEmpty && location != '-' ? location : other.location,
      priority: priority.isNotEmpty ? priority : other.priority,
      status: status.isNotEmpty ? status : other.status,
      customerName: customerName.isNotEmpty ? customerName : other.customerName,
      customerPhone: customerPhone.isNotEmpty && customerPhone != '-'
          ? customerPhone
          : other.customerPhone,
      customerAddress: customerAddress.isNotEmpty && customerAddress != 'Address Not Available'
          ? customerAddress
          : other.customerAddress,
      productName: productName.isNotEmpty ? productName : other.productName,
      imageUrl: imageUrl.isNotEmpty ? imageUrl : other.imageUrl,
    );
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static int? _readInt(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value == null) continue;
      if (value is int) return value;
      if (value is num) return value.toInt();
      final parsed = int.tryParse(value.toString().trim());
      if (parsed != null) return parsed;
    }
    return null;
  }

  static String _readString(
    Map<String, dynamic> source,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = source[key];
      if (value == null) continue;
      if (value is Map || value is List) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') {
        return text;
      }
    }
    return fallback;
  }

  static String _fullName(Map<String, dynamic> source) {
    final first = _readString(
      source,
      const ['first_name', 'firstName', 'firstname'],
    );
    final last = _readString(
      source,
      const ['last_name', 'lastName', 'lastname'],
    );
    final full = [first, last]
        .where((part) => part.trim().isNotEmpty)
        .join(' ')
        .trim();
    if (full.isNotEmpty) return full;
    return _readString(
      source,
      const ['customer_name', 'full_name', 'name'],
      fallback: '',
    );
  }

  static String _normalizeId(String raw) {
    return raw.trim().replaceFirst(RegExp(r'^#'), '');
  }

  static List<String> _requestIdKeysForType(String normalizedType) {
    switch (normalizedType) {
      case FieldExecutiveDeliveryTypes.returnRequest:
        return const <String>[
          'request_id',
          'requestId',
          'return_request_id',
          'returnRequestId',
          'id',
        ];
      case FieldExecutiveDeliveryTypes.pickupRequest:
        return const <String>[
          'request_id',
          'requestId',
          'pickup_request_id',
          'pickupRequestId',
          'id',
        ];
      case FieldExecutiveDeliveryTypes.requestPart:
        return const <String>[
          'request_id',
          'requestId',
          'part_request_id',
          'partRequestId',
          'id',
        ];
      default:
        return const <String>[
          'request_id',
          'requestId',
          'return_request_id',
          'pickup_request_id',
          'part_request_id',
          'id',
        ];
    }
  }

  static String _normalizePriority(String raw) {
    final value = raw.trim().toLowerCase();
    if (value.contains('high') || value == '1' || value == 'urgent') {
      return 'High';
    }
    if (value.contains('low') || value == '3') {
      return 'Low';
    }
    return 'Medium';
  }

  static String _readAddress(
    Map<String, dynamic> source,
    Map<String, dynamic> customer,
  ) {
    final candidates = <dynamic>[
      source['customer_address'],
      source['customerAddress'],
      source['address'],
      customer['customer_address'],
      customer['customerAddress'],
      customer['address'],
      source['customer_addresses'],
      customer['customer_addresses'],
      customer,
      source,
    ];

    for (final candidate in candidates) {
      final formatted = _formatAddress(candidate);
      if (formatted.isNotEmpty) return formatted;
    }
    return 'Address Not Available';
  }

  static String _formatAddress(dynamic value) {
    if (value == null) return '';
    if (value is String) {
      final text = value.trim();
      if (text.isEmpty || text.toLowerCase() == 'null') return '';
      return text;
    }
    if (value is List) {
      for (final item in value) {
        final text = _formatAddress(item);
        if (text.isNotEmpty) return text;
      }
      return '';
    }

    final map = _asMap(value);
    if (map == null) return '';

    final branch = _readString(map, const ['branch_name', 'branchName']);
    final line1 = _readString(
      map,
      const ['address1', 'address_1', 'address_line_1', 'line1'],
    );
    final line2 = _readString(
      map,
      const ['address2', 'address_2', 'address_line_2', 'line2'],
    );
    final city = _readString(map, const ['city', 'city_name']);
    final state = _readString(map, const ['state', 'state_name']);
    final country = _readString(map, const ['country', 'country_name']);
    final pincode = _readString(
      map,
      const ['pincode', 'pin_code', 'postal_code', 'zip'],
    );

    final lines = <String>[
      if (branch.isNotEmpty) branch,
      if (line1.isNotEmpty || line2.isNotEmpty)
        [line1, line2].where((part) => part.isNotEmpty).join(', '),
      if (city.isNotEmpty || state.isNotEmpty || country.isNotEmpty || pincode.isNotEmpty)
        [
          [city, state, country].where((part) => part.isNotEmpty).join(', '),
          pincode,
        ].where((part) => part.isNotEmpty).join(' - '),
    ];

    if (lines.isNotEmpty) {
      return lines.join('\n').trim();
    }

    return _readString(
      map,
      const ['full_address', 'formatted_address', 'address', 'location'],
      fallback: '',
    );
  }
}
