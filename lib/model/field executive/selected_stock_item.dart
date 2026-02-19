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

    String read(List<String> keys) {
      for (final key in keys) {
        final value = map[key];
        if (value == null || value is Map || value is List) continue;
        final text = value.toString().trim();
        if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
      }
      return '';
    }

    return UsedStockItem(
      productId: read(const ['product_id', 'productId', 'id', 'part_id']),
      productName: read(const ['product_name', 'name', 'title']),
      quantity: parseQuantity(
        map['quantity'] ?? map['qty'] ?? map['requested_quantity'],
      ),
    );
  }
}

typedef SelectedStockItem = UsedStockItem;
