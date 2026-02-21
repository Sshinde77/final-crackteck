import 'package:flutter/material.dart';

import '../../constants/api_constants.dart';
import '../../model/field executive/selected_stock_item.dart';
import '../../routes/app_routes.dart';
import '../../services/api_service.dart';

class AddProductScreen extends StatefulWidget {
  final int roleId;
  final String roleName;
  final bool selectionMode;
  final String diagnosisName;
  final SelectedStockItem? initialSelectedPart;

  const AddProductScreen({
    super.key,
    required this.roleId,
    required this.roleName,
    this.selectionMode = false,
    this.diagnosisName = '',
    this.initialSelectedPart,
  });

  static const Color primaryGreen = Color(0xFF1F8B00);

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  bool _isLoading = true;
  String? _error;
  List<_Product> _products = const [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiService.fetchFieldExecutiveProducts(
        roleId: widget.roleId,
      );
      final mapped = response.map(_mapProduct).toList();
      if (!mounted) return;
      setState(() {
        _products = mapped;
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

  String _readImage(dynamic value) {
    if (value == null) return '';

    if (value is String) {
      return _normalizeImageSource(value);
    }

    if (value is List) {
      for (final item in value) {
        final image = _readImage(item);
        if (image.isNotEmpty) return image;
      }
      return '';
    }

    final map = _asMap(value);
    if (map != null) {
      for (final key in const [
        'main_product_image',
        'product_image',
        'image',
        'image_url',
        'path',
        'url',
        'src',
        'thumbnail',
        'thumb',
      ]) {
        final image = _readImage(map[key]);
        if (image.isNotEmpty) return image;
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

  _Product _mapProduct(Map<String, dynamic> item) {
    final nestedProduct = _asMap(item['product']) ?? _asMap(item['products']);
    final id = _readText(
      nestedProduct ?? item,
      const ['product_id', 'productId', 'id'],
    );
    final name = _readText(
      nestedProduct ?? item,
      const ['product_name', 'name', 'title'],
    );
    final price = _readText(
      nestedProduct ?? item,
      const ['final_price', 'selling_price', 'price', 'amount'],
    );
    final image = _readImage(
      nestedProduct?['main_product_image'] ??
          nestedProduct?['product_image'] ??
          nestedProduct?['image'] ??
          nestedProduct?['image_url'] ??
          item['main_product_image'] ??
          item['product_image'] ??
          item['image'] ??
          item['image_url'],
    );

    return _Product(
      id: id.replaceFirst(RegExp(r'^#'), ''),
      name: name.isEmpty ? '-' : name,
      price: _formatPrice(price),
      imageUrl: image,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AddProductScreen.primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add products',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.search, color: Colors.black54),
                      SizedBox(width: 8),
                      Text(
                        'Search',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
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
                                  onPressed: _loadProducts,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AddProductScreen.primaryGreen,
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
                      : _products.isEmpty
                          ? const Center(
                              child: Text(
                                'No products available',
                                style: TextStyle(color: Colors.black54),
                              ),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _products.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: 0.68,
                              ),
                              itemBuilder: (context, index) {
                                final product = _products[index];
                                return _ProductCard(
                                  product: product,
                                  roleId: widget.roleId,
                                  roleName: widget.roleName,
                                  selectionMode: widget.selectionMode,
                                  diagnosisName: widget.diagnosisName,
                                  initialSelectedPart: widget.initialSelectedPart,
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final _Product product;
  final int roleId;
  final String roleName;
  final bool selectionMode;
  final String diagnosisName;
  final SelectedStockItem? initialSelectedPart;

  const _ProductCard({
    required this.product,
    required this.roleId,
    required this.roleName,
    this.selectionMode = false,
    this.diagnosisName = '',
    this.initialSelectedPart,
  });

  SelectedStockItem? _parseSelectedPart(dynamic raw) {
    if (raw is SelectedStockItem) {
      return raw;
    }
    if (raw is Map<String, dynamic>) {
      return SelectedStockItem.fromMap(raw);
    }
    if (raw is Map) {
      return SelectedStockItem.fromMap(Map<String, dynamic>.from(raw));
    }
    return null;
  }

  Future<void> _openRequestedProductDetail(BuildContext context) async {
    final bool isSameAsInitial =
        initialSelectedPart != null &&
        initialSelectedPart!.productId.trim().replaceFirst(RegExp(r'^#'), '') ==
            product.id.trim().replaceFirst(RegExp(r'^#'), '');

    final dynamic result = await Navigator.pushNamed(
      context,
      AppRoutes.FieldExecutiveRequestedProductDetailScreen,
      arguments: fieldexecutiverequestedproductlistArguments(
        roleId: roleId,
        roleName: roleName,
        productId: product.id,
        selectionMode: selectionMode,
        diagnosisName: diagnosisName,
        initialSelectedPart: isSameAsInitial ? initialSelectedPart : null,
      ),
    );

    if (!context.mounted || !selectionMode) {
      return;
    }

    final selectedPart = _parseSelectedPart(result);
    if (selectedPart == null) {
      return;
    }

    Navigator.pop(context, selectedPart);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openRequestedProductDetail(context),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: product.imageUrl.isEmpty
                    ? const Icon(Icons.image_not_supported, color: Colors.grey)
                    : Image.network(
                        product.imageUrl,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                          );
                        },
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                product.price,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: SizedBox(
                width: double.infinity,
                height: 36,
                child: ElevatedButton(
                  onPressed: () => _openRequestedProductDetail(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AddProductScreen.primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Request Part',
                    style: TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _Product {
  final String id;
  final String name;
  final String price;
  final String imageUrl;

  const _Product({
    this.id = '',
    required this.name,
    required this.price,
    required this.imageUrl,
  });
}
