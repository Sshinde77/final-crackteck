import 'package:flutter/material.dart';

import '../../constants/api_constants.dart';
import '../../model/Delivery_person/return_order_detail_model.dart';
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
  ReturnOrderDetailModel? _returnOrderDetail;

  @override 
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _returnOrderDetail = null;
    });

    try {
      final rawDetail =
          _normalizedDeliveryType == DeliveryRequestTypes.returnOrder
          ? (await ApiService.fetchReturnOrderDetailModel(
              deliveryId: widget.deliveryId,
              roleId: widget.roleId,
            )).rawResponse
          : await ApiService.fetchDeliveryRequestDetail(
              deliveryType: widget.deliveryType,
              deliveryId: widget.deliveryId,
              roleId: widget.roleId,
            );
      final normalizedDetail = _normalizeDetail(rawDetail);
      final returnOrderDetail =
          _normalizedDeliveryType == DeliveryRequestTypes.returnOrder
          ? ReturnOrderDetailModel.fromJson(
              rawDetail,
              fallbackOrderId: widget.deliveryId,
            )
          : null;

      if (!mounted) return;
      setState(() {
        _detail = normalizedDetail;
        _returnOrderDetail = returnOrderDetail;
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
      payload['address_detail'],
      serviceRequest['customer_address'],
      serviceRequest['address_detail'],
      rawDetail['shipping_address'],
      rawDetail['customer_address'],
      rawDetail['address_detail'],
    ]);
    final shippingAddress = _firstMap(<dynamic>[
      payload['shipping_address'],
      payload['address_detail'],
      serviceRequest['address_detail'],
      rawDetail['shipping_address'],
      customerAddress,
    ]);
    final primaryWarehouse = _firstMap(<dynamic>[
      payload['primary_warehouse'],
      rawDetail['primary_warehouse'],
    ]);

    return <String, dynamic>{
      'payload': payload,
      'product': product,
      'service_request': serviceRequest,
      'customer': customer,
      'customer_address': customerAddress,
      'shipping_address': shippingAddress,
      'primary_warehouse': primaryWarehouse,
      'request_type': _firstNonEmpty(
        <dynamic>[
          payload['request_type'],
          serviceRequest['request_type'],
          if (_isOrderBasedDeliveryType) _normalizedDeliveryType,
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
      case DeliveryRequestTypes.returnOrder:
        final returnOrder = _mapFrom(rawDetail['return_order']);
        if (returnOrder.isNotEmpty) return returnOrder;
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
    if (_isOrderBasedDeliveryType) {
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
      _customerAddress.isNotEmpty ||
      (_typedReturnOrderDetail?.hasData ?? false);

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

  bool _hasVisibleValue(String? value) {
    if (value == null) return false;
    final normalized = value.trim();
    return normalized.isNotEmpty &&
        normalized.toLowerCase() != 'n/a' &&
        normalized.toLowerCase() != 'null';
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

  ReturnOrderDetailModel? get _typedReturnOrderDetail =>
      _normalizedDeliveryType == DeliveryRequestTypes.returnOrder
      ? _returnOrderDetail
      : null;

  bool get _isPartDeliveryType =>
      _normalizedDeliveryType == DeliveryRequestTypes.part ||
      _normalizedDeliveryType == DeliveryRequestTypes.productDelivery;

  bool get _isOrderBasedDeliveryType =>
      _normalizedDeliveryType == DeliveryRequestTypes.productDelivery ||
      _normalizedDeliveryType == DeliveryRequestTypes.returnOrder;

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
            _typedReturnOrderDetail?.orderNumber,
            _typedReturnOrderDetail?.requestId,
            _typedReturnOrderDetail?.id,
            _detailSafe['request_id'],
            _detailSafe['id'],
            widget.requestId,
            widget.deliveryId,
          ],
        ),
      );

  String get _displayHeaderId => _firstNonEmpty(
        <dynamic>[
          _typedReturnOrderDetail?.orderNumber,
          _typedReturnOrderDetail?.requestId,
          _typedReturnOrderDetail?.id,
          if (_isOrderBasedDeliveryType)
            _payload['order_number'],
          _detailSafe['request_id'],
          widget.requestId,
          widget.deliveryId,
        ],
      );

  String get _displayImageUrl {
    final raw = _firstNonEmpty(
      <dynamic>[
        _typedReturnOrderDetail?.product.imageUrl,
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
          _typedReturnOrderDetail?.product.productName,
          (_isPartDeliveryType || _isOrderBasedDeliveryType)
              ? _product['product_name']
              : _product['name'],
          _mapFrom(_product['product_details'])['product_name'],
          _product['name'],
          widget.productName,
        ],
      );

  String get _displayModelNo => _firstNonEmpty(
        <dynamic>[
          _typedReturnOrderDetail?.product.modelNo,
          _mapFrom(_product['product_details'])['model_no'],
          _product['model_no'],
          _product['model'],
        ],
      );

  String get _displayMacAddress => _firstNonEmpty(
        <dynamic>[
          _typedReturnOrderDetail?.product.macAddress,
          _product['mac_address'],
          _product['macAddress'],
          _mapFrom(_product['product_details'])['mac_address'],
          _mapFrom(_product['product_details'])['macAddress'],
        ],
        fallback: '',
      );

  String get _displayPriceOrCharge => _normalizePrice(
        _firstNonEmpty(
          <dynamic>[
            _typedReturnOrderDetail?.totalAmount,
            _typedReturnOrderDetail?.product.unitPrice,
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
          _typedReturnOrderDetail?.quantity,
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
          _typedReturnOrderDetail?.customer.firstName,
          _typedReturnOrderDetail?.customer.lastName,
          _typedReturnOrderDetail?.customer.fullName,
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
          _typedReturnOrderDetail?.customer.phone,
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
          _typedReturnOrderDetail?.customer.email,
          _customer['email'],
          _customer['email_id'],
        ],
      );

  Map<String, dynamic> get _shippingAddress =>
      _firstMap(<dynamic>[_detailSafe['shipping_address'], _payload['shipping_address']]);
  Map<String, dynamic> get _warehouseDetails {
    final primaryWarehouse = _mapFrom(_detailSafe['primary_warehouse']);
    if (primaryWarehouse.isNotEmpty) return primaryWarehouse;

    final direct = _mapFrom(_product['warehouse_details']);
    if (direct.isNotEmpty) return direct;

    final nestedProduct = _mapFrom(_product['product_details']);
    final nestedWarehouse = _mapFrom(nestedProduct['warehouse']);
    if (nestedWarehouse.isNotEmpty) return nestedWarehouse;

    final payloadPrimaryWarehouse = _mapFrom(_payload['primary_warehouse']);
    if (payloadPrimaryWarehouse.isNotEmpty) return payloadPrimaryWarehouse;

    final payloadWarehouse = _mapFrom(_payload['warehouse']);
    if (payloadWarehouse.isNotEmpty) return payloadWarehouse;

    return _mapFrom(_payload['warehouse_details']);
  }

  Map<String, dynamic> get _addressDetail => _firstMap(<dynamic>[
        _payload['address_detail'],
        _serviceRequest['address_detail'],
        _detailSafe['address_detail'],
      ]);

  String get _displayWarehouseName => _firstNonEmpty(
        <dynamic>[
          _typedReturnOrderDetail?.warehouseAddress.name,
          _typedReturnOrderDetail?.warehouseAddress.branchName,
          _warehouseDetails['name'],
          _warehouseDetails['branch_name'],
        ],
        fallback: 'Warehouse',
      );

  String get _displayBranchName => _firstNonEmpty(
        <dynamic>[
          _typedReturnOrderDetail?.shippingAddress.branchName,
          _typedReturnOrderDetail?.customerAddress.branchName,
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
        _typedReturnOrderDetail?.customerAddress.address1,
        _typedReturnOrderDetail?.shippingAddress.address1,
        _shippingAddress['address1'],
        _customerAddress['address1'],
        _customerAddress['address_1'],
      ],
      fallback: '',
    );
    final address2 = _firstNonEmpty(
      <dynamic>[
        _typedReturnOrderDetail?.customerAddress.address2,
        _typedReturnOrderDetail?.shippingAddress.address2,
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
        <dynamic>[
          _typedReturnOrderDetail?.customerAddress.city,
          _typedReturnOrderDetail?.shippingAddress.city,
          _shippingAddress['city'],
          _customerAddress['city'],
        ],
      );

  String get _displayState => _firstNonEmpty(
        <dynamic>[
          _typedReturnOrderDetail?.customerAddress.state,
          _typedReturnOrderDetail?.shippingAddress.state,
          _shippingAddress['state'],
          _customerAddress['state'],
        ],
      );

  String get _displayCountry => _firstNonEmpty(
        <dynamic>[
          _typedReturnOrderDetail?.customerAddress.country,
          _typedReturnOrderDetail?.shippingAddress.country,
          _shippingAddress['country'],
          _customerAddress['country'],
        ],
      );

  String get _displayPincode => _firstNonEmpty(
        <dynamic>[
          _typedReturnOrderDetail?.customerAddress.pincode,
          _typedReturnOrderDetail?.shippingAddress.pincode,
          _shippingAddress['pincode'],
          _customerAddress['pincode'],
          _customerAddress['pin_code'],
        ],
      );

  String get _displayFromLocation {
    final returnOrderDetail = _typedReturnOrderDetail;
    if (returnOrderDetail != null) {
      final value = _firstNonEmpty(
        <dynamic>[
          returnOrderDetail.warehouseAddress.formatted,
          returnOrderDetail.warehouseAddress.primaryLabel,
          widget.location,
        ],
        fallback: 'Warehouse',
      );
      return value;
    }
    if (_normalizedDeliveryType == DeliveryRequestTypes.productDelivery) {
      return _formatAddress(_warehouseDetails, fallback: _displayWarehouseName);
    }
    if (_normalizedDeliveryType == DeliveryRequestTypes.part) {
      return _formatAddress(_warehouseDetails, fallback: _displayWarehouseName);
    }
    if (_normalizedDeliveryType == DeliveryRequestTypes.pickup) {
      return _formatAddress(_warehouseDetails, fallback: _displayWarehouseName);
    }
    if (_normalizedDeliveryType == DeliveryRequestTypes.returnRequest) {
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
    final returnOrderDetail = _typedReturnOrderDetail;
    if (returnOrderDetail != null) {
      return _firstNonEmpty(
        <dynamic>[
          returnOrderDetail.customerAddress.formatted,
          returnOrderDetail.shippingAddress.formatted,
          widget.customerAddress,
        ],
        fallback: 'Customer address not available',
      );
    }
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
    if (_normalizedDeliveryType == DeliveryRequestTypes.pickup) {
      return _formatAddress(
        _customerAddress,
        fallback: 'Customer address not available',
      );
    }
    if (_normalizedDeliveryType == DeliveryRequestTypes.returnRequest) {
      return _formatAddress(
        _addressDetail,
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
    final returnOrderDetail = _typedReturnOrderDetail;
    if (returnOrderDetail != null) {
      return _firstNonEmpty(
        <dynamic>[
          returnOrderDetail.customerAddress.formatted,
          returnOrderDetail.shippingAddress.formatted,
          widget.customerAddress,
        ],
        fallback: 'N/A',
      );
    }
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
          _typedReturnOrderDetail?.id,
          _detailSafe['id'],
          widget.deliveryId,
        ],
        fallback: '',
      );

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String get _currentStatus => _firstNonEmpty(
        <dynamic>[
          _typedReturnOrderDetail?.status,
          _payload['status'],
          _payload['order_status'],
          widget.status,
        ],
        fallback: '',
      );

  String get _statusKey =>
      _currentStatus.trim().toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');

  bool get _shouldContinueReturnOrder =>
      _normalizedDeliveryType == DeliveryRequestTypes.returnOrder &&
      <String>{
        'approved',
        'accepted',
        'orderaccepted',
        'picked',
        'inprogress',
      }.contains(_statusKey);

  void _openTrackingScreen(String deliveryId) {
    Navigator.pushNamed(
      context,
      AppRoutes.DeliveryMapTrackingScreen,
      arguments: deliverymaptrackingArguments(
        roleId: widget.roleId,
        roleName: widget.roleName,
        deliveryType: widget.deliveryType,
        deliveryId: deliveryId,
        requestId: _displayRequestId,
        productName: _displayProductName,
        customerName: _displayCustomerName,
        customerPhone: _displayCustomerPhone,
        customerAddress: _displayCustomerAddressForNavigation,
      ),
    );
  }

  Future<void> _onAcceptPressed() async {
    if (_isAccepting) return;

    final acceptId = _acceptId;
    if (acceptId.isEmpty) {
      _showSnack('Unable to accept request: delivery id is missing.');
      return;
    }

    if (_shouldContinueReturnOrder) {
      _openTrackingScreen(acceptId);
      return;
    }

    setState(() {
      _isAccepting = true;
    });

    final response =
        _normalizedDeliveryType == DeliveryRequestTypes.returnOrder
        ? await ApiService.acceptReturnOrder(
            deliveryId: acceptId,
            roleId: widget.roleId,
          )
        : await ApiService.acceptDeliveryRequest(
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

    _openTrackingScreen(acceptId);
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
          widget.requestType.trim().isEmpty
              ? 'Delivery Details'
              : widget.requestType,
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
                        : Text(
                            _shouldContinueReturnOrder ? 'Continue' : 'Accept',
                            style: const TextStyle(
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
    final fromLocation = _displayFromLocation;
    final toLocation = _displayToLocation;

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
          if (_hasVisibleValue(fromLocation))
            _locationRow(
              label: 'From:',
              value: fromLocation,
            ),
          if (_hasVisibleValue(fromLocation) && _hasVisibleValue(toLocation))
            SizedBox(height: _isCompactLayout ? 14 : 18),
          if (_hasVisibleValue(toLocation))
            _locationRow(
              label: 'To:',
              value: toLocation,
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
    final details = <String>[
      if (_displayModelNo.isNotEmpty && _displayModelNo != 'N/A')
        'Model: $_displayModelNo',
      if (_displayMacAddress.isNotEmpty && _displayMacAddress != 'N/A')
        'MAC: $_displayMacAddress',
    ];
    final priceOrCharge = _displayPriceOrCharge;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_hasVisibleValue(_displayProductName))
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
        if (details.isNotEmpty) ...[
          SizedBox(height: compact ? 6 : 8),
          ...details.map(
            (detail) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                detail,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: compact ? 12.5 : 13,
                  color: const Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
        if (_hasVisibleValue(priceOrCharge)) ...[
          SizedBox(height: compact ? 8 : 10),
          Text(
            priceOrCharge,
            style: TextStyle(
              fontSize: compact ? 16 : 17,
              color: Colors.black,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildExtraDetailsCard() {
    final returnOrderDetail = _typedReturnOrderDetail;
    if (returnOrderDetail != null) {
      final items = <MapEntry<String, String>>[
        MapEntry('Order No', _displayHeaderId),
        MapEntry('Status', _currentStatus),
        MapEntry('First Name', returnOrderDetail.customer.firstName),
        MapEntry('Last Name', returnOrderDetail.customer.lastName),
        MapEntry('Customer', _displayCustomerName),
        MapEntry('Phone', _displayCustomerPhone),
        MapEntry('Email', _displayCustomerEmail),
        MapEntry(
          'Shipping Branch',
          _firstNonEmpty(<dynamic>[
            returnOrderDetail.shippingAddress.branchName,
            returnOrderDetail.customerAddress.branchName,
          ], fallback: ''),
        ),
        MapEntry('Payment Status', returnOrderDetail.paymentStatus),
        MapEntry(
          'Total Amount',
          _normalizePrice(returnOrderDetail.totalAmount),
        ),
        MapEntry(
          'Unit Price',
          _normalizePrice(returnOrderDetail.product.unitPrice),
        ),
        MapEntry('Quantity', _displayQuantity),
        MapEntry('Product Name', _displayProductName),
        MapEntry('Model No', _displayModelNo),
        MapEntry('MAC Address', _displayMacAddress),
        MapEntry('HSN Code', returnOrderDetail.product.hsnCode),
        MapEntry('Weight', returnOrderDetail.product.weight),
        MapEntry('Dimensions', returnOrderDetail.product.dimensions),
        MapEntry('Shipping Time', returnOrderDetail.product.shippingTime),
        MapEntry('Brand Warranty', returnOrderDetail.product.brandWarranty),
        MapEntry('COD', returnOrderDetail.product.cod),
        MapEntry('Installation', returnOrderDetail.product.installation),
        MapEntry('Warehouse', _displayWarehouseName),
        MapEntry(
          'Warehouse Code',
          returnOrderDetail.warehouseAddress.warehouseCode,
        ),
        MapEntry(
          'Warehouse Contact',
          returnOrderDetail.warehouseAddress.phoneNumber,
        ),
        MapEntry(
          'Warehouse Address',
          returnOrderDetail.warehouseAddress.formatted,
        ),
        MapEntry(
          'Shipping Address',
          _firstNonEmpty(<dynamic>[
            returnOrderDetail.shippingAddress.formatted,
            returnOrderDetail.customerAddress.formatted,
          ], fallback: ''),
        ),
        MapEntry(
          'Customer Address',
          _firstNonEmpty(<dynamic>[
            returnOrderDetail.customerAddress.formatted,
            returnOrderDetail.shippingAddress.formatted,
          ], fallback: ''),
        ),
        MapEntry('Expected Delivery', returnOrderDetail.expectedDeliveryDate),
        MapEntry('Customer Notes', returnOrderDetail.customerNotes),
        MapEntry('Admin Notes', returnOrderDetail.adminNotes),
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
      MapEntry('Product Name', _displayProductName),
      MapEntry('Model No', _displayModelNo),
      MapEntry('MAC Address', _displayMacAddress),
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
      MapEntry(
        'Shipping Address',
        _formatAddress(
          _firstMap(<dynamic>[_shippingAddress, _addressDetail, _customerAddress]),
        ),
      ),
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
