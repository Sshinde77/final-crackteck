import 'package:flutter/material.dart';

import '../../services/delivery_person/delivery_track_work_service.dart';
import 'delivery_notification.dart';

class TotalDeliveryScreen extends StatefulWidget {
  const TotalDeliveryScreen({
    super.key,
    this.roleId = 0,
    this.roleName = '',
  });

  final int roleId;
  final String roleName;

  @override
  State<TotalDeliveryScreen> createState() => _TotalDeliveryScreenState();
}

class _TotalDeliveryScreenState extends State<TotalDeliveryScreen> {
  static const Color darkGreen = Color(0xFF145A00);

  final DeliveryTrackWorkService _trackWorkService = DeliveryTrackWorkService();
  bool _isLoading = true;
  String? _errorText;
  Map<String, dynamic> _ordersSummary = <String, dynamic>{};
  Map<String, dynamic> _returnOrdersSummary = <String, dynamic>{};
  Map<String, dynamic> _pickupsSummary = <String, dynamic>{};
  Map<String, dynamic> _partsSummary = <String, dynamic>{};
  List<Map<String, dynamic>> _orders = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _returnOrders = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _pickups = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _parts = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });
    try {
      final response = await _trackWorkService.fetchTrackYourWork();
      final resolved = _resolveTrackWork(response);
      if (!mounted) return;
      setState(() {
        _ordersSummary = resolved.$1;
        _returnOrdersSummary = resolved.$2;
        _pickupsSummary = resolved.$3;
        _partsSummary = resolved.$4;
        _orders = resolved.$5;
        _returnOrders = resolved.$6;
        _pickups = resolved.$7;
        _parts = resolved.$8;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorText = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _value(List<String> keys, {String fallback = '--'}) {
    for (final key in keys) {
      final value = _ordersSummary[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return fallback;
  }

  (
    Map<String, dynamic>,
    Map<String, dynamic>,
    Map<String, dynamic>,
    Map<String, dynamic>,
    List<Map<String, dynamic>>,
    List<Map<String, dynamic>>,
    List<Map<String, dynamic>>,
    List<Map<String, dynamic>>,
  ) _resolveTrackWork(
    Map<String, dynamic> source,
  ) {
    final ordersSummary = _mapFrom(source['orders']);
    final returnOrdersSummary = _mapFrom(source['return_orders']);
    final pickupsSummary = _mapFrom(source['service_request_product_pickups']);
    final partsSummary = _mapFrom(source['service_request_product_request_parts']);

    return (
      ordersSummary,
      returnOrdersSummary,
      pickupsSummary,
      partsSummary,
      _extractPaginatedItems(ordersSummary),
      _extractPaginatedItems(returnOrdersSummary),
      _extractPaginatedItems(pickupsSummary),
      _extractPaginatedItems(partsSummary),
    );
  }

  List<Map<String, dynamic>> _extractPaginatedItems(Map<String, dynamic> summary) {
    final directList = _listFrom(summary['data']);
    if (directList.isNotEmpty) {
      return directList;
    }

    final paginated = _mapFrom(summary['data']);
    final paginatedList = _listFrom(paginated['data']);
    if (paginatedList.isNotEmpty) {
      return paginatedList;
    }

    return const <Map<String, dynamic>>[];
  }

  Map<String, dynamic> _mapFrom(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const <String, dynamic>{};
  }

  List<Map<String, dynamic>> _listFrom(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return const <Map<String, dynamic>>[];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: darkGreen,
        foregroundColor: Colors.white,
        title: const Text('Track Your Work'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DeliveryNotificationScreen(
                    roleId: widget.roleId,
                    roleName: widget.roleName,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.notifications_none),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorText != null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Text(_errorText!, textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _loadData,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _MetricCard(
                              title: _value(
                                const [
                                  'total_assigned',
                                ],
                              ),
                              subtitle: 'Assigned Orders',
                              icon: Icons.inventory_2_outlined,
                            ),
                          ),
                          Expanded(
                            child: _MetricCard(
                              title: _value(
                                const [
                                  'delivered',
                                ],
                              ),
                              subtitle: 'Delivered',
                              icon: Icons.timer_outlined,
                            ),
                          ),
                          Expanded(
                            child: _MetricCard(
                              title: _value(
                                const [
                                  'pending',
                                ],
                              ),
                              subtitle: 'Pending',
                              icon: Icons.account_balance_wallet_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _SectionCard(
                        title: 'Orders',
                        subtitle: 'Product delivery orders',
                        summary: [
                          'Assigned: ${_stat(_ordersSummary, const ['total_assigned'])}',
                          'Delivered: ${_stat(_ordersSummary, const ['delivered'])}',
                          'Pending: ${_stat(_ordersSummary, const ['pending'])}',
                          'In Progress: ${_stat(_ordersSummary, const ['in_progress'])}',
                        ],
                        child: _buildList(
                          _orders,
                          emptyMessage: 'No product delivery orders found.',
                          type: _WorkItemType.order,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SectionCard(
                        title: 'Return Orders',
                        subtitle: 'Assigned return pickups',
                        summary: [
                          'Assigned: ${_stat(_returnOrdersSummary, const ['total_assigned'])}',
                          'Completed: ${_stat(_returnOrdersSummary, const ['completed'])}',
                          'Pending: ${_stat(_returnOrdersSummary, const ['pending'])}',
                          'Cancelled: ${_stat(_returnOrdersSummary, const ['cancelled'])}',
                        ],
                        child: _buildList(
                          _returnOrders,
                          emptyMessage: 'No return orders found.',
                          type: _WorkItemType.returnOrder,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SectionCard(
                        title: 'Service Product Pickups',
                        subtitle: 'Pickup tasks for service requests',
                        summary: [
                          'Assigned: ${_stat(_pickupsSummary, const ['total_assigned'])}',
                          'Completed: ${_stat(_pickupsSummary, const ['completed'])}',
                          'Pending: ${_stat(_pickupsSummary, const ['pending'])}',
                          'Cancelled: ${_stat(_pickupsSummary, const ['cancelled'])}',
                        ],
                        child: _buildList(
                          _pickups,
                          emptyMessage: 'No service product pickups found.',
                          type: _WorkItemType.pickup,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SectionCard(
                        title: 'Request Parts',
                        subtitle: 'Assigned service request part deliveries',
                        summary: [
                          'Assigned: ${_stat(_partsSummary, const ['total_assigned'])}',
                          'Completed: ${_stat(_partsSummary, const ['completed'])}',
                          'Pending: ${_stat(_partsSummary, const ['pending'])}',
                          'Cancelled: ${_stat(_partsSummary, const ['cancelled'])}',
                        ],
                        child: _buildList(
                          _parts,
                          emptyMessage: 'No service request part tasks found.',
                          type: _WorkItemType.part,
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  String _stat(Map<String, dynamic> source, List<String> keys) {
    return _read(source, keys, fallback: '0');
  }

  Widget _buildList(
    List<Map<String, dynamic>> items, {
    required String emptyMessage,
    required _WorkItemType type,
  }) {
    if (items.isEmpty) {
      return _EmptyState(message: emptyMessage);
    }
    return Column(
      children: items
          .map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _WorkItemCard(item: item, type: type),
              ))
          .toList(),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        children: [
          Icon(icon, color: _TotalDeliveryScreenState.darkGreen),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

enum _WorkItemType {
  order,
  returnOrder,
  pickup,
  part,
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.summary,
    required this.child,
  });

  final String title;
  final String subtitle;
  final List<String> summary;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: summary
                .map(
                  (item) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F7F2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _WorkItemCard extends StatelessWidget {
  const _WorkItemCard({required this.item, required this.type});

  final Map<String, dynamic> item;
  final _WorkItemType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _titleForItem(item, type),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            _statusForItem(item, type),
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 10),
          Text(
            _subtitleForItem(item, type),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.black54),
      ),
    );
  }
}

String _text(
  Map<String, dynamic> source,
  List<String> keys, {
  String fallback = '',
}) {
  return _read(source, keys, fallback: fallback);
}

String _read(
  Map<String, dynamic> source,
  List<String> keys, {
  String fallback = '',
}) {
  for (final key in keys) {
    final value = source[key];
    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString().trim();
    }
  }
  return fallback;
}

String _orderNumber(Map<String, dynamic> order) {
  return _text(
    order,
    const ['order_number', 'order_id', 'order_no', 'request_id', 'id'],
    fallback: '#--',
  );
}

String _titleForItem(Map<String, dynamic> item, _WorkItemType type) {
  switch (type) {
    case _WorkItemType.order:
    case _WorkItemType.returnOrder:
      return _orderNumber(item);
    case _WorkItemType.pickup:
      return _read(
        item,
        const ['request_id', 'id'],
        fallback: 'Pickup Request',
      );
    case _WorkItemType.part:
      return _read(
        item,
        const ['request_id', 'id'],
        fallback: 'Part Request',
      );
  }
}

String _statusForItem(Map<String, dynamic> item, _WorkItemType type) {
  switch (type) {
    case _WorkItemType.order:
    case _WorkItemType.returnOrder:
      return _read(item, const ['delivery_status', 'status'], fallback: 'Pending');
    case _WorkItemType.pickup:
    case _WorkItemType.part:
      return _read(item, const ['status'], fallback: 'Pending');
  }
}

String _subtitleForItem(Map<String, dynamic> item, _WorkItemType type) {
  switch (type) {
    case _WorkItemType.order:
    case _WorkItemType.returnOrder:
      return '${_customerName(item)}\n${_orderAddress(item)}';
    case _WorkItemType.pickup:
      final serviceRequest = item['service_request'];
      final product = item['service_request_product'];
      final requestId = serviceRequest is Map
          ? _read(
              Map<String, dynamic>.from(serviceRequest),
              const ['request_id', 'id'],
            )
          : '';
      final productName = product is Map
          ? _read(
              Map<String, dynamic>.from(product),
              const ['name', 'model_no', 'sku'],
            )
          : '';
      return [
        if (requestId.isNotEmpty) 'Service Request: $requestId',
        if (productName.isNotEmpty) 'Product: $productName',
      ].join('\n');
    case _WorkItemType.part:
      final serviceRequest = item['service_request'];
      final product = item['product'];
      final requestId = serviceRequest is Map
          ? _read(
              Map<String, dynamic>.from(serviceRequest),
              const ['request_id', 'id'],
            )
          : '';
      final productName = product is Map
          ? _read(
              Map<String, dynamic>.from(product),
              const ['product_name', 'name', 'sku'],
            )
          : '';
      return [
        if (requestId.isNotEmpty) 'Service Request: $requestId',
        if (productName.isNotEmpty) 'Part/Product: $productName',
      ].join('\n');
  }
}

String _customerName(Map<String, dynamic> order) {
  final customer = order['customer'];
  if (customer is Map) {
    final firstName = customer['first_name']?.toString().trim() ?? '';
    final lastName = customer['last_name']?.toString().trim() ?? '';
    final fullName = '$firstName $lastName'.trim();
    if (fullName.isNotEmpty) {
      return fullName;
    }
  }

  return _text(
    order,
    const ['customer_name', 'name'],
    fallback: 'Customer',
  );
}

String _orderAddress(Map<String, dynamic> order) {
  final shipping = order['shipping_address'];
  if (shipping is Map) {
    final parts = <String>[
      shipping['branch_name']?.toString().trim() ?? '',
      shipping['address1']?.toString().trim() ?? '',
      shipping['address2']?.toString().trim() ?? '',
      shipping['city']?.toString().trim() ?? '',
      shipping['state']?.toString().trim() ?? '',
      shipping['pincode']?.toString().trim() ?? '',
    ].where((part) => part.isNotEmpty).toList();

    if (parts.isNotEmpty) {
      return parts.join(', ');
    }
  }

  return _text(
    order,
    const ['delivery_address', 'address', 'customer_address'],
    fallback: 'Address not available',
  );
}
