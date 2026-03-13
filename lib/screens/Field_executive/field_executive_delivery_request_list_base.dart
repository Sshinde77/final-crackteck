import 'package:flutter/material.dart';

import '../../core/secure_storage_service.dart';
import '../../services/api_service.dart';
import 'field_executive_delivery_part_request_detail_screen.dart';
import 'field_executive_delivery_product_detail_screen.dart';
import 'field_executive_delivery_flow_helpers.dart';
import 'field_executive_delivery_pickup_detail_screen.dart';
import 'field_executive_delivery_return_detail_screen.dart';

class FieldExecutiveDeliveryRequestListBase extends StatefulWidget {
  final int roleId;
  final String roleName;
  final String deliveryType;
  final String appBarTitle;

  const FieldExecutiveDeliveryRequestListBase({
    super.key,
    required this.roleId,
    required this.roleName,
    required this.deliveryType,
    required this.appBarTitle,
  });

  @override
  State<FieldExecutiveDeliveryRequestListBase> createState() =>
      _FieldExecutiveDeliveryRequestListBaseState();
}

class _FieldExecutiveDeliveryRequestListBaseState
    extends State<FieldExecutiveDeliveryRequestListBase> {
  static const Color primaryGreen = Color(0xFF1E7C10);

  bool _isLoading = true;
  String? _error;
  int? _userId;
  List<FieldExecutiveDeliveryRequest> _requests =
      <FieldExecutiveDeliveryRequest>[];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiService.fetchDeliveryRequests(
        deliveryType: widget.deliveryType,
        roleId: widget.roleId,
      );
      final userId = await SecureStorageService.getUserId();
      if (!mounted) return;

      setState(() {
        _userId = userId;
        _requests = response
            .map(
              (item) => FieldExecutiveDeliveryRequest.fromApi(
                item,
                fallbackType: widget.deliveryType,
              ),
            )
            .where((item) => item.requestId.isNotEmpty)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _openDetail(FieldExecutiveDeliveryRequest request) {
    final normalizedType = FieldExecutiveDeliveryTypes.normalize(
      widget.deliveryType,
    );

    if (normalizedType == FieldExecutiveDeliveryTypes.productDelivery) {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => DeliveryProductDetailScreen(
            roleId: widget.roleId,
            roleName: widget.roleName,
            deliveryType: widget.deliveryType,
            deliveryId: request.id?.toString() ?? request.requestId,
            requestType: FieldExecutiveDeliveryTypes.label(widget.deliveryType),
            requestId: request.requestId,
            productName: request.productName,
            location: request.location,
            status: request.status,
            customerName: request.customerName,
            customerPhone: request.customerPhone,
            customerAddress: request.customerAddress,
          ),
        ),
      );
      return;
    }

    Widget destination = FieldExecutiveDeliveryReturnDetailScreen(
      roleId: widget.roleId,
      roleName: widget.roleName,
      userId: _userId,
      requestId: request.requestId,
    );
    if (normalizedType == FieldExecutiveDeliveryTypes.pickupRequest) {
      destination = FieldExecutiveDeliveryPickupDetailScreen(
        roleId: widget.roleId,
        roleName: widget.roleName,
        userId: _userId,
        requestId: request.requestId,
      );
    } else if (normalizedType == FieldExecutiveDeliveryTypes.requestPart) {
      destination = FieldExecutiveDeliveryPartRequestDetailScreen(
        roleId: widget.roleId,
        roleName: widget.roleName,
        userId: _userId,
        requestId: request.requestId,
      );
    }

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => destination,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: primaryGreen,
          onRefresh: _loadRequests,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _ErrorCard(
                          message: _error!,
                          onRetry: _loadRequests,
                        ),
                      ],
                    )
                  : _requests.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 150),
                            Center(
                              child: Text(
                                'No delivery requests found',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                          itemCount: _requests.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final request = _requests[index];
                            final requestTypeLabel = FieldExecutiveDeliveryTypes.label(
                              request.deliveryType.isNotEmpty
                                  ? request.deliveryType
                                  : widget.deliveryType,
                            );

                            return InkWell(
                              onTap: () => _openDetail(request),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _InfoRow(
                                      label: 'Request ID',
                                      value: request.displayRequestId,
                                    ),
                                    _InfoRow(
                                      label: 'Request Type',
                                      value: requestTypeLabel,
                                    ),
                                    _InfoRow(
                                      label: 'Status',
                                      value: request.status.isEmpty
                                          ? '-'
                                          : request.status,
                                    ),
                                    if (request.customerName.isNotEmpty)
                                      _InfoRow(
                                        label: 'Customer Name',
                                        value: request.customerName,
                                      ),
                                    if (request.productName.isNotEmpty)
                                      _InfoRow(
                                        label: 'Product Name',
                                        value: request.productName,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
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
