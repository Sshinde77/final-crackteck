import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/api_constants.dart';
import '../../model/Delivery_person/delivery_order_model.dart';
import '../../provider/attendance_provider.dart';
import '../../provider/delivery_person/delivery_home_provider.dart';
import '../../routes/app_routes.dart';
import '../../services/api_service.dart';
import '../../services/delivery_person/delivery_attendance_service.dart';
import '../Field_executive/field_executive_delivery_product_detail_screen.dart';

class DeliveryPersonHomeTab extends StatefulWidget {
  final int roleId;
  final String roleName;

  const DeliveryPersonHomeTab({
    super.key,
    required this.roleId,
    required this.roleName,
  });

  @override
  State<DeliveryPersonHomeTab> createState() => _DeliveryPersonHomeTabState();
}

class _DeliveryPersonHomeTabState extends State<DeliveryPersonHomeTab> {
  final TextEditingController _searchCtrl = TextEditingController();
  final DeliveryAttendanceService _attendanceService =
      DeliveryAttendanceService();
  OrdersTab _activeTab = OrdersTab.productDelivery;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DeliveryHomeProvider>().loadHomeData();
      context.read<AttendanceProvider>().initialize(roleId: widget.roleId);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  String _fmtTime(DateTime? dt) {
    if (dt == null) return '--:-- --';
    return DeliveryOrderModel.formatTime(dt);
  }

  Future<void> _refreshData() async {
    await Future.wait<void>([
      context.read<DeliveryHomeProvider>().loadHomeData(),
      context.read<AttendanceProvider>().initialize(
        roleId: widget.roleId,
        forceRefresh: true,
      ),
    ]);
  }

  String _deliveryTypeForOrder(DeliveryOrderModel order) {
    switch (order.category) {
      case DeliveryOrderCategory.productDelivery:
        return DeliveryRequestTypes.productDelivery;
      case DeliveryOrderCategory.pickupDelivery:
        return DeliveryRequestTypes.pickup;
      case DeliveryOrderCategory.requestPart:
        return DeliveryRequestTypes.part;
      case DeliveryOrderCategory.returnRequest:
        return DeliveryRequestTypes.returnRequest;
    }
  }

