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
    final product = json['product'] is Map
        ? Map<String, dynamic>.from(json['product'] as Map)
        : const <String, dynamic>{};

    final id = _toText(json['id']);
    final requestId = _toText(json['request_id']);
    final productName = _toText(product['product_name']);
    final modelNo = _toText(product['model_no']);
    final finalPrice = _toText(product['final_price']);
    final mainProductImage = _toText(product['main_product_image']);
    final status = _toText(json['status']);
    final location = _toText(json['location']);
    final customerName = _toText(json['customer_name']);
    final customerPhone = _toText(json['customer_phone']);
    final customerAddress = _toText(json['customer_address']);

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
      customer_address: customerAddress.isEmpty ? 'N/A' : customerAddress,
    );
  }

  static String _toText(dynamic value) {
    if (value == null) return '';
    if (value is String) return value.trim();
    if (value is num || value is bool) return value.toString();
    return '';
  }
}
