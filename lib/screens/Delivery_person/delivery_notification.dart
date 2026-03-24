import 'package:flutter/material.dart';

class DeliveryNotificationScreen extends StatelessWidget {
  final int roleId;
  final String roleName;


  const DeliveryNotificationScreen({
    Key? key,
    required this.roleId,
    required this.roleName,

  }) : super(key: key);

  static const Color green = Color(0xFF1E7C10);
  static const Color lightGreen = Color(0xFFE6FFE1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ✅ AppBar with BACK (returns to previous screen)
      appBar: AppBar(
        backgroundColor: green,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Notification",
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          // ---------------- NEW ORDER ----------------
          _NewOrderCard(
            onViewOrder: () {
              // TODO: navigate to order detail
            },
          ),

          const SizedBox(height: 14),

          // ---------------- SERVICE RATING ----------------
          _SimpleNotificationCard(
            title: "Service Rating",
            description:
            "Nice! #12345678 customer rated you 4 stars.\nKeep up the good work!",
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.star, color: Colors.amber, size: 16),
                Icon(Icons.star, color: Colors.amber, size: 16),
                Icon(Icons.star, color: Colors.amber, size: 16),
                Icon(Icons.star, color: Colors.amber, size: 16),
                Icon(Icons.star_border, color: Colors.grey, size: 16),
              ],
            ),
            time: "1 day ago",
            onTap: () {},
          ),

          const SizedBox(height: 14),

          _SimpleNotificationCard(
            title: "You completed 32 deliveries this week.",
            description:
            "Great hustle!\nYou're on the right track to unlock more rewards and recognition!",
            time: "2 days ago",
            onTap: () {},
          ),

          const SizedBox(height: 14),

          _SimpleNotificationCard(
            title: "Your profile is incomplete.",
            description: "Please upload your ID proof.",
            time: "2 hours ago",
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

/// ---------------- NEW ORDER CARD ----------------

class _NewOrderCard extends StatelessWidget {
  final VoidCallback onViewOrder;

  const _NewOrderCard({
    required this.onViewOrder,
  });

  static const Color green = Color(0xFF1E7C10);
  static const Color lightGreen = Color(0xFFE6FFE1);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onViewOrder,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + dot
            Row(
              children: [
                const Expanded(
                  child: Text(
                    "New Order",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: green,
                    ),
                  ),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: lightGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: const [
                      Expanded(
                        child: Text(
                          "ID:  #12345678",
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        "28-5-2525   5:30Pm",
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  const _KeyValue(label: "From:", value: "Vasai Warehouse"),
                  const SizedBox(height: 6),
                  const _KeyValue(
                    label: "To:",
                    value: "101, A wing Borivali west\n400062",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "15 minutes ago",
              style: TextStyle(color: Colors.black54, fontSize: 12),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: onViewOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "View Order",
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
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

/// ---------------- SIMPLE NOTIFICATION CARD ----------------

class _SimpleNotificationCard extends StatelessWidget {
  final String title;
  final String description;
  final String time;
  final VoidCallback onTap;
  final Widget? trailing;

  const _SimpleNotificationCard({
    required this.title,
    required this.description,
    required this.time,
    required this.onTap,
    this.trailing,
  });

  static const Color green = Color(0xFF1E7C10);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: green,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 8),
            Text(
              time,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------------- KEY VALUE ----------------

class _KeyValue extends StatelessWidget {
  final String label;
  final String value;

  const _KeyValue({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 48,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
