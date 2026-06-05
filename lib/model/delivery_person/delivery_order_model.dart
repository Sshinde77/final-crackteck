enum DeliveryOrderStatus { pending, delivered, cancelled }

enum DeliveryOrderCategory {
  productDelivery,
  pickupDelivery,
  requestPart,
  returnRequest,
  returnProduct,
}

class DeliveryOrderModel {
  DeliveryOrderModel({
    required this.id,
    required this.displayId,
    this.requestId = '',
    required this.date,
    required this.time,
    required this.from,
    required this.to,
    required this.accepted,
    required this.rawStatus,
    required this.status,
    required this.category,
  });

  final String id;
  final String displayId;
  final String requestId;
  final String date;
  final String time;
  final String from;
  final String to;
  final bool accepted;
  final String rawStatus;
  final DeliveryOrderStatus status;
  final DeliveryOrderCategory category;
  bool get isDelivered => status == DeliveryOrderStatus.delivered;

  factory DeliveryOrderModel.fromJson(Map<String, dynamic> json) {
    final statusText =
        (json['status'] ??
                json['order_status'] ??
                json['delivery_status'] ??
                json['state'] ??
                '')
            .toString()
            .toLowerCase();
    final compactStatus = statusText.replaceAll(RegExp(r'[^a-z]'), '');
    final category = _parseCategory(json);

    final isReturnFlow =
        category == DeliveryOrderCategory.returnRequest ||
        category == DeliveryOrderCategory.returnProduct;
    final from = isReturnFlow
        ? _returnFromAddress(json)
        : _readAddress(
            json,
            <String>[
              'from_address',
              'pickup_address',
              'warehouse_address',
              'warehouse',
              'from',
              'source',
            ],
            fallback:
                _warehouseName(json) ??
                _formatNestedAddress(json['warehouse_details']) ??
                'Warehouse',
          );
    final to = isReturnFlow
        ? _returnToAddress(json)
        : _readAddress(
            json,
            <String>[
              'to_address',
              'delivery_address',
              'customer_address',
              'address',
              'to',
            ],
            fallback:
                _formatNestedAddress(json['shipping_address']) ??
                'Customer address not available',
          );
    final rawDate =
        json['date'] ??
        json['order_date'] ??
        json['created_at'] ??
        json['updated_at'] ??
        '';
    final parsed = DateTime.tryParse(rawDate.toString());
    final rawId =
        (json['display_id'] ??
                json['order_id'] ??
                json['id'] ??
                json['request_id'] ??
                'NA')
            .toString();
    final normalizedId = rawId.startsWith('#') ? rawId : '#$rawId';
    final displayId =
        (json['order_number'] ??
                json['display_id'] ??
                json['order_id'] ??
                json['id'] ??
                json['request_id'] ??
                'NA')
            .toString();
    final nestedServiceRequest = json['service_request'];
    final serviceRequestId = nestedServiceRequest is Map
        ? nestedServiceRequest['request_id'] ??
              nestedServiceRequest['requestId']
        : null;
    final requestId =
        (serviceRequestId ?? json['request_id'] ?? json['requestId'] ?? '')
            .toString();
    final isDelivered = _isDelivered(json, compactStatus);
    final isCancelled = _isCancelled(json, compactStatus);

    return DeliveryOrderModel(
      id: normalizedId,
      displayId: displayId,
      requestId: requestId,
      date: parsed == null
          ? (rawDate.toString().isEmpty ? '--' : rawDate.toString())
          : '${parsed.day}-${parsed.month}-${parsed.year}',
      time: parsed == null
          ? (json['time']?.toString() ?? '--')
          : formatTime(parsed),
      from: from,
      to: to,
      accepted:
          isDelivered ||
          compactStatus.contains('accept') ||
          compactStatus.contains('assigned') ||
          compactStatus.contains('picked') ||
          compactStatus.contains('inprogress') ||
          compactStatus.contains('approved'),
      rawStatus: statusText,
      status: isCancelled
          ? DeliveryOrderStatus.cancelled
          : isDelivered
          ? DeliveryOrderStatus.delivered
          : DeliveryOrderStatus.pending,
      category: category,
    );
  }

