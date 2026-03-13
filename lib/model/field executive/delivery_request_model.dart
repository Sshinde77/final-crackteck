class DeliveryRequestModel {
  final String id;
  final String request_id;
  final String product_name;
  final String model_no;
  final String final_price;
  final String? main_product_image;

  // Optional fields kept for detail-screen navigation compatibility.
  final String status;
  final String location;
  final String customer_name;
  final String customer_phone;
  final String customer_address;

  const DeliveryRequestModel({
    required this.id,
    required this.request_id,
    required this.product_name,
    required this.model_no,
    required this.final_price,
    required this.main_product_image,
    required this.status,
    required this.location,
    required this.customer_name,
    required this.customer_phone,
    required this.customer_address,
  });

  factory DeliveryRequestModel.fromJson(Map<String, dynamic> json) {
    final product = _asMap(
          json['product'],
        ) ??
        _asMap(json['product_detail']) ??
        _asMap(json['product_details']) ??
        _asMap(json['service_request_product']) ??
        const <String, dynamic>{};
    final serviceRequest = _asMap(json['service_request']) ?? const <String, dynamic>{};
    final customer = _asMap(serviceRequest['customer']) ??
        _asMap(json['customer']) ??
        const <String, dynamic>{};
    final customerAddress = _asMap(serviceRequest['customer_address']) ??
        _asMap(json['customer_address']) ??
        const <String, dynamic>{};

    final id = _firstText([
      json['id'],
      json['order_id'],
      json['delivery_id'],
    ]);
    final requestId = _firstText([
      json['request_id'],
      json['order_no'],
      json['order_number'],
      serviceRequest['request_id'],
      id,
    ]);
    final productName = _firstText([
      product['product_name'],
      product['name'],
      json['product_name'],
      json['name'],
    ]);
    final modelNo = _firstText([
      product['model_no'],
      product['model'],
      json['model_no'],
    ]);
    final finalPrice = _firstText([
      product['final_price'],
      product['price'],
      json['final_price'],
      json['total_amount'],
      json['amount'],
    ]);
    final mainProductImage = _firstText([
      product['main_product_image'],
      product['product_image'],
      product['image'],
      json['main_product_image'],
      json['product_image'],
    ]);
    final status = _firstText([
      json['status'],
      json['delivery_status'],
      json['order_status'],
    ]);
    final location = _firstText([
      json['location'],
      customerAddress['branch_name'],
      customerAddress['city'],
    ]);
    final customerName = _firstText([
      _joinName(customer),
      json['customer_name'],
      json['name'],
    ]);
    final customerPhone = _firstText([
      customer['phone'],
      customer['phone_number'],
      json['customer_phone'],
      json['phone'],
    ]);
    final customerAddressText = _firstText([
      _formatAddress(customerAddress),
      json['customer_address'],
      json['address'],
    ]);

    return DeliveryRequestModel(
      id: id,
      request_id: requestId.isEmpty ? 'N/A' : requestId,
      product_name: productName.isEmpty ? 'N/A' : productName,
      model_no: modelNo.isEmpty ? 'N/A' : modelNo,
      final_price: finalPrice.isEmpty ? 'N/A' : finalPrice,
      main_product_image: mainProductImage.isEmpty ? null : mainProductImage,
      status: status.isEmpty ? 'N/A' : status,
      location: location.isEmpty ? 'N/A' : location,
      customer_name: customerName.isEmpty ? 'N/A' : customerName,
      customer_phone: customerPhone.isEmpty ? 'N/A' : customerPhone,
      customer_address: customerAddressText.isEmpty ? 'N/A' : customerAddressText,
    );
  }

  static String _toText(dynamic value) {
    if (value == null) return '';
    if (value is String) return value.trim();
    if (value is num || value is bool) return value.toString();
    return '';
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static String _firstText(List<dynamic> values) {
    for (final value in values) {
      final text = _toText(value);
      if (text.isNotEmpty && text.toLowerCase() != 'null') {
        return text;
      }
    }
    return '';
  }

  static String _joinName(Map<String, dynamic> value) {
    final first = _toText(value['first_name']);
    final last = _toText(value['last_name']);
    return [first, last].where((part) => part.isNotEmpty).join(' ').trim();
  }

  static String _formatAddress(Map<String, dynamic> value) {
    final addressLine = [
      _toText(value['address1']),
      _toText(value['address_1']),
      _toText(value['address2']),
      _toText(value['address_2']),
    ].where((part) => part.isNotEmpty).join(', ');
    final locality = [
      _toText(value['city']),
      _toText(value['state']),
      _toText(value['country']),
      _toText(value['pincode']),
      _toText(value['pin_code']),
    ].where((part) => part.isNotEmpty).join(', ');

    return [addressLine, locality].where((part) => part.isNotEmpty).join(', ');
  }
}
