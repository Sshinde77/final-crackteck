import 'package:flutter/foundation.dart';

import '../model/field executive/requested_product.dart';

class RequestedProductsStore extends ChangeNotifier {
  RequestedProductsStore._();

  static final RequestedProductsStore instance = RequestedProductsStore._();

  final List<RequestedProduct> _items = <RequestedProduct>[];

  List<RequestedProduct> getAllProducts() {
    return List<RequestedProduct>.unmodifiable(_items);
  }

  RequestedProduct? getById(String productId) {
    final normalizedId = _normalizeId(productId);
    if (normalizedId.isEmpty) return null;
    for (final item in _items) {
      if (_normalizeId(item.id) == normalizedId) {
        return item;
      }
    }
    return null;
  }

  void addOrUpdateProduct(
    RequestedProduct product, {
    bool mergeQuantity = false,
  }) {
    final normalizedId = _normalizeId(product.id);
    if (normalizedId.isEmpty) return;

    final index = _items.indexWhere(
      (item) => _normalizeId(item.id) == normalizedId,
    );

    if (index == -1) {
      _items.add(
        product.copyWith(
          id: normalizedId,
          quantity: product.quantity < 1 ? 1 : product.quantity,
        ),
      );
      notifyListeners();
      return;
    }

    final existing = _items[index];
    final nextQuantity = mergeQuantity
        ? existing.quantity + (product.quantity < 1 ? 1 : product.quantity)
        : (product.quantity < 1 ? 1 : product.quantity);

    _items[index] = product.copyWith(
      id: normalizedId,
      quantity: nextQuantity,
    );
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    final normalizedId = _normalizeId(productId);
    if (normalizedId.isEmpty) return;

    final index = _items.indexWhere(
      (item) => _normalizeId(item.id) == normalizedId,
    );
    if (index == -1) return;

    final safeQuantity = quantity < 1 ? 1 : quantity;
    _items[index] = _items[index].copyWith(quantity: safeQuantity);
    notifyListeners();
  }

  void removeProduct(String productId) {
    final normalizedId = _normalizeId(productId);
    if (normalizedId.isEmpty) return;
    _items.removeWhere((item) => _normalizeId(item.id) == normalizedId);
    notifyListeners();
  }

  void clear() {
    if (_items.isEmpty) return;
    _items.clear();
    notifyListeners();
  }

  String _normalizeId(String rawId) {
    return rawId.trim().replaceFirst(RegExp(r'^#'), '');
  }
}
