class ReturnOrderDetailModel {
  const ReturnOrderDetailModel({
    required this.id,
    required this.orderNumber,
    required this.requestId,
    required this.status,
    required this.quantity,
    required this.totalAmount,
    required this.paymentStatus,
    required this.expectedDeliveryDate,
    required this.customerNotes,
    required this.adminNotes,
    required this.customer,
    required this.customerAddress,
    required this.shippingAddress,
    required this.warehouseAddress,
    required this.product,
    required this.payload,
    required this.rawResponse,
  });

  final String id;
  final String orderNumber;
  final String requestId;
  final String status;
  final String quantity;
  final String totalAmount;
  final String paymentStatus;
  final String expectedDeliveryDate;
  final String customerNotes;
  final String adminNotes;
  final ReturnOrderCustomer customer;
  final ReturnOrderAddress customerAddress;
  final ReturnOrderAddress shippingAddress;
  final ReturnOrderAddress warehouseAddress;
  final ReturnOrderProduct product;
  final Map<String, dynamic> payload;
  final Map<String, dynamic> rawResponse;

  bool get hasData =>
      _hasVisibleText(id) ||
      _hasVisibleText(orderNumber) ||
      _hasVisibleText(requestId) ||
      customer.hasData ||
      customerAddress.hasData ||
      shippingAddress.hasData ||
      warehouseAddress.hasData ||
      product.hasData;

  factory ReturnOrderDetailModel.fromJson(
    Map<String, dynamic> json, {
    String? fallbackOrderId,
  }) {
    final data = _asMap(json['data']);
    final payload =
        _asMap(json['return_order']) ??
        _asMap(data?['return_order']) ??
        _asMap(json['order']) ??
        _asMap(data?['order']) ??
        data ??
        Map<String, dynamic>.from(json);
    final serviceRequest = _firstMap(<dynamic>[
      payload['service_request'],
      data?['service_request'],
      json['service_request'],
    ]);
    final firstOrderItem = _firstMap(<dynamic>[
      _firstListMap(payload['order_items']),
      payload['product'],
      data?['product'],
    ]);
    final productDetails = _firstMap(<dynamic>[
      firstOrderItem['product_details'],
      payload['product_details'],
      payload['product'],
      data?['product_details'],
      data?['product'],
      json['product'],
    ]);
    final warehouse = _firstMap(<dynamic>[
      payload['primary_warehouse'],
      json['primary_warehouse'],
      payload['warehouse'],
      firstOrderItem['warehouse_details'],
      productDetails['warehouse'],
    ]);
    final shippingAddress = _firstMap(<dynamic>[
      payload['shipping_address'],
      payload['address_detail'],
      serviceRequest['address_detail'],
      json['shipping_address'],
      json['address_detail'],
    ]);
    final customerAddress = _firstMap(<dynamic>[
      payload['customer_address'],
      payload['address_detail'],
      serviceRequest['customer_address'],
      shippingAddress,
      json['customer_address'],
      json['address_detail'],
    ]);
    final customer = _firstMap(<dynamic>[
      payload['customer'],
      payload['customer_details'],
      serviceRequest['customer'],
      serviceRequest['customer_details'],
      json['customer'],
      json['customer_details'],
    ]);

    return ReturnOrderDetailModel(
      id: _firstNonEmpty(<dynamic>[
        payload['id'],
        payload['order_id'],
        payload['request_id'],
        fallbackOrderId,
      ]),
      orderNumber: _firstNonEmpty(<dynamic>[
        payload['order_number'],
        payload['display_id'],
        payload['order_id'],
        payload['id'],
        fallbackOrderId,
      ]),
      requestId: _firstNonEmpty(<dynamic>[
        serviceRequest['request_id'],
        payload['request_id'],
      ]),
      status: _firstNonEmpty(<dynamic>[
        payload['status'],
        payload['order_status'],
      ]),
      quantity: _firstNonEmpty(<dynamic>[
        firstOrderItem['quantity'],
        payload['requested_quantity'],
        payload['quantity'],
        payload['total_items'],
      ], fallback: '1'),
      totalAmount: _firstNonEmpty(<dynamic>[
        payload['total_amount'],
        firstOrderItem['line_total'],
        firstOrderItem['unit_price'],
        payload['final_price'],
      ], fallback: ''),
      paymentStatus: _firstNonEmpty(<dynamic>[
        payload['payment_status'],
      ], fallback: ''),
      expectedDeliveryDate: _firstNonEmpty(<dynamic>[
        payload['expected_delivery_date'],
        payload['delivery_date'],
        payload['created_at'],
      ], fallback: ''),
      customerNotes: _firstNonEmpty(<dynamic>[
        payload['customer_notes'],
        payload['notes'],
      ], fallback: ''),
      adminNotes: _firstNonEmpty(<dynamic>[
        payload['admin_notes'],
        payload['remark'],
        payload['remarks'],
      ], fallback: ''),
      customer: ReturnOrderCustomer.fromMap(customer),
      customerAddress: ReturnOrderAddress.fromMap(customerAddress),
      shippingAddress: ReturnOrderAddress.fromMap(shippingAddress),
      warehouseAddress: ReturnOrderAddress.fromMap(warehouse),
      product: ReturnOrderProduct.fromSources(
        item: firstOrderItem,
        productDetails: productDetails,
      ),
      payload: Map<String, dynamic>.from(payload),
      rawResponse: Map<String, dynamic>.from(json),
    );
  }
}

