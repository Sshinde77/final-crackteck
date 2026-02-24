import 'package:flutter/material.dart';

import '../../constants/api_constants.dart';
import '../../routes/app_routes.dart';
import '../../services/api_service.dart';

class DeliveryProductDetailScreen extends StatefulWidget {
  final int roleId;
  final String roleName;
  final String deliveryType;
  final String deliveryId;
  final String requestType;
  final String requestId;
  final String productName;
  final String location;
  final String status;
  final String customerName;
  final String customerPhone;
  final String customerAddress;

  const DeliveryProductDetailScreen({
    super.key,
    required this.roleId,
    required this.roleName,
    required this.deliveryType,
    required this.deliveryId,
    required this.requestType,
    required this.requestId,
    required this.productName,
    required this.location,
    required this.status,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
  });

  static const Color _primaryGreen = Color(0xFF1E7C10);

  @override
  State<DeliveryProductDetailScreen> createState() =>
      _DeliveryProductDetailScreenState();
}

class _DeliveryProductDetailScreenState extends State<DeliveryProductDetailScreen> {
  bool _isLoading = true;
  bool _isAccepting = false;
  String? _errorMessage;
  Map<String, dynamic>? _detail;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final rawDetail = await ApiService.fetchDeliveryRequestDetail(
        deliveryType: widget.deliveryType,
        deliveryId: widget.deliveryId,
        roleId: widget.roleId,
      );
      final normalizedDetail = _normalizeDetail(rawDetail);

