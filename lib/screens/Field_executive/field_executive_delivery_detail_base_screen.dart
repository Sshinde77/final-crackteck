import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import 'field_executive_delivery_flow_helpers.dart';

class FieldExecutiveDeliveryDetailBaseScreen extends StatefulWidget {
  final int roleId;
  final String roleName;
  final int? userId;
  final String deliveryType;
  final String requestId;
  final String appBarTitle;
  final Future<Map<String, dynamic>> Function(
    String requestId,
    int roleId,
    int? userId,
  ) loadDetail;

  const FieldExecutiveDeliveryDetailBaseScreen({
    super.key,
    required this.roleId,
    required this.roleName,
    this.userId,
    required this.deliveryType,
    required this.requestId,
    required this.appBarTitle,
    required this.loadDetail,
  });

  @override
  State<FieldExecutiveDeliveryDetailBaseScreen> createState() =>
      _FieldExecutiveDeliveryDetailBaseScreenState();
}

class _FieldExecutiveDeliveryDetailBaseScreenState
    extends State<FieldExecutiveDeliveryDetailBaseScreen> {
  static const Color primaryGreen = Color(0xFF1E7C10);

  bool _isLoading = true;
  String? _error;
  _DeliveryDetailData? _detail;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  String get _normalizedRequestId =>
      widget.requestId.trim().replaceFirst(RegExp(r'^#'), '');

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _detail = null;
    });

    if (_normalizedRequestId.isEmpty) {
      setState(() {
        _isLoading = false;
        _error = 'Request ID is missing.';
      });
      return;
    }

    try {
      final response = await widget.loadDetail(
        _normalizedRequestId,
        widget.roleId,
        widget.userId,
      );
      if (!mounted) return;

      final parsed = _parseApiResponse(response);
      setState(() {
        _isLoading = false;
        _detail = parsed.data;
        _error = parsed.error;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _detail = null;
        _error = _cleanError(e.toString());
      });
    }
  }

  String _cleanError(String value) {
    final text = value
        .replaceFirst('Exception: ', '')
        .replaceFirst('Unhandled Exception: ', '')
        .trim();
    return text.isEmpty ? 'Failed to load request details.' : text;
  }

  _ParsedDetailResponse _parseApiResponse(Map<String, dynamic> response) {
    final success = response['success'];
    if (success is bool && !success) {
      final message = _readText(response['message']) ??
          _readText(response['error']) ??
          'Failed to load request details.';
      return _ParsedDetailResponse(error: message);
    }

    final data = _asMap(response['data']) ?? response;
    if (data.isEmpty) {
      return const _ParsedDetailResponse(error: 'Invalid response format.');
    }

    final serviceRequest = _asMap(data['service_request']);
    final customer = _asMap(serviceRequest?['customer']);
    final product = _asMap(data['product']);
    final requestProduct = _asMap(data['service_request_product']);
    final customerAddress = _asMap(serviceRequest?['customer_address']) ??
        _asMap(data['customer_address']);

    final firstName = _readFromMap(customer, const ['first_name']);
    final lastName = _readFromMap(customer, const ['last_name']);

    return _ParsedDetailResponse(
      data: _DeliveryDetailData(
        headerProductName: _readFromMap(product, const ['product_name']),
        requestId: _readFromMap(data, const ['request_id']) ?? _normalizedRequestId,
        requestType: _readFromMap(data, const ['request_type']) ??
            FieldExecutiveDeliveryTypes.label(widget.deliveryType),
        status: _readFromMap(data, const ['status']),
        customerName: _joinName(firstName, lastName),
        customerPhone: _readFromMap(customer, const ['phone']),
        productName: _readFromMap(requestProduct, const ['name']),
        productId: _readFromMap(data, const ['product_id']),
        requestedQuantity: _readFromMap(data, const ['requested_quantity']),
        priority: _readFromMap(data, const ['priority']),
        customerAddressId:
            _readFromMap(serviceRequest, const ['customer_address_id']),
        customerAddressText: _formatAddress(customerAddress),
      ),
    );
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  String? _readFromMap(Map<String, dynamic>? source, List<String> keys) {
    if (source == null || source.isEmpty) return null;
    for (final key in keys) {
      final text = _readText(source[key]);
      if (text != null) return text;
    }
    return null;
  }

  String? _readText(dynamic value) {
    if (value == null || value is Map || value is List) return null;
    final text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') return null;
    return text;
  }

  String? _joinName(String? first, String? last) {
    final parts = <String>[
      if (first != null && first.isNotEmpty) first,
      if (last != null && last.isNotEmpty) last,
    ];
    if (parts.isEmpty) return null;
    return parts.join(' ');
  }

  String? _formatAddress(Map<String, dynamic> address) {
    if (address.isEmpty) return null;
    final line1 = _readFromMap(address, const ['address_1', 'address1', 'address_line_1']);
    final line2 = _readFromMap(address, const ['address_2', 'address2', 'address_line_2']);
    final city = _readFromMap(address, const ['city']);
    final state = _readFromMap(address, const ['state']);
    final pincode = _readFromMap(address, const ['pincode']);
    final formatted = <String>[
      if (line1 != null) line1,
      if (line2 != null) line2,
      if (city != null || state != null || pincode != null)
        [city, state, pincode]
            .where((item) => item != null && item.isNotEmpty)
            .join(', '),
    ].where((item) => item.isNotEmpty).join(', ');
    return formatted.isEmpty ? null : formatted;
  }

  void _onStartDeliveryTap() {
    final detail = _detail;
    if (detail == null) return;

    final requestId = detail.requestId.replaceFirst(RegExp(r'^#'), '');
    if (requestId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request ID missing in delivery detail')),
      );
      return;
    }

    Navigator.pushNamed(
      context,
      AppRoutes.FieldExecutiveMapTrackingScreen,
      arguments: fieldexecutivemaptrackingArguments(
        roleId: widget.roleId,
        roleName: widget.roleName,
        serviceId: requestId,
        displayServiceId: '#$requestId',
        customerName: detail.customerName ?? '',
        customerAddress: detail.customerAddressText ?? '',
        customerPhone: detail.customerPhone ?? '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;
    final showLocationSection =
        detail != null && detail.customerAddressId != null;

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
          widget.appBarTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_error != null)
                      _ErrorBanner(
                        message: _error!,
                        onRetry: _loadDetail,
                      ),
                    if (_error == null && detail != null) ...[
                      _SectionCard(
                        title: 'Header',
                        children: [
                          if (detail.headerProductName != null)
                            _DetailRow(
                              label: 'Product Name',
                              value: detail.headerProductName!,
                            ),
                          _DetailRow(label: 'Request ID', value: detail.requestId),
                          _DetailRow(
                            label: 'Request Type',
                            value: detail.requestType,
                          ),
                          if (detail.status != null)
                            _DetailRow(label: 'Status', value: detail.status!),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _SectionCard(
                        title: 'Customer Info',
                        children: [
                          if (detail.customerName != null)
                            _DetailRow(label: 'Name', value: detail.customerName!),
                          if (detail.customerPhone != null)
                            _DetailRow(label: 'Phone', value: detail.customerPhone!),
                          if (detail.status != null)
                            _DetailRow(label: 'Status', value: detail.status!),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _SectionCard(
                        title: 'Product Info',
                        children: [
                          if (detail.productName != null)
                            _DetailRow(label: 'Product Name', value: detail.productName!),
                          if (detail.productId != null)
                            _DetailRow(label: 'Product ID', value: detail.productId!),
                          if (detail.requestedQuantity != null)
                            _DetailRow(
                              label: 'Requested Quantity',
                              value: detail.requestedQuantity!,
                            ),
                          if (detail.priority != null)
                            _DetailRow(label: 'Priority', value: detail.priority!),
                        ],
                      ),
                      if (showLocationSection) ...[
                        const SizedBox(height: 12),
                        _SectionCard(
                          title: 'Location',
                          children: [
                            _DetailRow(
                              label: 'Address ID',
                              value: detail.customerAddressId!,
                            ),
                            if (detail.customerAddressText != null)
                              _DetailRow(
                                label: 'Address',
                                value: detail.customerAddressText!,
                              ),
                          ],
                        ),
                      ],
                    ],
                  ],
                ),
              ),
      ),
      bottomNavigationBar: (_error == null && detail != null)
          ? SafeArea(
              top: false,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _onStartDeliveryTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Start Delivery',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

class _DeliveryDetailData {
  final String? headerProductName;
  final String requestId;
  final String requestType;
  final String? status;
  final String? customerName;
  final String? customerPhone;
  final String? productName;
  final String? productId;
  final String? requestedQuantity;
  final String? priority;
  final String? customerAddressId;
  final String? customerAddressText;

  const _DeliveryDetailData({
    this.headerProductName,
    required this.requestId,
    required this.requestType,
    this.status,
    this.customerName,
    this.customerPhone,
    this.productName,
    this.productId,
    this.requestedQuantity,
    this.priority,
    this.customerAddressId,
    this.customerAddressText,
  });
}

class _ParsedDetailResponse {
  final _DeliveryDetailData? data;
  final String? error;

  const _ParsedDetailResponse({
    this.data,
    this.error,
  });
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBanner({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            size: 18,
            color: Colors.red.shade700,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
