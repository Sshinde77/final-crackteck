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
  static const Color _pageBackground = Color(0xFFF3F3F3);
  static const Color _cardBorder = Color(0xFFE0E0E0);
  static const Color _dangerRed = Color(0xFFD30E0E);

  bool get _isCompactLayout => MediaQuery.sizeOf(context).width < 380;

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
    final customer = _firstMap(<dynamic>[
      payload['customer'],
      payload['customer_details'],
      serviceRequest['customer'],
      serviceRequest['customer_details'],
      rawDetail['customer'],
      rawDetail['customer_details'],
    ]);
    final customerAddress = _firstMap(<dynamic>[
      payload['shipping_address'],
      payload['customer_address'],
      serviceRequest['customer_address'],
      rawDetail['shipping_address'],
      rawDetail['customer_address'],
    ]);
    final shippingAddress = _firstMap(<dynamic>[
      payload['shipping_address'],
      rawDetail['shipping_address'],
      customerAddress,
    ]);

    return <String, dynamic>{
      'payload': payload,
      'product': product,
      'service_request': serviceRequest,
      'customer': customer,
      'customer_address': customerAddress,
      'shipping_address': shippingAddress,
      'request_type': _firstNonEmpty(
        <dynamic>[
          payload['request_type'],
          serviceRequest['request_type'],
          if (_normalizedDeliveryType == DeliveryRequestTypes.productDelivery)
            DeliveryRequestTypes.productDelivery,
        ],
        fallback: '',
      ),
      'request_id': _firstNonEmpty(
        <dynamic>[
          serviceRequest['request_id'],
          payload['request_id'],
          payload['order_number'],
          payload['id'],
        ],
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
      case DeliveryRequestTypes.productDelivery:
        final order = _mapFrom(rawDetail['order']);
        if (order.isNotEmpty) return order;
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
    if (_normalizedDeliveryType == DeliveryRequestTypes.productDelivery) {
      final orderItems = _listOfMaps(payload['order_items']);
      if (orderItems.isNotEmpty) {
        return orderItems.first;
      }
      return _mapFrom(payload['product']);
    }

    if (_normalizedDeliveryType == DeliveryRequestTypes.part) {
      return _mapFrom(payload['product']);
    }
    return _mapFrom(payload['service_request_product']);
  }

  bool get _hasDetail =>
      _payload.isNotEmpty ||
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

  Map<String, dynamic> _firstMap(List<dynamic> values) {
    for (final value in values) {
      final parsed = _mapFrom(value);
      if (parsed.isNotEmpty) return parsed;
    }
    return const <String, dynamic>{};
  }

  List<Map<String, dynamic>> _listOfMaps(dynamic value) {
    if (value is! List) return const <Map<String, dynamic>>[];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
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
      if (parsed.isNotEmpty && parsed.toLowerCase() != 'null') return parsed;
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
        .where((value) => value.isNotEmpty && value.toLowerCase() != 'null')
        .toList();
    if (cleaned.isEmpty) return fallback;
    return cleaned.join(separator);
  }

  String _normalizePrice(String raw) {
    final value = raw.trim();
    if (value.isEmpty || value == 'N/A') return 'N/A';
    if (value.contains('\u20B9')) return value;
    return '\u20B9 $value';
  }

  String _formatAddress(Map<String, dynamic> source, {String fallback = 'N/A'}) {
    final parts = <String>[
      _asText(source['name']),
      _asText(source['branch_name']),
      _asText(source['address1']),
      _asText(source['address2']),
      _asText(source['city']),
      _asText(source['state']),
      _asText(source['country']),
      _asText(source['pincode']),
    ].where((part) => part.isNotEmpty && part.toLowerCase() != 'null').toList();

    if (parts.isEmpty) return fallback;
    return parts.join(', ');
  }

  String _normalizeRequestId(String raw) {
    final value = raw.trim();
    if (value.isEmpty || value == 'N/A') return 'N/A';
    return value.startsWith('#') ? value : '#$value';
  }

  String get _normalizedDeliveryType =>
      DeliveryRequestTypes.normalize(widget.deliveryType);

  bool get _isPartDeliveryType =>
      _normalizedDeliveryType == DeliveryRequestTypes.part ||
      _normalizedDeliveryType == DeliveryRequestTypes.productDelivery;

  Map<String, dynamic> get _payload => _mapFrom(_detailSafe['payload']);
  Map<String, dynamic> get _product => _mapFrom(_detailSafe['product']);
  Map<String, dynamic> get _serviceRequest =>
      _mapFrom(_detailSafe['service_request']);
  Map<String, dynamic> get _customer => _mapFrom(_detailSafe['customer']);
  Map<String, dynamic> get _customerAddress =>
      _mapFrom(_detailSafe['customer_address']);

  String get _displayRequestId => _normalizeRequestId(
        _firstNonEmpty(
          <dynamic>[
            _detailSafe['request_id'],
            _detailSafe['id'],
            widget.requestId,
            widget.deliveryId,
          ],
        ),
      );

  String get _displayHeaderId => _firstNonEmpty(
        <dynamic>[
          if (_normalizedDeliveryType == DeliveryRequestTypes.productDelivery)
            _payload['order_number'],
          _detailSafe['request_id'],
          widget.requestId,
          widget.deliveryId,
        ],
      );

  String get _displayImageUrl {
    final raw = _firstNonEmpty(
      <dynamic>[
        _mapFrom(_product['product_details'])['main_product_image'],
        _product['main_product_image'],
        _product['product_image'],
        _product['image'],
      ],
      fallback: '',
    );

    if (raw.isEmpty) return '';
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    if (raw.startsWith('/')) return '${ApiConstants.siteBaseUrl}$raw';
    return '${ApiConstants.siteBaseUrl}/$raw';
  }

  String get _displayProductName => _firstNonEmpty(
        <dynamic>[
          _isPartDeliveryType ? _product['product_name'] : _product['name'],
          _mapFrom(_product['product_details'])['product_name'],
          _product['name'],
          widget.productName,
        ],
      );

  String get _displayModelNo => _firstNonEmpty(
        <dynamic>[
          _mapFrom(_product['product_details'])['model_no'],
          _product['model_no'],
          _product['model'],
        ],
      );

  String get _displayPriceOrCharge => _normalizePrice(
        _firstNonEmpty(
          <dynamic>[
            _normalizedDeliveryType == DeliveryRequestTypes.productDelivery
                ? _payload['total_amount']
                : _isPartDeliveryType
                ? _product['final_price']
                : _product['service_charge'],
            _product['line_total'],
            _payload['final_price'],
            _payload['total_amount'],
          ],
        ),
      );

  String get _displayQuantity => _firstNonEmpty(
        <dynamic>[
          _product['quantity'],
          _payload['requested_quantity'],
          _payload['quantity'],
          _product['requested_quantity'],
          _product['qty'],
          _payload['total_items'],
        ],
        fallback: '1',
      );

  String get _displayCustomerName => _joinNonEmpty(
        <dynamic>[
          _customer['first_name'],
          _customer['last_name'],
          _customer['name'],
          _customer['full_name'],
          _customer['customer_name'],
          widget.customerName,
        ],
      );

  String get _displayCustomerPhone => _firstNonEmpty(
        <dynamic>[
          _customer['phone'],
          _customer['phone_number'],
          _customer['mobile'],
          _customer['mobile_number'],
          _customer['contact_number'],
          widget.customerPhone,
        ],
      );

  String get _displayCustomerEmail => _firstNonEmpty(
        <dynamic>[
          _customer['email'],
          _customer['email_id'],
        ],
      );

  Map<String, dynamic> get _shippingAddress =>
      _firstMap(<dynamic>[_detailSafe['shipping_address'], _payload['shipping_address']]);
  Map<String, dynamic> get _warehouseDetails {
    final direct = _mapFrom(_product['warehouse_details']);
    if (direct.isNotEmpty) return direct;

    final nestedProduct = _mapFrom(_product['product_details']);
    final nestedWarehouse = _mapFrom(nestedProduct['warehouse']);
    if (nestedWarehouse.isNotEmpty) return nestedWarehouse;

    final payloadWarehouse = _mapFrom(_payload['warehouse']);
    if (payloadWarehouse.isNotEmpty) return payloadWarehouse;

    return _mapFrom(_payload['warehouse_details']);
  }

  String get _displayWarehouseName => _firstNonEmpty(
        <dynamic>[
          _warehouseDetails['name'],
          _warehouseDetails['branch_name'],
        ],
        fallback: 'Warehouse',
      );

  String get _displayBranchName => _firstNonEmpty(
        <dynamic>[
          _shippingAddress['branch_name'],
          _customerAddress['branch_name'],
          _payload['branch_name'],
          widget.location,
        ],
        fallback: 'Warehouse',
      );

  String get _displayAddressLine {
    final address1 = _firstNonEmpty(
      <dynamic>[
        _shippingAddress['address1'],
        _customerAddress['address1'],
        _customerAddress['address_1'],
      ],
      fallback: '',
    );
    final address2 = _firstNonEmpty(
      <dynamic>[
        _shippingAddress['address2'],
        _customerAddress['address2'],
        _customerAddress['address_2'],
      ],
      fallback: '',
    );
    final fromApi = _joinNonEmpty(
      <dynamic>[address1, address2],
      separator: ', ',
      fallback: '',
    );

    if (fromApi.isNotEmpty) return fromApi;
    if (widget.customerAddress.trim().isNotEmpty &&
        widget.customerAddress != 'N/A') {
      return widget.customerAddress.trim();
    }
    return 'N/A';
  }

  String get _displayCity => _firstNonEmpty(
        <dynamic>[_shippingAddress['city'], _customerAddress['city']],
      );

  String get _displayState => _firstNonEmpty(
        <dynamic>[_shippingAddress['state'], _customerAddress['state']],
      );

  String get _displayCountry => _firstNonEmpty(
        <dynamic>[_shippingAddress['country'], _customerAddress['country']],
      );

  String get _displayPincode => _firstNonEmpty(
        <dynamic>[
          _shippingAddress['pincode'],
          _customerAddress['pincode'],
          _customerAddress['pin_code'],
        ],
      );

  String get _displayFromLocation {
    if (_normalizedDeliveryType == DeliveryRequestTypes.productDelivery) {
      return _formatAddress(_warehouseDetails, fallback: _displayWarehouseName);
    }
    if (_normalizedDeliveryType == DeliveryRequestTypes.part) {
      return _formatAddress(_warehouseDetails, fallback: _displayWarehouseName);
    }
    if (_displayBranchName != 'N/A' && _displayBranchName.isNotEmpty) {
      return _displayBranchName;
    }
    if (widget.location.trim().isNotEmpty && widget.location != 'N/A') {
      return widget.location.trim();
    }
    return 'Warehouse';
  }

  String get _displayToLocation {
    if (_normalizedDeliveryType == DeliveryRequestTypes.productDelivery) {
      return _formatAddress(
        _shippingAddress,
        fallback: 'Customer address not available',
      );
    }
    if (_normalizedDeliveryType == DeliveryRequestTypes.part) {
      return _formatAddress(
        _customerAddress,
        fallback: 'Customer address not available',
      );
    }
    final parts = <String>[
      _displayAddressLine,
      _displayCity,
      _displayState,
      _displayPincode,
    ].where((part) => part.isNotEmpty && part != 'N/A').toList();

    if (parts.isNotEmpty) {
      return parts.join(', ');
    }
    if (widget.customerAddress.trim().isNotEmpty &&
        widget.customerAddress != 'N/A') {
      return widget.customerAddress.trim();
    }
    return 'Customer address not available';
  }

  String get _displayCustomerAddressForNavigation {
    if (_normalizedDeliveryType == DeliveryRequestTypes.productDelivery) {
      return _formatAddress(_shippingAddress, fallback: 'N/A');
    }
    final parts = <String>[
      _displayAddressLine,
      _displayCity,
      _displayState,
      _displayCountry,
      _displayPincode,
    ].where((part) => part != 'N/A').toList();

    if (parts.isNotEmpty) return parts.join(', ');
    return widget.customerAddress.trim().isNotEmpty
        ? widget.customerAddress.trim()
        : 'N/A';
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
      backgroundColor: _pageBackground,
      appBar: AppBar(
        backgroundColor: DeliveryProductDetailScreen._primaryGreen,
        toolbarHeight: _isCompactLayout ? 66 : 76,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
            size: _isCompactLayout ? 24 : 26,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 4,
        title: Text(
          'Product to be delivered',
          style: TextStyle(
            color: Colors.white,
            fontSize: _isCompactLayout ? 17 : 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: _isCompactLayout ? 12 : 16),
            child: Icon(
              Icons.notifications_none_rounded,
              color: Colors.white,
              size: _isCompactLayout ? 24 : 26,
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _buildBody(),
      ),
      bottomNavigationBar: showActionButton
          ? SafeArea(
              top: false,
              child: Container(
                color: Colors.white,
                padding: EdgeInsets.fromLTRB(
                  _isCompactLayout ? 16 : 20,
                  12,
                  _isCompactLayout ? 16 : 20,
                  _isCompactLayout ? 14 : 18,
                ),
                child: SizedBox(
                  height: _isCompactLayout ? 50 : 54,
                  child: ElevatedButton(
                    onPressed: _isAccepting ? null : _onAcceptPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DeliveryProductDetailScreen._primaryGreen,
                      disabledBackgroundColor:
                          DeliveryProductDetailScreen._primaryGreen.withValues(
                        alpha: 0.75,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isAccepting
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Accept',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
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
      padding: EdgeInsets.fromLTRB(
        _isCompactLayout ? 12 : 16,
        _isCompactLayout ? 14 : 18,
        _isCompactLayout ? 12 : 16,
        _isCompactLayout ? 14 : 18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(),
          SizedBox(height: _isCompactLayout ? 14 : 18),
          _buildProductCard(),
          SizedBox(height: _isCompactLayout ? 14 : 16),
          _buildExtraDetailsCard(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_isCompactLayout ? 14 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_isCompactLayout ? 18 : 20),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _summaryPair(
                  label: _normalizedDeliveryType ==
                          DeliveryRequestTypes.productDelivery
                      ? 'Order No'
                      : 'Request ID',
                  value: _displayHeaderId,
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: _isCompactLayout ? 12 : 14),
            child: const Divider(
              height: 1,
              thickness: 1.2,
              color: Color(0xFF9E9E9E),
            ),
          ),
          _locationRow(
            label: 'From:',
            value: _displayFromLocation,
          ),
          SizedBox(height: _isCompactLayout ? 14 : 18),
          _locationRow(
            label: 'To:',
            value: _displayToLocation,
          ),
        ],
      ),
    );
  }

  Widget _summaryPair({
    required String label,
    required String value,
    bool alignEnd = false,
  }) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          Text(
            '$label:',
            style: TextStyle(
              fontSize: _isCompactLayout ? 13.5 : 15,
              color: Colors.black,
              fontWeight: FontWeight.w700,
            ),
          ),
        if (label.isEmpty)
        SizedBox(height: _isCompactLayout ? 2 : 4),
        const SizedBox(height: 2),
        Text(
          value,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          style: TextStyle(
            fontSize: _isCompactLayout ? 13.5 : 15,
            color: Colors.black,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _locationRow({
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: _isCompactLayout ? 56 : 64,
          child: Text(
            label,
            style: TextStyle(
              fontSize: _isCompactLayout ? 14.5 : 16,
              color: Colors.black,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: _isCompactLayout ? 13.5 : 15,
              color: Colors.black,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard() {
    final compact = _isCompactLayout;
    final imageSize = compact ? 88.0 : 100.0;
    final cardRadius = compact ? 18.0 : 20.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stackProductMeta = constraints.maxWidth < 360;
          final qtyWidget = Column(
            crossAxisAlignment:
                stackProductMeta ? CrossAxisAlignment.start : CrossAxisAlignment.end,
            children: [
              const Text(
                'Qty',
                style: TextStyle(
                  fontSize: 12.5,
                  color: _dangerRed,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _displayQuantity,
                style: const TextStyle(
                  fontSize: 20,
                  color: _dangerRed,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          );

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: imageSize,
                height: imageSize,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: _DeliveryProductImage(imageUrl: _displayImageUrl),
                ),
              ),
              SizedBox(width: compact ? 10 : 12),
              Expanded(
                child: stackProductMeta
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProductMeta(compact),
                          const SizedBox(height: 10),
                          qtyWidget,
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildProductMeta(compact)),
                          const SizedBox(width: 10),
                          qtyWidget,
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProductMeta(bool compact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _displayProductName,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: compact ? 15.5 : 17,
            height: 1.2,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: compact ? 8 : 10),
        Text(
          _displayPriceOrCharge,
          style: TextStyle(
            fontSize: compact ? 16 : 17,
            color: Colors.black,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildExtraDetailsCard() {
    final productDetails = _mapFrom(_product['product_details']);
    final items = <MapEntry<String, String>>[
      MapEntry('Order No', _displayHeaderId),
      MapEntry('First Name', _firstNonEmpty(<dynamic>[_customer['first_name']], fallback: '')),
      MapEntry('Last Name', _firstNonEmpty(<dynamic>[_customer['last_name']], fallback: '')),
      MapEntry('Customer', _displayCustomerName),
      MapEntry('Phone', _displayCustomerPhone),
      MapEntry('Email', _displayCustomerEmail),
      MapEntry('Shipping Branch', _firstNonEmpty(<dynamic>[_shippingAddress['branch_name']])),
      MapEntry('Payment Status', _firstNonEmpty(<dynamic>[_payload['payment_status']])),
      MapEntry('Total Amount', _normalizePrice(_firstNonEmpty(<dynamic>[_payload['total_amount']]))),
      MapEntry('Unit Price', _normalizePrice(_firstNonEmpty(<dynamic>[_product['unit_price'], _product['line_total']]))),
      MapEntry('Quantity', _displayQuantity),
      MapEntry('Model No', _displayModelNo),
      MapEntry('HSN Code', _firstNonEmpty(<dynamic>[_product['hsn_code'], productDetails['hsn_code']])),
      MapEntry('Weight', _firstNonEmpty(<dynamic>[_product['weight'], productDetails['weight']])),
      MapEntry('Dimensions', _firstNonEmpty(<dynamic>[_product['dimensions'], productDetails['dimensions']])),
      MapEntry('Shipping Time', _firstNonEmpty(<dynamic>[_product['shipping_time'], productDetails['shipping_time']])),
      MapEntry('Brand Warranty', _firstNonEmpty(<dynamic>[productDetails['brand_warranty']])),
      MapEntry('COD', _firstNonEmpty(<dynamic>[_product['cod'], productDetails['cod']])),
      MapEntry('Installation', _firstNonEmpty(<dynamic>[_product['installation'], productDetails['installation']])),
      MapEntry('Warehouse', _displayWarehouseName),
      MapEntry('Warehouse Code', _firstNonEmpty(<dynamic>[_warehouseDetails['warehouse_code']])),
      MapEntry('Warehouse Contact', _firstNonEmpty(<dynamic>[_warehouseDetails['phone_number']])),
      MapEntry('Warehouse Address', _formatAddress(_warehouseDetails)),
      MapEntry('Shipping Address', _formatAddress(_shippingAddress)),
      MapEntry('Expected Delivery', _firstNonEmpty(<dynamic>[_payload['expected_delivery_date']])),
      MapEntry('Customer Notes', _firstNonEmpty(<dynamic>[_payload['customer_notes']], fallback: '')),
      MapEntry('Admin Notes', _firstNonEmpty(<dynamic>[_payload['admin_notes']], fallback: '')),
    ].where((item) => item.value.isNotEmpty && item.value != 'N/A').toList();

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_isCompactLayout ? 14 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_isCompactLayout ? 16 : 18),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Additional Details',
            style: TextStyle(
              fontSize: _isCompactLayout ? 14 : 15,
              color: Colors.black,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: _isCompactLayout ? 10 : 12),
          ...items.map(_detailRow),
        ],
      ),
    );
  }

  Widget _detailRow(MapEntry<String, String> item) {
    return Padding(
      padding: EdgeInsets.only(bottom: _isCompactLayout ? 8 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _isCompactLayout ? 88 : 104,
            child: Text(
              item.key,
              style: TextStyle(
                fontSize: _isCompactLayout ? 12 : 13,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            ': ',
            style: TextStyle(
              fontSize: _isCompactLayout ? 12 : 13,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              item.value,
              style: TextStyle(
                fontSize: _isCompactLayout ? 12.5 : 13.5,
                color: Colors.black87,
                fontWeight: FontWeight.w700,
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
      fit: BoxFit.contain,
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
      color: const Color(0xFFF0F0F0),
      alignment: Alignment.center,
      child: showLoader
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(
              Icons.inventory_2_outlined,
              color: Color(0xFF7C7C7C),
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
              size: 30,
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
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: DeliveryProductDetailScreen._primaryGreen,
              ),
              child: const Text(
                'Retry',
                style: TextStyle(color: Colors.white),
              ),
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
              size: 30,
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
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: DeliveryProductDetailScreen._primaryGreen,
              ),
              child: const Text(
                'Retry',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
