class DiagnosisItem {
  final String name;
  final String statusLabel;
  final String partStatus;
  final String partId;
  final String quantity;
  final String requestedPartId;
  final String requestedQuantity;
  final String requestedPartName;
  final String productIdFromApi;
  final String quantityFromApi;
  final String? report;

  const DiagnosisItem({
    required this.name,
    this.statusLabel = '',
    this.partStatus = '',
    this.partId = '',
    this.quantity = '',
    this.requestedPartId = '',
    this.requestedQuantity = '',
    this.requestedPartName = '',
    this.productIdFromApi = '',
    this.quantityFromApi = '',
    this.report,
  });

  factory DiagnosisItem.fromJson(Map<String, dynamic> json) {
    dynamic readRaw(List<String> keys) {
      for (final key in keys) {
        if (!json.containsKey(key)) continue;
        final value = json[key];
        if (value == null) continue;
        return value;
      }
      return null;
    }

    String readString(List<String> keys) {
      final value = readRaw(keys);
      if (value == null || value is Map || value is List) return '';
      final text = value.toString().trim();
      if (text.isEmpty || text.toLowerCase() == 'null') return '';
      return text;
    }

    final name = readString(const [
      'name',
      'diagnosis_name',
      'diagnosisName',
      'diagnosis',
      'title',
      'label',
    ]);

    final reportText = readString(const [
      'report',
      'remarks',
      'remark',
      'note',
      'notes',
      'problem_solution',
      'problemSolution',
      'description',
    ]);

    final rawStatus = readRaw(const [
      'status',
      'status_label',
      'statusLabel',
      'diagnosis_status',
      'diagnosisStatus',
      'is_working',
      'isWorking',
      'working',
    ]);

    final rawPartStatus = readRaw(const [
      'part_status',
      'partStatus',
    ]);
    final partId = readString(const [
      'part_id',
      'partId',
      'product_id',
      'productId',
    ]);
    final quantity = readString(const [
      'quantity',
      'qty',
      'requested_quantity',
      'requestedQuantity',
    ]);
    final requestedPartId = readString(const [
      'requested_part_id',
      'requestedPartId',
      'part_id',
      'partId',
      'product_id',
      'productId',
    ]);
    final requestedQuantity = readString(const [
      'requested_quantity',
      'requestedQuantity',
      'quantity',
      'qty',
    ]);
    final quantityFromApi = readString(const ['quantity']);
    final dynamic productDataRaw = readRaw(const [
      'product_data',
      'productData',
    ]);
    String productIdFromApi = '';
    String requestedPartName = '';
    if (productDataRaw is Map) {
      final productData = Map<String, dynamic>.from(productDataRaw as Map);
      for (final key in const ['id', 'product_id', 'productId']) {
        final dynamic value = productData[key];
        if (value == null || value is Map || value is List) {
          continue;
        }
        final String text = value.toString().trim();
        if (text.isNotEmpty && text.toLowerCase() != 'null') {
          productIdFromApi = text;
          break;
        }
      }
      for (final key in const ['product_name', 'name', 'title']) {
        final dynamic value = productData[key];
        if (value == null || value is Map || value is List) {
          continue;
        }
        final String text = value.toString().trim();
        if (text.isNotEmpty && text.toLowerCase() != 'null') {
          requestedPartName = text;
          break;
        }
      }
    }

    return DiagnosisItem(
      name: name,
      statusLabel: _normalizeStatusLabel(rawStatus),
      partStatus: _normalizePartStatus(rawPartStatus),
      partId: partId,
      quantity: quantity,
      requestedPartId: requestedPartId,
      requestedQuantity: requestedQuantity,
      requestedPartName: requestedPartName,
      productIdFromApi: productIdFromApi,
      quantityFromApi: quantityFromApi,
      report: reportText.isEmpty ? null : reportText,
    );
  }

  static String _normalizeStatusLabel(dynamic rawStatus) {
    if (rawStatus == null) return '';
    if (rawStatus is bool) {
      return rawStatus ? 'Working' : 'Not Working';
    }

    final rawText = rawStatus.toString().trim();
    if (rawText.isEmpty || rawText.toLowerCase() == 'null') return '';

    final normalized = rawText
        .toLowerCase()
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    switch (normalized) {
      case 'working':
        return 'Working';
      case 'not working':
        return 'Not Working';
      case 'add to pickup':
        return 'Add to Pickup';
      case 'use stock in hand':
        return 'Use Stock in Hand';
      case 'request a part':
        return 'Request a Part';
      default:
        return _toTitleCase(normalized);
    }
  }

  static String _toTitleCase(String text) {
    if (text.isEmpty) return '';
    final words = text.split(' ');
    return words
        .where((word) => word.isNotEmpty)
        .map(
          (word) =>
              '${word[0].toUpperCase()}${word.length > 1 ? word.substring(1) : ''}',
        )
        .join(' ');
  }

  static String _normalizePartStatus(dynamic rawPartStatus) {
    if (rawPartStatus == null) return '';
    final rawText = rawPartStatus.toString().trim();
    if (rawText.isEmpty || rawText.toLowerCase() == 'null') return '';

    final normalized = rawText
        .toLowerCase()
        .replaceAll('-', '_')
        .replaceAll(' ', '_')
        .replaceAll(RegExp(r'_+'), '_')
        .trim();

    switch (normalized) {
      case 'requested':
      case 'delivered':
      case 'waiting_for_approval':
      case 'customer_approved':
      case 'used':
        return normalized;
      default:
        return '';
    }
  }
}
