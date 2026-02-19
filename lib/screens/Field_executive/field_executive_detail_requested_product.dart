import 'package:flutter/material.dart';

import '../../constants/api_constants.dart';
import '../../constants/app_strings.dart';
import '../../model/field executive/requested_product.dart';
import '../../routes/app_routes.dart';
import '../../services/api_service.dart';
import '../../services/requested_products_store.dart';

class ProductRequestedDetailScreen extends StatefulWidget {
  final int roleId;
  final String roleName;
  final String productId;

  const ProductRequestedDetailScreen({
    super.key,
    required this.roleId,
    required this.roleName,
    this.productId = '',
  });

  @override
  State<ProductRequestedDetailScreen> createState() =>
      _ProductRequestedDetailScreenState();
}

class _ProductRequestedDetailScreenState
    extends State<ProductRequestedDetailScreen> {
  static const Color primaryGreen = Color(0xFF2E7D32);

  bool _isLoading = true;
  String? _error;
  int qty = 1;
  _RequestedProductData _product = const _RequestedProductData.empty();

  @override
  void initState() {
    super.initState();
    _loadProductDetail();
  }

  Future<void> _loadProductDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final detail = await ApiService.fetchFieldExecutiveProductDetail(
        widget.productId,
        roleId: widget.roleId,
      );
      final mapped = _mapProduct(detail);
      if (!mounted) return;
      setState(() {
        _product = mapped;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '').trim();
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  String _readText(Map<String, dynamic>? source, List<String> keys) {
    if (source == null) return '';
    for (final key in keys) {
      final value = source[key];
      if (value == null || value is Map || value is List) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
    }
    return '';
  }

  String _normalizeImageSource(String raw) {
    final value = raw.trim();
    if (value.isEmpty || value.toLowerCase() == 'null') return '';

    final parsed = Uri.tryParse(value);
    if (parsed != null && parsed.hasScheme) {
      final scheme = parsed.scheme.toLowerCase();
      if (scheme == 'http' || scheme == 'https') return parsed.toString();
      return '';
    }

    final base = Uri.parse(ApiConstants.baseUrl);
    final origin = Uri(
      scheme: base.scheme,
      host: base.host,
      port: base.hasPort ? base.port : null,
    );

    final relative = value.startsWith('//')
        ? Uri.parse('https:$value')
        : value.startsWith('/')
            ? Uri.parse(value)
            : Uri.parse('/$value');

    return origin.resolveUri(relative).toString();
  }

  String _readImage(Map<String, dynamic>? source) {
    if (source == null) return '';
    for (final key in const [
      'main_product_image',
      'product_image',
      'image_url',
      'image',
      'thumbnail',
      'thumb',
      'path',
      'url',
    ]) {
      final value = source[key];
      if (value is String) {
        final normalized = _normalizeImageSource(value);
        if (normalized.isNotEmpty) return normalized;
      }
    }
    return '';
  }

  String _formatPrice(String rawPrice) {
    final price = rawPrice.trim();
    if (price.isEmpty) return '-';
    if (price.contains('\u20B9')) return price;
    return '\u20B9 $price';
  }

  _RequestedProductData _mapProduct(Map<String, dynamic> detail) {
    final product = _asMap(detail['product']) ?? _asMap(detail['products']);
    final source = product ?? detail;

    final image = _readImage(source);
    final productName = _readText(
      source,
      const ['product_name', 'name', 'title'],
    );
    final modelNo = _readText(
      source,
      const ['model_no', 'model_number', 'model', 'modelNo'],
    );
    final shortDescription = _readText(
      source,
      const ['short_description', 'short_desc', 'subtitle'],
    );
    final finalPrice = _readText(
      source,
      const ['final_price', 'selling_price', 'price', 'amount'],
    );
    final fullDescription = _readText(
      source,
      const ['full_description', 'description', 'long_description', 'details'],
    );
    final technicalSpecification = _readText(
      source,
      const [
        'technical_specification',
        'technical_specifications',
        'specification',
        'specifications',
      ],
    );
    final brandWarranty = _readText(
      source,
      const ['brand_warranty', 'warranty', 'brandWarranty'],
    );
    final companyWarranty = _readText(
      source,
      const ['company_warranty', 'companyWarranty'],
    );
    final totalRequestedQuantity = _readText(
      source,
      const ['total_requested_quantity', 'requested_quantity', 'quantity', 'qty'],
    );

    return _RequestedProductData(
      image: image.isEmpty ? 'assets/products/motherboard.png' : image,
      productName: productName.isEmpty ? '-' : productName,
      modelNo: modelNo.isEmpty ? '-' : modelNo,
      shortDescription: shortDescription.isEmpty ? '-' : shortDescription,
      finalPrice: _formatPrice(finalPrice),
      fullDescription: fullDescription.isEmpty ? '-' : fullDescription,
      technicalSpecification:
          technicalSpecification.isEmpty ? '-' : technicalSpecification,
      brandWarranty: brandWarranty.isEmpty ? '-' : brandWarranty,
      companyWarranty: companyWarranty.isEmpty ? '-' : companyWarranty,
      totalRequestedQuantity:
          totalRequestedQuantity.isEmpty ? '2' : totalRequestedQuantity,
    );
  }

  String get _resolvedProductId {
    final normalized = widget.productId.trim().replaceFirst(RegExp(r'^#'), '');
    if (normalized.isNotEmpty) return normalized;
    return _product.productName.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
  }

  void _addRequestedProductToStore() {
    final product = RequestedProduct(
      id: _resolvedProductId,
      image: _product.image,
      productName: _product.productName,
      modelNo: _product.modelNo,
      shortDescription: _product.shortDescription,
      finalPrice: _product.finalPrice,
      fullDescription: _product.fullDescription,
      technicalSpecification: _product.technicalSpecification,
      brandWarranty: _product.brandWarranty,
      companyWarranty: _product.companyWarranty,
      quantity: qty < 1 ? 1 : qty,
    );

    RequestedProductsStore.instance.addOrUpdateProduct(product);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          AppStrings.productTitle,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _error!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.black54),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: _loadProductDetail,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryGreen,
                                  ),
                                  child: const Text(
                                    'Retry',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildImageCard(_product.image),
                              const SizedBox(height: 14),
                              _buildHeaderCard(_product),
                              const SizedBox(height: 14),
                              _buildTextCard(
                                'Short Description',
                                _product.shortDescription,
                              ),
                              const SizedBox(height: 12),
                              _buildTextCard(
                                'Full Description',
                                _product.fullDescription,
                              ),
                              const SizedBox(height: 12),
                              _buildTextCard(
                                'Technical Specification',
                                _product.technicalSpecification,
                              ),
                              const SizedBox(height: 12),
                              _buildInfoGrid(_product),
                            ],
                          ),
                        ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Row(
                    children: [
                      _qtyButton(Icons.remove, () {
                        if (qty > 1) {
                          setState(() => qty--);
                        }
                      }),
                      Container(
                        width: 40,
                        alignment: Alignment.center,
                        child: Text(
                          qty.toString(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      _qtyButton(Icons.add, () {
                        setState(() => qty++);
                      }),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          _addRequestedProductToStore();
                          Navigator.pushNamed(
                            context,
                            AppRoutes.FieldExecutiveProductListToAddMoreScreen,
                            arguments: fieldexecutiveproductlisttoaddmoreArguments(
                              roleId: widget.roleId,
                              roleName: widget.roleName,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          AppStrings.addButton,
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCard(String imagePathOrUrl) {
    final isNetwork = imagePathOrUrl.startsWith('http://') ||
        imagePathOrUrl.startsWith('https://');

    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7EAF0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: isNetwork
            ? Image.network(
                imagePathOrUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: Colors.grey,
                      size: 40,
                    ),
                  );
                },
              )
            : Image.asset(
                imagePathOrUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: Colors.grey,
                      size: 40,
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildHeaderCard(_RequestedProductData data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7EAF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.productName,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Model No: ${data.modelNo}',
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                data.finalPrice,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF163B18),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF8EC),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  'Qty: ${data.totalRequestedQuantity}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF176A21),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextCard(String title, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7EAF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGrid(_RequestedProductData data) {
    return Row(
      children: [
        Expanded(
          child: _buildMiniInfoCard(
            title: 'Brand Warranty',
            value: data.brandWarranty,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMiniInfoCard(
            title: 'Company Warranty',
            value: data.companyWarranty,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniInfoCard({
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7EAF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: primaryGreen,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

class _RequestedProductData {
  final String image;
  final String productName;
  final String modelNo;
  final String shortDescription;
  final String finalPrice;
  final String fullDescription;
  final String technicalSpecification;
  final String brandWarranty;
  final String companyWarranty;
  final String totalRequestedQuantity;

  const _RequestedProductData({
    required this.image,
    required this.productName,
    required this.modelNo,
    required this.shortDescription,
    required this.finalPrice,
    required this.fullDescription,
    required this.technicalSpecification,
    required this.brandWarranty,
    required this.companyWarranty,
    required this.totalRequestedQuantity,
  });

  const _RequestedProductData.empty()
      : image = 'assets/products/motherboard.png',
        productName = '-',
        modelNo = '-',
        shortDescription = '-',
        finalPrice = '-',
        fullDescription = '-',
        technicalSpecification = '-',
        brandWarranty = '-',
        companyWarranty = '-',
        totalRequestedQuantity = '2';
}
