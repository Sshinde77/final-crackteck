import 'package:flutter/material.dart';

import '../../constants/api_constants.dart';
import '../../model/field executive/selected_stock_item.dart';
import '../../routes/app_routes.dart';
import '../../services/api_service.dart';

class StockInHandScreen extends StatefulWidget {
  final int roleId;
  final String roleName;
  final bool selectionMode;
  final String diagnosisName;
  final List<SelectedStockItem> initialSelectedItems;

  const StockInHandScreen({
    super.key,
    required this.roleId,
    required this.roleName,
    this.selectionMode = false,
    this.diagnosisName = '',
    this.initialSelectedItems = const <SelectedStockItem>[],
  });

  @override
  State<StockInHandScreen> createState() => _StockInHandScreenState();
}

class _StockInHandScreenState extends State<StockInHandScreen> {
  static const Color primaryGreen = Color(0xFF2E7D32);

  bool _isLoading = true;
  String? _error;
  List<_StockItemData> _items = const [];
  final Map<String, int> _selectedQuantities = <String, int>{};

  @override
  void initState() {
    super.initState();
    for (final item in widget.initialSelectedItems) {
      final key = _normalizeKey(item.productId);
      if (key.isNotEmpty && item.quantity > 0) {
        _selectedQuantities[key] = item.quantity;
      }
    }
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

  String _readId(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value == null || value is Map || value is List) {
        continue;
      }
      final text = value.toString().trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') {
        return text.replaceFirst(RegExp(r'^#'), '');
      }
    }
    return '';
  }

  String _normalizeKey(String raw) {
    return raw.trim().replaceFirst(RegExp(r'^#'), '');
  }

  String _itemKey(_StockItemData item, int index) {
    final normalized = _normalizeKey(item.productId);
    if (normalized.isNotEmpty) return normalized;
    return 'idx_$index';
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
    final productId = _readId(
      products,
      const ['product_id', 'productId', 'id'],
    );
    final stockInHandId = _readId(
      item,
      const ['stock_in_hand_id', 'stockInHandId', 'id'],
    );

    return _StockItemData(
      imageUrl: image,
      productName: name.isEmpty ? '-' : name,
      finalPrice: _formatPrice(price),
      quantity: quantity.isEmpty ? '0' : quantity,
      productId: productId.isNotEmpty ? productId : stockInHandId,
    );
  }

  void _increaseSelectedQty(_StockItemData item, int index) {
    final key = _itemKey(item, index);
    final current = _selectedQuantities[key] ?? 0;
    _addOrUpdateSelectedQty(key, current + 1);
  }

  void _decreaseSelectedQty(_StockItemData item, int index) {
    final key = _itemKey(item, index);
    final current = _selectedQuantities[key] ?? 0;
    if (current <= 0) return;
    final next = current - 1;
    if (next <= 0) {
      _removeSelectedItem(key);
      return;
    }
    _addOrUpdateSelectedQty(key, next);
  }

  void _addOrUpdateSelectedQty(String key, int quantity) {
    final safeQty = quantity < 1 ? 1 : quantity;
    setState(() {
      _selectedQuantities[key] = safeQty;
    });
  }

  void _removeSelectedItem(String key) {
    setState(() {
      _selectedQuantities.remove(key);
    });
  }

  void _clearSelectedQty(_StockItemData item, int index) {
    _removeSelectedItem(_itemKey(item, index));
  }

  List<SelectedStockItem> _buildSelectedStockResult() {
    final result = <SelectedStockItem>[];
    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];
      final key = _itemKey(item, i);
      final qty = _selectedQuantities[key] ?? 0;
      if (qty <= 0) continue;
      // Selection payload must always carry a concrete product id for part_id.
      final String normalizedProductId = _normalizeKey(item.productId);
      if (normalizedProductId.isEmpty) {
        debugPrint(
          '[StockInHand->Checklist] Dropping item with missing productId '
          '(name="${item.productName}", key="$key", quantity=$qty)',
        );
        continue;
      }
      final int safeQty = qty < 1 ? 1 : qty;
      result.add(
        SelectedStockItem(
          productId: normalizedProductId,
          productName: item.productName,
          quantity: safeQty,
        ),
      );
    }
    return result;
  }

  bool _validateAndReturnSelection() {
    final selected = _buildSelectedStockResult();
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least 1 stock item.'),
        ),
      );
      return false;
    }

    for (int i = 0; i < selected.length; i++) {
      final item = selected[i];
      debugPrint(
        '[StockInHand->Checklist][POP][$i] '
        'productId=${item.productId}, '
        'productName=${item.productName}, '
        'quantity=${item.quantity}',
      );
    }
    Navigator.pop(context, selected);
    return true;
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
        title: Text(
          widget.selectionMode && widget.diagnosisName.trim().isNotEmpty
              ? 'Stock in hand - ${widget.diagnosisName}'
              : 'Stock in hand',
          style: const TextStyle(
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
                          final selectedQty =
                              _selectedQuantities[_itemKey(item, index)] ?? 0;
                          return InkWell(
                            onTap: widget.selectionMode
                                ? null
                                : () {
                                    Navigator.pushNamed(
                                      context,
                                      AppRoutes.FieldExecutiveProductDetailScreen,
                                      arguments: fieldexecutiveproductdetailArguments(
                                        roleId: widget.roleId,
                                        roleName: widget.roleName,
                                        productId: item.productId,
                                      ),
                                    );
                                  },
                            child: StockItemCard(
                              item: item,
                              selectionMode: widget.selectionMode,
                              selectedQty: selectedQty,
                              onIncrease: widget.selectionMode
                                  ? () => _increaseSelectedQty(item, index)
                                  : null,
                              onDecrease: widget.selectionMode
                                  ? () => _decreaseSelectedQty(item, index)
                                  : null,
                              onClear: widget.selectionMode
                                  ? () => _clearSelectedQty(item, index)
                                  : null,
                            ),
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
              onPressed: widget.selectionMode
                  ? () {
                      _validateAndReturnSelection();
                    }
                  : () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.FieldExecutiveAddProductScreen,
                        arguments: fieldexecutiveaddproductArguments(
                          roleId: widget.roleId,
                          roleName: widget.roleName,
                        ),
                      );
                    },
              child: Text(
                widget.selectionMode ? 'Use Selected Stock' : 'Request more product',
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
  final String productId;

  const _StockItemData({
    required this.imageUrl,
    required this.productName,
    required this.finalPrice,
    required this.quantity,
    this.productId = '',
  });
}

class StockItemCard extends StatelessWidget {
  final _StockItemData item;
  final bool selectionMode;
  final int selectedQty;
  final VoidCallback? onIncrease;
  final VoidCallback? onDecrease;
  final VoidCallback? onClear;

  const StockItemCard({
    super.key,
    required this.item,
    this.selectionMode = false,
    this.selectedQty = 0,
    this.onIncrease,
    this.onDecrease,
    this.onClear,
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
    Widget qtyView;
    if (selectionMode) {
      qtyView = Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text(
            'Selected',
            style: TextStyle(fontSize: 12, color: Colors.red),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _qtyButton(icon: Icons.remove, onTap: onDecrease),
              SizedBox(
                width: 28,
                child: Text(
                  selectedQty.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
              _qtyButton(icon: Icons.add, onTap: onIncrease),
            ],
          ),
          if (selectedQty > 0) ...[
            const SizedBox(height: 4),
            InkWell(
              onTap: onClear,
              child: const Text(
                'Remove',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      );
    } else {
      qtyView = Column(
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
      );
    }

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
          qtyView,
        ],
      ),
    );
  }

  Widget _qtyButton({required IconData icon, required VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: const Color(0xFF2E7D32),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 14, color: Colors.white),
      ),
    );
  }
}