  Future<void> _openProductScreen(DeliveryOrderModel order) async {
    final normalizedStatus = order.rawStatus.trim().toLowerCase();
    final statusKey = normalizedStatus.replaceAll(RegExp(r'[^a-z]'), '');
    final deliveryType = _deliveryTypeForOrder(order);
    final normalizedDeliveryType = DeliveryRequestTypes.normalize(deliveryType);

    if (normalizedDeliveryType == DeliveryRequestTypes.part) {
      if (statusKey == 'apapproved') {
        await _openTrackingScreen(order, useFieldExecutiveScreen: true);
        return;
      }
      if (statusKey == 'assigned') {
        await _openPartDetailScreen(order);
        return;
      }
    }
    if (normalizedStatus == 'order_accepted') {
      await _openTrackingScreen(order);
      return;
    }

    final deliveryId = order.id.replaceFirst(RegExp(r'^#'), '');
    final accepted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DeliveryProductDetailScreen(
          roleId: widget.roleId,
          roleName: widget.roleName,
          deliveryType: deliveryType,
          deliveryId: deliveryId,
          requestType: DeliveryRequestTypes.labelFor(deliveryType),
          requestId: order.id,
          productName: '',
          location: order.to,
          status: order.status.name,
          customerName: '',
          customerPhone: '',
          customerAddress: '',
        ),
      ),
    );

    if (accepted == true && mounted) {
      context.read<DeliveryHomeProvider>().markOrderAccepted(order.id);
      _toast('Accepted ${order.id}');
    }
  }

  Future<void> _openPartDetailScreen(DeliveryOrderModel order) async {
    final deliveryType = _deliveryTypeForOrder(order);
    final deliveryId = order.id.replaceFirst(RegExp(r'^#'), '');

    try {
      final rawDetail = await ApiService.fetchDeliveryRequestDetail(
        deliveryType: deliveryType,
        deliveryId: deliveryId,
        roleId: widget.roleId,
      );
      final payload = _resolveDeliveryPayload(rawDetail, deliveryType);
      final serviceRequest = _mapFrom(payload['service_request']);
      final customer = _firstMap(<dynamic>[
        payload['customer'],
        payload['customer_details'],
        serviceRequest['customer'],
        serviceRequest['customer_details'],
      ]);
      final customerAddress = _firstMap(<dynamic>[
        payload['customer_address'],
        payload['shipping_address'],
        serviceRequest['customer_address'],
      ]);
      final payloadProduct = _mapFrom(payload['product']);
      final payloadServiceProduct = _mapFrom(payload['service_request_product']);

      if (!mounted) return;

      await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => DeliveryProductDetailScreen(
            roleId: widget.roleId,
            roleName: widget.roleName,
            deliveryType: deliveryType,
            deliveryId: deliveryId,
            requestType: DeliveryRequestTypes.labelFor(deliveryType),
            requestId: _firstNonEmpty(<dynamic>[
              serviceRequest['request_id'],
              payload['request_id'],
              order.requestId,
              order.displayId,
              order.id,
            ], fallback: order.displayId),
            productName: _firstNonEmpty(<dynamic>[
              payloadProduct['product_name'],
              payloadServiceProduct['name'],
              payloadServiceProduct['product_name'],
            ], fallback: ''),
            location: _formatAddress(
              customerAddress,
              fallback: order.to,
            ),
            status: order.rawStatus,
            customerName: _joinNonEmpty(<dynamic>[
              customer['first_name'],
              customer['last_name'],
              customer['name'],
              customer['full_name'],
            ], fallback: ''),
            customerPhone: _firstNonEmpty(<dynamic>[
              customer['phone'],
              customer['phone_number'],
              customer['mobile'],
              customer['contact_number'],
            ], fallback: ''),
            customerAddress: _formatAddress(
              customerAddress,
              fallback: order.to,
            ),
          ),
        ),
      );
    } catch (error) {
      _toast(
        'Failed to open request detail: ${error.toString().replaceFirst('Exception: ', '')}',
      );
    }
  }

  Future<void> _openTrackingScreen(
    DeliveryOrderModel order, {
    bool useFieldExecutiveScreen = false,
  }) async {
    final deliveryType = _deliveryTypeForOrder(order);
    final deliveryId = order.id.replaceFirst(RegExp(r'^#'), '');

    try {
      final rawDetail = await ApiService.fetchDeliveryRequestDetail(
        deliveryType: deliveryType,
        deliveryId: deliveryId,
        roleId: widget.roleId,
      );
      final payload = _resolveDeliveryPayload(rawDetail, deliveryType);
      final serviceRequest = _mapFrom(payload['service_request']);
      final customer = _firstMap(<dynamic>[
        payload['customer'],
        payload['customer_details'],
        serviceRequest['customer'],
        serviceRequest['customer_details'],
      ]);
      final shippingAddress = _firstMap(<dynamic>[
        payload['shipping_address'],
        payload['customer_address'],
        serviceRequest['customer_address'],
      ]);
      final firstItem = _firstListMap(payload['order_items']);
      final productDetails = _mapFrom(firstItem['product_details']);
      final payloadProduct = _mapFrom(payload['product']);
      final payloadServiceProduct = _mapFrom(payload['service_request_product']);

      if (!mounted) return;

      if (useFieldExecutiveScreen) {
        final requestId = _firstNonEmpty(
          <dynamic>[
            serviceRequest['request_id'],
            payload['request_id'],
            order.requestId,
            payload['id'],
            order.displayId,
          ],
          fallback: order.displayId,
        );
        Navigator.pushNamed(
          context,
          AppRoutes.FieldExecutiveMapTrackingScreen,
          arguments: fieldexecutivemaptrackingArguments(
            roleId: widget.roleId,
            roleName: widget.roleName,
            serviceId: requestId.replaceFirst(RegExp(r'^#'), ''),
            displayServiceId: _normalizeDisplayId(requestId),
            customerName: _joinNonEmpty(
              <dynamic>[
                customer['first_name'],
                customer['last_name'],
                customer['name'],
                customer['full_name'],
              ],
              fallback: 'Customer',
            ),
            customerPhone: _firstNonEmpty(
              <dynamic>[
                customer['phone'],
                customer['phone_number'],
                customer['mobile'],
                customer['contact_number'],
              ],
              fallback: '',
            ),
            customerAddress: _formatAddress(shippingAddress, fallback: order.to),
          ),
        );
        return;
      }

      Navigator.pushNamed(
        context,
        AppRoutes.DeliveryMapTrackingScreen,
        arguments: deliverymaptrackingArguments(
          roleId: widget.roleId,
          roleName: widget.roleName,
          deliveryType: deliveryType,
          deliveryId: deliveryId,
          requestId: _firstNonEmpty(<dynamic>[
            payload['order_number'],
            serviceRequest['request_id'],
            payload['request_id'],
            order.displayId,
            order.id,
          ], fallback: order.displayId),
          productName: _firstNonEmpty(<dynamic>[
            firstItem['product_name'],
            productDetails['product_name'],
            payloadProduct['product_name'],
            payloadServiceProduct['name'],
          ]),
          customerName: _joinNonEmpty(<dynamic>[
            customer['first_name'],
            customer['last_name'],
            customer['name'],
            customer['full_name'],
          ], fallback: 'Customer'),
          customerPhone: _firstNonEmpty(<dynamic>[
            customer['phone'],
            customer['phone_number'],
            customer['mobile'],
            customer['contact_number'],
          ], fallback: ''),
          customerAddress: _formatAddress(shippingAddress, fallback: order.to),
        ),
      );
    } catch (error) {
      _toast(
        'Failed to open tracking: ${error.toString().replaceFirst('Exception: ', '')}',
      );
    }
  }

  Map<String, dynamic> _resolveDeliveryPayload(
    Map<String, dynamic> rawDetail,
    String deliveryType,
  ) {
    final normalizedType = DeliveryRequestTypes.normalize(deliveryType);
    if (normalizedType == DeliveryRequestTypes.productDelivery) {
      final order = _mapFrom(rawDetail['order']);
      if (order.isNotEmpty) return order;
    }
    final data = _mapFrom(rawDetail['data']);
    return data.isNotEmpty ? data : rawDetail;
  }

  Map<String, dynamic> _mapFrom(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const <String, dynamic>{};
  }

  Map<String, dynamic> _firstMap(List<dynamic> values) {
    for (final value in values) {
      final mapped = _mapFrom(value);
      if (mapped.isNotEmpty) return mapped;
    }
    return const <String, dynamic>{};
  }

  Map<String, dynamic> _firstListMap(dynamic value) {
    if (value is List) {
      for (final item in value) {
        final mapped = _mapFrom(item);
        if (mapped.isNotEmpty) return mapped;
      }
    }
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
      if (parsed.isNotEmpty && parsed.toLowerCase() != 'null') return parsed;
    }
    return fallback;
  }

  String _joinNonEmpty(
    List<dynamic> values, {
    String separator = ' ',
    String fallback = 'N/A',
  }) {
    final parts = values
        .map(_asText)
        .where((value) => value.isNotEmpty && value.toLowerCase() != 'null')
        .toList();
    if (parts.isEmpty) return fallback;
    return parts.join(separator);
  }

  String _normalizeDisplayId(String value) {
    final parsed = _asText(value);
    if (parsed.isEmpty || parsed == 'N/A') return parsed;
    return parsed.startsWith('#') ? parsed : '#$parsed';
  }

  String _formatAddress(
    Map<String, dynamic> source, {
    String fallback = 'N/A',
  }) {
    if (source.isEmpty) return fallback;
    final parts = <String>[
      _asText(source['name']),
      _asText(source['branch_name']),
      _asText(source['address1']),
      _asText(source['address2']),
      _asText(source['city']),
      _asText(source['state']),
      _asText(source['country']),
      _asText(source['pincode']),
    ].where((value) => value.isNotEmpty).toList();
    if (parts.isEmpty) return fallback;
    return parts.join(', ');
  }

  Future<void> _handleAttendance({required bool login}) async {
    final attendance = context.read<AttendanceProvider>();
    final message = login
        ? await attendance.clockIn(
            roleId: widget.roleId,
            apiCall: _attendanceService.attendanceLogin,
          )
        : await attendance.clockOut(
            roleId: widget.roleId,
            apiCall: _attendanceService.attendanceLogout,
          );
    if (!mounted) return;
    _toast(message);
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF1E7C10);
    final provider = context.watch<DeliveryHomeProvider>();
    final attendanceProvider = context.watch<AttendanceProvider>();

    final q = _searchCtrl.text.trim().toLowerCase();
    final productDeliveryCount = provider.countByCategory(
      DeliveryOrderCategory.productDelivery,
    );
    final pickupDeliveryCount = provider.countByCategory(
      DeliveryOrderCategory.pickupDelivery,
    );
    final requestPartCount = provider.countByCategory(
      DeliveryOrderCategory.requestPart,
    );
    final returnRequestCount = provider.countByCategory(
      DeliveryOrderCategory.returnRequest,
    );

    final visibleOrders = provider.orders.where((o) {
      final matchesTab = o.category == _activeTab.category;
      final isDelivered =
          o.rawStatus.trim().toLowerCase() == 'delivered' ||
          o.status == DeliveryOrderStatus.delivered;

      if (!matchesTab || isDelivered) return false;
      if (q.isEmpty) return true;

      return o.displayId.toLowerCase().contains(q) ||
          o.id.toLowerCase().contains(q) ||
          o.from.toLowerCase().contains(q) ||
          o.to.toLowerCase().contains(q);
    }).toList();

    final ordersTitle = _activeTab.title;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                HeaderWithSearch(
                  green: green,
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) =>
                      _toast('Searching: "${_searchCtrl.text}"'),
                  onNotificationTap: () {
                    Navigator.of(context, rootNavigator: true).pushNamed(
                      AppRoutes.DeliveryNotificationScreen,
                      arguments: deliverynotificationArguments(
                        roleId: widget.roleId,
                        roleName: widget.roleName,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      AttendanceSection(
                        loginTimeText: _fmtTime(
                          attendanceProvider.attendance.clockInAt,
                        ),
                        logoutTimeText: _fmtTime(
                          attendanceProvider.attendance.clockOutAt,
                        ),
                        isBusy:
                            attendanceProvider.isUpdating ||
                            attendanceProvider.isLoading,
                        onLogin: attendanceProvider.canClockIn
                            ? () => _handleAttendance(login: true)
                            : null,
                        onLogout: attendanceProvider.canClockOut
                            ? () => _handleAttendance(login: false)
                            : null,
                      ),
                      const SizedBox(height: 12),
                      StatsTabsSection(
                        activeTab: _activeTab,
                        onTabChanged: (tab) => setState(() => _activeTab = tab),
                      ),
                      const SizedBox(height: 16),
                      if (provider.isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: CircularProgressIndicator(),
                        )
                      else if (provider.error != null)
                        _HomeStateCard(
                          message: provider.error!,
                          actionLabel: 'Retry',
                          onTap: () => _refreshData(),
                        )
                      else if (visibleOrders.isEmpty)
                        _HomeStateCard(
                          message: 'No orders available right now.',
                          actionLabel: 'Refresh',
                          onTap: () => _refreshData(),
                        )
                      else
                        OrdersSection(
                          title: ordersTitle,
                          orders: visibleOrders,
                          onAccept: _openProductScreen,
                        ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HeaderWithSearch extends StatelessWidget {
  const HeaderWithSearch({
    super.key,
    required this.green,
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    required this.onNotificationTap,
  });

  final Color green;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onNotificationTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 90,
          width: double.infinity,
          decoration: BoxDecoration(color: green),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Align(
            alignment: Alignment.topLeft,
            child: Row(
              children: [
                const Text(
                  'CRACKTECK',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: onNotificationTap,
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.notifications_none,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 22,
          child: Material(
            elevation: 2,
            borderRadius: BorderRadius.circular(10),
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: "Search Today's Order",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 140),
      ],
    );
  }
}

class AttendanceSection extends StatelessWidget {
  const AttendanceSection({
    super.key,
    required this.loginTimeText,
    required this.logoutTimeText,
    required this.isBusy,
    required this.onLogin,
    required this.onLogout,
  });

  final String loginTimeText;
  final String logoutTimeText;
  final bool isBusy;
  final VoidCallback? onLogin;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey, width: 1),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text(
                'Attendance',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              SizedBox(width: 6),
              Icon(
                Icons.arrow_forward_ios_outlined,
                size: 14,
                color: Colors.black54,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _AttendanceTile(
                  label: 'Check-in',
                  icon: Icons.login,
                  pillColor: const Color(0xFF1E7C10),
                  bg: const Color(0xFFEFF7EE),
                  timeText: loginTimeText,
                  onTap: isBusy ? null : onLogin,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AttendanceTile(
                  label: 'Check-out',
                  icon: Icons.logout,
                  pillColor: const Color(0xFFD32F2F),
                  bg: const Color(0xFFFFEFEF),
                  timeText: logoutTimeText,
                  onTap: isBusy ? null : onLogout,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AttendanceTile extends StatelessWidget {
  const _AttendanceTile({
    required this.label,
    required this.icon,
    required this.pillColor,
    required this.bg,
    required this.timeText,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color pillColor;
  final Color bg;
  final String timeText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.55 : 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.black12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: pillColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    Icon(icon, color: Colors.white, size: 14),
                    const SizedBox(width: 15),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                timeText,
                style: const TextStyle(
                  color: Colors.black45,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum OrdersTab { productDelivery, pickupDelivery, requestPart, returnRequest }

extension OrdersTabX on OrdersTab {
  String get title {
    switch (this) {
      case OrdersTab.productDelivery:
        return 'Product Delivery';
      case OrdersTab.pickupDelivery:
        return 'Pickup Delivery';
      case OrdersTab.requestPart:
        return 'Request Part';
      case OrdersTab.returnRequest:
        return 'Return Request';
    }
  }

  DeliveryOrderCategory get category {
    switch (this) {
      case OrdersTab.productDelivery:
        return DeliveryOrderCategory.productDelivery;
      case OrdersTab.pickupDelivery:
        return DeliveryOrderCategory.pickupDelivery;
      case OrdersTab.requestPart:
        return DeliveryOrderCategory.requestPart;
      case OrdersTab.returnRequest:
        return DeliveryOrderCategory.returnRequest;
    }
  }
}

class StatsTabsSection extends StatelessWidget {
  const StatsTabsSection({
    super.key,
    required this.activeTab,
    required this.onTabChanged,
  });

  final OrdersTab activeTab;
  final ValueChanged<OrdersTab> onTabChanged;

  @override
  Widget build(BuildContext context) {
    final cards = <OrdersTab>[
      OrdersTab.productDelivery,
      OrdersTab.pickupDelivery,
      OrdersTab.requestPart,
      OrdersTab.returnRequest,
    ];

    return Row(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          Expanded(
            child: TabStatCard(
              label: cards[i].title,
              selected: activeTab == cards[i],
              onTap: () => onTabChanged(cards[i]),
            ),
          ),
          if (i != cards.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class TabStatCard extends StatelessWidget {
  const TabStatCard({
    super.key,
    required this.label,
    required this.onTap,
    required this.selected,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    const activeGreen = Color(0xFF1E7C10);

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: selected ? activeGreen : const Color(0xFFF4F7F3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? activeGreen : const Color(0xFFD7E8D2),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        child: Center(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,

            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF17321A),
              fontWeight: FontWeight.w700,
              fontSize: 11,
              height: 1.15,
            ),
          ),
        ),
      ),
    );
  }
}

class OrdersSection extends StatelessWidget {
  const OrdersSection({
    super.key,
    required this.title,
    required this.orders,
    required this.onAccept,
  });

  final String title;
  final List<DeliveryOrderModel> orders;
  final ValueChanged<DeliveryOrderModel> onAccept;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        ),
        const SizedBox(height: 10),
        Column(
          children: orders
              .map(
                (o) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: OrderCard(order: o, onAccept: () => onAccept(o)),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order, required this.onAccept});

  final DeliveryOrderModel order;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    final isRequestPart = order.category == DeliveryOrderCategory.requestPart;
    final primaryIdValue = isRequestPart
        ? (order.requestId.trim().isEmpty ? order.displayId : order.requestId)
        : order.displayId;
    if (order.status == DeliveryOrderStatus.cancelled) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Order No: $primaryIdValue',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${order.date}   ${order.time}',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1, thickness: 1, color: Color(0x22000000)),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  width: 50,
                  child: Text(
                    'From:',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                ),
                Expanded(
                  child: Text(
                    order.from,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  width: 50,
                  child: Text(
                    'To:',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                ),
                Expanded(
                  child: Text(
                    order.to,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    const green = Color(0xFF1E7C10);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onAccept,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: order.accepted ? const Color(0xFFB8D8B2) : Colors.black12,
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Order No: $primaryIdValue',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${order.date}   ${order.time}',
                    style: const TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'From:\n${order.from}',
                style: const TextStyle(fontSize: 12, height: 1.25),
              ),
              const SizedBox(height: 6),
              Text(
                'To:\n${order.to}',
                style: const TextStyle(fontSize: 12, height: 1.25),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeStateCard extends StatelessWidget {
  const _HomeStateCard({
    required this.message,
    required this.actionLabel,
    required this.onTap,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E7C10),
            ),
            child: Text(
              actionLabel,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
