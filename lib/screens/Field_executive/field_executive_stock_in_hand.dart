import 'package:flutter/material.dart';

import '../../constants/api_constants.dart';
import '../../routes/app_routes.dart';
import '../../services/api_service.dart';

class StockInHandScreen extends StatefulWidget {
  final int roleId;
  final String roleName;

  const StockInHandScreen({
    super.key,
    required this.roleId,
    required this.roleName,
  });

  @override
  State<StockInHandScreen> createState() => _StockInHandScreenState();
}

class _StockInHandScreenState extends State<StockInHandScreen> {
  static const Color primaryGreen = Color(0xFF2E7D32);

  bool _isLoading = true;
  String? _error;
  List<_StockItemData> _items = const [];

  @override
  void initState() {
    super.initState();
    _loadStockInHand();
  }

  Future<void> _loadStockInHand() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiService.fetchStockInHand(roleId: widget.roleId);
      final items = response.map(_mapStockItem).toList();
      if (!mounted) return;
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _cleanError(e);
        _isLoading = false;
      });
    }
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '').trim();
  }

  String _readText(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value == null || value is Map || value is List) {
        continue;
      }
      final text = value.toString().trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') {
        return text;
      }
    }
    return '';
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

    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      for (final key in const [
        'url',
        'image',
        'image_url',
        'path',
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

  String _formatPrice(String rawPrice) {
    final price = rawPrice.trim();
    if (price.isEmpty) return '-';
    if (price.contains('\u20B9')) return price;
    return '\u20B9 $price';
  }

  _StockItemData _mapStockItem(Map<String, dynamic> item) {
    final products = item['products'] is Map
        ? Map<String, dynamic>.from(item['products'] as Map)
        : <String, dynamic>{};

    final image = _readImage(
      products['main_product_image'] ??
          products['product_image'] ??
          products['image_url'] ??
          products['image'] ??
          products['images'] ??
          item['image'] ??
          item['product_image'] ??
          item['image_url'] ??
          item['images'] ??
          item['product_images'],
    );
    final name = _readText(products, const ['product_name', 'name', 'title']);
    final price = _readText(
      products,
      const ['final_price', 'selling_price', 'price', 'amount'],
    );
    final quantity = _readText(
      item,
      const ['total_requested_quantity', 'requested_quantity', 'quantity', 'qty'],
    );

    return _StockItemData(
      imageUrl: image,
      productName: name.isEmpty ? '-' : name,
      finalPrice: _formatPrice(price),
      quantity: quantity.isEmpty ? '0' : quantity,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Stock in hand',
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
                            onPressed: _loadStockInHand,
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
                : _items.isEmpty
                    ? const Center(
                        child: Text(
                          'No stock in hand available',
                          style: TextStyle(color: Colors.black54),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          return InkWell(
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.FieldExecutiveProductDetailScreen,
                                arguments: fieldexecutiveproductdetailArguments(
                                  roleId: widget.roleId,
                                  roleName: widget.roleName,
                                ),
                              );
                            },
                            child: StockItemCard(item: item),
                          );
                        },
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
                  AppRoutes.FieldExecutiveAddProductScreen,
                  arguments: fieldexecutiveaddproductArguments(
                    roleId: widget.roleId,
                    roleName: widget.roleName,
                  ),
                );
              },
              child: const Text(
                'Request more product',
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
}

class _StockItemData {
  final String imageUrl;
  final String productName;
  final String finalPrice;
  final String quantity;

  const _StockItemData({
    required this.imageUrl,
    required this.productName,
    required this.finalPrice,
    required this.quantity,
  });
}

class StockItemCard extends StatelessWidget {
  final _StockItemData item;

  const StockItemCard({
    super.key,
    required this.item,
  });

  Widget _buildImage() {
    if (item.imageUrl.isEmpty) {
      return const Icon(Icons.image_not_supported, color: Colors.grey);
    }
    return Image.network(
      item.imageUrl,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) =>
          const Icon(Icons.image_not_supported, color: Colors.grey),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: _buildImage(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.finalPrice,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Qty',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.quantity,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