class ReturnOrderCustomer {
  const ReturnOrderCustomer({
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.phone,
    required this.email,
  });

  final String firstName;
  final String lastName;
  final String fullName;
  final String phone;
  final String email;

  bool get hasData =>
      _hasVisibleText(firstName) ||
      _hasVisibleText(lastName) ||
      _hasVisibleText(fullName) ||
      _hasVisibleText(phone) ||
      _hasVisibleText(email);

  String get name => _firstNonEmpty(<dynamic>[
    _joinNonEmpty(<String>[firstName, lastName]),
    fullName,
  ], fallback: '');

  factory ReturnOrderCustomer.fromMap(Map<String, dynamic>? source) {
    final map = source ?? const <String, dynamic>{};
    return ReturnOrderCustomer(
      firstName: _firstNonEmpty(<dynamic>[
        map['first_name'],
        map['firstName'],
        map['firstname'],
      ], fallback: ''),
      lastName: _firstNonEmpty(<dynamic>[
        map['last_name'],
        map['lastName'],
        map['lastname'],
      ], fallback: ''),
      fullName: _firstNonEmpty(<dynamic>[
        map['name'],
        map['full_name'],
        map['customer_name'],
      ], fallback: ''),
      phone: _firstNonEmpty(<dynamic>[
        map['phone'],
        map['phone_number'],
        map['mobile'],
        map['mobile_number'],
        map['contact_number'],
      ], fallback: ''),
      email: _firstNonEmpty(<dynamic>[
        map['email'],
        map['email_id'],
      ], fallback: ''),
    );
  }
}

class ReturnOrderAddress {
  const ReturnOrderAddress({
    required this.name,
    required this.branchName,
    required this.address1,
    required this.address2,
    required this.city,
    required this.state,
    required this.country,
    required this.pincode,
    required this.phoneNumber,
    required this.warehouseCode,
  });

  final String name;
  final String branchName;
  final String address1;
  final String address2;
  final String city;
  final String state;
  final String country;
  final String pincode;
  final String phoneNumber;
  final String warehouseCode;

  bool get hasData =>
      _hasVisibleText(name) ||
      _hasVisibleText(branchName) ||
      _hasVisibleText(address1) ||
      _hasVisibleText(address2) ||
      _hasVisibleText(city) ||
      _hasVisibleText(state) ||
      _hasVisibleText(country) ||
      _hasVisibleText(pincode);

  String get formatted => _joinNonEmpty(<String>[
    name,
    branchName,
    address1,
    address2,
    city,
    state,
    country,
    pincode,
  ]);

  String get primaryLabel => _firstNonEmpty(<dynamic>[
    name,
    branchName,
    formatted,
  ], fallback: '');

  factory ReturnOrderAddress.fromMap(Map<String, dynamic>? source) {
    final map = source ?? const <String, dynamic>{};
    return ReturnOrderAddress(
      name: _firstNonEmpty(<dynamic>[map['name']], fallback: ''),
      branchName: _firstNonEmpty(<dynamic>[map['branch_name']], fallback: ''),
      address1: _firstNonEmpty(<dynamic>[
        map['address1'],
        map['address_1'],
        map['street'],
      ], fallback: ''),
      address2: _firstNonEmpty(<dynamic>[
        map['address2'],
        map['address_2'],
        map['locality'],
      ], fallback: ''),
      city: _firstNonEmpty(<dynamic>[map['city']], fallback: ''),
      state: _firstNonEmpty(<dynamic>[map['state']], fallback: ''),
      country: _firstNonEmpty(<dynamic>[map['country']], fallback: ''),
      pincode: _firstNonEmpty(<dynamic>[
        map['pincode'],
        map['pin_code'],
      ], fallback: ''),
      phoneNumber: _firstNonEmpty(<dynamic>[
        map['phone_number'],
        map['phone'],
        map['contact_number'],
      ], fallback: ''),
      warehouseCode: _firstNonEmpty(<dynamic>[
        map['warehouse_code'],
      ], fallback: ''),
    );
  }
}

