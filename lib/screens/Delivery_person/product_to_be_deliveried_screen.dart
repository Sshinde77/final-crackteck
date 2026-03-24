import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../services/delivery_man_service.dart';

class ProductToBeDeliveredScreen extends StatefulWidget {
  final int roleId;
  final String roleName;
  final String orderId;

  const ProductToBeDeliveredScreen({
    super.key,
    required this.roleId,
    required this.roleName,
    this.orderId = '#12345678',
  });

  @override
  State<ProductToBeDeliveredScreen> createState() =>
      _ProductToBeDeliveredScreenState();
}

class _ProductToBeDeliveredScreenState extends State<ProductToBeDeliveredScreen> {
  static const Color _green = Color(0xFF1E7C10);

  final DeliveryManService _deliveryService = DeliveryManService.instance;
  bool _accepted = false;
  bool _isLoading = true;
  bool _isAccepting = false;
  int _unreadNoti = 1;
  Map<String, dynamic> _detail = <String, dynamic>{};

  final List<_ProductItem> items = const <_ProductItem>[
    _ProductItem(
      title: 'Intel Core i3 12100F 12th Gen Desktop PC Processor',
      price: '62,990',
      qty: 2,
      icon: Icons.memory,
    ),
    _ProductItem(
      title: 'Intel Core i3 12100F 12th Gen Desktop PC Processor',
      price: '62,990',
      qty: 1,
      icon: Icons.developer_board,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() => _isLoading = true);
    try {
      final detail = await _deliveryService.fetchOrderDetail(widget.orderId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        final status = (_detail['status'] ?? _detail['order_status'] ?? '')
            .toString()
            .toLowerCase();
        _accepted = status.contains('accept') ||
            status.contains('assigned') ||
            status.contains('picked');
      });
    } catch (_) {
      // Keep graceful fallback UI.
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _onAccept() async {
    if (_accepted || _isAccepting) return;
    setState(() => _isAccepting = true);
    try {
      final response = await _deliveryService.acceptOrder(widget.orderId);
      if (!mounted) return;
      if (!response.success) {
        _toast(response.message ?? 'Failed to accept order');
        return;
      }
      setState(() => _accepted = true);
      Navigator.pushNamed(
        context,
        AppRoutes.DeliverypickupparcelScreen,
        arguments: deliverypickupparcelArguments(
          roleId: widget.roleId,
          roleName: widget.roleName,
          orderId: widget.orderId,
        ),
      ).then((_) {
        if (mounted) {
          Navigator.pop(context, true);
        }
      });
    } catch (error) {
      if (!mounted) return;
      _toast(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isAccepting = false);
      }
    }
  }

  void _onNotificationTap() {
    setState(() => _unreadNoti = 0);
    _toast('Notifications clicked');
  }

  String get _fromAddress {
    return (_detail['from_address'] ??
            _detail['pickup_address'] ??
            _detail['warehouse_address'] ??
            'Vasai Warehouse')
        .toString();
  }

  String get _toAddress {
    return (_detail['to_address'] ??
            _detail['delivery_address'] ??
            _detail['customer_address'] ??
            'Customer address not available')
        .toString();
  }

  String get _dateText {
    final raw = (_detail['order_date'] ?? _detail['date'] ?? '').toString();
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw.isEmpty ? '--' : raw;
    return '${parsed.day}-${parsed.month}-${parsed.year}';
  }

  String get _timeText {
    final raw = (_detail['order_date'] ?? _detail['date'] ?? '').toString();
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return (_detail['time'] ?? '--').toString();
    int h = parsed.hour % 12;
    if (h == 0) h = 12;
    final suffix = parsed.hour >= 12 ? 'PM' : 'AM';
    return '${h.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')} $suffix';
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, false);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: _green,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.pop(context, false),
          ),
          title: const Text(
            'Product to be delivered',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: _onNotificationTap,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(
                        Icons.notifications_none,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    if (_unreadNoti > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                      child: Column(
                        children: [
                          _OrderInfoCard(
                            orderId: widget.orderId,
                            date: _dateText,
                            time: _timeText,
                            from: _fromAddress,
                            to: _toAddress,
                          ),
                          const SizedBox(height: 14),
                          ...items.map(
                            (p) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _ProductCard(item: p),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: (_accepted || _isAccepting) ? null : _onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
                      disabledBackgroundColor: Colors.black12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isAccepting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            _accepted ? 'Accepted' : 'Accept',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderInfoCard extends StatelessWidget {
  const _OrderInfoCard({
    required this.orderId,
    required this.date,
    required this.time,
    required this.from,
    required this.to,
  });

  final String orderId;
  final String date;
  final String time;
  final String from;
  final String to;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
                  'ID:   $orderId',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                '$date    $time',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: Colors.black54,
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
                  'From:',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                ),
              ),
              Expanded(
                child: Text(
                  from,
                  style: const TextStyle(fontSize: 12, height: 1.25),
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
                  to,
                  style: const TextStyle(fontSize: 12, height: 1.25),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.item});

  final _ProductItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 74,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F4F4),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(item.icon, size: 28, color: Colors.black54),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Rs ${item.price}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Qty',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.qty.toString(),
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductItem {
  const _ProductItem({
    required this.title,
    required this.price,
    required this.qty,
    required this.icon,
  });

  final String title;
  final String price;
  final int qty;
  final IconData icon;
}
