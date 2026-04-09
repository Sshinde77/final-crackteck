import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../model/Delivery_person/delivery_order_detail_model.dart';
import '../../provider/delivery_person/delivery_order_detail_provider.dart';
import '../../routes/app_routes.dart';

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

  int _unreadNoti = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DeliveryOrderDetailProvider>().loadDetail();
    });
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _onAccept() async {
    final provider = context.read<DeliveryOrderDetailProvider>();
    if (provider.accepted || provider.isAccepting) return;

    final message = await provider.acceptOrder();
    if (!mounted || message == null) return;
    _toast(message);
    if (provider.accepted) {
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
    }
  }

  void _onNotificationTap() {
    setState(() => _unreadNoti = 0);
    _toast('Notifications clicked');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DeliveryOrderDetailProvider>();
    final detail = provider.detail;
    final items = detail.items
        .map(
          (item) => _ProductItem(
            title: item.title,
            price: item.price,
            qty: item.qty,
            icon: Icons.inventory_2_outlined,
          ),
        )
        .toList();

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
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                       child: Column(
                         children: [
                          if (provider.error != null && provider.error!.trim().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF5F5),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFFFD6D6)),
                                ),
                                child: Text(
                                  provider.error!,
                                  style: const TextStyle(
                                    color: Color(0xFF9B1C1C),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          _OrderInfoCard(
                            orderId: detail.id,
                            date: detail.date,
                            time: detail.time,
                            from: detail.from,
                            to: detail.to,
                          ),
                          const SizedBox(height: 14),
                          _AdditionalDetailsCard(
                            firstName: detail.customerFirstName,
                            lastName: detail.customerLastName,
                            customerName: detail.customerName,
                            customerPhone: detail.customerPhone,
                            customerEmail: detail.customerEmail,
                          ),
                          const SizedBox(height: 14),
                          if (items.isEmpty)
                            const _EmptyProductsCard()
                          else
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
                    onPressed: (provider.accepted || provider.isAccepting)
                        ? null
                        : _onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
                      disabledBackgroundColor: Colors.black12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: provider.isAccepting
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
                            provider.accepted ? 'Accepted' : 'Accept',
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

class _AdditionalDetailsCard extends StatelessWidget {
  const _AdditionalDetailsCard({
    required this.firstName,
    required this.lastName,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
  });

  final String firstName;
  final String lastName;
  final String customerName;
  final String customerPhone;
  final String customerEmail;

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
          const Text(
            'Additional Details',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          _AdditionalDetailRow(label: 'First Name', value: firstName),
          const SizedBox(height: 8),
          _AdditionalDetailRow(label: 'Last Name', value: lastName),
          const SizedBox(height: 8),
          _AdditionalDetailRow(label: 'Customer Name', value: customerName),
          const SizedBox(height: 8),
          _AdditionalDetailRow(label: 'Phone Number', value: customerPhone),
          const SizedBox(height: 8),
          _AdditionalDetailRow(label: 'Email', value: customerEmail),
        ],
      ),
    );
  }
}

class _AdditionalDetailRow extends StatelessWidget {
  const _AdditionalDetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              height: 1.25,
              color: Colors.black54,
            ),
          ),
        ),
      ],
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

class _EmptyProductsCard extends StatelessWidget {
  const _EmptyProductsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: const Text(
        'No product items found for this order.',
        style: TextStyle(
          fontSize: 12,
          color: Colors.black54,
          fontWeight: FontWeight.w600,
        ),
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
