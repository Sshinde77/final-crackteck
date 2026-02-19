class RequestedProduct {
  final String id;
  final String image;
  final String productName;
  final String modelNo;
  final String shortDescription;
  final String finalPrice;
  final String fullDescription;
  final String technicalSpecification;
  final String brandWarranty;
  final String companyWarranty;
  final int quantity;

  const RequestedProduct({
    required this.id,
    required this.image,
    required this.productName,
    required this.modelNo,
    required this.shortDescription,
    required this.finalPrice,
    required this.fullDescription,
    required this.technicalSpecification,
    required this.brandWarranty,
    required this.companyWarranty,
    required this.quantity,
  });

  RequestedProduct copyWith({
    String? id,
    String? image,
    String? productName,
    String? modelNo,
    String? shortDescription,
    String? finalPrice,
    String? fullDescription,
    String? technicalSpecification,
    String? brandWarranty,
    String? companyWarranty,
    int? quantity,
  }) {
    return RequestedProduct(
      id: id ?? this.id,
      image: image ?? this.image,
      productName: productName ?? this.productName,
      modelNo: modelNo ?? this.modelNo,
      shortDescription: shortDescription ?? this.shortDescription,
      finalPrice: finalPrice ?? this.finalPrice,
      fullDescription: fullDescription ?? this.fullDescription,
      technicalSpecification:
          technicalSpecification ?? this.technicalSpecification,
      brandWarranty: brandWarranty ?? this.brandWarranty,
      companyWarranty: companyWarranty ?? this.companyWarranty,
      quantity: quantity ?? this.quantity,
    );
  }
}