      if (!mounted) return;
      setState(() {
        _detail = normalizedDetail;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _cleanErrorMessage(error);
        _isLoading = false;
      });
    }
  }

  String _cleanErrorMessage(Object error) {
    final message = error.toString().trim();
    const prefix = 'Exception:';
    if (message.startsWith(prefix)) {
      return message.substring(prefix.length).trim();
    }
    return message;
  }

  Map<String, dynamic> _normalizeDetail(Map<String, dynamic> rawDetail) {
    final payload = _resolveRequestPayload(rawDetail);
    final product = _resolveProduct(payload);
    final serviceRequest = _mapFrom(payload['service_request']);
    final customer = _mapFrom(serviceRequest['customer']);
    final customerAddress = _mapFrom(serviceRequest['customer_address']);

    return <String, dynamic>{
      'product': product,
      'service_request': serviceRequest,
      'customer': customer,
      'customer_address': customerAddress,
      'request_type': _firstNonEmpty(
        <dynamic>[payload['request_type'], serviceRequest['request_type']],
        fallback: '',
      ),
      'request_id': _firstNonEmpty(
        <dynamic>[payload['request_id'], serviceRequest['request_id'], payload['id']],
        fallback: '',
      ),
      'id': _firstNonEmpty(
        <dynamic>[payload['id']],
        fallback: '',
      ),
    };
  }

  Map<String, dynamic> _resolveRequestPayload(Map<String, dynamic> rawDetail) {
    switch (_normalizedDeliveryType) {
      case DeliveryRequestTypes.part:
        final data = _mapFrom(rawDetail['data']);
        return data.isNotEmpty ? data : rawDetail;
      case DeliveryRequestTypes.pickup:
        final pickupRequest = _mapFrom(rawDetail['pickup_request']);
        return pickupRequest.isNotEmpty ? pickupRequest : rawDetail;
      case DeliveryRequestTypes.returnRequest:
        final returnRequest = _mapFrom(rawDetail['return_request']);
        return returnRequest.isNotEmpty ? returnRequest : rawDetail;
      default:
        return rawDetail;
    }
  }

  Map<String, dynamic> _resolveProduct(Map<String, dynamic> payload) {
    if (_normalizedDeliveryType == DeliveryRequestTypes.part) {
      return _mapFrom(payload['product']);
    }
    return _mapFrom(payload['service_request_product']);
  }

  bool get _hasDetail =>
      _product.isNotEmpty ||
      _serviceRequest.isNotEmpty ||
      _customer.isNotEmpty ||
      _customerAddress.isNotEmpty;

  Map<String, dynamic> get _detailSafe => _detail ?? const <String, dynamic>{};

  Map<String, dynamic> _mapFrom(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value as Map);
    return const <String, dynamic>{};
  }

  String _asText(dynamic value) {
    if (value == null) return '';
    if (value is String) return value.trim();
    if (value is num || value is bool) return value.toString();
    return '';
  }

  String _firstNonEmpty(List<dynamic> values, {String fallback = 'N/A'}) {
    for (final value in values) {
      final parsed = _asText(value);
      if (parsed.isNotEmpty) return parsed;
    }
    return fallback;
  }

  String _joinNonEmpty(
    List<dynamic> values, {
    String separator = ' ',
    String fallback = 'N/A',
  }) {
    final cleaned = values
        .map(_asText)
        .where((value) => value.isNotEmpty)
        .toList();
    if (cleaned.isEmpty) return fallback;
    return cleaned.join(separator);
  }

  String _requestTypeLabelFromApi(String rawType) {
    switch (rawType.trim().toLowerCase()) {
      case 'request_part':
        return 'Part Request';
      case 'pickup_request':
        return 'Pickup Request';
      case 'return_request':
        return 'Return Request';
      default:
        return '';
    }
  }

  String get _normalizedDeliveryType =>
      DeliveryRequestTypes.normalize(widget.deliveryType);

  bool get _isPartDeliveryType =>
      _normalizedDeliveryType == DeliveryRequestTypes.part;

  Map<String, dynamic> get _product => _mapFrom(_detailSafe['product']);
  Map<String, dynamic> get _serviceRequest => _mapFrom(_detailSafe['service_request']);
  Map<String, dynamic> get _customer => _mapFrom(_detailSafe['customer']);
  Map<String, dynamic> get _customerAddress => _mapFrom(_detailSafe['customer_address']);

  String get _displayRequestType {
    final apiRequestType = _firstNonEmpty(
      <dynamic>[
        _detailSafe['request_type'],
      ],
      fallback: '',
    );
    final apiLabel = _requestTypeLabelFromApi(apiRequestType);
    if (apiLabel.isNotEmpty) return apiLabel;

    return DeliveryRequestTypes.labelFor(widget.deliveryType);
  }

  String get _displayRequestId => _firstNonEmpty(
    <dynamic>[
      _detailSafe['request_id'],
      _detailSafe['id'],
    ],
  );

  String get _displayImageUrl {
    final raw = _firstNonEmpty(
      <dynamic>[
        _product['main_product_image'],
      ],
      fallback: '',
    );

    if (raw.isEmpty) return '';
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    if (raw.startsWith('/')) return '${ApiConstants.baseUrl}$raw';
    return '${ApiConstants.baseUrl}/$raw';
  }

  String get _displayProductName {
    return _firstNonEmpty(
      <dynamic>[
        _isPartDeliveryType ? _product['product_name'] : _product['name'],
      ],
    );
  }

  String get _displayModelNo => _firstNonEmpty(
    <dynamic>[
      _product['model_no'],
    ],
  );

  String get _displayDescription => _firstNonEmpty(
    <dynamic>[
      _isPartDeliveryType ? _product['short_description'] : _product['description'],
    ],
  );

  String get _displayPriceOrChargeLabel =>
      _isPartDeliveryType ? 'Final Price' : 'Service Charge';

  String get _displayPriceOrCharge => _firstNonEmpty(
    <dynamic>[
      _isPartDeliveryType ? _product['final_price'] : _product['service_charge'],
    ],
  );

  String get _displayCustomerName => _joinNonEmpty(
    <dynamic>[
      _customer['first_name'],
      _customer['last_name'],
    ],
  );

  String get _displayCustomerPhone {
    return _firstNonEmpty(
      <dynamic>[
        _customer['phone'],
        _customer['phone_number'],
      ],
    );
  }

  String get _displayCustomerEmail => _firstNonEmpty(
    <dynamic>[
      _customer['email'],
    ],
  );

  String get _displayBranchName => _firstNonEmpty(
    <dynamic>[
      _customerAddress['branch_name'],
    ],
  );

  String get _displayAddressLine {
    final address1 = _firstNonEmpty(
      <dynamic>[
        _customerAddress['address1'],
        _customerAddress['address_1'],
      ],
      fallback: '',
    );
    final address2 = _firstNonEmpty(
      <dynamic>[
        _customerAddress['address2'],
        _customerAddress['address_2'],
      ],
      fallback: '',
    );
    final fromAddressObject = _joinNonEmpty(
      <dynamic>[address1, address2],
      separator: ', ',
      fallback: '',
    );
    if (fromAddressObject.isNotEmpty) return fromAddressObject;

    return 'N/A';
  }

  String get _displayCity => _firstNonEmpty(
    <dynamic>[
      _customerAddress['city'],
    ],
  );

  String get _displayState => _firstNonEmpty(
    <dynamic>[
      _customerAddress['state'],
    ],
  );

  String get _displayCountry => _firstNonEmpty(
    <dynamic>[
      _customerAddress['country'],
    ],
  );

  String get _displayPincode => _firstNonEmpty(
    <dynamic>[
      _customerAddress['pincode'],
      _customerAddress['pin_code'],
    ],
  );

  String get _displayCustomerAddressForNavigation {
    final parts = <String>[
      _displayAddressLine,
      _displayCity,
      _displayState,
      _displayCountry,
      _displayPincode,
    ].where((part) => part != 'N/A').toList();

    if (parts.isNotEmpty) return parts.join(', ');
    return 'N/A';
  }

  String get _acceptId => _firstNonEmpty(
    <dynamic>[
      _detailSafe['id'],
    ],
    fallback: '',
  );

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _onAcceptPressed() async {
    if (_isAccepting) return;

    final acceptId = _acceptId;
    if (acceptId.isEmpty) {
      _showSnack('Unable to accept request: delivery id is missing.');
      return;
    }

    setState(() {
      _isAccepting = true;
    });

    final response = await ApiService.acceptDeliveryRequest(
      deliveryType: widget.deliveryType,
      deliveryId: acceptId,
      roleId: widget.roleId,
    );

    if (!mounted) return;

    setState(() {
      _isAccepting = false;
    });

    final responseMessage = (response.message ?? '').trim();
    final message = responseMessage.isNotEmpty
        ? responseMessage
        : (response.success
            ? 'Delivery request accepted successfully'
            : 'Failed to accept delivery request');
    _showSnack(message);

    if (!response.success) return;

    Navigator.pushNamed(
      context,
      AppRoutes.DeliveryMapTrackingScreen,
      arguments: deliverymaptrackingArguments(
        roleId: widget.roleId,
        roleName: widget.roleName,
        deliveryType: widget.deliveryType,
        deliveryId: acceptId,
        requestId: _displayRequestId,
        productName: _displayProductName,
        customerName: _displayCustomerName,
        customerPhone: _displayCustomerPhone,
        customerAddress: _displayCustomerAddressForNavigation,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showActionButton = !_isLoading && _errorMessage == null && _hasDetail;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: DeliveryProductDetailScreen._primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Delivery Details - $_displayRequestType',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
      bottomNavigationBar: showActionButton
          ? SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isAccepting ? null : _onAcceptPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DeliveryProductDetailScreen._primaryGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isAccepting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Accept',
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

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: DeliveryProductDetailScreen._primaryGreen,
        ),
      );
    }

    if (_errorMessage != null) {
      return _DeliveryDetailErrorState(
        message: _errorMessage!,
        onRetry: _fetchDetails,
      );
    }

    if (!_hasDetail) {
      return _DeliveryDetailEmptyState(onRetry: _fetchDetails);
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 210,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _DeliveryProductImage(imageUrl: _displayImageUrl),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _displayRequestType,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Request ID: $_displayRequestId',
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            const Text(
              'Product Details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            _detailRow('Product Name', _displayProductName),
            _detailRow('Model No', _displayModelNo),
            _detailRow('Description', _displayDescription),
            _detailRow(_displayPriceOrChargeLabel, _displayPriceOrCharge),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 16),
            const Text(
              'Customer Details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            _detailRow('Customer Name', _displayCustomerName),
            _detailRow('Phone', _displayCustomerPhone),
            _detailRow('Email', _displayCustomerEmail),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 16),
            const Text(
              'Location Details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            _detailRow('Branch Name', _displayBranchName),
            _detailRow('Address', _displayAddressLine),
            _detailRow('City', _displayCity),
            _detailRow('State', _displayState),
            _detailRow('Country', _displayCountry),
            _detailRow('Pincode', _displayPincode),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Text(': ', style: TextStyle(fontSize: 13, color: Colors.black54)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13.5,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryProductImage extends StatelessWidget {
  final String imageUrl;

  const _DeliveryProductImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return const _DeliveryImagePlaceholder();
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const _DeliveryImagePlaceholder(),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const _DeliveryImagePlaceholder(showLoader: true);
      },
    );
  }
}

class _DeliveryImagePlaceholder extends StatelessWidget {
  final bool showLoader;

  const _DeliveryImagePlaceholder({this.showLoader = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF3F4F6),
      alignment: Alignment.center,
      child: showLoader
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(
              Icons.image_not_supported_outlined,
              color: Color(0xFF6B7280),
              size: 34,
            ),
    );
  }
}

class _DeliveryDetailErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DeliveryDetailErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 28,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryDetailEmptyState extends StatelessWidget {
  final VoidCallback onRetry;

  const _DeliveryDetailEmptyState({
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.inbox_outlined,
              color: Color(0xFF6B7280),
              size: 28,
            ),
            const SizedBox(height: 12),
            const Text(
              'No delivery request details found',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