class ReturnOrderProduct {
  const ReturnOrderProduct({
    required this.productName,
    required this.modelNo,
    required this.macAddress,
    required this.imageUrl,
    required this.unitPrice,
    required this.hsnCode,
    required this.weight,
    required this.dimensions,
    required this.shippingTime,
    required this.brandWarranty,
    required this.cod,
    required this.installation,
  });

  final String productName;
  final String modelNo;
  final String macAddress;
  final String imageUrl;
  final String unitPrice;
  final String hsnCode;
  final String weight;
  final String dimensions;
  final String shippingTime;
  final String brandWarranty;
  final String cod;
  final String installation;

  bool get hasData =>
      _hasVisibleText(productName) ||
      _hasVisibleText(modelNo) ||
      _hasVisibleText(macAddress) ||
      _hasVisibleText(imageUrl);

  factory ReturnOrderProduct.fromSources({
    Map<String, dynamic>? item,
    Map<String, dynamic>? productDetails,
  }) {
    final orderItem = item ?? const <String, dynamic>{};
    final details = productDetails ?? const <String, dynamic>{};
    return ReturnOrderProduct(
      productName: _firstNonEmpty(<dynamic>[
        orderItem['product_name'],
        details['product_name'],
        orderItem['name'],
      ], fallback: ''),
      modelNo: _firstNonEmpty(<dynamic>[
        details['model_no'],
        orderItem['model_no'],
        orderItem['model'],
      ], fallback: ''),
      macAddress: _firstNonEmpty(<dynamic>[
        orderItem['mac_address'],
        orderItem['macAddress'],
        details['mac_address'],
        details['macAddress'],
      ], fallback: ''),
      imageUrl: _firstNonEmpty(<dynamic>[
        details['main_product_image'],
        orderItem['main_product_image'],
        orderItem['product_image'],
        orderItem['image'],
      ], fallback: ''),
      unitPrice: _firstNonEmpty(<dynamic>[
        orderItem['unit_price'],
        orderItem['line_total'],
        details['final_price'],
      ], fallback: ''),
      hsnCode: _firstNonEmpty(<dynamic>[
        orderItem['hsn_code'],
        details['hsn_code'],
      ], fallback: ''),
      weight: _firstNonEmpty(<dynamic>[
        orderItem['weight'],
        details['weight'],
      ], fallback: ''),
      dimensions: _firstNonEmpty(<dynamic>[
        orderItem['dimensions'],
        details['dimensions'],
      ], fallback: ''),
      shippingTime: _firstNonEmpty(<dynamic>[
        orderItem['shipping_time'],
        details['shipping_time'],
      ], fallback: ''),
      brandWarranty: _firstNonEmpty(<dynamic>[
        details['brand_warranty'],
      ], fallback: ''),
      cod: _firstNonEmpty(<dynamic>[
        orderItem['cod'],
        details['cod'],
      ], fallback: ''),
      installation: _firstNonEmpty(<dynamic>[
        orderItem['installation'],
        details['installation'],
      ], fallback: ''),
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

Map<String, dynamic> _firstMap(List<dynamic> values) {
  for (final value in values) {
    final mapped = _asMap(value);
    if (mapped != null && mapped.isNotEmpty) {
      return mapped;
    }
  }
  return const <String, dynamic>{};
}

Map<String, dynamic>? _firstListMap(dynamic value) {
  if (value is! List) return null;
  for (final item in value) {
    final mapped = _asMap(item);
    if (mapped != null && mapped.isNotEmpty) {
      return mapped;
    }
  }
  return null;
}

String _asText(dynamic value) {
  if (value == null) return '';
  if (value is String) return value.trim();
  if (value is num || value is bool) return value.toString();
  return '';
}

String _firstNonEmpty(List<dynamic> values, {String fallback = ''}) {
  for (final value in values) {
    final parsed = _asText(value);
    if (_hasVisibleText(parsed)) {
      return parsed;
    }
  }
  return fallback;
}

bool _hasVisibleText(String value) {
  final normalized = value.trim().toLowerCase();
  return normalized.isNotEmpty && normalized != 'null' && normalized != 'n/a';
}

String _joinNonEmpty(List<String> values, {String separator = ', '}) {
  return values
      .map((value) => value.trim())
      .where(_hasVisibleText)
      .join(separator);
}
