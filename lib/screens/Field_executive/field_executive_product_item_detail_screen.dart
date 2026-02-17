import 'dart:convert';

import 'package:flutter/material.dart';

import '../../constants/api_constants.dart';
import '../../model/field executive/field_executive_product_service.dart';
import '../../routes/app_routes.dart';
import '../../services/api_service.dart';
import 'field_executive_installation_checklist_screen.dart';

class FieldExecutiveProductItemDetailScreen extends StatefulWidget {
  final int roleId;
  final String roleName;
  final String title;
  final String serviceId;
  final String serviceRequestId;
  final String displayServiceId;
  final String location;
  final String priority;
  final FieldExecutiveProductItemDetailFlow flow;
  final FieldExecutiveProductServicesController controller;

  const FieldExecutiveProductItemDetailScreen({
    super.key,
    required this.roleId,
    required this.roleName,
    required this.title,
    required this.serviceId,
    this.serviceRequestId = '',
    this.displayServiceId = '',
    required this.location,
    required this.priority,
    required this.flow,
    required this.controller,
  });

  static const primaryGreen = Color(0xFF1E7C10);

  @override
  State<FieldExecutiveProductItemDetailScreen> createState() =>
      _FieldExecutiveProductItemDetailScreenState();
}

class _FieldExecutiveProductItemDetailScreenState
    extends State<FieldExecutiveProductItemDetailScreen> {
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _productMap;
  String _requestId = '';

  @override
  void initState() {
    super.initState();
    _loadProductDetail();
  }

  String _normalizeId(String raw) {
    return raw.trim().replaceFirst(RegExp(r'^#'), '');
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  String _readFromMap(Map<String, dynamic>? source, List<String> keys) {
    if (source == null) return '';
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

  String _extractRequestId(Map<String, dynamic> detail) {
    final candidates = <Map<String, dynamic>?>[
      detail,
      _asMap(detail['data']),
      _asMap(detail['service_request']),
      _asMap(detail['request']),
      _asMap(detail['service']),
    ];

    for (final map in candidates) {
      final value = _readFromMap(
        map,
        const ['request_id', 'requestId', 'service_id', 'ticket_no'],
      );
      if (value.isNotEmpty) {
        return value;
      }
    }
    return '';
  }

  List<Map<String, dynamic>> _extractProductMaps(Map<String, dynamic> detail) {
    final products = <Map<String, dynamic>>[];
    const keys = <String>[
      'products',
      'product',
      'product_detail',
      'product_details',
      'service_products',
      'service_product',
      'items',
      'item',
    ];

    void collect(dynamic node) {
      if (node == null) return;
      final map = _asMap(node);
      if (map != null) {
        products.add(map);
        return;
      }
      if (node is List) {
        for (final item in node) {
          collect(item);
        }
      }
    }

    void scan(dynamic node, {int depth = 0}) {
      if (depth > 3 || node == null) return;

      final map = _asMap(node);
      if (map != null) {
        for (final key in keys) {
          collect(map[key]);
        }
        scan(map['data'], depth: depth + 1);
        scan(map['service_request'], depth: depth + 1);
        scan(map['request'], depth: depth + 1);
        scan(map['service'], depth: depth + 1);
        return;
      }

      if (node is List) {
        for (final item in node) {
          scan(item, depth: depth + 1);
        }
      }
    }

    scan(detail);

    final seen = <String>{};
    final deduped = <Map<String, dynamic>>[];
    for (final product in products) {
      final identity = [
        product['id'],
        product['service_requests_id'],
        product['item_code_id'],
        product['name'],
        product['model_no'],
        product['sku'],
      ].map((value) => value?.toString() ?? '').join('|');
      if (seen.add(identity)) {
        deduped.add(product);
      }
    }
    return deduped;
  }

  bool _matchesSelectedProduct(Map<String, dynamic> product) {
    final selected = _normalizeId(widget.serviceId);
    if (selected.isEmpty) return false;

    for (final key in const ['id', 'product_id', 'item_code_id', 'sku']) {
      final value = product[key];
      final normalized = _normalizeId(value?.toString() ?? '');
      if (normalized.isNotEmpty && normalized == selected) {
        return true;
      }
    }
    return false;
  }

  bool _looksLikeHtml(String raw) {
    final value = raw.trimLeft().toLowerCase();
    return value.startsWith('<!doctype html') || value.startsWith('<html');
  }

  String _normalizeImageSource(String raw) {
    final value = raw.trim();
    if (value.isEmpty || value.toLowerCase() == 'null') {
      return '';
    }
    if (_looksLikeHtml(value)) {
      return '';
    }
    if (value.startsWith('data:image/')) {
      return value;
    }
    if (value.contains('<') && value.contains('>')) {
      return '';
    }

    final parsed = Uri.tryParse(value);
    if (parsed != null && parsed.hasScheme) {
      final scheme = parsed.scheme.toLowerCase();
      if (scheme == 'http' || scheme == 'https') {
        return parsed.toString();
      }
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

  String _readImageFromDynamic(dynamic value) {
    if (value == null) return '';

    if (value is String) {
      final text = value.trim();
      if (text.isEmpty || text.toLowerCase() == 'null') {
        return '';
      }

      if (text.startsWith('[') || text.startsWith('{')) {
        try {
          final decoded = jsonDecode(text);
          final nested = _readImageFromDynamic(decoded);
          if (nested.isNotEmpty) {
            return nested;
          }
        } catch (_) {}
      }

      if (text.contains(',')) {
        for (final part in text.split(',')) {
          final normalized = _normalizeImageSource(part);
          if (normalized.isNotEmpty) {
            return normalized;
          }
        }
      }

      return _normalizeImageSource(text);
    }

    if (value is List) {
      for (final item in value) {
        final nested = _readImageFromDynamic(item);
        if (nested.isNotEmpty) {
          return nested;
        }
      }
      return '';
    }

    if (value is Map) {
      for (final key in const [
        'url',
        'path',
        'image',
        'images',
        'src',
        'thumbnail',
        'thumb',
      ]) {
        final nested = _readImageFromDynamic(value[key]);
        if (nested.isNotEmpty) {
          return nested;
        }
      }
    }

    return '';
  }

  String _extractImageUrl(Map<String, dynamic>? product) {
    if (product == null) return '';
    for (final key in const [
      'images',
      'image',
      'image_url',
      'product_image',
      'thumbnail',
      'thumb',
      'photo',
    ]) {
      final url = _readImageFromDynamic(product[key]);
      if (url.isNotEmpty) {
        return url;
      }
    }
    return '';
  }

  String _formatDate(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return '-';
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    final day = parsed.day.toString().padLeft(2, '0');
    final month = parsed.month.toString().padLeft(2, '0');
    return '$day-$month-${parsed.year}';
  }

  Future<void> _loadProductDetail() async {
    final requestDbId = _normalizeId(widget.serviceRequestId);
    if (requestDbId.isEmpty || int.tryParse(requestDbId) == null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final detail = await ApiService.fetchServiceRequestDetail(
        requestDbId,
        roleId: widget.roleId,
      );

      if (!mounted) return;

      final products = _extractProductMaps(detail);
      Map<String, dynamic>? selected;
      for (final product in products) {
        if (_matchesSelectedProduct(product)) {
          selected = product;
          break;
        }
      }
      selected ??= products.isNotEmpty ? products.first : null;

      setState(() {
        _productMap = selected;
        _requestId = _extractRequestId(detail);
        _isLoading = false;
        _error = selected == null ? 'Product details not found in API response.' : null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      });
    }
  }

  String get _productName {
    final name = _readFromMap(
      _productMap,
      const ['name', 'product_name', 'title', 'service_name'],
    );
    return name.isEmpty ? widget.title : name;
  }

  String get _serviceIdForDisplay {
    if (_requestId.trim().isNotEmpty) return _requestId.trim();
    if (widget.displayServiceId.trim().isNotEmpty) return widget.displayServiceId.trim();
    return widget.serviceId;
  }

  String _firstResolvedId(List<String> candidates) {
    for (final candidate in candidates) {
      final normalized = _normalizeId(candidate);
      if (normalized.isNotEmpty && int.tryParse(normalized) != null) {
        return normalized;
      }
    }
    for (final candidate in candidates) {
      final normalized = _normalizeId(candidate);
      if (normalized.isNotEmpty) {
        return normalized;
      }
    }
    return '';
  }

  String get _serviceRequestIdForDiagnosisApi {
    return _firstResolvedId([
      _readFromMap(
        _productMap,
        const [
          'service_requests_id',
          'service_request_id',
          'serviceRequestId',
          'request_service_id',
        ],
      ),
      widget.serviceRequestId,
    ]);
  }

  String get _productIdForDiagnosisApi {
    return _firstResolvedId([
      _readFromMap(
        _productMap,
        const ['id', 'product_id', 'productId', 'item_code_id', 'itemCodeId'],
      ),
      widget.serviceId,
    ]);
  }

  String get _type {
    final value = _readFromMap(_productMap, const ['type']);
    return value.isEmpty ? '-' : value;
  }

  String get _modelNo {
    final value = _readFromMap(_productMap, const ['model_no', 'model']);
    return value.isEmpty ? '-' : value;
  }

  String get _purchaseDate {
    final value = _readFromMap(_productMap, const ['purchase_date']);
    return _formatDate(value);
  }

  String get _brand {
    final value = _readFromMap(_productMap, const ['brand']);
    return value.isEmpty ? '-' : value;
  }

  String get _description {
    final value = _readFromMap(_productMap, const ['description']);
    if (value.isNotEmpty) return value;
    return 'No description available.';
  }

  Widget _buildImageFallback({IconData icon = Icons.image_not_supported}) {
    return Container(
      color: Colors.grey.shade100,
      alignment: Alignment.center,
      child: Icon(icon, color: Colors.grey.shade500, size: 46),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _extractImageUrl(_productMap);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: FieldExecutiveProductItemDetailScreen.primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Product Detail',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading && _productMap == null
            ? const Center(
                child: CircularProgressIndicator(
                  color: FieldExecutiveProductItemDetailScreen.primaryGreen,
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 250,
                      width: double.infinity,
                      color: Colors.grey.shade100,
                      child: imageUrl.isEmpty
                          ? _buildImageFallback()
                          : Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildImageFallback(),
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) {
                                  return child;
                                }
                                return _buildImageFallback(icon: Icons.image);
                              },
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_error != null && _error!.trim().isNotEmpty)
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange.shade200),
                              ),
                              child: Text(
                                _error!,
                                style: TextStyle(
                                  color: Colors.orange.shade900,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  _productName,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.red.shade200),
                                ),
                                child: Text(
                                  widget.priority,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Service ID: $_serviceIdForDisplay',
                            style: const TextStyle(
                              color: FieldExecutiveProductItemDetailScreen.primaryGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 16),
                          _buildDetailItem('Type', _type),
                          _buildDetailItem('Model No', _modelNo),
                          _buildDetailItem('Purchase Date', _purchaseDate),
                          _buildDetailItem('Brand', _brand),
                          const SizedBox(height: 24),
                          const Text(
                            'Issue Description',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Text(
                              _description,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                                height: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
      bottomNavigationBar:
          widget.flow == FieldExecutiveProductItemDetailFlow.afterOtpVerification
              ? SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  FieldExecutiveInstallationChecklistScreen(
                               roleId: widget.roleId,
                                roleName: widget.roleName,
                                serviceId: widget.serviceId,
                                serviceRequestId: widget.serviceRequestId,
                                serviceRequestDbId: _serviceRequestIdForDiagnosisApi,
                                productDbId: _productIdForDiagnosisApi,
                                selectedProduct: _productMap,
                                flow: widget.flow,
                                controller: widget.controller,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              FieldExecutiveProductItemDetailScreen.primaryGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Start Service',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              : null,
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),
          ),
          const Text(':  ', style: TextStyle(color: Colors.black54)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
