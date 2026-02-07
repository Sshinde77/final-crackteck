import 'package:flutter/material.dart';


class ProductToBeDeliveredScreen extends StatefulWidget {
  final int roleId;
  final String roleName;

  // ✅ IMPORTANT: make it OPTIONAL so route_generator error goes away
  // If passed from dashboard, it will show correct id.
  final String orderId;

  const ProductToBeDeliveredScreen({
    Key? key,
    required this.roleId,
    required this.roleName,
    this.orderId = "#12345678",
  }) : super(key: key);

  @override
  State<ProductToBeDeliveredScreen> createState() =>
      _ProductToBeDeliveredScreenState();
}

class _ProductToBeDeliveredScreenState extends State<ProductToBeDeliveredScreen> {
  static const Color _green = Color(0xFF1E7C10);

  bool _accepted = false;
  int _unreadNoti = 1;


  // ✅ STATIC DATA
  late final String orderDate;
  late final String orderTime;
  late final String fromAddress;
  late final String toAddress;

  late final List<_ProductItem> items;

  @override
  void initState() {
    super.initState();

    orderDate = "28-5-2525";
    orderTime = "5:30Pm";
    fromAddress = "Vasai Warehouse";
    toAddress = "101, A wing Borivali west\n400062";

    items = const <_ProductItem>[
      _ProductItem(
        title: "Intel Core i3 12100F 12th\nGen  Desktop PC Processor",
        price: "₹ 62,990",
        qty: 2,
        icon: Icons.memory,
      ),
      _ProductItem(
        title: "Intel Core i3 12100F 12th\nGen  Desktop PC Processor",
        price: "₹ 62,990",
        qty: 2,
        icon: Icons.developer_board,
      ),
      _ProductItem(
        title: "Intel Core i3 12100F 12th\nGen  Desktop PC Processor",
        price: "₹ 62,990",
        qty: 2,
        icon: Icons.power,
      ),
    ];
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  void _onAccept() {
    if (_accepted) return;
    setState(() => _accepted = true);

    // ✅ Navigate to Map Screen
    // Navigator.pushNamed(
    //   context,
    //   AppRoutes.DeliverypickupparcelScreen,
    //   arguments: deliverypickupparcelArguments(
    //     roleId: widget.roleId,
    //     roleName: widget.roleName,
    //     orderId: widget.orderId,
    //   ),
    // ).then((_) {
    //   // ✅ Safety check: only pop if we are still on this screen
    //   if (mounted) {
    //     Navigator.pop(context, true);
    //   }
    // });
  }

  void _onNotificationTap() {
    setState(() => _unreadNoti = 0);
    _toast("Notifications clicked");
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // ✅ if user presses back (system back), return FALSE to dashboard
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
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context, false),
          ),
          title: const Text(
            "Product to be delivered",
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
                      child: Icon(Icons.notifications_none,
                          color: Colors.white, size: 22),
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                child: Column(
                  children: [
                    _OrderInfoCard(
                      orderId: widget.orderId, // ✅ show passed id
                      date: orderDate,
                      time: orderTime,
                      from: fromAddress,
                      to: toAddress,
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
                    onPressed: _accepted ? null : _onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
                      disabledBackgroundColor: Colors.black12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      _accepted ? "Accepted" : "Accept",
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

/// ---------- ORDER CARD ----------
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
                  "ID:   $orderId",
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ),
              Text(
                "$date    $time",
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
                child: Text("From:",
                    style: TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 12)),
              ),
              Expanded(
                child: Text(from,
                    style: const TextStyle(fontSize: 12, height: 1.25)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                width: 50,
                child: Text("To:",
                    style: TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 12)),
              ),
              Expanded(
                child: Text(to,
                    style: const TextStyle(fontSize: 12, height: 1.25)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ---------- PRODUCT CARD ----------
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
                  item.price,
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
                "Qty",
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

/// ✅ FIXED MODEL (no duplicate qty)
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
