import 'dart:convert';

import 'package:flutter/material.dart';
import '../../constants/api_constants.dart';
import '../../model/field executive/field_executive_product_service.dart';
import '../../routes/app_routes.dart';
import '../../services/api_service.dart';

class FieldExecutiveAllProductsScreen extends StatefulWidget {
  final int roleId;
  final String roleName;
  final FieldExecutiveProductItemDetailFlow flow;
  final FieldExecutiveProductServicesController controller;
  final String serviceRequestId;

  const FieldExecutiveAllProductsScreen({
    super.key,
    required this.roleId,
    required this.roleName,
    this.flow = FieldExecutiveProductItemDetailFlow.normalBrowsing,
    required this.controller,
    this.serviceRequestId = '',
  });

  static const primaryGreen = Color(0xFF1E7C10);

  @override
  State<FieldExecutiveAllProductsScreen> createState() =>
      _FieldExecutiveAllProductsScreenState();
}

class _FieldExecutiveAllProductsScreenState
    extends State<FieldExecutiveAllProductsScreen> {
  bool _isLoadingFromApi = false;
  bool _didLoadFromApi = false;
  String? _apiError;

  @override
  void initState() {
    super.initState();
    _loadProductsFromApi();
  }

  @override
  void didUpdateWidget(covariant FieldExecutiveAllProductsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.serviceRequestId != widget.serviceRequestId) {
      _didLoadFromApi = false;
      _loadProductsFromApi(force: true);
    }
  }

  String _normalizeRequestId(String raw) {
    return raw.trim().replaceFirst(RegExp(r'^#'), '');
  }

  String _cleanError(Object error) {
    final message = error.toString();
    return message.replaceFirst(RegExp(r'^Exception:\s*'), '').trim();
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  String _readFromProduct(Map<String, dynamic> product, List<String> keys) {
    for (final key in keys) {
      final value = product[key];
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
      if (map == null) continue;
      final requestId = _readFromProduct(
        map,
        const ['request_id', 'requestId', 'service_id', 'ticket_no'],
      );
      if (requestId.isNotEmpty) {
        return requestId;
      }
    }

    return '';
  }

  bool _isCompletedStatus(String rawStatus) {
    final value = rawStatus.trim().toLowerCase();
    return value == 'completed' ||
        value == 'complete' ||
        value == 'done' ||
        value == 'closed' ||
        value == 'resolved';
  }

  String _toLabelCase(String raw) {
    final value = raw.trim().replaceAll('_', ' ');
    if (value.isEmpty) {
      return '';
    }
    return value
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
        .join(' ');
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

  String _extractImageUrl(Map<String, dynamic> product) {
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

  List<Map<String, dynamic>> _extractProductMaps(Map<String, dynamic> detail) {
    final productMaps = <Map<String, dynamic>>[];
    const candidateKeys = <String>[
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
        productMaps.add(map);
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
        for (final key in candidateKeys) {
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
    for (final product in productMaps) {
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

  List<FieldExecutiveProductService> _mapToControllerItems(
    List<Map<String, dynamic>> productMaps,
    String requestId,
  ) {
    return productMaps.asMap().entries.map((entry) {
      final index = entry.key;
      final product = entry.value;

      final name = _readFromProduct(
        product,
        const ['name', 'product_name', 'title', 'service_name'],
      );
      final fallbackName = 'Product ${index + 1}';
      final productName = name.isEmpty ? fallbackName : name;

      final productId = _readFromProduct(
        product,
        const ['id', 'product_id', 'item_code_id', 'sku'],
      );
      final idValue = productId.isEmpty ? '${index + 1}' : productId;
      final serviceId = idValue.startsWith('#') ? idValue : '#$idValue';

      final productStatus = _readFromProduct(product, const ['status']);
      final priorityText = _toLabelCase(productStatus);

      final type = _readFromProduct(product, const ['type']);
      final modelNo = _readFromProduct(product, const ['model_no', 'model']);
      final brand = _readFromProduct(product, const ['brand']);
      final description = _readFromProduct(product, const ['description']);
      final imageUrl = _extractImageUrl(product);

      final subtitle = description.isNotEmpty
          ? description
          : <String>[
              if (type.isNotEmpty) type,
              if (modelNo.isNotEmpty) 'Model: $modelNo',
              if (brand.isNotEmpty) 'Brand: $brand',
            ].join(' | ');

      return FieldExecutiveProductService(
        title: productName,
        serviceId: serviceId,
        location: '-',
        priority: priorityText.isEmpty ? 'Processing' : priorityText,
        description: subtitle,
        imageUrl: imageUrl,
        requestId: requestId,
        status: _isCompletedStatus(productStatus)
            ? FieldExecutiveProductServiceStatus.completed
            : FieldExecutiveProductServiceStatus.incomplete,
      );
    }).toList();
  }

  Future<void> _loadProductsFromApi({bool force = false}) async {
    final normalizedServiceId = _normalizeRequestId(widget.serviceRequestId);
    if (normalizedServiceId.isEmpty || int.tryParse(normalizedServiceId) == null) {
      return;
    }
    if (_didLoadFromApi && !force) {
      return;
    }

    setState(() {
      _isLoadingFromApi = true;
      _apiError = null;
    });

    try {
      final detail = await ApiService.fetchServiceRequestDetail(
        normalizedServiceId,
        roleId: widget.roleId,
      );

      if (!mounted) {
        return;
      }

      final productMaps = _extractProductMaps(detail);
      final requestId = _extractRequestId(detail);
      final apiItems = _mapToControllerItems(productMaps, requestId);
      if (apiItems.isEmpty) {
        setState(() {
          _didLoadFromApi = true;
          _isLoadingFromApi = false;
          _apiError = 'No products found for this service request.';
        });
        return;
      }

      widget.controller.replaceItems(apiItems, preserveExistingStatus: true);
      setState(() {
        _didLoadFromApi = true;
        _isLoadingFromApi = false;
        _apiError = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _didLoadFromApi = true;
        _isLoadingFromApi = false;
        _apiError = _cleanError(error);
      });
    }
  }

  String _subtitleFor(FieldExecutiveProductService item) {
    if (item.description.trim().isNotEmpty) {
      return item.description;
    }
    if (item.title == 'Monitor Setup') {
      return 'Standard installation for LED/LCD monitors';
    }
    if (item.title == 'UPS Installation') {
      return 'Battery backup configuration and testing';
    }
    if (item.title == 'Keyboard and Mouse') {
      return 'Wired/Wireless setup and driver installation';
    }
    return 'Visit charge of Rs 159 waived in final bill; spare part/ repair cost extra';
  }

  Widget _buildImageFallback({IconData icon = Icons.image_not_supported}) {
    return Container(
      color: Colors.grey.shade100,
      alignment: Alignment.center,
      child: Icon(icon, color: Colors.grey.shade500, size: 26),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: FieldExecutiveAllProductsScreen.primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'All Products',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: widget.controller,
          builder: (context, _) {
            final items = widget.controller.items;

            if (_isLoadingFromApi && items.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(
                  color: FieldExecutiveAllProductsScreen.primaryGreen,
                ),
              );
            }

            if (items.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _apiError ?? 'No products available for this service request.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                      if (_didLoadFromApi && widget.serviceRequestId.trim().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => _loadProductsFromApi(force: true),
                          child: const Text('Retry'),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: [
                if (_isLoadingFromApi)
                  const LinearProgressIndicator(
                    color: FieldExecutiveAllProductsScreen.primaryGreen,
                  ),
                if (_apiError != null && _apiError!.isNotEmpty)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Text(
                      _apiError!,
                      style: TextStyle(
                        color: Colors.orange.shade900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Padding(
                        padding: EdgeInsets.only(bottom: index == items.length - 1 ? 0 : 12),
                        child: _buildProductCard(
                          context,
                          item,
                          _subtitleFor(item),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    FieldExecutiveProductService item,
    String subtitle,
  ) {
    final isCompleted = item.isCompleted;
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.FieldExecutiveProductItemDetailScreen,
          arguments: fieldexecutiveproductitemdetailArguments(
            roleId: widget.roleId,
            roleName: widget.roleName,
            title: item.title,
            serviceId: item.serviceId,
            serviceRequestId: _normalizeRequestId(widget.serviceRequestId),
            displayServiceId:
                item.requestId.trim().isEmpty ? item.serviceId : item.requestId,
            location: item.location,
            priority: item.priority,
            flow: widget.flow,
            controller: widget.controller,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: item.imageUrl.trim().isEmpty
                        ? _buildImageFallback()
                        : Image.network(
                            item.imageUrl,
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
                  const SizedBox(width: 12),
                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(fontSize: 10, color: Colors.black54),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const SizedBox(
                              width: 70,
                              child: Text('Service ID:', style: TextStyle(fontSize: 12, color: Colors.black54)),
                            ),
                            Text(
                              item.requestId.trim().isEmpty
                                  ? item.serviceId
                                  : item.requestId,
                              style: const TextStyle(
                                fontSize: 12,
                                color: FieldExecutiveAllProductsScreen.primaryGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const SizedBox(
                              width: 70,
                              child: Text('Location:', style: TextStyle(fontSize: 12, color: Colors.black54)),
                            ),
                            Text(item.location, style: const TextStyle(fontSize: 12, color: FieldExecutiveAllProductsScreen.primaryGreen, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isCompleted ? Colors.green.shade50 : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isCompleted ? Colors.green.shade200 : Colors.red.shade200,
                            ),
                          ),
                          child: Text(
                            isCompleted ? 'Completed' : 'Incomplete',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isCompleted ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Priority Tag
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12)),
                ),
                child: Text(
                  item.priority,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
