import 'package:flutter/material.dart';

import '../../services/delivery_man_service.dart';
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

  final DeliveryManService _deliveryService = DeliveryManService.instance;
  bool _isLoading = true;
  String? _errorText;
  Map<String, dynamic> _dashboard = <String, dynamic>{};
  List<Map<String, dynamic>> _orders = <Map<String, dynamic>>[];

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
      final results = await Future.wait<dynamic>([
        _deliveryService.fetchDashboard(),
        _deliveryService.fetchOrders(),
      ]);
      if (!mounted) return;
      setState(() {
        _dashboard = results[0] as Map<String, dynamic>;
        _orders = results[1] as List<Map<String, dynamic>>;
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
      final value = _dashboard[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return fallback;
  }

  List<Map<String, dynamic>> get _recentOrders => _orders.take(8).toList();

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
                                const ['total_orders', 'monthly_orders', 'orders_count'],
                              ),
                              subtitle: 'Total Orders',
                              icon: Icons.inventory_2_outlined,
                            ),
                          ),
                          Expanded(
                            child: _MetricCard(
                              title: _value(
                                const ['working_hours', 'weekly_work_hours', 'hours'],
                              ),
                              subtitle: 'Work Hours',
                              icon: Icons.timer_outlined,
                            ),
                          ),
                          Expanded(
                            child: _MetricCard(
                              title: _value(
                                const ['earnings', 'monthly_earnings', 'wallet_balance'],
                              ),
                              subtitle: 'Earnings',
                              icon: Icons.account_balance_wallet_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Current Order',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      if (_orders.isEmpty)
                        const _EmptyState(message: 'No active orders available.')
                      else
                        _OrderCard(order: _orders.first),
                      const SizedBox(height: 20),
                      const Text(
                        'Recent Orders',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      if (_recentOrders.isEmpty)
                        const _EmptyState(message: 'No recent orders found.')
                      else
                        ..._recentOrders.map((order) => _RecentOrderTile(order: order)),
                    ],
                  ),
      ),
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

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final Map<String, dynamic> order;

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
            _text(order, const ['order_id', 'order_no', 'id'], fallback: '#--'),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            _text(
              order,
              const ['delivery_status', 'status'],
              fallback: 'Pending',
            ),
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 10),
          Text(
            _text(
              order,
              const ['delivery_address', 'address', 'customer_address'],
              fallback: 'Address not available',
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentOrderTile extends StatelessWidget {
  const _RecentOrderTile({required this.order});

  final Map<String, dynamic> order;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.local_shipping_outlined,
              color: _TotalDeliveryScreenState.darkGreen,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _text(order, const ['order_id', 'order_no', 'id'], fallback: '#--'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  _text(
                    order,
                    const ['customer_name', 'name'],
                    fallback: 'Customer',
                  ),
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
          Text(
            _text(order, const ['delivery_status', 'status'], fallback: 'Pending'),
            style: const TextStyle(
              color: _TotalDeliveryScreenState.darkGreen,
              fontWeight: FontWeight.w600,
            ),
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
  for (final key in keys) {
    final value = source[key];
    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString().trim();
    }
  }
  return fallback;
}