  DeliveryOrderModel copyWith({
    String? id,
    String? displayId,
    String? requestId,
    String? date,
    String? time,
    String? from,
    String? to,
    bool? accepted,
    String? rawStatus,
    DeliveryOrderStatus? status,
    DeliveryOrderCategory? category,
  }) {
    return DeliveryOrderModel(
      id: id ?? this.id,
      displayId: displayId ?? this.displayId,
      requestId: requestId ?? this.requestId,
      date: date ?? this.date,
      time: time ?? this.time,
      from: from ?? this.from,
      to: to ?? this.to,
      accepted: accepted ?? this.accepted,
      rawStatus: rawStatus ?? this.rawStatus,
      status: status ?? this.status,
      category: category ?? this.category,
    );
  }

  static DeliveryOrderCategory _parseCategory(Map<String, dynamic> json) {
    final rawCategory =
        <dynamic>[
              json['request_type'],
              json['delivery_type'],
              json['type'],
              json['order_type'],
              json['request_category'],
              json['category'],
              json['service_type'],
            ]
            .firstWhere(
              (value) => value != null && value.toString().trim().isNotEmpty,
              orElse: () => '',
            )
            .toString()
            .toLowerCase();

    final compact = rawCategory.replaceAll(RegExp(r'[^a-z]'), '');

    if (compact.contains('pickup')) {
      return DeliveryOrderCategory.pickupDelivery;
    }
    if (compact.contains('requestpart') || compact.contains('partrequest')) {
      return DeliveryOrderCategory.requestPart;
    }
    if (compact.contains('returnorder') || compact.contains('returnproduct')) {
      return DeliveryOrderCategory.returnProduct;
    }
    if (compact.contains('return')) {
      return DeliveryOrderCategory.returnRequest;
    }
    return DeliveryOrderCategory.productDelivery;
  }

  static String _readAddress(
    Map<String, dynamic> json,
    List<String> keys, {
    required String fallback,
  }) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;

      if (value is Map) {
        final name = value['name']?.toString().trim();
        if (name != null && name.isNotEmpty) {
          return name;
        }

        final formatted = _formatNestedAddress(value);
        if (formatted != null && formatted.trim().isNotEmpty) {
          return formatted;
        }

        continue;
      }

