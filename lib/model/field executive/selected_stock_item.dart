class UsedStockItem {
  final String productId;
  final String productName;
  final int quantity;

  const UsedStockItem({
    required this.productId,
    required this.productName,
    required this.quantity,
  });

  UsedStockItem copyWith({
    String? productId,
    String? productName,
    int? quantity,
  }) {
    return UsedStockItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
    };
  }

  // API-ready payload helper for future server submission.
  Map<String, dynamic> toApiJson({
    String productIdKey = 'product_id',
    String quantityKey = 'quantity',
  }) {
    return <String, dynamic>{
      productIdKey: productId,
      quantityKey: quantity,
    };
  }

  factory UsedStockItem.fromMap(Map<String, dynamic> map) {
    int parseQuantity(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString().trim()) ?? 0;
    }

    String readFromMap(Map<String, dynamic> source, List<String> keys) {
      for (final key in keys) {
        final value = source[key];
        if (value == null || value is Map || value is List) continue;
        final text = value.toString().trim();
        if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
      }
      return '';
    }

    final Map<String, dynamic> products =
        map['products'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(map['products'] as Map<String, dynamic>)
        : (map['products'] is Map
              ? Map<String, dynamic>.from(map['products'] as Map)
              : <String, dynamic>{});

    final String rootProductId = readFromMap(
      map,
      const ['product_id', 'productId', 'id', 'part_id'],
    );
    final String nestedProductId = readFromMap(
      products,
      const ['id', 'product_id', 'productId', 'part_id'],
    );
    final String resolvedProductId = rootProductId.isNotEmpty
        ? rootProductId
        : nestedProductId;
    final String rootProductName = readFromMap(
      map,
      const ['product_name', 'name', 'title'],
    );
    final String resolvedProductName = rootProductName.isNotEmpty
        ? rootProductName
        : readFromMap(products, const ['product_name', 'name', 'title']);

    return UsedStockItem(
      productId: resolvedProductId,
      productName: resolvedProductName,
      quantity: parseQuantity(
        map['quantity'] ??
            map['total_requested_quantity'] ??
            map['qty'] ??
            map['requested_quantity'],
      ),
    );
  }
}

typedef SelectedStockItem = UsedStockItem;
