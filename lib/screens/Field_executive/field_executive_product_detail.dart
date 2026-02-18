import 'package:flutter/material.dart';

import '../../constants/api_constants.dart';
import '../../constants/app_strings.dart';
import '../../routes/app_routes.dart';
import '../../services/api_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final int roleId;
  final String roleName;
  final String productId;

  const ProductDetailScreen({
    super.key,
    required this.roleId,
    required this.roleName,
    this.productId = '',
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  static const Color primaryGreen = Color(0xFF2E7D32);

  bool _isLoading = true;
  String? _error;
  _ProductDetailData _product = const _ProductDetailData.empty();

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
      final item = await ApiService.fetchStockInHandProductById(
        widget.productId,
        roleId: widget.roleId,
      );
      final product = _mapProductDetail(item);
      if (!mounted) return;
      setState(() {
        _product = product;
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

  _ProductDetailData _mapProductDetail(Map<String, dynamic> item) {
    final products = _asMap(item['products']);

    final image = _readImage(products) != ''
        ? _readImage(products)
        : _readImage(item);
    final productName = _readText(
      products ?? item,
      const ['product_name', 'name', 'title'],
    );
    final modelNo = _readText(
      products ?? item,
      const ['model_no', 'model_number', 'model', 'modelNo'],
    );
    final shortDescription = _readText(
      products ?? item,
      const ['short_description', 'short_desc', 'subtitle'],
    );
    final finalPrice = _readText(
      products ?? item,
      const ['final_price', 'selling_price', 'price', 'amount'],
    );
    final fullDescription = _readText(
      products ?? item,
      const ['full_description', 'description', 'long_description', 'details'],
    );
    final technicalSpecification = _readText(
      products ?? item,
      const [
        'technical_specification',
        'technical_specifications',
        'specification',
        'specifications',
      ],
    );
    final brandWarranty = _readText(
      products ?? item,
      const ['brand_warranty', 'warranty', 'brandWarranty'],
    );
    final companyWarranty = _readText(
      products ?? item,
      const ['company_warranty', 'companyWarranty'],
    );
    final totalRequestedQuantity = _readText(
      item,
      const ['total_requested_quantity', 'requested_quantity', 'quantity', 'qty'],
    );

    return _ProductDetailData(
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
          totalRequestedQuantity.isEmpty ? '0' : totalRequestedQuantity,
    );
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
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
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
                        _buildTextCard('Short Description', _product.shortDescription),
                        const SizedBox(height: 12),
                        _buildTextCard('Full Description', _product.fullDescription),
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
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.FieldExecutiveProductPaymentScreen,
                  arguments: fieldexecutiveproductpaymentArguments(
                    roleId: widget.roleId,
                    roleName: widget.roleName,
                  ),
                );
              },
              child: const Text(
                'Use in repair',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
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

  Widget _buildHeaderCard(_ProductDetailData data) {
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

  Widget _buildInfoGrid(_ProductDetailData data) {
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
}

class _ProductDetailData {
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

  const _ProductDetailData({
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

  const _ProductDetailData.empty()
      : image = 'assets/products/motherboard.png',
        productName = '-',
        modelNo = '-',
        shortDescription = '-',
        finalPrice = '-',
        fullDescription = '-',
        technicalSpecification = '-',
        brandWarranty = '-',
        companyWarranty = '-',
        totalRequestedQuantity = '0';
}