      final text = value.toString().trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
    return fallback;
  }

  static String? _formatNestedAddress(dynamic value) {
    if (value is! Map) return null;
    final map = Map<String, dynamic>.from(value);
    final parts = <String>[
      map['name']?.toString() ?? '',
      map['branch_name']?.toString() ?? '',
      map['address_detail']?.toString() ?? '',
      map['address1']?.toString() ?? '',
      map['address_1']?.toString() ?? '',
      map['address2']?.toString() ?? '',
      map['address_2']?.toString() ?? '',
      map['street']?.toString() ?? '',
      map['locality']?.toString() ?? '',
      map['city']?.toString() ?? '',
      map['state']?.toString() ?? '',
      map['country']?.toString() ?? '',
      map['pincode']?.toString() ?? '',
      map['pin_code']?.toString() ?? '',
    ].where((part) => part.trim().isNotEmpty).toList();

    if (parts.isEmpty) return null;
    return parts.join(', ');
  }

  static bool _isCancelled(Map<String, dynamic> json, String compactStatus) {
    if (_hasValue(json['cancelled_at'])) {
      return true;
    }
    return compactStatus.contains('cancel') ||
        compactStatus.contains('reject');
  }

  static bool _isDelivered(Map<String, dynamic> json, String compactStatus) {
    if (_hasValue(json['delivered_at'])) {
      return true;
    }

    final deliveredStatuses = <String>{
      'delivered',
      'completed',
      'orderdelivered',
      'returnorderdelivered',
      'returnrequestdelivered',
    };
    if (deliveredStatuses.contains(compactStatus)) {
      return true;
    }

    final orderItems = json['order_items'];
    if (orderItems is List && orderItems.isNotEmpty) {
      final itemStatuses = orderItems
          .whereType<Map>()
          .map((item) => (item['item_status'] ?? '').toString().trim().toLowerCase())
          .where((status) => status.isNotEmpty)
          .toList();
      if (itemStatuses.isNotEmpty &&
          itemStatuses.every(
            (status) => status == 'delivered' || status == 'completed',
          )) {
        return true;
      }
    }

    return false;
  }

  static bool _hasValue(dynamic value) {
    if (value == null) return false;
    return value.toString().trim().isNotEmpty;
  }

  static String? _warehouseName(Map<String, dynamic> json) {
    final warehouseDetails = json['warehouse_details'];
    if (warehouseDetails is Map && warehouseDetails['name'] != null) {
      final name = warehouseDetails['name'].toString().trim();
      if (name.isNotEmpty) return name;
    }

    final orderItems = json['order_items'];
    if (orderItems is List && orderItems.isNotEmpty) {
      final firstItem = orderItems.first;
      if (firstItem is Map) {
        final productDetails = firstItem['product_details'];
        if (productDetails is Map) {
          final warehouse = productDetails['warehouse'];
          if (warehouse is Map && warehouse['name'] != null) {
            final name = warehouse['name'].toString().trim();
            if (name.isNotEmpty) return name;
          }
        }
      }
    }

    return null;
  }

  static String _returnFromAddress(Map<String, dynamic> json) {
    final candidates = <dynamic>[
      json['primary_warehouse'],
      json['warehouse_details'],
      json['warehouse'],
      (json['return_request'] is Map)
          ? (json['return_request'] as Map)['primary_warehouse']
          : null,
      (json['return_request'] is Map)
          ? (json['return_request'] as Map)['warehouse_details']
          : null,
      (json['return_request'] is Map)
          ? (json['return_request'] as Map)['warehouse']
          : null,
    ];

    for (final candidate in candidates) {
      if (candidate is Map) {
        final map = Map<String, dynamic>.from(candidate);
        final formatted = _formatNestedAddress(map);
        if (formatted != null && formatted.isNotEmpty) {
          return formatted;
        }
        final name = map['name']?.toString().trim();
        if (name != null && name.isNotEmpty) {
          return name;
        }
      } else if (candidate != null) {
        final text = candidate.toString().trim();
        if (text.isNotEmpty) {
          return text;
        }
      }
    }

    final formatted = _formatNestedAddress(json['primary_warehouse']);
    if (formatted != null && formatted.isNotEmpty) {
      return formatted;
    }

    final nestedFormatted = _formatNestedAddress(
      (json['return_request'] is Map)
          ? (json['return_request'] as Map)['primary_warehouse']
          : null,
    );
    if (nestedFormatted != null && nestedFormatted.isNotEmpty) {
      return nestedFormatted;
    }

    return _readAddress(
      json,
      const ['warehouse_address', 'warehouse', 'from', 'source'],
      fallback:
          _warehouseName(json) ??
          _formatNestedAddress(json['warehouse_details']) ??
          'Warehouse',
    );
  }

  static String _returnToAddress(Map<String, dynamic> json) {
    final serviceRequest = json['service_request'];
    final candidates = <dynamic>[
      json['address_detail'],
      json['customer_address'],
      json['shipping_address'],
      serviceRequest is Map ? serviceRequest['address_detail'] : null,
      serviceRequest is Map ? serviceRequest['customer_address'] : null,
      serviceRequest is Map ? serviceRequest['shipping_address'] : null,
      (json['return_request'] is Map)
          ? (json['return_request'] as Map)['address_detail']
          : null,
      (json['return_request'] is Map)
          ? (json['return_request'] as Map)['customer_address']
          : null,
      (json['return_request'] is Map)
          ? (json['return_request'] as Map)['shipping_address']
          : null,
    ];

    for (final candidate in candidates) {
      if (candidate is Map) {
        final formatted = _formatNestedAddress(candidate);
        if (formatted != null && formatted.isNotEmpty) {
          return formatted;
        }
      } else if (candidate != null) {
        final text = candidate.toString().trim();
        if (text.isNotEmpty) {
          return text;
        }
      }
    }

    return _readAddress(
      json,
      const ['to_address', 'delivery_address', 'customer_address', 'address', 'to'],
      fallback:
          _formatNestedAddress(json['shipping_address']) ??
          'Customer address not available',
    );
  }

  static String formatTime(DateTime dateTime) {
    int hour = dateTime.hour % 12;
    if (hour == 0) hour = 12;
    final suffix = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} $suffix';
  }
}
